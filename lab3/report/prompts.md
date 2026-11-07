# 操作系统Lab3 Prompt

## 模块一 Trap 上下文恢复与 Trap 入口功能

【Prompt 任务说明】

任务详情：本任务为 RISC\-V 64 教学操作系统 ucore lab3 的功能模块一"Trap 上下文恢复与 Trap 入口"。请在 kern/trap/trapentry\.S 中完成两处工作：

\(1\) 定义 RESTORE\_ALL 汇编宏，与文件中已给出的 SAVE\_ALL 宏严格镜像，实现 Trap 上下文的完整恢复；

\(2\) 填充 \_\_alltraps 标签内标有 "lab3: YOUR CODE" 的代码空位，建立汇编入口与 C 语言 Trap 处理函数 trap\(struct trapframe \*tf\) 之间的调用关系。

操作约束：仅允许修改 kern/trap/trapentry\.S 中上述两处位置；禁止修改 SAVE\_ALL 宏、struct trapframe / struct pushregs 结构体定义、trap\(\) 及 trap\_dispatch\(\) 的函数签名、\_\_trapret 标签与 sret 指令、libs/riscv\.h 中任何宏定义；禁止改动文件中已有的其它汇编代码与注释，保持原有底层工程逻辑原样。

输出验证要求：交付代码须使整个工程通过 riscv64\-unknown\-elf\-gcc 编译（汇编阶段无错误、不产生新的警告）；系统运行后应形成"Trap 进入 → SAVE\_ALL 保存 → 进入 trap\(\) → 返回 \_\_trapret → RESTORE\_ALL 恢复 → sret 返回"的完整闭环，中断发生后内核能恢复到被打断前的执行流继续运行，且不破坏内核栈。

【Rely 依赖说明】

实现本功能仅依赖以下最小集合，请首先阅读并严格遵循：

1. kern/trap/trapentry\.S 中已给出的 SAVE\_ALL 宏：它定义了 Trap frame 在栈上的实际内存布局，是本任务全部正确性约束的来源，RESTORE\_ALL 必须与它的保存关系一一对应，不得另行假设布局。

2. kern/trap/trap\.h 中的 struct pushregs 与 struct trapframe：共 36 个 uintptr\_t 字段，依次为 32 个通用寄存器（x0 至 x31）与 4 个 CSR（sstatus、sepc、sbadaddr、scause）。

3. libs/riscv\.h 中的 REGBYTES 常量与 STORE/LOAD 宏（64 位下 REGBYTES 为 8），以及 csrw/csrr/csrrw 等 CSR 指令的用法约束。

4. RISC\-V 调用约定：函数第一个参数经 a0 传递；sp 为栈指针。

5. void trap\(struct trapframe \*tf\) 函数原型（见 trap\.h）：trap\(\) 返回后，控制流必须到达 \_\_trapret。

【Guarantee 接口清单】

必须交付：

1. RESTORE\_ALL 汇编宏：在 trapentry\.S 中 SAVE\_ALL 之后、\_\_alltraps 之前以 \.macro RESTORE\_ALL \.\.\. \.endm 形式定义，供 \_\_trapret 处调用。

2. \_\_alltraps 内 "lab3: YOUR CODE" 空位处的实现代码。
 允许：自行定义仅在本文件内部使用的辅助宏；不允许：新增任何对外可见的符号，不允许修改任何已列出的既有接口。

【Specification 行为规格】

一、RESTORE\_ALL 宏

前置状态：当前 sp 指向 Trap frame 基址，即 SAVE\_ALL 刚执行完毕、栈顶已下移 36\*REGBYTES 个单位，frame 内 36 个槽位均已按 SAVE\_ALL 的保存关系写入。

后置效果（全部须成立）：

1. 处理器通用寄存器 x1 至 x31 恢复为 frame 对应槽位中保存的值；x0 为硬连线零寄存器，无需、也不得写回。

2. CSR 寄存器 sstatus、sepc、sbadaddr、scause 分别恢复为 frame 第 32、33、34、35 槽保存的值。

3. sp 恢复为 Trap 发生前的栈顶值，即 SAVE\_ALL 分配 frame 之前的 sp；恢复完成后栈自然平衡，frame 占用的栈空间视为已弹出，此后不得再对 frame 区域做任何访存。
 顺序约束（违反任一即视为错误）：
 a\. RISC\-V 不存在从内存直接装载到 CSR 的通路，恢复 CSR 必须经过通用寄存器中转再写回；中转寄存器会因此暂时持有垃圾值，故 CSR 恢复操作必须先于全部通用寄存器的恢复完成，否则将破坏已经恢复的现场。
 b\. 恢复 sp 槽（偏移 2\*REGBYTES）的操作必须是最后一次以 Trap frame 基址为地址的访存：该指令执行后 sp 即被改写，此前任何指令不得修改 sp。
 c\. 除上述两条外不对指令序列做其它预设，实现方式由你自行决定，但必须满足全部前置/后置条件。

二、\_\_alltraps 空位处代码

前置状态：SAVE\_ALL 已完整执行，sp 恰好等于当前 Trap frame 的起始地址。

后置效果：

1. 以当前 sp 的值（即 Trap frame 地址）作为唯一参数，按 RISC\-V 调用约定调用 trap\(struct trapframe \*tf\)；trap\(\) 内可见的 tf 指针必须逐位等于调用时的 sp。

2. trap\(\) 返回后，控制流必须到达 \_\_trapret，继而执行 RESTORE\_ALL 与 sret，最终恢复到被打断的执行流。
 场景与边界：本段代码在任何 Trap（时钟中断、断点异常、非法指令异常等）发生时都会执行，与 Trap 类型无关，不得内嵌任何针对特定 Trap 类型的判断逻辑；不得破坏 RESTORE\_ALL 恢复上下文所需的任何信息（含 frame 内容及栈平衡）。

## 模块二 中断与异常处理功能

\[PROMPT\]

**任务**：以 [https://github\.com/roseven\-7/OS\-RISCV\-ucore/tree/lab3](https://github.com/roseven-7/OS-RISCV-ucore/tree/lab3) 为基础，修改 lab3/code/kern/trap/trap\.c，实现功能模块二“中断与异常处理”。本模块对 Trap 入口传入的中断和异常进行分类、输出及必要的状态更新，并与已有 Trap 返回机制衔接。

**操作要求**：必须修改项目中的实际文件。先确认当前分支是 lab3，再阅读 trap\.c、trap\.h、riscv\.h、clock\.h、clock\.c、sbi\.h 和已有评分用例。在 //lab3 function2 YOUR CODE 标记处实现两个处理函数。仅修改 trap\.c，保留函数签名、Trap frame 布局以及其他已有函数的实现；允许增加必要头文件和模块内部宏。无需重做分支中已完成的 Trap 汇编入口和寄存器恢复逻辑。

**输出要求**：使用下面 \[RELY\]、\[GUARANTEE\]、\[SPECIFICATION\] 的信息，以真实源码为准。完成实际文件修改后，编译内核并运行仓库评分用例，报告改动位置和实际测试结果。不能用修改评分脚本或输出虚假 PASS 的方式代替正确实现。

\[RELY\]

**基础版本与目录**：本次基于远端 lab3 分支提交 9a552966b8e506f0d5c7c4151992c6bdb6ae9ec4。仓库根目录下的实际工程位于 lab3/code/。

**宏定义**：libs/riscv\.h 中已有：

```Plain Text
#define IRQ_U_SOFT   0
#define IRQ_S_SOFT   1
#define IRQ_H_SOFT   2
#define IRQ_M_SOFT   3
#define IRQ_U_TIMER  4
#define IRQ_S_TIMER  5
#define IRQ_H_TIMER  6
#define IRQ_M_TIMER  7
#define IRQ_U_EXT    8
#define IRQ_S_EXT    9
#define IRQ_H_EXT    10
#define IRQ_M_EXT    11

#define CAUSE_ILLEGAL_INSTRUCTION 0x2
#define CAUSE_BREAKPOINT          0x3
```

trap\.c 已定义 TICK\_NUM=100。本模块采用 SHUTDOWN\_AFTER=10，含义是累计输出 10 次统计信息后关机。原始分支未定义后一个宏，需在 trap\.c 中补充，不应误认为它已经由头文件提供。

**数据结构**：kern/trap/trap\.h 已定义：

```Plain Text
struct trapframe {
    struct pushregs gpr;
    uintptr_t status;
    uintptr_t epc;
    uintptr_t badvaddr;
    uintptr_t cause;
};
```

struct pushregs 在同一头文件中保存通用寄存器现场。cause 的最高位是中断标志，其余位为原因编号；epc 为 Trap 返回时恢复的执行位置。工程目标为 RV64。

**变量及可用函数**：

```Plain Text
// clock.h
extern volatile size_t ticks;
void clock_set_next_event(void);

// trap.h
void print_trapframe(struct trapframe *tf);

// stdio.h
int cprintf(const char *fmt, ...);

// sbi.h
void sbi_shutdown(void);
```

trap\.c 已有内部函数 static void print\_ticks\(\)：正常构建时输出 100 ticks\\n，定义 DEBUG\_GRADE 时还执行已有测试结束逻辑。必须保留并复用它。

已有 trap\_dispatch\(\) 区分中断和异常；已有 trapentry\.S 从 Trap frame 恢复现场并执行 sret。这些流程无需修改。

\[GUARANTEE\]

必须实现以下两个接口，保留签名和外部可见性：

```Plain Text
void interrupt_handler(struct trapframe *tf);
void exception_handler(struct trapframe *tf);
```

前者完成中断分类、时钟续设、计数、统计输出和条件关机；后者完成异常分类、规定输出和必要的执行位置更新。若新增辅助函数，应声明为 static，且仅服务于本模块。

\[SPECIFICATION\]

### interrupt\_handler

**Pre\-Condition**：

- tf 指向有效的 Trap frame，其原因值可用于中断分类。

- 正常路径由 trap\_dispatch\(\) 调用。评分用例也可能直接传入未携带最高位中断标志的原因编号。

- 监督态时钟中断发生前，框架已经完成时钟初始化，ticks 表示已处理的时钟中断总数。

**Post\-Condition**：

- 当前中断完成规定处理；未触发关机时正常返回统一的 Trap 返回流程。

- 仅监督态时钟中断使 ticks 增加，每次恰好增加 1。

- Trap frame 的执行位置和寄存器现场不被修改。

**Case 1：监督态时钟中断**：原因编号为 IRQ\_S\_TIMER 时，设置下一次时钟事件，并计入本次中断。每当累计次数达到 TICK\_NUM 的整数倍时输出一次统计信息。正常构建下，累计输出达到 SHUTDOWN\_AFTER 次后调用框架关机接口；当前参数对应 1000 次中断、10 次统计输出。未达到关机条件时返回，保证后续仍可接收时钟中断。

**Case 2：其他已列出中断**：当原因编号属于 \[RELY\] 列出的其他软件、时钟或外部中断时，输出相应特权级与中断类型提示后返回。IRQ\_S\_SOFT 的输出必须是 Supervisor software interrupt\\n。这些分支不参与时钟计数和关机判断。

**Case 3：未知中断**：输出 Unknown interrupt: cause \<十进制原因编号\>\\n，再输出完整 Trap frame。输出后返回，保留原返回位置；包括直接传入原因编号 15 的测试情况。

**Requirements**：

- 分类时正确排除原因值最高位的中断标志，保留 RV64 原因编号的完整位宽。

- 每次监督态时钟中断均续设下一次事件，不能只在输出统计信息时续设。

- 复用已有统计输出逻辑，不修改其 DEBUG\_GRADE 分支；该分支触发既有测试结束行为时沿用框架约定。

- 处理函数本身不恢复寄存器或执行 sret，返回后由已有汇编路径完成。

### exception\_handler

**Pre\-Condition**：

- tf 指向有效的 Trap frame，cause 为异常原因。

- 对需要跳过的非法指令和断点，epc 指向可读取、按 2 字节对齐的异常指令起始地址。

- 本实验处理的指令长度范围为 16 位压缩指令和 32 位指令，不要求实现更长指令的解码与恢复。

**Post\-Condition**：

- 非法指令和断点异常输出指定信息，并使返回地址指向触发异常指令的下一条指令。

- 其他异常完成现场输出，返回地址保持不变。

- 除上述两类异常更新 epc 外，不修改其他 Trap frame 字段或时钟计数。

**Case 1：非法指令异常**：原因值为 CAUSE\_ILLEGAL\_INSTRUCTION 时，输出 Illegal instruction at \<原异常地址\>\\n，其中地址使用 %p 格式。随后根据本次指令长度更新返回位置，使返回后不再重复执行同一条非法指令。

**Case 2：断点异常**：原因值为 CAUSE\_BREAKPOINT 时，输出 Breakpoint at \<原断点地址\>\\n，地址使用 %p 格式。正确跳过 16 位 c\.ebreak 或 32 位 ebreak，使返回后继续执行下一条指令。

**Case 3：其他异常**：通过已有接口输出完整 Trap frame。不额外实现恢复逻辑，也不擅自跳过指令；包括直接传入异常原因值 20 的测试情况。

**Requirements**：

- 根据 RISC\-V 编码规则区分本实验使用的 16 位和 32 位指令，分别将返回位置前移 2 或 4 字节，不能统一使用固定偏移。

- 读取编码时支持 32 位指令从仅按 2 字节对齐的地址开始，避免额外引入对齐异常。

- 输出地址必须是更新前的异常指令地址，更新必须作用于当前 Trap frame，以便原有返回流程恢复新的执行位置。

- 仅对要求处理的两类异常跳过指令，其他异常保留原现场。

