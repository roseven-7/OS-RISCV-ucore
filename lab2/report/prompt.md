# Lab2 实验 Prompts

<!-- BEGIN PROMPT: task1.md -->
## 一、Prompt 任务说明

**背景**：ucore-riscv64 教学内核 lab2。启动链路 `kern_init() → pmm_init() → init_pmm_manager() → page_init() → check_alloc_page()`；物理内存范围由设备树提供（`get_memory_base()/get_memory_size()`），QEMU 默认 128MiB 且 `-m` 可配，大小必须读设备树、不能假设。

**任务**：在 `kern/mm/pmm.c` 中 `//lab2 function1 YOUR CODE` 标记处，实现 `static void page_init(void);`，使内核能够识别、组织并分配可用物理内存。功能需求如下：

1. 设置虚拟地址与物理地址的偏移 `va_pa_offset`：本内核采用恒等偏移映射，VA = PA + PHYSICAL_MEMORY_OFFSET，该值是后续 `PADDR()` 等一切地址换算的基础；
2. 通过 `get_memory_base()/get_memory_size()` 获取 DRAM 起始物理地址与大小，确认范围有效并输出探测结果；
3. 结合内核能够管理的地址上界确定物理页号范围：`nbase` 是 DRAM 起始位置对应的物理页号，`npage` 是内核可管理的物理页号上界（注意 npage 是上界而非页数，页数 = npage − nbase）；描述符数组须覆盖页号区间 `[nbase, npage)`，即 `pages[i]` 描述物理页号 `nbase+i` 的页；
4. 安置描述符数组：所有 Page 描述符连续排列在内核镜像之后，`pages` 指向 `end` 之后按页对齐的位置（注意 `end` 是链接脚本定义的内核镜像结尾虚拟地址，与物理地址 KernelEnd 不能直接混用）；数组自身占用的页面也是"被占用的内存"，必须计入不可分配范围；
5. 空闲区建立之前，所有描述符先处于保留状态（`SetPageReserved`），防止布局尚未完成的页面被提前分配；
6. 注册空闲区：数组末尾（虚拟地址，需经 `PADDR()` 转为物理地址）向上按页对齐，设备树报告的内存末端向下按页对齐，只有两者之间非空的完整页区间才通过 `pa2page()` 转换为描述符起点、以 `init_memmap()` 交给当前 pmm_manager；物理内存末尾不足一页的部分同样不得交给分配器；
7. 设备树信息无效时调用 `panic()` 终止初始化，不得带着错误状态继续。

一句话概括布局目标：OpenSBI 占用区之后依次是"内核镜像 → 必要的对齐空隙 → Page 描述符数组 → 再次按页对齐产生的空隙 → 最终可分配的连续物理页"。

**操作要求（边界清晰）**：

- 你必须修改项目中的实际文件，而不是仅展示代码；
- 只允许修改 `page_init()` 的函数体；
- 不得修改函数签名、本文件内其他任何函数，不得修改 `kern/mm/pmm.h`、`kern/mm/memlayout.h`、`kern/mm/default_pmm.c` 及工程内任何宏、结构体、全局变量声明与测试函数；
- 不得硬编码任何内存地址数值（如 0x80000000、0x88000000），一律使用宏、全局变量或设备树接口获取；
- 保留工程原有底层逻辑（页号约定 `pages[i]` 描述物理页号 `nbase+i`、`PADDR()` 换算语义等），不得自创替代机制；
- 若下方 Rely / Guarantee / Specification 中的函数签名与当前工程实际代码不一致，一律以工程实际代码为准。

**输出要求**：

- 先用 3–5 句话（或一张文本内存图）说明你建立的物理内存布局关系，再给出完整函数实现；
- 随后逐条自证：Specification 每一条后置效果与分支场景分别由哪些代码行保证；
- 最后列出你识别并处理的所有边界情况。

## 二、Rely 依赖说明（最小依赖集合）

仅依赖以下已存在于工程的符号，不要假设其他接口存在：

- 设备树接口（`kern/driver/dtb.h`）：`uint64_t get_memory_base(void)`、`uint64_t get_memory_size(void)`，分别返回 DRAM 起始物理地址与字节数；
- 全局变量（`kern/mm/pmm.c`）：`struct Page *pages`、`size_t npage`、`uint64_t va_pa_offset`、`const size_t nbase`（= DRAM_BASE/PGSIZE，已初始化）；
- 常量与宏（`kern/mm/memlayout.h`、`riscv.h`、`defs.h`）：`KERNBASE`、`KERNTOP`（虚拟地址上界）、`PHYSICAL_MEMORY_END`（物理地址上界 0x88000000）、`PHYSICAL_MEMORY_OFFSET`（虚址−物理 偏移）、`KERNEL_BEGIN_PADDR`、`DRAM_BASE`、`PGSIZE`、`ROUNDUP`、`ROUNDDOWN`、`PADDR(kva)`；
- 其他：`extern char end[]`（内核镜像结束处的虚拟地址符号）、`pa2page(pa)`、`init_memmap(struct Page *base, size_t n)`、`SetPageReserved(page)`、`cprintf(...)`、`panic(...)`、`struct Page`。

## 三、Guarantee 接口清单

- 交付且仅交付一个对外函数：`static void page_init(void);`（在 pmm.c 中，被 pmm_init() 调用）；
- 不得新增任何对外接口、全局变量或全局状态；允许自行定义局部变量与辅助计算。

## 四、Specification 行为规格

**前置状态**：`init_pmm_manager()` 已将 `pmm_manager` 指向 `default_pmm_manager` 并完成其 `init()`；`dtb_init()` 已成功执行，内存信息可由 `get_memory_base()/get_memory_size()` 读取；内核运行在已建立恒等偏移映射的环境中（VA = PA + PHYSICAL_MEMORY_OFFSET）。

**后置效果（函数成功返回时必须全部成立）**：

1. `va_pa_offset` 已赋值为 `PHYSICAL_MEMORY_OFFSET`；
2. `npage` 等于"可管理物理页号上界"：`npage = (min(get_memory_base()+get_memory_size(), PHYSICAL_MEMORY_END) >> PGSHIFT)`；注意 npage 是页号上界而非页数，页数 = npage − nbase；
3. `pages` 指向 `ROUNDUP(end, PGSIZE)` 处（end 为虚拟地址），数组共 `npage − nbase` 项；
4. 页号 `[nbase, freemem)` 对应的描述符 `PG_reserved` 位均为 1（OpenSBI、内核镜像、数组自身所在页都不得进入空闲区）；
5. 空闲区 `[freemem, mem_end)` 的完整页面已通过 `init_memmap()` 交给当前 pmm_manager；
6. `cprintf` 已输出探测到的物理内存范围（起始地址、大小、结束地址）。

**分支场景**：

- 设备树信息无效（base 为 0、size 为 0、base+size 溢出或回绕）→ 调用 `panic()` 终止初始化，不得静默继续；
- 算得 `npage <= nbase`（没有任何可管理页）→ 不得调用 `init_memmap()`；
- 数组末尾向上对齐后 `freemem >= mem_end`（没有剩余完整空闲页）→ 不得调用 `init_memmap()`；
- 设备树报告的内存末端未按页对齐 → 用 `ROUNDDOWN` 丢弃尾部的不足一页部分，不得交给分配器。

**必须实现的东西**：

1. 赋值 `va_pa_offset`；
2. 读取 `get_memory_base()/get_memory_size()` 并做有效性校验，无效则 `panic()`；
3. `cprintf` 打印内存范围（建议格式含 base 与 base+size−1）；
4. 计算可管理上界并截断：`maxpa = min(base+size, PHYSICAL_MEMORY_END)`，`npage = maxpa >> PGSHIFT`；
5. `pages = (struct Page *)ROUNDUP(end, PGSIZE)`；
6. 对全部 `npage − nbase` 个描述符先执行 `SetPageReserved`（数组布局完成前任何页不得被分配）；
7. 计算数组末尾：`(char *)pages + (npage − nbase) * sizeof(struct Page)` 得虚拟地址，经 `PADDR()` 转物理地址，再 `ROUNDUP` 到 `PGSIZE`，记为 `freemem`；`mem_end = ROUNDDOWN(base + size, PGSIZE)`；
8. 仅当 `freemem < mem_end`，调用 `init_memmap(pa2page(freemem), (mem_end - freemem) / PGSIZE)`。

**可验证性基准**：QEMU 默认 128MB 内存时，`npage = 0x88000`、`nbase = 0x80000`、描述符共 32768 个；`init_memmap` 收到的页数必须等于 `(mem_end - freemem)/PGSIZE`，后续 `check_alloc_page()` 与 `nr_free_pages()` 的输出可用于核验。实现不得为凑数硬编码任何数值。
<!-- END PROMPT: task1.md -->

---


<!-- BEGIN PROMPT: lab2-best-fit-prompt.md -->
# Lab2 功能模块二任务二：Best-Fit 连续物理页分配

## [PROMPT]

**任务**：参考 `kern/mm/default_pmm.c` 中 First-Fit 的实现，在 `kern/mm/best_fit_pmm.c` 的 `lab2 function2-2 YOUR CODE` 标记处实现完整的 Best-Fit 物理内存管理模块。根据 `kern/mm/pmm.h` 中 `struct pmm_manager` 的接口定义管理函数和内部状态，并定义 `best_fit_pmm_manager`。随后修改 `kern/mm/pmm.c` 的 `init_pmm_manager()`，使内核使用 `best_fit_pmm_manager`。

**操作要求**：在项目中修改实际文件。保留已有代码，只在完成任务所需的位置补充或修改内容；不得修改 `basic_check()`、`best_fit_check()` 两个测试函数。

**输出要求**：完成代码后，说明实现涉及的函数和状态如何满足下方的接口及行为规格，并说明构建和测试结果。以项目中的真实接口和代码为准，不引入本任务以外的功能。

## [RELY]

只使用以下项目中已有的接口和约定：

- `kern/mm/pmm.h` 定义 `struct pmm_manager`，其回调依次为 `init(void)`、`init_memmap(struct Page *base, size_t n)`、`alloc_pages(size_t n)`、`free_pages(struct Page *base, size_t n)`、`nr_free_pages(void)` 和 `check(void)`。
- `kern/mm/best_fit_pmm.h` 声明 `extern const struct pmm_manager best_fit_pmm_manager;`。
- `kern/mm/memlayout.h` 定义 `struct Page`，其中 `flags` 表示页面状态，`property` 用于记录空闲连续块的页数，`page_link` 用于链表；`PageReserved`、`PageProperty`、`SetPageProperty`、`ClearPageProperty` 是已有页面状态宏。
- `kern/mm/default_pmm.c` 展示了 First-Fit 管理器如何初始化空闲页面、分配页面、释放并合并连续空闲块，以及如何实现 `struct pmm_manager` 回调，可作为参考。
- `libs/list.h` 提供双向循环链表操作；`pmm.h` 提供 `page_ref`、`set_page_ref` 等页面引用计数操作。
- `best_fit_pmm.c` 已提供 `basic_check()` 和 `best_fit_check()`。测试直接访问名为 `free_list` 和 `nr_free` 的状态，并会保存、清空和恢复它们；分配器实际使用的状态必须与测试操作的状态一致。
- `pmm.c` 的 `alloc_pages()`、`free_pages()`、`nr_free_pages()` 通过当前 `pmm_manager` 调用对应回调；`init_pmm_manager()` 负责选择并初始化管理器。

## [GUARANTEE]

在 `kern/mm/best_fit_pmm.c` 中实现以下回调。内部函数名可按实现需要调整，但函数指针的返回类型和参数必须与这里及 `struct pmm_manager` 一致：

```c
static void best_fit_init(void);
static void best_fit_init_memmap(struct Page *base, size_t n);
static struct Page *best_fit_alloc_pages(size_t n);
static void best_fit_free_pages(struct Page *base, size_t n);
static size_t best_fit_nr_free_pages(void);
```

定义 `const struct pmm_manager best_fit_pmm_manager`，将 `init`、`init_memmap`、`alloc_pages`、`free_pages`、`nr_free_pages` 分别绑定到对应实现，并将 `check` 绑定到已有的 `best_fit_check()`。

在 `kern/mm/pmm.c` 中修改 `init_pmm_manager()`，选择 `best_fit_pmm_manager` 并调用其初始化回调。

不得修改 `basic_check()` 和 `best_fit_check()` 的函数体。不得修改与本任务无关的代码。

## [SPECIFICATION]

### Best-Fit 管理器初始化

**Pre-Condition**：管理器尚未接收可分配页面。

**Post-Condition**：管理器的空闲块链表为空，空闲页数为零。

### 可用页面区间初始化

**Pre-Condition**：管理器已初始化；传入的 `n` 大于零；`base` 开始的 `n` 个连续页面描述符是可交给管理器的保留页面。

**Post-Condition**：这 `n` 个页面被加入空闲管理，引用计数清零，空闲页数增加 `n`。每个空闲连续块由其首页描述；首页记录该块的页面数并标记为 `PageProperty`。空闲块互不重叠，链表能正确描述当前所有空闲块。

### 空闲状态约定

空闲链表中的每个节点都是一个空闲块的首页，且设置 `PageProperty`；该页的 `property` 等于块内页面数。所有空闲块的 `property` 总和等于 `nr_free_pages()` 返回值。空闲页面的引用计数为零。该状态约定需满足 `best_fit_check()` 对链表、标志、块大小和空闲页总数的检查。

### 连续页面分配

**Pre-Condition**：请求的页面数 `n` 大于零。

**Post-Condition**：成功时返回一个至少包含 `n` 个连续物理页面的空闲块首页，分配出的页面不再被记录为空闲块，空闲页数减少 `n`。若选中空闲块大于请求大小，未分配的页面仍作为空闲块正确记录。失败时返回 `NULL`，空闲管理状态不因失败而改变。

**Case 1**：有多个空闲块能够满足请求时，选择页面数最接近请求大小且不小于请求大小的块，即 Best-Fit。

**Case 2**：没有单个连续空闲块能够满足请求时，返回 `NULL`；不能将不连续的空闲块拼接成一次分配。

**Case 3**：空闲链表为空时，返回 `NULL`。现有测试可能在链表为空时暂未同步修改空闲页计数；分配结果仍须由当前空闲块状态决定。

### 页面释放

**Pre-Condition**：`n` 大于零；`base` 开始的 `n` 个连续物理页面当前已分配且未保留。

**Post-Condition**：释放页面被重新纳入空闲管理，引用计数清零，空闲页数增加 `n`。空闲块描述正确；与释放区间物理地址连续的空闲块应合并，避免相邻空闲区仍被分别记录。

### 空闲页数查询

**Pre-Condition**：管理器已初始化。

**Post-Condition**：返回当前空闲页面总数，不改变管理器状态。

### 管理器注册与测试

**Post-Condition**：`best_fit_pmm_manager` 的名称为 `"best_fit_pmm_manager"`，其各回调指向 Best-Fit 的对应实现，检查回调指向已有的 `best_fit_check()`。`init_pmm_manager()` 选择并初始化该管理器，使后续页面初始化、分配、释放和检查均通过 Best-Fit 管理器执行。

实现必须满足已有 `basic_check()`、`best_fit_check()` 的断言和状态约定。算法的时间、空间复杂度不作要求，以实现完整并通过测试为准。完成后构建并运行项目提供的检查；评分测试应报告 `[Test 1] Page Init: PASS` 和 `[Test 2] Best-Fit: PASS`。

<!-- END PROMPT: lab2-best-fit-prompt.md -->

---


<!-- BEGIN PROMPT: lab2_buddy_prompt.md -->
# Lab2 功能模块二任务三：Buddy System 伙伴系统分配

## [PROMPT]

**任务**：在当前 `lab2/` 工程中实现 Buddy System 物理页分配器，并接入现有内核。新增或完善 `kern/mm/buddy_system_pmm.c`，在 `kern/mm/buddy_system_pmm.h` 中声明管理器，再修改 `kern/mm/pmm.c` 的 `init_pmm_manager()`，选择 `buddy_system_pmm_manager`。按阶数维护空闲页块，将正数页请求向上取整到最小可容纳的二次幂页块，通过逐级拆分完成分配，通过同阶伙伴合并完成释放。

**操作要求**：先阅读下方 RELY 列出的真实接口和当前实现，再直接修改项目文件，采用最小改动。保留现有 First-Fit、Best-Fit 实现及已有测试；不得修改 `struct pmm_manager`、`struct Page`、公共页分配接口、`page_init()` 或设备树探测逻辑。新增辅助函数、宏、内部类型和状态限于 Buddy 模块内部。不得使用宿主机 `malloc`、`free` 或项目中不存在的内核堆接口。现有 Makefile 自动编译 `kern/mm` 下的 C 文件，不应为新增 Buddy 模块修改 Makefile。已有 Buddy 自检应保留；内核自检的具体用例由第二份测试 prompt 单独规定。

**输出要求**：直接完成文件操作，并说明分阶链表、页面状态、区间初始化、请求取整、拆分、释放及伙伴合并的行为，明确 `free_pages(base, n)` 的完整块释放约定。严格以项目真实代码为准；如实际接口与本 prompt 不符，应指出差异。若进行了构建或运行检查，准确报告命令、结果和未覆盖的边界。

## [RELY]

- `kern/mm/pmm.h` 定义 `struct pmm_manager`，包含以下回调：

```c
void (*init)(void);
void (*init_memmap)(struct Page *base, size_t n);
struct Page *(*alloc_pages)(size_t n);
void (*free_pages)(struct Page *base, size_t n);
size_t (*nr_free_pages)(void);
void (*check)(void);
```

  公共 `alloc_pages()`、`free_pages()`、`nr_free_pages()` 通过当前管理器转发；启动时 `check_alloc_page()` 调用管理器的 `check` 回调。

- `kern/mm/memlayout.h` 中的 `struct Page` 含 `ref`、`flags`、`property` 和 `page_link`。`PageReserved`、`PageProperty`、`SetPageReserved`、`SetPageProperty`、`ClearPageProperty` 用于检查和修改页面状态；`pmm.h` 提供引用计数操作。`property` 在 First-Fit、Best-Fit 中表示页数，Buddy 可将它用作块阶数，但不得改变结构定义或其他分配器的字段语义。

- `pmm.h` 提供全局 `pages`、`nbase`、`npage`，以及 `page2ppn()`、`pa2page()`、`page2pa()`。`page2ppn(page)` 等于 `page - pages + nbase`，可管理物理页号范围为 `[nbase, npage)`；`npage` 是页号上界，描述符数量为 `npage - nbase`。伙伴关系和块对齐必须按物理页号计算，不能直接按描述符数组下标异或。

- `libs/list.h` 提供双向循环链表的初始化、插入、删除和空表检查操作。当前 Buddy 设计使用 `buddy_areas[BUDDY_MAX_ORDER]` 分阶保存空闲链表，`BUDDY_MAX_ORDER` 为 32，对应阶数 0 至 31；`buddy_nr_free` 保存实际空闲页数。阶数 `k` 的块包含 `2^k` 页，块首页物理页号按 `2^k` 对齐。

- `kern/mm/default_pmm.c` 和 `kern/mm/best_fit_pmm.c` 展示管理器注册方式。`pmm.c` 的 `init_pmm_manager()` 选择管理器并调用其 `init()`；`page_init()` 完成描述符布局后，通过 `init_memmap()` 交出仍处于保留状态的完整空闲页。

- Buddy 分配成功后，块首页清除 `PageProperty`，并在 `property` 中保留实际分配阶数。当前释放约定为：`base` 必须是原分配返回的块首页，`n > 0` 且不大于实际块大小；释放按记录阶数归还完整块。比如申请 3 页实际占用 4 页，`free_pages(base, 3)` 归还完整 4 页，不支持任意子块释放。

- 项目采用 GNU C/RISC-V 内核环境，提供 `assert()` 和 `cprintf()`。当前实验只要求串行调用，不需要增加多核同步或宿主测试框架。

## [GUARANTEE]

在 `kern/mm/buddy_system_pmm.c` 中实现或完善以下内部接口和管理器定义，可增加必要的 `static` 辅助函数、内部类型、宏及状态：

```c
static void buddy_init(void);
static void buddy_init_memmap(struct Page *base, size_t n);
static struct Page *buddy_alloc_pages(size_t n);
static void buddy_free_pages(struct Page *base, size_t n);
static size_t buddy_nr_free_pages(void);
static void buddy_check(void);
const struct pmm_manager buddy_system_pmm_manager;
```

在 `kern/mm/buddy_system_pmm.h` 声明管理器：

```c
extern const struct pmm_manager buddy_system_pmm_manager;
```

在 `kern/mm/pmm.c` 中引用 Buddy 头文件，修改 `init_pmm_manager()` 以选择该管理器并调用其 `init()`，保留启动输出和其余初始化流程：

```c
static void init_pmm_manager(void);
```

管理器的六个回调必须绑定到对应 Buddy 函数，`check` 绑定到 `buddy_check()`。不得新增公共分配接口；已有自检不得删除或改成空实现，具体自检规格见第二份测试 prompt。

## [SPECIFICATION]

### buddy_init(void)

**Pre-Condition**：Buddy 管理器尚未接收可分配页面。

**Post-Condition**：各阶空闲链表均初始化为空表，实际空闲页数为零，后续可通过 `buddy_init_memmap()` 登记空闲区间。

**Requirements**：初始化不申请页面，不依赖分配接口，不修改其他管理器的状态。

### buddy_init_memmap(struct Page *base, size_t n)

**Pre-Condition**：管理器已初始化；`n > 0`；`base` 开始的 `n` 个描述符处于可管理范围内，均为保留页面，且该区间未重复登记。

**Post-Condition**：恰好将输入区间内的页面纳入空闲管理，清理其保留标志、块描述及引用计数，实际空闲页数增加 `n`。各空闲块大小为二次幂，按物理页号对齐，互不重叠且没有可继续合并的同阶伙伴。

**Case 1：长度或起点未按大块对齐**：输入长度不是二次幂，或区间起点不满足大块对齐时，将区间拆成多个满足物理页号对齐的二次幂块，不得登记输入区间之外的页面。

**Case 2：与已有伙伴合并**：新增块存在已经登记的同阶空闲伙伴时，可以逐级合并；不得把保留页、已分配页或不同阶块作为可合并伙伴。

**Requirements**：第 `k` 阶链表中仅登记设置了 `PageProperty` 且 `property == k` 的块首页；所有阶表示的页数之和必须等于 `buddy_nr_free`。

### buddy_alloc_pages(size_t n)

**Pre-Condition**：管理器已初始化，空闲链表和计数一致；`n > 0`。

**Post-Condition**：成功时返回至少容纳 `n` 页的连续块首页；实际块大小为不小于 `n` 的最小二次幂，空闲页数按实际大小减少。块首页不再登记为空闲，但保留分配阶数；拆分产生的余块仍正确登记。失败时返回 `NULL`，链表、页面状态和空闲页数保持不变。

**Case 1：目标阶有空闲块**：直接从目标阶取出一个块，清除其空闲块首页标志并更新计数。

**Case 2：从高阶拆分**：目标阶为空时，寻找更高的第一个非空阶；逐级拆分，保留左半块继续处理，将右半块登记到对应阶，直至取得目标阶块。

**Case 3：资源不足或阶数越界**：请求大于实际空闲页数、超出支持阶数，或没有足够大的单个伙伴块时返回 `NULL`，不能拼接不连续页面。

**Requirements**：请求阶数计算和位移不得越界；不得把 `n == 0` 当作正常成功请求，该输入不在前置条件内，可使用断言拒绝。

### buddy_free_pages(struct Page *base, size_t n)

**Pre-Condition**：`base` 是此前成功分配且尚未释放的原始块首页；`n > 0` 且不大于首页记录阶数对应的实际块大小；块内页面未保留、未登记为空闲。

**Post-Condition**：清理被释放块的页面状态和引用计数，按首页保存的阶数归还整个伙伴块，空闲页数按实际块大小增加。释放后的块与同阶空闲伙伴尽可能合并，其他存活分配不受影响。

**Case 1：找到同阶空闲伙伴**：按 `buddy_ppn = ppn XOR (1 << order)` 定位伙伴。伙伴处于 `[nbase, npage)` 且是同阶空闲块首页时，将其从链表摘除，以较低物理页号作为合并后首页，继续检查更高阶伙伴。

**Case 2：不能继续合并**：伙伴越界、不是空闲块首页、阶数不同或已经达到最大阶时停止，将当前块登记到对应阶链表。

**Requirements**：按 `n` 释放原请求向上取整后的完整块，不支持内部指针、任意子块或重复释放。对非法输入可使用断言，不要求提供恢复策略。

### buddy_nr_free_pages(void)

**Pre-Condition**：管理器已初始化，空闲计数与链表一致。

**Post-Condition**：返回当前实际空闲页数，不修改任何状态；结果等于各阶空闲块页数之和。

### buddy_check(void)

**Pre-Condition**：管理器已完成初始化和可用区间登记。

**Post-Condition**：完成第二份测试 prompt 规定的可执行检查，结束后不遗留测试分配，不破坏真实空闲链表、页面标志或计数。

**Requirements**：保留已有自检行为；具体不变量、16 页隔离区用例及恢复方法由第二份测试 prompt 规定。可用资源不足时必须明确检查范围，不能把跳过的用例报告为通过。

### init_pmm_manager(void) 中的管理器接入

**Pre-Condition**：保留现有 `pmm_init()`、`page_init()` 和分配检查调用链。

**Post-Condition**：当前管理器指向 `buddy_system_pmm_manager`，输出管理器名称并调用其 `init()`；后续空闲区登记、分配、释放、查询和启动自检均经现有框架调用 Buddy。

**Requirements**：保留 First-Fit、Best-Fit 源码及测试，不修改公共接口或为 Buddy 新设并行的分配入口。

<!-- END PROMPT: lab2_buddy_prompt.md -->

---

<!-- BEGIN PROMPT: lab2_buddy_test_prompt.md -->
# Lab2 功能模块二任务三：Buddy System 内核自检

## [PROMPT]

**任务**：阅读当前 `lab2/kern/mm/buddy_system_pmm.c` 和 `.h`，针对已实现的 Buddy System 分配器设计并完善内核自检。检查应通过 `buddy_system_pmm_manager` 的 `check` 回调执行，验证空闲链表不变量、逐阶拆分、非二次幂请求取整、资源耗尽、伙伴合并及测试结束后的状态恢复。

**操作要求**：先核对下方 RELY 中的真实实现和接口，再直接修改项目中的测试代码。不得修改被测分配算法、公共页分配接口、`struct Page`、管理器选择或已有 First-Fit、Best-Fit 测试。新增测试函数和测试状态限于 Buddy 模块内部；允许直接调用模块内的 `static` 分配、释放函数，以便隔离分阶链表。不得将这些内部测试描述为已通过公共 `alloc_pages()`、`free_pages()` 包装接口执行；不得使用宿主动态内存或宿主测试框架。

**输出要求**：说明每组断言验证的行为、测试区如何预留和隔离、真实链表和页面标志如何恢复，并准确报告实际构建及运行命令和结果。区分已执行、因资源不足而跳过及尚未覆盖的场景，不得将成功提示等同于所有边界均已验证。

## [RELY]

- `kern/mm/buddy_system_pmm.c` 已实现以下模块内部操作：

```c
static void buddy_init(void);
static void buddy_init_memmap(struct Page *base, size_t n);
static struct Page *buddy_alloc_pages(size_t n);
static void buddy_free_pages(struct Page *base, size_t n);
static size_t buddy_nr_free_pages(void);
```

  `buddy_alloc_pages(n)` 要求 `n > 0`，成功返回向上取整后的块首页；`buddy_free_pages(base, n)` 按首页记录的阶数归还完整块。申请 3 页消耗 4 页，按 3 页参数释放时归还完整 4 页。

- `buddy_areas[BUDDY_MAX_ORDER]` 按阶维护空闲双向循环链表，`BUDDY_MAX_ORDER` 为 32；`buddy_nr_free` 记录实际空闲页数。阶数 `k` 的块有 `2^k` 页，块首页的 `property` 保存阶数，`PageProperty` 表示该首页登记为空闲。

- `pmm.h` 提供 `pages`、`nbase`、`npage` 和 `page2ppn()`。可管理页号范围为 `[nbase, npage)`，伙伴通过物理页号 `ppn XOR (1 << order)` 定位；只有范围有效、设置了 `PageProperty` 且阶数相同的块才能合并。

- `libs/list.h` 提供链表操作；页面标志和引用计数通过项目已有接口维护。复制链表头不会自动修复首尾节点的链接，恢复空表与非空表必须分别处理。暂时隔离真实链表时，还需清除其块首页的 `PageProperty`，防止测试区误将其识别为可合并伙伴；结束后必须恢复。

- `buddy_system_pmm_manager` 的 `.check` 绑定 `buddy_check()`。`pmm_init()` 完成 `page_init()` 后，`check_alloc_page()` 调用该回调，回调返回后才输出 `check_alloc_page() succeeded!`。

- 项目提供 `assert()` 和 `cprintf()`；测试运行于内核启动阶段，不能假设有足够的空闲页或一定存在完整的 16 页块。当前实验为串行环境，不要求并发压力测试。

## [GUARANTEE]

在 `kern/mm/buddy_system_pmm.c` 中实现或完善以下内部测试接口，可增加必要的 `static` 测试辅助函数：

```c
static void buddy_check_lists(void);
static void buddy_check(void);
```

`buddy_check_lists()` 负责空闲链表不变量检查；`buddy_check()` 负责在预留隔离区中执行分配、释放和合并用例，随后恢复真实管理器状态。保留 `buddy_system_pmm_manager.check` 对 `buddy_check()` 的现有绑定，不增加公共接口或额外启动调用。

## [SPECIFICATION]

### buddy_check_lists(void)

**Pre-Condition**：各阶空闲链表和 `buddy_nr_free` 已初始化；链表结构可遍历。

**Post-Condition**：检查通过时，每个节点均为设置了 `PageProperty` 的空闲块首页，其 `property` 与所在阶数一致，物理页号按 `2^order` 对齐；所有块表示的页数总和等于 `buddy_nr_free`，不存在仍可合并的同阶空闲伙伴。检查本身不修改管理器状态。

**Case 1：块描述与对齐**：逐阶遍历链表，断言块首页标志、记录阶数和物理页号对齐均正确。

**Case 2：空闲总量**：累计每个块的实际页数，与 `buddy_nr_free` 比较，发现拆分、分配或释放中遗漏的计数更新。

**Case 3：伙伴合并不变量**：在未到最大阶时，按物理页号异或查找伙伴；若伙伴处于可管理范围，断言不存在另一个同阶空闲伙伴仍未合并。

**Requirements**：本函数检查当前实现可核对的不变量，不得仅凭链表总页数一致就宣称已经验证所有空闲区间互不重叠或完成任意输入的边界测试。

### buddy_check(void)

**Pre-Condition**：Buddy 已完成初始化和空闲区登记；真实空闲链表及计数有效；测试开始时没有其他并发分配操作。

**Post-Condition**：所有可执行断言通过后，测试区之外的空闲链表、页面标志和计数恢复，预留块已经归还，最终空闲页数等于测试前的值。测试不留下已分配页，也不破坏后续内核运行。

**Case 1：初始检查与资源条件**：先调用 `buddy_check_lists()`，记录初始空闲页数。若空闲页数少于 16，允许跳过隔离用例并保持状态不变；否则申请一个完整的 16 页块，并断言预留成功。空闲总数不少于 16 不能单独保证申请成功，缺少连续块时不得报告后续用例已执行。

**Case 2：隔离真实状态**：预留成功后，保存各阶真实链表头和此时的空闲计数，暂时清除真实空闲块首页标志并清空测试用链表。将计数置零，再通过 `buddy_free_pages(arena, 16)` 把预留区变为唯一的空闲块；断言隔离区共有 16 页。隔离操作不得把其他真实空闲页合并进测试区。

**Case 3：超额请求与单页拆分**：隔离区请求 17 页返回 `NULL`，页数保持 16。申请 1 页应返回隔离区首页，空闲页数减为 15；检查拆分后的链表不变量。释放该页后，页数恢复 16，并重新合并为 4 阶块。

**Case 4：非二次幂请求**：申请 3 页应返回隔离区首页，实际消耗 4 页，空闲页数减为 12；按 3 页参数释放后，完整 4 页被归还，空闲页数恢复 16，链表不变量再次成立。

**Case 5：耗尽与逐步合并**：申请两个 8 页块，分别返回隔离区左、右半块，此时空闲页数为零，再申请 1 页失败。只释放右半块后，空闲页数为 8，申请 9 页仍失败；释放左半块后，页数恢复 16，两半合并为完整块。

**Case 6：恢复真实管理器**：移除隔离链表中的测试块，恢复其分配阶数；恢复保存的各阶链表头，并分别重建空表自循环或非空表首尾节点与表头的双向链接。恢复真实空闲块首页标志和预留后的计数，再正常释放原预留的 16 页块。最后调用 `buddy_check_lists()`，断言最终空闲页数等于测试前记录。

**Requirements**：资源不足导致的分配失败不得改变现有状态；测试只释放自己持有的分配块。任意未对齐起点的合成 `init_memmap()` 测试、随机压力、非法释放和并发场景不属于上述用例；报告不得把这些未执行场景写成已通过。

### 构建与运行验证

**Pre-Condition**：已安装工程要求的 RISC-V 交叉编译器、GNU Make 和 QEMU，当前构建选择 Buddy。

**Post-Condition**：记录实际构建和运行结果；内核启动时应输出 `memory management: buddy_system_pmm_manager`，自检成功返回后输出 `check_alloc_page() succeeded!`。

**Case 1：默认内存**：在 `lab2/` 中干净构建并以默认 128 MiB 内存启动，保存管理器名称、物理内存范围、检查结果及异常输出。

**Case 2：非二次幂内存**：使用同一镜像以 127 MiB 启动，核对设备树探测范围和自检结果，用于检查实际初始化区间变化下的行为；该运行不能替代任意区间起点的单元测试。

**Requirements**：使用实际可用的工具路径并原样记录命令。若使用超时命令结束内核空闲循环，应说明终止信号来自演示命令；不得把仅适用于 Page Init、Best-Fit 的 `make grade` 分数作为 Buddy 的评分结果。

<!-- END PROMPT: lab2_buddy_test_prompt.md -->

---


<!-- BEGIN PROMPT: lab2-slub-prompt.md -->
# Lab2 功能模块二扩展任务：SLUB 内存对象分配

## [PROMPT]

**任务**：在当前 `lab2/` 工程中，从零实现一个简化的 SLUB 内存对象分配模块并接入现有内核。新增 `kern/mm/slub.c` 实现模块，新增 `kern/mm/slub.h` 声明模块接口，并在 `kern/init/init.c` 中完成初始化接入。实现 SLUB 的两层结构：第一层通过现有物理页分配接口申请和归还页面，第二层在页面内部组织可复用的对象槽，支持不同正字节数的对象分配和释放。允许简化实现，算法的时间和空间复杂度不作要求，但必须体现页面层和对象层的分工。

当前 `pmm.c` 已选择 `buddy_system_pmm_manager`。SLUB 只能通过 `pmm.h` 中的公共页接口获取和释放页面，不得直接调用 Buddy 的内部函数、访问 Buddy 的空闲链表或依赖 Best-Fit 的内部状态。

**操作要求**：必须直接修改项目中的实际文件，保留现有代码并采用最小改动。不得修改 `buddy_system_pmm.c/.h`、`best_fit_pmm.c/.h`、`pmm.h`、`struct Page`、当前 `pmm_manager` 的选择、公共页分配接口或已有测试函数。不得使用宿主机 `malloc`、`free` 或项目中不存在的内核堆接口。SLUB 的内部元数据必须由 SLUB 自己管理，不能占用 `struct Page` 的 `property`、`flags` 或 `page_link` 字段。现有 Makefile 会自动编译 `kern/mm` 目录下的 C 文件，新增 `slub.c` 不应要求修改 Makefile。本份 prompt 只用于生成 SLUB 实现和初始化接入，不添加 SLUB 测试函数；测试函数由第二份 prompt 单独设计。

**输出要求**：直接完成文件操作，并说明新增接口、页面与对象的组织方式、元数据生命周期、Buddy 接口兼容方式和初始化接入位置。严格以当前工程真实代码为准，不引入 SLUB 之外的功能，不把本 prompt 选定的文件名或接口误称为指导书强制规定的内容；如果进行了构建或测试，准确报告命令和结果。

## [RELY]

- `kern/mm/pmm.h` 提供当前唯一的公共页分配接口：

```c
struct Page *alloc_pages(size_t n);
void free_pages(struct Page *base, size_t n);
size_t nr_free_pages(void);
#define alloc_page() alloc_pages(1)
#define free_page(page) free_pages(page, 1)
```

  `alloc_pages(n)` 返回 `struct Page *` 页描述符，失败返回 `NULL`；它不是可直接访问的页面数据地址。`free_pages(base, n)` 的 `base` 必须是对应分配返回的首页描述符。

- 当前 `pmm.c` 的 `pmm_manager` 是 `buddy_system_pmm_manager`。Buddy 将请求页数向上取整为 2 的幂次页块，返回块首页，并在该首页的 `property` 中记录块阶数；释放时根据首页记录的阶数归还完整伙伴块。因此，SLUB 必须保存自己的实际占用页数和页面类型；释放页面时必须传递与底层分配契合的页数，并且不能清除、改写或依赖 Buddy 的 `Page` 状态字段。SLUB 若采用单页小对象 slab，可固定调用 `alloc_pages(1)`/`free_pages(page, 1)`；大对象路径应申请 2 的幂次页块并保存该申请阶数，释放时使用同一页块大小。

- `kern/mm/mmu.h` 提供 `PGSIZE`、`PGSHIFT` 等页面常量；`kern/mm/pmm.h` 提供 `page2pa(struct Page *page)`、`pa2page(uintptr_t pa)` 和全局 `va_pa_offset`。当前直接映射关系是：内核虚拟地址等于物理地址加 `va_pa_offset`。应通过 `page2pa(page) + va_pa_offset` 将页描述符转换为可访问的内核虚拟地址，不能把 `struct Page *` 当作页面数据地址，也不能假定工程存在 `KADDR` 宏。

- `struct Page` 位于 `kern/mm/memlayout.h`，字段为 `ref`、`flags`、`property`、`page_link`，由底层页分配器维护。SLUB 不得向其中添加字段或借用其中字段保存 slab、对象大小、位图、分配类型等信息。SLUB 元数据必须放在 SLUB 自己持有的页面中；例如可以在每个 slab 的首部保存 magic、类型、对象大小、对象数量、空闲数量、底层页阶数和对象位图。

- `libs/defs.h` 提供 `size_t`、`uintptr_t`、`NULL` 等定义；`libs/list.h` 提供链表操作。实现可以采用静态的 slab 管理链表或页面内位图，但不得通过动态宿主机内存创建管理结构。

- `kern/init/init.c` 中 `kern_init()` 先调用 `pmm_init()`，随后进入无限循环。SLUB 初始化必须放在 `pmm_init()` 成功返回之后、原有无限循环之前。不要改变已有物理内存初始化和检查流程。

- 实验指导书明确说明 SLUB 不提供代码框架和测试函数，要求从零生成模块并接入现有内核；测试方案另行设计。无需复现 Linux 完整 SLUB，不要求多核缓存、并发锁、每 CPU slab 或完整缓存着色机制。

## [GUARANTEE]

新增 `kern/mm/slub.h`，声明以下公开接口；在 `kern/mm/slub.c` 实现这些接口及所需的 `static` 辅助函数、内部类型和静态状态：

```c
void slub_init(void);
void *slub_alloc(size_t size);
void slub_free(void *ptr);
```

修改 `kern/init/init.c`：增加 `slub.h` 头文件引用，并在 `pmm_init()` 返回后调用一次 `slub_init()`，保留其余启动逻辑：

```c
int kern_init(void);
```

允许为内部管理增加静态 slab 链表、页面内 header、对象位图和大小分类。不得增加或修改公开的物理页分配接口，不得让 SLUB 初始化依赖 `slub_alloc()`，避免元数据初始化递归。

## [SPECIFICATION]

### slub_init(void)

**Pre-Condition**：`pmm_init()` 已完成，当前页管理器可通过 `alloc_pages()` 和 `free_pages()` 工作；尚未调用 SLUB 分配或释放接口。

**Post-Condition**：SLUB 的所有静态状态和管理链表初始化完成，没有存活对象，也没有因初始化预先占用的页面；后续分配可以按需创建 slab。

**Requirements**：当前实验只要求串行调用，不需要多核同步或中断保护。

### slub_alloc(size_t size)

**Pre-Condition**：已调用 `slub_init()`；`size` 是调用者请求的对象字节数。

**Post-Condition**：成功时返回当前内核地址空间中可直接访问的、至少包含 `size` 字节的对象首地址；地址满足实现选择的基本对齐要求，且不与其他存活对象、页面首部或位图重叠。对象内容不要求清零。失败时返回 `NULL`，已有对象和所有 SLUB 元数据保持有效，不留下未登记的底层页面。

**Case 1：零大小与溢出**：`size == 0` 时返回 `NULL` 且不改变状态。计算对象槽大小、首部、位图或页数发生整数溢出，或者所需页块超过可申请范围时返回 `NULL`。

**Case 2：小对象 slab**：对不超过实现规定上限的请求，选择合适的大小类别或按对齐后的对象大小建立 slab。一个 slab 必须在同一页或同一底层页块中包含多个可复用对象槽；优先复用已有 slab 的空闲槽，只有没有可用槽时才通过 `alloc_pages()` 建立新的 slab。页面首部、位图和对齐填充必须计入可用容量，任何槽都不能越过所属页块边界。

**Case 3：大对象**：对超过小对象上限的请求，申请足够的连续 2 的幂次页块，保存底层页首页、实际申请阶数和对象有效大小等释放所需信息，并从页块中返回满足对齐要求的对象地址。大对象可以独占一个页块，但不能只支持少数固定字节数而拒绝其他本可由页块容纳的正字节数请求。

**Case 4：复用和底层失败**：已有对象释放后再次分配时，应能复用对应 slab 的空闲槽。底层 `alloc_pages()` 返回 `NULL` 时，返回 `NULL`，不能破坏已有 slab、存活对象或空闲槽状态。

**Requirements**：实现必须明确区分小对象 slab 和大对象页块，并能从 `slub_free()` 收到的原始指针定位其所属元数据。可采用页首 header 加位图等不依赖额外动态内存的方案；返回给调用者的地址不能指向 header 或位图。大小分类、对齐粒度和小对象上限可自行选择，但必须在实现说明中写明。

### slub_free(void *ptr)

**Pre-Condition**：已调用 `slub_init()`；`ptr` 为 `NULL`，或是此前 `slub_alloc()` 成功返回且尚未释放的原始对象指针。不要求支持重复释放、外来指针或对象内部指针。

**Post-Condition**：非空合法指针对应的对象不再存活，其他存活对象和 SLUB 元数据不被破坏；必要时底层页块被完整归还。

**Case 1：空指针**：`ptr == NULL` 时直接返回，不改变任何状态。

**Case 2：小对象释放**：根据对象所属 slab 的元数据定位槽位，将槽位标记为空闲并更新空闲数量。只要 slab 仍有存活对象，就不能归还其底层页。若 slab 完全空闲，则先从 SLUB 管理结构移除，再通过公共 `free_pages()` 归还创建该 slab 时申请的完整页块；归还后不得访问其中的 header、位图或对象。

**Case 3：大对象释放**：从页块首部取得申请阶数和页首页，归还完整的底层 2 的幂次页块；不能只归还请求字节数换算出的部分页面，也不能误释放相邻 slab 或对象。

**Requirements**：释放前必须验证指针属于当前 SLUB 管理的有效槽或大对象范围，并避免重复释放导致计数下溢或链表损坏。若实现选择对非法指针使用断言，应在说明中明确；不要求为未定义输入提供恢复策略。

### `kern_init()` 中的初始化接入

**Pre-Condition**：保留现有 `dtb_init()`、控制台初始化、`pmm_init()` 和物理内存检查流程。

**Post-Condition**：内核完成物理页管理初始化后调用一次 `slub_init()`，随后继续原有无限循环。新增 `slub.c` 通过现有 Makefile 自动参与编译和链接；Buddy 的启动输出和检查行为保持不变。

**Requirements**：本 prompt 不添加 SLUB 测试调用。实现完成后，第二份测试 prompt 再设计测试函数，测试应通过公开的 `slub_alloc/slub_free` 接口验证小对象复用、大对象分配释放、边界值和失败路径。

<!-- END PROMPT: lab2-slub-prompt.md -->

---


<!-- BEGIN PROMPT: lab2-slub-test-prompt.md -->
# Lab2 功能模块二扩展任务：SLUB 测试

## [PROMPT]

**任务**：在当前 `lab2/` 工程中，为已经实现并接入的 SLUB 模块设计并实现测试函数，验证不同大小内存对象的分配、访问、复用和释放。测试必须通过 SLUB 的公开接口进行，不得直接访问 SLUB 的内部结构、静态变量、页面首部或位图。测试应接入现有内核启动流程，在 `slub_init()` 成功完成后执行一次，并在测试结束后恢复底层物理页分配器的状态。

**操作要求**：必须在项目中修改实际文件。保留现有 SLUB 实现和 Buddy 实现，只增加测试所需的最小代码。可以在 `kern/mm/slub.c` 中增加 `slub_check()`，也可以新增 `kern/mm/slub_test.c`；公开声明放在 `kern/mm/slub.h`。只允许通过 `slub_alloc(size_t)` 和 `slub_free(void *)` 测试对象分配与释放，不得调用 `alloc_pages()`、`free_pages()` 来代替 SLUB 测试，不得修改 Buddy 的内部代码和已有 Buddy 测试。不得修改已有 Best-Fit 测试函数。测试失败时使用工程已有的 `assert()` 机制报告错误，不能静默跳过失败情况。

**输出要求**：直接完成文件操作，并说明每组测试覆盖的行为、选择的边界值、测试前后空闲页状态如何恢复，以及测试如何证明对象之间没有重叠。测试代码应与当前 `buddy_system_pmm_manager` 和现有启动链路兼容。以当前工程真实接口和实现为准，不引入与 SLUB 无关的功能；如进行了构建或运行，准确报告命令和结果。

## [RELY]

- `kern/mm/slub.h` 提供待测公开接口：

```c
void slub_init(void);
void *slub_alloc(size_t size);
void slub_free(void *ptr);
```

  测试可以新增以下公开检查入口：

```c
void slub_check(void);
```

- `kern/mm/pmm.h` 提供状态核对接口：

```c
size_t nr_free_pages(void);
```

  测试可以在开始时保存空闲页数，在所有对象释放后断言恢复原值。测试不得依赖某个具体的页分配算法内部链表。

- 当前 `pmm.c` 选择 `buddy_system_pmm_manager`。Buddy 对底层页块按 2 的幂次管理；SLUB 测试必须把 SLUB 看作唯一对象分配接口，不对 Buddy 的块阶数或 `struct Page::property` 作断言。

- `kern/init/init.c` 当前顺序为调用 `pmm_init()`，再调用 `slub_init()`，随后进入无限循环。测试入口必须放在 `slub_init()` 返回之后，并且只调用一次。保留 `pmm_init()` 已有的页管理检查和 Buddy 检查输出。

- `libs/defs.h` 提供 `size_t`、`uintptr_t` 和 `NULL`；工程可用 `assert()`。对象返回地址是当前内核可访问的地址，测试可以将其转换为 `unsigned char *` 后读写请求范围内的字节。

- 指导书要求测试“不同大小内存对象的分配和释放”，并在报告中说明测试覆盖的核心行为和边界情况。测试实现不要求复现 Linux SLUB 的全部内部机制。

## [GUARANTEE]

在 `kern/mm/slub.h` 中声明：

```c
void slub_check(void);
```

在 `kern/mm/slub.c` 或新增的 `kern/mm/slub_test.c` 中实现：

```c
void slub_check(void);
```

修改 `kern/init/init.c` 的 `kern_init()`：在现有 `slub_init()` 调用成功返回后调用一次：

```c
int kern_init(void);
```

允许增加 `static` 测试辅助函数、测试数组和测试记录结构。测试辅助状态应在 `slub_check()` 返回前释放或恢复，不得依赖测试数据在函数返回后继续存在。不得修改 SLUB 的公开分配接口语义，不得添加宿主机测试代码代替内核测试。

## [SPECIFICATION]

### slub_check(void)

**Pre-Condition**：`pmm_init()` 和 `slub_init()` 已成功完成；当前没有其他测试对象占用 SLUB 资源；底层页管理器可以正常报告空闲页数。

**Post-Condition**：所有测试断言通过后返回；测试期间创建的每个对象都已经通过 `slub_free()` 释放；`nr_free_pages()` 恢复到测试开始时保存的值；SLUB 中不残留测试对象或测试专用 slab。测试失败时触发断言并停止内核，不能返回一个未验证的成功结果。

**Case 1：零大小和空指针**：调用 `slub_alloc(0)`，断言返回 `NULL` 且空闲页数不变；调用 `slub_free(NULL)`，断言不改变空闲页数。该组验证无效大小和空指针释放的边界行为。

**Case 2：小对象分配与写入**：至少测试大小 `1`、`7`、`8`、`15`、`16`、`64`、`128` 和 `256` 字节。对每个成功返回的对象，在请求范围内写入唯一字节模式并读回，断言数据保持一致；保存所有指针并两两断言对象有效区间不重叠。测试应同时申请多个相同大小的小对象，以验证一个 slab 中多个槽位的分配，而不是只申请一个对象。

**Case 3：小对象释放与复用**：释放一部分小对象，记录仍存活对象的数据并再次申请相同或相近大小的对象；断言新对象可访问、与仍存活对象不重叠，并确认仍存活对象的数据未被破坏。随后释放全部小对象，验证完整释放路径。不要断言复用必须返回某个固定地址，只验证复用后的行为和状态正确。

**Case 4：大对象与页面边界**：至少测试一个大于小对象上限的大小、一个恰好跨越页面可用范围的大小，以及一个跨越页面边界的大小，例如 `257`、`PGSIZE` 和 `PGSIZE + 1`；根据实际实现允许的上限选择其他安全大小。对每个成功对象写入并读回请求范围内的首字节、中间字节和末字节，断言不同大对象的有效区间不重叠。大对象释放必须通过 `slub_free()` 完成，测试不得直接释放其底层页面。

**Case 5：混合分配和失败路径**：交错申请小对象和大对象，保持一部分对象存活，同时释放另一部分，再申请新对象，验证不同类型对象的生命周期互不破坏。可以尝试一个明显超过当前可用物理内存的请求，断言返回 `NULL` 且已有对象和空闲页计数保持有效；如果该请求会触发实现未定义的整数范围，必须在测试前排除并说明原因。失败路径不能要求系统预留固定数量页面。

**Case 6：完整清理**：按照记录的原始指针释放所有仍存活的测试对象，包括小对象和大对象。释放后断言 `nr_free_pages()` 等于测试开始时保存的值，并再次调用一个小对象分配和释放的成功路径，确认测试清理没有破坏 SLUB 的后续使用。最后再次核对空闲页数恢复到保存值。

**Requirements**：

- 测试必须使用原始指针调用 `slub_free()`，不能传入对象内部地址；测试不要求验证未定义的重复释放或外来指针。
- 测试不得依赖对象内容初始为零；所有读回断言只能检查测试自己写入的字节。
- 测试数组和对象数量应与当前内核可用内存相称，不能一次性消耗全部物理内存而使其他启动检查失效。
- 测试应能在当前 Buddy 作为底层页分配器时运行；不得假定 `alloc_pages(n)` 返回恰好 `n` 页或直接访问 Buddy 的内部状态。
- 测试输出可以在 `slub_check()` 开始和成功结束时使用 `cprintf()`，但成功与否必须由断言和内核控制流保证。不得修改已有 `check_alloc_page()` 的行为。

<!-- END PROMPT: lab2-slub-test-prompt.md -->