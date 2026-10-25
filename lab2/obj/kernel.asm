
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00002517          	auipc	a0,0x2
ffffffffc0200050:	f9c50513          	addi	a0,a0,-100 # ffffffffc0201fe8 <etext+0x2>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0fe000ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00002517          	auipc	a0,0x2
ffffffffc0200066:	fa650513          	addi	a0,a0,-90 # ffffffffc0202008 <etext+0x22>
ffffffffc020006a:	0ea000ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00002597          	auipc	a1,0x2
ffffffffc0200072:	f7858593          	addi	a1,a1,-136 # ffffffffc0201fe6 <etext>
ffffffffc0200076:	00002517          	auipc	a0,0x2
ffffffffc020007a:	fb250513          	addi	a0,a0,-78 # ffffffffc0202028 <etext+0x42>
ffffffffc020007e:	0d6000ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00006597          	auipc	a1,0x6
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0206018 <buddy_areas>
ffffffffc020008a:	00002517          	auipc	a0,0x2
ffffffffc020008e:	fbe50513          	addi	a0,a0,-66 # ffffffffc0202048 <etext+0x62>
ffffffffc0200092:	0c2000ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00006597          	auipc	a1,0x6
ffffffffc020009a:	1e658593          	addi	a1,a1,486 # ffffffffc020627c <end>
ffffffffc020009e:	00002517          	auipc	a0,0x2
ffffffffc02000a2:	fca50513          	addi	a0,a0,-54 # ffffffffc0202068 <etext+0x82>
ffffffffc02000a6:	0ae000ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00006597          	auipc	a1,0x6
ffffffffc02000ae:	5d158593          	addi	a1,a1,1489 # ffffffffc020667b <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00002517          	auipc	a0,0x2
ffffffffc02000d0:	fbc50513          	addi	a0,a0,-68 # ffffffffc0202088 <etext+0xa2>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a8bd                	j	ffffffffc0200154 <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00006517          	auipc	a0,0x6
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0206018 <buddy_areas>
ffffffffc02000e0:	00006617          	auipc	a2,0x6
ffffffffc02000e4:	19c60613          	addi	a2,a2,412 # ffffffffc020627c <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	6e5010ef          	jal	ra,ffffffffc0201fd4 <memset>
    dtb_init();
ffffffffc02000f4:	134000ef          	jal	ra,ffffffffc0200228 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	126000ef          	jal	ra,ffffffffc020021e <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00002517          	auipc	a0,0x2
ffffffffc0200100:	fbc50513          	addi	a0,a0,-68 # ffffffffc02020b8 <etext+0xd2>
ffffffffc0200104:	086000ef          	jal	ra,ffffffffc020018a <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	62f000ef          	jal	ra,ffffffffc0200f3a <pmm_init>
    slub_init();
ffffffffc0200110:	198010ef          	jal	ra,ffffffffc02012a8 <slub_init>
    slub_check();
ffffffffc0200114:	422010ef          	jal	ra,ffffffffc0201536 <slub_check>

    /* do nothing */
    while (1)
ffffffffc0200118:	a001                	j	ffffffffc0200118 <kern_init+0x40>

ffffffffc020011a <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc020011a:	1141                	addi	sp,sp,-16
ffffffffc020011c:	e022                	sd	s0,0(sp)
ffffffffc020011e:	e406                	sd	ra,8(sp)
ffffffffc0200120:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200122:	0fe000ef          	jal	ra,ffffffffc0200220 <cons_putc>
    (*cnt) ++;
ffffffffc0200126:	401c                	lw	a5,0(s0)
}
ffffffffc0200128:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc020012a:	2785                	addiw	a5,a5,1
ffffffffc020012c:	c01c                	sw	a5,0(s0)
}
ffffffffc020012e:	6402                	ld	s0,0(sp)
ffffffffc0200130:	0141                	addi	sp,sp,16
ffffffffc0200132:	8082                	ret

ffffffffc0200134 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200134:	1101                	addi	sp,sp,-32
ffffffffc0200136:	862a                	mv	a2,a0
ffffffffc0200138:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020013a:	00000517          	auipc	a0,0x0
ffffffffc020013e:	fe050513          	addi	a0,a0,-32 # ffffffffc020011a <cputch>
ffffffffc0200142:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200144:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200146:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200148:	277010ef          	jal	ra,ffffffffc0201bbe <vprintfmt>
    return cnt;
}
ffffffffc020014c:	60e2                	ld	ra,24(sp)
ffffffffc020014e:	4532                	lw	a0,12(sp)
ffffffffc0200150:	6105                	addi	sp,sp,32
ffffffffc0200152:	8082                	ret

ffffffffc0200154 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200154:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200156:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc020015a:	8e2a                	mv	t3,a0
ffffffffc020015c:	f42e                	sd	a1,40(sp)
ffffffffc020015e:	f832                	sd	a2,48(sp)
ffffffffc0200160:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200162:	00000517          	auipc	a0,0x0
ffffffffc0200166:	fb850513          	addi	a0,a0,-72 # ffffffffc020011a <cputch>
ffffffffc020016a:	004c                	addi	a1,sp,4
ffffffffc020016c:	869a                	mv	a3,t1
ffffffffc020016e:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200170:	ec06                	sd	ra,24(sp)
ffffffffc0200172:	e0ba                	sd	a4,64(sp)
ffffffffc0200174:	e4be                	sd	a5,72(sp)
ffffffffc0200176:	e8c2                	sd	a6,80(sp)
ffffffffc0200178:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc020017a:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc020017c:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020017e:	241010ef          	jal	ra,ffffffffc0201bbe <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200182:	60e2                	ld	ra,24(sp)
ffffffffc0200184:	4512                	lw	a0,4(sp)
ffffffffc0200186:	6125                	addi	sp,sp,96
ffffffffc0200188:	8082                	ret

ffffffffc020018a <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020018a:	1101                	addi	sp,sp,-32
ffffffffc020018c:	e822                	sd	s0,16(sp)
ffffffffc020018e:	ec06                	sd	ra,24(sp)
ffffffffc0200190:	e426                	sd	s1,8(sp)
ffffffffc0200192:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200194:	00054503          	lbu	a0,0(a0)
ffffffffc0200198:	c51d                	beqz	a0,ffffffffc02001c6 <cputs+0x3c>
ffffffffc020019a:	0405                	addi	s0,s0,1
ffffffffc020019c:	4485                	li	s1,1
ffffffffc020019e:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001a0:	080000ef          	jal	ra,ffffffffc0200220 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001a4:	00044503          	lbu	a0,0(s0)
ffffffffc02001a8:	008487bb          	addw	a5,s1,s0
ffffffffc02001ac:	0405                	addi	s0,s0,1
ffffffffc02001ae:	f96d                	bnez	a0,ffffffffc02001a0 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001b0:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001b4:	4529                	li	a0,10
ffffffffc02001b6:	06a000ef          	jal	ra,ffffffffc0200220 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001ba:	60e2                	ld	ra,24(sp)
ffffffffc02001bc:	8522                	mv	a0,s0
ffffffffc02001be:	6442                	ld	s0,16(sp)
ffffffffc02001c0:	64a2                	ld	s1,8(sp)
ffffffffc02001c2:	6105                	addi	sp,sp,32
ffffffffc02001c4:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001c6:	4405                	li	s0,1
ffffffffc02001c8:	b7f5                	j	ffffffffc02001b4 <cputs+0x2a>

ffffffffc02001ca <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001ca:	00006317          	auipc	t1,0x6
ffffffffc02001ce:	05e30313          	addi	t1,t1,94 # ffffffffc0206228 <is_panic>
ffffffffc02001d2:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d6:	715d                	addi	sp,sp,-80
ffffffffc02001d8:	ec06                	sd	ra,24(sp)
ffffffffc02001da:	e822                	sd	s0,16(sp)
ffffffffc02001dc:	f436                	sd	a3,40(sp)
ffffffffc02001de:	f83a                	sd	a4,48(sp)
ffffffffc02001e0:	fc3e                	sd	a5,56(sp)
ffffffffc02001e2:	e0c2                	sd	a6,64(sp)
ffffffffc02001e4:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001e6:	000e0363          	beqz	t3,ffffffffc02001ec <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001ea:	a001                	j	ffffffffc02001ea <__panic+0x20>
    is_panic = 1;
ffffffffc02001ec:	4785                	li	a5,1
ffffffffc02001ee:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001f2:	8432                	mv	s0,a2
ffffffffc02001f4:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f6:	862e                	mv	a2,a1
ffffffffc02001f8:	85aa                	mv	a1,a0
ffffffffc02001fa:	00002517          	auipc	a0,0x2
ffffffffc02001fe:	ede50513          	addi	a0,a0,-290 # ffffffffc02020d8 <etext+0xf2>
    va_start(ap, fmt);
ffffffffc0200202:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200204:	f51ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200208:	65a2                	ld	a1,8(sp)
ffffffffc020020a:	8522                	mv	a0,s0
ffffffffc020020c:	f29ff0ef          	jal	ra,ffffffffc0200134 <vcprintf>
    cprintf("\n");
ffffffffc0200210:	00002517          	auipc	a0,0x2
ffffffffc0200214:	ea050513          	addi	a0,a0,-352 # ffffffffc02020b0 <etext+0xca>
ffffffffc0200218:	f3dff0ef          	jal	ra,ffffffffc0200154 <cprintf>
ffffffffc020021c:	b7f9                	j	ffffffffc02001ea <__panic+0x20>

ffffffffc020021e <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020021e:	8082                	ret

ffffffffc0200220 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200220:	0ff57513          	zext.b	a0,a0
ffffffffc0200224:	51d0106f          	j	ffffffffc0201f40 <sbi_console_putchar>

ffffffffc0200228 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200228:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc020022a:	00002517          	auipc	a0,0x2
ffffffffc020022e:	ece50513          	addi	a0,a0,-306 # ffffffffc02020f8 <etext+0x112>
void dtb_init(void) {
ffffffffc0200232:	fc86                	sd	ra,120(sp)
ffffffffc0200234:	f8a2                	sd	s0,112(sp)
ffffffffc0200236:	e8d2                	sd	s4,80(sp)
ffffffffc0200238:	f4a6                	sd	s1,104(sp)
ffffffffc020023a:	f0ca                	sd	s2,96(sp)
ffffffffc020023c:	ecce                	sd	s3,88(sp)
ffffffffc020023e:	e4d6                	sd	s5,72(sp)
ffffffffc0200240:	e0da                	sd	s6,64(sp)
ffffffffc0200242:	fc5e                	sd	s7,56(sp)
ffffffffc0200244:	f862                	sd	s8,48(sp)
ffffffffc0200246:	f466                	sd	s9,40(sp)
ffffffffc0200248:	f06a                	sd	s10,32(sp)
ffffffffc020024a:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc020024c:	f09ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200250:	00006597          	auipc	a1,0x6
ffffffffc0200254:	db05b583          	ld	a1,-592(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200258:	00002517          	auipc	a0,0x2
ffffffffc020025c:	eb050513          	addi	a0,a0,-336 # ffffffffc0202108 <etext+0x122>
ffffffffc0200260:	ef5ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200264:	00006417          	auipc	s0,0x6
ffffffffc0200268:	da440413          	addi	s0,s0,-604 # ffffffffc0206008 <boot_dtb>
ffffffffc020026c:	600c                	ld	a1,0(s0)
ffffffffc020026e:	00002517          	auipc	a0,0x2
ffffffffc0200272:	eaa50513          	addi	a0,a0,-342 # ffffffffc0202118 <etext+0x132>
ffffffffc0200276:	edfff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc020027a:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020027e:	00002517          	auipc	a0,0x2
ffffffffc0200282:	eb250513          	addi	a0,a0,-334 # ffffffffc0202130 <etext+0x14a>
    if (boot_dtb == 0) {
ffffffffc0200286:	120a0463          	beqz	s4,ffffffffc02003ae <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc020028a:	57f5                	li	a5,-3
ffffffffc020028c:	07fa                	slli	a5,a5,0x1e
ffffffffc020028e:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200292:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200294:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200298:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020029e:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a2:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002aa:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ae:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002b0:	8ec9                	or	a3,a3,a0
ffffffffc02002b2:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002b6:	1b7d                	addi	s6,s6,-1
ffffffffc02002b8:	0167f7b3          	and	a5,a5,s6
ffffffffc02002bc:	8dd5                	or	a1,a1,a3
ffffffffc02002be:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002c0:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002c4:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002c6:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9c71>
ffffffffc02002ca:	10f59163          	bne	a1,a5,ffffffffc02003cc <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002ce:	471c                	lw	a5,8(a4)
ffffffffc02002d0:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002d2:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d4:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d8:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002dc:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e0:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e4:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e8:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ec:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f0:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f4:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f8:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002fc:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002fe:	01146433          	or	s0,s0,a7
ffffffffc0200302:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200306:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020030a:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020030c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200310:	8c49                	or	s0,s0,a0
ffffffffc0200312:	0166f6b3          	and	a3,a3,s6
ffffffffc0200316:	00ca6a33          	or	s4,s4,a2
ffffffffc020031a:	0167f7b3          	and	a5,a5,s6
ffffffffc020031e:	8c55                	or	s0,s0,a3
ffffffffc0200320:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200324:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200326:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200328:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020032a:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020032e:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200330:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200332:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200336:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200338:	00002917          	auipc	s2,0x2
ffffffffc020033c:	e4890913          	addi	s2,s2,-440 # ffffffffc0202180 <etext+0x19a>
ffffffffc0200340:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200342:	4d91                	li	s11,4
ffffffffc0200344:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200346:	00002497          	auipc	s1,0x2
ffffffffc020034a:	e3248493          	addi	s1,s1,-462 # ffffffffc0202178 <etext+0x192>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020034e:	000a2703          	lw	a4,0(s4)
ffffffffc0200352:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200356:	0087569b          	srliw	a3,a4,0x8
ffffffffc020035a:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200362:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200366:	0107571b          	srliw	a4,a4,0x10
ffffffffc020036a:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020036c:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200370:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200374:	8fd5                	or	a5,a5,a3
ffffffffc0200376:	00eb7733          	and	a4,s6,a4
ffffffffc020037a:	8fd9                	or	a5,a5,a4
ffffffffc020037c:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020037e:	09778c63          	beq	a5,s7,ffffffffc0200416 <dtb_init+0x1ee>
ffffffffc0200382:	00fbea63          	bltu	s7,a5,ffffffffc0200396 <dtb_init+0x16e>
ffffffffc0200386:	07a78663          	beq	a5,s10,ffffffffc02003f2 <dtb_init+0x1ca>
ffffffffc020038a:	4709                	li	a4,2
ffffffffc020038c:	00e79763          	bne	a5,a4,ffffffffc020039a <dtb_init+0x172>
ffffffffc0200390:	4c81                	li	s9,0
ffffffffc0200392:	8a56                	mv	s4,s5
ffffffffc0200394:	bf6d                	j	ffffffffc020034e <dtb_init+0x126>
ffffffffc0200396:	ffb78ee3          	beq	a5,s11,ffffffffc0200392 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc020039a:	00002517          	auipc	a0,0x2
ffffffffc020039e:	e5e50513          	addi	a0,a0,-418 # ffffffffc02021f8 <etext+0x212>
ffffffffc02003a2:	db3ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02003a6:	00002517          	auipc	a0,0x2
ffffffffc02003aa:	e8a50513          	addi	a0,a0,-374 # ffffffffc0202230 <etext+0x24a>
}
ffffffffc02003ae:	7446                	ld	s0,112(sp)
ffffffffc02003b0:	70e6                	ld	ra,120(sp)
ffffffffc02003b2:	74a6                	ld	s1,104(sp)
ffffffffc02003b4:	7906                	ld	s2,96(sp)
ffffffffc02003b6:	69e6                	ld	s3,88(sp)
ffffffffc02003b8:	6a46                	ld	s4,80(sp)
ffffffffc02003ba:	6aa6                	ld	s5,72(sp)
ffffffffc02003bc:	6b06                	ld	s6,64(sp)
ffffffffc02003be:	7be2                	ld	s7,56(sp)
ffffffffc02003c0:	7c42                	ld	s8,48(sp)
ffffffffc02003c2:	7ca2                	ld	s9,40(sp)
ffffffffc02003c4:	7d02                	ld	s10,32(sp)
ffffffffc02003c6:	6de2                	ld	s11,24(sp)
ffffffffc02003c8:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003ca:	b369                	j	ffffffffc0200154 <cprintf>
}
ffffffffc02003cc:	7446                	ld	s0,112(sp)
ffffffffc02003ce:	70e6                	ld	ra,120(sp)
ffffffffc02003d0:	74a6                	ld	s1,104(sp)
ffffffffc02003d2:	7906                	ld	s2,96(sp)
ffffffffc02003d4:	69e6                	ld	s3,88(sp)
ffffffffc02003d6:	6a46                	ld	s4,80(sp)
ffffffffc02003d8:	6aa6                	ld	s5,72(sp)
ffffffffc02003da:	6b06                	ld	s6,64(sp)
ffffffffc02003dc:	7be2                	ld	s7,56(sp)
ffffffffc02003de:	7c42                	ld	s8,48(sp)
ffffffffc02003e0:	7ca2                	ld	s9,40(sp)
ffffffffc02003e2:	7d02                	ld	s10,32(sp)
ffffffffc02003e4:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e6:	00002517          	auipc	a0,0x2
ffffffffc02003ea:	d6a50513          	addi	a0,a0,-662 # ffffffffc0202150 <etext+0x16a>
}
ffffffffc02003ee:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003f0:	b395                	j	ffffffffc0200154 <cprintf>
                int name_len = strlen(name);
ffffffffc02003f2:	8556                	mv	a0,s5
ffffffffc02003f4:	367010ef          	jal	ra,ffffffffc0201f5a <strlen>
ffffffffc02003f8:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	4619                	li	a2,6
ffffffffc02003fc:	85a6                	mv	a1,s1
ffffffffc02003fe:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200400:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200402:	3ad010ef          	jal	ra,ffffffffc0201fae <strncmp>
ffffffffc0200406:	e111                	bnez	a0,ffffffffc020040a <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200408:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020040a:	0a91                	addi	s5,s5,4
ffffffffc020040c:	9ad2                	add	s5,s5,s4
ffffffffc020040e:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200412:	8a56                	mv	s4,s5
ffffffffc0200414:	bf2d                	j	ffffffffc020034e <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200416:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020041a:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020041e:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200422:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200426:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042a:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020042e:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200432:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200436:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020043a:	0087979b          	slliw	a5,a5,0x8
ffffffffc020043e:	00eaeab3          	or	s5,s5,a4
ffffffffc0200442:	00fb77b3          	and	a5,s6,a5
ffffffffc0200446:	00faeab3          	or	s5,s5,a5
ffffffffc020044a:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020044c:	000c9c63          	bnez	s9,ffffffffc0200464 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200450:	1a82                	slli	s5,s5,0x20
ffffffffc0200452:	00368793          	addi	a5,a3,3
ffffffffc0200456:	020ada93          	srli	s5,s5,0x20
ffffffffc020045a:	9abe                	add	s5,s5,a5
ffffffffc020045c:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200460:	8a56                	mv	s4,s5
ffffffffc0200462:	b5f5                	j	ffffffffc020034e <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200464:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200468:	85ca                	mv	a1,s2
ffffffffc020046a:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046c:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200470:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200474:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200478:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047c:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200480:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200482:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200486:	0087979b          	slliw	a5,a5,0x8
ffffffffc020048a:	8d59                	or	a0,a0,a4
ffffffffc020048c:	00fb77b3          	and	a5,s6,a5
ffffffffc0200490:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200492:	1502                	slli	a0,a0,0x20
ffffffffc0200494:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200496:	9522                	add	a0,a0,s0
ffffffffc0200498:	2f9010ef          	jal	ra,ffffffffc0201f90 <strcmp>
ffffffffc020049c:	66a2                	ld	a3,8(sp)
ffffffffc020049e:	f94d                	bnez	a0,ffffffffc0200450 <dtb_init+0x228>
ffffffffc02004a0:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200450 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02004a4:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a8:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004ac:	00002517          	auipc	a0,0x2
ffffffffc02004b0:	cdc50513          	addi	a0,a0,-804 # ffffffffc0202188 <etext+0x1a2>
           fdt32_to_cpu(x >> 32);
ffffffffc02004b4:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b8:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004bc:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c0:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004c4:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004cc:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d0:	0187d693          	srli	a3,a5,0x18
ffffffffc02004d4:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d8:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004dc:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e0:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004e4:	010f6f33          	or	t5,t5,a6
ffffffffc02004e8:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004ec:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f4:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f8:	0186f6b3          	and	a3,a3,s8
ffffffffc02004fc:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200500:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200504:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200508:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020050c:	8361                	srli	a4,a4,0x18
ffffffffc020050e:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200512:	0105d59b          	srliw	a1,a1,0x10
ffffffffc0200516:	01e6e6b3          	or	a3,a3,t5
ffffffffc020051a:	00cb7633          	and	a2,s6,a2
ffffffffc020051e:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200522:	0085959b          	slliw	a1,a1,0x8
ffffffffc0200526:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200532:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200536:	0088989b          	slliw	a7,a7,0x8
ffffffffc020053a:	011b78b3          	and	a7,s6,a7
ffffffffc020053e:	005eeeb3          	or	t4,t4,t0
ffffffffc0200542:	00c6e733          	or	a4,a3,a2
ffffffffc0200546:	006c6c33          	or	s8,s8,t1
ffffffffc020054a:	010b76b3          	and	a3,s6,a6
ffffffffc020054e:	00bb7b33          	and	s6,s6,a1
ffffffffc0200552:	01d7e7b3          	or	a5,a5,t4
ffffffffc0200556:	016c6b33          	or	s6,s8,s6
ffffffffc020055a:	01146433          	or	s0,s0,a7
ffffffffc020055e:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200560:	1702                	slli	a4,a4,0x20
ffffffffc0200562:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200564:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200566:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200568:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020056a:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020056e:	0167eb33          	or	s6,a5,s6
ffffffffc0200572:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200574:	be1ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200578:	85a2                	mv	a1,s0
ffffffffc020057a:	00002517          	auipc	a0,0x2
ffffffffc020057e:	c2e50513          	addi	a0,a0,-978 # ffffffffc02021a8 <etext+0x1c2>
ffffffffc0200582:	bd3ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200586:	014b5613          	srli	a2,s6,0x14
ffffffffc020058a:	85da                	mv	a1,s6
ffffffffc020058c:	00002517          	auipc	a0,0x2
ffffffffc0200590:	c3450513          	addi	a0,a0,-972 # ffffffffc02021c0 <etext+0x1da>
ffffffffc0200594:	bc1ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200598:	008b05b3          	add	a1,s6,s0
ffffffffc020059c:	15fd                	addi	a1,a1,-1
ffffffffc020059e:	00002517          	auipc	a0,0x2
ffffffffc02005a2:	c4250513          	addi	a0,a0,-958 # ffffffffc02021e0 <etext+0x1fa>
ffffffffc02005a6:	bafff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005aa:	00002517          	auipc	a0,0x2
ffffffffc02005ae:	c8650513          	addi	a0,a0,-890 # ffffffffc0202230 <etext+0x24a>
        memory_base = mem_base;
ffffffffc02005b2:	00006797          	auipc	a5,0x6
ffffffffc02005b6:	c687bf23          	sd	s0,-898(a5) # ffffffffc0206230 <memory_base>
        memory_size = mem_size;
ffffffffc02005ba:	00006797          	auipc	a5,0x6
ffffffffc02005be:	c767bf23          	sd	s6,-898(a5) # ffffffffc0206238 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005c2:	b3f5                	j	ffffffffc02003ae <dtb_init+0x186>

ffffffffc02005c4 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005c4:	00006517          	auipc	a0,0x6
ffffffffc02005c8:	c6c53503          	ld	a0,-916(a0) # ffffffffc0206230 <memory_base>
ffffffffc02005cc:	8082                	ret

ffffffffc02005ce <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005ce:	00006517          	auipc	a0,0x6
ffffffffc02005d2:	c6a53503          	ld	a0,-918(a0) # ffffffffc0206238 <memory_size>
ffffffffc02005d6:	8082                	ret

ffffffffc02005d8 <buddy_init>:
    return (size_t)1 << order;
}

static void
buddy_init(void) {
    for (unsigned int order = 0; order < BUDDY_MAX_ORDER; order ++) {
ffffffffc02005d8:	00006797          	auipc	a5,0x6
ffffffffc02005dc:	a4078793          	addi	a5,a5,-1472 # ffffffffc0206018 <buddy_areas>
ffffffffc02005e0:	00006717          	auipc	a4,0x6
ffffffffc02005e4:	c3870713          	addi	a4,a4,-968 # ffffffffc0206218 <slub_slabs>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005e8:	e79c                	sd	a5,8(a5)
ffffffffc02005ea:	e39c                	sd	a5,0(a5)
ffffffffc02005ec:	07c1                	addi	a5,a5,16
ffffffffc02005ee:	fee79de3          	bne	a5,a4,ffffffffc02005e8 <buddy_init+0x10>
        list_init(&buddy_areas[order].free_list);
    }
    buddy_nr_free = 0;
ffffffffc02005f2:	00006797          	auipc	a5,0x6
ffffffffc02005f6:	c407b723          	sd	zero,-946(a5) # ffffffffc0206240 <buddy_nr_free>
}
ffffffffc02005fa:	8082                	ret

ffffffffc02005fc <buddy_add_block>:

/* Insert a free block and coalesce all already-free XOR buddies. */
static void
buddy_add_block(struct Page *base, unsigned int order) {
    while (order + 1 < BUDDY_MAX_ORDER) {
ffffffffc02005fc:	0015871b          	addiw	a4,a1,1
ffffffffc0200600:	47fd                	li	a5,31
ffffffffc0200602:	88ba                	mv	a7,a4
ffffffffc0200604:	0ae7ea63          	bltu	a5,a4,ffffffffc02006b8 <buddy_add_block+0xbc>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200608:	00006317          	auipc	t1,0x6
ffffffffc020060c:	c4833303          	ld	t1,-952(t1) # ffffffffc0206250 <pages>
ffffffffc0200610:	00002617          	auipc	a2,0x2
ffffffffc0200614:	6d063603          	ld	a2,1744(a2) # ffffffffc0202ce0 <nbase>
        ppn_t ppn = page2ppn(base);
        ppn_t buddy_ppn = ppn ^ (ppn_t)buddy_block_pages(order);
        if (buddy_ppn < nbase || buddy_ppn >= npage) {
ffffffffc0200618:	00006f17          	auipc	t5,0x6
ffffffffc020061c:	c30f3f03          	ld	t5,-976(t5) # ffffffffc0206248 <npage>
ffffffffc0200620:	00002e97          	auipc	t4,0x2
ffffffffc0200624:	6b0ebe83          	ld	t4,1712(t4) # ffffffffc0202cd0 <error_string+0x38>
    return (size_t)1 << order;
ffffffffc0200628:	4e05                	li	t3,1
    while (order + 1 < BUDDY_MAX_ORDER) {
ffffffffc020062a:	4ffd                	li	t6,31
ffffffffc020062c:	40650733          	sub	a4,a0,t1
ffffffffc0200630:	870d                	srai	a4,a4,0x3
ffffffffc0200632:	03d70733          	mul	a4,a4,t4
ffffffffc0200636:	0005869b          	sext.w	a3,a1
    return (size_t)1 << order;
ffffffffc020063a:	00de17b3          	sll	a5,t3,a3
ffffffffc020063e:	0008859b          	sext.w	a1,a7
ffffffffc0200642:	0015889b          	addiw	a7,a1,1
ffffffffc0200646:	9732                	add	a4,a4,a2
        ppn_t buddy_ppn = ppn ^ (ppn_t)buddy_block_pages(order);
ffffffffc0200648:	8f3d                	xor	a4,a4,a5
            break;
        }
        struct Page *buddy = pages + (buddy_ppn - nbase);
ffffffffc020064a:	40c70833          	sub	a6,a4,a2
ffffffffc020064e:	00281793          	slli	a5,a6,0x2
ffffffffc0200652:	97c2                	add	a5,a5,a6
ffffffffc0200654:	078e                	slli	a5,a5,0x3
ffffffffc0200656:	979a                	add	a5,a5,t1
        if (buddy_ppn < nbase || buddy_ppn >= npage) {
ffffffffc0200658:	02c76a63          	bltu	a4,a2,ffffffffc020068c <buddy_add_block+0x90>
ffffffffc020065c:	03e77863          	bgeu	a4,t5,ffffffffc020068c <buddy_add_block+0x90>
        if (!PageProperty(buddy) || buddy->property != order) {
ffffffffc0200660:	6798                	ld	a4,8(a5)
            break;
        }

        list_del(&buddy->page_link);
        ClearPageProperty(buddy);
ffffffffc0200662:	ffd77813          	andi	a6,a4,-3
        if (!PageProperty(buddy) || buddy->property != order) {
ffffffffc0200666:	8b09                	andi	a4,a4,2
ffffffffc0200668:	c315                	beqz	a4,ffffffffc020068c <buddy_add_block+0x90>
ffffffffc020066a:	4b98                	lw	a4,16(a5)
ffffffffc020066c:	02d71063          	bne	a4,a3,ffffffffc020068c <buddy_add_block+0x90>
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
ffffffffc0200670:	6f94                	ld	a3,24(a5)
ffffffffc0200672:	7398                	ld	a4,32(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200674:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0200676:	e314                	sd	a3,0(a4)
        ClearPageProperty(buddy);
ffffffffc0200678:	0107b423          	sd	a6,8(a5)
        buddy->property = 0;
ffffffffc020067c:	0007a823          	sw	zero,16(a5)
        if (buddy < base) {
ffffffffc0200680:	00a7f363          	bgeu	a5,a0,ffffffffc0200686 <buddy_add_block+0x8a>
ffffffffc0200684:	853e                	mv	a0,a5
    while (order + 1 < BUDDY_MAX_ORDER) {
ffffffffc0200686:	fbf593e3          	bne	a1,t6,ffffffffc020062c <buddy_add_block+0x30>
ffffffffc020068a:	46fd                	li	a3,31
    __list_add(elm, listelm, listelm->next);
ffffffffc020068c:	02069793          	slli	a5,a3,0x20
        }
        order ++;
    }

    base->property = order;
    SetPageProperty(base);
ffffffffc0200690:	6518                	ld	a4,8(a0)
ffffffffc0200692:	01c7d613          	srli	a2,a5,0x1c
ffffffffc0200696:	00006797          	auipc	a5,0x6
ffffffffc020069a:	98278793          	addi	a5,a5,-1662 # ffffffffc0206018 <buddy_areas>
ffffffffc020069e:	97b2                	add	a5,a5,a2
ffffffffc02006a0:	6790                	ld	a2,8(a5)
ffffffffc02006a2:	00276713          	ori	a4,a4,2
ffffffffc02006a6:	e518                	sd	a4,8(a0)
    base->property = order;
ffffffffc02006a8:	c914                	sw	a3,16(a0)
    list_add(&buddy_areas[order].free_list, &base->page_link);
ffffffffc02006aa:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc02006ae:	e218                	sd	a4,0(a2)
ffffffffc02006b0:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc02006b2:	f110                	sd	a2,32(a0)
    elm->prev = prev;
ffffffffc02006b4:	ed1c                	sd	a5,24(a0)
}
ffffffffc02006b6:	8082                	ret
    while (order + 1 < BUDDY_MAX_ORDER) {
ffffffffc02006b8:	86ae                	mv	a3,a1
ffffffffc02006ba:	bfc9                	j	ffffffffc020068c <buddy_add_block+0x90>

ffffffffc02006bc <buddy_nr_free_pages>:
}

static size_t
buddy_nr_free_pages(void) {
    return buddy_nr_free;
}
ffffffffc02006bc:	00006517          	auipc	a0,0x6
ffffffffc02006c0:	b8453503          	ld	a0,-1148(a0) # ffffffffc0206240 <buddy_nr_free>
ffffffffc02006c4:	8082                	ret

ffffffffc02006c6 <buddy_check_lists>:

static void
buddy_check_lists(void) {
ffffffffc02006c6:	1141                	addi	sp,sp,-16
ffffffffc02006c8:	e406                	sd	ra,8(sp)
ffffffffc02006ca:	00006897          	auipc	a7,0x6
ffffffffc02006ce:	b868b883          	ld	a7,-1146(a7) # ffffffffc0206250 <pages>
ffffffffc02006d2:	00002517          	auipc	a0,0x2
ffffffffc02006d6:	60e53503          	ld	a0,1550(a0) # ffffffffc0202ce0 <nbase>
            assert((ppn & (buddy_block_pages(order) - 1)) == 0);
            total += buddy_block_pages(order);

            if (order + 1 < BUDDY_MAX_ORDER) {
                ppn_t buddy_ppn = ppn ^ (ppn_t)buddy_block_pages(order);
                if (buddy_ppn >= nbase && buddy_ppn < npage) {
ffffffffc02006da:	00006f97          	auipc	t6,0x6
ffffffffc02006de:	b6efbf83          	ld	t6,-1170(t6) # ffffffffc0206248 <npage>
ffffffffc02006e2:	00006317          	auipc	t1,0x6
ffffffffc02006e6:	93630313          	addi	t1,t1,-1738 # ffffffffc0206018 <buddy_areas>
    for (unsigned int order = 0; order < BUDDY_MAX_ORDER; order ++) {
ffffffffc02006ea:	4601                	li	a2,0
    size_t total = 0;
ffffffffc02006ec:	4581                	li	a1,0
    return (size_t)1 << order;
ffffffffc02006ee:	4285                	li	t0,1
ffffffffc02006f0:	00002e97          	auipc	t4,0x2
ffffffffc02006f4:	5e0ebe83          	ld	t4,1504(t4) # ffffffffc0202cd0 <error_string+0x38>
            if (order + 1 < BUDDY_MAX_ORDER) {
ffffffffc02006f8:	4f7d                	li	t5,31
    for (unsigned int order = 0; order < BUDDY_MAX_ORDER; order ++) {
ffffffffc02006fa:	02000393          	li	t2,32
    return listelm->next;
ffffffffc02006fe:	00833703          	ld	a4,8(t1)
        for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
ffffffffc0200702:	06670163          	beq	a4,t1,ffffffffc0200764 <buddy_check_lists+0x9e>
    return (size_t)1 << order;
ffffffffc0200706:	00c29833          	sll	a6,t0,a2
            assert((ppn & (buddy_block_pages(order) - 1)) == 0);
ffffffffc020070a:	fff80e13          	addi	t3,a6,-1
            struct Page *page = le2page(le, page_link);
ffffffffc020070e:	fe870793          	addi	a5,a4,-24
ffffffffc0200712:	411787b3          	sub	a5,a5,a7
ffffffffc0200716:	878d                	srai	a5,a5,0x3
ffffffffc0200718:	03d787b3          	mul	a5,a5,t4
            assert(PageProperty(page) && page->property == order);
ffffffffc020071c:	ff073683          	ld	a3,-16(a4)
ffffffffc0200720:	8a89                	andi	a3,a3,2
ffffffffc0200722:	97aa                	add	a5,a5,a0
ffffffffc0200724:	cea5                	beqz	a3,ffffffffc020079c <buddy_check_lists+0xd6>
ffffffffc0200726:	ff872683          	lw	a3,-8(a4)
ffffffffc020072a:	06c69963          	bne	a3,a2,ffffffffc020079c <buddy_check_lists+0xd6>
            assert((ppn & (buddy_block_pages(order) - 1)) == 0);
ffffffffc020072e:	00fe76b3          	and	a3,t3,a5
ffffffffc0200732:	e6c9                	bnez	a3,ffffffffc02007bc <buddy_check_lists+0xf6>
            total += buddy_block_pages(order);
ffffffffc0200734:	95c2                	add	a1,a1,a6
            if (order + 1 < BUDDY_MAX_ORDER) {
ffffffffc0200736:	05e60463          	beq	a2,t5,ffffffffc020077e <buddy_check_lists+0xb8>
                ppn_t buddy_ppn = ppn ^ (ppn_t)buddy_block_pages(order);
ffffffffc020073a:	0107c7b3          	xor	a5,a5,a6
                if (buddy_ppn >= nbase && buddy_ppn < npage) {
ffffffffc020073e:	02a7e063          	bltu	a5,a0,ffffffffc020075e <buddy_check_lists+0x98>
ffffffffc0200742:	01f7fe63          	bgeu	a5,t6,ffffffffc020075e <buddy_check_lists+0x98>
                    struct Page *buddy = pages + (buddy_ppn - nbase);
ffffffffc0200746:	8f89                	sub	a5,a5,a0
ffffffffc0200748:	00279693          	slli	a3,a5,0x2
ffffffffc020074c:	97b6                	add	a5,a5,a3
ffffffffc020074e:	078e                	slli	a5,a5,0x3
ffffffffc0200750:	97c6                	add	a5,a5,a7
                    assert(!PageProperty(buddy) || buddy->property != order);
ffffffffc0200752:	6794                	ld	a3,8(a5)
ffffffffc0200754:	8a89                	andi	a3,a3,2
ffffffffc0200756:	c681                	beqz	a3,ffffffffc020075e <buddy_check_lists+0x98>
ffffffffc0200758:	4b9c                	lw	a5,16(a5)
ffffffffc020075a:	0ac78163          	beq	a5,a2,ffffffffc02007fc <buddy_check_lists+0x136>
ffffffffc020075e:	6718                	ld	a4,8(a4)
        for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
ffffffffc0200760:	fa6717e3          	bne	a4,t1,ffffffffc020070e <buddy_check_lists+0x48>
    for (unsigned int order = 0; order < BUDDY_MAX_ORDER; order ++) {
ffffffffc0200764:	2605                	addiw	a2,a2,1
ffffffffc0200766:	0341                	addi	t1,t1,16
ffffffffc0200768:	f8761be3          	bne	a2,t2,ffffffffc02006fe <buddy_check_lists+0x38>
                }
            }
        }
    }
    assert(total == buddy_nr_free);
ffffffffc020076c:	00006797          	auipc	a5,0x6
ffffffffc0200770:	ad47b783          	ld	a5,-1324(a5) # ffffffffc0206240 <buddy_nr_free>
ffffffffc0200774:	06f59463          	bne	a1,a5,ffffffffc02007dc <buddy_check_lists+0x116>
}
ffffffffc0200778:	60a2                	ld	ra,8(sp)
ffffffffc020077a:	0141                	addi	sp,sp,16
ffffffffc020077c:	8082                	ret
ffffffffc020077e:	6718                	ld	a4,8(a4)
        for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
ffffffffc0200780:	fe6706e3          	beq	a4,t1,ffffffffc020076c <buddy_check_lists+0xa6>
            struct Page *page = le2page(le, page_link);
ffffffffc0200784:	fe870793          	addi	a5,a4,-24
ffffffffc0200788:	411787b3          	sub	a5,a5,a7
ffffffffc020078c:	878d                	srai	a5,a5,0x3
ffffffffc020078e:	03d787b3          	mul	a5,a5,t4
            assert(PageProperty(page) && page->property == order);
ffffffffc0200792:	ff073683          	ld	a3,-16(a4)
ffffffffc0200796:	8a89                	andi	a3,a3,2
ffffffffc0200798:	97aa                	add	a5,a5,a0
ffffffffc020079a:	f6d1                	bnez	a3,ffffffffc0200726 <buddy_check_lists+0x60>
ffffffffc020079c:	00002697          	auipc	a3,0x2
ffffffffc02007a0:	aac68693          	addi	a3,a3,-1364 # ffffffffc0202248 <etext+0x262>
ffffffffc02007a4:	00002617          	auipc	a2,0x2
ffffffffc02007a8:	ad460613          	addi	a2,a2,-1324 # ffffffffc0202278 <etext+0x292>
ffffffffc02007ac:	0a000593          	li	a1,160
ffffffffc02007b0:	00002517          	auipc	a0,0x2
ffffffffc02007b4:	ae050513          	addi	a0,a0,-1312 # ffffffffc0202290 <etext+0x2aa>
ffffffffc02007b8:	a13ff0ef          	jal	ra,ffffffffc02001ca <__panic>
            assert((ppn & (buddy_block_pages(order) - 1)) == 0);
ffffffffc02007bc:	00002697          	auipc	a3,0x2
ffffffffc02007c0:	af468693          	addi	a3,a3,-1292 # ffffffffc02022b0 <etext+0x2ca>
ffffffffc02007c4:	00002617          	auipc	a2,0x2
ffffffffc02007c8:	ab460613          	addi	a2,a2,-1356 # ffffffffc0202278 <etext+0x292>
ffffffffc02007cc:	0a100593          	li	a1,161
ffffffffc02007d0:	00002517          	auipc	a0,0x2
ffffffffc02007d4:	ac050513          	addi	a0,a0,-1344 # ffffffffc0202290 <etext+0x2aa>
ffffffffc02007d8:	9f3ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(total == buddy_nr_free);
ffffffffc02007dc:	00002697          	auipc	a3,0x2
ffffffffc02007e0:	b3c68693          	addi	a3,a3,-1220 # ffffffffc0202318 <etext+0x332>
ffffffffc02007e4:	00002617          	auipc	a2,0x2
ffffffffc02007e8:	a9460613          	addi	a2,a2,-1388 # ffffffffc0202278 <etext+0x292>
ffffffffc02007ec:	0ad00593          	li	a1,173
ffffffffc02007f0:	00002517          	auipc	a0,0x2
ffffffffc02007f4:	aa050513          	addi	a0,a0,-1376 # ffffffffc0202290 <etext+0x2aa>
ffffffffc02007f8:	9d3ff0ef          	jal	ra,ffffffffc02001ca <__panic>
                    assert(!PageProperty(buddy) || buddy->property != order);
ffffffffc02007fc:	00002697          	auipc	a3,0x2
ffffffffc0200800:	ae468693          	addi	a3,a3,-1308 # ffffffffc02022e0 <etext+0x2fa>
ffffffffc0200804:	00002617          	auipc	a2,0x2
ffffffffc0200808:	a7460613          	addi	a2,a2,-1420 # ffffffffc0202278 <etext+0x292>
ffffffffc020080c:	0a800593          	li	a1,168
ffffffffc0200810:	00002517          	auipc	a0,0x2
ffffffffc0200814:	a8050513          	addi	a0,a0,-1408 # ffffffffc0202290 <etext+0x2aa>
ffffffffc0200818:	9b3ff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc020081c <buddy_free_pages>:
buddy_free_pages(struct Page *base, size_t n) {
ffffffffc020081c:	1141                	addi	sp,sp,-16
ffffffffc020081e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200820:	c9c5                	beqz	a1,ffffffffc02008d0 <buddy_free_pages+0xb4>
ffffffffc0200822:	87ae                	mv	a5,a1
    unsigned int order = base->property;
ffffffffc0200824:	490c                	lw	a1,16(a0)
    assert(order < BUDDY_MAX_ORDER);
ffffffffc0200826:	477d                	li	a4,31
ffffffffc0200828:	08b76463          	bltu	a4,a1,ffffffffc02008b0 <buddy_free_pages+0x94>
    return (size_t)1 << order;
ffffffffc020082c:	4605                	li	a2,1
ffffffffc020082e:	00b61633          	sll	a2,a2,a1
    assert(n <= block_pages);
ffffffffc0200832:	04f66f63          	bltu	a2,a5,ffffffffc0200890 <buddy_free_pages+0x74>
    for (struct Page *page = base; page != base + block_pages; page ++) {
ffffffffc0200836:	02800693          	li	a3,40
ffffffffc020083a:	00b696b3          	sll	a3,a3,a1
ffffffffc020083e:	96aa                	add	a3,a3,a0
ffffffffc0200840:	87aa                	mv	a5,a0
        assert(!PageReserved(page) && !PageProperty(page));
ffffffffc0200842:	6798                	ld	a4,8(a5)
ffffffffc0200844:	8b0d                	andi	a4,a4,3
ffffffffc0200846:	e70d                	bnez	a4,ffffffffc0200870 <buddy_free_pages+0x54>
        page->flags = page->property = 0;
ffffffffc0200848:	0007a823          	sw	zero,16(a5)
ffffffffc020084c:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200850:	0007a023          	sw	zero,0(a5)
    for (struct Page *page = base; page != base + block_pages; page ++) {
ffffffffc0200854:	02878793          	addi	a5,a5,40
ffffffffc0200858:	fed795e3          	bne	a5,a3,ffffffffc0200842 <buddy_free_pages+0x26>
    buddy_nr_free += block_pages;
ffffffffc020085c:	00006717          	auipc	a4,0x6
ffffffffc0200860:	9e470713          	addi	a4,a4,-1564 # ffffffffc0206240 <buddy_nr_free>
ffffffffc0200864:	631c                	ld	a5,0(a4)
}
ffffffffc0200866:	60a2                	ld	ra,8(sp)
    buddy_nr_free += block_pages;
ffffffffc0200868:	97b2                	add	a5,a5,a2
ffffffffc020086a:	e31c                	sd	a5,0(a4)
}
ffffffffc020086c:	0141                	addi	sp,sp,16
    buddy_add_block(base, order);
ffffffffc020086e:	b379                	j	ffffffffc02005fc <buddy_add_block>
        assert(!PageReserved(page) && !PageProperty(page));
ffffffffc0200870:	00002697          	auipc	a3,0x2
ffffffffc0200874:	af868693          	addi	a3,a3,-1288 # ffffffffc0202368 <etext+0x382>
ffffffffc0200878:	00002617          	auipc	a2,0x2
ffffffffc020087c:	a0060613          	addi	a2,a2,-1536 # ffffffffc0202278 <etext+0x292>
ffffffffc0200880:	08a00593          	li	a1,138
ffffffffc0200884:	00002517          	auipc	a0,0x2
ffffffffc0200888:	a0c50513          	addi	a0,a0,-1524 # ffffffffc0202290 <etext+0x2aa>
ffffffffc020088c:	93fff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(n <= block_pages);
ffffffffc0200890:	00002697          	auipc	a3,0x2
ffffffffc0200894:	ac068693          	addi	a3,a3,-1344 # ffffffffc0202350 <etext+0x36a>
ffffffffc0200898:	00002617          	auipc	a2,0x2
ffffffffc020089c:	9e060613          	addi	a2,a2,-1568 # ffffffffc0202278 <etext+0x292>
ffffffffc02008a0:	08700593          	li	a1,135
ffffffffc02008a4:	00002517          	auipc	a0,0x2
ffffffffc02008a8:	9ec50513          	addi	a0,a0,-1556 # ffffffffc0202290 <etext+0x2aa>
ffffffffc02008ac:	91fff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(order < BUDDY_MAX_ORDER);
ffffffffc02008b0:	00002697          	auipc	a3,0x2
ffffffffc02008b4:	a8868693          	addi	a3,a3,-1400 # ffffffffc0202338 <etext+0x352>
ffffffffc02008b8:	00002617          	auipc	a2,0x2
ffffffffc02008bc:	9c060613          	addi	a2,a2,-1600 # ffffffffc0202278 <etext+0x292>
ffffffffc02008c0:	08500593          	li	a1,133
ffffffffc02008c4:	00002517          	auipc	a0,0x2
ffffffffc02008c8:	9cc50513          	addi	a0,a0,-1588 # ffffffffc0202290 <etext+0x2aa>
ffffffffc02008cc:	8ffff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(n > 0);
ffffffffc02008d0:	00002697          	auipc	a3,0x2
ffffffffc02008d4:	a6068693          	addi	a3,a3,-1440 # ffffffffc0202330 <etext+0x34a>
ffffffffc02008d8:	00002617          	auipc	a2,0x2
ffffffffc02008dc:	9a060613          	addi	a2,a2,-1632 # ffffffffc0202278 <etext+0x292>
ffffffffc02008e0:	08300593          	li	a1,131
ffffffffc02008e4:	00002517          	auipc	a0,0x2
ffffffffc02008e8:	9ac50513          	addi	a0,a0,-1620 # ffffffffc0202290 <etext+0x2aa>
ffffffffc02008ec:	8dfff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc02008f0 <buddy_alloc_pages>:
    assert(n > 0);
ffffffffc02008f0:	c171                	beqz	a0,ffffffffc02009b4 <buddy_alloc_pages+0xc4>
    if (n > buddy_nr_free) {
ffffffffc02008f2:	00006f17          	auipc	t5,0x6
ffffffffc02008f6:	94ef0f13          	addi	t5,t5,-1714 # ffffffffc0206240 <buddy_nr_free>
ffffffffc02008fa:	000f3e83          	ld	t4,0(t5)
ffffffffc02008fe:	04aee263          	bltu	t4,a0,ffffffffc0200942 <buddy_alloc_pages+0x52>
    unsigned int wanted = 0;
ffffffffc0200902:	4681                	li	a3,0
    return (size_t)1 << order;
ffffffffc0200904:	4785                	li	a5,1
    while (wanted < BUDDY_MAX_ORDER && buddy_block_pages(wanted) < n) {
ffffffffc0200906:	02000713          	li	a4,32
ffffffffc020090a:	a021                	j	ffffffffc0200912 <buddy_alloc_pages+0x22>
        wanted ++;
ffffffffc020090c:	2685                	addiw	a3,a3,1
    while (wanted < BUDDY_MAX_ORDER && buddy_block_pages(wanted) < n) {
ffffffffc020090e:	02e68a63          	beq	a3,a4,ffffffffc0200942 <buddy_alloc_pages+0x52>
    return (size_t)1 << order;
ffffffffc0200912:	00d79833          	sll	a6,a5,a3
    while (wanted < BUDDY_MAX_ORDER && buddy_block_pages(wanted) < n) {
ffffffffc0200916:	fea86be3          	bltu	a6,a0,ffffffffc020090c <buddy_alloc_pages+0x1c>
ffffffffc020091a:	02069793          	slli	a5,a3,0x20
ffffffffc020091e:	01c7d713          	srli	a4,a5,0x1c
ffffffffc0200922:	00005617          	auipc	a2,0x5
ffffffffc0200926:	6f660613          	addi	a2,a2,1782 # ffffffffc0206018 <buddy_areas>
ffffffffc020092a:	9732                	add	a4,a4,a2
ffffffffc020092c:	87b6                	mv	a5,a3
    while (order < BUDDY_MAX_ORDER &&
ffffffffc020092e:	02000593          	li	a1,32
    return list->next == list;
ffffffffc0200932:	00873883          	ld	a7,8(a4)
ffffffffc0200936:	01171863          	bne	a4,a7,ffffffffc0200946 <buddy_alloc_pages+0x56>
        order ++;
ffffffffc020093a:	2785                	addiw	a5,a5,1
    while (order < BUDDY_MAX_ORDER &&
ffffffffc020093c:	0741                	addi	a4,a4,16
ffffffffc020093e:	feb79ae3          	bne	a5,a1,ffffffffc0200932 <buddy_alloc_pages+0x42>
        return NULL;
ffffffffc0200942:	4501                	li	a0,0
}
ffffffffc0200944:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc0200946:	0008b303          	ld	t1,0(a7)
ffffffffc020094a:	0088b583          	ld	a1,8(a7)
    ClearPageProperty(base);
ffffffffc020094e:	ff08b703          	ld	a4,-16(a7)
    struct Page *base = le2page(le, page_link);
ffffffffc0200952:	fe888513          	addi	a0,a7,-24
    prev->next = next;
ffffffffc0200956:	00b33423          	sd	a1,8(t1)
    next->prev = prev;
ffffffffc020095a:	0065b023          	sd	t1,0(a1)
    ClearPageProperty(base);
ffffffffc020095e:	9b75                	andi	a4,a4,-3
ffffffffc0200960:	fee8b823          	sd	a4,-16(a7)
    while (order > wanted) {
ffffffffc0200964:	04f6f163          	bgeu	a3,a5,ffffffffc02009a6 <buddy_alloc_pages+0xb6>
ffffffffc0200968:	37fd                	addiw	a5,a5,-1
ffffffffc020096a:	02079593          	slli	a1,a5,0x20
ffffffffc020096e:	01c5d713          	srli	a4,a1,0x1c
ffffffffc0200972:	963a                	add	a2,a2,a4
        struct Page *right = base + buddy_block_pages(order);
ffffffffc0200974:	02800e13          	li	t3,40
ffffffffc0200978:	a011                	j	ffffffffc020097c <buddy_alloc_pages+0x8c>
ffffffffc020097a:	37fd                	addiw	a5,a5,-1
ffffffffc020097c:	00fe1733          	sll	a4,t3,a5
ffffffffc0200980:	972a                	add	a4,a4,a0
        SetPageProperty(right);
ffffffffc0200982:	670c                	ld	a1,8(a4)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200984:	00863303          	ld	t1,8(a2)
        right->property = order;
ffffffffc0200988:	cb1c                	sw	a5,16(a4)
        SetPageProperty(right);
ffffffffc020098a:	0025e593          	ori	a1,a1,2
ffffffffc020098e:	e70c                	sd	a1,8(a4)
        list_add(&buddy_areas[order].free_list, &right->page_link);
ffffffffc0200990:	01870593          	addi	a1,a4,24
    prev->next = next->prev = elm;
ffffffffc0200994:	00b33023          	sd	a1,0(t1)
ffffffffc0200998:	e60c                	sd	a1,8(a2)
    elm->prev = prev;
ffffffffc020099a:	ef10                	sd	a2,24(a4)
    elm->next = next;
ffffffffc020099c:	02673023          	sd	t1,32(a4)
    while (order > wanted) {
ffffffffc02009a0:	1641                	addi	a2,a2,-16
ffffffffc02009a2:	fcd79ce3          	bne	a5,a3,ffffffffc020097a <buddy_alloc_pages+0x8a>
    buddy_nr_free -= buddy_block_pages(wanted);
ffffffffc02009a6:	410e8833          	sub	a6,t4,a6
    base->property = wanted;
ffffffffc02009aa:	fed8ac23          	sw	a3,-8(a7)
    buddy_nr_free -= buddy_block_pages(wanted);
ffffffffc02009ae:	010f3023          	sd	a6,0(t5)
    return base;
ffffffffc02009b2:	8082                	ret
buddy_alloc_pages(size_t n) {
ffffffffc02009b4:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02009b6:	00002697          	auipc	a3,0x2
ffffffffc02009ba:	97a68693          	addi	a3,a3,-1670 # ffffffffc0202330 <etext+0x34a>
ffffffffc02009be:	00002617          	auipc	a2,0x2
ffffffffc02009c2:	8ba60613          	addi	a2,a2,-1862 # ffffffffc0202278 <etext+0x292>
ffffffffc02009c6:	05800593          	li	a1,88
ffffffffc02009ca:	00002517          	auipc	a0,0x2
ffffffffc02009ce:	8c650513          	addi	a0,a0,-1850 # ffffffffc0202290 <etext+0x2aa>
buddy_alloc_pages(size_t n) {
ffffffffc02009d2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02009d4:	ff6ff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc02009d8 <buddy_check>:

/* Exercise splitting, rounding, exhaustion, and merges at several orders. */
static void
buddy_check(void) {
ffffffffc02009d8:	da010113          	addi	sp,sp,-608
ffffffffc02009dc:	25213023          	sd	s2,576(sp)
    buddy_check_lists();
    size_t saved_nr_free = buddy_nr_free;
ffffffffc02009e0:	00006917          	auipc	s2,0x6
ffffffffc02009e4:	86090913          	addi	s2,s2,-1952 # ffffffffc0206240 <buddy_nr_free>
buddy_check(void) {
ffffffffc02009e8:	23313c23          	sd	s3,568(sp)
ffffffffc02009ec:	24113c23          	sd	ra,600(sp)
ffffffffc02009f0:	24813823          	sd	s0,592(sp)
ffffffffc02009f4:	24913423          	sd	s1,584(sp)
ffffffffc02009f8:	23413823          	sd	s4,560(sp)
ffffffffc02009fc:	23513423          	sd	s5,552(sp)
ffffffffc0200a00:	23613023          	sd	s6,544(sp)
ffffffffc0200a04:	21713c23          	sd	s7,536(sp)
ffffffffc0200a08:	21813823          	sd	s8,528(sp)
ffffffffc0200a0c:	21913423          	sd	s9,520(sp)
    buddy_check_lists();
ffffffffc0200a10:	cb7ff0ef          	jal	ra,ffffffffc02006c6 <buddy_check_lists>
    size_t saved_nr_free = buddy_nr_free;
ffffffffc0200a14:	00093983          	ld	s3,0(s2)
    if (saved_nr_free < 16) {
ffffffffc0200a18:	47bd                	li	a5,15
ffffffffc0200a1a:	0337eb63          	bltu	a5,s3,ffffffffc0200a50 <buddy_check+0x78>
    }
    buddy_nr_free = real_free_after_reserve;
    buddy_free_pages(arena, 16);
    assert(buddy_nr_free == saved_nr_free);
    buddy_check_lists();
}
ffffffffc0200a1e:	25813083          	ld	ra,600(sp)
ffffffffc0200a22:	25013403          	ld	s0,592(sp)
ffffffffc0200a26:	24813483          	ld	s1,584(sp)
ffffffffc0200a2a:	24013903          	ld	s2,576(sp)
ffffffffc0200a2e:	23813983          	ld	s3,568(sp)
ffffffffc0200a32:	23013a03          	ld	s4,560(sp)
ffffffffc0200a36:	22813a83          	ld	s5,552(sp)
ffffffffc0200a3a:	22013b03          	ld	s6,544(sp)
ffffffffc0200a3e:	21813b83          	ld	s7,536(sp)
ffffffffc0200a42:	21013c03          	ld	s8,528(sp)
ffffffffc0200a46:	20813c83          	ld	s9,520(sp)
ffffffffc0200a4a:	26010113          	addi	sp,sp,608
ffffffffc0200a4e:	8082                	ret
    struct Page *arena = buddy_alloc_pages(16);
ffffffffc0200a50:	4541                	li	a0,16
ffffffffc0200a52:	e9fff0ef          	jal	ra,ffffffffc02008f0 <buddy_alloc_pages>
ffffffffc0200a56:	84aa                	mv	s1,a0
    assert(arena != NULL);
ffffffffc0200a58:	1c050463          	beqz	a0,ffffffffc0200c20 <buddy_check+0x248>
ffffffffc0200a5c:	00005417          	auipc	s0,0x5
ffffffffc0200a60:	5bc40413          	addi	s0,s0,1468 # ffffffffc0206018 <buddy_areas>
ffffffffc0200a64:	8a0a                	mv	s4,sp
ffffffffc0200a66:	00005b17          	auipc	s6,0x5
ffffffffc0200a6a:	7b2b0b13          	addi	s6,s6,1970 # ffffffffc0206218 <slub_slabs>
ffffffffc0200a6e:	8652                	mv	a2,s4
ffffffffc0200a70:	8aa2                	mv	s5,s0
ffffffffc0200a72:	86a2                	mv	a3,s0
        saved_heads[order] = buddy_areas[order].free_list;
ffffffffc0200a74:	669c                	ld	a5,8(a3)
ffffffffc0200a76:	6298                	ld	a4,0(a3)
ffffffffc0200a78:	e61c                	sd	a5,8(a2)
ffffffffc0200a7a:	e218                	sd	a4,0(a2)
        for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
ffffffffc0200a7c:	00d78a63          	beq	a5,a3,ffffffffc0200a90 <buddy_check+0xb8>
            ClearPageProperty(le2page(le, page_link));
ffffffffc0200a80:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200a84:	9b75                	andi	a4,a4,-3
ffffffffc0200a86:	fee7b823          	sd	a4,-16(a5)
    return listelm->next;
ffffffffc0200a8a:	679c                	ld	a5,8(a5)
        for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
ffffffffc0200a8c:	fed79ae3          	bne	a5,a3,ffffffffc0200a80 <buddy_check+0xa8>
    elm->prev = elm->next = elm;
ffffffffc0200a90:	e694                	sd	a3,8(a3)
ffffffffc0200a92:	e294                	sd	a3,0(a3)
    for (unsigned int order = 0; order < BUDDY_MAX_ORDER; order ++) {
ffffffffc0200a94:	06c1                	addi	a3,a3,16
ffffffffc0200a96:	0641                	addi	a2,a2,16
ffffffffc0200a98:	fd669ee3          	bne	a3,s6,ffffffffc0200a74 <buddy_check+0x9c>
    buddy_free_pages(arena, 16);
ffffffffc0200a9c:	45c1                	li	a1,16
ffffffffc0200a9e:	8526                	mv	a0,s1
    size_t real_free_after_reserve = buddy_nr_free;
ffffffffc0200aa0:	00093b83          	ld	s7,0(s2)
    buddy_nr_free = 0;
ffffffffc0200aa4:	00005797          	auipc	a5,0x5
ffffffffc0200aa8:	7807be23          	sd	zero,1948(a5) # ffffffffc0206240 <buddy_nr_free>
    buddy_free_pages(arena, 16);
ffffffffc0200aac:	d71ff0ef          	jal	ra,ffffffffc020081c <buddy_free_pages>
    assert(buddy_nr_free == 16);
ffffffffc0200ab0:	00093c83          	ld	s9,0(s2)
ffffffffc0200ab4:	47c1                	li	a5,16
ffffffffc0200ab6:	18fc9563          	bne	s9,a5,ffffffffc0200c40 <buddy_check+0x268>
    assert(buddy_alloc_pages(17) == NULL);
ffffffffc0200aba:	4545                	li	a0,17
ffffffffc0200abc:	e35ff0ef          	jal	ra,ffffffffc02008f0 <buddy_alloc_pages>
ffffffffc0200ac0:	1a051063          	bnez	a0,ffffffffc0200c60 <buddy_check+0x288>
    struct Page *p = buddy_alloc_pages(1);
ffffffffc0200ac4:	4505                	li	a0,1
ffffffffc0200ac6:	e2bff0ef          	jal	ra,ffffffffc02008f0 <buddy_alloc_pages>
    assert(p == arena && buddy_nr_free == 15);
ffffffffc0200aca:	1aa49b63          	bne	s1,a0,ffffffffc0200c80 <buddy_check+0x2a8>
ffffffffc0200ace:	00093703          	ld	a4,0(s2)
ffffffffc0200ad2:	47bd                	li	a5,15
ffffffffc0200ad4:	1af71663          	bne	a4,a5,ffffffffc0200c80 <buddy_check+0x2a8>
    buddy_check_lists();
ffffffffc0200ad8:	befff0ef          	jal	ra,ffffffffc02006c6 <buddy_check_lists>
    buddy_free_pages(p, 1);
ffffffffc0200adc:	4585                	li	a1,1
ffffffffc0200ade:	8526                	mv	a0,s1
ffffffffc0200ae0:	d3dff0ef          	jal	ra,ffffffffc020081c <buddy_free_pages>
    assert(buddy_nr_free == 16);
ffffffffc0200ae4:	00093c03          	ld	s8,0(s2)
ffffffffc0200ae8:	1b9c1c63          	bne	s8,s9,ffffffffc0200ca0 <buddy_check+0x2c8>
    assert(!list_empty(&buddy_areas[4].free_list));
ffffffffc0200aec:	048ab703          	ld	a4,72(s5)
ffffffffc0200af0:	00005797          	auipc	a5,0x5
ffffffffc0200af4:	56878793          	addi	a5,a5,1384 # ffffffffc0206058 <buddy_areas+0x40>
ffffffffc0200af8:	1cf70463          	beq	a4,a5,ffffffffc0200cc0 <buddy_check+0x2e8>
    buddy_check_lists();
ffffffffc0200afc:	bcbff0ef          	jal	ra,ffffffffc02006c6 <buddy_check_lists>
    p = buddy_alloc_pages(3);
ffffffffc0200b00:	450d                	li	a0,3
ffffffffc0200b02:	defff0ef          	jal	ra,ffffffffc02008f0 <buddy_alloc_pages>
    assert(p == arena && buddy_nr_free == 12);
ffffffffc0200b06:	1ca49d63          	bne	s1,a0,ffffffffc0200ce0 <buddy_check+0x308>
ffffffffc0200b0a:	00093703          	ld	a4,0(s2)
ffffffffc0200b0e:	47b1                	li	a5,12
ffffffffc0200b10:	1cf71863          	bne	a4,a5,ffffffffc0200ce0 <buddy_check+0x308>
    buddy_free_pages(p, 3);
ffffffffc0200b14:	458d                	li	a1,3
ffffffffc0200b16:	d07ff0ef          	jal	ra,ffffffffc020081c <buddy_free_pages>
    assert(buddy_nr_free == 16);
ffffffffc0200b1a:	00093783          	ld	a5,0(s2)
ffffffffc0200b1e:	1f879163          	bne	a5,s8,ffffffffc0200d00 <buddy_check+0x328>
    buddy_check_lists();
ffffffffc0200b22:	ba5ff0ef          	jal	ra,ffffffffc02006c6 <buddy_check_lists>
    struct Page *left = buddy_alloc_pages(8);
ffffffffc0200b26:	4521                	li	a0,8
ffffffffc0200b28:	dc9ff0ef          	jal	ra,ffffffffc02008f0 <buddy_alloc_pages>
ffffffffc0200b2c:	8c2a                	mv	s8,a0
    struct Page *right = buddy_alloc_pages(8);
ffffffffc0200b2e:	4521                	li	a0,8
ffffffffc0200b30:	dc1ff0ef          	jal	ra,ffffffffc02008f0 <buddy_alloc_pages>
ffffffffc0200b34:	8aaa                	mv	s5,a0
    assert(left == arena && right == arena + 8);
ffffffffc0200b36:	1f849563          	bne	s1,s8,ffffffffc0200d20 <buddy_check+0x348>
ffffffffc0200b3a:	14048793          	addi	a5,s1,320
ffffffffc0200b3e:	1ef51163          	bne	a0,a5,ffffffffc0200d20 <buddy_check+0x348>
    assert(buddy_nr_free == 0 && buddy_alloc_pages(1) == NULL);
ffffffffc0200b42:	00093783          	ld	a5,0(s2)
ffffffffc0200b46:	1e079d63          	bnez	a5,ffffffffc0200d40 <buddy_check+0x368>
ffffffffc0200b4a:	4505                	li	a0,1
ffffffffc0200b4c:	da5ff0ef          	jal	ra,ffffffffc02008f0 <buddy_alloc_pages>
ffffffffc0200b50:	1e051863          	bnez	a0,ffffffffc0200d40 <buddy_check+0x368>
    buddy_free_pages(right, 8);
ffffffffc0200b54:	45a1                	li	a1,8
ffffffffc0200b56:	8556                	mv	a0,s5
ffffffffc0200b58:	cc5ff0ef          	jal	ra,ffffffffc020081c <buddy_free_pages>
    assert(buddy_nr_free == 8);
ffffffffc0200b5c:	00093703          	ld	a4,0(s2)
ffffffffc0200b60:	47a1                	li	a5,8
ffffffffc0200b62:	1ef71f63          	bne	a4,a5,ffffffffc0200d60 <buddy_check+0x388>
    assert(buddy_alloc_pages(9) == NULL);
ffffffffc0200b66:	4525                	li	a0,9
ffffffffc0200b68:	d89ff0ef          	jal	ra,ffffffffc02008f0 <buddy_alloc_pages>
ffffffffc0200b6c:	20051a63          	bnez	a0,ffffffffc0200d80 <buddy_check+0x3a8>
    buddy_free_pages(left, 8);
ffffffffc0200b70:	45a1                	li	a1,8
ffffffffc0200b72:	8526                	mv	a0,s1
ffffffffc0200b74:	ca9ff0ef          	jal	ra,ffffffffc020081c <buddy_free_pages>
    assert(buddy_nr_free == 16);
ffffffffc0200b78:	00093703          	ld	a4,0(s2)
ffffffffc0200b7c:	47c1                	li	a5,16
ffffffffc0200b7e:	22f71163          	bne	a4,a5,ffffffffc0200da0 <buddy_check+0x3c8>
    buddy_check_lists();
ffffffffc0200b82:	b45ff0ef          	jal	ra,ffffffffc02006c6 <buddy_check_lists>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200b86:	6c94                	ld	a3,24(s1)
ffffffffc0200b88:	7098                	ld	a4,32(s1)
    ClearPageProperty(arena);
ffffffffc0200b8a:	649c                	ld	a5,8(s1)
    prev->next = next;
ffffffffc0200b8c:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0200b8e:	e314                	sd	a3,0(a4)
ffffffffc0200b90:	9bf5                	andi	a5,a5,-3
ffffffffc0200b92:	e49c                	sd	a5,8(s1)
    arena->property = 4;
ffffffffc0200b94:	4791                	li	a5,4
ffffffffc0200b96:	c89c                	sw	a5,16(s1)
        buddy_areas[order].free_list = saved_heads[order];
ffffffffc0200b98:	000a3703          	ld	a4,0(s4)
ffffffffc0200b9c:	008a3783          	ld	a5,8(s4)
ffffffffc0200ba0:	e018                	sd	a4,0(s0)
ffffffffc0200ba2:	e41c                	sd	a5,8(s0)
        if (head->next == head) {
ffffffffc0200ba4:	06878863          	beq	a5,s0,ffffffffc0200c14 <buddy_check+0x23c>
            head->next->prev = head;
ffffffffc0200ba8:	e380                	sd	s0,0(a5)
            head->prev->next = head;
ffffffffc0200baa:	601c                	ld	a5,0(s0)
ffffffffc0200bac:	e780                	sd	s0,8(a5)
    return listelm->next;
ffffffffc0200bae:	641c                	ld	a5,8(s0)
        for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
ffffffffc0200bb0:	00878b63          	beq	a5,s0,ffffffffc0200bc6 <buddy_check+0x1ee>
            SetPageProperty(le2page(le, page_link));
ffffffffc0200bb4:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200bb8:	00276713          	ori	a4,a4,2
ffffffffc0200bbc:	fee7b823          	sd	a4,-16(a5)
ffffffffc0200bc0:	679c                	ld	a5,8(a5)
        for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
ffffffffc0200bc2:	fe8799e3          	bne	a5,s0,ffffffffc0200bb4 <buddy_check+0x1dc>
    for (unsigned int order = 0; order < BUDDY_MAX_ORDER; order ++) {
ffffffffc0200bc6:	0441                	addi	s0,s0,16
ffffffffc0200bc8:	0a41                	addi	s4,s4,16
ffffffffc0200bca:	fd6417e3          	bne	s0,s6,ffffffffc0200b98 <buddy_check+0x1c0>
    buddy_free_pages(arena, 16);
ffffffffc0200bce:	45c1                	li	a1,16
ffffffffc0200bd0:	8526                	mv	a0,s1
    buddy_nr_free = real_free_after_reserve;
ffffffffc0200bd2:	01793023          	sd	s7,0(s2)
    buddy_free_pages(arena, 16);
ffffffffc0200bd6:	c47ff0ef          	jal	ra,ffffffffc020081c <buddy_free_pages>
    assert(buddy_nr_free == saved_nr_free);
ffffffffc0200bda:	00093783          	ld	a5,0(s2)
ffffffffc0200bde:	1f379163          	bne	a5,s3,ffffffffc0200dc0 <buddy_check+0x3e8>
}
ffffffffc0200be2:	25013403          	ld	s0,592(sp)
ffffffffc0200be6:	25813083          	ld	ra,600(sp)
ffffffffc0200bea:	24813483          	ld	s1,584(sp)
ffffffffc0200bee:	24013903          	ld	s2,576(sp)
ffffffffc0200bf2:	23813983          	ld	s3,568(sp)
ffffffffc0200bf6:	23013a03          	ld	s4,560(sp)
ffffffffc0200bfa:	22813a83          	ld	s5,552(sp)
ffffffffc0200bfe:	22013b03          	ld	s6,544(sp)
ffffffffc0200c02:	21813b83          	ld	s7,536(sp)
ffffffffc0200c06:	21013c03          	ld	s8,528(sp)
ffffffffc0200c0a:	20813c83          	ld	s9,520(sp)
ffffffffc0200c0e:	26010113          	addi	sp,sp,608
    buddy_check_lists();
ffffffffc0200c12:	bc55                	j	ffffffffc02006c6 <buddy_check_lists>
    elm->prev = elm->next = elm;
ffffffffc0200c14:	e000                	sd	s0,0(s0)
    for (unsigned int order = 0; order < BUDDY_MAX_ORDER; order ++) {
ffffffffc0200c16:	0441                	addi	s0,s0,16
ffffffffc0200c18:	0a41                	addi	s4,s4,16
ffffffffc0200c1a:	f7641fe3          	bne	s0,s6,ffffffffc0200b98 <buddy_check+0x1c0>
ffffffffc0200c1e:	bf45                	j	ffffffffc0200bce <buddy_check+0x1f6>
    assert(arena != NULL);
ffffffffc0200c20:	00001697          	auipc	a3,0x1
ffffffffc0200c24:	77868693          	addi	a3,a3,1912 # ffffffffc0202398 <etext+0x3b2>
ffffffffc0200c28:	00001617          	auipc	a2,0x1
ffffffffc0200c2c:	65060613          	addi	a2,a2,1616 # ffffffffc0202278 <etext+0x292>
ffffffffc0200c30:	0ba00593          	li	a1,186
ffffffffc0200c34:	00001517          	auipc	a0,0x1
ffffffffc0200c38:	65c50513          	addi	a0,a0,1628 # ffffffffc0202290 <etext+0x2aa>
ffffffffc0200c3c:	d8eff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(buddy_nr_free == 16);
ffffffffc0200c40:	00001697          	auipc	a3,0x1
ffffffffc0200c44:	76868693          	addi	a3,a3,1896 # ffffffffc02023a8 <etext+0x3c2>
ffffffffc0200c48:	00001617          	auipc	a2,0x1
ffffffffc0200c4c:	63060613          	addi	a2,a2,1584 # ffffffffc0202278 <etext+0x292>
ffffffffc0200c50:	0c900593          	li	a1,201
ffffffffc0200c54:	00001517          	auipc	a0,0x1
ffffffffc0200c58:	63c50513          	addi	a0,a0,1596 # ffffffffc0202290 <etext+0x2aa>
ffffffffc0200c5c:	d6eff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(buddy_alloc_pages(17) == NULL);
ffffffffc0200c60:	00001697          	auipc	a3,0x1
ffffffffc0200c64:	76068693          	addi	a3,a3,1888 # ffffffffc02023c0 <etext+0x3da>
ffffffffc0200c68:	00001617          	auipc	a2,0x1
ffffffffc0200c6c:	61060613          	addi	a2,a2,1552 # ffffffffc0202278 <etext+0x292>
ffffffffc0200c70:	0ca00593          	li	a1,202
ffffffffc0200c74:	00001517          	auipc	a0,0x1
ffffffffc0200c78:	61c50513          	addi	a0,a0,1564 # ffffffffc0202290 <etext+0x2aa>
ffffffffc0200c7c:	d4eff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(p == arena && buddy_nr_free == 15);
ffffffffc0200c80:	00001697          	auipc	a3,0x1
ffffffffc0200c84:	76068693          	addi	a3,a3,1888 # ffffffffc02023e0 <etext+0x3fa>
ffffffffc0200c88:	00001617          	auipc	a2,0x1
ffffffffc0200c8c:	5f060613          	addi	a2,a2,1520 # ffffffffc0202278 <etext+0x292>
ffffffffc0200c90:	0cd00593          	li	a1,205
ffffffffc0200c94:	00001517          	auipc	a0,0x1
ffffffffc0200c98:	5fc50513          	addi	a0,a0,1532 # ffffffffc0202290 <etext+0x2aa>
ffffffffc0200c9c:	d2eff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(buddy_nr_free == 16);
ffffffffc0200ca0:	00001697          	auipc	a3,0x1
ffffffffc0200ca4:	70868693          	addi	a3,a3,1800 # ffffffffc02023a8 <etext+0x3c2>
ffffffffc0200ca8:	00001617          	auipc	a2,0x1
ffffffffc0200cac:	5d060613          	addi	a2,a2,1488 # ffffffffc0202278 <etext+0x292>
ffffffffc0200cb0:	0d000593          	li	a1,208
ffffffffc0200cb4:	00001517          	auipc	a0,0x1
ffffffffc0200cb8:	5dc50513          	addi	a0,a0,1500 # ffffffffc0202290 <etext+0x2aa>
ffffffffc0200cbc:	d0eff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(!list_empty(&buddy_areas[4].free_list));
ffffffffc0200cc0:	00001697          	auipc	a3,0x1
ffffffffc0200cc4:	74868693          	addi	a3,a3,1864 # ffffffffc0202408 <etext+0x422>
ffffffffc0200cc8:	00001617          	auipc	a2,0x1
ffffffffc0200ccc:	5b060613          	addi	a2,a2,1456 # ffffffffc0202278 <etext+0x292>
ffffffffc0200cd0:	0d100593          	li	a1,209
ffffffffc0200cd4:	00001517          	auipc	a0,0x1
ffffffffc0200cd8:	5bc50513          	addi	a0,a0,1468 # ffffffffc0202290 <etext+0x2aa>
ffffffffc0200cdc:	ceeff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(p == arena && buddy_nr_free == 12);
ffffffffc0200ce0:	00001697          	auipc	a3,0x1
ffffffffc0200ce4:	75068693          	addi	a3,a3,1872 # ffffffffc0202430 <etext+0x44a>
ffffffffc0200ce8:	00001617          	auipc	a2,0x1
ffffffffc0200cec:	59060613          	addi	a2,a2,1424 # ffffffffc0202278 <etext+0x292>
ffffffffc0200cf0:	0d500593          	li	a1,213
ffffffffc0200cf4:	00001517          	auipc	a0,0x1
ffffffffc0200cf8:	59c50513          	addi	a0,a0,1436 # ffffffffc0202290 <etext+0x2aa>
ffffffffc0200cfc:	cceff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(buddy_nr_free == 16);
ffffffffc0200d00:	00001697          	auipc	a3,0x1
ffffffffc0200d04:	6a868693          	addi	a3,a3,1704 # ffffffffc02023a8 <etext+0x3c2>
ffffffffc0200d08:	00001617          	auipc	a2,0x1
ffffffffc0200d0c:	57060613          	addi	a2,a2,1392 # ffffffffc0202278 <etext+0x292>
ffffffffc0200d10:	0d700593          	li	a1,215
ffffffffc0200d14:	00001517          	auipc	a0,0x1
ffffffffc0200d18:	57c50513          	addi	a0,a0,1404 # ffffffffc0202290 <etext+0x2aa>
ffffffffc0200d1c:	caeff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(left == arena && right == arena + 8);
ffffffffc0200d20:	00001697          	auipc	a3,0x1
ffffffffc0200d24:	73868693          	addi	a3,a3,1848 # ffffffffc0202458 <etext+0x472>
ffffffffc0200d28:	00001617          	auipc	a2,0x1
ffffffffc0200d2c:	55060613          	addi	a2,a2,1360 # ffffffffc0202278 <etext+0x292>
ffffffffc0200d30:	0dc00593          	li	a1,220
ffffffffc0200d34:	00001517          	auipc	a0,0x1
ffffffffc0200d38:	55c50513          	addi	a0,a0,1372 # ffffffffc0202290 <etext+0x2aa>
ffffffffc0200d3c:	c8eff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(buddy_nr_free == 0 && buddy_alloc_pages(1) == NULL);
ffffffffc0200d40:	00001697          	auipc	a3,0x1
ffffffffc0200d44:	74068693          	addi	a3,a3,1856 # ffffffffc0202480 <etext+0x49a>
ffffffffc0200d48:	00001617          	auipc	a2,0x1
ffffffffc0200d4c:	53060613          	addi	a2,a2,1328 # ffffffffc0202278 <etext+0x292>
ffffffffc0200d50:	0dd00593          	li	a1,221
ffffffffc0200d54:	00001517          	auipc	a0,0x1
ffffffffc0200d58:	53c50513          	addi	a0,a0,1340 # ffffffffc0202290 <etext+0x2aa>
ffffffffc0200d5c:	c6eff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(buddy_nr_free == 8);
ffffffffc0200d60:	00001697          	auipc	a3,0x1
ffffffffc0200d64:	75868693          	addi	a3,a3,1880 # ffffffffc02024b8 <etext+0x4d2>
ffffffffc0200d68:	00001617          	auipc	a2,0x1
ffffffffc0200d6c:	51060613          	addi	a2,a2,1296 # ffffffffc0202278 <etext+0x292>
ffffffffc0200d70:	0df00593          	li	a1,223
ffffffffc0200d74:	00001517          	auipc	a0,0x1
ffffffffc0200d78:	51c50513          	addi	a0,a0,1308 # ffffffffc0202290 <etext+0x2aa>
ffffffffc0200d7c:	c4eff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(buddy_alloc_pages(9) == NULL);
ffffffffc0200d80:	00001697          	auipc	a3,0x1
ffffffffc0200d84:	75068693          	addi	a3,a3,1872 # ffffffffc02024d0 <etext+0x4ea>
ffffffffc0200d88:	00001617          	auipc	a2,0x1
ffffffffc0200d8c:	4f060613          	addi	a2,a2,1264 # ffffffffc0202278 <etext+0x292>
ffffffffc0200d90:	0e000593          	li	a1,224
ffffffffc0200d94:	00001517          	auipc	a0,0x1
ffffffffc0200d98:	4fc50513          	addi	a0,a0,1276 # ffffffffc0202290 <etext+0x2aa>
ffffffffc0200d9c:	c2eff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(buddy_nr_free == 16);
ffffffffc0200da0:	00001697          	auipc	a3,0x1
ffffffffc0200da4:	60868693          	addi	a3,a3,1544 # ffffffffc02023a8 <etext+0x3c2>
ffffffffc0200da8:	00001617          	auipc	a2,0x1
ffffffffc0200dac:	4d060613          	addi	a2,a2,1232 # ffffffffc0202278 <etext+0x292>
ffffffffc0200db0:	0e200593          	li	a1,226
ffffffffc0200db4:	00001517          	auipc	a0,0x1
ffffffffc0200db8:	4dc50513          	addi	a0,a0,1244 # ffffffffc0202290 <etext+0x2aa>
ffffffffc0200dbc:	c0eff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(buddy_nr_free == saved_nr_free);
ffffffffc0200dc0:	00001697          	auipc	a3,0x1
ffffffffc0200dc4:	73068693          	addi	a3,a3,1840 # ffffffffc02024f0 <etext+0x50a>
ffffffffc0200dc8:	00001617          	auipc	a2,0x1
ffffffffc0200dcc:	4b060613          	addi	a2,a2,1200 # ffffffffc0202278 <etext+0x292>
ffffffffc0200dd0:	0fa00593          	li	a1,250
ffffffffc0200dd4:	00001517          	auipc	a0,0x1
ffffffffc0200dd8:	4bc50513          	addi	a0,a0,1212 # ffffffffc0202290 <etext+0x2aa>
ffffffffc0200ddc:	beeff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0200de0 <buddy_init_memmap>:
buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc0200de0:	7119                	addi	sp,sp,-128
ffffffffc0200de2:	fc86                	sd	ra,120(sp)
ffffffffc0200de4:	f8a2                	sd	s0,112(sp)
ffffffffc0200de6:	f4a6                	sd	s1,104(sp)
ffffffffc0200de8:	f0ca                	sd	s2,96(sp)
ffffffffc0200dea:	ecce                	sd	s3,88(sp)
ffffffffc0200dec:	e8d2                	sd	s4,80(sp)
ffffffffc0200dee:	e4d6                	sd	s5,72(sp)
ffffffffc0200df0:	e0da                	sd	s6,64(sp)
ffffffffc0200df2:	fc5e                	sd	s7,56(sp)
ffffffffc0200df4:	f862                	sd	s8,48(sp)
ffffffffc0200df6:	f466                	sd	s9,40(sp)
ffffffffc0200df8:	f06a                	sd	s10,32(sp)
ffffffffc0200dfa:	ec6e                	sd	s11,24(sp)
    assert(n > 0);
ffffffffc0200dfc:	0e058d63          	beqz	a1,ffffffffc0200ef6 <buddy_init_memmap+0x116>
    for (struct Page *page = base; page != base + n; page ++) {
ffffffffc0200e00:	00259693          	slli	a3,a1,0x2
ffffffffc0200e04:	96ae                	add	a3,a3,a1
ffffffffc0200e06:	068e                	slli	a3,a3,0x3
ffffffffc0200e08:	96aa                	add	a3,a3,a0
ffffffffc0200e0a:	8b2e                	mv	s6,a1
ffffffffc0200e0c:	8caa                	mv	s9,a0
ffffffffc0200e0e:	87aa                	mv	a5,a0
ffffffffc0200e10:	00d50f63          	beq	a0,a3,ffffffffc0200e2e <buddy_init_memmap+0x4e>
        assert(PageReserved(page));
ffffffffc0200e14:	6798                	ld	a4,8(a5)
ffffffffc0200e16:	8b05                	andi	a4,a4,1
ffffffffc0200e18:	cf5d                	beqz	a4,ffffffffc0200ed6 <buddy_init_memmap+0xf6>
        page->flags = page->property = 0;
ffffffffc0200e1a:	0007a823          	sw	zero,16(a5)
ffffffffc0200e1e:	0007b423          	sd	zero,8(a5)
ffffffffc0200e22:	0007a023          	sw	zero,0(a5)
    for (struct Page *page = base; page != base + n; page ++) {
ffffffffc0200e26:	02878793          	addi	a5,a5,40
ffffffffc0200e2a:	fed795e3          	bne	a5,a3,ffffffffc0200e14 <buddy_init_memmap+0x34>
        buddy_nr_free += block_pages;
ffffffffc0200e2e:	00005417          	auipc	s0,0x5
ffffffffc0200e32:	41240413          	addi	s0,s0,1042 # ffffffffc0206240 <buddy_nr_free>
ffffffffc0200e36:	4a15                	li	s4,5
ffffffffc0200e38:	00043d03          	ld	s10,0(s0)
ffffffffc0200e3c:	022a1793          	slli	a5,s4,0x22
    return (size_t)1 << order;
ffffffffc0200e40:	4b85                	li	s7,1
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200e42:	00002917          	auipc	s2,0x2
ffffffffc0200e46:	e9e93903          	ld	s2,-354(s2) # ffffffffc0202ce0 <nbase>
ffffffffc0200e4a:	00005a97          	auipc	s5,0x5
ffffffffc0200e4e:	406a8a93          	addi	s5,s5,1030 # ffffffffc0206250 <pages>
ffffffffc0200e52:	00002497          	auipc	s1,0x2
ffffffffc0200e56:	e7e4b483          	ld	s1,-386(s1) # ffffffffc0202cd0 <error_string+0x38>
        while (order + 1 < BUDDY_MAX_ORDER) {
ffffffffc0200e5a:	4c7d                	li	s8,31
        page += block_pages;
ffffffffc0200e5c:	02800993          	li	s3,40
ffffffffc0200e60:	e43e                	sd	a5,8(sp)
ffffffffc0200e62:	000ab683          	ld	a3,0(s5)
ffffffffc0200e66:	4701                	li	a4,0
ffffffffc0200e68:	40dc86b3          	sub	a3,s9,a3
ffffffffc0200e6c:	868d                	srai	a3,a3,0x3
ffffffffc0200e6e:	029686b3          	mul	a3,a3,s1
ffffffffc0200e72:	96ca                	add	a3,a3,s2
        while (order + 1 < BUDDY_MAX_ORDER) {
ffffffffc0200e74:	a031                	j	ffffffffc0200e80 <buddy_init_memmap+0xa0>
            if (larger > remaining || (ppn & (larger - 1)) != 0) {
ffffffffc0200e76:	17fd                	addi	a5,a5,-1
ffffffffc0200e78:	8ff5                	and	a5,a5,a3
ffffffffc0200e7a:	eb91                	bnez	a5,ffffffffc0200e8e <buddy_init_memmap+0xae>
        while (order + 1 < BUDDY_MAX_ORDER) {
ffffffffc0200e7c:	05870763          	beq	a4,s8,ffffffffc0200eca <buddy_init_memmap+0xea>
ffffffffc0200e80:	0007059b          	sext.w	a1,a4
ffffffffc0200e84:	2705                	addiw	a4,a4,1
    return (size_t)1 << order;
ffffffffc0200e86:	00eb97b3          	sll	a5,s7,a4
            if (larger > remaining || (ppn & (larger - 1)) != 0) {
ffffffffc0200e8a:	fefb76e3          	bgeu	s6,a5,ffffffffc0200e76 <buddy_init_memmap+0x96>
    return (size_t)1 << order;
ffffffffc0200e8e:	00bb9db3          	sll	s11,s7,a1
        page += block_pages;
ffffffffc0200e92:	00b99a33          	sll	s4,s3,a1
        buddy_add_block(page, order);
ffffffffc0200e96:	8566                	mv	a0,s9
        buddy_nr_free += block_pages;
ffffffffc0200e98:	9d6e                	add	s10,s10,s11
        buddy_add_block(page, order);
ffffffffc0200e9a:	f62ff0ef          	jal	ra,ffffffffc02005fc <buddy_add_block>
        remaining -= block_pages;
ffffffffc0200e9e:	41bb0b33          	sub	s6,s6,s11
        buddy_nr_free += block_pages;
ffffffffc0200ea2:	01a43023          	sd	s10,0(s0)
        page += block_pages;
ffffffffc0200ea6:	9cd2                	add	s9,s9,s4
    while (remaining != 0) {
ffffffffc0200ea8:	fa0b1de3          	bnez	s6,ffffffffc0200e62 <buddy_init_memmap+0x82>
}
ffffffffc0200eac:	70e6                	ld	ra,120(sp)
ffffffffc0200eae:	7446                	ld	s0,112(sp)
ffffffffc0200eb0:	74a6                	ld	s1,104(sp)
ffffffffc0200eb2:	7906                	ld	s2,96(sp)
ffffffffc0200eb4:	69e6                	ld	s3,88(sp)
ffffffffc0200eb6:	6a46                	ld	s4,80(sp)
ffffffffc0200eb8:	6aa6                	ld	s5,72(sp)
ffffffffc0200eba:	6b06                	ld	s6,64(sp)
ffffffffc0200ebc:	7be2                	ld	s7,56(sp)
ffffffffc0200ebe:	7c42                	ld	s8,48(sp)
ffffffffc0200ec0:	7ca2                	ld	s9,40(sp)
ffffffffc0200ec2:	7d02                	ld	s10,32(sp)
ffffffffc0200ec4:	6de2                	ld	s11,24(sp)
ffffffffc0200ec6:	6109                	addi	sp,sp,128
ffffffffc0200ec8:	8082                	ret
ffffffffc0200eca:	4785                	li	a5,1
ffffffffc0200ecc:	6a22                	ld	s4,8(sp)
ffffffffc0200ece:	45fd                	li	a1,31
ffffffffc0200ed0:	01f79d93          	slli	s11,a5,0x1f
ffffffffc0200ed4:	b7c9                	j	ffffffffc0200e96 <buddy_init_memmap+0xb6>
        assert(PageReserved(page));
ffffffffc0200ed6:	00001697          	auipc	a3,0x1
ffffffffc0200eda:	63a68693          	addi	a3,a3,1594 # ffffffffc0202510 <etext+0x52a>
ffffffffc0200ede:	00001617          	auipc	a2,0x1
ffffffffc0200ee2:	39a60613          	addi	a2,a2,922 # ffffffffc0202278 <etext+0x292>
ffffffffc0200ee6:	03d00593          	li	a1,61
ffffffffc0200eea:	00001517          	auipc	a0,0x1
ffffffffc0200eee:	3a650513          	addi	a0,a0,934 # ffffffffc0202290 <etext+0x2aa>
ffffffffc0200ef2:	ad8ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(n > 0);
ffffffffc0200ef6:	00001697          	auipc	a3,0x1
ffffffffc0200efa:	43a68693          	addi	a3,a3,1082 # ffffffffc0202330 <etext+0x34a>
ffffffffc0200efe:	00001617          	auipc	a2,0x1
ffffffffc0200f02:	37a60613          	addi	a2,a2,890 # ffffffffc0202278 <etext+0x292>
ffffffffc0200f06:	03b00593          	li	a1,59
ffffffffc0200f0a:	00001517          	auipc	a0,0x1
ffffffffc0200f0e:	38650513          	addi	a0,a0,902 # ffffffffc0202290 <etext+0x2aa>
ffffffffc0200f12:	ab8ff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0200f16 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0200f16:	00005797          	auipc	a5,0x5
ffffffffc0200f1a:	3427b783          	ld	a5,834(a5) # ffffffffc0206258 <pmm_manager>
ffffffffc0200f1e:	6f9c                	ld	a5,24(a5)
ffffffffc0200f20:	8782                	jr	a5

ffffffffc0200f22 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0200f22:	00005797          	auipc	a5,0x5
ffffffffc0200f26:	3367b783          	ld	a5,822(a5) # ffffffffc0206258 <pmm_manager>
ffffffffc0200f2a:	739c                	ld	a5,32(a5)
ffffffffc0200f2c:	8782                	jr	a5

ffffffffc0200f2e <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc0200f2e:	00005797          	auipc	a5,0x5
ffffffffc0200f32:	32a7b783          	ld	a5,810(a5) # ffffffffc0206258 <pmm_manager>
ffffffffc0200f36:	779c                	ld	a5,40(a5)
ffffffffc0200f38:	8782                	jr	a5

ffffffffc0200f3a <pmm_init>:
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc0200f3a:	00001797          	auipc	a5,0x1
ffffffffc0200f3e:	60e78793          	addi	a5,a5,1550 # ffffffffc0202548 <buddy_system_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200f42:	638c                	ld	a1,0(a5)
        }
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200f44:	7179                	addi	sp,sp,-48
ffffffffc0200f46:	e44e                	sd	s3,8(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200f48:	00001517          	auipc	a0,0x1
ffffffffc0200f4c:	63850513          	addi	a0,a0,1592 # ffffffffc0202580 <buddy_system_pmm_manager+0x38>
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc0200f50:	00005997          	auipc	s3,0x5
ffffffffc0200f54:	30898993          	addi	s3,s3,776 # ffffffffc0206258 <pmm_manager>
void pmm_init(void) {
ffffffffc0200f58:	f406                	sd	ra,40(sp)
ffffffffc0200f5a:	ec26                	sd	s1,24(sp)
ffffffffc0200f5c:	e84a                	sd	s2,16(sp)
ffffffffc0200f5e:	e052                	sd	s4,0(sp)
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc0200f60:	00f9b023          	sd	a5,0(s3)
void pmm_init(void) {
ffffffffc0200f64:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200f66:	9eeff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    pmm_manager->init();
ffffffffc0200f6a:	0009b783          	ld	a5,0(s3)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200f6e:	00005917          	auipc	s2,0x5
ffffffffc0200f72:	30290913          	addi	s2,s2,770 # ffffffffc0206270 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200f76:	679c                	ld	a5,8(a5)
ffffffffc0200f78:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200f7a:	57f5                	li	a5,-3
ffffffffc0200f7c:	07fa                	slli	a5,a5,0x1e
ffffffffc0200f7e:	00f93023          	sd	a5,0(s2)
    mem_base = get_memory_base();
ffffffffc0200f82:	e42ff0ef          	jal	ra,ffffffffc02005c4 <get_memory_base>
ffffffffc0200f86:	84aa                	mv	s1,a0
    mem_size = get_memory_size();
ffffffffc0200f88:	e46ff0ef          	jal	ra,ffffffffc02005ce <get_memory_size>
ffffffffc0200f8c:	8a2a                	mv	s4,a0
    if (mem_base == 0 || mem_size == 0 ||
ffffffffc0200f8e:	12048f63          	beqz	s1,ffffffffc02010cc <pmm_init+0x192>
ffffffffc0200f92:	12050d63          	beqz	a0,ffffffffc02010cc <pmm_init+0x192>
        mem_base + mem_size < mem_base) {  // overflow / wrap-around
ffffffffc0200f96:	00a48433          	add	s0,s1,a0
    if (mem_base == 0 || mem_size == 0 ||
ffffffffc0200f9a:	12946963          	bltu	s0,s1,ffffffffc02010cc <pmm_init+0x192>
    cprintf("physical memory map:\n");
ffffffffc0200f9e:	00001517          	auipc	a0,0x1
ffffffffc0200fa2:	65250513          	addi	a0,a0,1618 # ffffffffc02025f0 <buddy_system_pmm_manager+0xa8>
ffffffffc0200fa6:	9aeff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n",
ffffffffc0200faa:	fff40693          	addi	a3,s0,-1
ffffffffc0200fae:	8626                	mv	a2,s1
ffffffffc0200fb0:	85d2                	mv	a1,s4
ffffffffc0200fb2:	00001517          	auipc	a0,0x1
ffffffffc0200fb6:	65650513          	addi	a0,a0,1622 # ffffffffc0202608 <buddy_system_pmm_manager+0xc0>
ffffffffc0200fba:	99aff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    if (maxpa > PHYSICAL_MEMORY_END) {
ffffffffc0200fbe:	47c5                	li	a5,17
ffffffffc0200fc0:	07ee                	slli	a5,a5,0x1b
ffffffffc0200fc2:	88a2                	mv	a7,s0
ffffffffc0200fc4:	0c87ee63          	bltu	a5,s0,ffffffffc02010a0 <pmm_init+0x166>
    npage = maxpa >> PGSHIFT;
ffffffffc0200fc8:	77fd                	lui	a5,0xfffff
ffffffffc0200fca:	00006617          	auipc	a2,0x6
ffffffffc0200fce:	2b160613          	addi	a2,a2,689 # ffffffffc020727b <end+0xfff>
ffffffffc0200fd2:	8e7d                	and	a2,a2,a5
ffffffffc0200fd4:	00c8d513          	srli	a0,a7,0xc
ffffffffc0200fd8:	00005797          	auipc	a5,0x5
ffffffffc0200fdc:	26a7b823          	sd	a0,624(a5) # ffffffffc0206248 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200fe0:	00005797          	auipc	a5,0x5
ffffffffc0200fe4:	26c7b823          	sd	a2,624(a5) # ffffffffc0206250 <pages>
    if (npage > nbase) {
ffffffffc0200fe8:	000805b7          	lui	a1,0x80
ffffffffc0200fec:	04a5ff63          	bgeu	a1,a0,ffffffffc020104a <pmm_init+0x110>
        n = npage - nbase;
ffffffffc0200ff0:	00251793          	slli	a5,a0,0x2
ffffffffc0200ff4:	97aa                	add	a5,a5,a0
ffffffffc0200ff6:	fec006b7          	lui	a3,0xfec00
ffffffffc0200ffa:	078e                	slli	a5,a5,0x3
ffffffffc0200ffc:	96b2                	add	a3,a3,a2
ffffffffc0200ffe:	96be                	add	a3,a3,a5
ffffffffc0201000:	40b50833          	sub	a6,a0,a1
ffffffffc0201004:	87b2                	mv	a5,a2
            SetPageReserved(pages + i);
ffffffffc0201006:	6798                	ld	a4,8(a5)
        for (i = 0; i < n; i++) {
ffffffffc0201008:	02878793          	addi	a5,a5,40
            SetPageReserved(pages + i);
ffffffffc020100c:	00176713          	ori	a4,a4,1
ffffffffc0201010:	fee7b023          	sd	a4,-32(a5)
        for (i = 0; i < n; i++) {
ffffffffc0201014:	fef699e3          	bne	a3,a5,ffffffffc0201006 <pmm_init+0xcc>
        freemem = PADDR((uintptr_t)pages + n * sizeof(struct Page));
ffffffffc0201018:	00281593          	slli	a1,a6,0x2
ffffffffc020101c:	95c2                	add	a1,a1,a6
ffffffffc020101e:	058e                	slli	a1,a1,0x3
ffffffffc0201020:	00c586b3          	add	a3,a1,a2
ffffffffc0201024:	c02007b7          	lui	a5,0xc0200
ffffffffc0201028:	0ef6e963          	bltu	a3,a5,ffffffffc020111a <pmm_init+0x1e0>
        freemem = ROUNDUP(freemem, PGSIZE);
ffffffffc020102c:	00093703          	ld	a4,0(s2)
ffffffffc0201030:	6585                	lui	a1,0x1
ffffffffc0201032:	15fd                	addi	a1,a1,-1
ffffffffc0201034:	77fd                	lui	a5,0xfffff
ffffffffc0201036:	8d99                	sub	a1,a1,a4
ffffffffc0201038:	95b6                	add	a1,a1,a3
        mem_end = ROUNDDOWN(mem_base + mem_size, PGSIZE);
ffffffffc020103a:	8c7d                	and	s0,s0,a5
ffffffffc020103c:	8dfd                	and	a1,a1,a5
        if (mem_end > maxpa) {
ffffffffc020103e:	0088f463          	bgeu	a7,s0,ffffffffc0201046 <pmm_init+0x10c>
            mem_end = ROUNDDOWN(maxpa, PGSIZE);
ffffffffc0201042:	00f8f433          	and	s0,a7,a5
        if (freemem < mem_end) {
ffffffffc0201046:	0485ef63          	bltu	a1,s0,ffffffffc02010a4 <pmm_init+0x16a>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc020104a:	0009b783          	ld	a5,0(s3)
ffffffffc020104e:	7b9c                	ld	a5,48(a5)
ffffffffc0201050:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201052:	00001517          	auipc	a0,0x1
ffffffffc0201056:	63e50513          	addi	a0,a0,1598 # ffffffffc0202690 <buddy_system_pmm_manager+0x148>
ffffffffc020105a:	8faff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc020105e:	00004597          	auipc	a1,0x4
ffffffffc0201062:	fa258593          	addi	a1,a1,-94 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201066:	00005797          	auipc	a5,0x5
ffffffffc020106a:	20b7b123          	sd	a1,514(a5) # ffffffffc0206268 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020106e:	c02007b7          	lui	a5,0xc0200
ffffffffc0201072:	06f5eb63          	bltu	a1,a5,ffffffffc02010e8 <pmm_init+0x1ae>
ffffffffc0201076:	00093603          	ld	a2,0(s2)
}
ffffffffc020107a:	7402                	ld	s0,32(sp)
ffffffffc020107c:	70a2                	ld	ra,40(sp)
ffffffffc020107e:	64e2                	ld	s1,24(sp)
ffffffffc0201080:	6942                	ld	s2,16(sp)
ffffffffc0201082:	69a2                	ld	s3,8(sp)
ffffffffc0201084:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201086:	40c58633          	sub	a2,a1,a2
ffffffffc020108a:	00005797          	auipc	a5,0x5
ffffffffc020108e:	1cc7bb23          	sd	a2,470(a5) # ffffffffc0206260 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201092:	00001517          	auipc	a0,0x1
ffffffffc0201096:	61e50513          	addi	a0,a0,1566 # ffffffffc02026b0 <buddy_system_pmm_manager+0x168>
}
ffffffffc020109a:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020109c:	8b8ff06f          	j	ffffffffc0200154 <cprintf>
ffffffffc02010a0:	88be                	mv	a7,a5
ffffffffc02010a2:	b71d                	j	ffffffffc0200fc8 <pmm_init+0x8e>
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02010a4:	00c5d793          	srli	a5,a1,0xc
ffffffffc02010a8:	04a7fd63          	bgeu	a5,a0,ffffffffc0201102 <pmm_init+0x1c8>
    pmm_manager->init_memmap(base, n);
ffffffffc02010ac:	0009b703          	ld	a4,0(s3)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02010b0:	fff80537          	lui	a0,0xfff80
ffffffffc02010b4:	97aa                	add	a5,a5,a0
ffffffffc02010b6:	00279513          	slli	a0,a5,0x2
ffffffffc02010ba:	953e                	add	a0,a0,a5
ffffffffc02010bc:	6b1c                	ld	a5,16(a4)
            init_memmap(pa2page(freemem), (mem_end - freemem) / PGSIZE);
ffffffffc02010be:	40b405b3          	sub	a1,s0,a1
ffffffffc02010c2:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02010c4:	81b1                	srli	a1,a1,0xc
ffffffffc02010c6:	9532                	add	a0,a0,a2
ffffffffc02010c8:	9782                	jalr	a5
}
ffffffffc02010ca:	b741                	j	ffffffffc020104a <pmm_init+0x110>
        panic("page_init: invalid memory info from dtb: base 0x%016lx, size 0x%016lx\n",
ffffffffc02010cc:	8752                	mv	a4,s4
ffffffffc02010ce:	86a6                	mv	a3,s1
ffffffffc02010d0:	00001617          	auipc	a2,0x1
ffffffffc02010d4:	4c860613          	addi	a2,a2,1224 # ffffffffc0202598 <buddy_system_pmm_manager+0x50>
ffffffffc02010d8:	05000593          	li	a1,80
ffffffffc02010dc:	00001517          	auipc	a0,0x1
ffffffffc02010e0:	50450513          	addi	a0,a0,1284 # ffffffffc02025e0 <buddy_system_pmm_manager+0x98>
ffffffffc02010e4:	8e6ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02010e8:	86ae                	mv	a3,a1
ffffffffc02010ea:	00001617          	auipc	a2,0x1
ffffffffc02010ee:	54e60613          	addi	a2,a2,1358 # ffffffffc0202638 <buddy_system_pmm_manager+0xf0>
ffffffffc02010f2:	08a00593          	li	a1,138
ffffffffc02010f6:	00001517          	auipc	a0,0x1
ffffffffc02010fa:	4ea50513          	addi	a0,a0,1258 # ffffffffc02025e0 <buddy_system_pmm_manager+0x98>
ffffffffc02010fe:	8ccff0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0201102:	00001617          	auipc	a2,0x1
ffffffffc0201106:	55e60613          	addi	a2,a2,1374 # ffffffffc0202660 <buddy_system_pmm_manager+0x118>
ffffffffc020110a:	06a00593          	li	a1,106
ffffffffc020110e:	00001517          	auipc	a0,0x1
ffffffffc0201112:	57250513          	addi	a0,a0,1394 # ffffffffc0202680 <buddy_system_pmm_manager+0x138>
ffffffffc0201116:	8b4ff0ef          	jal	ra,ffffffffc02001ca <__panic>
        freemem = PADDR((uintptr_t)pages + n * sizeof(struct Page));
ffffffffc020111a:	00001617          	auipc	a2,0x1
ffffffffc020111e:	51e60613          	addi	a2,a2,1310 # ffffffffc0202638 <buddy_system_pmm_manager+0xf0>
ffffffffc0201122:	06900593          	li	a1,105
ffffffffc0201126:	00001517          	auipc	a0,0x1
ffffffffc020112a:	4ba50513          	addi	a0,a0,1210 # ffffffffc02025e0 <buddy_system_pmm_manager+0x98>
ffffffffc020112e:	89cff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0201132 <slub_free.part.0>:
    return listelm->next;
ffffffffc0201132:	00005817          	auipc	a6,0x5
ffffffffc0201136:	0e680813          	addi	a6,a6,230 # ffffffffc0206218 <slub_slabs>
ffffffffc020113a:	00883783          	ld	a5,8(a6)
    struct slub_slab *slab = slub_new_large(object_size);
    return slab == NULL ? NULL : slub_payload(slab);
}

void
slub_free(void *ptr) {
ffffffffc020113e:	1141                	addi	sp,sp,-16
ffffffffc0201140:	e406                	sd	ra,8(sp)
    for (list_entry_t *le = list_next(&slub_slabs);
ffffffffc0201142:	03078463          	beq	a5,a6,ffffffffc020116a <slub_free.part.0+0x38>
            : slab->object_size;
ffffffffc0201146:	4885                	li	a7,1
            ? slab->capacity * slab->object_size
ffffffffc0201148:	fe07b603          	ld	a2,-32(a5)
        size_t bytes = slab->kind == SLUB_SMALL
ffffffffc020114c:	fd87a583          	lw	a1,-40(a5)
    return (void *)((char *)slab + sizeof(*slab));
ffffffffc0201150:	05078693          	addi	a3,a5,80
            ? slab->capacity * slab->object_size
ffffffffc0201154:	8732                	mv	a4,a2
            : slab->object_size;
ffffffffc0201156:	03158a63          	beq	a1,a7,ffffffffc020118a <slub_free.part.0+0x58>
        if (address >= start && address < start + bytes) {
ffffffffc020115a:	00d56563          	bltu	a0,a3,ffffffffc0201164 <slub_free.part.0+0x32>
ffffffffc020115e:	9736                	add	a4,a4,a3
ffffffffc0201160:	02e56a63          	bltu	a0,a4,ffffffffc0201194 <slub_free.part.0+0x62>
ffffffffc0201164:	679c                	ld	a5,8(a5)
    for (list_entry_t *le = list_next(&slub_slabs);
ffffffffc0201166:	ff0791e3          	bne	a5,a6,ffffffffc0201148 <slub_free.part.0+0x16>
    if (ptr == NULL) {
        return;
    }

    struct slub_slab *slab = slub_find(ptr);
    assert(slab != NULL && slab->magic == SLUB_MAGIC);
ffffffffc020116a:	00001697          	auipc	a3,0x1
ffffffffc020116e:	58668693          	addi	a3,a3,1414 # ffffffffc02026f0 <buddy_system_pmm_manager+0x1a8>
ffffffffc0201172:	00001617          	auipc	a2,0x1
ffffffffc0201176:	10660613          	addi	a2,a2,262 # ffffffffc0202278 <etext+0x292>
ffffffffc020117a:	0c900593          	li	a1,201
ffffffffc020117e:	00001517          	auipc	a0,0x1
ffffffffc0201182:	5a250513          	addi	a0,a0,1442 # ffffffffc0202720 <buddy_system_pmm_manager+0x1d8>
ffffffffc0201186:	844ff0ef          	jal	ra,ffffffffc02001ca <__panic>
            : slab->object_size;
ffffffffc020118a:	fe87b703          	ld	a4,-24(a5)
ffffffffc020118e:	02e60733          	mul	a4,a2,a4
ffffffffc0201192:	b7e1                	j	ffffffffc020115a <slub_free.part.0+0x28>
    assert(slab != NULL && slab->magic == SLUB_MAGIC);
ffffffffc0201194:	fd07b803          	ld	a6,-48(a5)
ffffffffc0201198:	00002717          	auipc	a4,0x2
ffffffffc020119c:	b4073703          	ld	a4,-1216(a4) # ffffffffc0202cd8 <error_string+0x40>
ffffffffc02011a0:	fce815e3          	bne	a6,a4,ffffffffc020116a <slub_free.part.0+0x38>
    char *start = (char *)slub_payload(slab);
    size_t offset = (size_t)((char *)ptr - start);
    assert(offset < slab->capacity * slab->object_size);
ffffffffc02011a4:	fe87b803          	ld	a6,-24(a5)
    size_t offset = (size_t)((char *)ptr - start);
ffffffffc02011a8:	40d50733          	sub	a4,a0,a3
    assert(offset < slab->capacity * slab->object_size);
ffffffffc02011ac:	02c808b3          	mul	a7,a6,a2
ffffffffc02011b0:	0d177c63          	bgeu	a4,a7,ffffffffc0201288 <slub_free.part.0+0x156>
    assert(offset % slab->object_size == 0);
ffffffffc02011b4:	02c778b3          	remu	a7,a4,a2
ffffffffc02011b8:	08089863          	bnez	a7,ffffffffc0201248 <slub_free.part.0+0x116>

    if (slab->kind == SLUB_LARGE) {
ffffffffc02011bc:	4889                	li	a7,2
ffffffffc02011be:	03158b63          	beq	a1,a7,ffffffffc02011f4 <slub_free.part.0+0xc2>
        list_del(&slab->link);
        free_pages(page, pages);
        return;
    }

    size_t index = offset / slab->object_size;
ffffffffc02011c2:	02c75733          	divu	a4,a4,a2
    size_t word = index / 64;
    uint64_t bit = 1ULL << (index % 64);
ffffffffc02011c6:	4605                	li	a2,1
    size_t word = index / 64;
ffffffffc02011c8:	00675693          	srli	a3,a4,0x6
ffffffffc02011cc:	068e                	slli	a3,a3,0x3
ffffffffc02011ce:	96be                	add	a3,a3,a5
    assert((slab->bitmap[word] & bit) == 0);
ffffffffc02011d0:	6a8c                	ld	a1,16(a3)
    uint64_t bit = 1ULL << (index % 64);
ffffffffc02011d2:	00e61733          	sll	a4,a2,a4
    assert((slab->bitmap[word] & bit) == 0);
ffffffffc02011d6:	00b77633          	and	a2,a4,a1
ffffffffc02011da:	e639                	bnez	a2,ffffffffc0201228 <slub_free.part.0+0xf6>
    slab->bitmap[word] |= bit;
ffffffffc02011dc:	8f4d                	or	a4,a4,a1
ffffffffc02011de:	ea98                	sd	a4,16(a3)
    slab->free_count ++;
ffffffffc02011e0:	ff07b703          	ld	a4,-16(a5)
ffffffffc02011e4:	0705                	addi	a4,a4,1
ffffffffc02011e6:	fee7b823          	sd	a4,-16(a5)
    if (slab->free_count == slab->capacity) {
ffffffffc02011ea:	02e80563          	beq	a6,a4,ffffffffc0201214 <slub_free.part.0+0xe2>
        struct Page *page = slab->page;
        list_del(&slab->link);
        free_pages(page, 1);
    }
}
ffffffffc02011ee:	60a2                	ld	ra,8(sp)
ffffffffc02011f0:	0141                	addi	sp,sp,16
ffffffffc02011f2:	8082                	ret
        assert(ptr == start);
ffffffffc02011f4:	06d51a63          	bne	a0,a3,ffffffffc0201268 <slub_free.part.0+0x136>
    __list_del(listelm->prev, listelm->next);
ffffffffc02011f8:	6394                	ld	a3,0(a5)
ffffffffc02011fa:	6798                	ld	a4,8(a5)
        struct Page *page = slab->page;
ffffffffc02011fc:	ff87b503          	ld	a0,-8(a5)
        size_t pages = (size_t)1 << slab->order;
ffffffffc0201200:	fdc7a783          	lw	a5,-36(a5)
}
ffffffffc0201204:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201206:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0201208:	e314                	sd	a3,0(a4)
        free_pages(page, pages);
ffffffffc020120a:	4585                	li	a1,1
ffffffffc020120c:	00f595b3          	sll	a1,a1,a5
}
ffffffffc0201210:	0141                	addi	sp,sp,16
        free_pages(page, pages);
ffffffffc0201212:	bb01                	j	ffffffffc0200f22 <free_pages>
    __list_del(listelm->prev, listelm->next);
ffffffffc0201214:	6394                	ld	a3,0(a5)
ffffffffc0201216:	6798                	ld	a4,8(a5)
        struct Page *page = slab->page;
ffffffffc0201218:	ff87b503          	ld	a0,-8(a5)
}
ffffffffc020121c:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020121e:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0201220:	e314                	sd	a3,0(a4)
        free_pages(page, 1);
ffffffffc0201222:	4585                	li	a1,1
}
ffffffffc0201224:	0141                	addi	sp,sp,16
        free_pages(page, 1);
ffffffffc0201226:	b9f5                	j	ffffffffc0200f22 <free_pages>
    assert((slab->bitmap[word] & bit) == 0);
ffffffffc0201228:	00001697          	auipc	a3,0x1
ffffffffc020122c:	56868693          	addi	a3,a3,1384 # ffffffffc0202790 <buddy_system_pmm_manager+0x248>
ffffffffc0201230:	00001617          	auipc	a2,0x1
ffffffffc0201234:	04860613          	addi	a2,a2,72 # ffffffffc0202278 <etext+0x292>
ffffffffc0201238:	0db00593          	li	a1,219
ffffffffc020123c:	00001517          	auipc	a0,0x1
ffffffffc0201240:	4e450513          	addi	a0,a0,1252 # ffffffffc0202720 <buddy_system_pmm_manager+0x1d8>
ffffffffc0201244:	f87fe0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(offset % slab->object_size == 0);
ffffffffc0201248:	00001697          	auipc	a3,0x1
ffffffffc020124c:	51868693          	addi	a3,a3,1304 # ffffffffc0202760 <buddy_system_pmm_manager+0x218>
ffffffffc0201250:	00001617          	auipc	a2,0x1
ffffffffc0201254:	02860613          	addi	a2,a2,40 # ffffffffc0202278 <etext+0x292>
ffffffffc0201258:	0cd00593          	li	a1,205
ffffffffc020125c:	00001517          	auipc	a0,0x1
ffffffffc0201260:	4c450513          	addi	a0,a0,1220 # ffffffffc0202720 <buddy_system_pmm_manager+0x1d8>
ffffffffc0201264:	f67fe0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(ptr == start);
ffffffffc0201268:	00001697          	auipc	a3,0x1
ffffffffc020126c:	51868693          	addi	a3,a3,1304 # ffffffffc0202780 <buddy_system_pmm_manager+0x238>
ffffffffc0201270:	00001617          	auipc	a2,0x1
ffffffffc0201274:	00860613          	addi	a2,a2,8 # ffffffffc0202278 <etext+0x292>
ffffffffc0201278:	0d000593          	li	a1,208
ffffffffc020127c:	00001517          	auipc	a0,0x1
ffffffffc0201280:	4a450513          	addi	a0,a0,1188 # ffffffffc0202720 <buddy_system_pmm_manager+0x1d8>
ffffffffc0201284:	f47fe0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(offset < slab->capacity * slab->object_size);
ffffffffc0201288:	00001697          	auipc	a3,0x1
ffffffffc020128c:	4a868693          	addi	a3,a3,1192 # ffffffffc0202730 <buddy_system_pmm_manager+0x1e8>
ffffffffc0201290:	00001617          	auipc	a2,0x1
ffffffffc0201294:	fe860613          	addi	a2,a2,-24 # ffffffffc0202278 <etext+0x292>
ffffffffc0201298:	0cc00593          	li	a1,204
ffffffffc020129c:	00001517          	auipc	a0,0x1
ffffffffc02012a0:	48450513          	addi	a0,a0,1156 # ffffffffc0202720 <buddy_system_pmm_manager+0x1d8>
ffffffffc02012a4:	f27fe0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc02012a8 <slub_init>:
    elm->prev = elm->next = elm;
ffffffffc02012a8:	00005797          	auipc	a5,0x5
ffffffffc02012ac:	f7078793          	addi	a5,a5,-144 # ffffffffc0206218 <slub_slabs>
ffffffffc02012b0:	e79c                	sd	a5,8(a5)
ffffffffc02012b2:	e39c                	sd	a5,0(a5)
    slub_initialized = 1;
ffffffffc02012b4:	4785                	li	a5,1
ffffffffc02012b6:	00005717          	auipc	a4,0x5
ffffffffc02012ba:	fcf72123          	sw	a5,-62(a4) # ffffffffc0206278 <slub_initialized>
}
ffffffffc02012be:	8082                	ret

ffffffffc02012c0 <slub_alloc>:
slub_alloc(size_t size) {
ffffffffc02012c0:	1101                	addi	sp,sp,-32
ffffffffc02012c2:	ec06                	sd	ra,24(sp)
ffffffffc02012c4:	e822                	sd	s0,16(sp)
ffffffffc02012c6:	e426                	sd	s1,8(sp)
    assert(slub_initialized);
ffffffffc02012c8:	00005797          	auipc	a5,0x5
ffffffffc02012cc:	fb07a783          	lw	a5,-80(a5) # ffffffffc0206278 <slub_initialized>
ffffffffc02012d0:	24078363          	beqz	a5,ffffffffc0201516 <slub_alloc+0x256>
ffffffffc02012d4:	842a                	mv	s0,a0
    if (size == 0) {
ffffffffc02012d6:	14050163          	beqz	a0,ffffffffc0201418 <slub_alloc+0x158>
    size_t remainder = size % align;
ffffffffc02012da:	00757793          	andi	a5,a0,7
    if (remainder != 0) {
ffffffffc02012de:	cb81                	beqz	a5,ffffffffc02012ee <slub_alloc+0x2e>
        size += align - remainder;
ffffffffc02012e0:	00850713          	addi	a4,a0,8
ffffffffc02012e4:	40f707b3          	sub	a5,a4,a5
    if (object_size < size) {
ffffffffc02012e8:	12a7e863          	bltu	a5,a0,ffffffffc0201418 <slub_alloc+0x158>
ffffffffc02012ec:	843e                	mv	s0,a5
    if (object_size <= SLUB_SMALL_MAX) {
ffffffffc02012ee:	10000793          	li	a5,256
ffffffffc02012f2:	0887e563          	bltu	a5,s0,ffffffffc020137c <slub_alloc+0xbc>
    return listelm->next;
ffffffffc02012f6:	00005497          	auipc	s1,0x5
ffffffffc02012fa:	f2248493          	addi	s1,s1,-222 # ffffffffc0206218 <slub_slabs>
ffffffffc02012fe:	649c                	ld	a5,8(s1)
        for (list_entry_t *le = list_next(&slub_slabs);
ffffffffc0201300:	12978263          	beq	a5,s1,ffffffffc0201424 <slub_alloc+0x164>
            if (slab->kind == SLUB_SMALL &&
ffffffffc0201304:	4685                	li	a3,1
ffffffffc0201306:	a021                	j	ffffffffc020130e <slub_alloc+0x4e>
ffffffffc0201308:	679c                	ld	a5,8(a5)
        for (list_entry_t *le = list_next(&slub_slabs);
ffffffffc020130a:	10978d63          	beq	a5,s1,ffffffffc0201424 <slub_alloc+0x164>
            if (slab->kind == SLUB_SMALL &&
ffffffffc020130e:	fd87a703          	lw	a4,-40(a5)
ffffffffc0201312:	fed71be3          	bne	a4,a3,ffffffffc0201308 <slub_alloc+0x48>
ffffffffc0201316:	fe07b603          	ld	a2,-32(a5)
ffffffffc020131a:	fe8617e3          	bne	a2,s0,ffffffffc0201308 <slub_alloc+0x48>
                slab->object_size == object_size && slab->free_count != 0) {
ffffffffc020131e:	ff07b303          	ld	t1,-16(a5)
ffffffffc0201322:	fe0303e3          	beqz	t1,ffffffffc0201308 <slub_alloc+0x48>
                for (size_t i = 0; i < slab->capacity; i ++) {
ffffffffc0201326:	fe87b883          	ld	a7,-24(a5)
ffffffffc020132a:	fc088fe3          	beqz	a7,ffffffffc0201308 <slub_alloc+0x48>
                    if ((slab->bitmap[word] & bit) != 0) {
ffffffffc020132e:	6b8c                	ld	a1,16(a5)
ffffffffc0201330:	0015f713          	andi	a4,a1,1
ffffffffc0201334:	1c071d63          	bnez	a4,ffffffffc020150e <slub_alloc+0x24e>
                for (size_t i = 0; i < slab->capacity; i ++) {
ffffffffc0201338:	0705                	addi	a4,a4,1
ffffffffc020133a:	fd1707e3          	beq	a4,a7,ffffffffc0201308 <slub_alloc+0x48>
                    size_t word = i / 64;
ffffffffc020133e:	00675613          	srli	a2,a4,0x6
                    if ((slab->bitmap[word] & bit) != 0) {
ffffffffc0201342:	0621                	addi	a2,a2,8
ffffffffc0201344:	00361593          	slli	a1,a2,0x3
ffffffffc0201348:	95be                	add	a1,a1,a5
ffffffffc020134a:	fd05b583          	ld	a1,-48(a1)
                    uint64_t bit = 1ULL << (i % 64);
ffffffffc020134e:	00e69533          	sll	a0,a3,a4
                    if ((slab->bitmap[word] & bit) != 0) {
ffffffffc0201352:	00a5f833          	and	a6,a1,a0
ffffffffc0201356:	fe0801e3          	beqz	a6,ffffffffc0201338 <slub_alloc+0x78>
                        return (char *)slub_payload(slab) + i * object_size;
ffffffffc020135a:	02870733          	mul	a4,a4,s0
                        slab->bitmap[word] &= ~bit;
ffffffffc020135e:	fff54513          	not	a0,a0
ffffffffc0201362:	00361693          	slli	a3,a2,0x3
ffffffffc0201366:	8de9                	and	a1,a1,a0
ffffffffc0201368:	96be                	add	a3,a3,a5
ffffffffc020136a:	fcb6b823          	sd	a1,-48(a3)
                        slab->free_count --;
ffffffffc020136e:	137d                	addi	t1,t1,-1
    return (void *)((char *)slab + sizeof(*slab));
ffffffffc0201370:	05078513          	addi	a0,a5,80
                        slab->free_count --;
ffffffffc0201374:	fe67b823          	sd	t1,-16(a5)
                        return (char *)slub_payload(slab) + i * object_size;
ffffffffc0201378:	953a                	add	a0,a0,a4
ffffffffc020137a:	a045                	j	ffffffffc020141a <slub_alloc+0x15a>
    if (object_size > ~(size_t)0 - total) {
ffffffffc020137c:	77fd                	lui	a5,0xfffff
ffffffffc020137e:	f8078793          	addi	a5,a5,-128 # ffffffffffffef80 <end+0x3fdf8d04>
ffffffffc0201382:	0887eb63          	bltu	a5,s0,ffffffffc0201418 <slub_alloc+0x158>
    size_t pages = (total + PGSIZE - 1) / PGSIZE;
ffffffffc0201386:	6785                	lui	a5,0x1
ffffffffc0201388:	07f78793          	addi	a5,a5,127 # 107f <kern_entry-0xffffffffc01fef81>
ffffffffc020138c:	97a2                	add	a5,a5,s0
ffffffffc020138e:	83b1                	srli	a5,a5,0xc
    while (block_pages < pages) {
ffffffffc0201390:	4705                	li	a4,1
ffffffffc0201392:	16e78b63          	beq	a5,a4,ffffffffc0201508 <slub_alloc+0x248>
    unsigned int order = 0;
ffffffffc0201396:	4481                	li	s1,0
    size_t block_pages = 1;
ffffffffc0201398:	4505                	li	a0,1
        block_pages <<= 1;
ffffffffc020139a:	0506                	slli	a0,a0,0x1
        order ++;
ffffffffc020139c:	2485                	addiw	s1,s1,1
    while (block_pages < pages) {
ffffffffc020139e:	fef56ee3          	bltu	a0,a5,ffffffffc020139a <slub_alloc+0xda>
    struct Page *page = alloc_pages(block_pages);
ffffffffc02013a2:	b75ff0ef          	jal	ra,ffffffffc0200f16 <alloc_pages>
    if (page == NULL) {
ffffffffc02013a6:	c92d                	beqz	a0,ffffffffc0201418 <slub_alloc+0x158>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02013a8:	00005797          	auipc	a5,0x5
ffffffffc02013ac:	ea87b783          	ld	a5,-344(a5) # ffffffffc0206250 <pages>
ffffffffc02013b0:	40f507b3          	sub	a5,a0,a5
ffffffffc02013b4:	00002717          	auipc	a4,0x2
ffffffffc02013b8:	91c73703          	ld	a4,-1764(a4) # ffffffffc0202cd0 <error_string+0x38>
ffffffffc02013bc:	878d                	srai	a5,a5,0x3
ffffffffc02013be:	02e787b3          	mul	a5,a5,a4
ffffffffc02013c2:	00002617          	auipc	a2,0x2
ffffffffc02013c6:	91e63603          	ld	a2,-1762(a2) # ffffffffc0202ce0 <nbase>
    __list_add(elm, listelm, listelm->next);
ffffffffc02013ca:	00005717          	auipc	a4,0x5
ffffffffc02013ce:	e4e70713          	addi	a4,a4,-434 # ffffffffc0206218 <slub_slabs>
ffffffffc02013d2:	6714                	ld	a3,8(a4)
    slab->capacity = 1;
ffffffffc02013d4:	4585                	li	a1,1
}
ffffffffc02013d6:	60e2                	ld	ra,24(sp)
ffffffffc02013d8:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02013da:	07b2                	slli	a5,a5,0xc
        (struct slub_slab *)(page2pa(page) + va_pa_offset);
ffffffffc02013dc:	00005617          	auipc	a2,0x5
ffffffffc02013e0:	e9463603          	ld	a2,-364(a2) # ffffffffc0206270 <va_pa_offset>
ffffffffc02013e4:	97b2                	add	a5,a5,a2
    slab->magic = SLUB_MAGIC;
ffffffffc02013e6:	00002617          	auipc	a2,0x2
ffffffffc02013ea:	8f263603          	ld	a2,-1806(a2) # ffffffffc0202cd8 <error_string+0x40>
ffffffffc02013ee:	e390                	sd	a2,0(a5)
    slab->kind = SLUB_LARGE;
ffffffffc02013f0:	4609                	li	a2,2
ffffffffc02013f2:	c790                	sw	a2,8(a5)
    slab->order = order;
ffffffffc02013f4:	c7c4                	sw	s1,12(a5)
    slab->object_size = object_size;
ffffffffc02013f6:	eb80                	sd	s0,16(a5)
    slab->page = page;
ffffffffc02013f8:	f788                	sd	a0,40(a5)
}
ffffffffc02013fa:	6442                	ld	s0,16(sp)
    list_add(&slub_slabs, &slab->link);
ffffffffc02013fc:	03078613          	addi	a2,a5,48
    slab->capacity = 1;
ffffffffc0201400:	ef8c                	sd	a1,24(a5)
    slab->free_count = 0;
ffffffffc0201402:	0207b023          	sd	zero,32(a5)
    prev->next = next->prev = elm;
ffffffffc0201406:	e290                	sd	a2,0(a3)
ffffffffc0201408:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020140a:	ff94                	sd	a3,56(a5)
    elm->prev = prev;
ffffffffc020140c:	fb98                	sd	a4,48(a5)
}
ffffffffc020140e:	64a2                	ld	s1,8(sp)
    return (void *)((char *)slab + sizeof(*slab));
ffffffffc0201410:	08078513          	addi	a0,a5,128
}
ffffffffc0201414:	6105                	addi	sp,sp,32
ffffffffc0201416:	8082                	ret
        return NULL;
ffffffffc0201418:	4501                	li	a0,0
}
ffffffffc020141a:	60e2                	ld	ra,24(sp)
ffffffffc020141c:	6442                	ld	s0,16(sp)
ffffffffc020141e:	64a2                	ld	s1,8(sp)
ffffffffc0201420:	6105                	addi	sp,sp,32
ffffffffc0201422:	8082                	ret
    struct Page *page = alloc_pages(1);
ffffffffc0201424:	4505                	li	a0,1
ffffffffc0201426:	af1ff0ef          	jal	ra,ffffffffc0200f16 <alloc_pages>
    if (page == NULL) {
ffffffffc020142a:	d57d                	beqz	a0,ffffffffc0201418 <slub_alloc+0x158>
    size_t capacity = available / object_size;
ffffffffc020142c:	6685                	lui	a3,0x1
ffffffffc020142e:	f8068693          	addi	a3,a3,-128 # f80 <kern_entry-0xffffffffc01ff080>
ffffffffc0201432:	0286d6b3          	divu	a3,a3,s0
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201436:	00005797          	auipc	a5,0x5
ffffffffc020143a:	e1a7b783          	ld	a5,-486(a5) # ffffffffc0206250 <pages>
ffffffffc020143e:	40f507b3          	sub	a5,a0,a5
ffffffffc0201442:	00002617          	auipc	a2,0x2
ffffffffc0201446:	88e63603          	ld	a2,-1906(a2) # ffffffffc0202cd0 <error_string+0x38>
ffffffffc020144a:	878d                	srai	a5,a5,0x3
ffffffffc020144c:	00002597          	auipc	a1,0x2
ffffffffc0201450:	8945b583          	ld	a1,-1900(a1) # ffffffffc0202ce0 <nbase>
ffffffffc0201454:	20000713          	li	a4,512
ffffffffc0201458:	02c787b3          	mul	a5,a5,a2
ffffffffc020145c:	8636                	mv	a2,a3
ffffffffc020145e:	97ae                	add	a5,a5,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0201460:	07b2                	slli	a5,a5,0xc
        (struct slub_slab *)(page2pa(page) + va_pa_offset);
ffffffffc0201462:	00005597          	auipc	a1,0x5
ffffffffc0201466:	e0e5b583          	ld	a1,-498(a1) # ffffffffc0206270 <va_pa_offset>
ffffffffc020146a:	97ae                	add	a5,a5,a1
    if (capacity > SLUB_BITMAP_WORDS * 64) {
ffffffffc020146c:	08d76b63          	bltu	a4,a3,ffffffffc0201502 <slub_alloc+0x242>
    slab->magic = SLUB_MAGIC;
ffffffffc0201470:	00002597          	auipc	a1,0x2
ffffffffc0201474:	8685b583          	ld	a1,-1944(a1) # ffffffffc0202cd8 <error_string+0x40>
        slab->bitmap[i] = ~0ULL;
ffffffffc0201478:	577d                	li	a4,-1
    slab->magic = SLUB_MAGIC;
ffffffffc020147a:	e38c                	sd	a1,0(a5)
    slab->kind = SLUB_SMALL;
ffffffffc020147c:	4585                	li	a1,1
    slab->page = page;
ffffffffc020147e:	f788                	sd	a0,40(a5)
        slab->bitmap[i] = ~0ULL;
ffffffffc0201480:	e3b8                	sd	a4,64(a5)
ffffffffc0201482:	e7b8                	sd	a4,72(a5)
ffffffffc0201484:	ebb8                	sd	a4,80(a5)
ffffffffc0201486:	efb8                	sd	a4,88(a5)
ffffffffc0201488:	f3b8                	sd	a4,96(a5)
ffffffffc020148a:	f7b8                	sd	a4,104(a5)
ffffffffc020148c:	fbb8                	sd	a4,112(a5)
ffffffffc020148e:	ffb8                	sd	a4,120(a5)
    slab->kind = SLUB_SMALL;
ffffffffc0201490:	e78c                	sd	a1,8(a5)
    slab->object_size = object_size;
ffffffffc0201492:	eb80                	sd	s0,16(a5)
    slab->capacity = capacity;
ffffffffc0201494:	ef90                	sd	a2,24(a5)
    slab->free_count = capacity;
ffffffffc0201496:	f390                	sd	a2,32(a5)
    if (capacity < SLUB_BITMAP_WORDS * 64) {
ffffffffc0201498:	1ff00713          	li	a4,511
ffffffffc020149c:	08078513          	addi	a0,a5,128
ffffffffc02014a0:	04d76063          	bltu	a4,a3,ffffffffc02014e0 <slub_alloc+0x220>
        size_t bits = capacity % 64;
ffffffffc02014a4:	03f67813          	andi	a6,a2,63
        size_t words = capacity / 64;
ffffffffc02014a8:	00665693          	srli	a3,a2,0x6
        for (size_t i = words + (bits != 0); i < SLUB_BITMAP_WORDS; i ++) {
ffffffffc02014ac:	010035b3          	snez	a1,a6
ffffffffc02014b0:	95b6                	add	a1,a1,a3
ffffffffc02014b2:	00858713          	addi	a4,a1,8
ffffffffc02014b6:	070e                	slli	a4,a4,0x3
ffffffffc02014b8:	48a1                	li	a7,8
ffffffffc02014ba:	973e                	add	a4,a4,a5
ffffffffc02014bc:	01158763          	beq	a1,a7,ffffffffc02014ca <slub_alloc+0x20a>
            slab->bitmap[i] = 0;
ffffffffc02014c0:	00073023          	sd	zero,0(a4)
        for (size_t i = words + (bits != 0); i < SLUB_BITMAP_WORDS; i ++) {
ffffffffc02014c4:	0721                	addi	a4,a4,8
ffffffffc02014c6:	fee51de3          	bne	a0,a4,ffffffffc02014c0 <slub_alloc+0x200>
        if (bits != 0) {
ffffffffc02014ca:	00080b63          	beqz	a6,ffffffffc02014e0 <slub_alloc+0x220>
            slab->bitmap[words] = (1ULL << bits) - 1;
ffffffffc02014ce:	00868713          	addi	a4,a3,8
ffffffffc02014d2:	4685                	li	a3,1
ffffffffc02014d4:	070e                	slli	a4,a4,0x3
ffffffffc02014d6:	010696b3          	sll	a3,a3,a6
ffffffffc02014da:	973e                	add	a4,a4,a5
ffffffffc02014dc:	16fd                	addi	a3,a3,-1
ffffffffc02014de:	e314                	sd	a3,0(a4)
    __list_add(elm, listelm, listelm->next);
ffffffffc02014e0:	6494                	ld	a3,8(s1)
        slab->bitmap[0] &= ~1ULL;
ffffffffc02014e2:	63b8                	ld	a4,64(a5)
}
ffffffffc02014e4:	60e2                	ld	ra,24(sp)
ffffffffc02014e6:	6442                	ld	s0,16(sp)
    list_add(&slub_slabs, &slab->link);
ffffffffc02014e8:	03078593          	addi	a1,a5,48
    prev->next = next->prev = elm;
ffffffffc02014ec:	e28c                	sd	a1,0(a3)
        slab->bitmap[0] &= ~1ULL;
ffffffffc02014ee:	9b79                	andi	a4,a4,-2
        slab->free_count --;
ffffffffc02014f0:	167d                	addi	a2,a2,-1
ffffffffc02014f2:	e48c                	sd	a1,8(s1)
    elm->prev = prev;
ffffffffc02014f4:	fb84                	sd	s1,48(a5)
    elm->next = next;
ffffffffc02014f6:	ff94                	sd	a3,56(a5)
        slab->bitmap[0] &= ~1ULL;
ffffffffc02014f8:	e3b8                	sd	a4,64(a5)
        slab->free_count --;
ffffffffc02014fa:	f390                	sd	a2,32(a5)
}
ffffffffc02014fc:	64a2                	ld	s1,8(sp)
ffffffffc02014fe:	6105                	addi	sp,sp,32
ffffffffc0201500:	8082                	ret
ffffffffc0201502:	20000613          	li	a2,512
ffffffffc0201506:	b7ad                	j	ffffffffc0201470 <slub_alloc+0x1b0>
    size_t block_pages = 1;
ffffffffc0201508:	4505                	li	a0,1
    unsigned int order = 0;
ffffffffc020150a:	4481                	li	s1,0
ffffffffc020150c:	bd59                	j	ffffffffc02013a2 <slub_alloc+0xe2>
                    if ((slab->bitmap[word] & bit) != 0) {
ffffffffc020150e:	4701                	li	a4,0
ffffffffc0201510:	5579                	li	a0,-2
ffffffffc0201512:	4621                	li	a2,8
ffffffffc0201514:	b5b9                	j	ffffffffc0201362 <slub_alloc+0xa2>
    assert(slub_initialized);
ffffffffc0201516:	00001697          	auipc	a3,0x1
ffffffffc020151a:	29a68693          	addi	a3,a3,666 # ffffffffc02027b0 <buddy_system_pmm_manager+0x268>
ffffffffc020151e:	00001617          	auipc	a2,0x1
ffffffffc0201522:	d5a60613          	addi	a2,a2,-678 # ffffffffc0202278 <etext+0x292>
ffffffffc0201526:	09800593          	li	a1,152
ffffffffc020152a:	00001517          	auipc	a0,0x1
ffffffffc020152e:	1f650513          	addi	a0,a0,502 # ffffffffc0202720 <buddy_system_pmm_manager+0x1d8>
ffffffffc0201532:	c99fe0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0201536 <slub_check>:
    uintptr_t bhi = blo + bsize;
    return alo < bhi && blo < ahi;
}

void
slub_check(void) {
ffffffffc0201536:	db010113          	addi	sp,sp,-592
ffffffffc020153a:	21513c23          	sd	s5,536(sp)
    assert(slub_initialized);
ffffffffc020153e:	00005a97          	auipc	s5,0x5
ffffffffc0201542:	d3aa8a93          	addi	s5,s5,-710 # ffffffffc0206278 <slub_initialized>
ffffffffc0201546:	000aa783          	lw	a5,0(s5)
slub_check(void) {
ffffffffc020154a:	24113423          	sd	ra,584(sp)
ffffffffc020154e:	24813023          	sd	s0,576(sp)
ffffffffc0201552:	22913c23          	sd	s1,568(sp)
ffffffffc0201556:	23213823          	sd	s2,560(sp)
ffffffffc020155a:	23313423          	sd	s3,552(sp)
ffffffffc020155e:	23413023          	sd	s4,544(sp)
ffffffffc0201562:	21613823          	sd	s6,528(sp)
ffffffffc0201566:	21713423          	sd	s7,520(sp)
ffffffffc020156a:	21813023          	sd	s8,512(sp)
ffffffffc020156e:	ffe6                	sd	s9,504(sp)
ffffffffc0201570:	fbea                	sd	s10,496(sp)
ffffffffc0201572:	f7ee                	sd	s11,488(sp)
    assert(slub_initialized);
ffffffffc0201574:	44078e63          	beqz	a5,ffffffffc02019d0 <slub_check+0x49a>
    size_t saved_nr_free = nr_free_pages();
ffffffffc0201578:	9b7ff0ef          	jal	ra,ffffffffc0200f2e <nr_free_pages>
    assert(slub_initialized);
ffffffffc020157c:	000aa783          	lw	a5,0(s5)
    size_t saved_nr_free = nr_free_pages();
ffffffffc0201580:	8b2a                	mv	s6,a0
    assert(slub_initialized);
ffffffffc0201582:	46078763          	beqz	a5,ffffffffc02019f0 <slub_check+0x4ba>

    assert(slub_alloc(0) == NULL);
    slub_free(NULL);
    assert(nr_free_pages() == saved_nr_free);
ffffffffc0201586:	9a9ff0ef          	jal	ra,ffffffffc0200f2e <nr_free_pages>
ffffffffc020158a:	3b651363          	bne	a0,s6,ffffffffc0201930 <slub_check+0x3fa>
ffffffffc020158e:	00001997          	auipc	s3,0x1
ffffffffc0201592:	4ba98993          	addi	s3,s3,1210 # ffffffffc0202a48 <small_sizes.1>
ffffffffc0201596:	4481                	li	s1,0
ffffffffc0201598:	4c05                	li	s8,1

    static const size_t small_sizes[] = {1, 7, 8, 15, 16, 64, 128, 256};
    void *small[24];
    size_t small_size[24];
    size_t small_count = 0;
ffffffffc020159a:	4401                	li	s0,0
    for (size_t i = 0; i < sizeof(small_sizes) / sizeof(small_sizes[0]); i ++) {
ffffffffc020159c:	09800a13          	li	s4,152
        for (size_t j = 0; j < 3; j ++) {
ffffffffc02015a0:	00341b93          	slli	s7,s0,0x3
ffffffffc02015a4:	109c                	addi	a5,sp,96
slub_check(void) {
ffffffffc02015a6:	8ca2                	mv	s9,s0
ffffffffc02015a8:	01778d33          	add	s10,a5,s7
ffffffffc02015ac:	121c                	addi	a5,sp,288
ffffffffc02015ae:	9bbe                	add	s7,s7,a5
ffffffffc02015b0:	040d                	addi	s0,s0,3
            small[small_count] = slub_alloc(small_sizes[i]);
            assert(small[small_count] != NULL);
            small_size[small_count] = small_sizes[i];
            slub_test_write(small[small_count], small_size[small_count],
ffffffffc02015b2:	4194893b          	subw	s2,s1,s9
            small[small_count] = slub_alloc(small_sizes[i]);
ffffffffc02015b6:	8562                	mv	a0,s8
ffffffffc02015b8:	d09ff0ef          	jal	ra,ffffffffc02012c0 <slub_alloc>
ffffffffc02015bc:	00ad3023          	sd	a0,0(s10)
            assert(small[small_count] != NULL);
ffffffffc02015c0:	3e050863          	beqz	a0,ffffffffc02019b0 <slub_check+0x47a>
            slub_test_write(small[small_count], small_size[small_count],
ffffffffc02015c4:	019907bb          	addw	a5,s2,s9
            small_size[small_count] = small_sizes[i];
ffffffffc02015c8:	018bb023          	sd	s8,0(s7)
            slub_test_write(small[small_count], small_size[small_count],
ffffffffc02015cc:	0ff7f793          	zext.b	a5,a5
    for (size_t i = 0; i < size; i ++) {
ffffffffc02015d0:	020c0b63          	beqz	s8,ffffffffc0201606 <slub_check+0xd0>
ffffffffc02015d4:	40a786bb          	subw	a3,a5,a0
ffffffffc02015d8:	01850633          	add	a2,a0,s8
ffffffffc02015dc:	87aa                	mv	a5,a0
ffffffffc02015de:	0ff6f693          	zext.b	a3,a3
        bytes[i] = (unsigned char)(seed + i);
ffffffffc02015e2:	00d7873b          	addw	a4,a5,a3
ffffffffc02015e6:	00e78023          	sb	a4,0(a5)
    for (size_t i = 0; i < size; i ++) {
ffffffffc02015ea:	0785                	addi	a5,a5,1
ffffffffc02015ec:	fec79be3          	bne	a5,a2,ffffffffc02015e2 <slub_check+0xac>
        assert(bytes[i] == (unsigned char)(seed + i));
ffffffffc02015f0:	00054703          	lbu	a4,0(a0)
ffffffffc02015f4:	00d507bb          	addw	a5,a0,a3
ffffffffc02015f8:	0ff7f793          	zext.b	a5,a5
ffffffffc02015fc:	08f71863          	bne	a4,a5,ffffffffc020168c <slub_check+0x156>
    for (size_t i = 0; i < size; i ++) {
ffffffffc0201600:	0505                	addi	a0,a0,1
ffffffffc0201602:	fec517e3          	bne	a0,a2,ffffffffc02015f0 <slub_check+0xba>
                            (unsigned char)(i * 19 + j));
            small_count ++;
ffffffffc0201606:	001c8d93          	addi	s11,s9,1
        for (size_t j = 0; j < 3; j ++) {
ffffffffc020160a:	0d21                	addi	s10,s10,8
ffffffffc020160c:	0ba1                	addi	s7,s7,8
ffffffffc020160e:	008d8463          	beq	s11,s0,ffffffffc0201616 <slub_check+0xe0>
ffffffffc0201612:	8cee                	mv	s9,s11
ffffffffc0201614:	b74d                	j	ffffffffc02015b6 <slub_check+0x80>
    for (size_t i = 0; i < sizeof(small_sizes) / sizeof(small_sizes[0]); i ++) {
ffffffffc0201616:	24cd                	addiw	s1,s1,19
ffffffffc0201618:	0ff4f493          	zext.b	s1,s1
ffffffffc020161c:	09a1                	addi	s3,s3,8
ffffffffc020161e:	01448563          	beq	s1,s4,ffffffffc0201628 <slub_check+0xf2>
            small[small_count] = slub_alloc(small_sizes[i]);
ffffffffc0201622:	0009bc03          	ld	s8,0(s3)
ffffffffc0201626:	bfad                	j	ffffffffc02015a0 <slub_check+0x6a>
        }
    }
    for (size_t i = 0; i < small_count; i ++) {
ffffffffc0201628:	06810313          	addi	t1,sp,104
ffffffffc020162c:	12810893          	addi	a7,sp,296
ffffffffc0201630:	4781                	li	a5,0
ffffffffc0201632:	cc49                	beqz	s0,ffffffffc02016cc <slub_check+0x196>
        for (size_t j = i + 1; j < small_count; j ++) {
ffffffffc0201634:	00178e13          	addi	t3,a5,1
ffffffffc0201638:	06fc8a63          	beq	s9,a5,ffffffffc02016ac <slub_check+0x176>
    uintptr_t alo = (uintptr_t)a;
ffffffffc020163c:	ff833503          	ld	a0,-8(t1)
    uintptr_t ahi = alo + asize;
ffffffffc0201640:	ff88b803          	ld	a6,-8(a7)
ffffffffc0201644:	86c6                	mv	a3,a7
ffffffffc0201646:	871a                	mv	a4,t1
ffffffffc0201648:	982a                	add	a6,a6,a0
ffffffffc020164a:	8672                	mv	a2,t3
    uintptr_t blo = (uintptr_t)b;
ffffffffc020164c:	630c                	ld	a1,0(a4)
    uintptr_t bhi = blo + bsize;
ffffffffc020164e:	629c                	ld	a5,0(a3)
ffffffffc0201650:	97ae                	add	a5,a5,a1
    return alo < bhi && blo < ahi;
ffffffffc0201652:	02f57463          	bgeu	a0,a5,ffffffffc020167a <slub_check+0x144>
ffffffffc0201656:	0305f263          	bgeu	a1,a6,ffffffffc020167a <slub_check+0x144>
            assert(!slub_test_overlap(small[i], small_size[i],
ffffffffc020165a:	00001697          	auipc	a3,0x1
ffffffffc020165e:	1de68693          	addi	a3,a3,478 # ffffffffc0202838 <buddy_system_pmm_manager+0x2f0>
ffffffffc0201662:	00001617          	auipc	a2,0x1
ffffffffc0201666:	c1660613          	addi	a2,a2,-1002 # ffffffffc0202278 <etext+0x292>
ffffffffc020166a:	11200593          	li	a1,274
ffffffffc020166e:	00001517          	auipc	a0,0x1
ffffffffc0201672:	0b250513          	addi	a0,a0,178 # ffffffffc0202720 <buddy_system_pmm_manager+0x1d8>
ffffffffc0201676:	b55fe0ef          	jal	ra,ffffffffc02001ca <__panic>
        for (size_t j = i + 1; j < small_count; j ++) {
ffffffffc020167a:	0605                	addi	a2,a2,1
ffffffffc020167c:	0721                	addi	a4,a4,8
ffffffffc020167e:	06a1                	addi	a3,a3,8
ffffffffc0201680:	fdb666e3          	bltu	a2,s11,ffffffffc020164c <slub_check+0x116>
ffffffffc0201684:	0321                	addi	t1,t1,8
ffffffffc0201686:	08a1                	addi	a7,a7,8
ffffffffc0201688:	87f2                	mv	a5,t3
ffffffffc020168a:	b76d                	j	ffffffffc0201634 <slub_check+0xfe>
        assert(bytes[i] == (unsigned char)(seed + i));
ffffffffc020168c:	00001697          	auipc	a3,0x1
ffffffffc0201690:	18468693          	addi	a3,a3,388 # ffffffffc0202810 <buddy_system_pmm_manager+0x2c8>
ffffffffc0201694:	00001617          	auipc	a2,0x1
ffffffffc0201698:	be460613          	addi	a2,a2,-1052 # ffffffffc0202278 <etext+0x292>
ffffffffc020169c:	0ec00593          	li	a1,236
ffffffffc02016a0:	00001517          	auipc	a0,0x1
ffffffffc02016a4:	08050513          	addi	a0,a0,128 # ffffffffc0202720 <buddy_system_pmm_manager+0x1d8>
ffffffffc02016a8:	b23fe0ef          	jal	ra,ffffffffc02001ca <__panic>
ffffffffc02016ac:	1080                	addi	s0,sp,96
        for (size_t j = i + 1; j < small_count; j ++) {
ffffffffc02016ae:	4481                	li	s1,0
    assert(slub_initialized);
ffffffffc02016b0:	000aa783          	lw	a5,0(s5)
                                      small[j], small_size[j]));
        }
    }

    for (size_t i = 0; i < small_count; i += 2) {
        slub_free(small[i]);
ffffffffc02016b4:	6008                	ld	a0,0(s0)
    assert(slub_initialized);
ffffffffc02016b6:	18078e63          	beqz	a5,ffffffffc0201852 <slub_check+0x31c>
    if (ptr == NULL) {
ffffffffc02016ba:	c119                	beqz	a0,ffffffffc02016c0 <slub_check+0x18a>
ffffffffc02016bc:	a77ff0ef          	jal	ra,ffffffffc0201132 <slub_free.part.0>
        small[i] = NULL;
ffffffffc02016c0:	00043023          	sd	zero,0(s0)
    for (size_t i = 0; i < small_count; i += 2) {
ffffffffc02016c4:	0489                	addi	s1,s1,2
ffffffffc02016c6:	0441                	addi	s0,s0,16
ffffffffc02016c8:	ffb4e4e3          	bltu	s1,s11,ffffffffc02016b0 <slub_check+0x17a>
ffffffffc02016cc:	1000                	addi	s0,sp,32
        for (size_t j = i + 1; j < small_count; j ++) {
ffffffffc02016ce:	8922                	mv	s2,s0
    }
    void *reused[8];
    for (size_t i = 0; i < 8; i ++) {
ffffffffc02016d0:	4481                	li	s1,0
        reused[i] = slub_alloc(8);
ffffffffc02016d2:	4521                	li	a0,8
ffffffffc02016d4:	bedff0ef          	jal	ra,ffffffffc02012c0 <slub_alloc>
ffffffffc02016d8:	00a93023          	sd	a0,0(s2)
ffffffffc02016dc:	87aa                	mv	a5,a0
        assert(reused[i] != NULL);
ffffffffc02016de:	18050a63          	beqz	a0,ffffffffc0201872 <slub_check+0x33c>
        slub_test_write(reused[i], 8, (unsigned char)(0xa0 + i));
ffffffffc02016e2:	fa04861b          	addiw	a2,s1,-96
    for (size_t i = 0; i < size; i ++) {
ffffffffc02016e6:	8e09                	sub	a2,a2,a0
ffffffffc02016e8:	00850593          	addi	a1,a0,8
        slub_test_write(reused[i], 8, (unsigned char)(0xa0 + i));
ffffffffc02016ec:	872a                	mv	a4,a0
ffffffffc02016ee:	0ff67613          	zext.b	a2,a2
        bytes[i] = (unsigned char)(seed + i);
ffffffffc02016f2:	00c706bb          	addw	a3,a4,a2
ffffffffc02016f6:	00d70023          	sb	a3,0(a4)
    for (size_t i = 0; i < size; i ++) {
ffffffffc02016fa:	0705                	addi	a4,a4,1
ffffffffc02016fc:	feb71be3          	bne	a4,a1,ffffffffc02016f2 <slub_check+0x1bc>
        assert(bytes[i] == (unsigned char)(seed + i));
ffffffffc0201700:	0007c683          	lbu	a3,0(a5)
ffffffffc0201704:	00c7873b          	addw	a4,a5,a2
ffffffffc0201708:	0ff77713          	zext.b	a4,a4
ffffffffc020170c:	f8e690e3          	bne	a3,a4,ffffffffc020168c <slub_check+0x156>
    for (size_t i = 0; i < size; i ++) {
ffffffffc0201710:	0785                	addi	a5,a5,1
ffffffffc0201712:	feb797e3          	bne	a5,a1,ffffffffc0201700 <slub_check+0x1ca>
    for (size_t i = 0; i < 8; i ++) {
ffffffffc0201716:	0485                	addi	s1,s1,1
ffffffffc0201718:	47a1                	li	a5,8
ffffffffc020171a:	0921                	addi	s2,s2,8
ffffffffc020171c:	faf49be3          	bne	s1,a5,ffffffffc02016d2 <slub_check+0x19c>
    }
    for (size_t i = 0; i < small_count; i ++) {
ffffffffc0201720:	04040493          	addi	s1,s0,64
ffffffffc0201724:	060d8263          	beqz	s11,ffffffffc0201788 <slub_check+0x252>
        if (small[i] != NULL) {
ffffffffc0201728:	7506                	ld	a0,96(sp)
ffffffffc020172a:	1090                	addi	a2,sp,96
ffffffffc020172c:	121c                	addi	a5,sp,288
    for (size_t i = 0; i < small_count; i ++) {
ffffffffc020172e:	4681                	li	a3,0
ffffffffc0201730:	04040493          	addi	s1,s0,64
        if (small[i] != NULL) {
ffffffffc0201734:	e911                	bnez	a0,ffffffffc0201748 <slub_check+0x212>
    for (size_t i = 0; i < small_count; i ++) {
ffffffffc0201736:	00168713          	addi	a4,a3,1
ffffffffc020173a:	0621                	addi	a2,a2,8
ffffffffc020173c:	07a1                	addi	a5,a5,8
ffffffffc020173e:	04dc8563          	beq	s9,a3,ffffffffc0201788 <slub_check+0x252>
        if (small[i] != NULL) {
ffffffffc0201742:	6208                	ld	a0,0(a2)
ffffffffc0201744:	86ba                	mv	a3,a4
ffffffffc0201746:	d965                	beqz	a0,ffffffffc0201736 <slub_check+0x200>
    uintptr_t ahi = alo + asize;
ffffffffc0201748:	638c                	ld	a1,0(a5)
ffffffffc020174a:	8722                	mv	a4,s0
ffffffffc020174c:	95aa                	add	a1,a1,a0
    uintptr_t blo = (uintptr_t)b;
ffffffffc020174e:	00073803          	ld	a6,0(a4)
    uintptr_t bhi = blo + bsize;
ffffffffc0201752:	00880893          	addi	a7,a6,8
    return alo < bhi && blo < ahi;
ffffffffc0201756:	03157f63          	bgeu	a0,a7,ffffffffc0201794 <slub_check+0x25e>
ffffffffc020175a:	02b87d63          	bgeu	a6,a1,ffffffffc0201794 <slub_check+0x25e>
            for (size_t j = 0; j < 8; j ++) {
                assert(!slub_test_overlap(small[i], small_size[i],
ffffffffc020175e:	00001697          	auipc	a3,0x1
ffffffffc0201762:	13a68693          	addi	a3,a3,314 # ffffffffc0202898 <buddy_system_pmm_manager+0x350>
ffffffffc0201766:	00001617          	auipc	a2,0x1
ffffffffc020176a:	b1260613          	addi	a2,a2,-1262 # ffffffffc0202278 <etext+0x292>
ffffffffc020176e:	12400593          	li	a1,292
ffffffffc0201772:	00001517          	auipc	a0,0x1
ffffffffc0201776:	fae50513          	addi	a0,a0,-82 # ffffffffc0202720 <buddy_system_pmm_manager+0x1d8>
ffffffffc020177a:	a51fe0ef          	jal	ra,ffffffffc02001ca <__panic>
ffffffffc020177e:	9b5ff0ef          	jal	ra,ffffffffc0201132 <slub_free.part.0>
                                          reused[j], 8));
            }
        }
    }
    for (size_t i = 0; i < 8; i ++) {
ffffffffc0201782:	0421                	addi	s0,s0,8
ffffffffc0201784:	00848c63          	beq	s1,s0,ffffffffc020179c <slub_check+0x266>
    assert(slub_initialized);
ffffffffc0201788:	000aa783          	lw	a5,0(s5)
        slub_free(reused[i]);
ffffffffc020178c:	6008                	ld	a0,0(s0)
    assert(slub_initialized);
ffffffffc020178e:	c3f1                	beqz	a5,ffffffffc0201852 <slub_check+0x31c>
    if (ptr == NULL) {
ffffffffc0201790:	f57d                	bnez	a0,ffffffffc020177e <slub_check+0x248>
ffffffffc0201792:	bfc5                	j	ffffffffc0201782 <slub_check+0x24c>
            for (size_t j = 0; j < 8; j ++) {
ffffffffc0201794:	0721                	addi	a4,a4,8
ffffffffc0201796:	fae49ce3          	bne	s1,a4,ffffffffc020174e <slub_check+0x218>
ffffffffc020179a:	bf71                	j	ffffffffc0201736 <slub_check+0x200>
    }
    for (size_t i = 0; i < small_count; i ++) {
ffffffffc020179c:	1080                	addi	s0,sp,96
ffffffffc020179e:	4481                	li	s1,0
ffffffffc02017a0:	000d9463          	bnez	s11,ffffffffc02017a8 <slub_check+0x272>
ffffffffc02017a4:	a831                	j	ffffffffc02017c0 <slub_check+0x28a>
ffffffffc02017a6:	84be                	mv	s1,a5
        if (small[i] != NULL) {
ffffffffc02017a8:	6008                	ld	a0,0(s0)
ffffffffc02017aa:	c511                	beqz	a0,ffffffffc02017b6 <slub_check+0x280>
    assert(slub_initialized);
ffffffffc02017ac:	000aa783          	lw	a5,0(s5)
ffffffffc02017b0:	c3cd                	beqz	a5,ffffffffc0201852 <slub_check+0x31c>
    if (ptr == NULL) {
ffffffffc02017b2:	981ff0ef          	jal	ra,ffffffffc0201132 <slub_free.part.0>
    for (size_t i = 0; i < small_count; i ++) {
ffffffffc02017b6:	00148793          	addi	a5,s1,1
ffffffffc02017ba:	0421                	addi	s0,s0,8
ffffffffc02017bc:	fe9c95e3          	bne	s9,s1,ffffffffc02017a6 <slub_check+0x270>
ffffffffc02017c0:	10100913          	li	s2,257
ffffffffc02017c4:	0024                	addi	s1,sp,8
    }

    static const size_t large_sizes[] = {257, PGSIZE, PGSIZE + 1};
    void *large[3];
    for (size_t i = 0; i < 3; i ++) {
        large[i] = slub_alloc(large_sizes[i]);
ffffffffc02017c6:	854a                	mv	a0,s2
ffffffffc02017c8:	89a6                	mv	s3,s1
ffffffffc02017ca:	af7ff0ef          	jal	ra,ffffffffc02012c0 <slub_alloc>
ffffffffc02017ce:	00a9b023          	sd	a0,0(s3)
ffffffffc02017d2:	00001a17          	auipc	s4,0x1
ffffffffc02017d6:	25ea0a13          	addi	s4,s4,606 # ffffffffc0202a30 <large_sizes.0>
ffffffffc02017da:	05000413          	li	s0,80
    for (size_t i = 0; i < 3; i ++) {
ffffffffc02017de:	05300b93          	li	s7,83
        assert(large[i] != NULL);
ffffffffc02017e2:	c921                	beqz	a0,ffffffffc0201832 <slub_check+0x2fc>
        unsigned char *bytes = (unsigned char *)large[i];
        bytes[0] = (unsigned char)(0x30 + i);
ffffffffc02017e4:	fe04069b          	addiw	a3,s0,-32
        bytes[large_sizes[i] / 2] = (unsigned char)(0x50 + i);
ffffffffc02017e8:	00195713          	srli	a4,s2,0x1
        bytes[0] = (unsigned char)(0x30 + i);
ffffffffc02017ec:	0ff6f693          	zext.b	a3,a3
ffffffffc02017f0:	00d50023          	sb	a3,0(a0)
        bytes[large_sizes[i] / 2] = (unsigned char)(0x50 + i);
ffffffffc02017f4:	972a                	add	a4,a4,a0
ffffffffc02017f6:	00870023          	sb	s0,0(a4)
        bytes[large_sizes[i] - 1] = (unsigned char)(0x70 + i);
ffffffffc02017fa:	992a                	add	s2,s2,a0
ffffffffc02017fc:	0204061b          	addiw	a2,s0,32
ffffffffc0201800:	fec90fa3          	sb	a2,-1(s2)
        assert(bytes[0] == (unsigned char)(0x30 + i));
ffffffffc0201804:	00054783          	lbu	a5,0(a0)
ffffffffc0201808:	14d79463          	bne	a5,a3,ffffffffc0201950 <slub_check+0x41a>
        assert(bytes[large_sizes[i] / 2] == (unsigned char)(0x50 + i));
ffffffffc020180c:	00074783          	lbu	a5,0(a4)
ffffffffc0201810:	16879063          	bne	a5,s0,ffffffffc0201970 <slub_check+0x43a>
    for (size_t i = 0; i < 3; i ++) {
ffffffffc0201814:	2405                	addiw	s0,s0,1
ffffffffc0201816:	0ff47413          	zext.b	s0,s0
ffffffffc020181a:	09a1                	addi	s3,s3,8
ffffffffc020181c:	0a21                	addi	s4,s4,8
ffffffffc020181e:	07740a63          	beq	s0,s7,ffffffffc0201892 <slub_check+0x35c>
        large[i] = slub_alloc(large_sizes[i]);
ffffffffc0201822:	000a3903          	ld	s2,0(s4)
ffffffffc0201826:	854a                	mv	a0,s2
ffffffffc0201828:	a99ff0ef          	jal	ra,ffffffffc02012c0 <slub_alloc>
ffffffffc020182c:	00a9b023          	sd	a0,0(s3)
        assert(large[i] != NULL);
ffffffffc0201830:	f955                	bnez	a0,ffffffffc02017e4 <slub_check+0x2ae>
ffffffffc0201832:	00001697          	auipc	a3,0x1
ffffffffc0201836:	0a668693          	addi	a3,a3,166 # ffffffffc02028d8 <buddy_system_pmm_manager+0x390>
ffffffffc020183a:	00001617          	auipc	a2,0x1
ffffffffc020183e:	a3e60613          	addi	a2,a2,-1474 # ffffffffc0202278 <etext+0x292>
ffffffffc0201842:	13600593          	li	a1,310
ffffffffc0201846:	00001517          	auipc	a0,0x1
ffffffffc020184a:	eda50513          	addi	a0,a0,-294 # ffffffffc0202720 <buddy_system_pmm_manager+0x1d8>
ffffffffc020184e:	97dfe0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(slub_initialized);
ffffffffc0201852:	00001697          	auipc	a3,0x1
ffffffffc0201856:	f5e68693          	addi	a3,a3,-162 # ffffffffc02027b0 <buddy_system_pmm_manager+0x268>
ffffffffc020185a:	00001617          	auipc	a2,0x1
ffffffffc020185e:	a1e60613          	addi	a2,a2,-1506 # ffffffffc0202278 <etext+0x292>
ffffffffc0201862:	0c300593          	li	a1,195
ffffffffc0201866:	00001517          	auipc	a0,0x1
ffffffffc020186a:	eba50513          	addi	a0,a0,-326 # ffffffffc0202720 <buddy_system_pmm_manager+0x1d8>
ffffffffc020186e:	95dfe0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(reused[i] != NULL);
ffffffffc0201872:	00001697          	auipc	a3,0x1
ffffffffc0201876:	00e68693          	addi	a3,a3,14 # ffffffffc0202880 <buddy_system_pmm_manager+0x338>
ffffffffc020187a:	00001617          	auipc	a2,0x1
ffffffffc020187e:	9fe60613          	addi	a2,a2,-1538 # ffffffffc0202278 <etext+0x292>
ffffffffc0201882:	11e00593          	li	a1,286
ffffffffc0201886:	00001517          	auipc	a0,0x1
ffffffffc020188a:	e9a50513          	addi	a0,a0,-358 # ffffffffc0202720 <buddy_system_pmm_manager+0x1d8>
ffffffffc020188e:	93dfe0ef          	jal	ra,ffffffffc02001ca <__panic>
    uintptr_t blo = (uintptr_t)b;
ffffffffc0201892:	6bc2                	ld	s7,16(sp)
    uintptr_t alo = (uintptr_t)a;
ffffffffc0201894:	6922                	ld	s2,8(sp)
    uintptr_t bhi = blo + bsize;
ffffffffc0201896:	6985                	lui	s3,0x1
ffffffffc0201898:	99de                	add	s3,s3,s7
    return alo < bhi && blo < ahi;
ffffffffc020189a:	01397663          	bgeu	s2,s3,ffffffffc02018a6 <slub_check+0x370>
    uintptr_t ahi = alo + asize;
ffffffffc020189e:	10190793          	addi	a5,s2,257
    return alo < bhi && blo < ahi;
ffffffffc02018a2:	0efbe763          	bltu	s7,a5,ffffffffc0201990 <slub_check+0x45a>
    uintptr_t blo = (uintptr_t)b;
ffffffffc02018a6:	6a62                	ld	s4,24(sp)
    uintptr_t bhi = blo + bsize;
ffffffffc02018a8:	6405                	lui	s0,0x1
ffffffffc02018aa:	0405                	addi	s0,s0,1
ffffffffc02018ac:	9452                	add	s0,s0,s4
    return alo < bhi && blo < ahi;
ffffffffc02018ae:	00897663          	bgeu	s2,s0,ffffffffc02018ba <slub_check+0x384>
    uintptr_t ahi = alo + asize;
ffffffffc02018b2:	10190793          	addi	a5,s2,257
    return alo < bhi && blo < ahi;
ffffffffc02018b6:	0cfa6d63          	bltu	s4,a5,ffffffffc0201990 <slub_check+0x45a>
ffffffffc02018ba:	008bf463          	bgeu	s7,s0,ffffffffc02018c2 <slub_check+0x38c>
ffffffffc02018be:	0d3a6963          	bltu	s4,s3,ffffffffc0201990 <slub_check+0x45a>
        for (size_t j = i + 1; j < 3; j ++) {
            assert(!slub_test_overlap(large[i], large_sizes[i],
                                      large[j], large_sizes[j]));
        }
    }
    void *mixed = slub_alloc(32);
ffffffffc02018c2:	02000513          	li	a0,32
ffffffffc02018c6:	9fbff0ef          	jal	ra,ffffffffc02012c0 <slub_alloc>
    assert(mixed != NULL);
ffffffffc02018ca:	14050363          	beqz	a0,ffffffffc0201a10 <slub_check+0x4da>
ffffffffc02018ce:	fc000793          	li	a5,-64
ffffffffc02018d2:	9f89                	subw	a5,a5,a0
ffffffffc02018d4:	02050713          	addi	a4,a0,32
ffffffffc02018d8:	86aa                	mv	a3,a0
ffffffffc02018da:	0ff7f793          	zext.b	a5,a5
        bytes[i] = (unsigned char)(seed + i);
ffffffffc02018de:	00f6863b          	addw	a2,a3,a5
ffffffffc02018e2:	00c68023          	sb	a2,0(a3)
    for (size_t i = 0; i < size; i ++) {
ffffffffc02018e6:	0685                	addi	a3,a3,1
ffffffffc02018e8:	fed71be3          	bne	a4,a3,ffffffffc02018de <slub_check+0x3a8>
ffffffffc02018ec:	86aa                	mv	a3,a0
        assert(bytes[i] == (unsigned char)(seed + i));
ffffffffc02018ee:	0006c583          	lbu	a1,0(a3)
ffffffffc02018f2:	00f6863b          	addw	a2,a3,a5
ffffffffc02018f6:	0ff67613          	zext.b	a2,a2
ffffffffc02018fa:	d8c599e3          	bne	a1,a2,ffffffffc020168c <slub_check+0x156>
    for (size_t i = 0; i < size; i ++) {
ffffffffc02018fe:	0685                	addi	a3,a3,1
ffffffffc0201900:	fed717e3          	bne	a4,a3,ffffffffc02018ee <slub_check+0x3b8>
    uintptr_t bhi = blo + bsize;
ffffffffc0201904:	10190793          	addi	a5,s2,257
    return alo < bhi && blo < ahi;
ffffffffc0201908:	12f57463          	bgeu	a0,a5,ffffffffc0201a30 <slub_check+0x4fa>
ffffffffc020190c:	12e97263          	bgeu	s2,a4,ffffffffc0201a30 <slub_check+0x4fa>
    slub_test_write(mixed, 32, 0xc0);
    for (size_t i = 0; i < 3; i ++) {
        assert(!slub_test_overlap(mixed, 32, large[i], large_sizes[i]));
ffffffffc0201910:	00001697          	auipc	a3,0x1
ffffffffc0201914:	09868693          	addi	a3,a3,152 # ffffffffc02029a8 <buddy_system_pmm_manager+0x460>
ffffffffc0201918:	00001617          	auipc	a2,0x1
ffffffffc020191c:	96060613          	addi	a2,a2,-1696 # ffffffffc0202278 <etext+0x292>
ffffffffc0201920:	14900593          	li	a1,329
ffffffffc0201924:	00001517          	auipc	a0,0x1
ffffffffc0201928:	dfc50513          	addi	a0,a0,-516 # ffffffffc0202720 <buddy_system_pmm_manager+0x1d8>
ffffffffc020192c:	89ffe0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == saved_nr_free);
ffffffffc0201930:	00001697          	auipc	a3,0x1
ffffffffc0201934:	e9868693          	addi	a3,a3,-360 # ffffffffc02027c8 <buddy_system_pmm_manager+0x280>
ffffffffc0201938:	00001617          	auipc	a2,0x1
ffffffffc020193c:	94060613          	addi	a2,a2,-1728 # ffffffffc0202278 <etext+0x292>
ffffffffc0201940:	10000593          	li	a1,256
ffffffffc0201944:	00001517          	auipc	a0,0x1
ffffffffc0201948:	ddc50513          	addi	a0,a0,-548 # ffffffffc0202720 <buddy_system_pmm_manager+0x1d8>
ffffffffc020194c:	87ffe0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(bytes[0] == (unsigned char)(0x30 + i));
ffffffffc0201950:	00001697          	auipc	a3,0x1
ffffffffc0201954:	fa068693          	addi	a3,a3,-96 # ffffffffc02028f0 <buddy_system_pmm_manager+0x3a8>
ffffffffc0201958:	00001617          	auipc	a2,0x1
ffffffffc020195c:	92060613          	addi	a2,a2,-1760 # ffffffffc0202278 <etext+0x292>
ffffffffc0201960:	13b00593          	li	a1,315
ffffffffc0201964:	00001517          	auipc	a0,0x1
ffffffffc0201968:	dbc50513          	addi	a0,a0,-580 # ffffffffc0202720 <buddy_system_pmm_manager+0x1d8>
ffffffffc020196c:	85ffe0ef          	jal	ra,ffffffffc02001ca <__panic>
        assert(bytes[large_sizes[i] / 2] == (unsigned char)(0x50 + i));
ffffffffc0201970:	00001697          	auipc	a3,0x1
ffffffffc0201974:	fa868693          	addi	a3,a3,-88 # ffffffffc0202918 <buddy_system_pmm_manager+0x3d0>
ffffffffc0201978:	00001617          	auipc	a2,0x1
ffffffffc020197c:	90060613          	addi	a2,a2,-1792 # ffffffffc0202278 <etext+0x292>
ffffffffc0201980:	13c00593          	li	a1,316
ffffffffc0201984:	00001517          	auipc	a0,0x1
ffffffffc0201988:	d9c50513          	addi	a0,a0,-612 # ffffffffc0202720 <buddy_system_pmm_manager+0x1d8>
ffffffffc020198c:	83ffe0ef          	jal	ra,ffffffffc02001ca <__panic>
            assert(!slub_test_overlap(large[i], large_sizes[i],
ffffffffc0201990:	00001697          	auipc	a3,0x1
ffffffffc0201994:	fc068693          	addi	a3,a3,-64 # ffffffffc0202950 <buddy_system_pmm_manager+0x408>
ffffffffc0201998:	00001617          	auipc	a2,0x1
ffffffffc020199c:	8e060613          	addi	a2,a2,-1824 # ffffffffc0202278 <etext+0x292>
ffffffffc02019a0:	14100593          	li	a1,321
ffffffffc02019a4:	00001517          	auipc	a0,0x1
ffffffffc02019a8:	d7c50513          	addi	a0,a0,-644 # ffffffffc0202720 <buddy_system_pmm_manager+0x1d8>
ffffffffc02019ac:	81ffe0ef          	jal	ra,ffffffffc02001ca <__panic>
            assert(small[small_count] != NULL);
ffffffffc02019b0:	00001697          	auipc	a3,0x1
ffffffffc02019b4:	e4068693          	addi	a3,a3,-448 # ffffffffc02027f0 <buddy_system_pmm_manager+0x2a8>
ffffffffc02019b8:	00001617          	auipc	a2,0x1
ffffffffc02019bc:	8c060613          	addi	a2,a2,-1856 # ffffffffc0202278 <etext+0x292>
ffffffffc02019c0:	10900593          	li	a1,265
ffffffffc02019c4:	00001517          	auipc	a0,0x1
ffffffffc02019c8:	d5c50513          	addi	a0,a0,-676 # ffffffffc0202720 <buddy_system_pmm_manager+0x1d8>
ffffffffc02019cc:	ffefe0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(slub_initialized);
ffffffffc02019d0:	00001697          	auipc	a3,0x1
ffffffffc02019d4:	de068693          	addi	a3,a3,-544 # ffffffffc02027b0 <buddy_system_pmm_manager+0x268>
ffffffffc02019d8:	00001617          	auipc	a2,0x1
ffffffffc02019dc:	8a060613          	addi	a2,a2,-1888 # ffffffffc0202278 <etext+0x292>
ffffffffc02019e0:	0fb00593          	li	a1,251
ffffffffc02019e4:	00001517          	auipc	a0,0x1
ffffffffc02019e8:	d3c50513          	addi	a0,a0,-708 # ffffffffc0202720 <buddy_system_pmm_manager+0x1d8>
ffffffffc02019ec:	fdefe0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(slub_initialized);
ffffffffc02019f0:	00001697          	auipc	a3,0x1
ffffffffc02019f4:	dc068693          	addi	a3,a3,-576 # ffffffffc02027b0 <buddy_system_pmm_manager+0x268>
ffffffffc02019f8:	00001617          	auipc	a2,0x1
ffffffffc02019fc:	88060613          	addi	a2,a2,-1920 # ffffffffc0202278 <etext+0x292>
ffffffffc0201a00:	09800593          	li	a1,152
ffffffffc0201a04:	00001517          	auipc	a0,0x1
ffffffffc0201a08:	d1c50513          	addi	a0,a0,-740 # ffffffffc0202720 <buddy_system_pmm_manager+0x1d8>
ffffffffc0201a0c:	fbefe0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(mixed != NULL);
ffffffffc0201a10:	00001697          	auipc	a3,0x1
ffffffffc0201a14:	f8868693          	addi	a3,a3,-120 # ffffffffc0202998 <buddy_system_pmm_manager+0x450>
ffffffffc0201a18:	00001617          	auipc	a2,0x1
ffffffffc0201a1c:	86060613          	addi	a2,a2,-1952 # ffffffffc0202278 <etext+0x292>
ffffffffc0201a20:	14600593          	li	a1,326
ffffffffc0201a24:	00001517          	auipc	a0,0x1
ffffffffc0201a28:	cfc50513          	addi	a0,a0,-772 # ffffffffc0202720 <buddy_system_pmm_manager+0x1d8>
ffffffffc0201a2c:	f9efe0ef          	jal	ra,ffffffffc02001ca <__panic>
    return alo < bhi && blo < ahi;
ffffffffc0201a30:	01357463          	bgeu	a0,s3,ffffffffc0201a38 <slub_check+0x502>
ffffffffc0201a34:	ecebeee3          	bltu	s7,a4,ffffffffc0201910 <slub_check+0x3da>
ffffffffc0201a38:	00857463          	bgeu	a0,s0,ffffffffc0201a40 <slub_check+0x50a>
ffffffffc0201a3c:	ecea6ae3          	bltu	s4,a4,ffffffffc0201910 <slub_check+0x3da>
    assert(slub_initialized);
ffffffffc0201a40:	000aa783          	lw	a5,0(s5)
ffffffffc0201a44:	e00787e3          	beqz	a5,ffffffffc0201852 <slub_check+0x31c>
    if (ptr == NULL) {
ffffffffc0201a48:	eeaff0ef          	jal	ra,ffffffffc0201132 <slub_free.part.0>
    }
    slub_free(mixed);
    for (size_t i = 0; i < 3; i ++) {
ffffffffc0201a4c:	01848413          	addi	s0,s1,24
    assert(slub_initialized);
ffffffffc0201a50:	000aa783          	lw	a5,0(s5)
        slub_free(large[i]);
ffffffffc0201a54:	6088                	ld	a0,0(s1)
    assert(slub_initialized);
ffffffffc0201a56:	de078ee3          	beqz	a5,ffffffffc0201852 <slub_check+0x31c>
    if (ptr == NULL) {
ffffffffc0201a5a:	c119                	beqz	a0,ffffffffc0201a60 <slub_check+0x52a>
ffffffffc0201a5c:	ed6ff0ef          	jal	ra,ffffffffc0201132 <slub_free.part.0>
    for (size_t i = 0; i < 3; i ++) {
ffffffffc0201a60:	04a1                	addi	s1,s1,8
ffffffffc0201a62:	fe9417e3          	bne	s0,s1,ffffffffc0201a50 <slub_check+0x51a>
    }

    assert(slub_alloc(~(size_t)0) == NULL);
ffffffffc0201a66:	557d                	li	a0,-1
ffffffffc0201a68:	859ff0ef          	jal	ra,ffffffffc02012c0 <slub_alloc>
ffffffffc0201a6c:	e13d                	bnez	a0,ffffffffc0201ad2 <slub_check+0x59c>
    assert(nr_free_pages() == saved_nr_free);
ffffffffc0201a6e:	cc0ff0ef          	jal	ra,ffffffffc0200f2e <nr_free_pages>
ffffffffc0201a72:	0d651063          	bne	a0,s6,ffffffffc0201b32 <slub_check+0x5fc>
    void *last = slub_alloc(32);
ffffffffc0201a76:	02000513          	li	a0,32
ffffffffc0201a7a:	847ff0ef          	jal	ra,ffffffffc02012c0 <slub_alloc>
    assert(last != NULL);
ffffffffc0201a7e:	c951                	beqz	a0,ffffffffc0201b12 <slub_check+0x5dc>
    assert(slub_initialized);
ffffffffc0201a80:	000aa783          	lw	a5,0(s5)
ffffffffc0201a84:	dc0787e3          	beqz	a5,ffffffffc0201852 <slub_check+0x31c>
    if (ptr == NULL) {
ffffffffc0201a88:	eaaff0ef          	jal	ra,ffffffffc0201132 <slub_free.part.0>
    slub_free(last);
    assert(nr_free_pages() == saved_nr_free);
ffffffffc0201a8c:	ca2ff0ef          	jal	ra,ffffffffc0200f2e <nr_free_pages>
ffffffffc0201a90:	07651163          	bne	a0,s6,ffffffffc0201af2 <slub_check+0x5bc>
    cprintf("slub_check() succeeded!\n");
}
ffffffffc0201a94:	24013403          	ld	s0,576(sp)
ffffffffc0201a98:	24813083          	ld	ra,584(sp)
ffffffffc0201a9c:	23813483          	ld	s1,568(sp)
ffffffffc0201aa0:	23013903          	ld	s2,560(sp)
ffffffffc0201aa4:	22813983          	ld	s3,552(sp)
ffffffffc0201aa8:	22013a03          	ld	s4,544(sp)
ffffffffc0201aac:	21813a83          	ld	s5,536(sp)
ffffffffc0201ab0:	21013b03          	ld	s6,528(sp)
ffffffffc0201ab4:	20813b83          	ld	s7,520(sp)
ffffffffc0201ab8:	20013c03          	ld	s8,512(sp)
ffffffffc0201abc:	7cfe                	ld	s9,504(sp)
ffffffffc0201abe:	7d5e                	ld	s10,496(sp)
ffffffffc0201ac0:	7dbe                	ld	s11,488(sp)
    cprintf("slub_check() succeeded!\n");
ffffffffc0201ac2:	00001517          	auipc	a0,0x1
ffffffffc0201ac6:	f4e50513          	addi	a0,a0,-178 # ffffffffc0202a10 <buddy_system_pmm_manager+0x4c8>
}
ffffffffc0201aca:	25010113          	addi	sp,sp,592
    cprintf("slub_check() succeeded!\n");
ffffffffc0201ace:	e86fe06f          	j	ffffffffc0200154 <cprintf>
    assert(slub_alloc(~(size_t)0) == NULL);
ffffffffc0201ad2:	00001697          	auipc	a3,0x1
ffffffffc0201ad6:	f0e68693          	addi	a3,a3,-242 # ffffffffc02029e0 <buddy_system_pmm_manager+0x498>
ffffffffc0201ada:	00000617          	auipc	a2,0x0
ffffffffc0201ade:	79e60613          	addi	a2,a2,1950 # ffffffffc0202278 <etext+0x292>
ffffffffc0201ae2:	15000593          	li	a1,336
ffffffffc0201ae6:	00001517          	auipc	a0,0x1
ffffffffc0201aea:	c3a50513          	addi	a0,a0,-966 # ffffffffc0202720 <buddy_system_pmm_manager+0x1d8>
ffffffffc0201aee:	edcfe0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == saved_nr_free);
ffffffffc0201af2:	00001697          	auipc	a3,0x1
ffffffffc0201af6:	cd668693          	addi	a3,a3,-810 # ffffffffc02027c8 <buddy_system_pmm_manager+0x280>
ffffffffc0201afa:	00000617          	auipc	a2,0x0
ffffffffc0201afe:	77e60613          	addi	a2,a2,1918 # ffffffffc0202278 <etext+0x292>
ffffffffc0201b02:	15500593          	li	a1,341
ffffffffc0201b06:	00001517          	auipc	a0,0x1
ffffffffc0201b0a:	c1a50513          	addi	a0,a0,-998 # ffffffffc0202720 <buddy_system_pmm_manager+0x1d8>
ffffffffc0201b0e:	ebcfe0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(last != NULL);
ffffffffc0201b12:	00001697          	auipc	a3,0x1
ffffffffc0201b16:	eee68693          	addi	a3,a3,-274 # ffffffffc0202a00 <buddy_system_pmm_manager+0x4b8>
ffffffffc0201b1a:	00000617          	auipc	a2,0x0
ffffffffc0201b1e:	75e60613          	addi	a2,a2,1886 # ffffffffc0202278 <etext+0x292>
ffffffffc0201b22:	15300593          	li	a1,339
ffffffffc0201b26:	00001517          	auipc	a0,0x1
ffffffffc0201b2a:	bfa50513          	addi	a0,a0,-1030 # ffffffffc0202720 <buddy_system_pmm_manager+0x1d8>
ffffffffc0201b2e:	e9cfe0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(nr_free_pages() == saved_nr_free);
ffffffffc0201b32:	00001697          	auipc	a3,0x1
ffffffffc0201b36:	c9668693          	addi	a3,a3,-874 # ffffffffc02027c8 <buddy_system_pmm_manager+0x280>
ffffffffc0201b3a:	00000617          	auipc	a2,0x0
ffffffffc0201b3e:	73e60613          	addi	a2,a2,1854 # ffffffffc0202278 <etext+0x292>
ffffffffc0201b42:	15100593          	li	a1,337
ffffffffc0201b46:	00001517          	auipc	a0,0x1
ffffffffc0201b4a:	bda50513          	addi	a0,a0,-1062 # ffffffffc0202720 <buddy_system_pmm_manager+0x1d8>
ffffffffc0201b4e:	e7cfe0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0201b52 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201b52:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201b56:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201b58:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201b5c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201b5e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201b62:	f022                	sd	s0,32(sp)
ffffffffc0201b64:	ec26                	sd	s1,24(sp)
ffffffffc0201b66:	e84a                	sd	s2,16(sp)
ffffffffc0201b68:	f406                	sd	ra,40(sp)
ffffffffc0201b6a:	e44e                	sd	s3,8(sp)
ffffffffc0201b6c:	84aa                	mv	s1,a0
ffffffffc0201b6e:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201b70:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201b74:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201b76:	03067e63          	bgeu	a2,a6,ffffffffc0201bb2 <printnum+0x60>
ffffffffc0201b7a:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201b7c:	00805763          	blez	s0,ffffffffc0201b8a <printnum+0x38>
ffffffffc0201b80:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201b82:	85ca                	mv	a1,s2
ffffffffc0201b84:	854e                	mv	a0,s3
ffffffffc0201b86:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201b88:	fc65                	bnez	s0,ffffffffc0201b80 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201b8a:	1a02                	slli	s4,s4,0x20
ffffffffc0201b8c:	00001797          	auipc	a5,0x1
ffffffffc0201b90:	efc78793          	addi	a5,a5,-260 # ffffffffc0202a88 <small_sizes.1+0x40>
ffffffffc0201b94:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201b98:	9a3e                	add	s4,s4,a5
}
ffffffffc0201b9a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201b9c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201ba0:	70a2                	ld	ra,40(sp)
ffffffffc0201ba2:	69a2                	ld	s3,8(sp)
ffffffffc0201ba4:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201ba6:	85ca                	mv	a1,s2
ffffffffc0201ba8:	87a6                	mv	a5,s1
}
ffffffffc0201baa:	6942                	ld	s2,16(sp)
ffffffffc0201bac:	64e2                	ld	s1,24(sp)
ffffffffc0201bae:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201bb0:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201bb2:	03065633          	divu	a2,a2,a6
ffffffffc0201bb6:	8722                	mv	a4,s0
ffffffffc0201bb8:	f9bff0ef          	jal	ra,ffffffffc0201b52 <printnum>
ffffffffc0201bbc:	b7f9                	j	ffffffffc0201b8a <printnum+0x38>

ffffffffc0201bbe <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201bbe:	7119                	addi	sp,sp,-128
ffffffffc0201bc0:	f4a6                	sd	s1,104(sp)
ffffffffc0201bc2:	f0ca                	sd	s2,96(sp)
ffffffffc0201bc4:	ecce                	sd	s3,88(sp)
ffffffffc0201bc6:	e8d2                	sd	s4,80(sp)
ffffffffc0201bc8:	e4d6                	sd	s5,72(sp)
ffffffffc0201bca:	e0da                	sd	s6,64(sp)
ffffffffc0201bcc:	fc5e                	sd	s7,56(sp)
ffffffffc0201bce:	f06a                	sd	s10,32(sp)
ffffffffc0201bd0:	fc86                	sd	ra,120(sp)
ffffffffc0201bd2:	f8a2                	sd	s0,112(sp)
ffffffffc0201bd4:	f862                	sd	s8,48(sp)
ffffffffc0201bd6:	f466                	sd	s9,40(sp)
ffffffffc0201bd8:	ec6e                	sd	s11,24(sp)
ffffffffc0201bda:	892a                	mv	s2,a0
ffffffffc0201bdc:	84ae                	mv	s1,a1
ffffffffc0201bde:	8d32                	mv	s10,a2
ffffffffc0201be0:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201be2:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201be6:	5b7d                	li	s6,-1
ffffffffc0201be8:	00001a97          	auipc	s5,0x1
ffffffffc0201bec:	ed4a8a93          	addi	s5,s5,-300 # ffffffffc0202abc <small_sizes.1+0x74>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201bf0:	00001b97          	auipc	s7,0x1
ffffffffc0201bf4:	0a8b8b93          	addi	s7,s7,168 # ffffffffc0202c98 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201bf8:	000d4503          	lbu	a0,0(s10)
ffffffffc0201bfc:	001d0413          	addi	s0,s10,1
ffffffffc0201c00:	01350a63          	beq	a0,s3,ffffffffc0201c14 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201c04:	c121                	beqz	a0,ffffffffc0201c44 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201c06:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201c08:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201c0a:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201c0c:	fff44503          	lbu	a0,-1(s0) # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0201c10:	ff351ae3          	bne	a0,s3,ffffffffc0201c04 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c14:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201c18:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201c1c:	4c81                	li	s9,0
ffffffffc0201c1e:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201c20:	5c7d                	li	s8,-1
ffffffffc0201c22:	5dfd                	li	s11,-1
ffffffffc0201c24:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201c28:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c2a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201c2e:	0ff5f593          	zext.b	a1,a1
ffffffffc0201c32:	00140d13          	addi	s10,s0,1
ffffffffc0201c36:	04b56263          	bltu	a0,a1,ffffffffc0201c7a <vprintfmt+0xbc>
ffffffffc0201c3a:	058a                	slli	a1,a1,0x2
ffffffffc0201c3c:	95d6                	add	a1,a1,s5
ffffffffc0201c3e:	4194                	lw	a3,0(a1)
ffffffffc0201c40:	96d6                	add	a3,a3,s5
ffffffffc0201c42:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201c44:	70e6                	ld	ra,120(sp)
ffffffffc0201c46:	7446                	ld	s0,112(sp)
ffffffffc0201c48:	74a6                	ld	s1,104(sp)
ffffffffc0201c4a:	7906                	ld	s2,96(sp)
ffffffffc0201c4c:	69e6                	ld	s3,88(sp)
ffffffffc0201c4e:	6a46                	ld	s4,80(sp)
ffffffffc0201c50:	6aa6                	ld	s5,72(sp)
ffffffffc0201c52:	6b06                	ld	s6,64(sp)
ffffffffc0201c54:	7be2                	ld	s7,56(sp)
ffffffffc0201c56:	7c42                	ld	s8,48(sp)
ffffffffc0201c58:	7ca2                	ld	s9,40(sp)
ffffffffc0201c5a:	7d02                	ld	s10,32(sp)
ffffffffc0201c5c:	6de2                	ld	s11,24(sp)
ffffffffc0201c5e:	6109                	addi	sp,sp,128
ffffffffc0201c60:	8082                	ret
            padc = '0';
ffffffffc0201c62:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201c64:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c68:	846a                	mv	s0,s10
ffffffffc0201c6a:	00140d13          	addi	s10,s0,1
ffffffffc0201c6e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201c72:	0ff5f593          	zext.b	a1,a1
ffffffffc0201c76:	fcb572e3          	bgeu	a0,a1,ffffffffc0201c3a <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201c7a:	85a6                	mv	a1,s1
ffffffffc0201c7c:	02500513          	li	a0,37
ffffffffc0201c80:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201c82:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201c86:	8d22                	mv	s10,s0
ffffffffc0201c88:	f73788e3          	beq	a5,s3,ffffffffc0201bf8 <vprintfmt+0x3a>
ffffffffc0201c8c:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201c90:	1d7d                	addi	s10,s10,-1
ffffffffc0201c92:	ff379de3          	bne	a5,s3,ffffffffc0201c8c <vprintfmt+0xce>
ffffffffc0201c96:	b78d                	j	ffffffffc0201bf8 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201c98:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201c9c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ca0:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201ca2:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201ca6:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201caa:	02d86463          	bltu	a6,a3,ffffffffc0201cd2 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201cae:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201cb2:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201cb6:	0186873b          	addw	a4,a3,s8
ffffffffc0201cba:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201cbe:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201cc0:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201cc4:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201cc6:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201cca:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201cce:	fed870e3          	bgeu	a6,a3,ffffffffc0201cae <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201cd2:	f40ddce3          	bgez	s11,ffffffffc0201c2a <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201cd6:	8de2                	mv	s11,s8
ffffffffc0201cd8:	5c7d                	li	s8,-1
ffffffffc0201cda:	bf81                	j	ffffffffc0201c2a <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201cdc:	fffdc693          	not	a3,s11
ffffffffc0201ce0:	96fd                	srai	a3,a3,0x3f
ffffffffc0201ce2:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ce6:	00144603          	lbu	a2,1(s0)
ffffffffc0201cea:	2d81                	sext.w	s11,s11
ffffffffc0201cec:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201cee:	bf35                	j	ffffffffc0201c2a <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201cf0:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201cf4:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201cf8:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201cfa:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201cfc:	bfd9                	j	ffffffffc0201cd2 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201cfe:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201d00:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201d04:	01174463          	blt	a4,a7,ffffffffc0201d0c <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201d08:	1a088e63          	beqz	a7,ffffffffc0201ec4 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201d0c:	000a3603          	ld	a2,0(s4)
ffffffffc0201d10:	46c1                	li	a3,16
ffffffffc0201d12:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201d14:	2781                	sext.w	a5,a5
ffffffffc0201d16:	876e                	mv	a4,s11
ffffffffc0201d18:	85a6                	mv	a1,s1
ffffffffc0201d1a:	854a                	mv	a0,s2
ffffffffc0201d1c:	e37ff0ef          	jal	ra,ffffffffc0201b52 <printnum>
            break;
ffffffffc0201d20:	bde1                	j	ffffffffc0201bf8 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201d22:	000a2503          	lw	a0,0(s4)
ffffffffc0201d26:	85a6                	mv	a1,s1
ffffffffc0201d28:	0a21                	addi	s4,s4,8
ffffffffc0201d2a:	9902                	jalr	s2
            break;
ffffffffc0201d2c:	b5f1                	j	ffffffffc0201bf8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201d2e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201d30:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201d34:	01174463          	blt	a4,a7,ffffffffc0201d3c <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201d38:	18088163          	beqz	a7,ffffffffc0201eba <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201d3c:	000a3603          	ld	a2,0(s4)
ffffffffc0201d40:	46a9                	li	a3,10
ffffffffc0201d42:	8a2e                	mv	s4,a1
ffffffffc0201d44:	bfc1                	j	ffffffffc0201d14 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201d46:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201d4a:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201d4c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201d4e:	bdf1                	j	ffffffffc0201c2a <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201d50:	85a6                	mv	a1,s1
ffffffffc0201d52:	02500513          	li	a0,37
ffffffffc0201d56:	9902                	jalr	s2
            break;
ffffffffc0201d58:	b545                	j	ffffffffc0201bf8 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201d5a:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201d5e:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201d60:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201d62:	b5e1                	j	ffffffffc0201c2a <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201d64:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201d66:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201d6a:	01174463          	blt	a4,a7,ffffffffc0201d72 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201d6e:	14088163          	beqz	a7,ffffffffc0201eb0 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201d72:	000a3603          	ld	a2,0(s4)
ffffffffc0201d76:	46a1                	li	a3,8
ffffffffc0201d78:	8a2e                	mv	s4,a1
ffffffffc0201d7a:	bf69                	j	ffffffffc0201d14 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201d7c:	03000513          	li	a0,48
ffffffffc0201d80:	85a6                	mv	a1,s1
ffffffffc0201d82:	e03e                	sd	a5,0(sp)
ffffffffc0201d84:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201d86:	85a6                	mv	a1,s1
ffffffffc0201d88:	07800513          	li	a0,120
ffffffffc0201d8c:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201d8e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201d90:	6782                	ld	a5,0(sp)
ffffffffc0201d92:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201d94:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201d98:	bfb5                	j	ffffffffc0201d14 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201d9a:	000a3403          	ld	s0,0(s4)
ffffffffc0201d9e:	008a0713          	addi	a4,s4,8
ffffffffc0201da2:	e03a                	sd	a4,0(sp)
ffffffffc0201da4:	14040263          	beqz	s0,ffffffffc0201ee8 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201da8:	0fb05763          	blez	s11,ffffffffc0201e96 <vprintfmt+0x2d8>
ffffffffc0201dac:	02d00693          	li	a3,45
ffffffffc0201db0:	0cd79163          	bne	a5,a3,ffffffffc0201e72 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201db4:	00044783          	lbu	a5,0(s0)
ffffffffc0201db8:	0007851b          	sext.w	a0,a5
ffffffffc0201dbc:	cf85                	beqz	a5,ffffffffc0201df4 <vprintfmt+0x236>
ffffffffc0201dbe:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201dc2:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201dc6:	000c4563          	bltz	s8,ffffffffc0201dd0 <vprintfmt+0x212>
ffffffffc0201dca:	3c7d                	addiw	s8,s8,-1
ffffffffc0201dcc:	036c0263          	beq	s8,s6,ffffffffc0201df0 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201dd0:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201dd2:	0e0c8e63          	beqz	s9,ffffffffc0201ece <vprintfmt+0x310>
ffffffffc0201dd6:	3781                	addiw	a5,a5,-32
ffffffffc0201dd8:	0ef47b63          	bgeu	s0,a5,ffffffffc0201ece <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201ddc:	03f00513          	li	a0,63
ffffffffc0201de0:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201de2:	000a4783          	lbu	a5,0(s4)
ffffffffc0201de6:	3dfd                	addiw	s11,s11,-1
ffffffffc0201de8:	0a05                	addi	s4,s4,1
ffffffffc0201dea:	0007851b          	sext.w	a0,a5
ffffffffc0201dee:	ffe1                	bnez	a5,ffffffffc0201dc6 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201df0:	01b05963          	blez	s11,ffffffffc0201e02 <vprintfmt+0x244>
ffffffffc0201df4:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201df6:	85a6                	mv	a1,s1
ffffffffc0201df8:	02000513          	li	a0,32
ffffffffc0201dfc:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201dfe:	fe0d9be3          	bnez	s11,ffffffffc0201df4 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201e02:	6a02                	ld	s4,0(sp)
ffffffffc0201e04:	bbd5                	j	ffffffffc0201bf8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201e06:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201e08:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201e0c:	01174463          	blt	a4,a7,ffffffffc0201e14 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201e10:	08088d63          	beqz	a7,ffffffffc0201eaa <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201e14:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201e18:	0a044d63          	bltz	s0,ffffffffc0201ed2 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201e1c:	8622                	mv	a2,s0
ffffffffc0201e1e:	8a66                	mv	s4,s9
ffffffffc0201e20:	46a9                	li	a3,10
ffffffffc0201e22:	bdcd                	j	ffffffffc0201d14 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201e24:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201e28:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201e2a:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201e2c:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201e30:	8fb5                	xor	a5,a5,a3
ffffffffc0201e32:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201e36:	02d74163          	blt	a4,a3,ffffffffc0201e58 <vprintfmt+0x29a>
ffffffffc0201e3a:	00369793          	slli	a5,a3,0x3
ffffffffc0201e3e:	97de                	add	a5,a5,s7
ffffffffc0201e40:	639c                	ld	a5,0(a5)
ffffffffc0201e42:	cb99                	beqz	a5,ffffffffc0201e58 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201e44:	86be                	mv	a3,a5
ffffffffc0201e46:	00001617          	auipc	a2,0x1
ffffffffc0201e4a:	c7260613          	addi	a2,a2,-910 # ffffffffc0202ab8 <small_sizes.1+0x70>
ffffffffc0201e4e:	85a6                	mv	a1,s1
ffffffffc0201e50:	854a                	mv	a0,s2
ffffffffc0201e52:	0ce000ef          	jal	ra,ffffffffc0201f20 <printfmt>
ffffffffc0201e56:	b34d                	j	ffffffffc0201bf8 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201e58:	00001617          	auipc	a2,0x1
ffffffffc0201e5c:	c5060613          	addi	a2,a2,-944 # ffffffffc0202aa8 <small_sizes.1+0x60>
ffffffffc0201e60:	85a6                	mv	a1,s1
ffffffffc0201e62:	854a                	mv	a0,s2
ffffffffc0201e64:	0bc000ef          	jal	ra,ffffffffc0201f20 <printfmt>
ffffffffc0201e68:	bb41                	j	ffffffffc0201bf8 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201e6a:	00001417          	auipc	s0,0x1
ffffffffc0201e6e:	c3640413          	addi	s0,s0,-970 # ffffffffc0202aa0 <small_sizes.1+0x58>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201e72:	85e2                	mv	a1,s8
ffffffffc0201e74:	8522                	mv	a0,s0
ffffffffc0201e76:	e43e                	sd	a5,8(sp)
ffffffffc0201e78:	0fc000ef          	jal	ra,ffffffffc0201f74 <strnlen>
ffffffffc0201e7c:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201e80:	01b05b63          	blez	s11,ffffffffc0201e96 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201e84:	67a2                	ld	a5,8(sp)
ffffffffc0201e86:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201e8a:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201e8c:	85a6                	mv	a1,s1
ffffffffc0201e8e:	8552                	mv	a0,s4
ffffffffc0201e90:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201e92:	fe0d9ce3          	bnez	s11,ffffffffc0201e8a <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201e96:	00044783          	lbu	a5,0(s0)
ffffffffc0201e9a:	00140a13          	addi	s4,s0,1
ffffffffc0201e9e:	0007851b          	sext.w	a0,a5
ffffffffc0201ea2:	d3a5                	beqz	a5,ffffffffc0201e02 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201ea4:	05e00413          	li	s0,94
ffffffffc0201ea8:	bf39                	j	ffffffffc0201dc6 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201eaa:	000a2403          	lw	s0,0(s4)
ffffffffc0201eae:	b7ad                	j	ffffffffc0201e18 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201eb0:	000a6603          	lwu	a2,0(s4)
ffffffffc0201eb4:	46a1                	li	a3,8
ffffffffc0201eb6:	8a2e                	mv	s4,a1
ffffffffc0201eb8:	bdb1                	j	ffffffffc0201d14 <vprintfmt+0x156>
ffffffffc0201eba:	000a6603          	lwu	a2,0(s4)
ffffffffc0201ebe:	46a9                	li	a3,10
ffffffffc0201ec0:	8a2e                	mv	s4,a1
ffffffffc0201ec2:	bd89                	j	ffffffffc0201d14 <vprintfmt+0x156>
ffffffffc0201ec4:	000a6603          	lwu	a2,0(s4)
ffffffffc0201ec8:	46c1                	li	a3,16
ffffffffc0201eca:	8a2e                	mv	s4,a1
ffffffffc0201ecc:	b5a1                	j	ffffffffc0201d14 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201ece:	9902                	jalr	s2
ffffffffc0201ed0:	bf09                	j	ffffffffc0201de2 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201ed2:	85a6                	mv	a1,s1
ffffffffc0201ed4:	02d00513          	li	a0,45
ffffffffc0201ed8:	e03e                	sd	a5,0(sp)
ffffffffc0201eda:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201edc:	6782                	ld	a5,0(sp)
ffffffffc0201ede:	8a66                	mv	s4,s9
ffffffffc0201ee0:	40800633          	neg	a2,s0
ffffffffc0201ee4:	46a9                	li	a3,10
ffffffffc0201ee6:	b53d                	j	ffffffffc0201d14 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201ee8:	03b05163          	blez	s11,ffffffffc0201f0a <vprintfmt+0x34c>
ffffffffc0201eec:	02d00693          	li	a3,45
ffffffffc0201ef0:	f6d79de3          	bne	a5,a3,ffffffffc0201e6a <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201ef4:	00001417          	auipc	s0,0x1
ffffffffc0201ef8:	bac40413          	addi	s0,s0,-1108 # ffffffffc0202aa0 <small_sizes.1+0x58>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201efc:	02800793          	li	a5,40
ffffffffc0201f00:	02800513          	li	a0,40
ffffffffc0201f04:	00140a13          	addi	s4,s0,1
ffffffffc0201f08:	bd6d                	j	ffffffffc0201dc2 <vprintfmt+0x204>
ffffffffc0201f0a:	00001a17          	auipc	s4,0x1
ffffffffc0201f0e:	b97a0a13          	addi	s4,s4,-1129 # ffffffffc0202aa1 <small_sizes.1+0x59>
ffffffffc0201f12:	02800513          	li	a0,40
ffffffffc0201f16:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201f1a:	05e00413          	li	s0,94
ffffffffc0201f1e:	b565                	j	ffffffffc0201dc6 <vprintfmt+0x208>

ffffffffc0201f20 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201f20:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201f22:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201f26:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201f28:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201f2a:	ec06                	sd	ra,24(sp)
ffffffffc0201f2c:	f83a                	sd	a4,48(sp)
ffffffffc0201f2e:	fc3e                	sd	a5,56(sp)
ffffffffc0201f30:	e0c2                	sd	a6,64(sp)
ffffffffc0201f32:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201f34:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201f36:	c89ff0ef          	jal	ra,ffffffffc0201bbe <vprintfmt>
}
ffffffffc0201f3a:	60e2                	ld	ra,24(sp)
ffffffffc0201f3c:	6161                	addi	sp,sp,80
ffffffffc0201f3e:	8082                	ret

ffffffffc0201f40 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201f40:	4781                	li	a5,0
ffffffffc0201f42:	00004717          	auipc	a4,0x4
ffffffffc0201f46:	0ce73703          	ld	a4,206(a4) # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201f4a:	88ba                	mv	a7,a4
ffffffffc0201f4c:	852a                	mv	a0,a0
ffffffffc0201f4e:	85be                	mv	a1,a5
ffffffffc0201f50:	863e                	mv	a2,a5
ffffffffc0201f52:	00000073          	ecall
ffffffffc0201f56:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201f58:	8082                	ret

ffffffffc0201f5a <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201f5a:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201f5e:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201f60:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201f62:	cb81                	beqz	a5,ffffffffc0201f72 <strlen+0x18>
        cnt ++;
ffffffffc0201f64:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201f66:	00a707b3          	add	a5,a4,a0
ffffffffc0201f6a:	0007c783          	lbu	a5,0(a5)
ffffffffc0201f6e:	fbfd                	bnez	a5,ffffffffc0201f64 <strlen+0xa>
ffffffffc0201f70:	8082                	ret
    }
    return cnt;
}
ffffffffc0201f72:	8082                	ret

ffffffffc0201f74 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201f74:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201f76:	e589                	bnez	a1,ffffffffc0201f80 <strnlen+0xc>
ffffffffc0201f78:	a811                	j	ffffffffc0201f8c <strnlen+0x18>
        cnt ++;
ffffffffc0201f7a:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201f7c:	00f58863          	beq	a1,a5,ffffffffc0201f8c <strnlen+0x18>
ffffffffc0201f80:	00f50733          	add	a4,a0,a5
ffffffffc0201f84:	00074703          	lbu	a4,0(a4)
ffffffffc0201f88:	fb6d                	bnez	a4,ffffffffc0201f7a <strnlen+0x6>
ffffffffc0201f8a:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201f8c:	852e                	mv	a0,a1
ffffffffc0201f8e:	8082                	ret

ffffffffc0201f90 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f90:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f94:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f98:	cb89                	beqz	a5,ffffffffc0201faa <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201f9a:	0505                	addi	a0,a0,1
ffffffffc0201f9c:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f9e:	fee789e3          	beq	a5,a4,ffffffffc0201f90 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201fa2:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201fa6:	9d19                	subw	a0,a0,a4
ffffffffc0201fa8:	8082                	ret
ffffffffc0201faa:	4501                	li	a0,0
ffffffffc0201fac:	bfed                	j	ffffffffc0201fa6 <strcmp+0x16>

ffffffffc0201fae <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201fae:	c20d                	beqz	a2,ffffffffc0201fd0 <strncmp+0x22>
ffffffffc0201fb0:	962e                	add	a2,a2,a1
ffffffffc0201fb2:	a031                	j	ffffffffc0201fbe <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201fb4:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201fb6:	00e79a63          	bne	a5,a4,ffffffffc0201fca <strncmp+0x1c>
ffffffffc0201fba:	00b60b63          	beq	a2,a1,ffffffffc0201fd0 <strncmp+0x22>
ffffffffc0201fbe:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201fc2:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201fc4:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201fc8:	f7f5                	bnez	a5,ffffffffc0201fb4 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201fca:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201fce:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201fd0:	4501                	li	a0,0
ffffffffc0201fd2:	8082                	ret

ffffffffc0201fd4 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201fd4:	ca01                	beqz	a2,ffffffffc0201fe4 <memset+0x10>
ffffffffc0201fd6:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201fd8:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201fda:	0785                	addi	a5,a5,1
ffffffffc0201fdc:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201fe0:	fec79de3          	bne	a5,a2,ffffffffc0201fda <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201fe4:	8082                	ret
