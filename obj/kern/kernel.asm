
obj/kern/kernel：     文件格式 elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 a0 11 00       	mov    $0x11a000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 a0 11 f0       	mov    $0xf011a000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 90 f1 17 f0       	mov    $0xf017f190,%eax
f010004b:	2d 0c e2 17 f0       	sub    $0xf017e20c,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 0c e2 17 f0       	push   $0xf017e20c
f0100058:	e8 a6 46 00 00       	call   f0104703 <memset>
//	int x = 1, y = 3, z = 4;
//	cprintf("x %d, y %x, z %d\n", x, y, z);
	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 99 04 00 00       	call   f01004fb <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 c0 4b 10 f0       	push   $0xf0104bc0
f010006f:	e8 89 31 00 00       	call   f01031fd <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 d0 11 00 00       	call   f0101249 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 a1 2b 00 00       	call   f0102c1f <env_init>
	//cprintf("for debug 1: reach here ! Hi, mingming! Jiayou Jiayou!");
	trap_init();
f010007e:	e8 eb 31 00 00       	call   f010326e <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 1c c4 11 f0       	push   $0xf011c41c
f010008d:	e8 34 2d 00 00       	call   f0102dc6 <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 ac e4 17 f0    	pushl  0xf017e4ac
f010009b:	e8 86 30 00 00       	call   f0103126 <env_run>

f01000a0 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000a0:	55                   	push   %ebp
f01000a1:	89 e5                	mov    %esp,%ebp
f01000a3:	56                   	push   %esi
f01000a4:	53                   	push   %ebx
f01000a5:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000a8:	83 3d 80 f1 17 f0 00 	cmpl   $0x0,0xf017f180
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 80 f1 17 f0    	mov    %esi,0xf017f180

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000b7:	fa                   	cli    
f01000b8:	fc                   	cld    

	va_start(ap, fmt);
f01000b9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000bc:	83 ec 04             	sub    $0x4,%esp
f01000bf:	ff 75 0c             	pushl  0xc(%ebp)
f01000c2:	ff 75 08             	pushl  0x8(%ebp)
f01000c5:	68 db 4b 10 f0       	push   $0xf0104bdb
f01000ca:	e8 2e 31 00 00       	call   f01031fd <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 fe 30 00 00       	call   f01031d7 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 3a 5f 10 f0 	movl   $0xf0105f3a,(%esp)
f01000e0:	e8 18 31 00 00       	call   f01031fd <cprintf>
	va_end(ap);
f01000e5:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e8:	83 ec 0c             	sub    $0xc,%esp
f01000eb:	6a 00                	push   $0x0
f01000ed:	e8 9e 08 00 00       	call   f0100990 <monitor>
f01000f2:	83 c4 10             	add    $0x10,%esp
f01000f5:	eb f1                	jmp    f01000e8 <_panic+0x48>

f01000f7 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f7:	55                   	push   %ebp
f01000f8:	89 e5                	mov    %esp,%ebp
f01000fa:	53                   	push   %ebx
f01000fb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fe:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100101:	ff 75 0c             	pushl  0xc(%ebp)
f0100104:	ff 75 08             	pushl  0x8(%ebp)
f0100107:	68 f3 4b 10 f0       	push   $0xf0104bf3
f010010c:	e8 ec 30 00 00       	call   f01031fd <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 ba 30 00 00       	call   f01031d7 <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 3a 5f 10 f0 	movl   $0xf0105f3a,(%esp)
f0100124:	e8 d4 30 00 00       	call   f01031fd <cprintf>
	va_end(ap);
f0100129:	83 c4 10             	add    $0x10,%esp
}
f010012c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010012f:	c9                   	leave  
f0100130:	c3                   	ret    

f0100131 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100131:	55                   	push   %ebp
f0100132:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100134:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100139:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010013a:	a8 01                	test   $0x1,%al
f010013c:	74 08                	je     f0100146 <serial_proc_data+0x15>
f010013e:	b2 f8                	mov    $0xf8,%dl
f0100140:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100141:	0f b6 c0             	movzbl %al,%eax
f0100144:	eb 05                	jmp    f010014b <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100146:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010014b:	5d                   	pop    %ebp
f010014c:	c3                   	ret    

f010014d <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010014d:	55                   	push   %ebp
f010014e:	89 e5                	mov    %esp,%ebp
f0100150:	53                   	push   %ebx
f0100151:	83 ec 04             	sub    $0x4,%esp
f0100154:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100156:	eb 2a                	jmp    f0100182 <cons_intr+0x35>
		if (c == 0)
f0100158:	85 d2                	test   %edx,%edx
f010015a:	74 26                	je     f0100182 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010015c:	a1 84 e4 17 f0       	mov    0xf017e484,%eax
f0100161:	8d 48 01             	lea    0x1(%eax),%ecx
f0100164:	89 0d 84 e4 17 f0    	mov    %ecx,0xf017e484
f010016a:	88 90 80 e2 17 f0    	mov    %dl,-0xfe81d80(%eax)
		if (cons.wpos == CONSBUFSIZE)
f0100170:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100176:	75 0a                	jne    f0100182 <cons_intr+0x35>
			cons.wpos = 0;
f0100178:	c7 05 84 e4 17 f0 00 	movl   $0x0,0xf017e484
f010017f:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100182:	ff d3                	call   *%ebx
f0100184:	89 c2                	mov    %eax,%edx
f0100186:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100189:	75 cd                	jne    f0100158 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010018b:	83 c4 04             	add    $0x4,%esp
f010018e:	5b                   	pop    %ebx
f010018f:	5d                   	pop    %ebp
f0100190:	c3                   	ret    

f0100191 <kbd_proc_data>:
f0100191:	ba 64 00 00 00       	mov    $0x64,%edx
f0100196:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100197:	a8 01                	test   $0x1,%al
f0100199:	0f 84 f0 00 00 00    	je     f010028f <kbd_proc_data+0xfe>
f010019f:	b2 60                	mov    $0x60,%dl
f01001a1:	ec                   	in     (%dx),%al
f01001a2:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001a4:	3c e0                	cmp    $0xe0,%al
f01001a6:	75 0d                	jne    f01001b5 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f01001a8:	83 0d 40 e2 17 f0 40 	orl    $0x40,0xf017e240
		return 0;
f01001af:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001b4:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001b5:	55                   	push   %ebp
f01001b6:	89 e5                	mov    %esp,%ebp
f01001b8:	53                   	push   %ebx
f01001b9:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001bc:	84 c0                	test   %al,%al
f01001be:	79 36                	jns    f01001f6 <kbd_proc_data+0x65>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001c0:	8b 0d 40 e2 17 f0    	mov    0xf017e240,%ecx
f01001c6:	89 cb                	mov    %ecx,%ebx
f01001c8:	83 e3 40             	and    $0x40,%ebx
f01001cb:	83 e0 7f             	and    $0x7f,%eax
f01001ce:	85 db                	test   %ebx,%ebx
f01001d0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001d3:	0f b6 d2             	movzbl %dl,%edx
f01001d6:	0f b6 82 80 4d 10 f0 	movzbl -0xfefb280(%edx),%eax
f01001dd:	83 c8 40             	or     $0x40,%eax
f01001e0:	0f b6 c0             	movzbl %al,%eax
f01001e3:	f7 d0                	not    %eax
f01001e5:	21 c8                	and    %ecx,%eax
f01001e7:	a3 40 e2 17 f0       	mov    %eax,0xf017e240
		return 0;
f01001ec:	b8 00 00 00 00       	mov    $0x0,%eax
f01001f1:	e9 a1 00 00 00       	jmp    f0100297 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001f6:	8b 0d 40 e2 17 f0    	mov    0xf017e240,%ecx
f01001fc:	f6 c1 40             	test   $0x40,%cl
f01001ff:	74 0e                	je     f010020f <kbd_proc_data+0x7e>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100201:	83 c8 80             	or     $0xffffff80,%eax
f0100204:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100206:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100209:	89 0d 40 e2 17 f0    	mov    %ecx,0xf017e240
	}

	shift |= shiftcode[data];
f010020f:	0f b6 c2             	movzbl %dl,%eax
f0100212:	0f b6 90 80 4d 10 f0 	movzbl -0xfefb280(%eax),%edx
f0100219:	0b 15 40 e2 17 f0    	or     0xf017e240,%edx
	shift ^= togglecode[data];
f010021f:	0f b6 88 80 4c 10 f0 	movzbl -0xfefb380(%eax),%ecx
f0100226:	31 ca                	xor    %ecx,%edx
f0100228:	89 15 40 e2 17 f0    	mov    %edx,0xf017e240

	c = charcode[shift & (CTL | SHIFT)][data];
f010022e:	89 d1                	mov    %edx,%ecx
f0100230:	83 e1 03             	and    $0x3,%ecx
f0100233:	8b 0c 8d 40 4c 10 f0 	mov    -0xfefb3c0(,%ecx,4),%ecx
f010023a:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f010023e:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f0100241:	f6 c2 08             	test   $0x8,%dl
f0100244:	74 1b                	je     f0100261 <kbd_proc_data+0xd0>
		if ('a' <= c && c <= 'z')
f0100246:	89 d8                	mov    %ebx,%eax
f0100248:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010024b:	83 f9 19             	cmp    $0x19,%ecx
f010024e:	77 05                	ja     f0100255 <kbd_proc_data+0xc4>
			c += 'A' - 'a';
f0100250:	83 eb 20             	sub    $0x20,%ebx
f0100253:	eb 0c                	jmp    f0100261 <kbd_proc_data+0xd0>
		else if ('A' <= c && c <= 'Z')
f0100255:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f0100258:	8d 4b 20             	lea    0x20(%ebx),%ecx
f010025b:	83 f8 19             	cmp    $0x19,%eax
f010025e:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100261:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100267:	75 2c                	jne    f0100295 <kbd_proc_data+0x104>
f0100269:	f7 d2                	not    %edx
f010026b:	f6 c2 06             	test   $0x6,%dl
f010026e:	75 25                	jne    f0100295 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f0100270:	83 ec 0c             	sub    $0xc,%esp
f0100273:	68 0d 4c 10 f0       	push   $0xf0104c0d
f0100278:	e8 80 2f 00 00       	call   f01031fd <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010027d:	ba 92 00 00 00       	mov    $0x92,%edx
f0100282:	b8 03 00 00 00       	mov    $0x3,%eax
f0100287:	ee                   	out    %al,(%dx)
f0100288:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f010028b:	89 d8                	mov    %ebx,%eax
f010028d:	eb 08                	jmp    f0100297 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010028f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100294:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100295:	89 d8                	mov    %ebx,%eax
}
f0100297:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010029a:	c9                   	leave  
f010029b:	c3                   	ret    

f010029c <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010029c:	55                   	push   %ebp
f010029d:	89 e5                	mov    %esp,%ebp
f010029f:	57                   	push   %edi
f01002a0:	56                   	push   %esi
f01002a1:	53                   	push   %ebx
f01002a2:	83 ec 0c             	sub    $0xc,%esp
f01002a5:	89 c6                	mov    %eax,%esi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a7:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002ac:	bf fd 03 00 00       	mov    $0x3fd,%edi
f01002b1:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b6:	eb 09                	jmp    f01002c1 <cons_putc+0x25>
f01002b8:	89 ca                	mov    %ecx,%edx
f01002ba:	ec                   	in     (%dx),%al
f01002bb:	ec                   	in     (%dx),%al
f01002bc:	ec                   	in     (%dx),%al
f01002bd:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002be:	83 c3 01             	add    $0x1,%ebx
f01002c1:	89 fa                	mov    %edi,%edx
f01002c3:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002c4:	a8 20                	test   $0x20,%al
f01002c6:	75 08                	jne    f01002d0 <cons_putc+0x34>
f01002c8:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002ce:	7e e8                	jle    f01002b8 <cons_putc+0x1c>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002d5:	89 f0                	mov    %esi,%eax
f01002d7:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002d8:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002dd:	bf 79 03 00 00       	mov    $0x379,%edi
f01002e2:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002e7:	eb 09                	jmp    f01002f2 <cons_putc+0x56>
f01002e9:	89 ca                	mov    %ecx,%edx
f01002eb:	ec                   	in     (%dx),%al
f01002ec:	ec                   	in     (%dx),%al
f01002ed:	ec                   	in     (%dx),%al
f01002ee:	ec                   	in     (%dx),%al
f01002ef:	83 c3 01             	add    $0x1,%ebx
f01002f2:	89 fa                	mov    %edi,%edx
f01002f4:	ec                   	in     (%dx),%al
f01002f5:	84 c0                	test   %al,%al
f01002f7:	78 08                	js     f0100301 <cons_putc+0x65>
f01002f9:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002ff:	7e e8                	jle    f01002e9 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100301:	ba 78 03 00 00       	mov    $0x378,%edx
f0100306:	89 f0                	mov    %esi,%eax
f0100308:	ee                   	out    %al,(%dx)
f0100309:	b2 7a                	mov    $0x7a,%dl
f010030b:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100310:	ee                   	out    %al,(%dx)
f0100311:	b8 08 00 00 00       	mov    $0x8,%eax
f0100316:	ee                   	out    %al,(%dx)


static void
cga_putc(int c)
{
	c = c + (colr << 8);
f0100317:	a1 6c ed 17 f0       	mov    0xf017ed6c,%eax
f010031c:	c1 e0 08             	shl    $0x8,%eax
f010031f:	01 f0                	add    %esi,%eax
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100321:	89 c1                	mov    %eax,%ecx
f0100323:	81 e1 00 ff ff ff    	and    $0xffffff00,%ecx
		c |= 0x0700;
f0100329:	89 c2                	mov    %eax,%edx
f010032b:	80 ce 07             	or     $0x7,%dh
f010032e:	85 c9                	test   %ecx,%ecx
f0100330:	0f 44 c2             	cmove  %edx,%eax

	switch (c & 0xff) {
f0100333:	0f b6 d0             	movzbl %al,%edx
f0100336:	83 fa 09             	cmp    $0x9,%edx
f0100339:	74 72                	je     f01003ad <cons_putc+0x111>
f010033b:	83 fa 09             	cmp    $0x9,%edx
f010033e:	7f 0a                	jg     f010034a <cons_putc+0xae>
f0100340:	83 fa 08             	cmp    $0x8,%edx
f0100343:	74 14                	je     f0100359 <cons_putc+0xbd>
f0100345:	e9 97 00 00 00       	jmp    f01003e1 <cons_putc+0x145>
f010034a:	83 fa 0a             	cmp    $0xa,%edx
f010034d:	74 38                	je     f0100387 <cons_putc+0xeb>
f010034f:	83 fa 0d             	cmp    $0xd,%edx
f0100352:	74 3b                	je     f010038f <cons_putc+0xf3>
f0100354:	e9 88 00 00 00       	jmp    f01003e1 <cons_putc+0x145>
	case '\b':
		if (crt_pos > 0) {
f0100359:	0f b7 15 88 e4 17 f0 	movzwl 0xf017e488,%edx
f0100360:	66 85 d2             	test   %dx,%dx
f0100363:	0f 84 e4 00 00 00    	je     f010044d <cons_putc+0x1b1>
			crt_pos--;
f0100369:	83 ea 01             	sub    $0x1,%edx
f010036c:	66 89 15 88 e4 17 f0 	mov    %dx,0xf017e488
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100373:	0f b7 d2             	movzwl %dx,%edx
f0100376:	b0 00                	mov    $0x0,%al
f0100378:	83 c8 20             	or     $0x20,%eax
f010037b:	8b 0d 8c e4 17 f0    	mov    0xf017e48c,%ecx
f0100381:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f0100385:	eb 78                	jmp    f01003ff <cons_putc+0x163>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100387:	66 83 05 88 e4 17 f0 	addw   $0x50,0xf017e488
f010038e:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038f:	0f b7 05 88 e4 17 f0 	movzwl 0xf017e488,%eax
f0100396:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010039c:	c1 e8 16             	shr    $0x16,%eax
f010039f:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003a2:	c1 e0 04             	shl    $0x4,%eax
f01003a5:	66 a3 88 e4 17 f0    	mov    %ax,0xf017e488
f01003ab:	eb 52                	jmp    f01003ff <cons_putc+0x163>
		break;
	case '\t':
		cons_putc(' ');
f01003ad:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b2:	e8 e5 fe ff ff       	call   f010029c <cons_putc>
		cons_putc(' ');
f01003b7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003bc:	e8 db fe ff ff       	call   f010029c <cons_putc>
		cons_putc(' ');
f01003c1:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c6:	e8 d1 fe ff ff       	call   f010029c <cons_putc>
		cons_putc(' ');
f01003cb:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d0:	e8 c7 fe ff ff       	call   f010029c <cons_putc>
		cons_putc(' ');
f01003d5:	b8 20 00 00 00       	mov    $0x20,%eax
f01003da:	e8 bd fe ff ff       	call   f010029c <cons_putc>
f01003df:	eb 1e                	jmp    f01003ff <cons_putc+0x163>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003e1:	0f b7 15 88 e4 17 f0 	movzwl 0xf017e488,%edx
f01003e8:	8d 4a 01             	lea    0x1(%edx),%ecx
f01003eb:	66 89 0d 88 e4 17 f0 	mov    %cx,0xf017e488
f01003f2:	0f b7 d2             	movzwl %dx,%edx
f01003f5:	8b 0d 8c e4 17 f0    	mov    0xf017e48c,%ecx
f01003fb:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003ff:	66 81 3d 88 e4 17 f0 	cmpw   $0x7cf,0xf017e488
f0100406:	cf 07 
f0100408:	76 43                	jbe    f010044d <cons_putc+0x1b1>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010040a:	a1 8c e4 17 f0       	mov    0xf017e48c,%eax
f010040f:	83 ec 04             	sub    $0x4,%esp
f0100412:	68 00 0f 00 00       	push   $0xf00
f0100417:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041d:	52                   	push   %edx
f010041e:	50                   	push   %eax
f010041f:	e8 2c 43 00 00       	call   f0104750 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100424:	8b 15 8c e4 17 f0    	mov    0xf017e48c,%edx
f010042a:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100430:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100436:	83 c4 10             	add    $0x10,%esp
f0100439:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010043e:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100441:	39 d0                	cmp    %edx,%eax
f0100443:	75 f4                	jne    f0100439 <cons_putc+0x19d>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100445:	66 83 2d 88 e4 17 f0 	subw   $0x50,0xf017e488
f010044c:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044d:	8b 0d 90 e4 17 f0    	mov    0xf017e490,%ecx
f0100453:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100458:	89 ca                	mov    %ecx,%edx
f010045a:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010045b:	0f b7 1d 88 e4 17 f0 	movzwl 0xf017e488,%ebx
f0100462:	8d 71 01             	lea    0x1(%ecx),%esi
f0100465:	89 d8                	mov    %ebx,%eax
f0100467:	66 c1 e8 08          	shr    $0x8,%ax
f010046b:	89 f2                	mov    %esi,%edx
f010046d:	ee                   	out    %al,(%dx)
f010046e:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100473:	89 ca                	mov    %ecx,%edx
f0100475:	ee                   	out    %al,(%dx)
f0100476:	89 d8                	mov    %ebx,%eax
f0100478:	89 f2                	mov    %esi,%edx
f010047a:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010047b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010047e:	5b                   	pop    %ebx
f010047f:	5e                   	pop    %esi
f0100480:	5f                   	pop    %edi
f0100481:	5d                   	pop    %ebp
f0100482:	c3                   	ret    

f0100483 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100483:	80 3d 94 e4 17 f0 00 	cmpb   $0x0,0xf017e494
f010048a:	74 11                	je     f010049d <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010048c:	55                   	push   %ebp
f010048d:	89 e5                	mov    %esp,%ebp
f010048f:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100492:	b8 31 01 10 f0       	mov    $0xf0100131,%eax
f0100497:	e8 b1 fc ff ff       	call   f010014d <cons_intr>
}
f010049c:	c9                   	leave  
f010049d:	f3 c3                	repz ret 

f010049f <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010049f:	55                   	push   %ebp
f01004a0:	89 e5                	mov    %esp,%ebp
f01004a2:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a5:	b8 91 01 10 f0       	mov    $0xf0100191,%eax
f01004aa:	e8 9e fc ff ff       	call   f010014d <cons_intr>
}
f01004af:	c9                   	leave  
f01004b0:	c3                   	ret    

f01004b1 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004b1:	55                   	push   %ebp
f01004b2:	89 e5                	mov    %esp,%ebp
f01004b4:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004b7:	e8 c7 ff ff ff       	call   f0100483 <serial_intr>
	kbd_intr();
f01004bc:	e8 de ff ff ff       	call   f010049f <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004c1:	a1 80 e4 17 f0       	mov    0xf017e480,%eax
f01004c6:	3b 05 84 e4 17 f0    	cmp    0xf017e484,%eax
f01004cc:	74 26                	je     f01004f4 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004ce:	8d 50 01             	lea    0x1(%eax),%edx
f01004d1:	89 15 80 e4 17 f0    	mov    %edx,0xf017e480
f01004d7:	0f b6 88 80 e2 17 f0 	movzbl -0xfe81d80(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004de:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004e0:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004e6:	75 11                	jne    f01004f9 <cons_getc+0x48>
			cons.rpos = 0;
f01004e8:	c7 05 80 e4 17 f0 00 	movl   $0x0,0xf017e480
f01004ef:	00 00 00 
f01004f2:	eb 05                	jmp    f01004f9 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004f9:	c9                   	leave  
f01004fa:	c3                   	ret    

f01004fb <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004fb:	55                   	push   %ebp
f01004fc:	89 e5                	mov    %esp,%ebp
f01004fe:	57                   	push   %edi
f01004ff:	56                   	push   %esi
f0100500:	53                   	push   %ebx
f0100501:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100504:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010050b:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100512:	5a a5 
	if (*cp != 0xA55A) {
f0100514:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010051b:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010051f:	74 11                	je     f0100532 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100521:	c7 05 90 e4 17 f0 b4 	movl   $0x3b4,0xf017e490
f0100528:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010052b:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100530:	eb 16                	jmp    f0100548 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100532:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100539:	c7 05 90 e4 17 f0 d4 	movl   $0x3d4,0xf017e490
f0100540:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100543:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100548:	8b 3d 90 e4 17 f0    	mov    0xf017e490,%edi
f010054e:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100553:	89 fa                	mov    %edi,%edx
f0100555:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100556:	8d 4f 01             	lea    0x1(%edi),%ecx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100559:	89 ca                	mov    %ecx,%edx
f010055b:	ec                   	in     (%dx),%al
f010055c:	0f b6 c0             	movzbl %al,%eax
f010055f:	c1 e0 08             	shl    $0x8,%eax
f0100562:	89 c3                	mov    %eax,%ebx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100564:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100569:	89 fa                	mov    %edi,%edx
f010056b:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056c:	89 ca                	mov    %ecx,%edx
f010056e:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010056f:	89 35 8c e4 17 f0    	mov    %esi,0xf017e48c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100575:	0f b6 c8             	movzbl %al,%ecx
f0100578:	89 d8                	mov    %ebx,%eax
f010057a:	09 c8                	or     %ecx,%eax

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f010057c:	66 a3 88 e4 17 f0    	mov    %ax,0xf017e488
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100582:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f0100587:	b8 00 00 00 00       	mov    $0x0,%eax
f010058c:	89 da                	mov    %ebx,%edx
f010058e:	ee                   	out    %al,(%dx)
f010058f:	b2 fb                	mov    $0xfb,%dl
f0100591:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100596:	ee                   	out    %al,(%dx)
f0100597:	be f8 03 00 00       	mov    $0x3f8,%esi
f010059c:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005a1:	89 f2                	mov    %esi,%edx
f01005a3:	ee                   	out    %al,(%dx)
f01005a4:	b2 f9                	mov    $0xf9,%dl
f01005a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ab:	ee                   	out    %al,(%dx)
f01005ac:	b2 fb                	mov    $0xfb,%dl
f01005ae:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b3:	ee                   	out    %al,(%dx)
f01005b4:	b2 fc                	mov    $0xfc,%dl
f01005b6:	b8 00 00 00 00       	mov    $0x0,%eax
f01005bb:	ee                   	out    %al,(%dx)
f01005bc:	b2 f9                	mov    $0xf9,%dl
f01005be:	b8 01 00 00 00       	mov    $0x1,%eax
f01005c3:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c4:	b2 fd                	mov    $0xfd,%dl
f01005c6:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005c7:	3c ff                	cmp    $0xff,%al
f01005c9:	0f 95 c1             	setne  %cl
f01005cc:	88 0d 94 e4 17 f0    	mov    %cl,0xf017e494
f01005d2:	89 da                	mov    %ebx,%edx
f01005d4:	ec                   	in     (%dx),%al
f01005d5:	89 f2                	mov    %esi,%edx
f01005d7:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005d8:	84 c9                	test   %cl,%cl
f01005da:	75 10                	jne    f01005ec <cons_init+0xf1>
		cprintf("Serial port does not exist!\n");
f01005dc:	83 ec 0c             	sub    $0xc,%esp
f01005df:	68 19 4c 10 f0       	push   $0xf0104c19
f01005e4:	e8 14 2c 00 00       	call   f01031fd <cprintf>
f01005e9:	83 c4 10             	add    $0x10,%esp
}
f01005ec:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005ef:	5b                   	pop    %ebx
f01005f0:	5e                   	pop    %esi
f01005f1:	5f                   	pop    %edi
f01005f2:	5d                   	pop    %ebp
f01005f3:	c3                   	ret    

f01005f4 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005f4:	55                   	push   %ebp
f01005f5:	89 e5                	mov    %esp,%ebp
f01005f7:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005fa:	8b 45 08             	mov    0x8(%ebp),%eax
f01005fd:	e8 9a fc ff ff       	call   f010029c <cons_putc>
}
f0100602:	c9                   	leave  
f0100603:	c3                   	ret    

f0100604 <getchar>:

int
getchar(void)
{
f0100604:	55                   	push   %ebp
f0100605:	89 e5                	mov    %esp,%ebp
f0100607:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010060a:	e8 a2 fe ff ff       	call   f01004b1 <cons_getc>
f010060f:	85 c0                	test   %eax,%eax
f0100611:	74 f7                	je     f010060a <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100613:	c9                   	leave  
f0100614:	c3                   	ret    

f0100615 <iscons>:

int
iscons(int fdnum)
{
f0100615:	55                   	push   %ebp
f0100616:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100618:	b8 01 00 00 00       	mov    $0x1,%eax
f010061d:	5d                   	pop    %ebp
f010061e:	c3                   	ret    

f010061f <xtoi>:
	const char *name;
	const char *desc;
	// return -1 to force monitor to exit
	int (*func)(int argc, char** argv, struct Trapframe* tf);
};
static uint32_t xtoi(char*buf){
f010061f:	55                   	push   %ebp
f0100620:	89 e5                	mov    %esp,%ebp
	uint32_t res = 0;
	buf += 2;
f0100622:	8d 50 02             	lea    0x2(%eax),%edx
	const char *desc;
	// return -1 to force monitor to exit
	int (*func)(int argc, char** argv, struct Trapframe* tf);
};
static uint32_t xtoi(char*buf){
	uint32_t res = 0;
f0100625:	b8 00 00 00 00       	mov    $0x0,%eax
	buf += 2;
	while(*buf){
f010062a:	eb 17                	jmp    f0100643 <xtoi+0x24>
		if(*buf >= 'a') *buf = *buf - 'a' + '0' + 10;
f010062c:	80 f9 60             	cmp    $0x60,%cl
f010062f:	7e 05                	jle    f0100636 <xtoi+0x17>
f0100631:	83 e9 27             	sub    $0x27,%ecx
f0100634:	88 0a                	mov    %cl,(%edx)
		res = res * 16 + *buf - '0';
f0100636:	c1 e0 04             	shl    $0x4,%eax
f0100639:	0f be 0a             	movsbl (%edx),%ecx
f010063c:	8d 44 08 d0          	lea    -0x30(%eax,%ecx,1),%eax
		++buf;
f0100640:	83 c2 01             	add    $0x1,%edx
	int (*func)(int argc, char** argv, struct Trapframe* tf);
};
static uint32_t xtoi(char*buf){
	uint32_t res = 0;
	buf += 2;
	while(*buf){
f0100643:	0f b6 0a             	movzbl (%edx),%ecx
f0100646:	84 c9                	test   %cl,%cl
f0100648:	75 e2                	jne    f010062c <xtoi+0xd>
		if(*buf >= 'a') *buf = *buf - 'a' + '0' + 10;
		res = res * 16 + *buf - '0';
		++buf;
	}
	return res;
}
f010064a:	5d                   	pop    %ebp
f010064b:	c3                   	ret    

f010064c <showvm>:
	else
		*pte = *pte | perm;
	return 0;
};

int showvm(int argc, char**argv, struct Trapframe*ft){
f010064c:	55                   	push   %ebp
f010064d:	89 e5                	mov    %esp,%ebp
f010064f:	57                   	push   %edi
f0100650:	56                   	push   %esi
f0100651:	53                   	push   %ebx
f0100652:	83 ec 0c             	sub    $0xc,%esp
f0100655:	8b 75 0c             	mov    0xc(%ebp),%esi
	if(argc == 1){
f0100658:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
f010065c:	75 12                	jne    f0100670 <showvm+0x24>
		cprintf("Usage: showvm 0xaddr 0x\n");
f010065e:	83 ec 0c             	sub    $0xc,%esp
f0100661:	68 80 4e 10 f0       	push   $0xf0104e80
f0100666:	e8 92 2b 00 00       	call   f01031fd <cprintf>
		return 0;
f010066b:	83 c4 10             	add    $0x10,%esp
f010066e:	eb 38                	jmp    f01006a8 <showvm+0x5c>
	}
	void**addr = (void**)xtoi(argv[1]);
f0100670:	8b 46 04             	mov    0x4(%esi),%eax
f0100673:	e8 a7 ff ff ff       	call   f010061f <xtoi>
f0100678:	89 c3                	mov    %eax,%ebx
	uint32_t n = xtoi(argv[2]);
f010067a:	8b 46 08             	mov    0x8(%esi),%eax
f010067d:	e8 9d ff ff ff       	call   f010061f <xtoi>
f0100682:	89 c6                	mov    %eax,%esi
	int i;
	for(i = 0; i < n; ++i){
f0100684:	bf 00 00 00 00       	mov    $0x0,%edi
f0100689:	eb 19                	jmp    f01006a4 <showvm+0x58>
		cprintf("VM at %x is %x\n", addr+i,addr[i]);
f010068b:	83 ec 04             	sub    $0x4,%esp
f010068e:	ff 33                	pushl  (%ebx)
f0100690:	53                   	push   %ebx
f0100691:	68 99 4e 10 f0       	push   $0xf0104e99
f0100696:	e8 62 2b 00 00       	call   f01031fd <cprintf>
		return 0;
	}
	void**addr = (void**)xtoi(argv[1]);
	uint32_t n = xtoi(argv[2]);
	int i;
	for(i = 0; i < n; ++i){
f010069b:	83 c7 01             	add    $0x1,%edi
f010069e:	83 c3 04             	add    $0x4,%ebx
f01006a1:	83 c4 10             	add    $0x10,%esp
f01006a4:	39 f7                	cmp    %esi,%edi
f01006a6:	75 e3                	jne    f010068b <showvm+0x3f>
		cprintf("VM at %x is %x\n", addr+i,addr[i]);
	}
	return 0;
}
f01006a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ad:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01006b0:	5b                   	pop    %ebx
f01006b1:	5e                   	pop    %esi
f01006b2:	5f                   	pop    %edi
f01006b3:	5d                   	pop    %ebp
f01006b4:	c3                   	ret    

f01006b5 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006b5:	55                   	push   %ebp
f01006b6:	89 e5                	mov    %esp,%ebp
f01006b8:	56                   	push   %esi
f01006b9:	53                   	push   %ebx
f01006ba:	bb 44 53 10 f0       	mov    $0xf0105344,%ebx
f01006bf:	be 8c 53 10 f0       	mov    $0xf010538c,%esi
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006c4:	83 ec 04             	sub    $0x4,%esp
f01006c7:	ff 33                	pushl  (%ebx)
f01006c9:	ff 73 fc             	pushl  -0x4(%ebx)
f01006cc:	68 a9 4e 10 f0       	push   $0xf0104ea9
f01006d1:	e8 27 2b 00 00       	call   f01031fd <cprintf>
f01006d6:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f01006d9:	83 c4 10             	add    $0x10,%esp
f01006dc:	39 f3                	cmp    %esi,%ebx
f01006de:	75 e4                	jne    f01006c4 <mon_help+0xf>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f01006e0:	b8 00 00 00 00       	mov    $0x0,%eax
f01006e5:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01006e8:	5b                   	pop    %ebx
f01006e9:	5e                   	pop    %esi
f01006ea:	5d                   	pop    %ebp
f01006eb:	c3                   	ret    

f01006ec <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006ec:	55                   	push   %ebp
f01006ed:	89 e5                	mov    %esp,%ebp
f01006ef:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006f2:	68 b2 4e 10 f0       	push   $0xf0104eb2
f01006f7:	e8 01 2b 00 00       	call   f01031fd <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006fc:	83 c4 08             	add    $0x8,%esp
f01006ff:	68 0c 00 10 00       	push   $0x10000c
f0100704:	68 08 50 10 f0       	push   $0xf0105008
f0100709:	e8 ef 2a 00 00       	call   f01031fd <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010070e:	83 c4 0c             	add    $0xc,%esp
f0100711:	68 0c 00 10 00       	push   $0x10000c
f0100716:	68 0c 00 10 f0       	push   $0xf010000c
f010071b:	68 30 50 10 f0       	push   $0xf0105030
f0100720:	e8 d8 2a 00 00       	call   f01031fd <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100725:	83 c4 0c             	add    $0xc,%esp
f0100728:	68 b5 4b 10 00       	push   $0x104bb5
f010072d:	68 b5 4b 10 f0       	push   $0xf0104bb5
f0100732:	68 54 50 10 f0       	push   $0xf0105054
f0100737:	e8 c1 2a 00 00       	call   f01031fd <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010073c:	83 c4 0c             	add    $0xc,%esp
f010073f:	68 0c e2 17 00       	push   $0x17e20c
f0100744:	68 0c e2 17 f0       	push   $0xf017e20c
f0100749:	68 78 50 10 f0       	push   $0xf0105078
f010074e:	e8 aa 2a 00 00       	call   f01031fd <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100753:	83 c4 0c             	add    $0xc,%esp
f0100756:	68 90 f1 17 00       	push   $0x17f190
f010075b:	68 90 f1 17 f0       	push   $0xf017f190
f0100760:	68 9c 50 10 f0       	push   $0xf010509c
f0100765:	e8 93 2a 00 00       	call   f01031fd <cprintf>
f010076a:	b8 8f f5 17 f0       	mov    $0xf017f58f,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010076f:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100774:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100777:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010077c:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100782:	85 c0                	test   %eax,%eax
f0100784:	0f 48 c2             	cmovs  %edx,%eax
f0100787:	c1 f8 0a             	sar    $0xa,%eax
f010078a:	50                   	push   %eax
f010078b:	68 c0 50 10 f0       	push   $0xf01050c0
f0100790:	e8 68 2a 00 00       	call   f01031fd <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100795:	b8 00 00 00 00       	mov    $0x0,%eax
f010079a:	c9                   	leave  
f010079b:	c3                   	ret    

f010079c <setpte>:
			cprintf("page not exist: %x\n",begin);
		}
	}
	return 0;
}
int setpte(int argc, char**argv, struct Trapframe*tf){
f010079c:	55                   	push   %ebp
f010079d:	89 e5                	mov    %esp,%ebp
f010079f:	56                   	push   %esi
f01007a0:	53                   	push   %ebx
f01007a1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	if(argc == 1){
f01007a4:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
f01007a8:	75 12                	jne    f01007bc <setpte+0x20>
		cprintf("Usage: setpte 0xaddress [0|1] [W|P|U]\n");
f01007aa:	83 ec 0c             	sub    $0xc,%esp
f01007ad:	68 ec 50 10 f0       	push   $0xf01050ec
f01007b2:	e8 46 2a 00 00       	call   f01031fd <cprintf>
		return 0;
f01007b7:	83 c4 10             	add    $0x10,%esp
f01007ba:	eb 6e                	jmp    f010082a <setpte+0x8e>
	}
	uint32_t addr = xtoi(argv[1]);
f01007bc:	8b 43 04             	mov    0x4(%ebx),%eax
f01007bf:	e8 5b fe ff ff       	call   f010061f <xtoi>
	pte_t *pte = pgdir_walk(kern_pgdir,(void*)addr, 1);
f01007c4:	83 ec 04             	sub    $0x4,%esp
f01007c7:	6a 01                	push   $0x1
f01007c9:	50                   	push   %eax
f01007ca:	ff 35 88 f1 17 f0    	pushl  0xf017f188
f01007d0:	e8 52 08 00 00       	call   f0101027 <pgdir_walk>
f01007d5:	89 c6                	mov    %eax,%esi
	cprintf("PTE_P: %x, PTE_W, %x, PTE_U, %x\n", *pte&PTE_P, *pte&PTE_W, *pte&PTE_U);
f01007d7:	8b 10                	mov    (%eax),%edx
f01007d9:	89 d0                	mov    %edx,%eax
f01007db:	83 e0 04             	and    $0x4,%eax
f01007de:	50                   	push   %eax
f01007df:	89 d0                	mov    %edx,%eax
f01007e1:	83 e0 02             	and    $0x2,%eax
f01007e4:	50                   	push   %eax
f01007e5:	83 e2 01             	and    $0x1,%edx
f01007e8:	52                   	push   %edx
f01007e9:	68 14 51 10 f0       	push   $0xf0105114
f01007ee:	e8 0a 2a 00 00       	call   f01031fd <cprintf>
	uint32_t perm = 0; 
	if(argv[3][0] =='P') perm = PTE_P;
f01007f3:	8b 43 0c             	mov    0xc(%ebx),%eax
f01007f6:	0f b6 10             	movzbl (%eax),%edx
f01007f9:	83 c4 20             	add    $0x20,%esp
f01007fc:	80 fa 50             	cmp    $0x50,%dl
f01007ff:	0f 94 c0             	sete   %al
f0100802:	0f b6 c0             	movzbl %al,%eax
	if(argv[3][0] =='W') perm |= PTE_W;
f0100805:	80 fa 57             	cmp    $0x57,%dl
f0100808:	75 05                	jne    f010080f <setpte+0x73>
f010080a:	83 c8 02             	or     $0x2,%eax
f010080d:	eb 0b                	jmp    f010081a <setpte+0x7e>
	if(argv[3][0] =='U') perm |= PTE_U;
f010080f:	89 c1                	mov    %eax,%ecx
f0100811:	83 c9 04             	or     $0x4,%ecx
f0100814:	80 fa 55             	cmp    $0x55,%dl
f0100817:	0f 44 c1             	cmove  %ecx,%eax
	if(argv[2][0] == '0')
f010081a:	8b 53 08             	mov    0x8(%ebx),%edx
f010081d:	80 3a 30             	cmpb   $0x30,(%edx)
f0100820:	75 06                	jne    f0100828 <setpte+0x8c>
		*pte = *pte & ~perm;
f0100822:	f7 d0                	not    %eax
f0100824:	21 06                	and    %eax,(%esi)
f0100826:	eb 02                	jmp    f010082a <setpte+0x8e>
	else
		*pte = *pte | perm;
f0100828:	09 06                	or     %eax,(%esi)
	return 0;
};
f010082a:	b8 00 00 00 00       	mov    $0x0,%eax
f010082f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100832:	5b                   	pop    %ebx
f0100833:	5e                   	pop    %esi
f0100834:	5d                   	pop    %ebp
f0100835:	c3                   	ret    

f0100836 <showmap>:
		++buf;
	}
	return res;
}

int showmap(int argc, char**argv, struct Trapframe*tf){
f0100836:	55                   	push   %ebp
f0100837:	89 e5                	mov    %esp,%ebp
f0100839:	57                   	push   %edi
f010083a:	56                   	push   %esi
f010083b:	53                   	push   %ebx
f010083c:	83 ec 0c             	sub    $0xc,%esp
f010083f:	8b 75 0c             	mov    0xc(%ebp),%esi
	if(argc == 1){	
f0100842:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
f0100846:	75 15                	jne    f010085d <showmap+0x27>
		cprintf("Usage: showmappings 0xbegin_addr 0xend_addr\n");
f0100848:	83 ec 0c             	sub    $0xc,%esp
f010084b:	68 38 51 10 f0       	push   $0xf0105138
f0100850:	e8 a8 29 00 00       	call   f01031fd <cprintf>
		return 0;
f0100855:	83 c4 10             	add    $0x10,%esp
f0100858:	e9 a5 00 00 00       	jmp    f0100902 <showmap+0xcc>
	}
	uint32_t begin = xtoi(argv[1]), end = xtoi(argv[2]);
f010085d:	8b 46 04             	mov    0x4(%esi),%eax
f0100860:	e8 ba fd ff ff       	call   f010061f <xtoi>
f0100865:	89 c3                	mov    %eax,%ebx
f0100867:	8b 46 08             	mov    0x8(%esi),%eax
f010086a:	e8 b0 fd ff ff       	call   f010061f <xtoi>
f010086f:	89 c7                	mov    %eax,%edi
	cprintf("begin : %x, end: %x\n", begin, end);
f0100871:	83 ec 04             	sub    $0x4,%esp
f0100874:	50                   	push   %eax
f0100875:	53                   	push   %ebx
f0100876:	68 cb 4e 10 f0       	push   $0xf0104ecb
f010087b:	e8 7d 29 00 00       	call   f01031fd <cprintf>
	for(; begin <= end; begin += PGSIZE){
f0100880:	83 c4 10             	add    $0x10,%esp
f0100883:	eb 79                	jmp    f01008fe <showmap+0xc8>
		pte_t *pte = pgdir_walk(kern_pgdir,(void*)begin, 1);
f0100885:	83 ec 04             	sub    $0x4,%esp
f0100888:	6a 01                	push   $0x1
f010088a:	53                   	push   %ebx
f010088b:	ff 35 88 f1 17 f0    	pushl  0xf017f188
f0100891:	e8 91 07 00 00       	call   f0101027 <pgdir_walk>
f0100896:	89 c6                	mov    %eax,%esi
		if(!pte) panic("boot map region panic, out of memory");
f0100898:	83 c4 10             	add    $0x10,%esp
f010089b:	85 c0                	test   %eax,%eax
f010089d:	75 14                	jne    f01008b3 <showmap+0x7d>
f010089f:	83 ec 04             	sub    $0x4,%esp
f01008a2:	68 68 51 10 f0       	push   $0xf0105168
f01008a7:	6a 2e                	push   $0x2e
f01008a9:	68 e0 4e 10 f0       	push   $0xf0104ee0
f01008ae:	e8 ed f7 ff ff       	call   f01000a0 <_panic>
		if(*pte & PTE_P){
f01008b3:	f6 00 01             	testb  $0x1,(%eax)
f01008b6:	74 2f                	je     f01008e7 <showmap+0xb1>
			cprintf("page %x with ", begin);
f01008b8:	83 ec 08             	sub    $0x8,%esp
f01008bb:	53                   	push   %ebx
f01008bc:	68 ef 4e 10 f0       	push   $0xf0104eef
f01008c1:	e8 37 29 00 00       	call   f01031fd <cprintf>
			cprintf("PTE_P: %x, PTE_W, %x, PTE_U, %x\n", *pte&PTE_P, *pte&PTE_W, *pte&PTE_U);
f01008c6:	8b 06                	mov    (%esi),%eax
f01008c8:	89 c2                	mov    %eax,%edx
f01008ca:	83 e2 04             	and    $0x4,%edx
f01008cd:	52                   	push   %edx
f01008ce:	89 c2                	mov    %eax,%edx
f01008d0:	83 e2 02             	and    $0x2,%edx
f01008d3:	52                   	push   %edx
f01008d4:	83 e0 01             	and    $0x1,%eax
f01008d7:	50                   	push   %eax
f01008d8:	68 14 51 10 f0       	push   $0xf0105114
f01008dd:	e8 1b 29 00 00       	call   f01031fd <cprintf>
f01008e2:	83 c4 20             	add    $0x20,%esp
f01008e5:	eb 11                	jmp    f01008f8 <showmap+0xc2>
		}
		else{
			cprintf("page not exist: %x\n",begin);
f01008e7:	83 ec 08             	sub    $0x8,%esp
f01008ea:	53                   	push   %ebx
f01008eb:	68 fd 4e 10 f0       	push   $0xf0104efd
f01008f0:	e8 08 29 00 00       	call   f01031fd <cprintf>
f01008f5:	83 c4 10             	add    $0x10,%esp
		cprintf("Usage: showmappings 0xbegin_addr 0xend_addr\n");
		return 0;
	}
	uint32_t begin = xtoi(argv[1]), end = xtoi(argv[2]);
	cprintf("begin : %x, end: %x\n", begin, end);
	for(; begin <= end; begin += PGSIZE){
f01008f8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01008fe:	39 fb                	cmp    %edi,%ebx
f0100900:	76 83                	jbe    f0100885 <showmap+0x4f>
		else{
			cprintf("page not exist: %x\n",begin);
		}
	}
	return 0;
}
f0100902:	b8 00 00 00 00       	mov    $0x0,%eax
f0100907:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010090a:	5b                   	pop    %ebx
f010090b:	5e                   	pop    %esi
f010090c:	5f                   	pop    %edi
f010090d:	5d                   	pop    %ebp
f010090e:	c3                   	ret    

f010090f <mon_backtrace>:
}*/


int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010090f:	55                   	push   %ebp
f0100910:	89 e5                	mov    %esp,%ebp
f0100912:	57                   	push   %edi
f0100913:	56                   	push   %esi
f0100914:	53                   	push   %ebx
f0100915:	83 ec 38             	sub    $0x38,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100918:	89 ee                	mov    %ebp,%esi
	uint32_t *ebp = (uint32_t*)read_ebp();
f010091a:	89 f3                	mov    %esi,%ebx
	uint32_t *eip = ebp + 1;
f010091c:	83 c6 04             	add    $0x4,%esi
	cprintf("Stack backtrace:\n");
f010091f:	68 11 4f 10 f0       	push   $0xf0104f11
f0100924:	e8 d4 28 00 00       	call   f01031fd <cprintf>
	while(ebp){
f0100929:	83 c4 10             	add    $0x10,%esp
		cprintf("ebp %08x   eip %08x  args %08x %08x %08x %08x %08x\n",ebp, *eip, *(ebp + 2), *(ebp+3),*(ebp + 4), *(ebp + 5), *(ebp + 6));
		struct Eipdebuginfo info;
		debuginfo_eip(*eip,&info);
f010092c:	8d 7d d0             	lea    -0x30(%ebp),%edi
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t *ebp = (uint32_t*)read_ebp();
	uint32_t *eip = ebp + 1;
	cprintf("Stack backtrace:\n");
	while(ebp){
f010092f:	eb 4e                	jmp    f010097f <mon_backtrace+0x70>
		cprintf("ebp %08x   eip %08x  args %08x %08x %08x %08x %08x\n",ebp, *eip, *(ebp + 2), *(ebp+3),*(ebp + 4), *(ebp + 5), *(ebp + 6));
f0100931:	ff 73 18             	pushl  0x18(%ebx)
f0100934:	ff 73 14             	pushl  0x14(%ebx)
f0100937:	ff 73 10             	pushl  0x10(%ebx)
f010093a:	ff 73 0c             	pushl  0xc(%ebx)
f010093d:	ff 73 08             	pushl  0x8(%ebx)
f0100940:	ff 36                	pushl  (%esi)
f0100942:	53                   	push   %ebx
f0100943:	68 90 51 10 f0       	push   $0xf0105190
f0100948:	e8 b0 28 00 00       	call   f01031fd <cprintf>
		struct Eipdebuginfo info;
		debuginfo_eip(*eip,&info);
f010094d:	83 c4 18             	add    $0x18,%esp
f0100950:	57                   	push   %edi
f0100951:	ff 36                	pushl  (%esi)
f0100953:	e8 06 31 00 00       	call   f0103a5e <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,(*eip) - info.eip_fn_addr);
f0100958:	83 c4 08             	add    $0x8,%esp
f010095b:	8b 06                	mov    (%esi),%eax
f010095d:	2b 45 e0             	sub    -0x20(%ebp),%eax
f0100960:	50                   	push   %eax
f0100961:	ff 75 d8             	pushl  -0x28(%ebp)
f0100964:	ff 75 dc             	pushl  -0x24(%ebp)
f0100967:	ff 75 d4             	pushl  -0x2c(%ebp)
f010096a:	ff 75 d0             	pushl  -0x30(%ebp)
f010096d:	68 23 4f 10 f0       	push   $0xf0104f23
f0100972:	e8 86 28 00 00       	call   f01031fd <cprintf>
		ebp = (uint32_t*)*ebp;
f0100977:	8b 1b                	mov    (%ebx),%ebx
		eip = (uint32_t*)ebp + 1;
f0100979:	8d 73 04             	lea    0x4(%ebx),%esi
f010097c:	83 c4 20             	add    $0x20,%esp
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t *ebp = (uint32_t*)read_ebp();
	uint32_t *eip = ebp + 1;
	cprintf("Stack backtrace:\n");
	while(ebp){
f010097f:	85 db                	test   %ebx,%ebx
f0100981:	75 ae                	jne    f0100931 <mon_backtrace+0x22>
		ebp = (uint32_t*)*ebp;
		eip = (uint32_t*)ebp + 1;
	}
	
	return 0;
}
f0100983:	b8 00 00 00 00       	mov    $0x0,%eax
f0100988:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010098b:	5b                   	pop    %ebx
f010098c:	5e                   	pop    %esi
f010098d:	5f                   	pop    %edi
f010098e:	5d                   	pop    %ebp
f010098f:	c3                   	ret    

f0100990 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100990:	55                   	push   %ebp
f0100991:	89 e5                	mov    %esp,%ebp
f0100993:	57                   	push   %edi
f0100994:	56                   	push   %esi
f0100995:	53                   	push   %ebx
f0100996:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100999:	68 c4 51 10 f0       	push   $0xf01051c4
f010099e:	e8 5a 28 00 00       	call   f01031fd <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01009a3:	c7 04 24 e8 51 10 f0 	movl   $0xf01051e8,(%esp)
f01009aa:	e8 4e 28 00 00       	call   f01031fd <cprintf>

	if (tf != NULL)
f01009af:	83 c4 10             	add    $0x10,%esp
f01009b2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01009b6:	74 0e                	je     f01009c6 <monitor+0x36>
		print_trapframe(tf);
f01009b8:	83 ec 0c             	sub    $0xc,%esp
f01009bb:	ff 75 08             	pushl  0x8(%ebp)
f01009be:	e8 0e 2b 00 00       	call   f01034d1 <print_trapframe>
f01009c3:	83 c4 10             	add    $0x10,%esp

	cprintf("%Ccyn Colored scheme with no highlight.\n");
f01009c6:	83 ec 0c             	sub    $0xc,%esp
f01009c9:	68 10 52 10 f0       	push   $0xf0105210
f01009ce:	e8 2a 28 00 00       	call   f01031fd <cprintf>
	cprintf("%Cble Hello%Cred World. %Cmag Test for colorization.\n");
f01009d3:	c7 04 24 3c 52 10 f0 	movl   $0xf010523c,(%esp)
f01009da:	e8 1e 28 00 00       	call   f01031fd <cprintf>
	cprintf("%Ibrw Colored scheme with highlight.\n");
f01009df:	c7 04 24 74 52 10 f0 	movl   $0xf0105274,(%esp)
f01009e6:	e8 12 28 00 00       	call   f01031fd <cprintf>
	cprintf("%Ible Hello%Ired World. %Imag Test for colorization.\n");
f01009eb:	c7 04 24 9c 52 10 f0 	movl   $0xf010529c,(%esp)
f01009f2:	e8 06 28 00 00       	call   f01031fd <cprintf>
	cprintf("%Cwht Return to default!\n");
f01009f7:	c7 04 24 34 4f 10 f0 	movl   $0xf0104f34,(%esp)
f01009fe:	e8 fa 27 00 00       	call   f01031fd <cprintf>
f0100a03:	83 c4 10             	add    $0x10,%esp
	while (1) {
		buf = readline("K> ");
f0100a06:	83 ec 0c             	sub    $0xc,%esp
f0100a09:	68 4e 4f 10 f0       	push   $0xf0104f4e
f0100a0e:	e8 99 3a 00 00       	call   f01044ac <readline>
f0100a13:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100a15:	83 c4 10             	add    $0x10,%esp
f0100a18:	85 c0                	test   %eax,%eax
f0100a1a:	74 ea                	je     f0100a06 <monitor+0x76>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100a1c:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100a23:	be 00 00 00 00       	mov    $0x0,%esi
f0100a28:	eb 0a                	jmp    f0100a34 <monitor+0xa4>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100a2a:	c6 03 00             	movb   $0x0,(%ebx)
f0100a2d:	89 f7                	mov    %esi,%edi
f0100a2f:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100a32:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100a34:	0f b6 03             	movzbl (%ebx),%eax
f0100a37:	84 c0                	test   %al,%al
f0100a39:	74 63                	je     f0100a9e <monitor+0x10e>
f0100a3b:	83 ec 08             	sub    $0x8,%esp
f0100a3e:	0f be c0             	movsbl %al,%eax
f0100a41:	50                   	push   %eax
f0100a42:	68 52 4f 10 f0       	push   $0xf0104f52
f0100a47:	e8 7a 3c 00 00       	call   f01046c6 <strchr>
f0100a4c:	83 c4 10             	add    $0x10,%esp
f0100a4f:	85 c0                	test   %eax,%eax
f0100a51:	75 d7                	jne    f0100a2a <monitor+0x9a>
			*buf++ = 0;
		if (*buf == 0)
f0100a53:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100a56:	74 46                	je     f0100a9e <monitor+0x10e>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100a58:	83 fe 0f             	cmp    $0xf,%esi
f0100a5b:	75 14                	jne    f0100a71 <monitor+0xe1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100a5d:	83 ec 08             	sub    $0x8,%esp
f0100a60:	6a 10                	push   $0x10
f0100a62:	68 57 4f 10 f0       	push   $0xf0104f57
f0100a67:	e8 91 27 00 00       	call   f01031fd <cprintf>
f0100a6c:	83 c4 10             	add    $0x10,%esp
f0100a6f:	eb 95                	jmp    f0100a06 <monitor+0x76>
			return 0;
		}
		argv[argc++] = buf;
f0100a71:	8d 7e 01             	lea    0x1(%esi),%edi
f0100a74:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100a78:	eb 03                	jmp    f0100a7d <monitor+0xed>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100a7a:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a7d:	0f b6 03             	movzbl (%ebx),%eax
f0100a80:	84 c0                	test   %al,%al
f0100a82:	74 ae                	je     f0100a32 <monitor+0xa2>
f0100a84:	83 ec 08             	sub    $0x8,%esp
f0100a87:	0f be c0             	movsbl %al,%eax
f0100a8a:	50                   	push   %eax
f0100a8b:	68 52 4f 10 f0       	push   $0xf0104f52
f0100a90:	e8 31 3c 00 00       	call   f01046c6 <strchr>
f0100a95:	83 c4 10             	add    $0x10,%esp
f0100a98:	85 c0                	test   %eax,%eax
f0100a9a:	74 de                	je     f0100a7a <monitor+0xea>
f0100a9c:	eb 94                	jmp    f0100a32 <monitor+0xa2>
			buf++;
	}
	argv[argc] = 0;
f0100a9e:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100aa5:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100aa6:	85 f6                	test   %esi,%esi
f0100aa8:	0f 84 58 ff ff ff    	je     f0100a06 <monitor+0x76>
f0100aae:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100ab3:	83 ec 08             	sub    $0x8,%esp
f0100ab6:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100ab9:	ff 34 85 40 53 10 f0 	pushl  -0xfefacc0(,%eax,4)
f0100ac0:	ff 75 a8             	pushl  -0x58(%ebp)
f0100ac3:	e8 a0 3b 00 00       	call   f0104668 <strcmp>
f0100ac8:	83 c4 10             	add    $0x10,%esp
f0100acb:	85 c0                	test   %eax,%eax
f0100acd:	75 22                	jne    f0100af1 <monitor+0x161>
			return commands[i].func(argc, argv, tf);
f0100acf:	83 ec 04             	sub    $0x4,%esp
f0100ad2:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100ad5:	ff 75 08             	pushl  0x8(%ebp)
f0100ad8:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100adb:	52                   	push   %edx
f0100adc:	56                   	push   %esi
f0100add:	ff 14 85 48 53 10 f0 	call   *-0xfefacb8(,%eax,4)
	cprintf("%Ible Hello%Ired World. %Imag Test for colorization.\n");
	cprintf("%Cwht Return to default!\n");
	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100ae4:	83 c4 10             	add    $0x10,%esp
f0100ae7:	85 c0                	test   %eax,%eax
f0100ae9:	0f 89 17 ff ff ff    	jns    f0100a06 <monitor+0x76>
f0100aef:	eb 20                	jmp    f0100b11 <monitor+0x181>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100af1:	83 c3 01             	add    $0x1,%ebx
f0100af4:	83 fb 06             	cmp    $0x6,%ebx
f0100af7:	75 ba                	jne    f0100ab3 <monitor+0x123>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100af9:	83 ec 08             	sub    $0x8,%esp
f0100afc:	ff 75 a8             	pushl  -0x58(%ebp)
f0100aff:	68 74 4f 10 f0       	push   $0xf0104f74
f0100b04:	e8 f4 26 00 00       	call   f01031fd <cprintf>
f0100b09:	83 c4 10             	add    $0x10,%esp
f0100b0c:	e9 f5 fe ff ff       	jmp    f0100a06 <monitor+0x76>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100b11:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100b14:	5b                   	pop    %ebx
f0100b15:	5e                   	pop    %esi
f0100b16:	5f                   	pop    %edi
f0100b17:	5d                   	pop    %ebp
f0100b18:	c3                   	ret    

f0100b19 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100b19:	89 d1                	mov    %edx,%ecx
f0100b1b:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100b1e:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100b21:	a8 01                	test   $0x1,%al
f0100b23:	74 52                	je     f0100b77 <check_va2pa+0x5e>
		return ~0;
	if(pseEnbl && *pgdir & PTE_PS){
		return PTE_ADDR(*pgdir) + (PTX(va) << PGSHIFT);
	}
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100b25:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b2a:	89 c1                	mov    %eax,%ecx
f0100b2c:	c1 e9 0c             	shr    $0xc,%ecx
f0100b2f:	3b 0d 84 f1 17 f0    	cmp    0xf017f184,%ecx
f0100b35:	72 1b                	jb     f0100b52 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b37:	55                   	push   %ebp
f0100b38:	89 e5                	mov    %esp,%ebp
f0100b3a:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b3d:	50                   	push   %eax
f0100b3e:	68 88 53 10 f0       	push   $0xf0105388
f0100b43:	68 3f 03 00 00       	push   $0x33f
f0100b48:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0100b4d:	e8 4e f5 ff ff       	call   f01000a0 <_panic>
		return ~0;
	if(pseEnbl && *pgdir & PTE_PS){
		return PTE_ADDR(*pgdir) + (PTX(va) << PGSHIFT);
	}
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100b52:	c1 ea 0c             	shr    $0xc,%edx
f0100b55:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b5b:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100b62:	89 c2                	mov    %eax,%edx
f0100b64:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b67:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b6c:	85 d2                	test   %edx,%edx
f0100b6e:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b73:	0f 44 c2             	cmove  %edx,%eax
f0100b76:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100b77:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	}
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100b7c:	c3                   	ret    

f0100b7d <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100b7d:	55                   	push   %ebp
f0100b7e:	89 e5                	mov    %esp,%ebp
f0100b80:	83 ec 08             	sub    $0x8,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100b83:	83 3d 98 e4 17 f0 00 	cmpl   $0x0,0xf017e498
f0100b8a:	75 11                	jne    f0100b9d <boot_alloc+0x20>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100b8c:	ba 8f 01 18 f0       	mov    $0xf018018f,%edx
f0100b91:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b97:	89 15 98 e4 17 f0    	mov    %edx,0xf017e498
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	
	if(n != 0){
f0100b9d:	85 c0                	test   %eax,%eax
f0100b9f:	74 5f                	je     f0100c00 <boot_alloc+0x83>
		char *start = nextfree;
f0100ba1:	8b 0d 98 e4 17 f0    	mov    0xf017e498,%ecx
		nextfree += n;
		nextfree = ROUNDUP((char*)nextfree, PGSIZE);
f0100ba7:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f0100bae:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100bb4:	89 15 98 e4 17 f0    	mov    %edx,0xf017e498
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100bba:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0100bc0:	77 12                	ja     f0100bd4 <boot_alloc+0x57>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100bc2:	52                   	push   %edx
f0100bc3:	68 ac 53 10 f0       	push   $0xf01053ac
f0100bc8:	6a 6d                	push   $0x6d
f0100bca:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0100bcf:	e8 cc f4 ff ff       	call   f01000a0 <_panic>
		if(PADDR(nextfree) > npages * PGSIZE){
f0100bd4:	a1 84 f1 17 f0       	mov    0xf017f184,%eax
f0100bd9:	c1 e0 0c             	shl    $0xc,%eax
	return (physaddr_t)kva - KERNBASE;
f0100bdc:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0100be2:	39 d0                	cmp    %edx,%eax
f0100be4:	73 21                	jae    f0100c07 <boot_alloc+0x8a>
			nextfree = start;
f0100be6:	89 0d 98 e4 17 f0    	mov    %ecx,0xf017e498
			panic("Run out of memory");
f0100bec:	83 ec 04             	sub    $0x4,%esp
f0100bef:	68 69 5c 10 f0       	push   $0xf0105c69
f0100bf4:	6a 6f                	push   $0x6f
f0100bf6:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0100bfb:	e8 a0 f4 ff ff       	call   f01000a0 <_panic>
		}
		return start;
	}
	else{
		return nextfree;
f0100c00:	a1 98 e4 17 f0       	mov    0xf017e498,%eax
f0100c05:	eb 02                	jmp    f0100c09 <boot_alloc+0x8c>
		nextfree = ROUNDUP((char*)nextfree, PGSIZE);
		if(PADDR(nextfree) > npages * PGSIZE){
			nextfree = start;
			panic("Run out of memory");
		}
		return start;
f0100c07:	89 c8                	mov    %ecx,%eax
	}
	else{
		return nextfree;
	}
//	return NULL;
}
f0100c09:	c9                   	leave  
f0100c0a:	c3                   	ret    

f0100c0b <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100c0b:	55                   	push   %ebp
f0100c0c:	89 e5                	mov    %esp,%ebp
f0100c0e:	57                   	push   %edi
f0100c0f:	56                   	push   %esi
f0100c10:	53                   	push   %ebx
f0100c11:	83 ec 3c             	sub    $0x3c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c14:	84 c0                	test   %al,%al
f0100c16:	0f 85 7a 02 00 00    	jne    f0100e96 <check_page_free_list+0x28b>
f0100c1c:	e9 87 02 00 00       	jmp    f0100ea8 <check_page_free_list+0x29d>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100c21:	83 ec 04             	sub    $0x4,%esp
f0100c24:	68 d0 53 10 f0       	push   $0xf01053d0
f0100c29:	68 7a 02 00 00       	push   $0x27a
f0100c2e:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0100c33:	e8 68 f4 ff ff       	call   f01000a0 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100c38:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100c3b:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100c3e:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c41:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c44:	89 c2                	mov    %eax,%edx
f0100c46:	2b 15 8c f1 17 f0    	sub    0xf017f18c,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100c4c:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100c52:	0f 95 c2             	setne  %dl
f0100c55:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100c58:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100c5c:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100c5e:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c62:	8b 00                	mov    (%eax),%eax
f0100c64:	85 c0                	test   %eax,%eax
f0100c66:	75 dc                	jne    f0100c44 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100c68:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c6b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100c71:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c74:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c77:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100c79:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100c7c:	a3 a0 e4 17 f0       	mov    %eax,0xf017e4a0
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c81:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c86:	8b 1d a0 e4 17 f0    	mov    0xf017e4a0,%ebx
f0100c8c:	eb 53                	jmp    f0100ce1 <check_page_free_list+0xd6>
f0100c8e:	89 d8                	mov    %ebx,%eax
f0100c90:	2b 05 8c f1 17 f0    	sub    0xf017f18c,%eax
f0100c96:	c1 f8 03             	sar    $0x3,%eax
f0100c99:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100c9c:	89 c2                	mov    %eax,%edx
f0100c9e:	c1 ea 16             	shr    $0x16,%edx
f0100ca1:	39 f2                	cmp    %esi,%edx
f0100ca3:	73 3a                	jae    f0100cdf <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ca5:	89 c2                	mov    %eax,%edx
f0100ca7:	c1 ea 0c             	shr    $0xc,%edx
f0100caa:	3b 15 84 f1 17 f0    	cmp    0xf017f184,%edx
f0100cb0:	72 12                	jb     f0100cc4 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cb2:	50                   	push   %eax
f0100cb3:	68 88 53 10 f0       	push   $0xf0105388
f0100cb8:	6a 56                	push   $0x56
f0100cba:	68 7b 5c 10 f0       	push   $0xf0105c7b
f0100cbf:	e8 dc f3 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100cc4:	83 ec 04             	sub    $0x4,%esp
f0100cc7:	68 80 00 00 00       	push   $0x80
f0100ccc:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100cd1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100cd6:	50                   	push   %eax
f0100cd7:	e8 27 3a 00 00       	call   f0104703 <memset>
f0100cdc:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100cdf:	8b 1b                	mov    (%ebx),%ebx
f0100ce1:	85 db                	test   %ebx,%ebx
f0100ce3:	75 a9                	jne    f0100c8e <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100ce5:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cea:	e8 8e fe ff ff       	call   f0100b7d <boot_alloc>
f0100cef:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100cf2:	8b 15 a0 e4 17 f0    	mov    0xf017e4a0,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100cf8:	8b 0d 8c f1 17 f0    	mov    0xf017f18c,%ecx
		assert(pp < pages + npages);
f0100cfe:	a1 84 f1 17 f0       	mov    0xf017f184,%eax
f0100d03:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100d06:	8d 1c c1             	lea    (%ecx,%eax,8),%ebx
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d09:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100d0c:	be 00 00 00 00       	mov    $0x0,%esi
f0100d11:	bf 00 00 00 00       	mov    $0x0,%edi
f0100d16:	89 75 cc             	mov    %esi,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d19:	e9 33 01 00 00       	jmp    f0100e51 <check_page_free_list+0x246>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100d1e:	39 ca                	cmp    %ecx,%edx
f0100d20:	73 19                	jae    f0100d3b <check_page_free_list+0x130>
f0100d22:	68 89 5c 10 f0       	push   $0xf0105c89
f0100d27:	68 95 5c 10 f0       	push   $0xf0105c95
f0100d2c:	68 94 02 00 00       	push   $0x294
f0100d31:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0100d36:	e8 65 f3 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100d3b:	39 da                	cmp    %ebx,%edx
f0100d3d:	72 19                	jb     f0100d58 <check_page_free_list+0x14d>
f0100d3f:	68 aa 5c 10 f0       	push   $0xf0105caa
f0100d44:	68 95 5c 10 f0       	push   $0xf0105c95
f0100d49:	68 95 02 00 00       	push   $0x295
f0100d4e:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0100d53:	e8 48 f3 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d58:	89 d0                	mov    %edx,%eax
f0100d5a:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100d5d:	a8 07                	test   $0x7,%al
f0100d5f:	74 19                	je     f0100d7a <check_page_free_list+0x16f>
f0100d61:	68 f4 53 10 f0       	push   $0xf01053f4
f0100d66:	68 95 5c 10 f0       	push   $0xf0105c95
f0100d6b:	68 96 02 00 00       	push   $0x296
f0100d70:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0100d75:	e8 26 f3 ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d7a:	c1 f8 03             	sar    $0x3,%eax
f0100d7d:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100d80:	85 c0                	test   %eax,%eax
f0100d82:	75 19                	jne    f0100d9d <check_page_free_list+0x192>
f0100d84:	68 be 5c 10 f0       	push   $0xf0105cbe
f0100d89:	68 95 5c 10 f0       	push   $0xf0105c95
f0100d8e:	68 99 02 00 00       	push   $0x299
f0100d93:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0100d98:	e8 03 f3 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d9d:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100da2:	75 19                	jne    f0100dbd <check_page_free_list+0x1b2>
f0100da4:	68 cf 5c 10 f0       	push   $0xf0105ccf
f0100da9:	68 95 5c 10 f0       	push   $0xf0105c95
f0100dae:	68 9a 02 00 00       	push   $0x29a
f0100db3:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0100db8:	e8 e3 f2 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100dbd:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100dc2:	75 19                	jne    f0100ddd <check_page_free_list+0x1d2>
f0100dc4:	68 28 54 10 f0       	push   $0xf0105428
f0100dc9:	68 95 5c 10 f0       	push   $0xf0105c95
f0100dce:	68 9b 02 00 00       	push   $0x29b
f0100dd3:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0100dd8:	e8 c3 f2 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100ddd:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100de2:	75 19                	jne    f0100dfd <check_page_free_list+0x1f2>
f0100de4:	68 e8 5c 10 f0       	push   $0xf0105ce8
f0100de9:	68 95 5c 10 f0       	push   $0xf0105c95
f0100dee:	68 9c 02 00 00       	push   $0x29c
f0100df3:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0100df8:	e8 a3 f2 ff ff       	call   f01000a0 <_panic>
f0100dfd:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e00:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100e05:	76 3f                	jbe    f0100e46 <check_page_free_list+0x23b>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e07:	89 c6                	mov    %eax,%esi
f0100e09:	c1 ee 0c             	shr    $0xc,%esi
f0100e0c:	39 75 c4             	cmp    %esi,-0x3c(%ebp)
f0100e0f:	77 12                	ja     f0100e23 <check_page_free_list+0x218>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e11:	50                   	push   %eax
f0100e12:	68 88 53 10 f0       	push   $0xf0105388
f0100e17:	6a 56                	push   $0x56
f0100e19:	68 7b 5c 10 f0       	push   $0xf0105c7b
f0100e1e:	e8 7d f2 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0100e23:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e28:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100e2b:	76 1e                	jbe    f0100e4b <check_page_free_list+0x240>
f0100e2d:	68 4c 54 10 f0       	push   $0xf010544c
f0100e32:	68 95 5c 10 f0       	push   $0xf0105c95
f0100e37:	68 9d 02 00 00       	push   $0x29d
f0100e3c:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0100e41:	e8 5a f2 ff ff       	call   f01000a0 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100e46:	83 c7 01             	add    $0x1,%edi
f0100e49:	eb 04                	jmp    f0100e4f <check_page_free_list+0x244>
		else
			++nfree_extmem;
f0100e4b:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100e4f:	8b 12                	mov    (%edx),%edx
f0100e51:	85 d2                	test   %edx,%edx
f0100e53:	0f 85 c5 fe ff ff    	jne    f0100d1e <check_page_free_list+0x113>
f0100e59:	8b 75 cc             	mov    -0x34(%ebp),%esi
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100e5c:	85 ff                	test   %edi,%edi
f0100e5e:	7f 19                	jg     f0100e79 <check_page_free_list+0x26e>
f0100e60:	68 02 5d 10 f0       	push   $0xf0105d02
f0100e65:	68 95 5c 10 f0       	push   $0xf0105c95
f0100e6a:	68 a5 02 00 00       	push   $0x2a5
f0100e6f:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0100e74:	e8 27 f2 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100e79:	85 f6                	test   %esi,%esi
f0100e7b:	7f 42                	jg     f0100ebf <check_page_free_list+0x2b4>
f0100e7d:	68 14 5d 10 f0       	push   $0xf0105d14
f0100e82:	68 95 5c 10 f0       	push   $0xf0105c95
f0100e87:	68 a6 02 00 00       	push   $0x2a6
f0100e8c:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0100e91:	e8 0a f2 ff ff       	call   f01000a0 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100e96:	a1 a0 e4 17 f0       	mov    0xf017e4a0,%eax
f0100e9b:	85 c0                	test   %eax,%eax
f0100e9d:	0f 85 95 fd ff ff    	jne    f0100c38 <check_page_free_list+0x2d>
f0100ea3:	e9 79 fd ff ff       	jmp    f0100c21 <check_page_free_list+0x16>
f0100ea8:	83 3d a0 e4 17 f0 00 	cmpl   $0x0,0xf017e4a0
f0100eaf:	0f 84 6c fd ff ff    	je     f0100c21 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100eb5:	be 00 04 00 00       	mov    $0x400,%esi
f0100eba:	e9 c7 fd ff ff       	jmp    f0100c86 <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100ebf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ec2:	5b                   	pop    %ebx
f0100ec3:	5e                   	pop    %esi
f0100ec4:	5f                   	pop    %edi
f0100ec5:	5d                   	pop    %ebp
f0100ec6:	c3                   	ret    

f0100ec7 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100ec7:	55                   	push   %ebp
f0100ec8:	89 e5                	mov    %esp,%ebp
f0100eca:	57                   	push   %edi
f0100ecb:	56                   	push   %esi
f0100ecc:	53                   	push   %ebx
f0100ecd:	83 ec 0c             	sub    $0xc,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 1; i < npages; i++) {
f0100ed0:	be 01 00 00 00       	mov    $0x1,%esi
f0100ed5:	eb 68                	jmp    f0100f3f <page_init+0x78>
f0100ed7:	8d 1c f5 00 00 00 00 	lea    0x0(,%esi,8),%ebx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ede:	89 df                	mov    %ebx,%edi
f0100ee0:	c1 e7 09             	shl    $0x9,%edi
		if(page2pa(&pages[i]) >= IOPHYSMEM && page2pa(&pages[i]) < PADDR(boot_alloc(0))) continue;
f0100ee3:	81 ff ff ff 09 00    	cmp    $0x9ffff,%edi
f0100ee9:	76 2f                	jbe    f0100f1a <page_init+0x53>
f0100eeb:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ef0:	e8 88 fc ff ff       	call   f0100b7d <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100ef5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100efa:	77 15                	ja     f0100f11 <page_init+0x4a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100efc:	50                   	push   %eax
f0100efd:	68 ac 53 10 f0       	push   $0xf01053ac
f0100f02:	68 32 01 00 00       	push   $0x132
f0100f07:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0100f0c:	e8 8f f1 ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100f11:	05 00 00 00 10       	add    $0x10000000,%eax
f0100f16:	39 c7                	cmp    %eax,%edi
f0100f18:	72 22                	jb     f0100f3c <page_init+0x75>
		pages[i].pp_ref = 0;
f0100f1a:	89 d8                	mov    %ebx,%eax
f0100f1c:	03 05 8c f1 17 f0    	add    0xf017f18c,%eax
f0100f22:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
		pages[i].pp_link = page_free_list;
f0100f28:	8b 15 a0 e4 17 f0    	mov    0xf017e4a0,%edx
f0100f2e:	89 10                	mov    %edx,(%eax)
		page_free_list = &pages[i];
f0100f30:	03 1d 8c f1 17 f0    	add    0xf017f18c,%ebx
f0100f36:	89 1d a0 e4 17 f0    	mov    %ebx,0xf017e4a0
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 1; i < npages; i++) {
f0100f3c:	83 c6 01             	add    $0x1,%esi
f0100f3f:	3b 35 84 f1 17 f0    	cmp    0xf017f184,%esi
f0100f45:	72 90                	jb     f0100ed7 <page_init+0x10>
		if(page2pa(&pages[i]) >= IOPHYSMEM && page2pa(&pages[i]) < PADDR(boot_alloc(0))) continue;
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0100f47:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f4a:	5b                   	pop    %ebx
f0100f4b:	5e                   	pop    %esi
f0100f4c:	5f                   	pop    %edi
f0100f4d:	5d                   	pop    %ebp
f0100f4e:	c3                   	ret    

f0100f4f <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100f4f:	55                   	push   %ebp
f0100f50:	89 e5                	mov    %esp,%ebp
f0100f52:	53                   	push   %ebx
f0100f53:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	if(page_free_list == NULL) return NULL; //out of memory
f0100f56:	8b 1d a0 e4 17 f0    	mov    0xf017e4a0,%ebx
f0100f5c:	85 db                	test   %ebx,%ebx
f0100f5e:	74 58                	je     f0100fb8 <page_alloc+0x69>
	struct PageInfo *ret = page_free_list; //fetch the head of the page list
	page_free_list = page_free_list->pp_link;
f0100f60:	8b 03                	mov    (%ebx),%eax
f0100f62:	a3 a0 e4 17 f0       	mov    %eax,0xf017e4a0
	if(alloc_flags && ALLOC_ZERO){
f0100f67:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100f6b:	74 45                	je     f0100fb2 <page_alloc+0x63>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f6d:	89 d8                	mov    %ebx,%eax
f0100f6f:	2b 05 8c f1 17 f0    	sub    0xf017f18c,%eax
f0100f75:	c1 f8 03             	sar    $0x3,%eax
f0100f78:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f7b:	89 c2                	mov    %eax,%edx
f0100f7d:	c1 ea 0c             	shr    $0xc,%edx
f0100f80:	3b 15 84 f1 17 f0    	cmp    0xf017f184,%edx
f0100f86:	72 12                	jb     f0100f9a <page_alloc+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f88:	50                   	push   %eax
f0100f89:	68 88 53 10 f0       	push   $0xf0105388
f0100f8e:	6a 56                	push   $0x56
f0100f90:	68 7b 5c 10 f0       	push   $0xf0105c7b
f0100f95:	e8 06 f1 ff ff       	call   f01000a0 <_panic>
		memset(page2kva(ret), '\0', PGSIZE);
f0100f9a:	83 ec 04             	sub    $0x4,%esp
f0100f9d:	68 00 10 00 00       	push   $0x1000
f0100fa2:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0100fa4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100fa9:	50                   	push   %eax
f0100faa:	e8 54 37 00 00       	call   f0104703 <memset>
f0100faf:	83 c4 10             	add    $0x10,%esp
	}
	//avoid double free error
	ret->pp_link = NULL;
f0100fb2:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	return ret;	
}
f0100fb8:	89 d8                	mov    %ebx,%eax
f0100fba:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fbd:	c9                   	leave  
f0100fbe:	c3                   	ret    

f0100fbf <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100fbf:	55                   	push   %ebp
f0100fc0:	89 e5                	mov    %esp,%ebp
f0100fc2:	83 ec 08             	sub    $0x8,%esp
f0100fc5:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if(pp->pp_ref != 0 || pp->pp_link != NULL){
f0100fc8:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100fcd:	75 05                	jne    f0100fd4 <page_free+0x15>
f0100fcf:	83 38 00             	cmpl   $0x0,(%eax)
f0100fd2:	74 17                	je     f0100feb <page_free+0x2c>
		panic("free an occupied page, or its next is not NULL");
f0100fd4:	83 ec 04             	sub    $0x4,%esp
f0100fd7:	68 94 54 10 f0       	push   $0xf0105494
f0100fdc:	68 5f 01 00 00       	push   $0x15f
f0100fe1:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0100fe6:	e8 b5 f0 ff ff       	call   f01000a0 <_panic>
	}
	pp->pp_ref = 0;
f0100feb:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
	struct PageInfo* tmp = page_free_list;
f0100ff1:	8b 15 a0 e4 17 f0    	mov    0xf017e4a0,%edx
	page_free_list = pp;
f0100ff7:	a3 a0 e4 17 f0       	mov    %eax,0xf017e4a0
	pp->pp_link = tmp;
f0100ffc:	89 10                	mov    %edx,(%eax)
}
f0100ffe:	c9                   	leave  
f0100fff:	c3                   	ret    

f0101000 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101000:	55                   	push   %ebp
f0101001:	89 e5                	mov    %esp,%ebp
f0101003:	83 ec 08             	sub    $0x8,%esp
f0101006:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101009:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f010100d:	83 e8 01             	sub    $0x1,%eax
f0101010:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101014:	66 85 c0             	test   %ax,%ax
f0101017:	75 0c                	jne    f0101025 <page_decref+0x25>
		page_free(pp);
f0101019:	83 ec 0c             	sub    $0xc,%esp
f010101c:	52                   	push   %edx
f010101d:	e8 9d ff ff ff       	call   f0100fbf <page_free>
f0101022:	83 c4 10             	add    $0x10,%esp
}
f0101025:	c9                   	leave  
f0101026:	c3                   	ret    

f0101027 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101027:	55                   	push   %ebp
f0101028:	89 e5                	mov    %esp,%ebp
f010102a:	56                   	push   %esi
f010102b:	53                   	push   %ebx
f010102c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	int dirIndex = PDX(va), tabIndex = PTX(va);
f010102f:	89 de                	mov    %ebx,%esi
f0101031:	c1 ee 0c             	shr    $0xc,%esi
f0101034:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f010103a:	c1 eb 16             	shr    $0x16,%ebx
 	pde_t *pde_my = pgdir + dirIndex;
f010103d:	c1 e3 02             	shl    $0x2,%ebx
f0101040:	03 5d 08             	add    0x8(%ebp),%ebx
	if(!((*pde_my) & PTE_P)){
f0101043:	f6 03 01             	testb  $0x1,(%ebx)
f0101046:	75 2d                	jne    f0101075 <pgdir_walk+0x4e>
		//if page directory entry for virtual address va is not present
		if(create){
f0101048:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010104c:	74 59                	je     f01010a7 <pgdir_walk+0x80>
			//ALLOC_ZERO parameter clears the allocated page by default
			struct PageInfo *newpage = page_alloc(ALLOC_ZERO);
f010104e:	83 ec 0c             	sub    $0xc,%esp
f0101051:	6a 01                	push   $0x1
f0101053:	e8 f7 fe ff ff       	call   f0100f4f <page_alloc>
			if(newpage == NULL){
f0101058:	83 c4 10             	add    $0x10,%esp
f010105b:	85 c0                	test   %eax,%eax
f010105d:	74 4f                	je     f01010ae <pgdir_walk+0x87>
				return NULL;
			}
			newpage->pp_ref++;
f010105f:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101064:	2b 05 8c f1 17 f0    	sub    0xf017f18c,%eax
f010106a:	c1 f8 03             	sar    $0x3,%eax
f010106d:	c1 e0 0c             	shl    $0xc,%eax
			pgdir[dirIndex] = page2pa(newpage) | PTE_P | PTE_U | PTE_W;
f0101070:	83 c8 07             	or     $0x7,%eax
f0101073:	89 03                	mov    %eax,(%ebx)
		else{
			return NULL;
		}
	}
	
	pte_t *retadd = (pte_t*)KADDR(PTE_ADDR(*pde_my));
f0101075:	8b 03                	mov    (%ebx),%eax
f0101077:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010107c:	89 c2                	mov    %eax,%edx
f010107e:	c1 ea 0c             	shr    $0xc,%edx
f0101081:	3b 15 84 f1 17 f0    	cmp    0xf017f184,%edx
f0101087:	72 15                	jb     f010109e <pgdir_walk+0x77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101089:	50                   	push   %eax
f010108a:	68 88 53 10 f0       	push   $0xf0105388
f010108f:	68 9e 01 00 00       	push   $0x19e
f0101094:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101099:	e8 02 f0 ff ff       	call   f01000a0 <_panic>
	return (pte_t*)(retadd + tabIndex);
f010109e:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f01010a5:	eb 0c                	jmp    f01010b3 <pgdir_walk+0x8c>
			}
			newpage->pp_ref++;
			pgdir[dirIndex] = page2pa(newpage) | PTE_P | PTE_U | PTE_W;
		}
		else{
			return NULL;
f01010a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01010ac:	eb 05                	jmp    f01010b3 <pgdir_walk+0x8c>
		//if page directory entry for virtual address va is not present
		if(create){
			//ALLOC_ZERO parameter clears the allocated page by default
			struct PageInfo *newpage = page_alloc(ALLOC_ZERO);
			if(newpage == NULL){
				return NULL;
f01010ae:	b8 00 00 00 00       	mov    $0x0,%eax
	}
	
	pte_t *retadd = (pte_t*)KADDR(PTE_ADDR(*pde_my));
	return (pte_t*)(retadd + tabIndex);
	return NULL;
}
f01010b3:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01010b6:	5b                   	pop    %ebx
f01010b7:	5e                   	pop    %esi
f01010b8:	5d                   	pop    %ebp
f01010b9:	c3                   	ret    

f01010ba <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01010ba:	55                   	push   %ebp
f01010bb:	89 e5                	mov    %esp,%ebp
f01010bd:	57                   	push   %edi
f01010be:	56                   	push   %esi
f01010bf:	53                   	push   %ebx
f01010c0:	83 ec 1c             	sub    $0x1c,%esp
f01010c3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01010c6:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	int cnt;
	for(cnt = 0; cnt < size/PGSIZE; cnt++){
f01010c9:	c1 e9 0c             	shr    $0xc,%ecx
f01010cc:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01010cf:	89 c3                	mov    %eax,%ebx
f01010d1:	be 00 00 00 00       	mov    $0x0,%esi
f01010d6:	89 d7                	mov    %edx,%edi
f01010d8:	29 c7                	sub    %eax,%edi
f01010da:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010dd:	83 c8 01             	or     $0x1,%eax
f01010e0:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01010e3:	eb 3f                	jmp    f0101124 <boot_map_region+0x6a>
		pte_t* pte_entry_my = pgdir_walk(pgdir, (void*)va, 1);
f01010e5:	83 ec 04             	sub    $0x4,%esp
f01010e8:	6a 01                	push   $0x1
f01010ea:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f01010ed:	50                   	push   %eax
f01010ee:	ff 75 e0             	pushl  -0x20(%ebp)
f01010f1:	e8 31 ff ff ff       	call   f0101027 <pgdir_walk>
		if(!pte_entry_my){
f01010f6:	83 c4 10             	add    $0x10,%esp
f01010f9:	85 c0                	test   %eax,%eax
f01010fb:	75 17                	jne    f0101114 <boot_map_region+0x5a>
			panic("Get page table entry for va in pgdir failed!");
f01010fd:	83 ec 04             	sub    $0x4,%esp
f0101100:	68 c4 54 10 f0       	push   $0xf01054c4
f0101105:	68 b6 01 00 00       	push   $0x1b6
f010110a:	68 5d 5c 10 f0       	push   $0xf0105c5d
f010110f:	e8 8c ef ff ff       	call   f01000a0 <_panic>
		}
		*(pte_entry_my) = pa | perm | PTE_P;
f0101114:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101117:	09 da                	or     %ebx,%edx
f0101119:	89 10                	mov    %edx,(%eax)
		va += PGSIZE;
		pa += PGSIZE;
f010111b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	int cnt;
	for(cnt = 0; cnt < size/PGSIZE; cnt++){
f0101121:	83 c6 01             	add    $0x1,%esi
f0101124:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0101127:	75 bc                	jne    f01010e5 <boot_map_region+0x2b>
		}
		*(pte_entry_my) = pa | perm | PTE_P;
		va += PGSIZE;
		pa += PGSIZE;
	}
}
f0101129:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010112c:	5b                   	pop    %ebx
f010112d:	5e                   	pop    %esi
f010112e:	5f                   	pop    %edi
f010112f:	5d                   	pop    %ebp
f0101130:	c3                   	ret    

f0101131 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101131:	55                   	push   %ebp
f0101132:	89 e5                	mov    %esp,%ebp
f0101134:	53                   	push   %ebx
f0101135:	83 ec 08             	sub    $0x8,%esp
f0101138:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t* pte_my = pgdir_walk(pgdir, va, 0); //test if the page is present
f010113b:	6a 00                	push   $0x0
f010113d:	ff 75 0c             	pushl  0xc(%ebp)
f0101140:	ff 75 08             	pushl  0x8(%ebp)
f0101143:	e8 df fe ff ff       	call   f0101027 <pgdir_walk>
	if((!pte_my) || (!((*pte_my) & PTE_P))){
f0101148:	83 c4 10             	add    $0x10,%esp
f010114b:	85 c0                	test   %eax,%eax
f010114d:	74 37                	je     f0101186 <page_lookup+0x55>
f010114f:	f6 00 01             	testb  $0x1,(%eax)
f0101152:	74 39                	je     f010118d <page_lookup+0x5c>
		return NULL;
	}
	if(pte_store != NULL){
f0101154:	85 db                	test   %ebx,%ebx
f0101156:	74 02                	je     f010115a <page_lookup+0x29>
		*pte_store = pte_my;
f0101158:	89 03                	mov    %eax,(%ebx)
	}
	return pa2page(PTE_ADDR(*pte_my));
f010115a:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010115c:	c1 e8 0c             	shr    $0xc,%eax
f010115f:	3b 05 84 f1 17 f0    	cmp    0xf017f184,%eax
f0101165:	72 14                	jb     f010117b <page_lookup+0x4a>
		panic("pa2page called with invalid pa");
f0101167:	83 ec 04             	sub    $0x4,%esp
f010116a:	68 f4 54 10 f0       	push   $0xf01054f4
f010116f:	6a 4f                	push   $0x4f
f0101171:	68 7b 5c 10 f0       	push   $0xf0105c7b
f0101176:	e8 25 ef ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f010117b:	8b 15 8c f1 17 f0    	mov    0xf017f18c,%edx
f0101181:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0101184:	eb 0c                	jmp    f0101192 <page_lookup+0x61>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t* pte_my = pgdir_walk(pgdir, va, 0); //test if the page is present
	if((!pte_my) || (!((*pte_my) & PTE_P))){
		return NULL;
f0101186:	b8 00 00 00 00       	mov    $0x0,%eax
f010118b:	eb 05                	jmp    f0101192 <page_lookup+0x61>
f010118d:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store != NULL){
		*pte_store = pte_my;
	}
	return pa2page(PTE_ADDR(*pte_my));
	return NULL;
}
f0101192:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101195:	c9                   	leave  
f0101196:	c3                   	ret    

f0101197 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101197:	55                   	push   %ebp
f0101198:	89 e5                	mov    %esp,%ebp
f010119a:	53                   	push   %ebx
f010119b:	83 ec 18             	sub    $0x18,%esp
f010119e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
/*	pte_t *pte_my = pgdir_walk(pgdir, va, 0); //do not allocate new page entry
 	if((pte_my == NULL) || (!(*pte_my & PTE_P))){
		return ;
	}*/
	pte_t *recpte_my = NULL;
f01011a1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo* destPagePtr= page_lookup(pgdir, va, &recpte_my);
f01011a8:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01011ab:	50                   	push   %eax
f01011ac:	53                   	push   %ebx
f01011ad:	ff 75 08             	pushl  0x8(%ebp)
f01011b0:	e8 7c ff ff ff       	call   f0101131 <page_lookup>
	if(destPagePtr == NULL || (!(*recpte_my) & PTE_P)){//no physical page at that address
f01011b5:	83 c4 10             	add    $0x10,%esp
f01011b8:	85 c0                	test   %eax,%eax
f01011ba:	74 20                	je     f01011dc <page_remove+0x45>
f01011bc:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01011bf:	83 3a 00             	cmpl   $0x0,(%edx)
f01011c2:	74 18                	je     f01011dc <page_remove+0x45>
		return;
	}
	page_decref(destPagePtr);
f01011c4:	83 ec 0c             	sub    $0xc,%esp
f01011c7:	50                   	push   %eax
f01011c8:	e8 33 fe ff ff       	call   f0101000 <page_decref>
	*recpte_my = 0;
f01011cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011d0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01011d6:	0f 01 3b             	invlpg (%ebx)
f01011d9:	83 c4 10             	add    $0x10,%esp
	tlb_invalidate(pgdir, va);	
	
}
f01011dc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01011df:	c9                   	leave  
f01011e0:	c3                   	ret    

f01011e1 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01011e1:	55                   	push   %ebp
f01011e2:	89 e5                	mov    %esp,%ebp
f01011e4:	57                   	push   %edi
f01011e5:	56                   	push   %esi
f01011e6:	53                   	push   %ebx
f01011e7:	83 ec 10             	sub    $0x10,%esp
f01011ea:	8b 75 0c             	mov    0xc(%ebp),%esi
f01011ed:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t* pte_my = pgdir_walk(pgdir, va, 1);//create a page table entry on demand
f01011f0:	6a 01                	push   $0x1
f01011f2:	57                   	push   %edi
f01011f3:	ff 75 08             	pushl  0x8(%ebp)
f01011f6:	e8 2c fe ff ff       	call   f0101027 <pgdir_walk>
f01011fb:	89 c3                	mov    %eax,%ebx
	if(!pte_my){
f01011fd:	83 c4 10             	add    $0x10,%esp
f0101200:	85 c0                	test   %eax,%eax
f0101202:	74 38                	je     f010123c <page_insert+0x5b>
		return 	-E_NO_MEM;
	}
	pp->pp_ref++;
f0101204:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	if(*pte_my & PTE_P){
f0101209:	f6 00 01             	testb  $0x1,(%eax)
f010120c:	74 0f                	je     f010121d <page_insert+0x3c>
		page_remove(pgdir, va);
f010120e:	83 ec 08             	sub    $0x8,%esp
f0101211:	57                   	push   %edi
f0101212:	ff 75 08             	pushl  0x8(%ebp)
f0101215:	e8 7d ff ff ff       	call   f0101197 <page_remove>
f010121a:	83 c4 10             	add    $0x10,%esp
f010121d:	8b 55 14             	mov    0x14(%ebp),%edx
f0101220:	83 ca 01             	or     $0x1,%edx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101223:	89 f0                	mov    %esi,%eax
f0101225:	2b 05 8c f1 17 f0    	sub    0xf017f18c,%eax
f010122b:	c1 f8 03             	sar    $0x3,%eax
f010122e:	c1 e0 0c             	shl    $0xc,%eax
	}
	*pte_my = page2pa(pp) | perm | PTE_P; 
f0101231:	09 d0                	or     %edx,%eax
f0101233:	89 03                	mov    %eax,(%ebx)
	return 0;
f0101235:	b8 00 00 00 00       	mov    $0x0,%eax
f010123a:	eb 05                	jmp    f0101241 <page_insert+0x60>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
	pte_t* pte_my = pgdir_walk(pgdir, va, 1);//create a page table entry on demand
	if(!pte_my){
		return 	-E_NO_MEM;
f010123c:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	if(*pte_my & PTE_P){
		page_remove(pgdir, va);
	}
	*pte_my = page2pa(pp) | perm | PTE_P; 
	return 0;
}
f0101241:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101244:	5b                   	pop    %ebx
f0101245:	5e                   	pop    %esi
f0101246:	5f                   	pop    %edi
f0101247:	5d                   	pop    %ebp
f0101248:	c3                   	ret    

f0101249 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101249:	55                   	push   %ebp
f010124a:	89 e5                	mov    %esp,%ebp
f010124c:	57                   	push   %edi
f010124d:	56                   	push   %esi
f010124e:	53                   	push   %ebx
f010124f:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101252:	6a 15                	push   $0x15
f0101254:	e8 43 1f 00 00       	call   f010319c <mc146818_read>
f0101259:	89 c3                	mov    %eax,%ebx
f010125b:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101262:	e8 35 1f 00 00       	call   f010319c <mc146818_read>
f0101267:	c1 e0 08             	shl    $0x8,%eax
f010126a:	09 d8                	or     %ebx,%eax
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f010126c:	c1 e0 0a             	shl    $0xa,%eax
f010126f:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101275:	85 c0                	test   %eax,%eax
f0101277:	0f 48 c2             	cmovs  %edx,%eax
f010127a:	c1 f8 0c             	sar    $0xc,%eax
f010127d:	a3 a4 e4 17 f0       	mov    %eax,0xf017e4a4
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101282:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101289:	e8 0e 1f 00 00       	call   f010319c <mc146818_read>
f010128e:	89 c6                	mov    %eax,%esi
f0101290:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101297:	e8 00 1f 00 00       	call   f010319c <mc146818_read>
f010129c:	c1 e0 08             	shl    $0x8,%eax
f010129f:	89 c3                	mov    %eax,%ebx
f01012a1:	09 f3                	or     %esi,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01012a3:	c1 e3 0a             	shl    $0xa,%ebx
f01012a6:	8d 93 ff 0f 00 00    	lea    0xfff(%ebx),%edx
f01012ac:	83 c4 0c             	add    $0xc,%esp
f01012af:	85 db                	test   %ebx,%ebx
f01012b1:	0f 48 da             	cmovs  %edx,%ebx
f01012b4:	c1 fb 0c             	sar    $0xc,%ebx
	cprintf("npages_basemem: %d\t npages_extmem: %d\n", npages_basemem, npages_extmem);
f01012b7:	53                   	push   %ebx
f01012b8:	ff 35 a4 e4 17 f0    	pushl  0xf017e4a4
f01012be:	68 14 55 10 f0       	push   $0xf0105514
f01012c3:	e8 35 1f 00 00       	call   f01031fd <cprintf>

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01012c8:	83 c4 10             	add    $0x10,%esp
f01012cb:	85 db                	test   %ebx,%ebx
f01012cd:	74 0d                	je     f01012dc <mem_init+0x93>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01012cf:	8d 83 00 01 00 00    	lea    0x100(%ebx),%eax
f01012d5:	a3 84 f1 17 f0       	mov    %eax,0xf017f184
f01012da:	eb 0a                	jmp    f01012e6 <mem_init+0x9d>
	else
		npages = npages_basemem;
f01012dc:	a1 a4 e4 17 f0       	mov    0xf017e4a4,%eax
f01012e1:	a3 84 f1 17 f0       	mov    %eax,0xf017f184

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f01012e6:	c1 e3 0c             	shl    $0xc,%ebx
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012e9:	c1 eb 0a             	shr    $0xa,%ebx
f01012ec:	53                   	push   %ebx
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f01012ed:	a1 a4 e4 17 f0       	mov    0xf017e4a4,%eax
f01012f2:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012f5:	c1 e8 0a             	shr    $0xa,%eax
f01012f8:	50                   	push   %eax
		npages * PGSIZE / 1024,
f01012f9:	a1 84 f1 17 f0       	mov    0xf017f184,%eax
f01012fe:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101301:	c1 e8 0a             	shr    $0xa,%eax
f0101304:	50                   	push   %eax
f0101305:	68 3c 55 10 f0       	push   $0xf010553c
f010130a:	e8 ee 1e 00 00       	call   f01031fd <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010130f:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101314:	e8 64 f8 ff ff       	call   f0100b7d <boot_alloc>
f0101319:	a3 88 f1 17 f0       	mov    %eax,0xf017f188
	memset(kern_pgdir, 0, PGSIZE);
f010131e:	83 c4 0c             	add    $0xc,%esp
f0101321:	68 00 10 00 00       	push   $0x1000
f0101326:	6a 00                	push   $0x0
f0101328:	50                   	push   %eax
f0101329:	e8 d5 33 00 00       	call   f0104703 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010132e:	a1 88 f1 17 f0       	mov    0xf017f188,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101333:	83 c4 10             	add    $0x10,%esp
f0101336:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010133b:	77 15                	ja     f0101352 <mem_init+0x109>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010133d:	50                   	push   %eax
f010133e:	68 ac 53 10 f0       	push   $0xf01053ac
f0101343:	68 9a 00 00 00       	push   $0x9a
f0101348:	68 5d 5c 10 f0       	push   $0xf0105c5d
f010134d:	e8 4e ed ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101352:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101358:	83 ca 05             	or     $0x5,%edx
f010135b:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	cprintf("UVPT is %x\n" ,UVPT);
f0101361:	83 ec 08             	sub    $0x8,%esp
f0101364:	68 00 00 40 ef       	push   $0xef400000
f0101369:	68 25 5d 10 f0       	push   $0xf0105d25
f010136e:	e8 8a 1e 00 00       	call   f01031fd <cprintf>
	cprintf("UPAGES is %x\n", UPAGES);
f0101373:	83 c4 08             	add    $0x8,%esp
f0101376:	68 00 00 00 ef       	push   $0xef000000
f010137b:	68 31 5d 10 f0       	push   $0xf0105d31
f0101380:	e8 78 1e 00 00       	call   f01031fd <cprintf>
	cprintf("Physical address of kern_pgdir: %x\n", PADDR(kern_pgdir));
f0101385:	a1 88 f1 17 f0       	mov    0xf017f188,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010138a:	83 c4 10             	add    $0x10,%esp
f010138d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101392:	77 15                	ja     f01013a9 <mem_init+0x160>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101394:	50                   	push   %eax
f0101395:	68 ac 53 10 f0       	push   $0xf01053ac
f010139a:	68 9d 00 00 00       	push   $0x9d
f010139f:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01013a4:	e8 f7 ec ff ff       	call   f01000a0 <_panic>
f01013a9:	83 ec 08             	sub    $0x8,%esp
	return (physaddr_t)kva - KERNBASE;
f01013ac:	05 00 00 00 10       	add    $0x10000000,%eax
f01013b1:	50                   	push   %eax
f01013b2:	68 78 55 10 f0       	push   $0xf0105578
f01013b7:	e8 41 1e 00 00       	call   f01031fd <cprintf>
	cprintf("Virtual address of kern_pgdir: %x\n", kern_pgdir);
f01013bc:	83 c4 08             	add    $0x8,%esp
f01013bf:	ff 35 88 f1 17 f0    	pushl  0xf017f188
f01013c5:	68 9c 55 10 f0       	push   $0xf010559c
f01013ca:	e8 2e 1e 00 00       	call   f01031fd <cprintf>
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:

	pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
f01013cf:	a1 84 f1 17 f0       	mov    0xf017f184,%eax
f01013d4:	c1 e0 03             	shl    $0x3,%eax
f01013d7:	e8 a1 f7 ff ff       	call   f0100b7d <boot_alloc>
f01013dc:	a3 8c f1 17 f0       	mov    %eax,0xf017f18c
	memset(pages, 0, npages*sizeof(struct PageInfo));
f01013e1:	83 c4 0c             	add    $0xc,%esp
f01013e4:	8b 3d 84 f1 17 f0    	mov    0xf017f184,%edi
f01013ea:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f01013f1:	52                   	push   %edx
f01013f2:	6a 00                	push   $0x0
f01013f4:	50                   	push   %eax
f01013f5:	e8 09 33 00 00       	call   f0104703 <memset>
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env*)boot_alloc(NENV * sizeof(struct Env));	
f01013fa:	b8 00 80 01 00       	mov    $0x18000,%eax
f01013ff:	e8 79 f7 ff ff       	call   f0100b7d <boot_alloc>
f0101404:	a3 ac e4 17 f0       	mov    %eax,0xf017e4ac
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101409:	e8 b9 fa ff ff       	call   f0100ec7 <page_init>

	check_page_free_list(1);
f010140e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101413:	e8 f3 f7 ff ff       	call   f0100c0b <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101418:	83 c4 10             	add    $0x10,%esp
f010141b:	83 3d 8c f1 17 f0 00 	cmpl   $0x0,0xf017f18c
f0101422:	75 17                	jne    f010143b <mem_init+0x1f2>
		panic("'pages' is a null pointer!");
f0101424:	83 ec 04             	sub    $0x4,%esp
f0101427:	68 3f 5d 10 f0       	push   $0xf0105d3f
f010142c:	68 b7 02 00 00       	push   $0x2b7
f0101431:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101436:	e8 65 ec ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010143b:	a1 a0 e4 17 f0       	mov    0xf017e4a0,%eax
f0101440:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101445:	eb 05                	jmp    f010144c <mem_init+0x203>
		++nfree;
f0101447:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010144a:	8b 00                	mov    (%eax),%eax
f010144c:	85 c0                	test   %eax,%eax
f010144e:	75 f7                	jne    f0101447 <mem_init+0x1fe>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101450:	83 ec 0c             	sub    $0xc,%esp
f0101453:	6a 00                	push   $0x0
f0101455:	e8 f5 fa ff ff       	call   f0100f4f <page_alloc>
f010145a:	89 c7                	mov    %eax,%edi
f010145c:	83 c4 10             	add    $0x10,%esp
f010145f:	85 c0                	test   %eax,%eax
f0101461:	75 19                	jne    f010147c <mem_init+0x233>
f0101463:	68 5a 5d 10 f0       	push   $0xf0105d5a
f0101468:	68 95 5c 10 f0       	push   $0xf0105c95
f010146d:	68 bf 02 00 00       	push   $0x2bf
f0101472:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101477:	e8 24 ec ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010147c:	83 ec 0c             	sub    $0xc,%esp
f010147f:	6a 00                	push   $0x0
f0101481:	e8 c9 fa ff ff       	call   f0100f4f <page_alloc>
f0101486:	89 c6                	mov    %eax,%esi
f0101488:	83 c4 10             	add    $0x10,%esp
f010148b:	85 c0                	test   %eax,%eax
f010148d:	75 19                	jne    f01014a8 <mem_init+0x25f>
f010148f:	68 70 5d 10 f0       	push   $0xf0105d70
f0101494:	68 95 5c 10 f0       	push   $0xf0105c95
f0101499:	68 c0 02 00 00       	push   $0x2c0
f010149e:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01014a3:	e8 f8 eb ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01014a8:	83 ec 0c             	sub    $0xc,%esp
f01014ab:	6a 00                	push   $0x0
f01014ad:	e8 9d fa ff ff       	call   f0100f4f <page_alloc>
f01014b2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014b5:	83 c4 10             	add    $0x10,%esp
f01014b8:	85 c0                	test   %eax,%eax
f01014ba:	75 19                	jne    f01014d5 <mem_init+0x28c>
f01014bc:	68 86 5d 10 f0       	push   $0xf0105d86
f01014c1:	68 95 5c 10 f0       	push   $0xf0105c95
f01014c6:	68 c1 02 00 00       	push   $0x2c1
f01014cb:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01014d0:	e8 cb eb ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01014d5:	39 f7                	cmp    %esi,%edi
f01014d7:	75 19                	jne    f01014f2 <mem_init+0x2a9>
f01014d9:	68 9c 5d 10 f0       	push   $0xf0105d9c
f01014de:	68 95 5c 10 f0       	push   $0xf0105c95
f01014e3:	68 c4 02 00 00       	push   $0x2c4
f01014e8:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01014ed:	e8 ae eb ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014f2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014f5:	39 c7                	cmp    %eax,%edi
f01014f7:	74 04                	je     f01014fd <mem_init+0x2b4>
f01014f9:	39 c6                	cmp    %eax,%esi
f01014fb:	75 19                	jne    f0101516 <mem_init+0x2cd>
f01014fd:	68 c0 55 10 f0       	push   $0xf01055c0
f0101502:	68 95 5c 10 f0       	push   $0xf0105c95
f0101507:	68 c5 02 00 00       	push   $0x2c5
f010150c:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101511:	e8 8a eb ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101516:	8b 0d 8c f1 17 f0    	mov    0xf017f18c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010151c:	8b 15 84 f1 17 f0    	mov    0xf017f184,%edx
f0101522:	c1 e2 0c             	shl    $0xc,%edx
f0101525:	89 f8                	mov    %edi,%eax
f0101527:	29 c8                	sub    %ecx,%eax
f0101529:	c1 f8 03             	sar    $0x3,%eax
f010152c:	c1 e0 0c             	shl    $0xc,%eax
f010152f:	39 d0                	cmp    %edx,%eax
f0101531:	72 19                	jb     f010154c <mem_init+0x303>
f0101533:	68 ae 5d 10 f0       	push   $0xf0105dae
f0101538:	68 95 5c 10 f0       	push   $0xf0105c95
f010153d:	68 c6 02 00 00       	push   $0x2c6
f0101542:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101547:	e8 54 eb ff ff       	call   f01000a0 <_panic>
f010154c:	89 f0                	mov    %esi,%eax
f010154e:	29 c8                	sub    %ecx,%eax
f0101550:	c1 f8 03             	sar    $0x3,%eax
f0101553:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f0101556:	39 c2                	cmp    %eax,%edx
f0101558:	77 19                	ja     f0101573 <mem_init+0x32a>
f010155a:	68 cb 5d 10 f0       	push   $0xf0105dcb
f010155f:	68 95 5c 10 f0       	push   $0xf0105c95
f0101564:	68 c7 02 00 00       	push   $0x2c7
f0101569:	68 5d 5c 10 f0       	push   $0xf0105c5d
f010156e:	e8 2d eb ff ff       	call   f01000a0 <_panic>
f0101573:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101576:	29 c8                	sub    %ecx,%eax
f0101578:	c1 f8 03             	sar    $0x3,%eax
f010157b:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f010157e:	39 c2                	cmp    %eax,%edx
f0101580:	77 19                	ja     f010159b <mem_init+0x352>
f0101582:	68 e8 5d 10 f0       	push   $0xf0105de8
f0101587:	68 95 5c 10 f0       	push   $0xf0105c95
f010158c:	68 c8 02 00 00       	push   $0x2c8
f0101591:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101596:	e8 05 eb ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010159b:	a1 a0 e4 17 f0       	mov    0xf017e4a0,%eax
f01015a0:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01015a3:	c7 05 a0 e4 17 f0 00 	movl   $0x0,0xf017e4a0
f01015aa:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01015ad:	83 ec 0c             	sub    $0xc,%esp
f01015b0:	6a 00                	push   $0x0
f01015b2:	e8 98 f9 ff ff       	call   f0100f4f <page_alloc>
f01015b7:	83 c4 10             	add    $0x10,%esp
f01015ba:	85 c0                	test   %eax,%eax
f01015bc:	74 19                	je     f01015d7 <mem_init+0x38e>
f01015be:	68 05 5e 10 f0       	push   $0xf0105e05
f01015c3:	68 95 5c 10 f0       	push   $0xf0105c95
f01015c8:	68 cf 02 00 00       	push   $0x2cf
f01015cd:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01015d2:	e8 c9 ea ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01015d7:	83 ec 0c             	sub    $0xc,%esp
f01015da:	57                   	push   %edi
f01015db:	e8 df f9 ff ff       	call   f0100fbf <page_free>
	page_free(pp1);
f01015e0:	89 34 24             	mov    %esi,(%esp)
f01015e3:	e8 d7 f9 ff ff       	call   f0100fbf <page_free>
	page_free(pp2);
f01015e8:	83 c4 04             	add    $0x4,%esp
f01015eb:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015ee:	e8 cc f9 ff ff       	call   f0100fbf <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015f3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015fa:	e8 50 f9 ff ff       	call   f0100f4f <page_alloc>
f01015ff:	89 c6                	mov    %eax,%esi
f0101601:	83 c4 10             	add    $0x10,%esp
f0101604:	85 c0                	test   %eax,%eax
f0101606:	75 19                	jne    f0101621 <mem_init+0x3d8>
f0101608:	68 5a 5d 10 f0       	push   $0xf0105d5a
f010160d:	68 95 5c 10 f0       	push   $0xf0105c95
f0101612:	68 d6 02 00 00       	push   $0x2d6
f0101617:	68 5d 5c 10 f0       	push   $0xf0105c5d
f010161c:	e8 7f ea ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101621:	83 ec 0c             	sub    $0xc,%esp
f0101624:	6a 00                	push   $0x0
f0101626:	e8 24 f9 ff ff       	call   f0100f4f <page_alloc>
f010162b:	89 c7                	mov    %eax,%edi
f010162d:	83 c4 10             	add    $0x10,%esp
f0101630:	85 c0                	test   %eax,%eax
f0101632:	75 19                	jne    f010164d <mem_init+0x404>
f0101634:	68 70 5d 10 f0       	push   $0xf0105d70
f0101639:	68 95 5c 10 f0       	push   $0xf0105c95
f010163e:	68 d7 02 00 00       	push   $0x2d7
f0101643:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101648:	e8 53 ea ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010164d:	83 ec 0c             	sub    $0xc,%esp
f0101650:	6a 00                	push   $0x0
f0101652:	e8 f8 f8 ff ff       	call   f0100f4f <page_alloc>
f0101657:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010165a:	83 c4 10             	add    $0x10,%esp
f010165d:	85 c0                	test   %eax,%eax
f010165f:	75 19                	jne    f010167a <mem_init+0x431>
f0101661:	68 86 5d 10 f0       	push   $0xf0105d86
f0101666:	68 95 5c 10 f0       	push   $0xf0105c95
f010166b:	68 d8 02 00 00       	push   $0x2d8
f0101670:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101675:	e8 26 ea ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010167a:	39 fe                	cmp    %edi,%esi
f010167c:	75 19                	jne    f0101697 <mem_init+0x44e>
f010167e:	68 9c 5d 10 f0       	push   $0xf0105d9c
f0101683:	68 95 5c 10 f0       	push   $0xf0105c95
f0101688:	68 da 02 00 00       	push   $0x2da
f010168d:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101692:	e8 09 ea ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101697:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010169a:	39 c6                	cmp    %eax,%esi
f010169c:	74 04                	je     f01016a2 <mem_init+0x459>
f010169e:	39 c7                	cmp    %eax,%edi
f01016a0:	75 19                	jne    f01016bb <mem_init+0x472>
f01016a2:	68 c0 55 10 f0       	push   $0xf01055c0
f01016a7:	68 95 5c 10 f0       	push   $0xf0105c95
f01016ac:	68 db 02 00 00       	push   $0x2db
f01016b1:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01016b6:	e8 e5 e9 ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f01016bb:	83 ec 0c             	sub    $0xc,%esp
f01016be:	6a 00                	push   $0x0
f01016c0:	e8 8a f8 ff ff       	call   f0100f4f <page_alloc>
f01016c5:	83 c4 10             	add    $0x10,%esp
f01016c8:	85 c0                	test   %eax,%eax
f01016ca:	74 19                	je     f01016e5 <mem_init+0x49c>
f01016cc:	68 05 5e 10 f0       	push   $0xf0105e05
f01016d1:	68 95 5c 10 f0       	push   $0xf0105c95
f01016d6:	68 dc 02 00 00       	push   $0x2dc
f01016db:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01016e0:	e8 bb e9 ff ff       	call   f01000a0 <_panic>
f01016e5:	89 f0                	mov    %esi,%eax
f01016e7:	2b 05 8c f1 17 f0    	sub    0xf017f18c,%eax
f01016ed:	c1 f8 03             	sar    $0x3,%eax
f01016f0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01016f3:	89 c2                	mov    %eax,%edx
f01016f5:	c1 ea 0c             	shr    $0xc,%edx
f01016f8:	3b 15 84 f1 17 f0    	cmp    0xf017f184,%edx
f01016fe:	72 12                	jb     f0101712 <mem_init+0x4c9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101700:	50                   	push   %eax
f0101701:	68 88 53 10 f0       	push   $0xf0105388
f0101706:	6a 56                	push   $0x56
f0101708:	68 7b 5c 10 f0       	push   $0xf0105c7b
f010170d:	e8 8e e9 ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101712:	83 ec 04             	sub    $0x4,%esp
f0101715:	68 00 10 00 00       	push   $0x1000
f010171a:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f010171c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101721:	50                   	push   %eax
f0101722:	e8 dc 2f 00 00       	call   f0104703 <memset>
	page_free(pp0);
f0101727:	89 34 24             	mov    %esi,(%esp)
f010172a:	e8 90 f8 ff ff       	call   f0100fbf <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010172f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101736:	e8 14 f8 ff ff       	call   f0100f4f <page_alloc>
f010173b:	83 c4 10             	add    $0x10,%esp
f010173e:	85 c0                	test   %eax,%eax
f0101740:	75 19                	jne    f010175b <mem_init+0x512>
f0101742:	68 14 5e 10 f0       	push   $0xf0105e14
f0101747:	68 95 5c 10 f0       	push   $0xf0105c95
f010174c:	68 e1 02 00 00       	push   $0x2e1
f0101751:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101756:	e8 45 e9 ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f010175b:	39 c6                	cmp    %eax,%esi
f010175d:	74 19                	je     f0101778 <mem_init+0x52f>
f010175f:	68 32 5e 10 f0       	push   $0xf0105e32
f0101764:	68 95 5c 10 f0       	push   $0xf0105c95
f0101769:	68 e2 02 00 00       	push   $0x2e2
f010176e:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101773:	e8 28 e9 ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101778:	89 f0                	mov    %esi,%eax
f010177a:	2b 05 8c f1 17 f0    	sub    0xf017f18c,%eax
f0101780:	c1 f8 03             	sar    $0x3,%eax
f0101783:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101786:	89 c2                	mov    %eax,%edx
f0101788:	c1 ea 0c             	shr    $0xc,%edx
f010178b:	3b 15 84 f1 17 f0    	cmp    0xf017f184,%edx
f0101791:	72 12                	jb     f01017a5 <mem_init+0x55c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101793:	50                   	push   %eax
f0101794:	68 88 53 10 f0       	push   $0xf0105388
f0101799:	6a 56                	push   $0x56
f010179b:	68 7b 5c 10 f0       	push   $0xf0105c7b
f01017a0:	e8 fb e8 ff ff       	call   f01000a0 <_panic>
f01017a5:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01017ab:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01017b1:	80 38 00             	cmpb   $0x0,(%eax)
f01017b4:	74 19                	je     f01017cf <mem_init+0x586>
f01017b6:	68 42 5e 10 f0       	push   $0xf0105e42
f01017bb:	68 95 5c 10 f0       	push   $0xf0105c95
f01017c0:	68 e5 02 00 00       	push   $0x2e5
f01017c5:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01017ca:	e8 d1 e8 ff ff       	call   f01000a0 <_panic>
f01017cf:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01017d2:	39 d0                	cmp    %edx,%eax
f01017d4:	75 db                	jne    f01017b1 <mem_init+0x568>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01017d6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01017d9:	a3 a0 e4 17 f0       	mov    %eax,0xf017e4a0

	// free the pages we took
	page_free(pp0);
f01017de:	83 ec 0c             	sub    $0xc,%esp
f01017e1:	56                   	push   %esi
f01017e2:	e8 d8 f7 ff ff       	call   f0100fbf <page_free>
	page_free(pp1);
f01017e7:	89 3c 24             	mov    %edi,(%esp)
f01017ea:	e8 d0 f7 ff ff       	call   f0100fbf <page_free>
	page_free(pp2);
f01017ef:	83 c4 04             	add    $0x4,%esp
f01017f2:	ff 75 d4             	pushl  -0x2c(%ebp)
f01017f5:	e8 c5 f7 ff ff       	call   f0100fbf <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017fa:	a1 a0 e4 17 f0       	mov    0xf017e4a0,%eax
f01017ff:	83 c4 10             	add    $0x10,%esp
f0101802:	eb 05                	jmp    f0101809 <mem_init+0x5c0>
		--nfree;
f0101804:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101807:	8b 00                	mov    (%eax),%eax
f0101809:	85 c0                	test   %eax,%eax
f010180b:	75 f7                	jne    f0101804 <mem_init+0x5bb>
		--nfree;
	assert(nfree == 0);
f010180d:	85 db                	test   %ebx,%ebx
f010180f:	74 19                	je     f010182a <mem_init+0x5e1>
f0101811:	68 4c 5e 10 f0       	push   $0xf0105e4c
f0101816:	68 95 5c 10 f0       	push   $0xf0105c95
f010181b:	68 f2 02 00 00       	push   $0x2f2
f0101820:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101825:	e8 76 e8 ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010182a:	83 ec 0c             	sub    $0xc,%esp
f010182d:	68 e0 55 10 f0       	push   $0xf01055e0
f0101832:	e8 c6 19 00 00       	call   f01031fd <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101837:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010183e:	e8 0c f7 ff ff       	call   f0100f4f <page_alloc>
f0101843:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101846:	83 c4 10             	add    $0x10,%esp
f0101849:	85 c0                	test   %eax,%eax
f010184b:	75 19                	jne    f0101866 <mem_init+0x61d>
f010184d:	68 5a 5d 10 f0       	push   $0xf0105d5a
f0101852:	68 95 5c 10 f0       	push   $0xf0105c95
f0101857:	68 53 03 00 00       	push   $0x353
f010185c:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101861:	e8 3a e8 ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101866:	83 ec 0c             	sub    $0xc,%esp
f0101869:	6a 00                	push   $0x0
f010186b:	e8 df f6 ff ff       	call   f0100f4f <page_alloc>
f0101870:	89 c3                	mov    %eax,%ebx
f0101872:	83 c4 10             	add    $0x10,%esp
f0101875:	85 c0                	test   %eax,%eax
f0101877:	75 19                	jne    f0101892 <mem_init+0x649>
f0101879:	68 70 5d 10 f0       	push   $0xf0105d70
f010187e:	68 95 5c 10 f0       	push   $0xf0105c95
f0101883:	68 54 03 00 00       	push   $0x354
f0101888:	68 5d 5c 10 f0       	push   $0xf0105c5d
f010188d:	e8 0e e8 ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101892:	83 ec 0c             	sub    $0xc,%esp
f0101895:	6a 00                	push   $0x0
f0101897:	e8 b3 f6 ff ff       	call   f0100f4f <page_alloc>
f010189c:	89 c6                	mov    %eax,%esi
f010189e:	83 c4 10             	add    $0x10,%esp
f01018a1:	85 c0                	test   %eax,%eax
f01018a3:	75 19                	jne    f01018be <mem_init+0x675>
f01018a5:	68 86 5d 10 f0       	push   $0xf0105d86
f01018aa:	68 95 5c 10 f0       	push   $0xf0105c95
f01018af:	68 55 03 00 00       	push   $0x355
f01018b4:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01018b9:	e8 e2 e7 ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01018be:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01018c1:	75 19                	jne    f01018dc <mem_init+0x693>
f01018c3:	68 9c 5d 10 f0       	push   $0xf0105d9c
f01018c8:	68 95 5c 10 f0       	push   $0xf0105c95
f01018cd:	68 58 03 00 00       	push   $0x358
f01018d2:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01018d7:	e8 c4 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018dc:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01018df:	74 04                	je     f01018e5 <mem_init+0x69c>
f01018e1:	39 c3                	cmp    %eax,%ebx
f01018e3:	75 19                	jne    f01018fe <mem_init+0x6b5>
f01018e5:	68 c0 55 10 f0       	push   $0xf01055c0
f01018ea:	68 95 5c 10 f0       	push   $0xf0105c95
f01018ef:	68 59 03 00 00       	push   $0x359
f01018f4:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01018f9:	e8 a2 e7 ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01018fe:	a1 a0 e4 17 f0       	mov    0xf017e4a0,%eax
f0101903:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101906:	c7 05 a0 e4 17 f0 00 	movl   $0x0,0xf017e4a0
f010190d:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101910:	83 ec 0c             	sub    $0xc,%esp
f0101913:	6a 00                	push   $0x0
f0101915:	e8 35 f6 ff ff       	call   f0100f4f <page_alloc>
f010191a:	83 c4 10             	add    $0x10,%esp
f010191d:	85 c0                	test   %eax,%eax
f010191f:	74 19                	je     f010193a <mem_init+0x6f1>
f0101921:	68 05 5e 10 f0       	push   $0xf0105e05
f0101926:	68 95 5c 10 f0       	push   $0xf0105c95
f010192b:	68 60 03 00 00       	push   $0x360
f0101930:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101935:	e8 66 e7 ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010193a:	83 ec 04             	sub    $0x4,%esp
f010193d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101940:	50                   	push   %eax
f0101941:	6a 00                	push   $0x0
f0101943:	ff 35 88 f1 17 f0    	pushl  0xf017f188
f0101949:	e8 e3 f7 ff ff       	call   f0101131 <page_lookup>
f010194e:	83 c4 10             	add    $0x10,%esp
f0101951:	85 c0                	test   %eax,%eax
f0101953:	74 19                	je     f010196e <mem_init+0x725>
f0101955:	68 00 56 10 f0       	push   $0xf0105600
f010195a:	68 95 5c 10 f0       	push   $0xf0105c95
f010195f:	68 63 03 00 00       	push   $0x363
f0101964:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101969:	e8 32 e7 ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010196e:	6a 02                	push   $0x2
f0101970:	6a 00                	push   $0x0
f0101972:	53                   	push   %ebx
f0101973:	ff 35 88 f1 17 f0    	pushl  0xf017f188
f0101979:	e8 63 f8 ff ff       	call   f01011e1 <page_insert>
f010197e:	83 c4 10             	add    $0x10,%esp
f0101981:	85 c0                	test   %eax,%eax
f0101983:	78 19                	js     f010199e <mem_init+0x755>
f0101985:	68 38 56 10 f0       	push   $0xf0105638
f010198a:	68 95 5c 10 f0       	push   $0xf0105c95
f010198f:	68 66 03 00 00       	push   $0x366
f0101994:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101999:	e8 02 e7 ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f010199e:	83 ec 0c             	sub    $0xc,%esp
f01019a1:	ff 75 d4             	pushl  -0x2c(%ebp)
f01019a4:	e8 16 f6 ff ff       	call   f0100fbf <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01019a9:	6a 02                	push   $0x2
f01019ab:	6a 00                	push   $0x0
f01019ad:	53                   	push   %ebx
f01019ae:	ff 35 88 f1 17 f0    	pushl  0xf017f188
f01019b4:	e8 28 f8 ff ff       	call   f01011e1 <page_insert>
f01019b9:	83 c4 20             	add    $0x20,%esp
f01019bc:	85 c0                	test   %eax,%eax
f01019be:	74 19                	je     f01019d9 <mem_init+0x790>
f01019c0:	68 68 56 10 f0       	push   $0xf0105668
f01019c5:	68 95 5c 10 f0       	push   $0xf0105c95
f01019ca:	68 6a 03 00 00       	push   $0x36a
f01019cf:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01019d4:	e8 c7 e6 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01019d9:	8b 3d 88 f1 17 f0    	mov    0xf017f188,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01019df:	a1 8c f1 17 f0       	mov    0xf017f18c,%eax
f01019e4:	89 c1                	mov    %eax,%ecx
f01019e6:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01019e9:	8b 17                	mov    (%edi),%edx
f01019eb:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01019f1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019f4:	29 c8                	sub    %ecx,%eax
f01019f6:	c1 f8 03             	sar    $0x3,%eax
f01019f9:	c1 e0 0c             	shl    $0xc,%eax
f01019fc:	39 c2                	cmp    %eax,%edx
f01019fe:	74 19                	je     f0101a19 <mem_init+0x7d0>
f0101a00:	68 98 56 10 f0       	push   $0xf0105698
f0101a05:	68 95 5c 10 f0       	push   $0xf0105c95
f0101a0a:	68 6b 03 00 00       	push   $0x36b
f0101a0f:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101a14:	e8 87 e6 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a19:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a1e:	89 f8                	mov    %edi,%eax
f0101a20:	e8 f4 f0 ff ff       	call   f0100b19 <check_va2pa>
f0101a25:	89 da                	mov    %ebx,%edx
f0101a27:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101a2a:	c1 fa 03             	sar    $0x3,%edx
f0101a2d:	c1 e2 0c             	shl    $0xc,%edx
f0101a30:	39 d0                	cmp    %edx,%eax
f0101a32:	74 19                	je     f0101a4d <mem_init+0x804>
f0101a34:	68 c0 56 10 f0       	push   $0xf01056c0
f0101a39:	68 95 5c 10 f0       	push   $0xf0105c95
f0101a3e:	68 6c 03 00 00       	push   $0x36c
f0101a43:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101a48:	e8 53 e6 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101a4d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101a52:	74 19                	je     f0101a6d <mem_init+0x824>
f0101a54:	68 57 5e 10 f0       	push   $0xf0105e57
f0101a59:	68 95 5c 10 f0       	push   $0xf0105c95
f0101a5e:	68 6d 03 00 00       	push   $0x36d
f0101a63:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101a68:	e8 33 e6 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f0101a6d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a70:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a75:	74 19                	je     f0101a90 <mem_init+0x847>
f0101a77:	68 68 5e 10 f0       	push   $0xf0105e68
f0101a7c:	68 95 5c 10 f0       	push   $0xf0105c95
f0101a81:	68 6e 03 00 00       	push   $0x36e
f0101a86:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101a8b:	e8 10 e6 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a90:	6a 02                	push   $0x2
f0101a92:	68 00 10 00 00       	push   $0x1000
f0101a97:	56                   	push   %esi
f0101a98:	57                   	push   %edi
f0101a99:	e8 43 f7 ff ff       	call   f01011e1 <page_insert>
f0101a9e:	83 c4 10             	add    $0x10,%esp
f0101aa1:	85 c0                	test   %eax,%eax
f0101aa3:	74 19                	je     f0101abe <mem_init+0x875>
f0101aa5:	68 f0 56 10 f0       	push   $0xf01056f0
f0101aaa:	68 95 5c 10 f0       	push   $0xf0105c95
f0101aaf:	68 71 03 00 00       	push   $0x371
f0101ab4:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101ab9:	e8 e2 e5 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101abe:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ac3:	a1 88 f1 17 f0       	mov    0xf017f188,%eax
f0101ac8:	e8 4c f0 ff ff       	call   f0100b19 <check_va2pa>
f0101acd:	89 f2                	mov    %esi,%edx
f0101acf:	2b 15 8c f1 17 f0    	sub    0xf017f18c,%edx
f0101ad5:	c1 fa 03             	sar    $0x3,%edx
f0101ad8:	c1 e2 0c             	shl    $0xc,%edx
f0101adb:	39 d0                	cmp    %edx,%eax
f0101add:	74 19                	je     f0101af8 <mem_init+0x8af>
f0101adf:	68 2c 57 10 f0       	push   $0xf010572c
f0101ae4:	68 95 5c 10 f0       	push   $0xf0105c95
f0101ae9:	68 72 03 00 00       	push   $0x372
f0101aee:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101af3:	e8 a8 e5 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101af8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101afd:	74 19                	je     f0101b18 <mem_init+0x8cf>
f0101aff:	68 79 5e 10 f0       	push   $0xf0105e79
f0101b04:	68 95 5c 10 f0       	push   $0xf0105c95
f0101b09:	68 73 03 00 00       	push   $0x373
f0101b0e:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101b13:	e8 88 e5 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101b18:	83 ec 0c             	sub    $0xc,%esp
f0101b1b:	6a 00                	push   $0x0
f0101b1d:	e8 2d f4 ff ff       	call   f0100f4f <page_alloc>
f0101b22:	83 c4 10             	add    $0x10,%esp
f0101b25:	85 c0                	test   %eax,%eax
f0101b27:	74 19                	je     f0101b42 <mem_init+0x8f9>
f0101b29:	68 05 5e 10 f0       	push   $0xf0105e05
f0101b2e:	68 95 5c 10 f0       	push   $0xf0105c95
f0101b33:	68 76 03 00 00       	push   $0x376
f0101b38:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101b3d:	e8 5e e5 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b42:	6a 02                	push   $0x2
f0101b44:	68 00 10 00 00       	push   $0x1000
f0101b49:	56                   	push   %esi
f0101b4a:	ff 35 88 f1 17 f0    	pushl  0xf017f188
f0101b50:	e8 8c f6 ff ff       	call   f01011e1 <page_insert>
f0101b55:	83 c4 10             	add    $0x10,%esp
f0101b58:	85 c0                	test   %eax,%eax
f0101b5a:	74 19                	je     f0101b75 <mem_init+0x92c>
f0101b5c:	68 f0 56 10 f0       	push   $0xf01056f0
f0101b61:	68 95 5c 10 f0       	push   $0xf0105c95
f0101b66:	68 79 03 00 00       	push   $0x379
f0101b6b:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101b70:	e8 2b e5 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b75:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b7a:	a1 88 f1 17 f0       	mov    0xf017f188,%eax
f0101b7f:	e8 95 ef ff ff       	call   f0100b19 <check_va2pa>
f0101b84:	89 f2                	mov    %esi,%edx
f0101b86:	2b 15 8c f1 17 f0    	sub    0xf017f18c,%edx
f0101b8c:	c1 fa 03             	sar    $0x3,%edx
f0101b8f:	c1 e2 0c             	shl    $0xc,%edx
f0101b92:	39 d0                	cmp    %edx,%eax
f0101b94:	74 19                	je     f0101baf <mem_init+0x966>
f0101b96:	68 2c 57 10 f0       	push   $0xf010572c
f0101b9b:	68 95 5c 10 f0       	push   $0xf0105c95
f0101ba0:	68 7a 03 00 00       	push   $0x37a
f0101ba5:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101baa:	e8 f1 e4 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101baf:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101bb4:	74 19                	je     f0101bcf <mem_init+0x986>
f0101bb6:	68 79 5e 10 f0       	push   $0xf0105e79
f0101bbb:	68 95 5c 10 f0       	push   $0xf0105c95
f0101bc0:	68 7b 03 00 00       	push   $0x37b
f0101bc5:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101bca:	e8 d1 e4 ff ff       	call   f01000a0 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101bcf:	83 ec 0c             	sub    $0xc,%esp
f0101bd2:	6a 00                	push   $0x0
f0101bd4:	e8 76 f3 ff ff       	call   f0100f4f <page_alloc>
f0101bd9:	83 c4 10             	add    $0x10,%esp
f0101bdc:	85 c0                	test   %eax,%eax
f0101bde:	74 19                	je     f0101bf9 <mem_init+0x9b0>
f0101be0:	68 05 5e 10 f0       	push   $0xf0105e05
f0101be5:	68 95 5c 10 f0       	push   $0xf0105c95
f0101bea:	68 7f 03 00 00       	push   $0x37f
f0101bef:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101bf4:	e8 a7 e4 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101bf9:	8b 15 88 f1 17 f0    	mov    0xf017f188,%edx
f0101bff:	8b 02                	mov    (%edx),%eax
f0101c01:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101c06:	89 c1                	mov    %eax,%ecx
f0101c08:	c1 e9 0c             	shr    $0xc,%ecx
f0101c0b:	3b 0d 84 f1 17 f0    	cmp    0xf017f184,%ecx
f0101c11:	72 15                	jb     f0101c28 <mem_init+0x9df>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101c13:	50                   	push   %eax
f0101c14:	68 88 53 10 f0       	push   $0xf0105388
f0101c19:	68 82 03 00 00       	push   $0x382
f0101c1e:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101c23:	e8 78 e4 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0101c28:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101c2d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101c30:	83 ec 04             	sub    $0x4,%esp
f0101c33:	6a 00                	push   $0x0
f0101c35:	68 00 10 00 00       	push   $0x1000
f0101c3a:	52                   	push   %edx
f0101c3b:	e8 e7 f3 ff ff       	call   f0101027 <pgdir_walk>
f0101c40:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101c43:	8d 57 04             	lea    0x4(%edi),%edx
f0101c46:	83 c4 10             	add    $0x10,%esp
f0101c49:	39 d0                	cmp    %edx,%eax
f0101c4b:	74 19                	je     f0101c66 <mem_init+0xa1d>
f0101c4d:	68 5c 57 10 f0       	push   $0xf010575c
f0101c52:	68 95 5c 10 f0       	push   $0xf0105c95
f0101c57:	68 83 03 00 00       	push   $0x383
f0101c5c:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101c61:	e8 3a e4 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c66:	6a 06                	push   $0x6
f0101c68:	68 00 10 00 00       	push   $0x1000
f0101c6d:	56                   	push   %esi
f0101c6e:	ff 35 88 f1 17 f0    	pushl  0xf017f188
f0101c74:	e8 68 f5 ff ff       	call   f01011e1 <page_insert>
f0101c79:	83 c4 10             	add    $0x10,%esp
f0101c7c:	85 c0                	test   %eax,%eax
f0101c7e:	74 19                	je     f0101c99 <mem_init+0xa50>
f0101c80:	68 9c 57 10 f0       	push   $0xf010579c
f0101c85:	68 95 5c 10 f0       	push   $0xf0105c95
f0101c8a:	68 86 03 00 00       	push   $0x386
f0101c8f:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101c94:	e8 07 e4 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c99:	8b 3d 88 f1 17 f0    	mov    0xf017f188,%edi
f0101c9f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ca4:	89 f8                	mov    %edi,%eax
f0101ca6:	e8 6e ee ff ff       	call   f0100b19 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101cab:	89 f2                	mov    %esi,%edx
f0101cad:	2b 15 8c f1 17 f0    	sub    0xf017f18c,%edx
f0101cb3:	c1 fa 03             	sar    $0x3,%edx
f0101cb6:	c1 e2 0c             	shl    $0xc,%edx
f0101cb9:	39 d0                	cmp    %edx,%eax
f0101cbb:	74 19                	je     f0101cd6 <mem_init+0xa8d>
f0101cbd:	68 2c 57 10 f0       	push   $0xf010572c
f0101cc2:	68 95 5c 10 f0       	push   $0xf0105c95
f0101cc7:	68 87 03 00 00       	push   $0x387
f0101ccc:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101cd1:	e8 ca e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101cd6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101cdb:	74 19                	je     f0101cf6 <mem_init+0xaad>
f0101cdd:	68 79 5e 10 f0       	push   $0xf0105e79
f0101ce2:	68 95 5c 10 f0       	push   $0xf0105c95
f0101ce7:	68 88 03 00 00       	push   $0x388
f0101cec:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101cf1:	e8 aa e3 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101cf6:	83 ec 04             	sub    $0x4,%esp
f0101cf9:	6a 00                	push   $0x0
f0101cfb:	68 00 10 00 00       	push   $0x1000
f0101d00:	57                   	push   %edi
f0101d01:	e8 21 f3 ff ff       	call   f0101027 <pgdir_walk>
f0101d06:	83 c4 10             	add    $0x10,%esp
f0101d09:	f6 00 04             	testb  $0x4,(%eax)
f0101d0c:	75 19                	jne    f0101d27 <mem_init+0xade>
f0101d0e:	68 dc 57 10 f0       	push   $0xf01057dc
f0101d13:	68 95 5c 10 f0       	push   $0xf0105c95
f0101d18:	68 89 03 00 00       	push   $0x389
f0101d1d:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101d22:	e8 79 e3 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101d27:	a1 88 f1 17 f0       	mov    0xf017f188,%eax
f0101d2c:	f6 00 04             	testb  $0x4,(%eax)
f0101d2f:	75 19                	jne    f0101d4a <mem_init+0xb01>
f0101d31:	68 8a 5e 10 f0       	push   $0xf0105e8a
f0101d36:	68 95 5c 10 f0       	push   $0xf0105c95
f0101d3b:	68 8a 03 00 00       	push   $0x38a
f0101d40:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101d45:	e8 56 e3 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d4a:	6a 02                	push   $0x2
f0101d4c:	68 00 10 00 00       	push   $0x1000
f0101d51:	56                   	push   %esi
f0101d52:	50                   	push   %eax
f0101d53:	e8 89 f4 ff ff       	call   f01011e1 <page_insert>
f0101d58:	83 c4 10             	add    $0x10,%esp
f0101d5b:	85 c0                	test   %eax,%eax
f0101d5d:	74 19                	je     f0101d78 <mem_init+0xb2f>
f0101d5f:	68 f0 56 10 f0       	push   $0xf01056f0
f0101d64:	68 95 5c 10 f0       	push   $0xf0105c95
f0101d69:	68 8d 03 00 00       	push   $0x38d
f0101d6e:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101d73:	e8 28 e3 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101d78:	83 ec 04             	sub    $0x4,%esp
f0101d7b:	6a 00                	push   $0x0
f0101d7d:	68 00 10 00 00       	push   $0x1000
f0101d82:	ff 35 88 f1 17 f0    	pushl  0xf017f188
f0101d88:	e8 9a f2 ff ff       	call   f0101027 <pgdir_walk>
f0101d8d:	83 c4 10             	add    $0x10,%esp
f0101d90:	f6 00 02             	testb  $0x2,(%eax)
f0101d93:	75 19                	jne    f0101dae <mem_init+0xb65>
f0101d95:	68 10 58 10 f0       	push   $0xf0105810
f0101d9a:	68 95 5c 10 f0       	push   $0xf0105c95
f0101d9f:	68 8e 03 00 00       	push   $0x38e
f0101da4:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101da9:	e8 f2 e2 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101dae:	83 ec 04             	sub    $0x4,%esp
f0101db1:	6a 00                	push   $0x0
f0101db3:	68 00 10 00 00       	push   $0x1000
f0101db8:	ff 35 88 f1 17 f0    	pushl  0xf017f188
f0101dbe:	e8 64 f2 ff ff       	call   f0101027 <pgdir_walk>
f0101dc3:	83 c4 10             	add    $0x10,%esp
f0101dc6:	f6 00 04             	testb  $0x4,(%eax)
f0101dc9:	74 19                	je     f0101de4 <mem_init+0xb9b>
f0101dcb:	68 44 58 10 f0       	push   $0xf0105844
f0101dd0:	68 95 5c 10 f0       	push   $0xf0105c95
f0101dd5:	68 8f 03 00 00       	push   $0x38f
f0101dda:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101ddf:	e8 bc e2 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101de4:	6a 02                	push   $0x2
f0101de6:	68 00 00 40 00       	push   $0x400000
f0101deb:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101dee:	ff 35 88 f1 17 f0    	pushl  0xf017f188
f0101df4:	e8 e8 f3 ff ff       	call   f01011e1 <page_insert>
f0101df9:	83 c4 10             	add    $0x10,%esp
f0101dfc:	85 c0                	test   %eax,%eax
f0101dfe:	78 19                	js     f0101e19 <mem_init+0xbd0>
f0101e00:	68 7c 58 10 f0       	push   $0xf010587c
f0101e05:	68 95 5c 10 f0       	push   $0xf0105c95
f0101e0a:	68 92 03 00 00       	push   $0x392
f0101e0f:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101e14:	e8 87 e2 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101e19:	6a 02                	push   $0x2
f0101e1b:	68 00 10 00 00       	push   $0x1000
f0101e20:	53                   	push   %ebx
f0101e21:	ff 35 88 f1 17 f0    	pushl  0xf017f188
f0101e27:	e8 b5 f3 ff ff       	call   f01011e1 <page_insert>
f0101e2c:	83 c4 10             	add    $0x10,%esp
f0101e2f:	85 c0                	test   %eax,%eax
f0101e31:	74 19                	je     f0101e4c <mem_init+0xc03>
f0101e33:	68 b4 58 10 f0       	push   $0xf01058b4
f0101e38:	68 95 5c 10 f0       	push   $0xf0105c95
f0101e3d:	68 95 03 00 00       	push   $0x395
f0101e42:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101e47:	e8 54 e2 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e4c:	83 ec 04             	sub    $0x4,%esp
f0101e4f:	6a 00                	push   $0x0
f0101e51:	68 00 10 00 00       	push   $0x1000
f0101e56:	ff 35 88 f1 17 f0    	pushl  0xf017f188
f0101e5c:	e8 c6 f1 ff ff       	call   f0101027 <pgdir_walk>
f0101e61:	83 c4 10             	add    $0x10,%esp
f0101e64:	f6 00 04             	testb  $0x4,(%eax)
f0101e67:	74 19                	je     f0101e82 <mem_init+0xc39>
f0101e69:	68 44 58 10 f0       	push   $0xf0105844
f0101e6e:	68 95 5c 10 f0       	push   $0xf0105c95
f0101e73:	68 96 03 00 00       	push   $0x396
f0101e78:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101e7d:	e8 1e e2 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101e82:	8b 3d 88 f1 17 f0    	mov    0xf017f188,%edi
f0101e88:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e8d:	89 f8                	mov    %edi,%eax
f0101e8f:	e8 85 ec ff ff       	call   f0100b19 <check_va2pa>
f0101e94:	89 c1                	mov    %eax,%ecx
f0101e96:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e99:	89 d8                	mov    %ebx,%eax
f0101e9b:	2b 05 8c f1 17 f0    	sub    0xf017f18c,%eax
f0101ea1:	c1 f8 03             	sar    $0x3,%eax
f0101ea4:	c1 e0 0c             	shl    $0xc,%eax
f0101ea7:	39 c1                	cmp    %eax,%ecx
f0101ea9:	74 19                	je     f0101ec4 <mem_init+0xc7b>
f0101eab:	68 f0 58 10 f0       	push   $0xf01058f0
f0101eb0:	68 95 5c 10 f0       	push   $0xf0105c95
f0101eb5:	68 99 03 00 00       	push   $0x399
f0101eba:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101ebf:	e8 dc e1 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ec4:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ec9:	89 f8                	mov    %edi,%eax
f0101ecb:	e8 49 ec ff ff       	call   f0100b19 <check_va2pa>
f0101ed0:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101ed3:	74 19                	je     f0101eee <mem_init+0xca5>
f0101ed5:	68 1c 59 10 f0       	push   $0xf010591c
f0101eda:	68 95 5c 10 f0       	push   $0xf0105c95
f0101edf:	68 9a 03 00 00       	push   $0x39a
f0101ee4:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101ee9:	e8 b2 e1 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101eee:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101ef3:	74 19                	je     f0101f0e <mem_init+0xcc5>
f0101ef5:	68 a0 5e 10 f0       	push   $0xf0105ea0
f0101efa:	68 95 5c 10 f0       	push   $0xf0105c95
f0101eff:	68 9c 03 00 00       	push   $0x39c
f0101f04:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101f09:	e8 92 e1 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101f0e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f13:	74 19                	je     f0101f2e <mem_init+0xce5>
f0101f15:	68 b1 5e 10 f0       	push   $0xf0105eb1
f0101f1a:	68 95 5c 10 f0       	push   $0xf0105c95
f0101f1f:	68 9d 03 00 00       	push   $0x39d
f0101f24:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101f29:	e8 72 e1 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101f2e:	83 ec 0c             	sub    $0xc,%esp
f0101f31:	6a 00                	push   $0x0
f0101f33:	e8 17 f0 ff ff       	call   f0100f4f <page_alloc>
f0101f38:	83 c4 10             	add    $0x10,%esp
f0101f3b:	85 c0                	test   %eax,%eax
f0101f3d:	74 04                	je     f0101f43 <mem_init+0xcfa>
f0101f3f:	39 c6                	cmp    %eax,%esi
f0101f41:	74 19                	je     f0101f5c <mem_init+0xd13>
f0101f43:	68 4c 59 10 f0       	push   $0xf010594c
f0101f48:	68 95 5c 10 f0       	push   $0xf0105c95
f0101f4d:	68 a0 03 00 00       	push   $0x3a0
f0101f52:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101f57:	e8 44 e1 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101f5c:	83 ec 08             	sub    $0x8,%esp
f0101f5f:	6a 00                	push   $0x0
f0101f61:	ff 35 88 f1 17 f0    	pushl  0xf017f188
f0101f67:	e8 2b f2 ff ff       	call   f0101197 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f6c:	8b 3d 88 f1 17 f0    	mov    0xf017f188,%edi
f0101f72:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f77:	89 f8                	mov    %edi,%eax
f0101f79:	e8 9b eb ff ff       	call   f0100b19 <check_va2pa>
f0101f7e:	83 c4 10             	add    $0x10,%esp
f0101f81:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f84:	74 19                	je     f0101f9f <mem_init+0xd56>
f0101f86:	68 70 59 10 f0       	push   $0xf0105970
f0101f8b:	68 95 5c 10 f0       	push   $0xf0105c95
f0101f90:	68 a4 03 00 00       	push   $0x3a4
f0101f95:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101f9a:	e8 01 e1 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f9f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fa4:	89 f8                	mov    %edi,%eax
f0101fa6:	e8 6e eb ff ff       	call   f0100b19 <check_va2pa>
f0101fab:	89 da                	mov    %ebx,%edx
f0101fad:	2b 15 8c f1 17 f0    	sub    0xf017f18c,%edx
f0101fb3:	c1 fa 03             	sar    $0x3,%edx
f0101fb6:	c1 e2 0c             	shl    $0xc,%edx
f0101fb9:	39 d0                	cmp    %edx,%eax
f0101fbb:	74 19                	je     f0101fd6 <mem_init+0xd8d>
f0101fbd:	68 1c 59 10 f0       	push   $0xf010591c
f0101fc2:	68 95 5c 10 f0       	push   $0xf0105c95
f0101fc7:	68 a5 03 00 00       	push   $0x3a5
f0101fcc:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101fd1:	e8 ca e0 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101fd6:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101fdb:	74 19                	je     f0101ff6 <mem_init+0xdad>
f0101fdd:	68 57 5e 10 f0       	push   $0xf0105e57
f0101fe2:	68 95 5c 10 f0       	push   $0xf0105c95
f0101fe7:	68 a6 03 00 00       	push   $0x3a6
f0101fec:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0101ff1:	e8 aa e0 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101ff6:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ffb:	74 19                	je     f0102016 <mem_init+0xdcd>
f0101ffd:	68 b1 5e 10 f0       	push   $0xf0105eb1
f0102002:	68 95 5c 10 f0       	push   $0xf0105c95
f0102007:	68 a7 03 00 00       	push   $0x3a7
f010200c:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0102011:	e8 8a e0 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102016:	6a 00                	push   $0x0
f0102018:	68 00 10 00 00       	push   $0x1000
f010201d:	53                   	push   %ebx
f010201e:	57                   	push   %edi
f010201f:	e8 bd f1 ff ff       	call   f01011e1 <page_insert>
f0102024:	83 c4 10             	add    $0x10,%esp
f0102027:	85 c0                	test   %eax,%eax
f0102029:	74 19                	je     f0102044 <mem_init+0xdfb>
f010202b:	68 94 59 10 f0       	push   $0xf0105994
f0102030:	68 95 5c 10 f0       	push   $0xf0105c95
f0102035:	68 aa 03 00 00       	push   $0x3aa
f010203a:	68 5d 5c 10 f0       	push   $0xf0105c5d
f010203f:	e8 5c e0 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0102044:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102049:	75 19                	jne    f0102064 <mem_init+0xe1b>
f010204b:	68 c2 5e 10 f0       	push   $0xf0105ec2
f0102050:	68 95 5c 10 f0       	push   $0xf0105c95
f0102055:	68 ab 03 00 00       	push   $0x3ab
f010205a:	68 5d 5c 10 f0       	push   $0xf0105c5d
f010205f:	e8 3c e0 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0102064:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102067:	74 19                	je     f0102082 <mem_init+0xe39>
f0102069:	68 ce 5e 10 f0       	push   $0xf0105ece
f010206e:	68 95 5c 10 f0       	push   $0xf0105c95
f0102073:	68 ac 03 00 00       	push   $0x3ac
f0102078:	68 5d 5c 10 f0       	push   $0xf0105c5d
f010207d:	e8 1e e0 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102082:	83 ec 08             	sub    $0x8,%esp
f0102085:	68 00 10 00 00       	push   $0x1000
f010208a:	ff 35 88 f1 17 f0    	pushl  0xf017f188
f0102090:	e8 02 f1 ff ff       	call   f0101197 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102095:	8b 3d 88 f1 17 f0    	mov    0xf017f188,%edi
f010209b:	ba 00 00 00 00       	mov    $0x0,%edx
f01020a0:	89 f8                	mov    %edi,%eax
f01020a2:	e8 72 ea ff ff       	call   f0100b19 <check_va2pa>
f01020a7:	83 c4 10             	add    $0x10,%esp
f01020aa:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020ad:	74 19                	je     f01020c8 <mem_init+0xe7f>
f01020af:	68 70 59 10 f0       	push   $0xf0105970
f01020b4:	68 95 5c 10 f0       	push   $0xf0105c95
f01020b9:	68 b0 03 00 00       	push   $0x3b0
f01020be:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01020c3:	e8 d8 df ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01020c8:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020cd:	89 f8                	mov    %edi,%eax
f01020cf:	e8 45 ea ff ff       	call   f0100b19 <check_va2pa>
f01020d4:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020d7:	74 19                	je     f01020f2 <mem_init+0xea9>
f01020d9:	68 cc 59 10 f0       	push   $0xf01059cc
f01020de:	68 95 5c 10 f0       	push   $0xf0105c95
f01020e3:	68 b1 03 00 00       	push   $0x3b1
f01020e8:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01020ed:	e8 ae df ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f01020f2:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01020f7:	74 19                	je     f0102112 <mem_init+0xec9>
f01020f9:	68 e3 5e 10 f0       	push   $0xf0105ee3
f01020fe:	68 95 5c 10 f0       	push   $0xf0105c95
f0102103:	68 b2 03 00 00       	push   $0x3b2
f0102108:	68 5d 5c 10 f0       	push   $0xf0105c5d
f010210d:	e8 8e df ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0102112:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102117:	74 19                	je     f0102132 <mem_init+0xee9>
f0102119:	68 b1 5e 10 f0       	push   $0xf0105eb1
f010211e:	68 95 5c 10 f0       	push   $0xf0105c95
f0102123:	68 b3 03 00 00       	push   $0x3b3
f0102128:	68 5d 5c 10 f0       	push   $0xf0105c5d
f010212d:	e8 6e df ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102132:	83 ec 0c             	sub    $0xc,%esp
f0102135:	6a 00                	push   $0x0
f0102137:	e8 13 ee ff ff       	call   f0100f4f <page_alloc>
f010213c:	83 c4 10             	add    $0x10,%esp
f010213f:	85 c0                	test   %eax,%eax
f0102141:	74 04                	je     f0102147 <mem_init+0xefe>
f0102143:	39 c3                	cmp    %eax,%ebx
f0102145:	74 19                	je     f0102160 <mem_init+0xf17>
f0102147:	68 f4 59 10 f0       	push   $0xf01059f4
f010214c:	68 95 5c 10 f0       	push   $0xf0105c95
f0102151:	68 b6 03 00 00       	push   $0x3b6
f0102156:	68 5d 5c 10 f0       	push   $0xf0105c5d
f010215b:	e8 40 df ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102160:	83 ec 0c             	sub    $0xc,%esp
f0102163:	6a 00                	push   $0x0
f0102165:	e8 e5 ed ff ff       	call   f0100f4f <page_alloc>
f010216a:	83 c4 10             	add    $0x10,%esp
f010216d:	85 c0                	test   %eax,%eax
f010216f:	74 19                	je     f010218a <mem_init+0xf41>
f0102171:	68 05 5e 10 f0       	push   $0xf0105e05
f0102176:	68 95 5c 10 f0       	push   $0xf0105c95
f010217b:	68 b9 03 00 00       	push   $0x3b9
f0102180:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0102185:	e8 16 df ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010218a:	8b 0d 88 f1 17 f0    	mov    0xf017f188,%ecx
f0102190:	8b 11                	mov    (%ecx),%edx
f0102192:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102198:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010219b:	2b 05 8c f1 17 f0    	sub    0xf017f18c,%eax
f01021a1:	c1 f8 03             	sar    $0x3,%eax
f01021a4:	c1 e0 0c             	shl    $0xc,%eax
f01021a7:	39 c2                	cmp    %eax,%edx
f01021a9:	74 19                	je     f01021c4 <mem_init+0xf7b>
f01021ab:	68 98 56 10 f0       	push   $0xf0105698
f01021b0:	68 95 5c 10 f0       	push   $0xf0105c95
f01021b5:	68 bc 03 00 00       	push   $0x3bc
f01021ba:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01021bf:	e8 dc de ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f01021c4:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01021ca:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021cd:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01021d2:	74 19                	je     f01021ed <mem_init+0xfa4>
f01021d4:	68 68 5e 10 f0       	push   $0xf0105e68
f01021d9:	68 95 5c 10 f0       	push   $0xf0105c95
f01021de:	68 be 03 00 00       	push   $0x3be
f01021e3:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01021e8:	e8 b3 de ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f01021ed:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021f0:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01021f6:	83 ec 0c             	sub    $0xc,%esp
f01021f9:	50                   	push   %eax
f01021fa:	e8 c0 ed ff ff       	call   f0100fbf <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01021ff:	83 c4 0c             	add    $0xc,%esp
f0102202:	6a 01                	push   $0x1
f0102204:	68 00 10 40 00       	push   $0x401000
f0102209:	ff 35 88 f1 17 f0    	pushl  0xf017f188
f010220f:	e8 13 ee ff ff       	call   f0101027 <pgdir_walk>
f0102214:	89 c7                	mov    %eax,%edi
f0102216:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102219:	a1 88 f1 17 f0       	mov    0xf017f188,%eax
f010221e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102221:	8b 40 04             	mov    0x4(%eax),%eax
f0102224:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102229:	8b 0d 84 f1 17 f0    	mov    0xf017f184,%ecx
f010222f:	89 c2                	mov    %eax,%edx
f0102231:	c1 ea 0c             	shr    $0xc,%edx
f0102234:	83 c4 10             	add    $0x10,%esp
f0102237:	39 ca                	cmp    %ecx,%edx
f0102239:	72 15                	jb     f0102250 <mem_init+0x1007>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010223b:	50                   	push   %eax
f010223c:	68 88 53 10 f0       	push   $0xf0105388
f0102241:	68 c5 03 00 00       	push   $0x3c5
f0102246:	68 5d 5c 10 f0       	push   $0xf0105c5d
f010224b:	e8 50 de ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102250:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0102255:	39 c7                	cmp    %eax,%edi
f0102257:	74 19                	je     f0102272 <mem_init+0x1029>
f0102259:	68 f4 5e 10 f0       	push   $0xf0105ef4
f010225e:	68 95 5c 10 f0       	push   $0xf0105c95
f0102263:	68 c6 03 00 00       	push   $0x3c6
f0102268:	68 5d 5c 10 f0       	push   $0xf0105c5d
f010226d:	e8 2e de ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102272:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102275:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f010227c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010227f:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102285:	2b 05 8c f1 17 f0    	sub    0xf017f18c,%eax
f010228b:	c1 f8 03             	sar    $0x3,%eax
f010228e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102291:	89 c2                	mov    %eax,%edx
f0102293:	c1 ea 0c             	shr    $0xc,%edx
f0102296:	39 d1                	cmp    %edx,%ecx
f0102298:	77 12                	ja     f01022ac <mem_init+0x1063>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010229a:	50                   	push   %eax
f010229b:	68 88 53 10 f0       	push   $0xf0105388
f01022a0:	6a 56                	push   $0x56
f01022a2:	68 7b 5c 10 f0       	push   $0xf0105c7b
f01022a7:	e8 f4 dd ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01022ac:	83 ec 04             	sub    $0x4,%esp
f01022af:	68 00 10 00 00       	push   $0x1000
f01022b4:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f01022b9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01022be:	50                   	push   %eax
f01022bf:	e8 3f 24 00 00       	call   f0104703 <memset>
	page_free(pp0);
f01022c4:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01022c7:	89 3c 24             	mov    %edi,(%esp)
f01022ca:	e8 f0 ec ff ff       	call   f0100fbf <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01022cf:	83 c4 0c             	add    $0xc,%esp
f01022d2:	6a 01                	push   $0x1
f01022d4:	6a 00                	push   $0x0
f01022d6:	ff 35 88 f1 17 f0    	pushl  0xf017f188
f01022dc:	e8 46 ed ff ff       	call   f0101027 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01022e1:	89 fa                	mov    %edi,%edx
f01022e3:	2b 15 8c f1 17 f0    	sub    0xf017f18c,%edx
f01022e9:	c1 fa 03             	sar    $0x3,%edx
f01022ec:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01022ef:	89 d0                	mov    %edx,%eax
f01022f1:	c1 e8 0c             	shr    $0xc,%eax
f01022f4:	83 c4 10             	add    $0x10,%esp
f01022f7:	3b 05 84 f1 17 f0    	cmp    0xf017f184,%eax
f01022fd:	72 12                	jb     f0102311 <mem_init+0x10c8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01022ff:	52                   	push   %edx
f0102300:	68 88 53 10 f0       	push   $0xf0105388
f0102305:	6a 56                	push   $0x56
f0102307:	68 7b 5c 10 f0       	push   $0xf0105c7b
f010230c:	e8 8f dd ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0102311:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102317:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010231a:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102320:	f6 00 01             	testb  $0x1,(%eax)
f0102323:	74 19                	je     f010233e <mem_init+0x10f5>
f0102325:	68 0c 5f 10 f0       	push   $0xf0105f0c
f010232a:	68 95 5c 10 f0       	push   $0xf0105c95
f010232f:	68 d0 03 00 00       	push   $0x3d0
f0102334:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0102339:	e8 62 dd ff ff       	call   f01000a0 <_panic>
f010233e:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102341:	39 d0                	cmp    %edx,%eax
f0102343:	75 db                	jne    f0102320 <mem_init+0x10d7>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102345:	a1 88 f1 17 f0       	mov    0xf017f188,%eax
f010234a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102350:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102353:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102359:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010235c:	89 3d a0 e4 17 f0    	mov    %edi,0xf017e4a0

	// free the pages we took
	page_free(pp0);
f0102362:	83 ec 0c             	sub    $0xc,%esp
f0102365:	50                   	push   %eax
f0102366:	e8 54 ec ff ff       	call   f0100fbf <page_free>
	page_free(pp1);
f010236b:	89 1c 24             	mov    %ebx,(%esp)
f010236e:	e8 4c ec ff ff       	call   f0100fbf <page_free>
	page_free(pp2);
f0102373:	89 34 24             	mov    %esi,(%esp)
f0102376:	e8 44 ec ff ff       	call   f0100fbf <page_free>

	cprintf("check_page() succeeded!\n");
f010237b:	c7 04 24 23 5f 10 f0 	movl   $0xf0105f23,(%esp)
f0102382:	e8 76 0e 00 00       	call   f01031fd <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U|PTE_P);
f0102387:	a1 8c f1 17 f0       	mov    0xf017f18c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010238c:	83 c4 10             	add    $0x10,%esp
f010238f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102394:	77 15                	ja     f01023ab <mem_init+0x1162>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102396:	50                   	push   %eax
f0102397:	68 ac 53 10 f0       	push   $0xf01053ac
f010239c:	68 c4 00 00 00       	push   $0xc4
f01023a1:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01023a6:	e8 f5 dc ff ff       	call   f01000a0 <_panic>
f01023ab:	83 ec 08             	sub    $0x8,%esp
f01023ae:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f01023b0:	05 00 00 00 10       	add    $0x10000000,%eax
f01023b5:	50                   	push   %eax
f01023b6:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01023bb:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01023c0:	a1 88 f1 17 f0       	mov    0xf017f188,%eax
f01023c5:	e8 f0 ec ff ff       	call   f01010ba <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U);
f01023ca:	a1 ac e4 17 f0       	mov    0xf017e4ac,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01023cf:	83 c4 10             	add    $0x10,%esp
f01023d2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01023d7:	77 15                	ja     f01023ee <mem_init+0x11a5>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01023d9:	50                   	push   %eax
f01023da:	68 ac 53 10 f0       	push   $0xf01053ac
f01023df:	68 cd 00 00 00       	push   $0xcd
f01023e4:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01023e9:	e8 b2 dc ff ff       	call   f01000a0 <_panic>
f01023ee:	83 ec 08             	sub    $0x8,%esp
f01023f1:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f01023f3:	05 00 00 00 10       	add    $0x10000000,%eax
f01023f8:	50                   	push   %eax
f01023f9:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01023fe:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102403:	a1 88 f1 17 f0       	mov    0xf017f188,%eax
f0102408:	e8 ad ec ff ff       	call   f01010ba <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010240d:	83 c4 10             	add    $0x10,%esp
f0102410:	b8 00 20 11 f0       	mov    $0xf0112000,%eax
f0102415:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010241a:	77 15                	ja     f0102431 <mem_init+0x11e8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010241c:	50                   	push   %eax
f010241d:	68 ac 53 10 f0       	push   $0xf01053ac
f0102422:	68 da 00 00 00       	push   $0xda
f0102427:	68 5d 5c 10 f0       	push   $0xf0105c5d
f010242c:	e8 6f dc ff ff       	call   f01000a0 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102431:	83 ec 08             	sub    $0x8,%esp
f0102434:	6a 02                	push   $0x2
f0102436:	68 00 20 11 00       	push   $0x112000
f010243b:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102440:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102445:	a1 88 f1 17 f0       	mov    0xf017f188,%eax
f010244a:	e8 6b ec ff ff       	call   f01010ba <boot_map_region>
		for(; padd < ((uintptr_t)0x10000000); padd += PTSIZE){
			kern_pgdir[PDX(KERNBASE+padd)] = padd  | PTE_PS | PTE_W| PTE_P;
		}	
	}
	else*/
	boot_map_region(kern_pgdir, KERNBASE, -KERNBASE,0 ,PTE_W);
f010244f:	83 c4 08             	add    $0x8,%esp
f0102452:	6a 02                	push   $0x2
f0102454:	6a 00                	push   $0x0
f0102456:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f010245b:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102460:	a1 88 f1 17 f0       	mov    0xf017f188,%eax
f0102465:	e8 50 ec ff ff       	call   f01010ba <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010246a:	8b 1d 88 f1 17 f0    	mov    0xf017f188,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102470:	a1 84 f1 17 f0       	mov    0xf017f184,%eax
f0102475:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102478:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010247f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102484:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102487:	8b 3d 8c f1 17 f0    	mov    0xf017f18c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010248d:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102490:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102493:	be 00 00 00 00       	mov    $0x0,%esi
f0102498:	eb 55                	jmp    f01024ef <mem_init+0x12a6>
f010249a:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01024a0:	89 d8                	mov    %ebx,%eax
f01024a2:	e8 72 e6 ff ff       	call   f0100b19 <check_va2pa>
f01024a7:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01024ae:	77 15                	ja     f01024c5 <mem_init+0x127c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01024b0:	57                   	push   %edi
f01024b1:	68 ac 53 10 f0       	push   $0xf01053ac
f01024b6:	68 0a 03 00 00       	push   $0x30a
f01024bb:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01024c0:	e8 db db ff ff       	call   f01000a0 <_panic>
f01024c5:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f01024cc:	39 c2                	cmp    %eax,%edx
f01024ce:	74 19                	je     f01024e9 <mem_init+0x12a0>
f01024d0:	68 18 5a 10 f0       	push   $0xf0105a18
f01024d5:	68 95 5c 10 f0       	push   $0xf0105c95
f01024da:	68 0a 03 00 00       	push   $0x30a
f01024df:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01024e4:	e8 b7 db ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01024e9:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01024ef:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f01024f2:	77 a6                	ja     f010249a <mem_init+0x1251>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01024f4:	8b 3d ac e4 17 f0    	mov    0xf017e4ac,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01024fa:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01024fd:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f0102502:	89 f2                	mov    %esi,%edx
f0102504:	89 d8                	mov    %ebx,%eax
f0102506:	e8 0e e6 ff ff       	call   f0100b19 <check_va2pa>
f010250b:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f0102512:	77 15                	ja     f0102529 <mem_init+0x12e0>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102514:	57                   	push   %edi
f0102515:	68 ac 53 10 f0       	push   $0xf01053ac
f010251a:	68 0f 03 00 00       	push   $0x30f
f010251f:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0102524:	e8 77 db ff ff       	call   f01000a0 <_panic>
f0102529:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f0102530:	39 c2                	cmp    %eax,%edx
f0102532:	74 19                	je     f010254d <mem_init+0x1304>
f0102534:	68 4c 5a 10 f0       	push   $0xf0105a4c
f0102539:	68 95 5c 10 f0       	push   $0xf0105c95
f010253e:	68 0f 03 00 00       	push   $0x30f
f0102543:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0102548:	e8 53 db ff ff       	call   f01000a0 <_panic>
f010254d:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102553:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f0102559:	75 a7                	jne    f0102502 <mem_init+0x12b9>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010255b:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010255e:	c1 e7 0c             	shl    $0xc,%edi
f0102561:	be 00 00 00 00       	mov    $0x0,%esi
f0102566:	eb 30                	jmp    f0102598 <mem_init+0x134f>
f0102568:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010256e:	89 d8                	mov    %ebx,%eax
f0102570:	e8 a4 e5 ff ff       	call   f0100b19 <check_va2pa>
f0102575:	39 c6                	cmp    %eax,%esi
f0102577:	74 19                	je     f0102592 <mem_init+0x1349>
f0102579:	68 80 5a 10 f0       	push   $0xf0105a80
f010257e:	68 95 5c 10 f0       	push   $0xf0105c95
f0102583:	68 13 03 00 00       	push   $0x313
f0102588:	68 5d 5c 10 f0       	push   $0xf0105c5d
f010258d:	e8 0e db ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102592:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102598:	39 fe                	cmp    %edi,%esi
f010259a:	72 cc                	jb     f0102568 <mem_init+0x131f>
f010259c:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01025a1:	89 f2                	mov    %esi,%edx
f01025a3:	89 d8                	mov    %ebx,%eax
f01025a5:	e8 6f e5 ff ff       	call   f0100b19 <check_va2pa>
f01025aa:	8d 96 00 a0 11 10    	lea    0x1011a000(%esi),%edx
f01025b0:	39 c2                	cmp    %eax,%edx
f01025b2:	74 19                	je     f01025cd <mem_init+0x1384>
f01025b4:	68 a8 5a 10 f0       	push   $0xf0105aa8
f01025b9:	68 95 5c 10 f0       	push   $0xf0105c95
f01025be:	68 17 03 00 00       	push   $0x317
f01025c3:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01025c8:	e8 d3 da ff ff       	call   f01000a0 <_panic>
f01025cd:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01025d3:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f01025d9:	75 c6                	jne    f01025a1 <mem_init+0x1358>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01025db:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01025e0:	89 d8                	mov    %ebx,%eax
f01025e2:	e8 32 e5 ff ff       	call   f0100b19 <check_va2pa>
f01025e7:	83 f8 ff             	cmp    $0xffffffff,%eax
f01025ea:	74 51                	je     f010263d <mem_init+0x13f4>
f01025ec:	68 f0 5a 10 f0       	push   $0xf0105af0
f01025f1:	68 95 5c 10 f0       	push   $0xf0105c95
f01025f6:	68 18 03 00 00       	push   $0x318
f01025fb:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0102600:	e8 9b da ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102605:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f010260a:	72 36                	jb     f0102642 <mem_init+0x13f9>
f010260c:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102611:	76 07                	jbe    f010261a <mem_init+0x13d1>
f0102613:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102618:	75 28                	jne    f0102642 <mem_init+0x13f9>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f010261a:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f010261e:	0f 85 83 00 00 00    	jne    f01026a7 <mem_init+0x145e>
f0102624:	68 3c 5f 10 f0       	push   $0xf0105f3c
f0102629:	68 95 5c 10 f0       	push   $0xf0105c95
f010262e:	68 21 03 00 00       	push   $0x321
f0102633:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0102638:	e8 63 da ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010263d:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102642:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102647:	76 3f                	jbe    f0102688 <mem_init+0x143f>
				assert(pgdir[i] & PTE_P);
f0102649:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f010264c:	f6 c2 01             	test   $0x1,%dl
f010264f:	75 19                	jne    f010266a <mem_init+0x1421>
f0102651:	68 3c 5f 10 f0       	push   $0xf0105f3c
f0102656:	68 95 5c 10 f0       	push   $0xf0105c95
f010265b:	68 25 03 00 00       	push   $0x325
f0102660:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0102665:	e8 36 da ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f010266a:	f6 c2 02             	test   $0x2,%dl
f010266d:	75 38                	jne    f01026a7 <mem_init+0x145e>
f010266f:	68 4d 5f 10 f0       	push   $0xf0105f4d
f0102674:	68 95 5c 10 f0       	push   $0xf0105c95
f0102679:	68 26 03 00 00       	push   $0x326
f010267e:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0102683:	e8 18 da ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102688:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f010268c:	74 19                	je     f01026a7 <mem_init+0x145e>
f010268e:	68 5e 5f 10 f0       	push   $0xf0105f5e
f0102693:	68 95 5c 10 f0       	push   $0xf0105c95
f0102698:	68 28 03 00 00       	push   $0x328
f010269d:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01026a2:	e8 f9 d9 ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01026a7:	83 c0 01             	add    $0x1,%eax
f01026aa:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01026af:	0f 86 50 ff ff ff    	jbe    f0102605 <mem_init+0x13bc>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01026b5:	83 ec 0c             	sub    $0xc,%esp
f01026b8:	68 20 5b 10 f0       	push   $0xf0105b20
f01026bd:	e8 3b 0b 00 00       	call   f01031fd <cprintf>
		uintptr_t paddress = 0;
		for(paddress = 0; paddress < ((uintptr_t)0x10000000); paddress += PTSIZE){
		invlpg((void*)(KERNBASE + paddress));
	}
	}*/
	lcr3(PADDR(kern_pgdir));
f01026c2:	a1 88 f1 17 f0       	mov    0xf017f188,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026c7:	83 c4 10             	add    $0x10,%esp
f01026ca:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01026cf:	77 15                	ja     f01026e6 <mem_init+0x149d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026d1:	50                   	push   %eax
f01026d2:	68 ac 53 10 f0       	push   $0xf01053ac
f01026d7:	68 01 01 00 00       	push   $0x101
f01026dc:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01026e1:	e8 ba d9 ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01026e6:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01026eb:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01026ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01026f3:	e8 13 e5 ff ff       	call   f0100c0b <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01026f8:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f01026fb:	83 e0 f3             	and    $0xfffffff3,%eax
f01026fe:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102703:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102706:	83 ec 0c             	sub    $0xc,%esp
f0102709:	6a 00                	push   $0x0
f010270b:	e8 3f e8 ff ff       	call   f0100f4f <page_alloc>
f0102710:	89 c3                	mov    %eax,%ebx
f0102712:	83 c4 10             	add    $0x10,%esp
f0102715:	85 c0                	test   %eax,%eax
f0102717:	75 19                	jne    f0102732 <mem_init+0x14e9>
f0102719:	68 5a 5d 10 f0       	push   $0xf0105d5a
f010271e:	68 95 5c 10 f0       	push   $0xf0105c95
f0102723:	68 eb 03 00 00       	push   $0x3eb
f0102728:	68 5d 5c 10 f0       	push   $0xf0105c5d
f010272d:	e8 6e d9 ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0102732:	83 ec 0c             	sub    $0xc,%esp
f0102735:	6a 00                	push   $0x0
f0102737:	e8 13 e8 ff ff       	call   f0100f4f <page_alloc>
f010273c:	89 c7                	mov    %eax,%edi
f010273e:	83 c4 10             	add    $0x10,%esp
f0102741:	85 c0                	test   %eax,%eax
f0102743:	75 19                	jne    f010275e <mem_init+0x1515>
f0102745:	68 70 5d 10 f0       	push   $0xf0105d70
f010274a:	68 95 5c 10 f0       	push   $0xf0105c95
f010274f:	68 ec 03 00 00       	push   $0x3ec
f0102754:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0102759:	e8 42 d9 ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010275e:	83 ec 0c             	sub    $0xc,%esp
f0102761:	6a 00                	push   $0x0
f0102763:	e8 e7 e7 ff ff       	call   f0100f4f <page_alloc>
f0102768:	89 c6                	mov    %eax,%esi
f010276a:	83 c4 10             	add    $0x10,%esp
f010276d:	85 c0                	test   %eax,%eax
f010276f:	75 19                	jne    f010278a <mem_init+0x1541>
f0102771:	68 86 5d 10 f0       	push   $0xf0105d86
f0102776:	68 95 5c 10 f0       	push   $0xf0105c95
f010277b:	68 ed 03 00 00       	push   $0x3ed
f0102780:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0102785:	e8 16 d9 ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f010278a:	83 ec 0c             	sub    $0xc,%esp
f010278d:	53                   	push   %ebx
f010278e:	e8 2c e8 ff ff       	call   f0100fbf <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102793:	89 f8                	mov    %edi,%eax
f0102795:	2b 05 8c f1 17 f0    	sub    0xf017f18c,%eax
f010279b:	c1 f8 03             	sar    $0x3,%eax
f010279e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01027a1:	89 c2                	mov    %eax,%edx
f01027a3:	c1 ea 0c             	shr    $0xc,%edx
f01027a6:	83 c4 10             	add    $0x10,%esp
f01027a9:	3b 15 84 f1 17 f0    	cmp    0xf017f184,%edx
f01027af:	72 12                	jb     f01027c3 <mem_init+0x157a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01027b1:	50                   	push   %eax
f01027b2:	68 88 53 10 f0       	push   $0xf0105388
f01027b7:	6a 56                	push   $0x56
f01027b9:	68 7b 5c 10 f0       	push   $0xf0105c7b
f01027be:	e8 dd d8 ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01027c3:	83 ec 04             	sub    $0x4,%esp
f01027c6:	68 00 10 00 00       	push   $0x1000
f01027cb:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f01027cd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01027d2:	50                   	push   %eax
f01027d3:	e8 2b 1f 00 00       	call   f0104703 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01027d8:	89 f0                	mov    %esi,%eax
f01027da:	2b 05 8c f1 17 f0    	sub    0xf017f18c,%eax
f01027e0:	c1 f8 03             	sar    $0x3,%eax
f01027e3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01027e6:	89 c2                	mov    %eax,%edx
f01027e8:	c1 ea 0c             	shr    $0xc,%edx
f01027eb:	83 c4 10             	add    $0x10,%esp
f01027ee:	3b 15 84 f1 17 f0    	cmp    0xf017f184,%edx
f01027f4:	72 12                	jb     f0102808 <mem_init+0x15bf>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01027f6:	50                   	push   %eax
f01027f7:	68 88 53 10 f0       	push   $0xf0105388
f01027fc:	6a 56                	push   $0x56
f01027fe:	68 7b 5c 10 f0       	push   $0xf0105c7b
f0102803:	e8 98 d8 ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102808:	83 ec 04             	sub    $0x4,%esp
f010280b:	68 00 10 00 00       	push   $0x1000
f0102810:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102812:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102817:	50                   	push   %eax
f0102818:	e8 e6 1e 00 00       	call   f0104703 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010281d:	6a 02                	push   $0x2
f010281f:	68 00 10 00 00       	push   $0x1000
f0102824:	57                   	push   %edi
f0102825:	ff 35 88 f1 17 f0    	pushl  0xf017f188
f010282b:	e8 b1 e9 ff ff       	call   f01011e1 <page_insert>
	assert(pp1->pp_ref == 1);
f0102830:	83 c4 20             	add    $0x20,%esp
f0102833:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102838:	74 19                	je     f0102853 <mem_init+0x160a>
f010283a:	68 57 5e 10 f0       	push   $0xf0105e57
f010283f:	68 95 5c 10 f0       	push   $0xf0105c95
f0102844:	68 f2 03 00 00       	push   $0x3f2
f0102849:	68 5d 5c 10 f0       	push   $0xf0105c5d
f010284e:	e8 4d d8 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102853:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f010285a:	01 01 01 
f010285d:	74 19                	je     f0102878 <mem_init+0x162f>
f010285f:	68 40 5b 10 f0       	push   $0xf0105b40
f0102864:	68 95 5c 10 f0       	push   $0xf0105c95
f0102869:	68 f3 03 00 00       	push   $0x3f3
f010286e:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0102873:	e8 28 d8 ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102878:	6a 02                	push   $0x2
f010287a:	68 00 10 00 00       	push   $0x1000
f010287f:	56                   	push   %esi
f0102880:	ff 35 88 f1 17 f0    	pushl  0xf017f188
f0102886:	e8 56 e9 ff ff       	call   f01011e1 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010288b:	83 c4 10             	add    $0x10,%esp
f010288e:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102895:	02 02 02 
f0102898:	74 19                	je     f01028b3 <mem_init+0x166a>
f010289a:	68 64 5b 10 f0       	push   $0xf0105b64
f010289f:	68 95 5c 10 f0       	push   $0xf0105c95
f01028a4:	68 f5 03 00 00       	push   $0x3f5
f01028a9:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01028ae:	e8 ed d7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01028b3:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01028b8:	74 19                	je     f01028d3 <mem_init+0x168a>
f01028ba:	68 79 5e 10 f0       	push   $0xf0105e79
f01028bf:	68 95 5c 10 f0       	push   $0xf0105c95
f01028c4:	68 f6 03 00 00       	push   $0x3f6
f01028c9:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01028ce:	e8 cd d7 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f01028d3:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01028d8:	74 19                	je     f01028f3 <mem_init+0x16aa>
f01028da:	68 e3 5e 10 f0       	push   $0xf0105ee3
f01028df:	68 95 5c 10 f0       	push   $0xf0105c95
f01028e4:	68 f7 03 00 00       	push   $0x3f7
f01028e9:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01028ee:	e8 ad d7 ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01028f3:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01028fa:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01028fd:	89 f0                	mov    %esi,%eax
f01028ff:	2b 05 8c f1 17 f0    	sub    0xf017f18c,%eax
f0102905:	c1 f8 03             	sar    $0x3,%eax
f0102908:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010290b:	89 c2                	mov    %eax,%edx
f010290d:	c1 ea 0c             	shr    $0xc,%edx
f0102910:	3b 15 84 f1 17 f0    	cmp    0xf017f184,%edx
f0102916:	72 12                	jb     f010292a <mem_init+0x16e1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102918:	50                   	push   %eax
f0102919:	68 88 53 10 f0       	push   $0xf0105388
f010291e:	6a 56                	push   $0x56
f0102920:	68 7b 5c 10 f0       	push   $0xf0105c7b
f0102925:	e8 76 d7 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f010292a:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102931:	03 03 03 
f0102934:	74 19                	je     f010294f <mem_init+0x1706>
f0102936:	68 88 5b 10 f0       	push   $0xf0105b88
f010293b:	68 95 5c 10 f0       	push   $0xf0105c95
f0102940:	68 f9 03 00 00       	push   $0x3f9
f0102945:	68 5d 5c 10 f0       	push   $0xf0105c5d
f010294a:	e8 51 d7 ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f010294f:	83 ec 08             	sub    $0x8,%esp
f0102952:	68 00 10 00 00       	push   $0x1000
f0102957:	ff 35 88 f1 17 f0    	pushl  0xf017f188
f010295d:	e8 35 e8 ff ff       	call   f0101197 <page_remove>
	assert(pp2->pp_ref == 0);
f0102962:	83 c4 10             	add    $0x10,%esp
f0102965:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010296a:	74 19                	je     f0102985 <mem_init+0x173c>
f010296c:	68 b1 5e 10 f0       	push   $0xf0105eb1
f0102971:	68 95 5c 10 f0       	push   $0xf0105c95
f0102976:	68 fb 03 00 00       	push   $0x3fb
f010297b:	68 5d 5c 10 f0       	push   $0xf0105c5d
f0102980:	e8 1b d7 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102985:	8b 0d 88 f1 17 f0    	mov    0xf017f188,%ecx
f010298b:	8b 11                	mov    (%ecx),%edx
f010298d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102993:	89 d8                	mov    %ebx,%eax
f0102995:	2b 05 8c f1 17 f0    	sub    0xf017f18c,%eax
f010299b:	c1 f8 03             	sar    $0x3,%eax
f010299e:	c1 e0 0c             	shl    $0xc,%eax
f01029a1:	39 c2                	cmp    %eax,%edx
f01029a3:	74 19                	je     f01029be <mem_init+0x1775>
f01029a5:	68 98 56 10 f0       	push   $0xf0105698
f01029aa:	68 95 5c 10 f0       	push   $0xf0105c95
f01029af:	68 fe 03 00 00       	push   $0x3fe
f01029b4:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01029b9:	e8 e2 d6 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f01029be:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01029c4:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01029c9:	74 19                	je     f01029e4 <mem_init+0x179b>
f01029cb:	68 68 5e 10 f0       	push   $0xf0105e68
f01029d0:	68 95 5c 10 f0       	push   $0xf0105c95
f01029d5:	68 00 04 00 00       	push   $0x400
f01029da:	68 5d 5c 10 f0       	push   $0xf0105c5d
f01029df:	e8 bc d6 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f01029e4:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01029ea:	83 ec 0c             	sub    $0xc,%esp
f01029ed:	53                   	push   %ebx
f01029ee:	e8 cc e5 ff ff       	call   f0100fbf <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01029f3:	c7 04 24 b4 5b 10 f0 	movl   $0xf0105bb4,(%esp)
f01029fa:	e8 fe 07 00 00       	call   f01031fd <cprintf>
f01029ff:	83 c4 10             	add    $0x10,%esp
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102a02:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a05:	5b                   	pop    %ebx
f0102a06:	5e                   	pop    %esi
f0102a07:	5f                   	pop    %edi
f0102a08:	5d                   	pop    %ebp
f0102a09:	c3                   	ret    

f0102a0a <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102a0a:	55                   	push   %ebp
f0102a0b:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102a0d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102a10:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102a13:	5d                   	pop    %ebp
f0102a14:	c3                   	ret    

f0102a15 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102a15:	55                   	push   %ebp
f0102a16:	89 e5                	mov    %esp,%ebp
f0102a18:	57                   	push   %edi
f0102a19:	56                   	push   %esi
f0102a1a:	53                   	push   %ebx
f0102a1b:	83 ec 20             	sub    $0x20,%esp
f0102a1e:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102a21:	8b 75 14             	mov    0x14(%ebp),%esi
	// LAB 3: Your code here.
	cprintf("user_mem_check va: %x, len: %x\n", va, len);
f0102a24:	ff 75 10             	pushl  0x10(%ebp)
f0102a27:	ff 75 0c             	pushl  0xc(%ebp)
f0102a2a:	68 e0 5b 10 f0       	push   $0xf0105be0
f0102a2f:	e8 c9 07 00 00       	call   f01031fd <cprintf>
	uint32_t begin = (uint32_t) ROUNDDOWN(va, PGSIZE); 
f0102a34:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102a37:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uint32_t end = (uint32_t) ROUNDUP(va+len, PGSIZE);
f0102a3d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102a40:	8b 55 10             	mov    0x10(%ebp),%edx
f0102a43:	8d 84 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%eax
f0102a4a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102a4f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	uint32_t i;
	for (i = (uint32_t)begin; i < end; i+=PGSIZE) {
f0102a52:	83 c4 10             	add    $0x10,%esp
f0102a55:	eb 43                	jmp    f0102a9a <user_mem_check+0x85>
		pte_t *pte = pgdir_walk(env->env_pgdir, (void*)i, 0);
f0102a57:	83 ec 04             	sub    $0x4,%esp
f0102a5a:	6a 00                	push   $0x0
f0102a5c:	53                   	push   %ebx
f0102a5d:	ff 77 5c             	pushl  0x5c(%edi)
f0102a60:	e8 c2 e5 ff ff       	call   f0101027 <pgdir_walk>
		// pprint(pte);
		if ((i>=ULIM) || !pte || !(*pte & PTE_P) || ((*pte & perm) != perm)) {
f0102a65:	83 c4 10             	add    $0x10,%esp
f0102a68:	85 c0                	test   %eax,%eax
f0102a6a:	74 14                	je     f0102a80 <user_mem_check+0x6b>
f0102a6c:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102a72:	77 0c                	ja     f0102a80 <user_mem_check+0x6b>
f0102a74:	8b 00                	mov    (%eax),%eax
f0102a76:	a8 01                	test   $0x1,%al
f0102a78:	74 06                	je     f0102a80 <user_mem_check+0x6b>
f0102a7a:	21 f0                	and    %esi,%eax
f0102a7c:	39 c6                	cmp    %eax,%esi
f0102a7e:	74 14                	je     f0102a94 <user_mem_check+0x7f>
f0102a80:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
f0102a83:	0f 42 5d 0c          	cmovb  0xc(%ebp),%ebx
			user_mem_check_addr = (i<(uint32_t)va?(uint32_t)va:i);
f0102a87:	89 1d 9c e4 17 f0    	mov    %ebx,0xf017e49c
			return -E_FAULT;
f0102a8d:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102a92:	eb 26                	jmp    f0102aba <user_mem_check+0xa5>
	// LAB 3: Your code here.
	cprintf("user_mem_check va: %x, len: %x\n", va, len);
	uint32_t begin = (uint32_t) ROUNDDOWN(va, PGSIZE); 
	uint32_t end = (uint32_t) ROUNDUP(va+len, PGSIZE);
	uint32_t i;
	for (i = (uint32_t)begin; i < end; i+=PGSIZE) {
f0102a94:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102a9a:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102a9d:	72 b8                	jb     f0102a57 <user_mem_check+0x42>
		if ((i>=ULIM) || !pte || !(*pte & PTE_P) || ((*pte & perm) != perm)) {
			user_mem_check_addr = (i<(uint32_t)va?(uint32_t)va:i);
			return -E_FAULT;
		}
	}
	cprintf("user_mem_check success va: %x, len: %x\n", va, len);
f0102a9f:	83 ec 04             	sub    $0x4,%esp
f0102aa2:	ff 75 10             	pushl  0x10(%ebp)
f0102aa5:	ff 75 0c             	pushl  0xc(%ebp)
f0102aa8:	68 00 5c 10 f0       	push   $0xf0105c00
f0102aad:	e8 4b 07 00 00       	call   f01031fd <cprintf>
	return 0;
f0102ab2:	83 c4 10             	add    $0x10,%esp
f0102ab5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102aba:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102abd:	5b                   	pop    %ebx
f0102abe:	5e                   	pop    %esi
f0102abf:	5f                   	pop    %edi
f0102ac0:	5d                   	pop    %ebp
f0102ac1:	c3                   	ret    

f0102ac2 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102ac2:	55                   	push   %ebp
f0102ac3:	89 e5                	mov    %esp,%ebp
f0102ac5:	53                   	push   %ebx
f0102ac6:	83 ec 04             	sub    $0x4,%esp
f0102ac9:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102acc:	8b 45 14             	mov    0x14(%ebp),%eax
f0102acf:	83 c8 04             	or     $0x4,%eax
f0102ad2:	50                   	push   %eax
f0102ad3:	ff 75 10             	pushl  0x10(%ebp)
f0102ad6:	ff 75 0c             	pushl  0xc(%ebp)
f0102ad9:	53                   	push   %ebx
f0102ada:	e8 36 ff ff ff       	call   f0102a15 <user_mem_check>
f0102adf:	83 c4 10             	add    $0x10,%esp
f0102ae2:	85 c0                	test   %eax,%eax
f0102ae4:	79 21                	jns    f0102b07 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102ae6:	83 ec 04             	sub    $0x4,%esp
f0102ae9:	ff 35 9c e4 17 f0    	pushl  0xf017e49c
f0102aef:	ff 73 48             	pushl  0x48(%ebx)
f0102af2:	68 28 5c 10 f0       	push   $0xf0105c28
f0102af7:	e8 01 07 00 00       	call   f01031fd <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102afc:	89 1c 24             	mov    %ebx,(%esp)
f0102aff:	e8 d2 05 00 00       	call   f01030d6 <env_destroy>
f0102b04:	83 c4 10             	add    $0x10,%esp
	}
}
f0102b07:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102b0a:	c9                   	leave  
f0102b0b:	c3                   	ret    

f0102b0c <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102b0c:	55                   	push   %ebp
f0102b0d:	89 e5                	mov    %esp,%ebp
f0102b0f:	57                   	push   %edi
f0102b10:	56                   	push   %esi
f0102b11:	53                   	push   %ebx
f0102b12:	83 ec 0c             	sub    $0xc,%esp
f0102b15:	89 c7                	mov    %eax,%edi
	// LAB 3: Your code here.
	// (But only if you need it for load_icode.)
	//
	void *begin = ROUNDDOWN(va, PGSIZE), *end = ROUNDUP(va+len, PGSIZE);
f0102b17:	89 d3                	mov    %edx,%ebx
f0102b19:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0102b1f:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102b26:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	for (; begin < end; begin += PGSIZE) {
f0102b2c:	eb 3d                	jmp    f0102b6b <region_alloc+0x5f>
		struct PageInfo *pg = page_alloc(0);
f0102b2e:	83 ec 0c             	sub    $0xc,%esp
f0102b31:	6a 00                	push   $0x0
f0102b33:	e8 17 e4 ff ff       	call   f0100f4f <page_alloc>
		if (!pg) panic("region_alloc failed!");
f0102b38:	83 c4 10             	add    $0x10,%esp
f0102b3b:	85 c0                	test   %eax,%eax
f0102b3d:	75 17                	jne    f0102b56 <region_alloc+0x4a>
f0102b3f:	83 ec 04             	sub    $0x4,%esp
f0102b42:	68 6c 5f 10 f0       	push   $0xf0105f6c
f0102b47:	68 20 01 00 00       	push   $0x120
f0102b4c:	68 81 5f 10 f0       	push   $0xf0105f81
f0102b51:	e8 4a d5 ff ff       	call   f01000a0 <_panic>
		page_insert(e->env_pgdir, pg, begin, PTE_W | PTE_U);
f0102b56:	6a 06                	push   $0x6
f0102b58:	53                   	push   %ebx
f0102b59:	50                   	push   %eax
f0102b5a:	ff 77 5c             	pushl  0x5c(%edi)
f0102b5d:	e8 7f e6 ff ff       	call   f01011e1 <page_insert>
{
	// LAB 3: Your code here.
	// (But only if you need it for load_icode.)
	//
	void *begin = ROUNDDOWN(va, PGSIZE), *end = ROUNDUP(va+len, PGSIZE);
	for (; begin < end; begin += PGSIZE) {
f0102b62:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102b68:	83 c4 10             	add    $0x10,%esp
f0102b6b:	39 f3                	cmp    %esi,%ebx
f0102b6d:	72 bf                	jb     f0102b2e <region_alloc+0x22>

	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
}
f0102b6f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b72:	5b                   	pop    %ebx
f0102b73:	5e                   	pop    %esi
f0102b74:	5f                   	pop    %edi
f0102b75:	5d                   	pop    %ebp
f0102b76:	c3                   	ret    

f0102b77 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102b77:	55                   	push   %ebp
f0102b78:	89 e5                	mov    %esp,%ebp
f0102b7a:	8b 55 08             	mov    0x8(%ebp),%edx
f0102b7d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102b80:	85 d2                	test   %edx,%edx
f0102b82:	75 11                	jne    f0102b95 <envid2env+0x1e>
		*env_store = curenv;
f0102b84:	a1 a8 e4 17 f0       	mov    0xf017e4a8,%eax
f0102b89:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102b8c:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102b8e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b93:	eb 5e                	jmp    f0102bf3 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102b95:	89 d0                	mov    %edx,%eax
f0102b97:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102b9c:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102b9f:	c1 e0 05             	shl    $0x5,%eax
f0102ba2:	03 05 ac e4 17 f0    	add    0xf017e4ac,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102ba8:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0102bac:	74 05                	je     f0102bb3 <envid2env+0x3c>
f0102bae:	39 50 48             	cmp    %edx,0x48(%eax)
f0102bb1:	74 10                	je     f0102bc3 <envid2env+0x4c>
		*env_store = 0;
f0102bb3:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102bb6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102bbc:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102bc1:	eb 30                	jmp    f0102bf3 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102bc3:	84 c9                	test   %cl,%cl
f0102bc5:	74 22                	je     f0102be9 <envid2env+0x72>
f0102bc7:	8b 15 a8 e4 17 f0    	mov    0xf017e4a8,%edx
f0102bcd:	39 d0                	cmp    %edx,%eax
f0102bcf:	74 18                	je     f0102be9 <envid2env+0x72>
f0102bd1:	8b 4a 48             	mov    0x48(%edx),%ecx
f0102bd4:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f0102bd7:	74 10                	je     f0102be9 <envid2env+0x72>
		*env_store = 0;
f0102bd9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102bdc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102be2:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102be7:	eb 0a                	jmp    f0102bf3 <envid2env+0x7c>
	}

	*env_store = e;
f0102be9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102bec:	89 01                	mov    %eax,(%ecx)
	return 0;
f0102bee:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102bf3:	5d                   	pop    %ebp
f0102bf4:	c3                   	ret    

f0102bf5 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102bf5:	55                   	push   %ebp
f0102bf6:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0102bf8:	b8 00 c3 11 f0       	mov    $0xf011c300,%eax
f0102bfd:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0102c00:	b8 23 00 00 00       	mov    $0x23,%eax
f0102c05:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0102c07:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0102c09:	b0 10                	mov    $0x10,%al
f0102c0b:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0102c0d:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0102c0f:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f0102c11:	ea 18 2c 10 f0 08 00 	ljmp   $0x8,$0xf0102c18
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0102c18:	b0 00                	mov    $0x0,%al
f0102c1a:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102c1d:	5d                   	pop    %ebp
f0102c1e:	c3                   	ret    

f0102c1f <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102c1f:	55                   	push   %ebp
f0102c20:	89 e5                	mov    %esp,%ebp
f0102c22:	56                   	push   %esi
f0102c23:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i = NENV - 1; i >= 0; --i){
		envs[i].env_id = 0;
f0102c24:	8b 35 ac e4 17 f0    	mov    0xf017e4ac,%esi
f0102c2a:	8b 15 b0 e4 17 f0    	mov    0xf017e4b0,%edx
f0102c30:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f0102c36:	8d 5e a0             	lea    -0x60(%esi),%ebx
f0102c39:	89 c1                	mov    %eax,%ecx
f0102c3b:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
//		envs[i].env_runs = 0;
//		envs[i].env_type = ENV_TYPE_USER;
//		envs[i].env_status = ENV_FREE;
		envs[i].env_link = env_free_list;
f0102c42:	89 50 44             	mov    %edx,0x44(%eax)
f0102c45:	83 e8 60             	sub    $0x60,%eax
		env_free_list = envs + i;
f0102c48:	89 ca                	mov    %ecx,%edx
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i = NENV - 1; i >= 0; --i){
f0102c4a:	39 d8                	cmp    %ebx,%eax
f0102c4c:	75 eb                	jne    f0102c39 <env_init+0x1a>
f0102c4e:	89 35 b0 e4 17 f0    	mov    %esi,0xf017e4b0
		envs[i].env_link = env_free_list;
		env_free_list = envs + i;
	}

	// Per-CPU part of the initialization
	env_init_percpu();
f0102c54:	e8 9c ff ff ff       	call   f0102bf5 <env_init_percpu>
}
f0102c59:	5b                   	pop    %ebx
f0102c5a:	5e                   	pop    %esi
f0102c5b:	5d                   	pop    %ebp
f0102c5c:	c3                   	ret    

f0102c5d <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102c5d:	55                   	push   %ebp
f0102c5e:	89 e5                	mov    %esp,%ebp
f0102c60:	53                   	push   %ebx
f0102c61:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102c64:	8b 1d b0 e4 17 f0    	mov    0xf017e4b0,%ebx
f0102c6a:	85 db                	test   %ebx,%ebx
f0102c6c:	0f 84 43 01 00 00    	je     f0102db5 <env_alloc+0x158>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102c72:	83 ec 0c             	sub    $0xc,%esp
f0102c75:	6a 01                	push   $0x1
f0102c77:	e8 d3 e2 ff ff       	call   f0100f4f <page_alloc>
f0102c7c:	83 c4 10             	add    $0x10,%esp
f0102c7f:	85 c0                	test   %eax,%eax
f0102c81:	0f 84 35 01 00 00    	je     f0102dbc <env_alloc+0x15f>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f0102c87:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
f0102c8c:	2b 05 8c f1 17 f0    	sub    0xf017f18c,%eax
f0102c92:	c1 f8 03             	sar    $0x3,%eax
f0102c95:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c98:	89 c2                	mov    %eax,%edx
f0102c9a:	c1 ea 0c             	shr    $0xc,%edx
f0102c9d:	3b 15 84 f1 17 f0    	cmp    0xf017f184,%edx
f0102ca3:	72 12                	jb     f0102cb7 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ca5:	50                   	push   %eax
f0102ca6:	68 88 53 10 f0       	push   $0xf0105388
f0102cab:	6a 56                	push   $0x56
f0102cad:	68 7b 5c 10 f0       	push   $0xf0105c7b
f0102cb2:	e8 e9 d3 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0102cb7:	2d 00 00 00 10       	sub    $0x10000000,%eax
	e->env_pgdir = (pde_t *) page2kva(p);
f0102cbc:	89 43 5c             	mov    %eax,0x5c(%ebx)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f0102cbf:	83 ec 04             	sub    $0x4,%esp
f0102cc2:	68 00 10 00 00       	push   $0x1000
f0102cc7:	ff 35 88 f1 17 f0    	pushl  0xf017f188
f0102ccd:	50                   	push   %eax
f0102cce:	e8 e5 1a 00 00       	call   f01047b8 <memcpy>

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102cd3:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102cd6:	83 c4 10             	add    $0x10,%esp
f0102cd9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102cde:	77 15                	ja     f0102cf5 <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ce0:	50                   	push   %eax
f0102ce1:	68 ac 53 10 f0       	push   $0xf01053ac
f0102ce6:	68 c5 00 00 00       	push   $0xc5
f0102ceb:	68 81 5f 10 f0       	push   $0xf0105f81
f0102cf0:	e8 ab d3 ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102cf5:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102cfb:	83 ca 05             	or     $0x5,%edx
f0102cfe:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102d04:	8b 43 48             	mov    0x48(%ebx),%eax
f0102d07:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102d0c:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102d11:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102d16:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102d19:	89 da                	mov    %ebx,%edx
f0102d1b:	2b 15 ac e4 17 f0    	sub    0xf017e4ac,%edx
f0102d21:	c1 fa 05             	sar    $0x5,%edx
f0102d24:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102d2a:	09 d0                	or     %edx,%eax
f0102d2c:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102d2f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d32:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102d35:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102d3c:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102d43:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102d4a:	83 ec 04             	sub    $0x4,%esp
f0102d4d:	6a 44                	push   $0x44
f0102d4f:	6a 00                	push   $0x0
f0102d51:	53                   	push   %ebx
f0102d52:	e8 ac 19 00 00       	call   f0104703 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102d57:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102d5d:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102d63:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102d69:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102d70:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102d76:	8b 43 44             	mov    0x44(%ebx),%eax
f0102d79:	a3 b0 e4 17 f0       	mov    %eax,0xf017e4b0
	*newenv_store = e;
f0102d7e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d81:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102d83:	8b 53 48             	mov    0x48(%ebx),%edx
f0102d86:	a1 a8 e4 17 f0       	mov    0xf017e4a8,%eax
f0102d8b:	83 c4 10             	add    $0x10,%esp
f0102d8e:	85 c0                	test   %eax,%eax
f0102d90:	74 05                	je     f0102d97 <env_alloc+0x13a>
f0102d92:	8b 40 48             	mov    0x48(%eax),%eax
f0102d95:	eb 05                	jmp    f0102d9c <env_alloc+0x13f>
f0102d97:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d9c:	83 ec 04             	sub    $0x4,%esp
f0102d9f:	52                   	push   %edx
f0102da0:	50                   	push   %eax
f0102da1:	68 8c 5f 10 f0       	push   $0xf0105f8c
f0102da6:	e8 52 04 00 00       	call   f01031fd <cprintf>
	return 0;
f0102dab:	83 c4 10             	add    $0x10,%esp
f0102dae:	b8 00 00 00 00       	mov    $0x0,%eax
f0102db3:	eb 0c                	jmp    f0102dc1 <env_alloc+0x164>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102db5:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102dba:	eb 05                	jmp    f0102dc1 <env_alloc+0x164>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102dbc:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102dc1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102dc4:	c9                   	leave  
f0102dc5:	c3                   	ret    

f0102dc6 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102dc6:	55                   	push   %ebp
f0102dc7:	89 e5                	mov    %esp,%ebp
f0102dc9:	57                   	push   %edi
f0102dca:	56                   	push   %esi
f0102dcb:	53                   	push   %ebx
f0102dcc:	83 ec 34             	sub    $0x34,%esp
f0102dcf:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env* env;
	int ret = env_alloc(&env, 0);
f0102dd2:	6a 00                	push   $0x0
f0102dd4:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102dd7:	50                   	push   %eax
f0102dd8:	e8 80 fe ff ff       	call   f0102c5d <env_alloc>
	if(ret != 0){
f0102ddd:	83 c4 10             	add    $0x10,%esp
f0102de0:	85 c0                	test   %eax,%eax
f0102de2:	74 17                	je     f0102dfb <env_create+0x35>
		panic("Env_create: allocate a new env failed!\n");
f0102de4:	83 ec 04             	sub    $0x4,%esp
f0102de7:	68 08 60 10 f0       	push   $0xf0106008
f0102dec:	68 b7 01 00 00       	push   $0x1b7
f0102df1:	68 81 5f 10 f0       	push   $0xf0105f81
f0102df6:	e8 a5 d2 ff ff       	call   f01000a0 <_panic>
	}
	load_icode(env, binary);
f0102dfb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102dfe:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// LAB 3: Your code here.
	struct Elf *ELFHDR = (struct Elf *) binary;
	struct Proghdr *ph, *eph;

	if (ELFHDR->e_magic != ELF_MAGIC)
f0102e01:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102e07:	74 17                	je     f0102e20 <env_create+0x5a>
		panic("Not executable!");
f0102e09:	83 ec 04             	sub    $0x4,%esp
f0102e0c:	68 a1 5f 10 f0       	push   $0xf0105fa1
f0102e11:	68 6d 01 00 00       	push   $0x16d
f0102e16:	68 81 5f 10 f0       	push   $0xf0105f81
f0102e1b:	e8 80 d2 ff ff       	call   f01000a0 <_panic>
	
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
f0102e20:	89 fb                	mov    %edi,%ebx
f0102e22:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + ELFHDR->e_phnum;
f0102e25:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0102e29:	c1 e6 05             	shl    $0x5,%esi
f0102e2c:	01 de                	add    %ebx,%esi
	//  The ph->p_filesz bytes from the ELF binary, starting at
	//  'binary + ph->p_offset', should be copied to virtual address
	//  ph->p_va.  Any remaining memory bytes should be cleared to zero.
	//  (The ELF header should have ph->p_filesz <= ph->p_memsz.)
	//  Use functions from the previous lab to allocate and map pages.
	lcr3(PADDR(e->env_pgdir));
f0102e2e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e31:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e34:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102e39:	77 15                	ja     f0102e50 <env_create+0x8a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e3b:	50                   	push   %eax
f0102e3c:	68 ac 53 10 f0       	push   $0xf01053ac
f0102e41:	68 79 01 00 00       	push   $0x179
f0102e46:	68 81 5f 10 f0       	push   $0xf0105f81
f0102e4b:	e8 50 d2 ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102e50:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102e55:	0f 22 d8             	mov    %eax,%cr3
f0102e58:	eb 50                	jmp    f0102eaa <env_create+0xe4>
	//it's silly to use kern_pgdir here.
	for (; ph < eph; ph++)
		if (ph->p_type == ELF_PROG_LOAD) {
f0102e5a:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102e5d:	75 48                	jne    f0102ea7 <env_create+0xe1>
			region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f0102e5f:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102e62:	8b 53 08             	mov    0x8(%ebx),%edx
f0102e65:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e68:	e8 9f fc ff ff       	call   f0102b0c <region_alloc>
			memset((void *)ph->p_va, 0, ph->p_memsz);
f0102e6d:	83 ec 04             	sub    $0x4,%esp
f0102e70:	ff 73 14             	pushl  0x14(%ebx)
f0102e73:	6a 00                	push   $0x0
f0102e75:	ff 73 08             	pushl  0x8(%ebx)
f0102e78:	e8 86 18 00 00       	call   f0104703 <memset>
			memcpy((void *)ph->p_va, binary+ph->p_offset, ph->p_filesz);
f0102e7d:	83 c4 0c             	add    $0xc,%esp
f0102e80:	ff 73 10             	pushl  0x10(%ebx)
f0102e83:	89 f8                	mov    %edi,%eax
f0102e85:	03 43 04             	add    0x4(%ebx),%eax
f0102e88:	50                   	push   %eax
f0102e89:	ff 73 08             	pushl  0x8(%ebx)
f0102e8c:	e8 27 19 00 00       	call   f01047b8 <memcpy>
			//but I'm curious about how exactly p_memsz and p_filesz differs
			cprintf("p_memsz: %x, p_filesz: %x\n", ph->p_memsz, ph->p_filesz);
f0102e91:	83 c4 0c             	add    $0xc,%esp
f0102e94:	ff 73 10             	pushl  0x10(%ebx)
f0102e97:	ff 73 14             	pushl  0x14(%ebx)
f0102e9a:	68 b1 5f 10 f0       	push   $0xf0105fb1
f0102e9f:	e8 59 03 00 00       	call   f01031fd <cprintf>
f0102ea4:	83 c4 10             	add    $0x10,%esp
	//  ph->p_va.  Any remaining memory bytes should be cleared to zero.
	//  (The ELF header should have ph->p_filesz <= ph->p_memsz.)
	//  Use functions from the previous lab to allocate and map pages.
	lcr3(PADDR(e->env_pgdir));
	//it's silly to use kern_pgdir here.
	for (; ph < eph; ph++)
f0102ea7:	83 c3 20             	add    $0x20,%ebx
f0102eaa:	39 de                	cmp    %ebx,%esi
f0102eac:	77 ac                	ja     f0102e5a <env_create+0x94>
			memcpy((void *)ph->p_va, binary+ph->p_offset, ph->p_filesz);
			//but I'm curious about how exactly p_memsz and p_filesz differs
			cprintf("p_memsz: %x, p_filesz: %x\n", ph->p_memsz, ph->p_filesz);
		}
	//we can use this because kern_pgdir is a subset of e->env_pgdir
	lcr3(PADDR(kern_pgdir));
f0102eae:	a1 88 f1 17 f0       	mov    0xf017f188,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102eb3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102eb8:	77 15                	ja     f0102ecf <env_create+0x109>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102eba:	50                   	push   %eax
f0102ebb:	68 ac 53 10 f0       	push   $0xf01053ac
f0102ec0:	68 84 01 00 00       	push   $0x184
f0102ec5:	68 81 5f 10 f0       	push   $0xf0105f81
f0102eca:	e8 d1 d1 ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102ecf:	05 00 00 00 10       	add    $0x10000000,%eax
f0102ed4:	0f 22 d8             	mov    %eax,%cr3
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.
	// LAB 3: Your code here.
	e->env_tf.tf_eip = ELFHDR->e_entry;
f0102ed7:	8b 47 18             	mov    0x18(%edi),%eax
f0102eda:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102edd:	89 47 30             	mov    %eax,0x30(%edi)
	region_alloc(e, (void *) (USTACKTOP - PGSIZE), PGSIZE);
f0102ee0:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102ee5:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102eea:	89 f8                	mov    %edi,%eax
f0102eec:	e8 1b fc ff ff       	call   f0102b0c <region_alloc>
	int ret = env_alloc(&env, 0);
	if(ret != 0){
		panic("Env_create: allocate a new env failed!\n");
	}
	load_icode(env, binary);
	cprintf("env_create: finished!\n");
f0102ef1:	83 ec 0c             	sub    $0xc,%esp
f0102ef4:	68 cc 5f 10 f0       	push   $0xf0105fcc
f0102ef9:	e8 ff 02 00 00       	call   f01031fd <cprintf>
	env->env_type = ENV_TYPE_USER;	
f0102efe:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102f01:	c7 40 50 00 00 00 00 	movl   $0x0,0x50(%eax)
	env->env_parent_id = 0;
f0102f08:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
f0102f0f:	83 c4 10             	add    $0x10,%esp
}
f0102f12:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f15:	5b                   	pop    %ebx
f0102f16:	5e                   	pop    %esi
f0102f17:	5f                   	pop    %edi
f0102f18:	5d                   	pop    %ebp
f0102f19:	c3                   	ret    

f0102f1a <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102f1a:	55                   	push   %ebp
f0102f1b:	89 e5                	mov    %esp,%ebp
f0102f1d:	57                   	push   %edi
f0102f1e:	56                   	push   %esi
f0102f1f:	53                   	push   %ebx
f0102f20:	83 ec 1c             	sub    $0x1c,%esp
f0102f23:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102f26:	8b 15 a8 e4 17 f0    	mov    0xf017e4a8,%edx
f0102f2c:	39 d7                	cmp    %edx,%edi
f0102f2e:	75 29                	jne    f0102f59 <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102f30:	a1 88 f1 17 f0       	mov    0xf017f188,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f35:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102f3a:	77 15                	ja     f0102f51 <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f3c:	50                   	push   %eax
f0102f3d:	68 ac 53 10 f0       	push   $0xf01053ac
f0102f42:	68 cd 01 00 00       	push   $0x1cd
f0102f47:	68 81 5f 10 f0       	push   $0xf0105f81
f0102f4c:	e8 4f d1 ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102f51:	05 00 00 00 10       	add    $0x10000000,%eax
f0102f56:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102f59:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102f5c:	85 d2                	test   %edx,%edx
f0102f5e:	74 05                	je     f0102f65 <env_free+0x4b>
f0102f60:	8b 42 48             	mov    0x48(%edx),%eax
f0102f63:	eb 05                	jmp    f0102f6a <env_free+0x50>
f0102f65:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f6a:	83 ec 04             	sub    $0x4,%esp
f0102f6d:	51                   	push   %ecx
f0102f6e:	50                   	push   %eax
f0102f6f:	68 e3 5f 10 f0       	push   $0xf0105fe3
f0102f74:	e8 84 02 00 00       	call   f01031fd <cprintf>
f0102f79:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102f7c:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102f83:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102f86:	89 d0                	mov    %edx,%eax
f0102f88:	c1 e0 02             	shl    $0x2,%eax
f0102f8b:	89 45 d8             	mov    %eax,-0x28(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102f8e:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102f91:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102f94:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102f9a:	0f 84 a8 00 00 00    	je     f0103048 <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102fa0:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102fa6:	89 f0                	mov    %esi,%eax
f0102fa8:	c1 e8 0c             	shr    $0xc,%eax
f0102fab:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0102fae:	3b 05 84 f1 17 f0    	cmp    0xf017f184,%eax
f0102fb4:	72 15                	jb     f0102fcb <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102fb6:	56                   	push   %esi
f0102fb7:	68 88 53 10 f0       	push   $0xf0105388
f0102fbc:	68 dc 01 00 00       	push   $0x1dc
f0102fc1:	68 81 5f 10 f0       	push   $0xf0105f81
f0102fc6:	e8 d5 d0 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102fcb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102fce:	c1 e0 16             	shl    $0x16,%eax
f0102fd1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102fd4:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102fd9:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102fe0:	01 
f0102fe1:	74 17                	je     f0102ffa <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102fe3:	83 ec 08             	sub    $0x8,%esp
f0102fe6:	89 d8                	mov    %ebx,%eax
f0102fe8:	c1 e0 0c             	shl    $0xc,%eax
f0102feb:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102fee:	50                   	push   %eax
f0102fef:	ff 77 5c             	pushl  0x5c(%edi)
f0102ff2:	e8 a0 e1 ff ff       	call   f0101197 <page_remove>
f0102ff7:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102ffa:	83 c3 01             	add    $0x1,%ebx
f0102ffd:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103003:	75 d4                	jne    f0102fd9 <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103005:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103008:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010300b:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103012:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103015:	3b 05 84 f1 17 f0    	cmp    0xf017f184,%eax
f010301b:	72 14                	jb     f0103031 <env_free+0x117>
		panic("pa2page called with invalid pa");
f010301d:	83 ec 04             	sub    $0x4,%esp
f0103020:	68 f4 54 10 f0       	push   $0xf01054f4
f0103025:	6a 4f                	push   $0x4f
f0103027:	68 7b 5c 10 f0       	push   $0xf0105c7b
f010302c:	e8 6f d0 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0103031:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103034:	a1 8c f1 17 f0       	mov    0xf017f18c,%eax
f0103039:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010303c:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f010303f:	50                   	push   %eax
f0103040:	e8 bb df ff ff       	call   f0101000 <page_decref>
f0103045:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103048:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f010304c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010304f:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0103054:	0f 85 29 ff ff ff    	jne    f0102f83 <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f010305a:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010305d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103062:	77 15                	ja     f0103079 <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103064:	50                   	push   %eax
f0103065:	68 ac 53 10 f0       	push   $0xf01053ac
f010306a:	68 ea 01 00 00       	push   $0x1ea
f010306f:	68 81 5f 10 f0       	push   $0xf0105f81
f0103074:	e8 27 d0 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0103079:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103080:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103085:	c1 e8 0c             	shr    $0xc,%eax
f0103088:	3b 05 84 f1 17 f0    	cmp    0xf017f184,%eax
f010308e:	72 14                	jb     f01030a4 <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0103090:	83 ec 04             	sub    $0x4,%esp
f0103093:	68 f4 54 10 f0       	push   $0xf01054f4
f0103098:	6a 4f                	push   $0x4f
f010309a:	68 7b 5c 10 f0       	push   $0xf0105c7b
f010309f:	e8 fc cf ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f01030a4:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f01030a7:	8b 15 8c f1 17 f0    	mov    0xf017f18c,%edx
f01030ad:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f01030b0:	50                   	push   %eax
f01030b1:	e8 4a df ff ff       	call   f0101000 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f01030b6:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f01030bd:	a1 b0 e4 17 f0       	mov    0xf017e4b0,%eax
f01030c2:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f01030c5:	89 3d b0 e4 17 f0    	mov    %edi,0xf017e4b0
f01030cb:	83 c4 10             	add    $0x10,%esp
}
f01030ce:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01030d1:	5b                   	pop    %ebx
f01030d2:	5e                   	pop    %esi
f01030d3:	5f                   	pop    %edi
f01030d4:	5d                   	pop    %ebp
f01030d5:	c3                   	ret    

f01030d6 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f01030d6:	55                   	push   %ebp
f01030d7:	89 e5                	mov    %esp,%ebp
f01030d9:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f01030dc:	ff 75 08             	pushl  0x8(%ebp)
f01030df:	e8 36 fe ff ff       	call   f0102f1a <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f01030e4:	c7 04 24 30 60 10 f0 	movl   $0xf0106030,(%esp)
f01030eb:	e8 0d 01 00 00       	call   f01031fd <cprintf>
f01030f0:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f01030f3:	83 ec 0c             	sub    $0xc,%esp
f01030f6:	6a 00                	push   $0x0
f01030f8:	e8 93 d8 ff ff       	call   f0100990 <monitor>
f01030fd:	83 c4 10             	add    $0x10,%esp
f0103100:	eb f1                	jmp    f01030f3 <env_destroy+0x1d>

f0103102 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103102:	55                   	push   %ebp
f0103103:	89 e5                	mov    %esp,%ebp
f0103105:	83 ec 0c             	sub    $0xc,%esp
	__asm __volatile("movl %0,%%esp\n"
f0103108:	8b 65 08             	mov    0x8(%ebp),%esp
f010310b:	61                   	popa   
f010310c:	07                   	pop    %es
f010310d:	1f                   	pop    %ds
f010310e:	83 c4 08             	add    $0x8,%esp
f0103111:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103112:	68 f9 5f 10 f0       	push   $0xf0105ff9
f0103117:	68 12 02 00 00       	push   $0x212
f010311c:	68 81 5f 10 f0       	push   $0xf0105f81
f0103121:	e8 7a cf ff ff       	call   f01000a0 <_panic>

f0103126 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103126:	55                   	push   %ebp
f0103127:	89 e5                	mov    %esp,%ebp
f0103129:	83 ec 08             	sub    $0x8,%esp
f010312c:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(e != curenv){ //a context switch, since a new environment is running
f010312f:	8b 15 a8 e4 17 f0    	mov    0xf017e4a8,%edx
f0103135:	39 d0                	cmp    %edx,%eax
f0103137:	74 48                	je     f0103181 <env_run+0x5b>
		if(curenv != NULL){
f0103139:	85 d2                	test   %edx,%edx
f010313b:	74 0d                	je     f010314a <env_run+0x24>
			if(curenv->env_status == ENV_RUNNING) curenv->env_status = ENV_RUNNABLE;
f010313d:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0103141:	75 07                	jne    f010314a <env_run+0x24>
f0103143:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
		}
		curenv = e;
f010314a:	a3 a8 e4 17 f0       	mov    %eax,0xf017e4a8
		curenv->env_runs++;
f010314f:	83 40 58 01          	addl   $0x1,0x58(%eax)
		curenv->env_status = ENV_RUNNING;
f0103153:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
		lcr3(PADDR(curenv->env_pgdir));
f010315a:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010315d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103162:	77 15                	ja     f0103179 <env_run+0x53>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103164:	50                   	push   %eax
f0103165:	68 ac 53 10 f0       	push   $0xf01053ac
f010316a:	68 37 02 00 00       	push   $0x237
f010316f:	68 81 5f 10 f0       	push   $0xf0105f81
f0103174:	e8 27 cf ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103179:	05 00 00 00 10       	add    $0x10000000,%eax
f010317e:	0f 22 d8             	mov    %eax,%cr3
	}
	cprintf("up to now everything goes well!\n");
f0103181:	83 ec 0c             	sub    $0xc,%esp
f0103184:	68 68 60 10 f0       	push   $0xf0106068
f0103189:	e8 6f 00 00 00       	call   f01031fd <cprintf>
	env_pop_tf(&curenv->env_tf);
f010318e:	83 c4 04             	add    $0x4,%esp
f0103191:	ff 35 a8 e4 17 f0    	pushl  0xf017e4a8
f0103197:	e8 66 ff ff ff       	call   f0103102 <env_pop_tf>

f010319c <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010319c:	55                   	push   %ebp
f010319d:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010319f:	ba 70 00 00 00       	mov    $0x70,%edx
f01031a4:	8b 45 08             	mov    0x8(%ebp),%eax
f01031a7:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01031a8:	b2 71                	mov    $0x71,%dl
f01031aa:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01031ab:	0f b6 c0             	movzbl %al,%eax
}
f01031ae:	5d                   	pop    %ebp
f01031af:	c3                   	ret    

f01031b0 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01031b0:	55                   	push   %ebp
f01031b1:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01031b3:	ba 70 00 00 00       	mov    $0x70,%edx
f01031b8:	8b 45 08             	mov    0x8(%ebp),%eax
f01031bb:	ee                   	out    %al,(%dx)
f01031bc:	b2 71                	mov    $0x71,%dl
f01031be:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031c1:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01031c2:	5d                   	pop    %ebp
f01031c3:	c3                   	ret    

f01031c4 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01031c4:	55                   	push   %ebp
f01031c5:	89 e5                	mov    %esp,%ebp
f01031c7:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01031ca:	ff 75 08             	pushl  0x8(%ebp)
f01031cd:	e8 22 d4 ff ff       	call   f01005f4 <cputchar>
f01031d2:	83 c4 10             	add    $0x10,%esp
	*cnt++;
}
f01031d5:	c9                   	leave  
f01031d6:	c3                   	ret    

f01031d7 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01031d7:	55                   	push   %ebp
f01031d8:	89 e5                	mov    %esp,%ebp
f01031da:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01031dd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01031e4:	ff 75 0c             	pushl  0xc(%ebp)
f01031e7:	ff 75 08             	pushl  0x8(%ebp)
f01031ea:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01031ed:	50                   	push   %eax
f01031ee:	68 c4 31 10 f0       	push   $0xf01031c4
f01031f3:	e8 c6 0b 00 00       	call   f0103dbe <vprintfmt>
	return cnt;
}
f01031f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01031fb:	c9                   	leave  
f01031fc:	c3                   	ret    

f01031fd <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01031fd:	55                   	push   %ebp
f01031fe:	89 e5                	mov    %esp,%ebp
f0103200:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103203:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103206:	50                   	push   %eax
f0103207:	ff 75 08             	pushl  0x8(%ebp)
f010320a:	e8 c8 ff ff ff       	call   f01031d7 <vcprintf>
	va_end(ap);

	return cnt;
}
f010320f:	c9                   	leave  
f0103210:	c3                   	ret    

f0103211 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103211:	55                   	push   %ebp
f0103212:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103214:	b8 00 ed 17 f0       	mov    $0xf017ed00,%eax
f0103219:	c7 05 04 ed 17 f0 00 	movl   $0xf0000000,0xf017ed04
f0103220:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0103223:	66 c7 05 08 ed 17 f0 	movw   $0x10,0xf017ed08
f010322a:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f010322c:	66 c7 05 48 c3 11 f0 	movw   $0x68,0xf011c348
f0103233:	68 00 
f0103235:	66 a3 4a c3 11 f0    	mov    %ax,0xf011c34a
f010323b:	89 c2                	mov    %eax,%edx
f010323d:	c1 ea 10             	shr    $0x10,%edx
f0103240:	88 15 4c c3 11 f0    	mov    %dl,0xf011c34c
f0103246:	c6 05 4e c3 11 f0 40 	movb   $0x40,0xf011c34e
f010324d:	c1 e8 18             	shr    $0x18,%eax
f0103250:	a2 4f c3 11 f0       	mov    %al,0xf011c34f
					sizeof(struct Taskstate), 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103255:	c6 05 4d c3 11 f0 89 	movb   $0x89,0xf011c34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f010325c:	b8 28 00 00 00       	mov    $0x28,%eax
f0103261:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0103264:	b8 50 c3 11 f0       	mov    $0xf011c350,%eax
f0103269:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f010326c:	5d                   	pop    %ebp
f010326d:	c3                   	ret    

f010326e <trap_init>:



void
trap_init(void)
{
f010326e:	55                   	push   %ebp
f010326f:	89 e5                	mov    %esp,%ebp
f0103271:	57                   	push   %edi
f0103272:	56                   	push   %esi
f0103273:	53                   	push   %ebx
f0103274:	83 ec 34             	sub    $0x34,%esp
	// SETGATE(idt[14], 0, GD_KT, th14, 0);
	// SETGATE(idt[16], 0, GD_KT, th16, 0);

	// Challenge:
	extern void (*funs[])();
	cprintf("funs %x\n", funs);
f0103277:	68 58 c3 11 f0       	push   $0xf011c358
f010327c:	68 89 60 10 f0       	push   $0xf0106089
f0103281:	e8 77 ff ff ff       	call   f01031fd <cprintf>
	cprintf("funs[0] %x\n", funs[0]);
f0103286:	83 c4 08             	add    $0x8,%esp
f0103289:	ff 35 58 c3 11 f0    	pushl  0xf011c358
f010328f:	68 92 60 10 f0       	push   $0xf0106092
f0103294:	e8 64 ff ff ff       	call   f01031fd <cprintf>
	cprintf("funs[48] %x\n", funs[48]);
f0103299:	83 c4 08             	add    $0x8,%esp
f010329c:	ff 35 18 c4 11 f0    	pushl  0xf011c418
f01032a2:	68 9e 60 10 f0       	push   $0xf010609e
f01032a7:	e8 51 ff ff ff       	call   f01031fd <cprintf>
f01032ac:	83 c4 10             	add    $0x10,%esp
	int i;
	for (i = 0; i <= 16; ++i)
f01032af:	ba 00 00 00 00       	mov    $0x0,%edx
f01032b4:	e9 83 00 00 00       	jmp    f010333c <trap_init+0xce>
		if (i==T_BRKPT)
f01032b9:	83 fa 03             	cmp    $0x3,%edx
f01032bc:	75 2f                	jne    f01032ed <trap_init+0x7f>
			SETGATE(idt[i], 0, GD_KT, funs[i], 3)
f01032be:	8b 1d 64 c3 11 f0    	mov    0xf011c364,%ebx
f01032c4:	89 df                	mov    %ebx,%edi
f01032c6:	c1 eb 10             	shr    $0x10,%ebx
f01032c9:	89 5d c8             	mov    %ebx,-0x38(%ebp)
	extern void (*funs[])();
	cprintf("funs %x\n", funs);
	cprintf("funs[0] %x\n", funs[0]);
	cprintf("funs[48] %x\n", funs[48]);
	int i;
	for (i = 0; i <= 16; ++i)
f01032cc:	b2 04                	mov    $0x4,%dl
		if (i==T_BRKPT)
			SETGATE(idt[i], 0, GD_KT, funs[i], 3)
f01032ce:	be 08 00 00 00       	mov    $0x8,%esi
f01032d3:	c6 45 e7 00          	movb   $0x0,-0x19(%ebp)
f01032d7:	c6 45 e6 00          	movb   $0x0,-0x1a(%ebp)
f01032db:	c6 45 e5 0e          	movb   $0xe,-0x1b(%ebp)
f01032df:	b9 00 00 00 00       	mov    $0x0,%ecx
f01032e4:	b8 03 00 00 00       	mov    $0x3,%eax
f01032e9:	c6 45 e4 01          	movb   $0x1,-0x1c(%ebp)
f01032ed:	66 89 3d d8 e4 17 f0 	mov    %di,0xf017e4d8
f01032f4:	66 89 35 da e4 17 f0 	mov    %si,0xf017e4da
f01032fb:	0f b6 75 e6          	movzbl -0x1a(%ebp),%esi
f01032ff:	c1 e6 05             	shl    $0x5,%esi
f0103302:	0f b6 7d e7          	movzbl -0x19(%ebp),%edi
f0103306:	09 f7                	or     %esi,%edi
f0103308:	89 fb                	mov    %edi,%ebx
f010330a:	88 1d dc e4 17 f0    	mov    %bl,0xf017e4dc
f0103310:	83 e1 01             	and    $0x1,%ecx
f0103313:	c1 e1 04             	shl    $0x4,%ecx
f0103316:	83 e1 10             	and    $0x10,%ecx
f0103319:	83 e0 03             	and    $0x3,%eax
f010331c:	c1 e0 05             	shl    $0x5,%eax
f010331f:	0a 4d e5             	or     -0x1b(%ebp),%cl
f0103322:	0f b6 75 e4          	movzbl -0x1c(%ebp),%esi
f0103326:	c1 e6 07             	shl    $0x7,%esi
f0103329:	09 c8                	or     %ecx,%eax
f010332b:	09 f0                	or     %esi,%eax
f010332d:	a2 dd e4 17 f0       	mov    %al,0xf017e4dd
f0103332:	0f b7 45 c8          	movzwl -0x38(%ebp),%eax
f0103336:	66 a3 de e4 17 f0    	mov    %ax,0xf017e4de
		else if (i!=2 && i!=15) {
f010333c:	83 fa 0f             	cmp    $0xf,%edx
f010333f:	74 39                	je     f010337a <trap_init+0x10c>
f0103341:	83 fa 02             	cmp    $0x2,%edx
f0103344:	74 34                	je     f010337a <trap_init+0x10c>
			SETGATE(idt[i], 0, GD_KT, funs[i], 0);
f0103346:	8b 04 95 58 c3 11 f0 	mov    -0xfee3ca8(,%edx,4),%eax
f010334d:	66 89 04 d5 c0 e4 17 	mov    %ax,-0xfe81b40(,%edx,8)
f0103354:	f0 
f0103355:	66 c7 04 d5 c2 e4 17 	movw   $0x8,-0xfe81b3e(,%edx,8)
f010335c:	f0 08 00 
f010335f:	c6 04 d5 c4 e4 17 f0 	movb   $0x0,-0xfe81b3c(,%edx,8)
f0103366:	00 
f0103367:	c6 04 d5 c5 e4 17 f0 	movb   $0x8e,-0xfe81b3b(,%edx,8)
f010336e:	8e 
f010336f:	c1 e8 10             	shr    $0x10,%eax
f0103372:	66 89 04 d5 c6 e4 17 	mov    %ax,-0xfe81b3a(,%edx,8)
f0103379:	f0 
f010337a:	0f b7 3d d8 e4 17 f0 	movzwl 0xf017e4d8,%edi
f0103381:	0f b7 35 da e4 17 f0 	movzwl 0xf017e4da,%esi
f0103388:	0f b6 05 dc e4 17 f0 	movzbl 0xf017e4dc,%eax
f010338f:	89 c3                	mov    %eax,%ebx
f0103391:	83 e3 1f             	and    $0x1f,%ebx
f0103394:	88 5d e7             	mov    %bl,-0x19(%ebp)
f0103397:	c0 e8 05             	shr    $0x5,%al
f010339a:	88 45 e6             	mov    %al,-0x1a(%ebp)
f010339d:	0f b6 1d dd e4 17 f0 	movzbl 0xf017e4dd,%ebx
f01033a4:	89 d8                	mov    %ebx,%eax
f01033a6:	83 e0 0f             	and    $0xf,%eax
f01033a9:	88 45 e5             	mov    %al,-0x1b(%ebp)
f01033ac:	89 d9                	mov    %ebx,%ecx
f01033ae:	c0 e9 04             	shr    $0x4,%cl
f01033b1:	83 e1 01             	and    $0x1,%ecx
f01033b4:	89 d8                	mov    %ebx,%eax
f01033b6:	c0 e8 05             	shr    $0x5,%al
f01033b9:	83 e0 03             	and    $0x3,%eax
f01033bc:	c0 eb 07             	shr    $0x7,%bl
f01033bf:	88 5d e4             	mov    %bl,-0x1c(%ebp)
f01033c2:	0f b7 1d de e4 17 f0 	movzwl 0xf017e4de,%ebx
f01033c9:	66 89 5d c8          	mov    %bx,-0x38(%ebp)
	extern void (*funs[])();
	cprintf("funs %x\n", funs);
	cprintf("funs[0] %x\n", funs[0]);
	cprintf("funs[48] %x\n", funs[48]);
	int i;
	for (i = 0; i <= 16; ++i)
f01033cd:	83 c2 01             	add    $0x1,%edx
f01033d0:	83 fa 10             	cmp    $0x10,%edx
f01033d3:	0f 8e e0 fe ff ff    	jle    f01032b9 <trap_init+0x4b>
f01033d9:	0f b6 75 e6          	movzbl -0x1a(%ebp),%esi
f01033dd:	c1 e6 05             	shl    $0x5,%esi
f01033e0:	0f b6 55 e7          	movzbl -0x19(%ebp),%edx
f01033e4:	09 f2                	or     %esi,%edx
f01033e6:	88 15 dc e4 17 f0    	mov    %dl,0xf017e4dc
f01033ec:	83 e1 01             	and    $0x1,%ecx
f01033ef:	c1 e1 04             	shl    $0x4,%ecx
f01033f2:	83 e1 10             	and    $0x10,%ecx
f01033f5:	c1 e0 05             	shl    $0x5,%eax
f01033f8:	0a 4d e5             	or     -0x1b(%ebp),%cl
f01033fb:	0f b6 55 e4          	movzbl -0x1c(%ebp),%edx
f01033ff:	c1 e2 07             	shl    $0x7,%edx
f0103402:	09 c8                	or     %ecx,%eax
f0103404:	09 d0                	or     %edx,%eax
f0103406:	a2 dd e4 17 f0       	mov    %al,0xf017e4dd
		if (i==T_BRKPT)
			SETGATE(idt[i], 0, GD_KT, funs[i], 3)
		else if (i!=2 && i!=15) {
			SETGATE(idt[i], 0, GD_KT, funs[i], 0);
		}
	SETGATE(idt[48], 0, GD_KT, funs[48], 3);
f010340b:	a1 18 c4 11 f0       	mov    0xf011c418,%eax
f0103410:	66 a3 40 e6 17 f0    	mov    %ax,0xf017e640
f0103416:	66 c7 05 42 e6 17 f0 	movw   $0x8,0xf017e642
f010341d:	08 00 
f010341f:	c6 05 44 e6 17 f0 00 	movb   $0x0,0xf017e644
f0103426:	c6 05 45 e6 17 f0 ee 	movb   $0xee,0xf017e645
f010342d:	c1 e8 10             	shr    $0x10,%eax
f0103430:	66 a3 46 e6 17 f0    	mov    %ax,0xf017e646
	// Per-CPU setup 
	trap_init_percpu();
f0103436:	e8 d6 fd ff ff       	call   f0103211 <trap_init_percpu>
}
f010343b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010343e:	5b                   	pop    %ebx
f010343f:	5e                   	pop    %esi
f0103440:	5f                   	pop    %edi
f0103441:	5d                   	pop    %ebp
f0103442:	c3                   	ret    

f0103443 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103443:	55                   	push   %ebp
f0103444:	89 e5                	mov    %esp,%ebp
f0103446:	53                   	push   %ebx
f0103447:	83 ec 0c             	sub    $0xc,%esp
f010344a:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f010344d:	ff 33                	pushl  (%ebx)
f010344f:	68 ab 60 10 f0       	push   $0xf01060ab
f0103454:	e8 a4 fd ff ff       	call   f01031fd <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103459:	83 c4 08             	add    $0x8,%esp
f010345c:	ff 73 04             	pushl  0x4(%ebx)
f010345f:	68 ba 60 10 f0       	push   $0xf01060ba
f0103464:	e8 94 fd ff ff       	call   f01031fd <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103469:	83 c4 08             	add    $0x8,%esp
f010346c:	ff 73 08             	pushl  0x8(%ebx)
f010346f:	68 c9 60 10 f0       	push   $0xf01060c9
f0103474:	e8 84 fd ff ff       	call   f01031fd <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103479:	83 c4 08             	add    $0x8,%esp
f010347c:	ff 73 0c             	pushl  0xc(%ebx)
f010347f:	68 d8 60 10 f0       	push   $0xf01060d8
f0103484:	e8 74 fd ff ff       	call   f01031fd <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103489:	83 c4 08             	add    $0x8,%esp
f010348c:	ff 73 10             	pushl  0x10(%ebx)
f010348f:	68 e7 60 10 f0       	push   $0xf01060e7
f0103494:	e8 64 fd ff ff       	call   f01031fd <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103499:	83 c4 08             	add    $0x8,%esp
f010349c:	ff 73 14             	pushl  0x14(%ebx)
f010349f:	68 f6 60 10 f0       	push   $0xf01060f6
f01034a4:	e8 54 fd ff ff       	call   f01031fd <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f01034a9:	83 c4 08             	add    $0x8,%esp
f01034ac:	ff 73 18             	pushl  0x18(%ebx)
f01034af:	68 05 61 10 f0       	push   $0xf0106105
f01034b4:	e8 44 fd ff ff       	call   f01031fd <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f01034b9:	83 c4 08             	add    $0x8,%esp
f01034bc:	ff 73 1c             	pushl  0x1c(%ebx)
f01034bf:	68 14 61 10 f0       	push   $0xf0106114
f01034c4:	e8 34 fd ff ff       	call   f01031fd <cprintf>
f01034c9:	83 c4 10             	add    $0x10,%esp
}
f01034cc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01034cf:	c9                   	leave  
f01034d0:	c3                   	ret    

f01034d1 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f01034d1:	55                   	push   %ebp
f01034d2:	89 e5                	mov    %esp,%ebp
f01034d4:	56                   	push   %esi
f01034d5:	53                   	push   %ebx
f01034d6:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f01034d9:	83 ec 08             	sub    $0x8,%esp
f01034dc:	53                   	push   %ebx
f01034dd:	68 5d 62 10 f0       	push   $0xf010625d
f01034e2:	e8 16 fd ff ff       	call   f01031fd <cprintf>
	print_regs(&tf->tf_regs);
f01034e7:	89 1c 24             	mov    %ebx,(%esp)
f01034ea:	e8 54 ff ff ff       	call   f0103443 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f01034ef:	83 c4 08             	add    $0x8,%esp
f01034f2:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f01034f6:	50                   	push   %eax
f01034f7:	68 65 61 10 f0       	push   $0xf0106165
f01034fc:	e8 fc fc ff ff       	call   f01031fd <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103501:	83 c4 08             	add    $0x8,%esp
f0103504:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103508:	50                   	push   %eax
f0103509:	68 78 61 10 f0       	push   $0xf0106178
f010350e:	e8 ea fc ff ff       	call   f01031fd <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103513:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103516:	83 c4 10             	add    $0x10,%esp
f0103519:	83 f8 13             	cmp    $0x13,%eax
f010351c:	77 09                	ja     f0103527 <print_trapframe+0x56>
		return excnames[trapno];
f010351e:	8b 14 85 80 64 10 f0 	mov    -0xfef9b80(,%eax,4),%edx
f0103525:	eb 10                	jmp    f0103537 <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f0103527:	83 f8 30             	cmp    $0x30,%eax
f010352a:	b9 2f 61 10 f0       	mov    $0xf010612f,%ecx
f010352f:	ba 23 61 10 f0       	mov    $0xf0106123,%edx
f0103534:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103537:	83 ec 04             	sub    $0x4,%esp
f010353a:	52                   	push   %edx
f010353b:	50                   	push   %eax
f010353c:	68 8b 61 10 f0       	push   $0xf010618b
f0103541:	e8 b7 fc ff ff       	call   f01031fd <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103546:	83 c4 10             	add    $0x10,%esp
f0103549:	3b 1d c0 ec 17 f0    	cmp    0xf017ecc0,%ebx
f010354f:	75 1a                	jne    f010356b <print_trapframe+0x9a>
f0103551:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103555:	75 14                	jne    f010356b <print_trapframe+0x9a>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103557:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f010355a:	83 ec 08             	sub    $0x8,%esp
f010355d:	50                   	push   %eax
f010355e:	68 9d 61 10 f0       	push   $0xf010619d
f0103563:	e8 95 fc ff ff       	call   f01031fd <cprintf>
f0103568:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f010356b:	83 ec 08             	sub    $0x8,%esp
f010356e:	ff 73 2c             	pushl  0x2c(%ebx)
f0103571:	68 ac 61 10 f0       	push   $0xf01061ac
f0103576:	e8 82 fc ff ff       	call   f01031fd <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f010357b:	83 c4 10             	add    $0x10,%esp
f010357e:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103582:	75 49                	jne    f01035cd <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103584:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103587:	89 c2                	mov    %eax,%edx
f0103589:	83 e2 01             	and    $0x1,%edx
f010358c:	ba 49 61 10 f0       	mov    $0xf0106149,%edx
f0103591:	b9 3e 61 10 f0       	mov    $0xf010613e,%ecx
f0103596:	0f 44 ca             	cmove  %edx,%ecx
f0103599:	89 c2                	mov    %eax,%edx
f010359b:	83 e2 02             	and    $0x2,%edx
f010359e:	ba 5b 61 10 f0       	mov    $0xf010615b,%edx
f01035a3:	be 55 61 10 f0       	mov    $0xf0106155,%esi
f01035a8:	0f 45 d6             	cmovne %esi,%edx
f01035ab:	83 e0 04             	and    $0x4,%eax
f01035ae:	be ae 62 10 f0       	mov    $0xf01062ae,%esi
f01035b3:	b8 60 61 10 f0       	mov    $0xf0106160,%eax
f01035b8:	0f 44 c6             	cmove  %esi,%eax
f01035bb:	51                   	push   %ecx
f01035bc:	52                   	push   %edx
f01035bd:	50                   	push   %eax
f01035be:	68 ba 61 10 f0       	push   $0xf01061ba
f01035c3:	e8 35 fc ff ff       	call   f01031fd <cprintf>
f01035c8:	83 c4 10             	add    $0x10,%esp
f01035cb:	eb 10                	jmp    f01035dd <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f01035cd:	83 ec 0c             	sub    $0xc,%esp
f01035d0:	68 3a 5f 10 f0       	push   $0xf0105f3a
f01035d5:	e8 23 fc ff ff       	call   f01031fd <cprintf>
f01035da:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f01035dd:	83 ec 08             	sub    $0x8,%esp
f01035e0:	ff 73 30             	pushl  0x30(%ebx)
f01035e3:	68 c9 61 10 f0       	push   $0xf01061c9
f01035e8:	e8 10 fc ff ff       	call   f01031fd <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f01035ed:	83 c4 08             	add    $0x8,%esp
f01035f0:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f01035f4:	50                   	push   %eax
f01035f5:	68 d8 61 10 f0       	push   $0xf01061d8
f01035fa:	e8 fe fb ff ff       	call   f01031fd <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f01035ff:	83 c4 08             	add    $0x8,%esp
f0103602:	ff 73 38             	pushl  0x38(%ebx)
f0103605:	68 eb 61 10 f0       	push   $0xf01061eb
f010360a:	e8 ee fb ff ff       	call   f01031fd <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f010360f:	83 c4 10             	add    $0x10,%esp
f0103612:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103616:	74 25                	je     f010363d <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103618:	83 ec 08             	sub    $0x8,%esp
f010361b:	ff 73 3c             	pushl  0x3c(%ebx)
f010361e:	68 fa 61 10 f0       	push   $0xf01061fa
f0103623:	e8 d5 fb ff ff       	call   f01031fd <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103628:	83 c4 08             	add    $0x8,%esp
f010362b:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f010362f:	50                   	push   %eax
f0103630:	68 09 62 10 f0       	push   $0xf0106209
f0103635:	e8 c3 fb ff ff       	call   f01031fd <cprintf>
f010363a:	83 c4 10             	add    $0x10,%esp
	}
}
f010363d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103640:	5b                   	pop    %ebx
f0103641:	5e                   	pop    %esi
f0103642:	5d                   	pop    %ebp
f0103643:	c3                   	ret    

f0103644 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103644:	55                   	push   %ebp
f0103645:	89 e5                	mov    %esp,%ebp
f0103647:	53                   	push   %ebx
f0103648:	83 ec 04             	sub    $0x4,%esp
f010364b:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010364e:	0f 20 d0             	mov    %cr2,%eax
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if ((tf->tf_cs&3) == 0)
f0103651:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103655:	75 17                	jne    f010366e <page_fault_handler+0x2a>
		panic("Kernel page fault!");
f0103657:	83 ec 04             	sub    $0x4,%esp
f010365a:	68 1c 62 10 f0       	push   $0xf010621c
f010365f:	68 0c 01 00 00       	push   $0x10c
f0103664:	68 2f 62 10 f0       	push   $0xf010622f
f0103669:	e8 32 ca ff ff       	call   f01000a0 <_panic>

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f010366e:	ff 73 30             	pushl  0x30(%ebx)
f0103671:	50                   	push   %eax
f0103672:	a1 a8 e4 17 f0       	mov    0xf017e4a8,%eax
f0103677:	ff 70 48             	pushl  0x48(%eax)
f010367a:	68 f8 63 10 f0       	push   $0xf01063f8
f010367f:	e8 79 fb ff ff       	call   f01031fd <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103684:	89 1c 24             	mov    %ebx,(%esp)
f0103687:	e8 45 fe ff ff       	call   f01034d1 <print_trapframe>
	env_destroy(curenv);
f010368c:	83 c4 04             	add    $0x4,%esp
f010368f:	ff 35 a8 e4 17 f0    	pushl  0xf017e4a8
f0103695:	e8 3c fa ff ff       	call   f01030d6 <env_destroy>
f010369a:	83 c4 10             	add    $0x10,%esp
}
f010369d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01036a0:	c9                   	leave  
f01036a1:	c3                   	ret    

f01036a2 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f01036a2:	55                   	push   %ebp
f01036a3:	89 e5                	mov    %esp,%ebp
f01036a5:	57                   	push   %edi
f01036a6:	56                   	push   %esi
f01036a7:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f01036aa:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f01036ab:	9c                   	pushf  
f01036ac:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f01036ad:	f6 c4 02             	test   $0x2,%ah
f01036b0:	74 19                	je     f01036cb <trap+0x29>
f01036b2:	68 3b 62 10 f0       	push   $0xf010623b
f01036b7:	68 95 5c 10 f0       	push   $0xf0105c95
f01036bc:	68 e3 00 00 00       	push   $0xe3
f01036c1:	68 2f 62 10 f0       	push   $0xf010622f
f01036c6:	e8 d5 c9 ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f01036cb:	83 ec 08             	sub    $0x8,%esp
f01036ce:	56                   	push   %esi
f01036cf:	68 54 62 10 f0       	push   $0xf0106254
f01036d4:	e8 24 fb ff ff       	call   f01031fd <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f01036d9:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f01036dd:	83 e0 03             	and    $0x3,%eax
f01036e0:	83 c4 10             	add    $0x10,%esp
f01036e3:	66 83 f8 03          	cmp    $0x3,%ax
f01036e7:	75 31                	jne    f010371a <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f01036e9:	a1 a8 e4 17 f0       	mov    0xf017e4a8,%eax
f01036ee:	85 c0                	test   %eax,%eax
f01036f0:	75 19                	jne    f010370b <trap+0x69>
f01036f2:	68 6f 62 10 f0       	push   $0xf010626f
f01036f7:	68 95 5c 10 f0       	push   $0xf0105c95
f01036fc:	68 e9 00 00 00       	push   $0xe9
f0103701:	68 2f 62 10 f0       	push   $0xf010622f
f0103706:	e8 95 c9 ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f010370b:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103710:	89 c7                	mov    %eax,%edi
f0103712:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103714:	8b 35 a8 e4 17 f0    	mov    0xf017e4a8,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f010371a:	89 35 c0 ec 17 f0    	mov    %esi,0xf017ecc0
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	if (tf->tf_trapno == T_PGFLT) {
f0103720:	8b 46 28             	mov    0x28(%esi),%eax
f0103723:	83 f8 0e             	cmp    $0xe,%eax
f0103726:	75 1d                	jne    f0103745 <trap+0xa3>
		cprintf("PAGE FAULT\n");
f0103728:	83 ec 0c             	sub    $0xc,%esp
f010372b:	68 76 62 10 f0       	push   $0xf0106276
f0103730:	e8 c8 fa ff ff       	call   f01031fd <cprintf>
		page_fault_handler(tf);
f0103735:	89 34 24             	mov    %esi,(%esp)
f0103738:	e8 07 ff ff ff       	call   f0103644 <page_fault_handler>
f010373d:	83 c4 10             	add    $0x10,%esp
f0103740:	e9 8d 00 00 00       	jmp    f01037d2 <trap+0x130>
		return;
	}
	if (tf->tf_trapno == T_BRKPT) {
f0103745:	83 f8 03             	cmp    $0x3,%eax
f0103748:	75 1a                	jne    f0103764 <trap+0xc2>
		cprintf("BREAK POINT\n");
f010374a:	83 ec 0c             	sub    $0xc,%esp
f010374d:	68 82 62 10 f0       	push   $0xf0106282
f0103752:	e8 a6 fa ff ff       	call   f01031fd <cprintf>
		monitor(tf);
f0103757:	89 34 24             	mov    %esi,(%esp)
f010375a:	e8 31 d2 ff ff       	call   f0100990 <monitor>
f010375f:	83 c4 10             	add    $0x10,%esp
f0103762:	eb 6e                	jmp    f01037d2 <trap+0x130>
		return;
	}
	if (tf->tf_trapno == T_SYSCALL) {
f0103764:	83 f8 30             	cmp    $0x30,%eax
f0103767:	75 2e                	jne    f0103797 <trap+0xf5>
		cprintf("SYSTEM CALL\n");
f0103769:	83 ec 0c             	sub    $0xc,%esp
f010376c:	68 8f 62 10 f0       	push   $0xf010628f
f0103771:	e8 87 fa ff ff       	call   f01031fd <cprintf>
		tf->tf_regs.reg_eax = 
			syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx,
f0103776:	83 c4 08             	add    $0x8,%esp
f0103779:	ff 76 04             	pushl  0x4(%esi)
f010377c:	ff 36                	pushl  (%esi)
f010377e:	ff 76 10             	pushl  0x10(%esi)
f0103781:	ff 76 18             	pushl  0x18(%esi)
f0103784:	ff 76 14             	pushl  0x14(%esi)
f0103787:	ff 76 1c             	pushl  0x1c(%esi)
f010378a:	e8 d8 00 00 00       	call   f0103867 <syscall>
		monitor(tf);
		return;
	}
	if (tf->tf_trapno == T_SYSCALL) {
		cprintf("SYSTEM CALL\n");
		tf->tf_regs.reg_eax = 
f010378f:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103792:	83 c4 20             	add    $0x20,%esp
f0103795:	eb 3b                	jmp    f01037d2 <trap+0x130>
			syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx,
				tf->tf_regs.reg_ebx, tf->tf_regs.reg_edi, tf->tf_regs.reg_esi);
		return;
	}
	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103797:	83 ec 0c             	sub    $0xc,%esp
f010379a:	56                   	push   %esi
f010379b:	e8 31 fd ff ff       	call   f01034d1 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01037a0:	83 c4 10             	add    $0x10,%esp
f01037a3:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01037a8:	75 17                	jne    f01037c1 <trap+0x11f>
		panic("unhandled trap in kernel");
f01037aa:	83 ec 04             	sub    $0x4,%esp
f01037ad:	68 9c 62 10 f0       	push   $0xf010629c
f01037b2:	68 d2 00 00 00       	push   $0xd2
f01037b7:	68 2f 62 10 f0       	push   $0xf010622f
f01037bc:	e8 df c8 ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f01037c1:	83 ec 0c             	sub    $0xc,%esp
f01037c4:	ff 35 a8 e4 17 f0    	pushl  0xf017e4a8
f01037ca:	e8 07 f9 ff ff       	call   f01030d6 <env_destroy>
f01037cf:	83 c4 10             	add    $0x10,%esp

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f01037d2:	a1 a8 e4 17 f0       	mov    0xf017e4a8,%eax
f01037d7:	85 c0                	test   %eax,%eax
f01037d9:	74 06                	je     f01037e1 <trap+0x13f>
f01037db:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01037df:	74 19                	je     f01037fa <trap+0x158>
f01037e1:	68 1c 64 10 f0       	push   $0xf010641c
f01037e6:	68 95 5c 10 f0       	push   $0xf0105c95
f01037eb:	68 fb 00 00 00       	push   $0xfb
f01037f0:	68 2f 62 10 f0       	push   $0xf010622f
f01037f5:	e8 a6 c8 ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f01037fa:	83 ec 0c             	sub    $0xc,%esp
f01037fd:	50                   	push   %eax
f01037fe:	e8 23 f9 ff ff       	call   f0103126 <env_run>
f0103803:	90                   	nop

f0103804 <th0>:
funs:
.text
/*
 * Challenge: my code here
 */
	noec(th0, 0)
f0103804:	6a 00                	push   $0x0
f0103806:	6a 00                	push   $0x0
f0103808:	eb 4e                	jmp    f0103858 <_alltraps>

f010380a <th1>:
	noec(th1, 1)
f010380a:	6a 00                	push   $0x0
f010380c:	6a 01                	push   $0x1
f010380e:	eb 48                	jmp    f0103858 <_alltraps>

f0103810 <th3>:
	zhanwei()
	noec(th3, 3)
f0103810:	6a 00                	push   $0x0
f0103812:	6a 03                	push   $0x3
f0103814:	eb 42                	jmp    f0103858 <_alltraps>

f0103816 <th4>:
	noec(th4, 4)
f0103816:	6a 00                	push   $0x0
f0103818:	6a 04                	push   $0x4
f010381a:	eb 3c                	jmp    f0103858 <_alltraps>

f010381c <th5>:
	noec(th5, 5)
f010381c:	6a 00                	push   $0x0
f010381e:	6a 05                	push   $0x5
f0103820:	eb 36                	jmp    f0103858 <_alltraps>

f0103822 <th6>:
	noec(th6, 6)
f0103822:	6a 00                	push   $0x0
f0103824:	6a 06                	push   $0x6
f0103826:	eb 30                	jmp    f0103858 <_alltraps>

f0103828 <th7>:
	noec(th7, 7)
f0103828:	6a 00                	push   $0x0
f010382a:	6a 07                	push   $0x7
f010382c:	eb 2a                	jmp    f0103858 <_alltraps>

f010382e <th8>:
	ec(th8, 8)
f010382e:	6a 08                	push   $0x8
f0103830:	eb 26                	jmp    f0103858 <_alltraps>

f0103832 <th9>:
	noec(th9, 9)
f0103832:	6a 00                	push   $0x0
f0103834:	6a 09                	push   $0x9
f0103836:	eb 20                	jmp    f0103858 <_alltraps>

f0103838 <th10>:
	ec(th10, 10)
f0103838:	6a 0a                	push   $0xa
f010383a:	eb 1c                	jmp    f0103858 <_alltraps>

f010383c <th11>:
	ec(th11, 11)
f010383c:	6a 0b                	push   $0xb
f010383e:	eb 18                	jmp    f0103858 <_alltraps>

f0103840 <th12>:
	ec(th12, 12)
f0103840:	6a 0c                	push   $0xc
f0103842:	eb 14                	jmp    f0103858 <_alltraps>

f0103844 <th13>:
	ec(th13, 13)
f0103844:	6a 0d                	push   $0xd
f0103846:	eb 10                	jmp    f0103858 <_alltraps>

f0103848 <th14>:
	ec(th14, 14)
f0103848:	6a 0e                	push   $0xe
f010384a:	eb 0c                	jmp    f0103858 <_alltraps>

f010384c <th16>:
	zhanwei()
	noec(th16, 16)
f010384c:	6a 00                	push   $0x0
f010384e:	6a 10                	push   $0x10
f0103850:	eb 06                	jmp    f0103858 <_alltraps>

f0103852 <th48>:
.data
	.space 124
.text
	noec(th48, 48)
f0103852:	6a 00                	push   $0x0
f0103854:	6a 30                	push   $0x30
f0103856:	eb 00                	jmp    f0103858 <_alltraps>

f0103858 <_alltraps>:

/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	pushl %ds
f0103858:	1e                   	push   %ds
	pushl %es
f0103859:	06                   	push   %es
	pushal
f010385a:	60                   	pusha  
	pushl $GD_KD
f010385b:	6a 10                	push   $0x10
	popl %ds
f010385d:	1f                   	pop    %ds
	pushl $GD_KD
f010385e:	6a 10                	push   $0x10
	popl %es
f0103860:	07                   	pop    %es
	pushl %esp
f0103861:	54                   	push   %esp
	call trap
f0103862:	e8 3b fe ff ff       	call   f01036a2 <trap>

f0103867 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0103867:	55                   	push   %ebp
f0103868:	89 e5                	mov    %esp,%ebp
f010386a:	83 ec 18             	sub    $0x18,%esp
f010386d:	8b 45 08             	mov    0x8(%ebp),%eax
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.


	switch (syscallno) {
f0103870:	83 f8 01             	cmp    $0x1,%eax
f0103873:	74 6a                	je     f01038df <syscall+0x78>
f0103875:	83 f8 01             	cmp    $0x1,%eax
f0103878:	72 0f                	jb     f0103889 <syscall+0x22>
f010387a:	83 f8 02             	cmp    $0x2,%eax
f010387d:	74 67                	je     f01038e6 <syscall+0x7f>
f010387f:	83 f8 03             	cmp    $0x3,%eax
f0103882:	74 6c                	je     f01038f0 <syscall+0x89>
f0103884:	e9 cc 00 00 00       	jmp    f0103955 <syscall+0xee>
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	struct Env *e;
	envid2env(sys_getenvid(), &e, 1);
f0103889:	83 ec 04             	sub    $0x4,%esp
f010388c:	6a 01                	push   $0x1
f010388e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103891:	50                   	push   %eax

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0103892:	a1 a8 e4 17 f0       	mov    0xf017e4a8,%eax
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	struct Env *e;
	envid2env(sys_getenvid(), &e, 1);
f0103897:	ff 70 48             	pushl  0x48(%eax)
f010389a:	e8 d8 f2 ff ff       	call   f0102b77 <envid2env>
	user_mem_assert(e, s, len, PTE_U);	
f010389f:	6a 04                	push   $0x4
f01038a1:	ff 75 10             	pushl  0x10(%ebp)
f01038a4:	ff 75 0c             	pushl  0xc(%ebp)
f01038a7:	ff 75 f4             	pushl  -0xc(%ebp)
f01038aa:	e8 13 f2 ff ff       	call   f0102ac2 <user_mem_assert>
	user_mem_check(e, s, len, PTE_U);
f01038af:	83 c4 20             	add    $0x20,%esp
f01038b2:	6a 04                	push   $0x4
f01038b4:	ff 75 10             	pushl  0x10(%ebp)
f01038b7:	ff 75 0c             	pushl  0xc(%ebp)
f01038ba:	ff 75 f4             	pushl  -0xc(%ebp)
f01038bd:	e8 53 f1 ff ff       	call   f0102a15 <user_mem_check>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01038c2:	83 c4 0c             	add    $0xc,%esp
f01038c5:	ff 75 0c             	pushl  0xc(%ebp)
f01038c8:	ff 75 10             	pushl  0x10(%ebp)
f01038cb:	68 d0 64 10 f0       	push   $0xf01064d0
f01038d0:	e8 28 f9 ff ff       	call   f01031fd <cprintf>
f01038d5:	83 c4 10             	add    $0x10,%esp


	switch (syscallno) {
	case(0):
		sys_cputs((const char*)a1, (size_t)a2);
		return 0;
f01038d8:	b8 00 00 00 00       	mov    $0x0,%eax
f01038dd:	eb 7b                	jmp    f010395a <syscall+0xf3>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f01038df:	e8 cd cb ff ff       	call   f01004b1 <cons_getc>
	switch (syscallno) {
	case(0):
		sys_cputs((const char*)a1, (size_t)a2);
		return 0;
	case(1):
		return sys_cgetc();
f01038e4:	eb 74                	jmp    f010395a <syscall+0xf3>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f01038e6:	a1 a8 e4 17 f0       	mov    0xf017e4a8,%eax
f01038eb:	8b 40 48             	mov    0x48(%eax),%eax
		sys_cputs((const char*)a1, (size_t)a2);
		return 0;
	case(1):
		return sys_cgetc();
	case(2):
		return sys_getenvid();
f01038ee:	eb 6a                	jmp    f010395a <syscall+0xf3>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f01038f0:	83 ec 04             	sub    $0x4,%esp
f01038f3:	6a 01                	push   $0x1
f01038f5:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01038f8:	50                   	push   %eax
f01038f9:	ff 75 0c             	pushl  0xc(%ebp)
f01038fc:	e8 76 f2 ff ff       	call   f0102b77 <envid2env>
f0103901:	83 c4 10             	add    $0x10,%esp
f0103904:	85 c0                	test   %eax,%eax
f0103906:	78 46                	js     f010394e <syscall+0xe7>
		return r;
	if (e == curenv)
f0103908:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010390b:	8b 15 a8 e4 17 f0    	mov    0xf017e4a8,%edx
f0103911:	39 d0                	cmp    %edx,%eax
f0103913:	75 15                	jne    f010392a <syscall+0xc3>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0103915:	83 ec 08             	sub    $0x8,%esp
f0103918:	ff 70 48             	pushl  0x48(%eax)
f010391b:	68 d5 64 10 f0       	push   $0xf01064d5
f0103920:	e8 d8 f8 ff ff       	call   f01031fd <cprintf>
f0103925:	83 c4 10             	add    $0x10,%esp
f0103928:	eb 16                	jmp    f0103940 <syscall+0xd9>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f010392a:	83 ec 04             	sub    $0x4,%esp
f010392d:	ff 70 48             	pushl  0x48(%eax)
f0103930:	ff 72 48             	pushl  0x48(%edx)
f0103933:	68 f0 64 10 f0       	push   $0xf01064f0
f0103938:	e8 c0 f8 ff ff       	call   f01031fd <cprintf>
f010393d:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0103940:	83 ec 0c             	sub    $0xc,%esp
f0103943:	ff 75 f4             	pushl  -0xc(%ebp)
f0103946:	e8 8b f7 ff ff       	call   f01030d6 <env_destroy>
f010394b:	83 c4 10             	add    $0x10,%esp
		return sys_cgetc();
	case(2):
		return sys_getenvid();
	case(3):
		sys_env_destroy(a1);
		return 0;
f010394e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103953:	eb 05                	jmp    f010395a <syscall+0xf3>
	default:
		return -E_NO_SYS;
f0103955:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax
	}
	panic("syscall not implemented");
}
f010395a:	c9                   	leave  
f010395b:	c3                   	ret    

f010395c <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010395c:	55                   	push   %ebp
f010395d:	89 e5                	mov    %esp,%ebp
f010395f:	57                   	push   %edi
f0103960:	56                   	push   %esi
f0103961:	53                   	push   %ebx
f0103962:	83 ec 14             	sub    $0x14,%esp
f0103965:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103968:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010396b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010396e:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103971:	8b 1a                	mov    (%edx),%ebx
f0103973:	8b 01                	mov    (%ecx),%eax
f0103975:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103978:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010397f:	e9 88 00 00 00       	jmp    f0103a0c <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0103984:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103987:	01 d8                	add    %ebx,%eax
f0103989:	89 c6                	mov    %eax,%esi
f010398b:	c1 ee 1f             	shr    $0x1f,%esi
f010398e:	01 c6                	add    %eax,%esi
f0103990:	d1 fe                	sar    %esi
f0103992:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103995:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103998:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010399b:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010399d:	eb 03                	jmp    f01039a2 <stab_binsearch+0x46>
			m--;
f010399f:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01039a2:	39 c3                	cmp    %eax,%ebx
f01039a4:	7f 1f                	jg     f01039c5 <stab_binsearch+0x69>
f01039a6:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01039aa:	83 ea 0c             	sub    $0xc,%edx
f01039ad:	39 f9                	cmp    %edi,%ecx
f01039af:	75 ee                	jne    f010399f <stab_binsearch+0x43>
f01039b1:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01039b4:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01039b7:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01039ba:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01039be:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01039c1:	76 18                	jbe    f01039db <stab_binsearch+0x7f>
f01039c3:	eb 05                	jmp    f01039ca <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01039c5:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01039c8:	eb 42                	jmp    f0103a0c <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01039ca:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01039cd:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01039cf:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01039d2:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01039d9:	eb 31                	jmp    f0103a0c <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01039db:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01039de:	73 17                	jae    f01039f7 <stab_binsearch+0x9b>
			*region_right = m - 1;
f01039e0:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01039e3:	83 e8 01             	sub    $0x1,%eax
f01039e6:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01039e9:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01039ec:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01039ee:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01039f5:	eb 15                	jmp    f0103a0c <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01039f7:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01039fa:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f01039fd:	89 1e                	mov    %ebx,(%esi)
			l = m;
			addr++;
f01039ff:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103a03:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103a05:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103a0c:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0103a0f:	0f 8e 6f ff ff ff    	jle    f0103984 <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103a15:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103a19:	75 0f                	jne    f0103a2a <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0103a1b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103a1e:	8b 00                	mov    (%eax),%eax
f0103a20:	83 e8 01             	sub    $0x1,%eax
f0103a23:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103a26:	89 06                	mov    %eax,(%esi)
f0103a28:	eb 2c                	jmp    f0103a56 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103a2a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103a2d:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103a2f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103a32:	8b 0e                	mov    (%esi),%ecx
f0103a34:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103a37:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103a3a:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103a3d:	eb 03                	jmp    f0103a42 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103a3f:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103a42:	39 c8                	cmp    %ecx,%eax
f0103a44:	7e 0b                	jle    f0103a51 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0103a46:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0103a4a:	83 ea 0c             	sub    $0xc,%edx
f0103a4d:	39 fb                	cmp    %edi,%ebx
f0103a4f:	75 ee                	jne    f0103a3f <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103a51:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103a54:	89 06                	mov    %eax,(%esi)
	}
}
f0103a56:	83 c4 14             	add    $0x14,%esp
f0103a59:	5b                   	pop    %ebx
f0103a5a:	5e                   	pop    %esi
f0103a5b:	5f                   	pop    %edi
f0103a5c:	5d                   	pop    %ebp
f0103a5d:	c3                   	ret    

f0103a5e <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103a5e:	55                   	push   %ebp
f0103a5f:	89 e5                	mov    %esp,%ebp
f0103a61:	57                   	push   %edi
f0103a62:	56                   	push   %esi
f0103a63:	53                   	push   %ebx
f0103a64:	83 ec 3c             	sub    $0x3c,%esp
f0103a67:	8b 75 08             	mov    0x8(%ebp),%esi
f0103a6a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103a6d:	c7 03 08 65 10 f0    	movl   $0xf0106508,(%ebx)
	info->eip_line = 0;
f0103a73:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0103a7a:	c7 43 08 08 65 10 f0 	movl   $0xf0106508,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0103a81:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0103a88:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0103a8b:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103a92:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0103a98:	77 21                	ja     f0103abb <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0103a9a:	a1 00 00 20 00       	mov    0x200000,%eax
f0103a9f:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		stab_end = usd->stab_end;
f0103aa2:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f0103aa7:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f0103aad:	89 7d c0             	mov    %edi,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f0103ab0:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f0103ab6:	89 7d bc             	mov    %edi,-0x44(%ebp)
f0103ab9:	eb 1a                	jmp    f0103ad5 <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103abb:	c7 45 bc 24 18 11 f0 	movl   $0xf0111824,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103ac2:	c7 45 c0 b9 ec 10 f0 	movl   $0xf010ecb9,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103ac9:	b8 b8 ec 10 f0       	mov    $0xf010ecb8,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103ace:	c7 45 c4 50 67 10 f0 	movl   $0xf0106750,-0x3c(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103ad5:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0103ad8:	39 7d c0             	cmp    %edi,-0x40(%ebp)
f0103adb:	0f 83 72 01 00 00    	jae    f0103c53 <debuginfo_eip+0x1f5>
f0103ae1:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f0103ae5:	0f 85 6f 01 00 00    	jne    f0103c5a <debuginfo_eip+0x1fc>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103aeb:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103af2:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0103af5:	29 f8                	sub    %edi,%eax
f0103af7:	c1 f8 02             	sar    $0x2,%eax
f0103afa:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103b00:	83 e8 01             	sub    $0x1,%eax
f0103b03:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103b06:	56                   	push   %esi
f0103b07:	6a 64                	push   $0x64
f0103b09:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103b0c:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103b0f:	89 f8                	mov    %edi,%eax
f0103b11:	e8 46 fe ff ff       	call   f010395c <stab_binsearch>
	if (lfile == 0)
f0103b16:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103b19:	83 c4 08             	add    $0x8,%esp
f0103b1c:	85 c0                	test   %eax,%eax
f0103b1e:	0f 84 3d 01 00 00    	je     f0103c61 <debuginfo_eip+0x203>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103b24:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103b27:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103b2a:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103b2d:	56                   	push   %esi
f0103b2e:	6a 24                	push   $0x24
f0103b30:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103b33:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103b36:	89 f8                	mov    %edi,%eax
f0103b38:	e8 1f fe ff ff       	call   f010395c <stab_binsearch>

	if (lfun <= rfun) {
f0103b3d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103b40:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0103b43:	83 c4 08             	add    $0x8,%esp
f0103b46:	39 c8                	cmp    %ecx,%eax
f0103b48:	7f 32                	jg     f0103b7c <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103b4a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103b4d:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0103b50:	8d 3c 97             	lea    (%edi,%edx,4),%edi
f0103b53:	8b 17                	mov    (%edi),%edx
f0103b55:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0103b58:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0103b5b:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0103b5e:	39 55 b8             	cmp    %edx,-0x48(%ebp)
f0103b61:	73 09                	jae    f0103b6c <debuginfo_eip+0x10e>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103b63:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0103b66:	03 55 c0             	add    -0x40(%ebp),%edx
f0103b69:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103b6c:	8b 57 08             	mov    0x8(%edi),%edx
f0103b6f:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0103b72:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0103b74:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103b77:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0103b7a:	eb 0f                	jmp    f0103b8b <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103b7c:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0103b7f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103b82:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103b85:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103b88:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103b8b:	83 ec 08             	sub    $0x8,%esp
f0103b8e:	6a 3a                	push   $0x3a
f0103b90:	ff 73 08             	pushl  0x8(%ebx)
f0103b93:	e8 4f 0b 00 00       	call   f01046e7 <strfind>
f0103b98:	2b 43 08             	sub    0x8(%ebx),%eax
f0103b9b:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103b9e:	83 c4 08             	add    $0x8,%esp
f0103ba1:	56                   	push   %esi
f0103ba2:	6a 44                	push   $0x44
f0103ba4:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103ba7:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103baa:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0103bad:	89 f0                	mov    %esi,%eax
f0103baf:	e8 a8 fd ff ff       	call   f010395c <stab_binsearch>
	if(lline <= rline){
f0103bb4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103bb7:	83 c4 10             	add    $0x10,%esp
f0103bba:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103bbd:	0f 8f a5 00 00 00    	jg     f0103c68 <debuginfo_eip+0x20a>
		info->eip_line = stabs[lline].n_desc;
f0103bc3:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103bc6:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0103bcb:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103bce:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103bd1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103bd4:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103bd7:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0103bda:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103bdd:	eb 06                	jmp    f0103be5 <debuginfo_eip+0x187>
f0103bdf:	83 e8 01             	sub    $0x1,%eax
f0103be2:	83 ea 0c             	sub    $0xc,%edx
f0103be5:	39 c7                	cmp    %eax,%edi
f0103be7:	7f 27                	jg     f0103c10 <debuginfo_eip+0x1b2>
	       && stabs[lline].n_type != N_SOL
f0103be9:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103bed:	80 f9 84             	cmp    $0x84,%cl
f0103bf0:	0f 84 80 00 00 00    	je     f0103c76 <debuginfo_eip+0x218>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103bf6:	80 f9 64             	cmp    $0x64,%cl
f0103bf9:	75 e4                	jne    f0103bdf <debuginfo_eip+0x181>
f0103bfb:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103bff:	74 de                	je     f0103bdf <debuginfo_eip+0x181>
f0103c01:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103c04:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103c07:	eb 73                	jmp    f0103c7c <debuginfo_eip+0x21e>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103c09:	03 55 c0             	add    -0x40(%ebp),%edx
f0103c0c:	89 13                	mov    %edx,(%ebx)
f0103c0e:	eb 03                	jmp    f0103c13 <debuginfo_eip+0x1b5>
f0103c10:	8b 5d 0c             	mov    0xc(%ebp),%ebx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103c13:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103c16:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103c19:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103c1e:	39 f2                	cmp    %esi,%edx
f0103c20:	7d 76                	jge    f0103c98 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
f0103c22:	83 c2 01             	add    $0x1,%edx
f0103c25:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103c28:	89 d0                	mov    %edx,%eax
f0103c2a:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103c2d:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0103c30:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0103c33:	eb 04                	jmp    f0103c39 <debuginfo_eip+0x1db>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103c35:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103c39:	39 c6                	cmp    %eax,%esi
f0103c3b:	7e 32                	jle    f0103c6f <debuginfo_eip+0x211>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103c3d:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103c41:	83 c0 01             	add    $0x1,%eax
f0103c44:	83 c2 0c             	add    $0xc,%edx
f0103c47:	80 f9 a0             	cmp    $0xa0,%cl
f0103c4a:	74 e9                	je     f0103c35 <debuginfo_eip+0x1d7>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103c4c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103c51:	eb 45                	jmp    f0103c98 <debuginfo_eip+0x23a>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103c53:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103c58:	eb 3e                	jmp    f0103c98 <debuginfo_eip+0x23a>
f0103c5a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103c5f:	eb 37                	jmp    f0103c98 <debuginfo_eip+0x23a>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103c61:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103c66:	eb 30                	jmp    f0103c98 <debuginfo_eip+0x23a>
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if(lline <= rline){
		info->eip_line = stabs[lline].n_desc;
	}
	else{
		return -1;
f0103c68:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103c6d:	eb 29                	jmp    f0103c98 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103c6f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103c74:	eb 22                	jmp    f0103c98 <debuginfo_eip+0x23a>
f0103c76:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103c79:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103c7c:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103c7f:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0103c82:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103c85:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103c88:	2b 45 c0             	sub    -0x40(%ebp),%eax
f0103c8b:	39 c2                	cmp    %eax,%edx
f0103c8d:	0f 82 76 ff ff ff    	jb     f0103c09 <debuginfo_eip+0x1ab>
f0103c93:	e9 7b ff ff ff       	jmp    f0103c13 <debuginfo_eip+0x1b5>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
}
f0103c98:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103c9b:	5b                   	pop    %ebx
f0103c9c:	5e                   	pop    %esi
f0103c9d:	5f                   	pop    %edi
f0103c9e:	5d                   	pop    %ebp
f0103c9f:	c3                   	ret    

f0103ca0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103ca0:	55                   	push   %ebp
f0103ca1:	89 e5                	mov    %esp,%ebp
f0103ca3:	57                   	push   %edi
f0103ca4:	56                   	push   %esi
f0103ca5:	53                   	push   %ebx
f0103ca6:	83 ec 1c             	sub    $0x1c,%esp
f0103ca9:	89 c7                	mov    %eax,%edi
f0103cab:	89 d6                	mov    %edx,%esi
f0103cad:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cb0:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103cb3:	89 d1                	mov    %edx,%ecx
f0103cb5:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103cb8:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103cbb:	8b 45 10             	mov    0x10(%ebp),%eax
f0103cbe:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103cc1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103cc4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0103ccb:	39 4d e4             	cmp    %ecx,-0x1c(%ebp)
f0103cce:	72 05                	jb     f0103cd5 <printnum+0x35>
f0103cd0:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0103cd3:	77 3e                	ja     f0103d13 <printnum+0x73>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103cd5:	83 ec 0c             	sub    $0xc,%esp
f0103cd8:	ff 75 18             	pushl  0x18(%ebp)
f0103cdb:	83 eb 01             	sub    $0x1,%ebx
f0103cde:	53                   	push   %ebx
f0103cdf:	50                   	push   %eax
f0103ce0:	83 ec 08             	sub    $0x8,%esp
f0103ce3:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103ce6:	ff 75 e0             	pushl  -0x20(%ebp)
f0103ce9:	ff 75 dc             	pushl  -0x24(%ebp)
f0103cec:	ff 75 d8             	pushl  -0x28(%ebp)
f0103cef:	e8 1c 0c 00 00       	call   f0104910 <__udivdi3>
f0103cf4:	83 c4 18             	add    $0x18,%esp
f0103cf7:	52                   	push   %edx
f0103cf8:	50                   	push   %eax
f0103cf9:	89 f2                	mov    %esi,%edx
f0103cfb:	89 f8                	mov    %edi,%eax
f0103cfd:	e8 9e ff ff ff       	call   f0103ca0 <printnum>
f0103d02:	83 c4 20             	add    $0x20,%esp
f0103d05:	eb 13                	jmp    f0103d1a <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103d07:	83 ec 08             	sub    $0x8,%esp
f0103d0a:	56                   	push   %esi
f0103d0b:	ff 75 18             	pushl  0x18(%ebp)
f0103d0e:	ff d7                	call   *%edi
f0103d10:	83 c4 10             	add    $0x10,%esp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103d13:	83 eb 01             	sub    $0x1,%ebx
f0103d16:	85 db                	test   %ebx,%ebx
f0103d18:	7f ed                	jg     f0103d07 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103d1a:	83 ec 08             	sub    $0x8,%esp
f0103d1d:	56                   	push   %esi
f0103d1e:	83 ec 04             	sub    $0x4,%esp
f0103d21:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103d24:	ff 75 e0             	pushl  -0x20(%ebp)
f0103d27:	ff 75 dc             	pushl  -0x24(%ebp)
f0103d2a:	ff 75 d8             	pushl  -0x28(%ebp)
f0103d2d:	e8 0e 0d 00 00       	call   f0104a40 <__umoddi3>
f0103d32:	83 c4 14             	add    $0x14,%esp
f0103d35:	0f be 80 12 65 10 f0 	movsbl -0xfef9aee(%eax),%eax
f0103d3c:	50                   	push   %eax
f0103d3d:	ff d7                	call   *%edi
f0103d3f:	83 c4 10             	add    $0x10,%esp
}
f0103d42:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103d45:	5b                   	pop    %ebx
f0103d46:	5e                   	pop    %esi
f0103d47:	5f                   	pop    %edi
f0103d48:	5d                   	pop    %ebp
f0103d49:	c3                   	ret    

f0103d4a <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103d4a:	55                   	push   %ebp
f0103d4b:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103d4d:	83 fa 01             	cmp    $0x1,%edx
f0103d50:	7e 0e                	jle    f0103d60 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103d52:	8b 10                	mov    (%eax),%edx
f0103d54:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103d57:	89 08                	mov    %ecx,(%eax)
f0103d59:	8b 02                	mov    (%edx),%eax
f0103d5b:	8b 52 04             	mov    0x4(%edx),%edx
f0103d5e:	eb 22                	jmp    f0103d82 <getuint+0x38>
	else if (lflag)
f0103d60:	85 d2                	test   %edx,%edx
f0103d62:	74 10                	je     f0103d74 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103d64:	8b 10                	mov    (%eax),%edx
f0103d66:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103d69:	89 08                	mov    %ecx,(%eax)
f0103d6b:	8b 02                	mov    (%edx),%eax
f0103d6d:	ba 00 00 00 00       	mov    $0x0,%edx
f0103d72:	eb 0e                	jmp    f0103d82 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103d74:	8b 10                	mov    (%eax),%edx
f0103d76:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103d79:	89 08                	mov    %ecx,(%eax)
f0103d7b:	8b 02                	mov    (%edx),%eax
f0103d7d:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103d82:	5d                   	pop    %ebp
f0103d83:	c3                   	ret    

f0103d84 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103d84:	55                   	push   %ebp
f0103d85:	89 e5                	mov    %esp,%ebp
f0103d87:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103d8a:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103d8e:	8b 10                	mov    (%eax),%edx
f0103d90:	3b 50 04             	cmp    0x4(%eax),%edx
f0103d93:	73 0a                	jae    f0103d9f <sprintputch+0x1b>
		*b->buf++ = ch;
f0103d95:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103d98:	89 08                	mov    %ecx,(%eax)
f0103d9a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d9d:	88 02                	mov    %al,(%edx)
}
f0103d9f:	5d                   	pop    %ebp
f0103da0:	c3                   	ret    

f0103da1 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103da1:	55                   	push   %ebp
f0103da2:	89 e5                	mov    %esp,%ebp
f0103da4:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103da7:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103daa:	50                   	push   %eax
f0103dab:	ff 75 10             	pushl  0x10(%ebp)
f0103dae:	ff 75 0c             	pushl  0xc(%ebp)
f0103db1:	ff 75 08             	pushl  0x8(%ebp)
f0103db4:	e8 05 00 00 00       	call   f0103dbe <vprintfmt>
	va_end(ap);
f0103db9:	83 c4 10             	add    $0x10,%esp
}
f0103dbc:	c9                   	leave  
f0103dbd:	c3                   	ret    

f0103dbe <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103dbe:	55                   	push   %ebp
f0103dbf:	89 e5                	mov    %esp,%ebp
f0103dc1:	57                   	push   %edi
f0103dc2:	56                   	push   %esi
f0103dc3:	53                   	push   %ebx
f0103dc4:	83 ec 3c             	sub    $0x3c,%esp
f0103dc7:	8b 75 08             	mov    0x8(%ebp),%esi
f0103dca:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103dcd:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103dd0:	eb 12                	jmp    f0103de4 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;
	char colorcontrol[5];
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103dd2:	85 c0                	test   %eax,%eax
f0103dd4:	0f 84 62 06 00 00    	je     f010443c <vprintfmt+0x67e>
				return;
			putch(ch, putdat);
f0103dda:	83 ec 08             	sub    $0x8,%esp
f0103ddd:	53                   	push   %ebx
f0103dde:	50                   	push   %eax
f0103ddf:	ff d6                	call   *%esi
f0103de1:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;
	char colorcontrol[5];
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103de4:	83 c7 01             	add    $0x1,%edi
f0103de7:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103deb:	83 f8 25             	cmp    $0x25,%eax
f0103dee:	75 e2                	jne    f0103dd2 <vprintfmt+0x14>
f0103df0:	c6 45 c4 20          	movb   $0x20,-0x3c(%ebp)
f0103df4:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
f0103dfb:	c7 45 c0 ff ff ff ff 	movl   $0xffffffff,-0x40(%ebp)
f0103e02:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103e09:	ba 00 00 00 00       	mov    $0x0,%edx
f0103e0e:	eb 07                	jmp    f0103e17 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e10:	8b 7d d4             	mov    -0x2c(%ebp),%edi
					colr = COLR_BLACK;
			}
			colr |= highlight;
			break;
		case '-':
			padc = '-';
f0103e13:	c6 45 c4 2d          	movb   $0x2d,-0x3c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e17:	8d 47 01             	lea    0x1(%edi),%eax
f0103e1a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103e1d:	0f b6 07             	movzbl (%edi),%eax
f0103e20:	0f b6 c8             	movzbl %al,%ecx
f0103e23:	83 e8 23             	sub    $0x23,%eax
f0103e26:	3c 55                	cmp    $0x55,%al
f0103e28:	0f 87 f3 05 00 00    	ja     f0104421 <vprintfmt+0x663>
f0103e2e:	0f b6 c0             	movzbl %al,%eax
f0103e31:	ff 24 85 c0 65 10 f0 	jmp    *-0xfef9a40(,%eax,4)
f0103e38:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103e3b:	c6 45 c4 30          	movb   $0x30,-0x3c(%ebp)
f0103e3f:	eb d6                	jmp    f0103e17 <vprintfmt+0x59>
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {

		// flag to pad on the right
		case 'C':
			memmove(colorcontrol, fmt, sizeof(unsigned char)*3);
f0103e41:	83 ec 04             	sub    $0x4,%esp
f0103e44:	6a 03                	push   $0x3
f0103e46:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103e49:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103e4c:	50                   	push   %eax
f0103e4d:	e8 fe 08 00 00       	call   f0104750 <memmove>
			colorcontrol[3] = '\0';
f0103e52:	c6 45 e6 00          	movb   $0x0,-0x1a(%ebp)
			fmt += 3;
f0103e56:	83 c7 04             	add    $0x4,%edi
			if(colorcontrol[0] >= '0' && colorcontrol[0] <= '9'){
f0103e59:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f0103e5d:	8d 50 d0             	lea    -0x30(%eax),%edx
f0103e60:	83 c4 10             	add    $0x10,%esp
f0103e63:	80 fa 09             	cmp    $0x9,%dl
f0103e66:	77 29                	ja     f0103e91 <vprintfmt+0xd3>
				colr = (colorcontrol[0] - '0') * 100 + (colorcontrol[1] - '0') * 10 + (colorcontrol[2] - '0');
f0103e68:	0f be c0             	movsbl %al,%eax
f0103e6b:	83 e8 30             	sub    $0x30,%eax
f0103e6e:	6b c0 64             	imul   $0x64,%eax,%eax
f0103e71:	0f be 55 e4          	movsbl -0x1c(%ebp),%edx
f0103e75:	8d 94 92 10 ff ff ff 	lea    -0xf0(%edx,%edx,4),%edx
f0103e7c:	8d 14 50             	lea    (%eax,%edx,2),%edx
f0103e7f:	0f be 45 e5          	movsbl -0x1b(%ebp),%eax
f0103e83:	8d 44 02 d0          	lea    -0x30(%edx,%eax,1),%eax
f0103e87:	a3 6c ed 17 f0       	mov    %eax,0xf017ed6c
f0103e8c:	e9 53 ff ff ff       	jmp    f0103de4 <vprintfmt+0x26>
			}
			else{
				if(strcmp(colorcontrol, "ble") == 0) colr = COLR_BLUE
f0103e91:	83 ec 08             	sub    $0x8,%esp
f0103e94:	68 28 63 10 f0       	push   $0xf0106328
f0103e99:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103e9c:	50                   	push   %eax
f0103e9d:	e8 c6 07 00 00       	call   f0104668 <strcmp>
f0103ea2:	83 c4 10             	add    $0x10,%esp
f0103ea5:	85 c0                	test   %eax,%eax
f0103ea7:	75 0f                	jne    f0103eb8 <vprintfmt+0xfa>
f0103ea9:	c7 05 6c ed 17 f0 01 	movl   $0x1,0xf017ed6c
f0103eb0:	00 00 00 
f0103eb3:	e9 2c ff ff ff       	jmp    f0103de4 <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "grn") == 0) colr = COLR_GREEN
f0103eb8:	83 ec 08             	sub    $0x8,%esp
f0103ebb:	68 2a 65 10 f0       	push   $0xf010652a
f0103ec0:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103ec3:	50                   	push   %eax
f0103ec4:	e8 9f 07 00 00       	call   f0104668 <strcmp>
f0103ec9:	83 c4 10             	add    $0x10,%esp
f0103ecc:	85 c0                	test   %eax,%eax
f0103ece:	75 0f                	jne    f0103edf <vprintfmt+0x121>
f0103ed0:	c7 05 6c ed 17 f0 02 	movl   $0x2,0xf017ed6c
f0103ed7:	00 00 00 
f0103eda:	e9 05 ff ff ff       	jmp    f0103de4 <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "cyn") == 0) colr = COLR_CYAN
f0103edf:	83 ec 08             	sub    $0x8,%esp
f0103ee2:	68 2e 65 10 f0       	push   $0xf010652e
f0103ee7:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103eea:	50                   	push   %eax
f0103eeb:	e8 78 07 00 00       	call   f0104668 <strcmp>
f0103ef0:	83 c4 10             	add    $0x10,%esp
f0103ef3:	85 c0                	test   %eax,%eax
f0103ef5:	75 0f                	jne    f0103f06 <vprintfmt+0x148>
f0103ef7:	c7 05 6c ed 17 f0 03 	movl   $0x3,0xf017ed6c
f0103efe:	00 00 00 
f0103f01:	e9 de fe ff ff       	jmp    f0103de4 <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "red") == 0) colr = COLR_RED
f0103f06:	83 ec 08             	sub    $0x8,%esp
f0103f09:	68 32 65 10 f0       	push   $0xf0106532
f0103f0e:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103f11:	50                   	push   %eax
f0103f12:	e8 51 07 00 00       	call   f0104668 <strcmp>
f0103f17:	83 c4 10             	add    $0x10,%esp
f0103f1a:	85 c0                	test   %eax,%eax
f0103f1c:	75 0f                	jne    f0103f2d <vprintfmt+0x16f>
f0103f1e:	c7 05 6c ed 17 f0 04 	movl   $0x4,0xf017ed6c
f0103f25:	00 00 00 
f0103f28:	e9 b7 fe ff ff       	jmp    f0103de4 <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "mag") == 0) colr = COLR_MAGENTA
f0103f2d:	83 ec 08             	sub    $0x8,%esp
f0103f30:	68 36 65 10 f0       	push   $0xf0106536
f0103f35:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103f38:	50                   	push   %eax
f0103f39:	e8 2a 07 00 00       	call   f0104668 <strcmp>
f0103f3e:	83 c4 10             	add    $0x10,%esp
f0103f41:	85 c0                	test   %eax,%eax
f0103f43:	75 0f                	jne    f0103f54 <vprintfmt+0x196>
f0103f45:	c7 05 6c ed 17 f0 05 	movl   $0x5,0xf017ed6c
f0103f4c:	00 00 00 
f0103f4f:	e9 90 fe ff ff       	jmp    f0103de4 <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "brw")== 0) colr = COLR_BROWN
f0103f54:	83 ec 08             	sub    $0x8,%esp
f0103f57:	68 3a 65 10 f0       	push   $0xf010653a
f0103f5c:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103f5f:	50                   	push   %eax
f0103f60:	e8 03 07 00 00       	call   f0104668 <strcmp>
f0103f65:	83 c4 10             	add    $0x10,%esp
f0103f68:	85 c0                	test   %eax,%eax
f0103f6a:	75 0f                	jne    f0103f7b <vprintfmt+0x1bd>
f0103f6c:	c7 05 6c ed 17 f0 06 	movl   $0x6,0xf017ed6c
f0103f73:	00 00 00 
f0103f76:	e9 69 fe ff ff       	jmp    f0103de4 <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "gry") == 0) colr = COLR_GRAY
f0103f7b:	83 ec 08             	sub    $0x8,%esp
f0103f7e:	68 3e 65 10 f0       	push   $0xf010653e
f0103f83:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103f86:	50                   	push   %eax
f0103f87:	e8 dc 06 00 00       	call   f0104668 <strcmp>
f0103f8c:	83 c4 10             	add    $0x10,%esp
f0103f8f:	83 f8 01             	cmp    $0x1,%eax
f0103f92:	19 c0                	sbb    %eax,%eax
f0103f94:	83 e0 07             	and    $0x7,%eax
f0103f97:	a3 6c ed 17 f0       	mov    %eax,0xf017ed6c
f0103f9c:	e9 43 fe ff ff       	jmp    f0103de4 <vprintfmt+0x26>
					colr = COLR_BLACK;
			}
			break;
				
		case 'I':
			highlight = COLR_HIGHLIGHT;
f0103fa1:	c7 05 68 ed 17 f0 08 	movl   $0x8,0xf017ed68
f0103fa8:	00 00 00 
			memmove(colorcontrol, fmt, sizeof(unsigned char)*3);
f0103fab:	83 ec 04             	sub    $0x4,%esp
f0103fae:	6a 03                	push   $0x3
f0103fb0:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103fb3:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103fb6:	50                   	push   %eax
f0103fb7:	e8 94 07 00 00       	call   f0104750 <memmove>
			colorcontrol[3] = '\0';
f0103fbc:	c6 45 e6 00          	movb   $0x0,-0x1a(%ebp)
			fmt += 3;
f0103fc0:	83 c7 04             	add    $0x4,%edi
			if(colorcontrol[0] >= '0' && colorcontrol[0] <= '9'){
f0103fc3:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f0103fc7:	8d 50 d0             	lea    -0x30(%eax),%edx
f0103fca:	83 c4 10             	add    $0x10,%esp
f0103fcd:	80 fa 09             	cmp    $0x9,%dl
f0103fd0:	77 29                	ja     f0103ffb <vprintfmt+0x23d>
				colr = (colorcontrol[0] - '0') * 100 + (colorcontrol[1] - '0') * 10 + (colorcontrol[2] - '0');
f0103fd2:	0f be c0             	movsbl %al,%eax
f0103fd5:	83 e8 30             	sub    $0x30,%eax
f0103fd8:	6b c0 64             	imul   $0x64,%eax,%eax
f0103fdb:	0f be 55 e4          	movsbl -0x1c(%ebp),%edx
f0103fdf:	8d 94 92 10 ff ff ff 	lea    -0xf0(%edx,%edx,4),%edx
f0103fe6:	8d 14 50             	lea    (%eax,%edx,2),%edx
f0103fe9:	0f be 45 e5          	movsbl -0x1b(%ebp),%eax
f0103fed:	8d 44 02 d0          	lea    -0x30(%edx,%eax,1),%eax
f0103ff1:	a3 6c ed 17 f0       	mov    %eax,0xf017ed6c
f0103ff6:	e9 02 01 00 00       	jmp    f01040fd <vprintfmt+0x33f>
			}
			else{
				if(strcmp(colorcontrol, "ble") == 0) colr = COLR_BLUE
f0103ffb:	83 ec 08             	sub    $0x8,%esp
f0103ffe:	68 28 63 10 f0       	push   $0xf0106328
f0104003:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0104006:	50                   	push   %eax
f0104007:	e8 5c 06 00 00       	call   f0104668 <strcmp>
f010400c:	83 c4 10             	add    $0x10,%esp
f010400f:	85 c0                	test   %eax,%eax
f0104011:	75 0f                	jne    f0104022 <vprintfmt+0x264>
f0104013:	c7 05 6c ed 17 f0 01 	movl   $0x1,0xf017ed6c
f010401a:	00 00 00 
f010401d:	e9 db 00 00 00       	jmp    f01040fd <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "grn") == 0) colr = COLR_GREEN
f0104022:	83 ec 08             	sub    $0x8,%esp
f0104025:	68 2a 65 10 f0       	push   $0xf010652a
f010402a:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f010402d:	50                   	push   %eax
f010402e:	e8 35 06 00 00       	call   f0104668 <strcmp>
f0104033:	83 c4 10             	add    $0x10,%esp
f0104036:	85 c0                	test   %eax,%eax
f0104038:	75 0f                	jne    f0104049 <vprintfmt+0x28b>
f010403a:	c7 05 6c ed 17 f0 02 	movl   $0x2,0xf017ed6c
f0104041:	00 00 00 
f0104044:	e9 b4 00 00 00       	jmp    f01040fd <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "cyn") == 0) colr = COLR_CYAN
f0104049:	83 ec 08             	sub    $0x8,%esp
f010404c:	68 2e 65 10 f0       	push   $0xf010652e
f0104051:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0104054:	50                   	push   %eax
f0104055:	e8 0e 06 00 00       	call   f0104668 <strcmp>
f010405a:	83 c4 10             	add    $0x10,%esp
f010405d:	85 c0                	test   %eax,%eax
f010405f:	75 0f                	jne    f0104070 <vprintfmt+0x2b2>
f0104061:	c7 05 6c ed 17 f0 03 	movl   $0x3,0xf017ed6c
f0104068:	00 00 00 
f010406b:	e9 8d 00 00 00       	jmp    f01040fd <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "red") == 0) colr = COLR_RED
f0104070:	83 ec 08             	sub    $0x8,%esp
f0104073:	68 32 65 10 f0       	push   $0xf0106532
f0104078:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f010407b:	50                   	push   %eax
f010407c:	e8 e7 05 00 00       	call   f0104668 <strcmp>
f0104081:	83 c4 10             	add    $0x10,%esp
f0104084:	85 c0                	test   %eax,%eax
f0104086:	75 0c                	jne    f0104094 <vprintfmt+0x2d6>
f0104088:	c7 05 6c ed 17 f0 04 	movl   $0x4,0xf017ed6c
f010408f:	00 00 00 
f0104092:	eb 69                	jmp    f01040fd <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "mag") == 0) colr = COLR_MAGENTA
f0104094:	83 ec 08             	sub    $0x8,%esp
f0104097:	68 36 65 10 f0       	push   $0xf0106536
f010409c:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f010409f:	50                   	push   %eax
f01040a0:	e8 c3 05 00 00       	call   f0104668 <strcmp>
f01040a5:	83 c4 10             	add    $0x10,%esp
f01040a8:	85 c0                	test   %eax,%eax
f01040aa:	75 0c                	jne    f01040b8 <vprintfmt+0x2fa>
f01040ac:	c7 05 6c ed 17 f0 05 	movl   $0x5,0xf017ed6c
f01040b3:	00 00 00 
f01040b6:	eb 45                	jmp    f01040fd <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "brw")== 0) colr = COLR_BROWN
f01040b8:	83 ec 08             	sub    $0x8,%esp
f01040bb:	68 3a 65 10 f0       	push   $0xf010653a
f01040c0:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f01040c3:	50                   	push   %eax
f01040c4:	e8 9f 05 00 00       	call   f0104668 <strcmp>
f01040c9:	83 c4 10             	add    $0x10,%esp
f01040cc:	85 c0                	test   %eax,%eax
f01040ce:	75 0c                	jne    f01040dc <vprintfmt+0x31e>
f01040d0:	c7 05 6c ed 17 f0 06 	movl   $0x6,0xf017ed6c
f01040d7:	00 00 00 
f01040da:	eb 21                	jmp    f01040fd <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "gry") == 0) colr = COLR_GRAY
f01040dc:	83 ec 08             	sub    $0x8,%esp
f01040df:	68 3e 65 10 f0       	push   $0xf010653e
f01040e4:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f01040e7:	50                   	push   %eax
f01040e8:	e8 7b 05 00 00       	call   f0104668 <strcmp>
f01040ed:	83 c4 10             	add    $0x10,%esp
f01040f0:	83 f8 01             	cmp    $0x1,%eax
f01040f3:	19 c0                	sbb    %eax,%eax
f01040f5:	83 e0 07             	and    $0x7,%eax
f01040f8:	a3 6c ed 17 f0       	mov    %eax,0xf017ed6c
				else
					colr = COLR_BLACK;
			}
			colr |= highlight;
f01040fd:	a1 68 ed 17 f0       	mov    0xf017ed68,%eax
f0104102:	09 05 6c ed 17 f0    	or     %eax,0xf017ed6c
			break;
f0104108:	e9 d7 fc ff ff       	jmp    f0103de4 <vprintfmt+0x26>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010410d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104110:	b8 00 00 00 00       	mov    $0x0,%eax
f0104115:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104118:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010411b:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f010411f:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0104122:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0104125:	83 fa 09             	cmp    $0x9,%edx
f0104128:	77 3f                	ja     f0104169 <vprintfmt+0x3ab>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010412a:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f010412d:	eb e9                	jmp    f0104118 <vprintfmt+0x35a>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f010412f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104132:	8d 48 04             	lea    0x4(%eax),%ecx
f0104135:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104138:	8b 00                	mov    (%eax),%eax
f010413a:	89 45 c0             	mov    %eax,-0x40(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010413d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104140:	eb 2d                	jmp    f010416f <vprintfmt+0x3b1>
f0104142:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104145:	85 c0                	test   %eax,%eax
f0104147:	b9 00 00 00 00       	mov    $0x0,%ecx
f010414c:	0f 49 c8             	cmovns %eax,%ecx
f010414f:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104152:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104155:	e9 bd fc ff ff       	jmp    f0103e17 <vprintfmt+0x59>
f010415a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010415d:	c7 45 c8 01 00 00 00 	movl   $0x1,-0x38(%ebp)
			goto reswitch;
f0104164:	e9 ae fc ff ff       	jmp    f0103e17 <vprintfmt+0x59>
f0104169:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010416c:	89 45 c0             	mov    %eax,-0x40(%ebp)

		process_precision:
			if (width < 0)
f010416f:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0104173:	0f 89 9e fc ff ff    	jns    f0103e17 <vprintfmt+0x59>
				width = precision, precision = -1;
f0104179:	8b 45 c0             	mov    -0x40(%ebp),%eax
f010417c:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010417f:	c7 45 c0 ff ff ff ff 	movl   $0xffffffff,-0x40(%ebp)
f0104186:	e9 8c fc ff ff       	jmp    f0103e17 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f010418b:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010418e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0104191:	e9 81 fc ff ff       	jmp    f0103e17 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104196:	8b 45 14             	mov    0x14(%ebp),%eax
f0104199:	8d 50 04             	lea    0x4(%eax),%edx
f010419c:	89 55 14             	mov    %edx,0x14(%ebp)
f010419f:	83 ec 08             	sub    $0x8,%esp
f01041a2:	53                   	push   %ebx
f01041a3:	ff 30                	pushl  (%eax)
f01041a5:	ff d6                	call   *%esi
			break;
f01041a7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01041aa:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f01041ad:	e9 32 fc ff ff       	jmp    f0103de4 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01041b2:	8b 45 14             	mov    0x14(%ebp),%eax
f01041b5:	8d 50 04             	lea    0x4(%eax),%edx
f01041b8:	89 55 14             	mov    %edx,0x14(%ebp)
f01041bb:	8b 00                	mov    (%eax),%eax
f01041bd:	99                   	cltd   
f01041be:	31 d0                	xor    %edx,%eax
f01041c0:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01041c2:	83 f8 07             	cmp    $0x7,%eax
f01041c5:	7f 0b                	jg     f01041d2 <vprintfmt+0x414>
f01041c7:	8b 14 85 20 67 10 f0 	mov    -0xfef98e0(,%eax,4),%edx
f01041ce:	85 d2                	test   %edx,%edx
f01041d0:	75 18                	jne    f01041ea <vprintfmt+0x42c>
				printfmt(putch, putdat, "error %d", err);
f01041d2:	50                   	push   %eax
f01041d3:	68 42 65 10 f0       	push   $0xf0106542
f01041d8:	53                   	push   %ebx
f01041d9:	56                   	push   %esi
f01041da:	e8 c2 fb ff ff       	call   f0103da1 <printfmt>
f01041df:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01041e2:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01041e5:	e9 fa fb ff ff       	jmp    f0103de4 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f01041ea:	52                   	push   %edx
f01041eb:	68 a7 5c 10 f0       	push   $0xf0105ca7
f01041f0:	53                   	push   %ebx
f01041f1:	56                   	push   %esi
f01041f2:	e8 aa fb ff ff       	call   f0103da1 <printfmt>
f01041f7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01041fa:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01041fd:	e9 e2 fb ff ff       	jmp    f0103de4 <vprintfmt+0x26>
f0104202:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0104205:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104208:	89 45 bc             	mov    %eax,-0x44(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010420b:	8b 45 14             	mov    0x14(%ebp),%eax
f010420e:	8d 48 04             	lea    0x4(%eax),%ecx
f0104211:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104214:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104216:	85 ff                	test   %edi,%edi
f0104218:	b8 23 65 10 f0       	mov    $0xf0106523,%eax
f010421d:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0104220:	80 7d c4 2d          	cmpb   $0x2d,-0x3c(%ebp)
f0104224:	0f 84 92 00 00 00    	je     f01042bc <vprintfmt+0x4fe>
f010422a:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
f010422e:	0f 8e 96 00 00 00    	jle    f01042ca <vprintfmt+0x50c>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104234:	83 ec 08             	sub    $0x8,%esp
f0104237:	52                   	push   %edx
f0104238:	57                   	push   %edi
f0104239:	e8 5f 03 00 00       	call   f010459d <strnlen>
f010423e:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0104241:	29 c1                	sub    %eax,%ecx
f0104243:	89 4d bc             	mov    %ecx,-0x44(%ebp)
f0104246:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104249:	0f be 45 c4          	movsbl -0x3c(%ebp),%eax
f010424d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0104250:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0104253:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104255:	eb 0f                	jmp    f0104266 <vprintfmt+0x4a8>
					putch(padc, putdat);
f0104257:	83 ec 08             	sub    $0x8,%esp
f010425a:	53                   	push   %ebx
f010425b:	ff 75 d0             	pushl  -0x30(%ebp)
f010425e:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104260:	83 ef 01             	sub    $0x1,%edi
f0104263:	83 c4 10             	add    $0x10,%esp
f0104266:	85 ff                	test   %edi,%edi
f0104268:	7f ed                	jg     f0104257 <vprintfmt+0x499>
f010426a:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010426d:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0104270:	85 c9                	test   %ecx,%ecx
f0104272:	b8 00 00 00 00       	mov    $0x0,%eax
f0104277:	0f 49 c1             	cmovns %ecx,%eax
f010427a:	29 c1                	sub    %eax,%ecx
f010427c:	89 75 08             	mov    %esi,0x8(%ebp)
f010427f:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0104282:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104285:	89 cb                	mov    %ecx,%ebx
f0104287:	eb 4d                	jmp    f01042d6 <vprintfmt+0x518>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104289:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
f010428d:	74 1b                	je     f01042aa <vprintfmt+0x4ec>
f010428f:	0f be c0             	movsbl %al,%eax
f0104292:	83 e8 20             	sub    $0x20,%eax
f0104295:	83 f8 5e             	cmp    $0x5e,%eax
f0104298:	76 10                	jbe    f01042aa <vprintfmt+0x4ec>
					putch('?', putdat);
f010429a:	83 ec 08             	sub    $0x8,%esp
f010429d:	ff 75 0c             	pushl  0xc(%ebp)
f01042a0:	6a 3f                	push   $0x3f
f01042a2:	ff 55 08             	call   *0x8(%ebp)
f01042a5:	83 c4 10             	add    $0x10,%esp
f01042a8:	eb 0d                	jmp    f01042b7 <vprintfmt+0x4f9>
				else
					putch(ch, putdat);
f01042aa:	83 ec 08             	sub    $0x8,%esp
f01042ad:	ff 75 0c             	pushl  0xc(%ebp)
f01042b0:	52                   	push   %edx
f01042b1:	ff 55 08             	call   *0x8(%ebp)
f01042b4:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01042b7:	83 eb 01             	sub    $0x1,%ebx
f01042ba:	eb 1a                	jmp    f01042d6 <vprintfmt+0x518>
f01042bc:	89 75 08             	mov    %esi,0x8(%ebp)
f01042bf:	8b 75 c0             	mov    -0x40(%ebp),%esi
f01042c2:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01042c5:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f01042c8:	eb 0c                	jmp    f01042d6 <vprintfmt+0x518>
f01042ca:	89 75 08             	mov    %esi,0x8(%ebp)
f01042cd:	8b 75 c0             	mov    -0x40(%ebp),%esi
f01042d0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01042d3:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f01042d6:	83 c7 01             	add    $0x1,%edi
f01042d9:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01042dd:	0f be d0             	movsbl %al,%edx
f01042e0:	85 d2                	test   %edx,%edx
f01042e2:	74 23                	je     f0104307 <vprintfmt+0x549>
f01042e4:	85 f6                	test   %esi,%esi
f01042e6:	78 a1                	js     f0104289 <vprintfmt+0x4cb>
f01042e8:	83 ee 01             	sub    $0x1,%esi
f01042eb:	79 9c                	jns    f0104289 <vprintfmt+0x4cb>
f01042ed:	89 df                	mov    %ebx,%edi
f01042ef:	8b 75 08             	mov    0x8(%ebp),%esi
f01042f2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01042f5:	eb 18                	jmp    f010430f <vprintfmt+0x551>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01042f7:	83 ec 08             	sub    $0x8,%esp
f01042fa:	53                   	push   %ebx
f01042fb:	6a 20                	push   $0x20
f01042fd:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01042ff:	83 ef 01             	sub    $0x1,%edi
f0104302:	83 c4 10             	add    $0x10,%esp
f0104305:	eb 08                	jmp    f010430f <vprintfmt+0x551>
f0104307:	89 df                	mov    %ebx,%edi
f0104309:	8b 75 08             	mov    0x8(%ebp),%esi
f010430c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010430f:	85 ff                	test   %edi,%edi
f0104311:	7f e4                	jg     f01042f7 <vprintfmt+0x539>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104313:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104316:	e9 c9 fa ff ff       	jmp    f0103de4 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010431b:	83 fa 01             	cmp    $0x1,%edx
f010431e:	7e 16                	jle    f0104336 <vprintfmt+0x578>
		return va_arg(*ap, long long);
f0104320:	8b 45 14             	mov    0x14(%ebp),%eax
f0104323:	8d 50 08             	lea    0x8(%eax),%edx
f0104326:	89 55 14             	mov    %edx,0x14(%ebp)
f0104329:	8b 50 04             	mov    0x4(%eax),%edx
f010432c:	8b 00                	mov    (%eax),%eax
f010432e:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0104331:	89 55 cc             	mov    %edx,-0x34(%ebp)
f0104334:	eb 32                	jmp    f0104368 <vprintfmt+0x5aa>
	else if (lflag)
f0104336:	85 d2                	test   %edx,%edx
f0104338:	74 18                	je     f0104352 <vprintfmt+0x594>
		return va_arg(*ap, long);
f010433a:	8b 45 14             	mov    0x14(%ebp),%eax
f010433d:	8d 50 04             	lea    0x4(%eax),%edx
f0104340:	89 55 14             	mov    %edx,0x14(%ebp)
f0104343:	8b 00                	mov    (%eax),%eax
f0104345:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0104348:	89 c1                	mov    %eax,%ecx
f010434a:	c1 f9 1f             	sar    $0x1f,%ecx
f010434d:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0104350:	eb 16                	jmp    f0104368 <vprintfmt+0x5aa>
	else
		return va_arg(*ap, int);
f0104352:	8b 45 14             	mov    0x14(%ebp),%eax
f0104355:	8d 50 04             	lea    0x4(%eax),%edx
f0104358:	89 55 14             	mov    %edx,0x14(%ebp)
f010435b:	8b 00                	mov    (%eax),%eax
f010435d:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0104360:	89 c1                	mov    %eax,%ecx
f0104362:	c1 f9 1f             	sar    $0x1f,%ecx
f0104365:	89 4d cc             	mov    %ecx,-0x34(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0104368:	8b 45 c8             	mov    -0x38(%ebp),%eax
f010436b:	8b 55 cc             	mov    -0x34(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010436e:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104373:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0104377:	79 74                	jns    f01043ed <vprintfmt+0x62f>
				putch('-', putdat);
f0104379:	83 ec 08             	sub    $0x8,%esp
f010437c:	53                   	push   %ebx
f010437d:	6a 2d                	push   $0x2d
f010437f:	ff d6                	call   *%esi
				num = -(long long) num;
f0104381:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0104384:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0104387:	f7 d8                	neg    %eax
f0104389:	83 d2 00             	adc    $0x0,%edx
f010438c:	f7 da                	neg    %edx
f010438e:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0104391:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0104396:	eb 55                	jmp    f01043ed <vprintfmt+0x62f>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104398:	8d 45 14             	lea    0x14(%ebp),%eax
f010439b:	e8 aa f9 ff ff       	call   f0103d4a <getuint>
			base = 10;
f01043a0:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01043a5:	eb 46                	jmp    f01043ed <vprintfmt+0x62f>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01043a7:	8d 45 14             	lea    0x14(%ebp),%eax
f01043aa:	e8 9b f9 ff ff       	call   f0103d4a <getuint>
			base = 8;
f01043af:	b9 08 00 00 00       	mov    $0x8,%ecx

			goto number;
f01043b4:	eb 37                	jmp    f01043ed <vprintfmt+0x62f>
		// pointer
		case 'p':
			putch('0', putdat);
f01043b6:	83 ec 08             	sub    $0x8,%esp
f01043b9:	53                   	push   %ebx
f01043ba:	6a 30                	push   $0x30
f01043bc:	ff d6                	call   *%esi
			putch('x', putdat);
f01043be:	83 c4 08             	add    $0x8,%esp
f01043c1:	53                   	push   %ebx
f01043c2:	6a 78                	push   $0x78
f01043c4:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01043c6:	8b 45 14             	mov    0x14(%ebp),%eax
f01043c9:	8d 50 04             	lea    0x4(%eax),%edx
f01043cc:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01043cf:	8b 00                	mov    (%eax),%eax
f01043d1:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01043d6:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01043d9:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01043de:	eb 0d                	jmp    f01043ed <vprintfmt+0x62f>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01043e0:	8d 45 14             	lea    0x14(%ebp),%eax
f01043e3:	e8 62 f9 ff ff       	call   f0103d4a <getuint>
			base = 16;
f01043e8:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01043ed:	83 ec 0c             	sub    $0xc,%esp
f01043f0:	0f be 7d c4          	movsbl -0x3c(%ebp),%edi
f01043f4:	57                   	push   %edi
f01043f5:	ff 75 d0             	pushl  -0x30(%ebp)
f01043f8:	51                   	push   %ecx
f01043f9:	52                   	push   %edx
f01043fa:	50                   	push   %eax
f01043fb:	89 da                	mov    %ebx,%edx
f01043fd:	89 f0                	mov    %esi,%eax
f01043ff:	e8 9c f8 ff ff       	call   f0103ca0 <printnum>
			break;
f0104404:	83 c4 20             	add    $0x20,%esp
f0104407:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010440a:	e9 d5 f9 ff ff       	jmp    f0103de4 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010440f:	83 ec 08             	sub    $0x8,%esp
f0104412:	53                   	push   %ebx
f0104413:	51                   	push   %ecx
f0104414:	ff d6                	call   *%esi
			break;
f0104416:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104419:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010441c:	e9 c3 f9 ff ff       	jmp    f0103de4 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104421:	83 ec 08             	sub    $0x8,%esp
f0104424:	53                   	push   %ebx
f0104425:	6a 25                	push   $0x25
f0104427:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104429:	83 c4 10             	add    $0x10,%esp
f010442c:	eb 03                	jmp    f0104431 <vprintfmt+0x673>
f010442e:	83 ef 01             	sub    $0x1,%edi
f0104431:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0104435:	75 f7                	jne    f010442e <vprintfmt+0x670>
f0104437:	e9 a8 f9 ff ff       	jmp    f0103de4 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f010443c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010443f:	5b                   	pop    %ebx
f0104440:	5e                   	pop    %esi
f0104441:	5f                   	pop    %edi
f0104442:	5d                   	pop    %ebp
f0104443:	c3                   	ret    

f0104444 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104444:	55                   	push   %ebp
f0104445:	89 e5                	mov    %esp,%ebp
f0104447:	83 ec 18             	sub    $0x18,%esp
f010444a:	8b 45 08             	mov    0x8(%ebp),%eax
f010444d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104450:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104453:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104457:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010445a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104461:	85 c0                	test   %eax,%eax
f0104463:	74 26                	je     f010448b <vsnprintf+0x47>
f0104465:	85 d2                	test   %edx,%edx
f0104467:	7e 22                	jle    f010448b <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104469:	ff 75 14             	pushl  0x14(%ebp)
f010446c:	ff 75 10             	pushl  0x10(%ebp)
f010446f:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104472:	50                   	push   %eax
f0104473:	68 84 3d 10 f0       	push   $0xf0103d84
f0104478:	e8 41 f9 ff ff       	call   f0103dbe <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010447d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104480:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104483:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104486:	83 c4 10             	add    $0x10,%esp
f0104489:	eb 05                	jmp    f0104490 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010448b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104490:	c9                   	leave  
f0104491:	c3                   	ret    

f0104492 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104492:	55                   	push   %ebp
f0104493:	89 e5                	mov    %esp,%ebp
f0104495:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104498:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010449b:	50                   	push   %eax
f010449c:	ff 75 10             	pushl  0x10(%ebp)
f010449f:	ff 75 0c             	pushl  0xc(%ebp)
f01044a2:	ff 75 08             	pushl  0x8(%ebp)
f01044a5:	e8 9a ff ff ff       	call   f0104444 <vsnprintf>
	va_end(ap);

	return rc;
}
f01044aa:	c9                   	leave  
f01044ab:	c3                   	ret    

f01044ac <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01044ac:	55                   	push   %ebp
f01044ad:	89 e5                	mov    %esp,%ebp
f01044af:	57                   	push   %edi
f01044b0:	56                   	push   %esi
f01044b1:	53                   	push   %ebx
f01044b2:	83 ec 0c             	sub    $0xc,%esp
f01044b5:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01044b8:	85 c0                	test   %eax,%eax
f01044ba:	74 11                	je     f01044cd <readline+0x21>
		cprintf("%s", prompt);
f01044bc:	83 ec 08             	sub    $0x8,%esp
f01044bf:	50                   	push   %eax
f01044c0:	68 a7 5c 10 f0       	push   $0xf0105ca7
f01044c5:	e8 33 ed ff ff       	call   f01031fd <cprintf>
f01044ca:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01044cd:	83 ec 0c             	sub    $0xc,%esp
f01044d0:	6a 00                	push   $0x0
f01044d2:	e8 3e c1 ff ff       	call   f0100615 <iscons>
f01044d7:	89 c7                	mov    %eax,%edi
f01044d9:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01044dc:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01044e1:	e8 1e c1 ff ff       	call   f0100604 <getchar>
f01044e6:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01044e8:	85 c0                	test   %eax,%eax
f01044ea:	79 18                	jns    f0104504 <readline+0x58>
			cprintf("read error: %e\n", c);
f01044ec:	83 ec 08             	sub    $0x8,%esp
f01044ef:	50                   	push   %eax
f01044f0:	68 40 67 10 f0       	push   $0xf0106740
f01044f5:	e8 03 ed ff ff       	call   f01031fd <cprintf>
			return NULL;
f01044fa:	83 c4 10             	add    $0x10,%esp
f01044fd:	b8 00 00 00 00       	mov    $0x0,%eax
f0104502:	eb 79                	jmp    f010457d <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104504:	83 f8 7f             	cmp    $0x7f,%eax
f0104507:	0f 94 c2             	sete   %dl
f010450a:	83 f8 08             	cmp    $0x8,%eax
f010450d:	0f 94 c0             	sete   %al
f0104510:	08 c2                	or     %al,%dl
f0104512:	74 1a                	je     f010452e <readline+0x82>
f0104514:	85 f6                	test   %esi,%esi
f0104516:	7e 16                	jle    f010452e <readline+0x82>
			if (echoing)
f0104518:	85 ff                	test   %edi,%edi
f010451a:	74 0d                	je     f0104529 <readline+0x7d>
				cputchar('\b');
f010451c:	83 ec 0c             	sub    $0xc,%esp
f010451f:	6a 08                	push   $0x8
f0104521:	e8 ce c0 ff ff       	call   f01005f4 <cputchar>
f0104526:	83 c4 10             	add    $0x10,%esp
			i--;
f0104529:	83 ee 01             	sub    $0x1,%esi
f010452c:	eb b3                	jmp    f01044e1 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010452e:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104534:	7f 20                	jg     f0104556 <readline+0xaa>
f0104536:	83 fb 1f             	cmp    $0x1f,%ebx
f0104539:	7e 1b                	jle    f0104556 <readline+0xaa>
			if (echoing)
f010453b:	85 ff                	test   %edi,%edi
f010453d:	74 0c                	je     f010454b <readline+0x9f>
				cputchar(c);
f010453f:	83 ec 0c             	sub    $0xc,%esp
f0104542:	53                   	push   %ebx
f0104543:	e8 ac c0 ff ff       	call   f01005f4 <cputchar>
f0104548:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010454b:	88 9e 80 ed 17 f0    	mov    %bl,-0xfe81280(%esi)
f0104551:	8d 76 01             	lea    0x1(%esi),%esi
f0104554:	eb 8b                	jmp    f01044e1 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0104556:	83 fb 0d             	cmp    $0xd,%ebx
f0104559:	74 05                	je     f0104560 <readline+0xb4>
f010455b:	83 fb 0a             	cmp    $0xa,%ebx
f010455e:	75 81                	jne    f01044e1 <readline+0x35>
			if (echoing)
f0104560:	85 ff                	test   %edi,%edi
f0104562:	74 0d                	je     f0104571 <readline+0xc5>
				cputchar('\n');
f0104564:	83 ec 0c             	sub    $0xc,%esp
f0104567:	6a 0a                	push   $0xa
f0104569:	e8 86 c0 ff ff       	call   f01005f4 <cputchar>
f010456e:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0104571:	c6 86 80 ed 17 f0 00 	movb   $0x0,-0xfe81280(%esi)
			return buf;
f0104578:	b8 80 ed 17 f0       	mov    $0xf017ed80,%eax
		}
	}
}
f010457d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104580:	5b                   	pop    %ebx
f0104581:	5e                   	pop    %esi
f0104582:	5f                   	pop    %edi
f0104583:	5d                   	pop    %ebp
f0104584:	c3                   	ret    

f0104585 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104585:	55                   	push   %ebp
f0104586:	89 e5                	mov    %esp,%ebp
f0104588:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010458b:	b8 00 00 00 00       	mov    $0x0,%eax
f0104590:	eb 03                	jmp    f0104595 <strlen+0x10>
		n++;
f0104592:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104595:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104599:	75 f7                	jne    f0104592 <strlen+0xd>
		n++;
	return n;
}
f010459b:	5d                   	pop    %ebp
f010459c:	c3                   	ret    

f010459d <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010459d:	55                   	push   %ebp
f010459e:	89 e5                	mov    %esp,%ebp
f01045a0:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01045a3:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01045a6:	ba 00 00 00 00       	mov    $0x0,%edx
f01045ab:	eb 03                	jmp    f01045b0 <strnlen+0x13>
		n++;
f01045ad:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01045b0:	39 c2                	cmp    %eax,%edx
f01045b2:	74 08                	je     f01045bc <strnlen+0x1f>
f01045b4:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01045b8:	75 f3                	jne    f01045ad <strnlen+0x10>
f01045ba:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01045bc:	5d                   	pop    %ebp
f01045bd:	c3                   	ret    

f01045be <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01045be:	55                   	push   %ebp
f01045bf:	89 e5                	mov    %esp,%ebp
f01045c1:	53                   	push   %ebx
f01045c2:	8b 45 08             	mov    0x8(%ebp),%eax
f01045c5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01045c8:	89 c2                	mov    %eax,%edx
f01045ca:	83 c2 01             	add    $0x1,%edx
f01045cd:	83 c1 01             	add    $0x1,%ecx
f01045d0:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01045d4:	88 5a ff             	mov    %bl,-0x1(%edx)
f01045d7:	84 db                	test   %bl,%bl
f01045d9:	75 ef                	jne    f01045ca <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01045db:	5b                   	pop    %ebx
f01045dc:	5d                   	pop    %ebp
f01045dd:	c3                   	ret    

f01045de <strcat>:

char *
strcat(char *dst, const char *src)
{
f01045de:	55                   	push   %ebp
f01045df:	89 e5                	mov    %esp,%ebp
f01045e1:	53                   	push   %ebx
f01045e2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01045e5:	53                   	push   %ebx
f01045e6:	e8 9a ff ff ff       	call   f0104585 <strlen>
f01045eb:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01045ee:	ff 75 0c             	pushl  0xc(%ebp)
f01045f1:	01 d8                	add    %ebx,%eax
f01045f3:	50                   	push   %eax
f01045f4:	e8 c5 ff ff ff       	call   f01045be <strcpy>
	return dst;
}
f01045f9:	89 d8                	mov    %ebx,%eax
f01045fb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01045fe:	c9                   	leave  
f01045ff:	c3                   	ret    

f0104600 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104600:	55                   	push   %ebp
f0104601:	89 e5                	mov    %esp,%ebp
f0104603:	56                   	push   %esi
f0104604:	53                   	push   %ebx
f0104605:	8b 75 08             	mov    0x8(%ebp),%esi
f0104608:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010460b:	89 f3                	mov    %esi,%ebx
f010460d:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104610:	89 f2                	mov    %esi,%edx
f0104612:	eb 0f                	jmp    f0104623 <strncpy+0x23>
		*dst++ = *src;
f0104614:	83 c2 01             	add    $0x1,%edx
f0104617:	0f b6 01             	movzbl (%ecx),%eax
f010461a:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010461d:	80 39 01             	cmpb   $0x1,(%ecx)
f0104620:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104623:	39 da                	cmp    %ebx,%edx
f0104625:	75 ed                	jne    f0104614 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104627:	89 f0                	mov    %esi,%eax
f0104629:	5b                   	pop    %ebx
f010462a:	5e                   	pop    %esi
f010462b:	5d                   	pop    %ebp
f010462c:	c3                   	ret    

f010462d <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010462d:	55                   	push   %ebp
f010462e:	89 e5                	mov    %esp,%ebp
f0104630:	56                   	push   %esi
f0104631:	53                   	push   %ebx
f0104632:	8b 75 08             	mov    0x8(%ebp),%esi
f0104635:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104638:	8b 55 10             	mov    0x10(%ebp),%edx
f010463b:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010463d:	85 d2                	test   %edx,%edx
f010463f:	74 21                	je     f0104662 <strlcpy+0x35>
f0104641:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104645:	89 f2                	mov    %esi,%edx
f0104647:	eb 09                	jmp    f0104652 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104649:	83 c2 01             	add    $0x1,%edx
f010464c:	83 c1 01             	add    $0x1,%ecx
f010464f:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104652:	39 c2                	cmp    %eax,%edx
f0104654:	74 09                	je     f010465f <strlcpy+0x32>
f0104656:	0f b6 19             	movzbl (%ecx),%ebx
f0104659:	84 db                	test   %bl,%bl
f010465b:	75 ec                	jne    f0104649 <strlcpy+0x1c>
f010465d:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010465f:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104662:	29 f0                	sub    %esi,%eax
}
f0104664:	5b                   	pop    %ebx
f0104665:	5e                   	pop    %esi
f0104666:	5d                   	pop    %ebp
f0104667:	c3                   	ret    

f0104668 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104668:	55                   	push   %ebp
f0104669:	89 e5                	mov    %esp,%ebp
f010466b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010466e:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104671:	eb 06                	jmp    f0104679 <strcmp+0x11>
		p++, q++;
f0104673:	83 c1 01             	add    $0x1,%ecx
f0104676:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104679:	0f b6 01             	movzbl (%ecx),%eax
f010467c:	84 c0                	test   %al,%al
f010467e:	74 04                	je     f0104684 <strcmp+0x1c>
f0104680:	3a 02                	cmp    (%edx),%al
f0104682:	74 ef                	je     f0104673 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104684:	0f b6 c0             	movzbl %al,%eax
f0104687:	0f b6 12             	movzbl (%edx),%edx
f010468a:	29 d0                	sub    %edx,%eax
}
f010468c:	5d                   	pop    %ebp
f010468d:	c3                   	ret    

f010468e <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010468e:	55                   	push   %ebp
f010468f:	89 e5                	mov    %esp,%ebp
f0104691:	53                   	push   %ebx
f0104692:	8b 45 08             	mov    0x8(%ebp),%eax
f0104695:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104698:	89 c3                	mov    %eax,%ebx
f010469a:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010469d:	eb 06                	jmp    f01046a5 <strncmp+0x17>
		n--, p++, q++;
f010469f:	83 c0 01             	add    $0x1,%eax
f01046a2:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01046a5:	39 d8                	cmp    %ebx,%eax
f01046a7:	74 15                	je     f01046be <strncmp+0x30>
f01046a9:	0f b6 08             	movzbl (%eax),%ecx
f01046ac:	84 c9                	test   %cl,%cl
f01046ae:	74 04                	je     f01046b4 <strncmp+0x26>
f01046b0:	3a 0a                	cmp    (%edx),%cl
f01046b2:	74 eb                	je     f010469f <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01046b4:	0f b6 00             	movzbl (%eax),%eax
f01046b7:	0f b6 12             	movzbl (%edx),%edx
f01046ba:	29 d0                	sub    %edx,%eax
f01046bc:	eb 05                	jmp    f01046c3 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01046be:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01046c3:	5b                   	pop    %ebx
f01046c4:	5d                   	pop    %ebp
f01046c5:	c3                   	ret    

f01046c6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01046c6:	55                   	push   %ebp
f01046c7:	89 e5                	mov    %esp,%ebp
f01046c9:	8b 45 08             	mov    0x8(%ebp),%eax
f01046cc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01046d0:	eb 07                	jmp    f01046d9 <strchr+0x13>
		if (*s == c)
f01046d2:	38 ca                	cmp    %cl,%dl
f01046d4:	74 0f                	je     f01046e5 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01046d6:	83 c0 01             	add    $0x1,%eax
f01046d9:	0f b6 10             	movzbl (%eax),%edx
f01046dc:	84 d2                	test   %dl,%dl
f01046de:	75 f2                	jne    f01046d2 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01046e0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01046e5:	5d                   	pop    %ebp
f01046e6:	c3                   	ret    

f01046e7 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01046e7:	55                   	push   %ebp
f01046e8:	89 e5                	mov    %esp,%ebp
f01046ea:	8b 45 08             	mov    0x8(%ebp),%eax
f01046ed:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01046f1:	eb 03                	jmp    f01046f6 <strfind+0xf>
f01046f3:	83 c0 01             	add    $0x1,%eax
f01046f6:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01046f9:	84 d2                	test   %dl,%dl
f01046fb:	74 04                	je     f0104701 <strfind+0x1a>
f01046fd:	38 ca                	cmp    %cl,%dl
f01046ff:	75 f2                	jne    f01046f3 <strfind+0xc>
			break;
	return (char *) s;
}
f0104701:	5d                   	pop    %ebp
f0104702:	c3                   	ret    

f0104703 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104703:	55                   	push   %ebp
f0104704:	89 e5                	mov    %esp,%ebp
f0104706:	57                   	push   %edi
f0104707:	56                   	push   %esi
f0104708:	53                   	push   %ebx
f0104709:	8b 7d 08             	mov    0x8(%ebp),%edi
f010470c:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010470f:	85 c9                	test   %ecx,%ecx
f0104711:	74 36                	je     f0104749 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104713:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104719:	75 28                	jne    f0104743 <memset+0x40>
f010471b:	f6 c1 03             	test   $0x3,%cl
f010471e:	75 23                	jne    f0104743 <memset+0x40>
		c &= 0xFF;
f0104720:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104724:	89 d3                	mov    %edx,%ebx
f0104726:	c1 e3 08             	shl    $0x8,%ebx
f0104729:	89 d6                	mov    %edx,%esi
f010472b:	c1 e6 18             	shl    $0x18,%esi
f010472e:	89 d0                	mov    %edx,%eax
f0104730:	c1 e0 10             	shl    $0x10,%eax
f0104733:	09 f0                	or     %esi,%eax
f0104735:	09 c2                	or     %eax,%edx
f0104737:	89 d0                	mov    %edx,%eax
f0104739:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010473b:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f010473e:	fc                   	cld    
f010473f:	f3 ab                	rep stos %eax,%es:(%edi)
f0104741:	eb 06                	jmp    f0104749 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104743:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104746:	fc                   	cld    
f0104747:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104749:	89 f8                	mov    %edi,%eax
f010474b:	5b                   	pop    %ebx
f010474c:	5e                   	pop    %esi
f010474d:	5f                   	pop    %edi
f010474e:	5d                   	pop    %ebp
f010474f:	c3                   	ret    

f0104750 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104750:	55                   	push   %ebp
f0104751:	89 e5                	mov    %esp,%ebp
f0104753:	57                   	push   %edi
f0104754:	56                   	push   %esi
f0104755:	8b 45 08             	mov    0x8(%ebp),%eax
f0104758:	8b 75 0c             	mov    0xc(%ebp),%esi
f010475b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010475e:	39 c6                	cmp    %eax,%esi
f0104760:	73 35                	jae    f0104797 <memmove+0x47>
f0104762:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104765:	39 d0                	cmp    %edx,%eax
f0104767:	73 2e                	jae    f0104797 <memmove+0x47>
		s += n;
		d += n;
f0104769:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f010476c:	89 d6                	mov    %edx,%esi
f010476e:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104770:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104776:	75 13                	jne    f010478b <memmove+0x3b>
f0104778:	f6 c1 03             	test   $0x3,%cl
f010477b:	75 0e                	jne    f010478b <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f010477d:	83 ef 04             	sub    $0x4,%edi
f0104780:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104783:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0104786:	fd                   	std    
f0104787:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104789:	eb 09                	jmp    f0104794 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010478b:	83 ef 01             	sub    $0x1,%edi
f010478e:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104791:	fd                   	std    
f0104792:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104794:	fc                   	cld    
f0104795:	eb 1d                	jmp    f01047b4 <memmove+0x64>
f0104797:	89 f2                	mov    %esi,%edx
f0104799:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010479b:	f6 c2 03             	test   $0x3,%dl
f010479e:	75 0f                	jne    f01047af <memmove+0x5f>
f01047a0:	f6 c1 03             	test   $0x3,%cl
f01047a3:	75 0a                	jne    f01047af <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01047a5:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01047a8:	89 c7                	mov    %eax,%edi
f01047aa:	fc                   	cld    
f01047ab:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01047ad:	eb 05                	jmp    f01047b4 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01047af:	89 c7                	mov    %eax,%edi
f01047b1:	fc                   	cld    
f01047b2:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01047b4:	5e                   	pop    %esi
f01047b5:	5f                   	pop    %edi
f01047b6:	5d                   	pop    %ebp
f01047b7:	c3                   	ret    

f01047b8 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01047b8:	55                   	push   %ebp
f01047b9:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01047bb:	ff 75 10             	pushl  0x10(%ebp)
f01047be:	ff 75 0c             	pushl  0xc(%ebp)
f01047c1:	ff 75 08             	pushl  0x8(%ebp)
f01047c4:	e8 87 ff ff ff       	call   f0104750 <memmove>
}
f01047c9:	c9                   	leave  
f01047ca:	c3                   	ret    

f01047cb <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01047cb:	55                   	push   %ebp
f01047cc:	89 e5                	mov    %esp,%ebp
f01047ce:	56                   	push   %esi
f01047cf:	53                   	push   %ebx
f01047d0:	8b 45 08             	mov    0x8(%ebp),%eax
f01047d3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01047d6:	89 c6                	mov    %eax,%esi
f01047d8:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01047db:	eb 1a                	jmp    f01047f7 <memcmp+0x2c>
		if (*s1 != *s2)
f01047dd:	0f b6 08             	movzbl (%eax),%ecx
f01047e0:	0f b6 1a             	movzbl (%edx),%ebx
f01047e3:	38 d9                	cmp    %bl,%cl
f01047e5:	74 0a                	je     f01047f1 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01047e7:	0f b6 c1             	movzbl %cl,%eax
f01047ea:	0f b6 db             	movzbl %bl,%ebx
f01047ed:	29 d8                	sub    %ebx,%eax
f01047ef:	eb 0f                	jmp    f0104800 <memcmp+0x35>
		s1++, s2++;
f01047f1:	83 c0 01             	add    $0x1,%eax
f01047f4:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01047f7:	39 f0                	cmp    %esi,%eax
f01047f9:	75 e2                	jne    f01047dd <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01047fb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104800:	5b                   	pop    %ebx
f0104801:	5e                   	pop    %esi
f0104802:	5d                   	pop    %ebp
f0104803:	c3                   	ret    

f0104804 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104804:	55                   	push   %ebp
f0104805:	89 e5                	mov    %esp,%ebp
f0104807:	8b 45 08             	mov    0x8(%ebp),%eax
f010480a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010480d:	89 c2                	mov    %eax,%edx
f010480f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104812:	eb 07                	jmp    f010481b <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104814:	38 08                	cmp    %cl,(%eax)
f0104816:	74 07                	je     f010481f <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104818:	83 c0 01             	add    $0x1,%eax
f010481b:	39 d0                	cmp    %edx,%eax
f010481d:	72 f5                	jb     f0104814 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010481f:	5d                   	pop    %ebp
f0104820:	c3                   	ret    

f0104821 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104821:	55                   	push   %ebp
f0104822:	89 e5                	mov    %esp,%ebp
f0104824:	57                   	push   %edi
f0104825:	56                   	push   %esi
f0104826:	53                   	push   %ebx
f0104827:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010482a:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010482d:	eb 03                	jmp    f0104832 <strtol+0x11>
		s++;
f010482f:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104832:	0f b6 01             	movzbl (%ecx),%eax
f0104835:	3c 09                	cmp    $0x9,%al
f0104837:	74 f6                	je     f010482f <strtol+0xe>
f0104839:	3c 20                	cmp    $0x20,%al
f010483b:	74 f2                	je     f010482f <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010483d:	3c 2b                	cmp    $0x2b,%al
f010483f:	75 0a                	jne    f010484b <strtol+0x2a>
		s++;
f0104841:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104844:	bf 00 00 00 00       	mov    $0x0,%edi
f0104849:	eb 10                	jmp    f010485b <strtol+0x3a>
f010484b:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104850:	3c 2d                	cmp    $0x2d,%al
f0104852:	75 07                	jne    f010485b <strtol+0x3a>
		s++, neg = 1;
f0104854:	8d 49 01             	lea    0x1(%ecx),%ecx
f0104857:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010485b:	85 db                	test   %ebx,%ebx
f010485d:	0f 94 c0             	sete   %al
f0104860:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104866:	75 19                	jne    f0104881 <strtol+0x60>
f0104868:	80 39 30             	cmpb   $0x30,(%ecx)
f010486b:	75 14                	jne    f0104881 <strtol+0x60>
f010486d:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0104871:	0f 85 82 00 00 00    	jne    f01048f9 <strtol+0xd8>
		s += 2, base = 16;
f0104877:	83 c1 02             	add    $0x2,%ecx
f010487a:	bb 10 00 00 00       	mov    $0x10,%ebx
f010487f:	eb 16                	jmp    f0104897 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0104881:	84 c0                	test   %al,%al
f0104883:	74 12                	je     f0104897 <strtol+0x76>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104885:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010488a:	80 39 30             	cmpb   $0x30,(%ecx)
f010488d:	75 08                	jne    f0104897 <strtol+0x76>
		s++, base = 8;
f010488f:	83 c1 01             	add    $0x1,%ecx
f0104892:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0104897:	b8 00 00 00 00       	mov    $0x0,%eax
f010489c:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010489f:	0f b6 11             	movzbl (%ecx),%edx
f01048a2:	8d 72 d0             	lea    -0x30(%edx),%esi
f01048a5:	89 f3                	mov    %esi,%ebx
f01048a7:	80 fb 09             	cmp    $0x9,%bl
f01048aa:	77 08                	ja     f01048b4 <strtol+0x93>
			dig = *s - '0';
f01048ac:	0f be d2             	movsbl %dl,%edx
f01048af:	83 ea 30             	sub    $0x30,%edx
f01048b2:	eb 22                	jmp    f01048d6 <strtol+0xb5>
		else if (*s >= 'a' && *s <= 'z')
f01048b4:	8d 72 9f             	lea    -0x61(%edx),%esi
f01048b7:	89 f3                	mov    %esi,%ebx
f01048b9:	80 fb 19             	cmp    $0x19,%bl
f01048bc:	77 08                	ja     f01048c6 <strtol+0xa5>
			dig = *s - 'a' + 10;
f01048be:	0f be d2             	movsbl %dl,%edx
f01048c1:	83 ea 57             	sub    $0x57,%edx
f01048c4:	eb 10                	jmp    f01048d6 <strtol+0xb5>
		else if (*s >= 'A' && *s <= 'Z')
f01048c6:	8d 72 bf             	lea    -0x41(%edx),%esi
f01048c9:	89 f3                	mov    %esi,%ebx
f01048cb:	80 fb 19             	cmp    $0x19,%bl
f01048ce:	77 16                	ja     f01048e6 <strtol+0xc5>
			dig = *s - 'A' + 10;
f01048d0:	0f be d2             	movsbl %dl,%edx
f01048d3:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01048d6:	3b 55 10             	cmp    0x10(%ebp),%edx
f01048d9:	7d 0f                	jge    f01048ea <strtol+0xc9>
			break;
		s++, val = (val * base) + dig;
f01048db:	83 c1 01             	add    $0x1,%ecx
f01048de:	0f af 45 10          	imul   0x10(%ebp),%eax
f01048e2:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01048e4:	eb b9                	jmp    f010489f <strtol+0x7e>
f01048e6:	89 c2                	mov    %eax,%edx
f01048e8:	eb 02                	jmp    f01048ec <strtol+0xcb>
f01048ea:	89 c2                	mov    %eax,%edx

	if (endptr)
f01048ec:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01048f0:	74 0d                	je     f01048ff <strtol+0xde>
		*endptr = (char *) s;
f01048f2:	8b 75 0c             	mov    0xc(%ebp),%esi
f01048f5:	89 0e                	mov    %ecx,(%esi)
f01048f7:	eb 06                	jmp    f01048ff <strtol+0xde>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01048f9:	84 c0                	test   %al,%al
f01048fb:	75 92                	jne    f010488f <strtol+0x6e>
f01048fd:	eb 98                	jmp    f0104897 <strtol+0x76>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01048ff:	f7 da                	neg    %edx
f0104901:	85 ff                	test   %edi,%edi
f0104903:	0f 45 c2             	cmovne %edx,%eax
}
f0104906:	5b                   	pop    %ebx
f0104907:	5e                   	pop    %esi
f0104908:	5f                   	pop    %edi
f0104909:	5d                   	pop    %ebp
f010490a:	c3                   	ret    
f010490b:	66 90                	xchg   %ax,%ax
f010490d:	66 90                	xchg   %ax,%ax
f010490f:	90                   	nop

f0104910 <__udivdi3>:
f0104910:	55                   	push   %ebp
f0104911:	57                   	push   %edi
f0104912:	56                   	push   %esi
f0104913:	83 ec 10             	sub    $0x10,%esp
f0104916:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f010491a:	8b 7c 24 20          	mov    0x20(%esp),%edi
f010491e:	8b 74 24 24          	mov    0x24(%esp),%esi
f0104922:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0104926:	85 d2                	test   %edx,%edx
f0104928:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010492c:	89 34 24             	mov    %esi,(%esp)
f010492f:	89 c8                	mov    %ecx,%eax
f0104931:	75 35                	jne    f0104968 <__udivdi3+0x58>
f0104933:	39 f1                	cmp    %esi,%ecx
f0104935:	0f 87 bd 00 00 00    	ja     f01049f8 <__udivdi3+0xe8>
f010493b:	85 c9                	test   %ecx,%ecx
f010493d:	89 cd                	mov    %ecx,%ebp
f010493f:	75 0b                	jne    f010494c <__udivdi3+0x3c>
f0104941:	b8 01 00 00 00       	mov    $0x1,%eax
f0104946:	31 d2                	xor    %edx,%edx
f0104948:	f7 f1                	div    %ecx
f010494a:	89 c5                	mov    %eax,%ebp
f010494c:	89 f0                	mov    %esi,%eax
f010494e:	31 d2                	xor    %edx,%edx
f0104950:	f7 f5                	div    %ebp
f0104952:	89 c6                	mov    %eax,%esi
f0104954:	89 f8                	mov    %edi,%eax
f0104956:	f7 f5                	div    %ebp
f0104958:	89 f2                	mov    %esi,%edx
f010495a:	83 c4 10             	add    $0x10,%esp
f010495d:	5e                   	pop    %esi
f010495e:	5f                   	pop    %edi
f010495f:	5d                   	pop    %ebp
f0104960:	c3                   	ret    
f0104961:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104968:	3b 14 24             	cmp    (%esp),%edx
f010496b:	77 7b                	ja     f01049e8 <__udivdi3+0xd8>
f010496d:	0f bd f2             	bsr    %edx,%esi
f0104970:	83 f6 1f             	xor    $0x1f,%esi
f0104973:	0f 84 97 00 00 00    	je     f0104a10 <__udivdi3+0x100>
f0104979:	bd 20 00 00 00       	mov    $0x20,%ebp
f010497e:	89 d7                	mov    %edx,%edi
f0104980:	89 f1                	mov    %esi,%ecx
f0104982:	29 f5                	sub    %esi,%ebp
f0104984:	d3 e7                	shl    %cl,%edi
f0104986:	89 c2                	mov    %eax,%edx
f0104988:	89 e9                	mov    %ebp,%ecx
f010498a:	d3 ea                	shr    %cl,%edx
f010498c:	89 f1                	mov    %esi,%ecx
f010498e:	09 fa                	or     %edi,%edx
f0104990:	8b 3c 24             	mov    (%esp),%edi
f0104993:	d3 e0                	shl    %cl,%eax
f0104995:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104999:	89 e9                	mov    %ebp,%ecx
f010499b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010499f:	8b 44 24 04          	mov    0x4(%esp),%eax
f01049a3:	89 fa                	mov    %edi,%edx
f01049a5:	d3 ea                	shr    %cl,%edx
f01049a7:	89 f1                	mov    %esi,%ecx
f01049a9:	d3 e7                	shl    %cl,%edi
f01049ab:	89 e9                	mov    %ebp,%ecx
f01049ad:	d3 e8                	shr    %cl,%eax
f01049af:	09 c7                	or     %eax,%edi
f01049b1:	89 f8                	mov    %edi,%eax
f01049b3:	f7 74 24 08          	divl   0x8(%esp)
f01049b7:	89 d5                	mov    %edx,%ebp
f01049b9:	89 c7                	mov    %eax,%edi
f01049bb:	f7 64 24 0c          	mull   0xc(%esp)
f01049bf:	39 d5                	cmp    %edx,%ebp
f01049c1:	89 14 24             	mov    %edx,(%esp)
f01049c4:	72 11                	jb     f01049d7 <__udivdi3+0xc7>
f01049c6:	8b 54 24 04          	mov    0x4(%esp),%edx
f01049ca:	89 f1                	mov    %esi,%ecx
f01049cc:	d3 e2                	shl    %cl,%edx
f01049ce:	39 c2                	cmp    %eax,%edx
f01049d0:	73 5e                	jae    f0104a30 <__udivdi3+0x120>
f01049d2:	3b 2c 24             	cmp    (%esp),%ebp
f01049d5:	75 59                	jne    f0104a30 <__udivdi3+0x120>
f01049d7:	8d 47 ff             	lea    -0x1(%edi),%eax
f01049da:	31 f6                	xor    %esi,%esi
f01049dc:	89 f2                	mov    %esi,%edx
f01049de:	83 c4 10             	add    $0x10,%esp
f01049e1:	5e                   	pop    %esi
f01049e2:	5f                   	pop    %edi
f01049e3:	5d                   	pop    %ebp
f01049e4:	c3                   	ret    
f01049e5:	8d 76 00             	lea    0x0(%esi),%esi
f01049e8:	31 f6                	xor    %esi,%esi
f01049ea:	31 c0                	xor    %eax,%eax
f01049ec:	89 f2                	mov    %esi,%edx
f01049ee:	83 c4 10             	add    $0x10,%esp
f01049f1:	5e                   	pop    %esi
f01049f2:	5f                   	pop    %edi
f01049f3:	5d                   	pop    %ebp
f01049f4:	c3                   	ret    
f01049f5:	8d 76 00             	lea    0x0(%esi),%esi
f01049f8:	89 f2                	mov    %esi,%edx
f01049fa:	31 f6                	xor    %esi,%esi
f01049fc:	89 f8                	mov    %edi,%eax
f01049fe:	f7 f1                	div    %ecx
f0104a00:	89 f2                	mov    %esi,%edx
f0104a02:	83 c4 10             	add    $0x10,%esp
f0104a05:	5e                   	pop    %esi
f0104a06:	5f                   	pop    %edi
f0104a07:	5d                   	pop    %ebp
f0104a08:	c3                   	ret    
f0104a09:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104a10:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f0104a14:	76 0b                	jbe    f0104a21 <__udivdi3+0x111>
f0104a16:	31 c0                	xor    %eax,%eax
f0104a18:	3b 14 24             	cmp    (%esp),%edx
f0104a1b:	0f 83 37 ff ff ff    	jae    f0104958 <__udivdi3+0x48>
f0104a21:	b8 01 00 00 00       	mov    $0x1,%eax
f0104a26:	e9 2d ff ff ff       	jmp    f0104958 <__udivdi3+0x48>
f0104a2b:	90                   	nop
f0104a2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104a30:	89 f8                	mov    %edi,%eax
f0104a32:	31 f6                	xor    %esi,%esi
f0104a34:	e9 1f ff ff ff       	jmp    f0104958 <__udivdi3+0x48>
f0104a39:	66 90                	xchg   %ax,%ax
f0104a3b:	66 90                	xchg   %ax,%ax
f0104a3d:	66 90                	xchg   %ax,%ax
f0104a3f:	90                   	nop

f0104a40 <__umoddi3>:
f0104a40:	55                   	push   %ebp
f0104a41:	57                   	push   %edi
f0104a42:	56                   	push   %esi
f0104a43:	83 ec 20             	sub    $0x20,%esp
f0104a46:	8b 44 24 34          	mov    0x34(%esp),%eax
f0104a4a:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0104a4e:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104a52:	89 c6                	mov    %eax,%esi
f0104a54:	89 44 24 10          	mov    %eax,0x10(%esp)
f0104a58:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0104a5c:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0104a60:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104a64:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0104a68:	89 74 24 18          	mov    %esi,0x18(%esp)
f0104a6c:	85 c0                	test   %eax,%eax
f0104a6e:	89 c2                	mov    %eax,%edx
f0104a70:	75 1e                	jne    f0104a90 <__umoddi3+0x50>
f0104a72:	39 f7                	cmp    %esi,%edi
f0104a74:	76 52                	jbe    f0104ac8 <__umoddi3+0x88>
f0104a76:	89 c8                	mov    %ecx,%eax
f0104a78:	89 f2                	mov    %esi,%edx
f0104a7a:	f7 f7                	div    %edi
f0104a7c:	89 d0                	mov    %edx,%eax
f0104a7e:	31 d2                	xor    %edx,%edx
f0104a80:	83 c4 20             	add    $0x20,%esp
f0104a83:	5e                   	pop    %esi
f0104a84:	5f                   	pop    %edi
f0104a85:	5d                   	pop    %ebp
f0104a86:	c3                   	ret    
f0104a87:	89 f6                	mov    %esi,%esi
f0104a89:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0104a90:	39 f0                	cmp    %esi,%eax
f0104a92:	77 5c                	ja     f0104af0 <__umoddi3+0xb0>
f0104a94:	0f bd e8             	bsr    %eax,%ebp
f0104a97:	83 f5 1f             	xor    $0x1f,%ebp
f0104a9a:	75 64                	jne    f0104b00 <__umoddi3+0xc0>
f0104a9c:	8b 6c 24 14          	mov    0x14(%esp),%ebp
f0104aa0:	39 6c 24 0c          	cmp    %ebp,0xc(%esp)
f0104aa4:	0f 86 f6 00 00 00    	jbe    f0104ba0 <__umoddi3+0x160>
f0104aaa:	3b 44 24 18          	cmp    0x18(%esp),%eax
f0104aae:	0f 82 ec 00 00 00    	jb     f0104ba0 <__umoddi3+0x160>
f0104ab4:	8b 44 24 14          	mov    0x14(%esp),%eax
f0104ab8:	8b 54 24 18          	mov    0x18(%esp),%edx
f0104abc:	83 c4 20             	add    $0x20,%esp
f0104abf:	5e                   	pop    %esi
f0104ac0:	5f                   	pop    %edi
f0104ac1:	5d                   	pop    %ebp
f0104ac2:	c3                   	ret    
f0104ac3:	90                   	nop
f0104ac4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104ac8:	85 ff                	test   %edi,%edi
f0104aca:	89 fd                	mov    %edi,%ebp
f0104acc:	75 0b                	jne    f0104ad9 <__umoddi3+0x99>
f0104ace:	b8 01 00 00 00       	mov    $0x1,%eax
f0104ad3:	31 d2                	xor    %edx,%edx
f0104ad5:	f7 f7                	div    %edi
f0104ad7:	89 c5                	mov    %eax,%ebp
f0104ad9:	8b 44 24 10          	mov    0x10(%esp),%eax
f0104add:	31 d2                	xor    %edx,%edx
f0104adf:	f7 f5                	div    %ebp
f0104ae1:	89 c8                	mov    %ecx,%eax
f0104ae3:	f7 f5                	div    %ebp
f0104ae5:	eb 95                	jmp    f0104a7c <__umoddi3+0x3c>
f0104ae7:	89 f6                	mov    %esi,%esi
f0104ae9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0104af0:	89 c8                	mov    %ecx,%eax
f0104af2:	89 f2                	mov    %esi,%edx
f0104af4:	83 c4 20             	add    $0x20,%esp
f0104af7:	5e                   	pop    %esi
f0104af8:	5f                   	pop    %edi
f0104af9:	5d                   	pop    %ebp
f0104afa:	c3                   	ret    
f0104afb:	90                   	nop
f0104afc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104b00:	b8 20 00 00 00       	mov    $0x20,%eax
f0104b05:	89 e9                	mov    %ebp,%ecx
f0104b07:	29 e8                	sub    %ebp,%eax
f0104b09:	d3 e2                	shl    %cl,%edx
f0104b0b:	89 c7                	mov    %eax,%edi
f0104b0d:	89 44 24 18          	mov    %eax,0x18(%esp)
f0104b11:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0104b15:	89 f9                	mov    %edi,%ecx
f0104b17:	d3 e8                	shr    %cl,%eax
f0104b19:	89 c1                	mov    %eax,%ecx
f0104b1b:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0104b1f:	09 d1                	or     %edx,%ecx
f0104b21:	89 fa                	mov    %edi,%edx
f0104b23:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0104b27:	89 e9                	mov    %ebp,%ecx
f0104b29:	d3 e0                	shl    %cl,%eax
f0104b2b:	89 f9                	mov    %edi,%ecx
f0104b2d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104b31:	89 f0                	mov    %esi,%eax
f0104b33:	d3 e8                	shr    %cl,%eax
f0104b35:	89 e9                	mov    %ebp,%ecx
f0104b37:	89 c7                	mov    %eax,%edi
f0104b39:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0104b3d:	d3 e6                	shl    %cl,%esi
f0104b3f:	89 d1                	mov    %edx,%ecx
f0104b41:	89 fa                	mov    %edi,%edx
f0104b43:	d3 e8                	shr    %cl,%eax
f0104b45:	89 e9                	mov    %ebp,%ecx
f0104b47:	09 f0                	or     %esi,%eax
f0104b49:	8b 74 24 1c          	mov    0x1c(%esp),%esi
f0104b4d:	f7 74 24 10          	divl   0x10(%esp)
f0104b51:	d3 e6                	shl    %cl,%esi
f0104b53:	89 d1                	mov    %edx,%ecx
f0104b55:	f7 64 24 0c          	mull   0xc(%esp)
f0104b59:	39 d1                	cmp    %edx,%ecx
f0104b5b:	89 74 24 14          	mov    %esi,0x14(%esp)
f0104b5f:	89 d7                	mov    %edx,%edi
f0104b61:	89 c6                	mov    %eax,%esi
f0104b63:	72 0a                	jb     f0104b6f <__umoddi3+0x12f>
f0104b65:	39 44 24 14          	cmp    %eax,0x14(%esp)
f0104b69:	73 10                	jae    f0104b7b <__umoddi3+0x13b>
f0104b6b:	39 d1                	cmp    %edx,%ecx
f0104b6d:	75 0c                	jne    f0104b7b <__umoddi3+0x13b>
f0104b6f:	89 d7                	mov    %edx,%edi
f0104b71:	89 c6                	mov    %eax,%esi
f0104b73:	2b 74 24 0c          	sub    0xc(%esp),%esi
f0104b77:	1b 7c 24 10          	sbb    0x10(%esp),%edi
f0104b7b:	89 ca                	mov    %ecx,%edx
f0104b7d:	89 e9                	mov    %ebp,%ecx
f0104b7f:	8b 44 24 14          	mov    0x14(%esp),%eax
f0104b83:	29 f0                	sub    %esi,%eax
f0104b85:	19 fa                	sbb    %edi,%edx
f0104b87:	d3 e8                	shr    %cl,%eax
f0104b89:	0f b6 4c 24 18       	movzbl 0x18(%esp),%ecx
f0104b8e:	89 d7                	mov    %edx,%edi
f0104b90:	d3 e7                	shl    %cl,%edi
f0104b92:	89 e9                	mov    %ebp,%ecx
f0104b94:	09 f8                	or     %edi,%eax
f0104b96:	d3 ea                	shr    %cl,%edx
f0104b98:	83 c4 20             	add    $0x20,%esp
f0104b9b:	5e                   	pop    %esi
f0104b9c:	5f                   	pop    %edi
f0104b9d:	5d                   	pop    %ebp
f0104b9e:	c3                   	ret    
f0104b9f:	90                   	nop
f0104ba0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104ba4:	29 f9                	sub    %edi,%ecx
f0104ba6:	19 c6                	sbb    %eax,%esi
f0104ba8:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0104bac:	89 74 24 18          	mov    %esi,0x18(%esp)
f0104bb0:	e9 ff fe ff ff       	jmp    f0104ab4 <__umoddi3+0x74>
