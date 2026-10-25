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