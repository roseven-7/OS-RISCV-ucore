#include <assert.h>
#include <defs.h>
#include <list.h>
#include <mmu.h>
#include <pmm.h>
#include <slub.h>
#include <stdio.h>

#define SLUB_MAGIC          ((uintptr_t)0x534c55424d414749ULL)
#define SLUB_SMALL_MAX      256
#define SLUB_BITMAP_WORDS   8
#define SLUB_SMALL          1
#define SLUB_LARGE          2

struct slub_slab {
    uintptr_t magic;
    unsigned int kind;
    unsigned int order;
    size_t object_size;
    size_t capacity;
    size_t free_count;
    struct Page *page;
    list_entry_t link;
    uint64_t bitmap[SLUB_BITMAP_WORDS];
};

static list_entry_t slub_slabs;
static int slub_initialized;

static size_t
slub_align(size_t size) {
    size_t align = sizeof(uintptr_t);
    size_t remainder = size % align;
    if (remainder != 0) {
        size += align - remainder;
    }
    return size;
}

static void *
slub_payload(struct slub_slab *slab) {
    return (void *)((char *)slab + sizeof(*slab));
}

static struct slub_slab *
slub_new_small(size_t object_size) {
    struct Page *page = alloc_pages(1);
    if (page == NULL) {
        return NULL;
    }

    struct slub_slab *slab =
        (struct slub_slab *)(page2pa(page) + va_pa_offset);
    size_t available = PGSIZE - sizeof(*slab);
    size_t capacity = available / object_size;
    if (capacity > SLUB_BITMAP_WORDS * 64) {
        capacity = SLUB_BITMAP_WORDS * 64;
    }
    if (capacity == 0) {
        free_pages(page, 1);
        return NULL;
    }

    slab->magic = SLUB_MAGIC;
    slab->kind = SLUB_SMALL;
    slab->order = 0;
    slab->object_size = object_size;
    slab->capacity = capacity;
    slab->free_count = capacity;
    slab->page = page;
    for (size_t i = 0; i < SLUB_BITMAP_WORDS; i ++) {
        slab->bitmap[i] = ~0ULL;
    }
    if (capacity < SLUB_BITMAP_WORDS * 64) {
        size_t words = capacity / 64;
        size_t bits = capacity % 64;
        for (size_t i = words + (bits != 0); i < SLUB_BITMAP_WORDS; i ++) {
            slab->bitmap[i] = 0;
        }
        if (bits != 0) {
            slab->bitmap[words] = (1ULL << bits) - 1;
        }
    }
    list_add(&slub_slabs, &slab->link);
    return slab;
}

static struct slub_slab *
slub_new_large(size_t object_size) {
    size_t total = sizeof(struct slub_slab);
    if (object_size > ~(size_t)0 - total) {
        return NULL;
    }
    total += object_size;

    if (total > ~(size_t)0 - (PGSIZE - 1)) {
        return NULL;
    }
    size_t pages = (total + PGSIZE - 1) / PGSIZE;
    size_t block_pages = 1;
    unsigned int order = 0;
    while (block_pages < pages) {
        if (block_pages > (~(size_t)0 >> 1)) {
            return NULL;
        }
        block_pages <<= 1;
        order ++;
    }

    struct Page *page = alloc_pages(block_pages);
    if (page == NULL) {
        return NULL;
    }
    struct slub_slab *slab =
        (struct slub_slab *)(page2pa(page) + va_pa_offset);
    slab->magic = SLUB_MAGIC;
    slab->kind = SLUB_LARGE;
    slab->order = order;
    slab->object_size = object_size;
    slab->capacity = 1;
    slab->free_count = 0;
    slab->page = page;
    list_add(&slub_slabs, &slab->link);
    return slab;
}

static struct slub_slab *
slub_find(void *ptr) {
    char *address = (char *)ptr;
    for (list_entry_t *le = list_next(&slub_slabs);
         le != &slub_slabs; le = list_next(le)) {
        struct slub_slab *slab = to_struct(le, struct slub_slab, link);
        char *start = (char *)slub_payload(slab);
        size_t bytes = slab->kind == SLUB_SMALL
            ? slab->capacity * slab->object_size
            : slab->object_size;
        if (address >= start && address < start + bytes) {
            return slab;
        }
    }
    return NULL;
}

void
slub_init(void) {
    list_init(&slub_slabs);
    slub_initialized = 1;
}

void *
slub_alloc(size_t size) {
    assert(slub_initialized);
    if (size == 0) {
        return NULL;
    }

    size_t object_size = slub_align(size);
    if (object_size < size) {
        return NULL;
    }

    if (object_size <= SLUB_SMALL_MAX) {
        for (list_entry_t *le = list_next(&slub_slabs);
             le != &slub_slabs; le = list_next(le)) {
            struct slub_slab *slab = to_struct(le, struct slub_slab, link);
            if (slab->kind == SLUB_SMALL &&
                slab->object_size == object_size && slab->free_count != 0) {
                for (size_t i = 0; i < slab->capacity; i ++) {
                    size_t word = i / 64;
                    uint64_t bit = 1ULL << (i % 64);
                    if ((slab->bitmap[word] & bit) != 0) {
                        slab->bitmap[word] &= ~bit;
                        slab->free_count --;
                        return (char *)slub_payload(slab) + i * object_size;
                    }
                }
            }
        }

        struct slub_slab *slab = slub_new_small(object_size);
        if (slab == NULL) {
            return NULL;
        }
        slab->bitmap[0] &= ~1ULL;
        slab->free_count --;
        return slub_payload(slab);
    }

    struct slub_slab *slab = slub_new_large(object_size);
    return slab == NULL ? NULL : slub_payload(slab);
}

void
slub_free(void *ptr) {
    assert(slub_initialized);
    if (ptr == NULL) {
        return;
    }

    struct slub_slab *slab = slub_find(ptr);
    assert(slab != NULL && slab->magic == SLUB_MAGIC);
    char *start = (char *)slub_payload(slab);
    size_t offset = (size_t)((char *)ptr - start);
    assert(offset < slab->capacity * slab->object_size);
    assert(offset % slab->object_size == 0);

    if (slab->kind == SLUB_LARGE) {
        assert(ptr == start);
        struct Page *page = slab->page;
        size_t pages = (size_t)1 << slab->order;
        list_del(&slab->link);
        free_pages(page, pages);
        return;
    }

    size_t index = offset / slab->object_size;
    size_t word = index / 64;
    uint64_t bit = 1ULL << (index % 64);
    assert((slab->bitmap[word] & bit) == 0);
    slab->bitmap[word] |= bit;
    slab->free_count ++;
    if (slab->free_count == slab->capacity) {
        struct Page *page = slab->page;
        list_del(&slab->link);
        free_pages(page, 1);
    }
}

static void
slub_test_write(void *ptr, size_t size, unsigned char seed) {
    unsigned char *bytes = (unsigned char *)ptr;
    for (size_t i = 0; i < size; i ++) {
        bytes[i] = (unsigned char)(seed + i);
    }
    for (size_t i = 0; i < size; i ++) {
        assert(bytes[i] == (unsigned char)(seed + i));
    }
}

static int
slub_test_overlap(void *a, size_t asize, void *b, size_t bsize) {
    uintptr_t alo = (uintptr_t)a;
    uintptr_t ahi = alo + asize;
    uintptr_t blo = (uintptr_t)b;
    uintptr_t bhi = blo + bsize;
    return alo < bhi && blo < ahi;
}

void
slub_check(void) {
    assert(slub_initialized);
    size_t saved_nr_free = nr_free_pages();

    assert(slub_alloc(0) == NULL);
    slub_free(NULL);
    assert(nr_free_pages() == saved_nr_free);

    static const size_t small_sizes[] = {1, 7, 8, 15, 16, 64, 128, 256};
    void *small[24];
    size_t small_size[24];
    size_t small_count = 0;
    for (size_t i = 0; i < sizeof(small_sizes) / sizeof(small_sizes[0]); i ++) {
        for (size_t j = 0; j < 3; j ++) {
            small[small_count] = slub_alloc(small_sizes[i]);
            assert(small[small_count] != NULL);
            small_size[small_count] = small_sizes[i];
            slub_test_write(small[small_count], small_size[small_count],
                            (unsigned char)(i * 19 + j));
            small_count ++;
        }
    }
    for (size_t i = 0; i < small_count; i ++) {
        for (size_t j = i + 1; j < small_count; j ++) {
            assert(!slub_test_overlap(small[i], small_size[i],
                                      small[j], small_size[j]));
        }
    }

    for (size_t i = 0; i < small_count; i += 2) {
        slub_free(small[i]);
        small[i] = NULL;
    }
    void *reused[8];
    for (size_t i = 0; i < 8; i ++) {
        reused[i] = slub_alloc(8);
        assert(reused[i] != NULL);
        slub_test_write(reused[i], 8, (unsigned char)(0xa0 + i));
    }
    for (size_t i = 0; i < small_count; i ++) {
        if (small[i] != NULL) {
            for (size_t j = 0; j < 8; j ++) {
                assert(!slub_test_overlap(small[i], small_size[i],
                                          reused[j], 8));
            }
        }
    }
    for (size_t i = 0; i < 8; i ++) {
        slub_free(reused[i]);
    }
    for (size_t i = 0; i < small_count; i ++) {
        if (small[i] != NULL) {
            slub_free(small[i]);
        }
    }

    static const size_t large_sizes[] = {257, PGSIZE, PGSIZE + 1};
    void *large[3];
    for (size_t i = 0; i < 3; i ++) {
        large[i] = slub_alloc(large_sizes[i]);
        assert(large[i] != NULL);
        unsigned char *bytes = (unsigned char *)large[i];
        bytes[0] = (unsigned char)(0x30 + i);
        bytes[large_sizes[i] / 2] = (unsigned char)(0x50 + i);
        bytes[large_sizes[i] - 1] = (unsigned char)(0x70 + i);
        assert(bytes[0] == (unsigned char)(0x30 + i));
        assert(bytes[large_sizes[i] / 2] == (unsigned char)(0x50 + i));
        assert(bytes[large_sizes[i] - 1] == (unsigned char)(0x70 + i));
    }
    for (size_t i = 0; i < 3; i ++) {
        for (size_t j = i + 1; j < 3; j ++) {
            assert(!slub_test_overlap(large[i], large_sizes[i],
                                      large[j], large_sizes[j]));
        }
    }
    void *mixed = slub_alloc(32);
    assert(mixed != NULL);
    slub_test_write(mixed, 32, 0xc0);
    for (size_t i = 0; i < 3; i ++) {
        assert(!slub_test_overlap(mixed, 32, large[i], large_sizes[i]));
    }
    slub_free(mixed);
    for (size_t i = 0; i < 3; i ++) {
        slub_free(large[i]);
    }

    assert(slub_alloc(~(size_t)0) == NULL);
    assert(nr_free_pages() == saved_nr_free);
    void *last = slub_alloc(32);
    assert(last != NULL);
    slub_free(last);
    assert(nr_free_pages() == saved_nr_free);
    cprintf("slub_check() succeeded!\n");
}
