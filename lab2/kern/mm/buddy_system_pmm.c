#include <pmm.h>
#include <list.h>
#include <stdio.h>
#include <buddy_system_pmm.h>

// lab2 challenge: Buddy System page allocator.
#define BUDDY_MAX_ORDER 32

typedef struct {
    list_entry_t free_list;
} buddy_area_t;

static buddy_area_t buddy_areas[BUDDY_MAX_ORDER];
static size_t buddy_nr_free;

static size_t
buddy_block_pages(unsigned int order) {
    return (size_t)1 << order;
}

static void
buddy_init(void) {
    for (unsigned int order = 0; order < BUDDY_MAX_ORDER; order ++) {
        list_init(&buddy_areas[order].free_list);
    }
    buddy_nr_free = 0;
}

/* Insert a free block and coalesce all already-free XOR buddies. */
static void
buddy_add_block(struct Page *base, unsigned int order) {
    while (order + 1 < BUDDY_MAX_ORDER) {
        ppn_t ppn = page2ppn(base);
        ppn_t buddy_ppn = ppn ^ (ppn_t)buddy_block_pages(order);
        if (buddy_ppn < nbase || buddy_ppn >= npage) {
            break;
        }
        struct Page *buddy = pages + (buddy_ppn - nbase);
        if (!PageProperty(buddy) || buddy->property != order) {
            break;
        }

        list_del(&buddy->page_link);
        ClearPageProperty(buddy);
        buddy->property = 0;
        if (buddy < base) {
            base = buddy;
        }
        order ++;
    }

    base->property = order;
    SetPageProperty(base);
    list_add(&buddy_areas[order].free_list, &base->page_link);
}

static void
buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    for (struct Page *page = base; page != base + n; page ++) {
        assert(PageReserved(page));
        page->flags = page->property = 0;
        set_page_ref(page, 0);
    }

    size_t remaining = n;
    struct Page *page = base;
    while (remaining != 0) {
        ppn_t ppn = page2ppn(page);
        unsigned int order = 0;
        while (order + 1 < BUDDY_MAX_ORDER) {
            size_t larger = buddy_block_pages(order + 1);
            if (larger > remaining || (ppn & (larger - 1)) != 0) {
                break;
            }
            order ++;
        }
        size_t block_pages = buddy_block_pages(order);
        buddy_add_block(page, order);
        buddy_nr_free += block_pages;
        page += block_pages;
        remaining -= block_pages;
    }
}

static struct Page *
buddy_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > buddy_nr_free) {
        return NULL;
    }

    unsigned int wanted = 0;
    while (wanted < BUDDY_MAX_ORDER && buddy_block_pages(wanted) < n) {
        wanted ++;
    }
    if (wanted == BUDDY_MAX_ORDER) {
        return NULL;
    }

    unsigned int order = wanted;
    while (order < BUDDY_MAX_ORDER &&
           list_empty(&buddy_areas[order].free_list)) {
        order ++;
    }
    if (order == BUDDY_MAX_ORDER) {
        return NULL;
    }

    list_entry_t *le = list_next(&buddy_areas[order].free_list);
    struct Page *base = le2page(le, page_link);
    list_del(le);
    ClearPageProperty(base);

    while (order > wanted) {
        order --;
        struct Page *right = base + buddy_block_pages(order);
        right->property = order;
        SetPageProperty(right);
        list_add(&buddy_areas[order].free_list, &right->page_link);
    }

    // Record the rounded block order so free_pages can return the full block.
    base->property = wanted;
    buddy_nr_free -= buddy_block_pages(wanted);
    return base;
}

static void
buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    unsigned int order = base->property;
    assert(order < BUDDY_MAX_ORDER);
    size_t block_pages = buddy_block_pages(order);
    assert(n <= block_pages);

    for (struct Page *page = base; page != base + block_pages; page ++) {
        assert(!PageReserved(page) && !PageProperty(page));
        page->flags = page->property = 0;
        set_page_ref(page, 0);
    }

    buddy_nr_free += block_pages;
    buddy_add_block(base, order);
}

static size_t
buddy_nr_free_pages(void) {
    return buddy_nr_free;
}

static void
buddy_check_lists(void) {
    size_t total = 0;
    for (unsigned int order = 0; order < BUDDY_MAX_ORDER; order ++) {
        list_entry_t *head = &buddy_areas[order].free_list;
        for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
            struct Page *page = le2page(le, page_link);
            ppn_t ppn = page2ppn(page);
            assert(PageProperty(page) && page->property == order);
            assert((ppn & (buddy_block_pages(order) - 1)) == 0);
            total += buddy_block_pages(order);

            if (order + 1 < BUDDY_MAX_ORDER) {
                ppn_t buddy_ppn = ppn ^ (ppn_t)buddy_block_pages(order);
                if (buddy_ppn >= nbase && buddy_ppn < npage) {
                    struct Page *buddy = pages + (buddy_ppn - nbase);
                    assert(!PageProperty(buddy) || buddy->property != order);
                }
            }
        }
    }
    assert(total == buddy_nr_free);
}

/* Exercise splitting, rounding, exhaustion, and merges at several orders. */
static void
buddy_check(void) {
    buddy_check_lists();
    size_t saved_nr_free = buddy_nr_free;
    if (saved_nr_free < 16) {
        return;
    }

    struct Page *arena = buddy_alloc_pages(16);
    assert(arena != NULL);
    list_entry_t saved_heads[BUDDY_MAX_ORDER];
    for (unsigned int order = 0; order < BUDDY_MAX_ORDER; order ++) {
        saved_heads[order] = buddy_areas[order].free_list;
        // Detached free blocks must not look like buddies to the test arena.
        list_entry_t *head = &buddy_areas[order].free_list;
        for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
            ClearPageProperty(le2page(le, page_link));
        }
        list_init(&buddy_areas[order].free_list);
    }
    size_t real_free_after_reserve = buddy_nr_free;
    buddy_nr_free = 0;

    buddy_free_pages(arena, 16);
    assert(buddy_nr_free == 16);
    assert(buddy_alloc_pages(17) == NULL);

    struct Page *p = buddy_alloc_pages(1);
    assert(p == arena && buddy_nr_free == 15);
    buddy_check_lists();
    buddy_free_pages(p, 1);
    assert(buddy_nr_free == 16);
    assert(!list_empty(&buddy_areas[4].free_list));
    buddy_check_lists();

    p = buddy_alloc_pages(3);
    assert(p == arena && buddy_nr_free == 12);
    buddy_free_pages(p, 3);
    assert(buddy_nr_free == 16);
    buddy_check_lists();

    struct Page *left = buddy_alloc_pages(8);
    struct Page *right = buddy_alloc_pages(8);
    assert(left == arena && right == arena + 8);
    assert(buddy_nr_free == 0 && buddy_alloc_pages(1) == NULL);
    buddy_free_pages(right, 8);
    assert(buddy_nr_free == 8);
    assert(buddy_alloc_pages(9) == NULL);
    buddy_free_pages(left, 8);
    assert(buddy_nr_free == 16);
    buddy_check_lists();

    // Remove the isolated test block and restore the original allocator state.
    list_del(&arena->page_link);
    ClearPageProperty(arena);
    arena->property = 4;
    for (unsigned int order = 0; order < BUDDY_MAX_ORDER; order ++) {
        buddy_areas[order].free_list = saved_heads[order];
        list_entry_t *head = &buddy_areas[order].free_list;
        if (head->next == head) {
            list_init(head);
        } else {
            // The copied head's first/last nodes still pointed to the live
            // head address; re-anchor those links after restoring the copy.
            head->next->prev = head;
            head->prev->next = head;
        }
        for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
            SetPageProperty(le2page(le, page_link));
        }
    }
    buddy_nr_free = real_free_after_reserve;
    buddy_free_pages(arena, 16);
    assert(buddy_nr_free == saved_nr_free);
    buddy_check_lists();
}

const struct pmm_manager buddy_system_pmm_manager = {
    .name = "buddy_system_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};
