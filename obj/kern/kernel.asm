
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
f0100015:	b8 00 90 11 00       	mov    $0x119000,%eax
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
f0100034:	bc 00 90 11 f0       	mov    $0xf0119000,%esp

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
f0100046:	b8 10 e1 17 f0       	mov    $0xf017e110,%eax
f010004b:	2d 8a d1 17 f0       	sub    $0xf017d18a,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 8a d1 17 f0       	push   $0xf017d18a
f0100058:	e8 0d 43 00 00       	call   f010436a <memset>
//	int x = 1, y = 3, z = 4;
//	cprintf("x %d, y %x, z %d\n", x, y, z);
	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 99 04 00 00       	call   f01004fb <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 40 48 10 f0       	push   $0xf0104840
f010006f:	e8 a1 30 00 00       	call   f0103115 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 d0 11 00 00       	call   f0101249 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 b9 2a 00 00       	call   f0102b37 <env_init>
	//cprintf("for debug 1: reach here ! Hi, mingming! Jiayou Jiayou!");
	trap_init();
f010007e:	e8 03 31 00 00       	call   f0103186 <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 9a b3 11 f0       	push   $0xf011b39a
f010008d:	e8 4c 2c 00 00       	call   f0102cde <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 28 d4 17 f0    	pushl  0xf017d428
f010009b:	e8 9e 2f 00 00       	call   f010303e <env_run>

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
f01000a8:	83 3d 00 e1 17 f0 00 	cmpl   $0x0,0xf017e100
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 00 e1 17 f0    	mov    %esi,0xf017e100

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
f01000c5:	68 5b 48 10 f0       	push   $0xf010485b
f01000ca:	e8 46 30 00 00       	call   f0103115 <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 16 30 00 00       	call   f01030ef <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 3a 5b 10 f0 	movl   $0xf0105b3a,(%esp)
f01000e0:	e8 30 30 00 00       	call   f0103115 <cprintf>
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
f0100107:	68 73 48 10 f0       	push   $0xf0104873
f010010c:	e8 04 30 00 00       	call   f0103115 <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 d2 2f 00 00       	call   f01030ef <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 3a 5b 10 f0 	movl   $0xf0105b3a,(%esp)
f0100124:	e8 ec 2f 00 00       	call   f0103115 <cprintf>
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
f010015c:	a1 04 d4 17 f0       	mov    0xf017d404,%eax
f0100161:	8d 48 01             	lea    0x1(%eax),%ecx
f0100164:	89 0d 04 d4 17 f0    	mov    %ecx,0xf017d404
f010016a:	88 90 00 d2 17 f0    	mov    %dl,-0xfe82e00(%eax)
		if (cons.wpos == CONSBUFSIZE)
f0100170:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100176:	75 0a                	jne    f0100182 <cons_intr+0x35>
			cons.wpos = 0;
f0100178:	c7 05 04 d4 17 f0 00 	movl   $0x0,0xf017d404
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
f01001a8:	83 0d c0 d1 17 f0 40 	orl    $0x40,0xf017d1c0
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
f01001c0:	8b 0d c0 d1 17 f0    	mov    0xf017d1c0,%ecx
f01001c6:	89 cb                	mov    %ecx,%ebx
f01001c8:	83 e3 40             	and    $0x40,%ebx
f01001cb:	83 e0 7f             	and    $0x7f,%eax
f01001ce:	85 db                	test   %ebx,%ebx
f01001d0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001d3:	0f b6 d2             	movzbl %dl,%edx
f01001d6:	0f b6 82 00 4a 10 f0 	movzbl -0xfefb600(%edx),%eax
f01001dd:	83 c8 40             	or     $0x40,%eax
f01001e0:	0f b6 c0             	movzbl %al,%eax
f01001e3:	f7 d0                	not    %eax
f01001e5:	21 c8                	and    %ecx,%eax
f01001e7:	a3 c0 d1 17 f0       	mov    %eax,0xf017d1c0
		return 0;
f01001ec:	b8 00 00 00 00       	mov    $0x0,%eax
f01001f1:	e9 a1 00 00 00       	jmp    f0100297 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001f6:	8b 0d c0 d1 17 f0    	mov    0xf017d1c0,%ecx
f01001fc:	f6 c1 40             	test   $0x40,%cl
f01001ff:	74 0e                	je     f010020f <kbd_proc_data+0x7e>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100201:	83 c8 80             	or     $0xffffff80,%eax
f0100204:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100206:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100209:	89 0d c0 d1 17 f0    	mov    %ecx,0xf017d1c0
	}

	shift |= shiftcode[data];
f010020f:	0f b6 c2             	movzbl %dl,%eax
f0100212:	0f b6 90 00 4a 10 f0 	movzbl -0xfefb600(%eax),%edx
f0100219:	0b 15 c0 d1 17 f0    	or     0xf017d1c0,%edx
	shift ^= togglecode[data];
f010021f:	0f b6 88 00 49 10 f0 	movzbl -0xfefb700(%eax),%ecx
f0100226:	31 ca                	xor    %ecx,%edx
f0100228:	89 15 c0 d1 17 f0    	mov    %edx,0xf017d1c0

	c = charcode[shift & (CTL | SHIFT)][data];
f010022e:	89 d1                	mov    %edx,%ecx
f0100230:	83 e1 03             	and    $0x3,%ecx
f0100233:	8b 0c 8d c0 48 10 f0 	mov    -0xfefb740(,%ecx,4),%ecx
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
f0100273:	68 8d 48 10 f0       	push   $0xf010488d
f0100278:	e8 98 2e 00 00       	call   f0103115 <cprintf>
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
f0100317:	a1 ec dc 17 f0       	mov    0xf017dcec,%eax
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
f0100359:	0f b7 15 08 d4 17 f0 	movzwl 0xf017d408,%edx
f0100360:	66 85 d2             	test   %dx,%dx
f0100363:	0f 84 e4 00 00 00    	je     f010044d <cons_putc+0x1b1>
			crt_pos--;
f0100369:	83 ea 01             	sub    $0x1,%edx
f010036c:	66 89 15 08 d4 17 f0 	mov    %dx,0xf017d408
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100373:	0f b7 d2             	movzwl %dx,%edx
f0100376:	b0 00                	mov    $0x0,%al
f0100378:	83 c8 20             	or     $0x20,%eax
f010037b:	8b 0d 0c d4 17 f0    	mov    0xf017d40c,%ecx
f0100381:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f0100385:	eb 78                	jmp    f01003ff <cons_putc+0x163>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100387:	66 83 05 08 d4 17 f0 	addw   $0x50,0xf017d408
f010038e:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038f:	0f b7 05 08 d4 17 f0 	movzwl 0xf017d408,%eax
f0100396:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010039c:	c1 e8 16             	shr    $0x16,%eax
f010039f:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003a2:	c1 e0 04             	shl    $0x4,%eax
f01003a5:	66 a3 08 d4 17 f0    	mov    %ax,0xf017d408
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
f01003e1:	0f b7 15 08 d4 17 f0 	movzwl 0xf017d408,%edx
f01003e8:	8d 4a 01             	lea    0x1(%edx),%ecx
f01003eb:	66 89 0d 08 d4 17 f0 	mov    %cx,0xf017d408
f01003f2:	0f b7 d2             	movzwl %dx,%edx
f01003f5:	8b 0d 0c d4 17 f0    	mov    0xf017d40c,%ecx
f01003fb:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003ff:	66 81 3d 08 d4 17 f0 	cmpw   $0x7cf,0xf017d408
f0100406:	cf 07 
f0100408:	76 43                	jbe    f010044d <cons_putc+0x1b1>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010040a:	a1 0c d4 17 f0       	mov    0xf017d40c,%eax
f010040f:	83 ec 04             	sub    $0x4,%esp
f0100412:	68 00 0f 00 00       	push   $0xf00
f0100417:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041d:	52                   	push   %edx
f010041e:	50                   	push   %eax
f010041f:	e8 93 3f 00 00       	call   f01043b7 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100424:	8b 15 0c d4 17 f0    	mov    0xf017d40c,%edx
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
f0100445:	66 83 2d 08 d4 17 f0 	subw   $0x50,0xf017d408
f010044c:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044d:	8b 0d 10 d4 17 f0    	mov    0xf017d410,%ecx
f0100453:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100458:	89 ca                	mov    %ecx,%edx
f010045a:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010045b:	0f b7 1d 08 d4 17 f0 	movzwl 0xf017d408,%ebx
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
f0100483:	80 3d 14 d4 17 f0 00 	cmpb   $0x0,0xf017d414
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
f01004c1:	a1 00 d4 17 f0       	mov    0xf017d400,%eax
f01004c6:	3b 05 04 d4 17 f0    	cmp    0xf017d404,%eax
f01004cc:	74 26                	je     f01004f4 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004ce:	8d 50 01             	lea    0x1(%eax),%edx
f01004d1:	89 15 00 d4 17 f0    	mov    %edx,0xf017d400
f01004d7:	0f b6 88 00 d2 17 f0 	movzbl -0xfe82e00(%eax),%ecx
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
f01004e8:	c7 05 00 d4 17 f0 00 	movl   $0x0,0xf017d400
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
f0100521:	c7 05 10 d4 17 f0 b4 	movl   $0x3b4,0xf017d410
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
f0100539:	c7 05 10 d4 17 f0 d4 	movl   $0x3d4,0xf017d410
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
f0100548:	8b 3d 10 d4 17 f0    	mov    0xf017d410,%edi
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
f010056f:	89 35 0c d4 17 f0    	mov    %esi,0xf017d40c

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
f010057c:	66 a3 08 d4 17 f0    	mov    %ax,0xf017d408
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
f01005cc:	88 0d 14 d4 17 f0    	mov    %cl,0xf017d414
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
f01005df:	68 99 48 10 f0       	push   $0xf0104899
f01005e4:	e8 2c 2b 00 00       	call   f0103115 <cprintf>
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
f0100661:	68 00 4b 10 f0       	push   $0xf0104b00
f0100666:	e8 aa 2a 00 00       	call   f0103115 <cprintf>
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
f0100691:	68 19 4b 10 f0       	push   $0xf0104b19
f0100696:	e8 7a 2a 00 00       	call   f0103115 <cprintf>
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
f01006ba:	bb c4 4f 10 f0       	mov    $0xf0104fc4,%ebx
f01006bf:	be 0c 50 10 f0       	mov    $0xf010500c,%esi
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006c4:	83 ec 04             	sub    $0x4,%esp
f01006c7:	ff 33                	pushl  (%ebx)
f01006c9:	ff 73 fc             	pushl  -0x4(%ebx)
f01006cc:	68 29 4b 10 f0       	push   $0xf0104b29
f01006d1:	e8 3f 2a 00 00       	call   f0103115 <cprintf>
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
f01006f2:	68 32 4b 10 f0       	push   $0xf0104b32
f01006f7:	e8 19 2a 00 00       	call   f0103115 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006fc:	83 c4 08             	add    $0x8,%esp
f01006ff:	68 0c 00 10 00       	push   $0x10000c
f0100704:	68 88 4c 10 f0       	push   $0xf0104c88
f0100709:	e8 07 2a 00 00       	call   f0103115 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010070e:	83 c4 0c             	add    $0xc,%esp
f0100711:	68 0c 00 10 00       	push   $0x10000c
f0100716:	68 0c 00 10 f0       	push   $0xf010000c
f010071b:	68 b0 4c 10 f0       	push   $0xf0104cb0
f0100720:	e8 f0 29 00 00       	call   f0103115 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100725:	83 c4 0c             	add    $0xc,%esp
f0100728:	68 25 48 10 00       	push   $0x104825
f010072d:	68 25 48 10 f0       	push   $0xf0104825
f0100732:	68 d4 4c 10 f0       	push   $0xf0104cd4
f0100737:	e8 d9 29 00 00       	call   f0103115 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010073c:	83 c4 0c             	add    $0xc,%esp
f010073f:	68 8a d1 17 00       	push   $0x17d18a
f0100744:	68 8a d1 17 f0       	push   $0xf017d18a
f0100749:	68 f8 4c 10 f0       	push   $0xf0104cf8
f010074e:	e8 c2 29 00 00       	call   f0103115 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100753:	83 c4 0c             	add    $0xc,%esp
f0100756:	68 10 e1 17 00       	push   $0x17e110
f010075b:	68 10 e1 17 f0       	push   $0xf017e110
f0100760:	68 1c 4d 10 f0       	push   $0xf0104d1c
f0100765:	e8 ab 29 00 00       	call   f0103115 <cprintf>
f010076a:	b8 0f e5 17 f0       	mov    $0xf017e50f,%eax
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
f010078b:	68 40 4d 10 f0       	push   $0xf0104d40
f0100790:	e8 80 29 00 00       	call   f0103115 <cprintf>
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
f01007ad:	68 6c 4d 10 f0       	push   $0xf0104d6c
f01007b2:	e8 5e 29 00 00       	call   f0103115 <cprintf>
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
f01007ca:	ff 35 08 e1 17 f0    	pushl  0xf017e108
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
f01007e9:	68 94 4d 10 f0       	push   $0xf0104d94
f01007ee:	e8 22 29 00 00       	call   f0103115 <cprintf>
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
f010084b:	68 b8 4d 10 f0       	push   $0xf0104db8
f0100850:	e8 c0 28 00 00       	call   f0103115 <cprintf>
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
f0100876:	68 4b 4b 10 f0       	push   $0xf0104b4b
f010087b:	e8 95 28 00 00       	call   f0103115 <cprintf>
	for(; begin <= end; begin += PGSIZE){
f0100880:	83 c4 10             	add    $0x10,%esp
f0100883:	eb 79                	jmp    f01008fe <showmap+0xc8>
		pte_t *pte = pgdir_walk(kern_pgdir,(void*)begin, 1);
f0100885:	83 ec 04             	sub    $0x4,%esp
f0100888:	6a 01                	push   $0x1
f010088a:	53                   	push   %ebx
f010088b:	ff 35 08 e1 17 f0    	pushl  0xf017e108
f0100891:	e8 91 07 00 00       	call   f0101027 <pgdir_walk>
f0100896:	89 c6                	mov    %eax,%esi
		if(!pte) panic("boot map region panic, out of memory");
f0100898:	83 c4 10             	add    $0x10,%esp
f010089b:	85 c0                	test   %eax,%eax
f010089d:	75 14                	jne    f01008b3 <showmap+0x7d>
f010089f:	83 ec 04             	sub    $0x4,%esp
f01008a2:	68 e8 4d 10 f0       	push   $0xf0104de8
f01008a7:	6a 2e                	push   $0x2e
f01008a9:	68 60 4b 10 f0       	push   $0xf0104b60
f01008ae:	e8 ed f7 ff ff       	call   f01000a0 <_panic>
		if(*pte & PTE_P){
f01008b3:	f6 00 01             	testb  $0x1,(%eax)
f01008b6:	74 2f                	je     f01008e7 <showmap+0xb1>
			cprintf("page %x with ", begin);
f01008b8:	83 ec 08             	sub    $0x8,%esp
f01008bb:	53                   	push   %ebx
f01008bc:	68 6f 4b 10 f0       	push   $0xf0104b6f
f01008c1:	e8 4f 28 00 00       	call   f0103115 <cprintf>
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
f01008d8:	68 94 4d 10 f0       	push   $0xf0104d94
f01008dd:	e8 33 28 00 00       	call   f0103115 <cprintf>
f01008e2:	83 c4 20             	add    $0x20,%esp
f01008e5:	eb 11                	jmp    f01008f8 <showmap+0xc2>
		}
		else{
			cprintf("page not exist: %x\n",begin);
f01008e7:	83 ec 08             	sub    $0x8,%esp
f01008ea:	53                   	push   %ebx
f01008eb:	68 7d 4b 10 f0       	push   $0xf0104b7d
f01008f0:	e8 20 28 00 00       	call   f0103115 <cprintf>
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
f010091f:	68 91 4b 10 f0       	push   $0xf0104b91
f0100924:	e8 ec 27 00 00       	call   f0103115 <cprintf>
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
f0100943:	68 10 4e 10 f0       	push   $0xf0104e10
f0100948:	e8 c8 27 00 00       	call   f0103115 <cprintf>
		struct Eipdebuginfo info;
		debuginfo_eip(*eip,&info);
f010094d:	83 c4 18             	add    $0x18,%esp
f0100950:	57                   	push   %edi
f0100951:	ff 36                	pushl  (%esi)
f0100953:	e8 6d 2d 00 00       	call   f01036c5 <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,(*eip) - info.eip_fn_addr);
f0100958:	83 c4 08             	add    $0x8,%esp
f010095b:	8b 06                	mov    (%esi),%eax
f010095d:	2b 45 e0             	sub    -0x20(%ebp),%eax
f0100960:	50                   	push   %eax
f0100961:	ff 75 d8             	pushl  -0x28(%ebp)
f0100964:	ff 75 dc             	pushl  -0x24(%ebp)
f0100967:	ff 75 d4             	pushl  -0x2c(%ebp)
f010096a:	ff 75 d0             	pushl  -0x30(%ebp)
f010096d:	68 a3 4b 10 f0       	push   $0xf0104ba3
f0100972:	e8 9e 27 00 00       	call   f0103115 <cprintf>
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
f0100999:	68 44 4e 10 f0       	push   $0xf0104e44
f010099e:	e8 72 27 00 00       	call   f0103115 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01009a3:	c7 04 24 68 4e 10 f0 	movl   $0xf0104e68,(%esp)
f01009aa:	e8 66 27 00 00       	call   f0103115 <cprintf>

	if (tf != NULL)
f01009af:	83 c4 10             	add    $0x10,%esp
f01009b2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01009b6:	74 0e                	je     f01009c6 <monitor+0x36>
		print_trapframe(tf);
f01009b8:	83 ec 0c             	sub    $0xc,%esp
f01009bb:	ff 75 08             	pushl  0x8(%ebp)
f01009be:	e8 9c 28 00 00       	call   f010325f <print_trapframe>
f01009c3:	83 c4 10             	add    $0x10,%esp

	cprintf("%Ccyn Colored scheme with no highlight.\n");
f01009c6:	83 ec 0c             	sub    $0xc,%esp
f01009c9:	68 90 4e 10 f0       	push   $0xf0104e90
f01009ce:	e8 42 27 00 00       	call   f0103115 <cprintf>
	cprintf("%Cble Hello%Cred World. %Cmag Test for colorization.\n");
f01009d3:	c7 04 24 bc 4e 10 f0 	movl   $0xf0104ebc,(%esp)
f01009da:	e8 36 27 00 00       	call   f0103115 <cprintf>
	cprintf("%Ibrw Colored scheme with highlight.\n");
f01009df:	c7 04 24 f4 4e 10 f0 	movl   $0xf0104ef4,(%esp)
f01009e6:	e8 2a 27 00 00       	call   f0103115 <cprintf>
	cprintf("%Ible Hello%Ired World. %Imag Test for colorization.\n");
f01009eb:	c7 04 24 1c 4f 10 f0 	movl   $0xf0104f1c,(%esp)
f01009f2:	e8 1e 27 00 00       	call   f0103115 <cprintf>
	cprintf("%Cwht Return to default!\n");
f01009f7:	c7 04 24 b4 4b 10 f0 	movl   $0xf0104bb4,(%esp)
f01009fe:	e8 12 27 00 00       	call   f0103115 <cprintf>
f0100a03:	83 c4 10             	add    $0x10,%esp
	while (1) {
		buf = readline("K> ");
f0100a06:	83 ec 0c             	sub    $0xc,%esp
f0100a09:	68 ce 4b 10 f0       	push   $0xf0104bce
f0100a0e:	e8 00 37 00 00       	call   f0104113 <readline>
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
f0100a42:	68 d2 4b 10 f0       	push   $0xf0104bd2
f0100a47:	e8 e1 38 00 00       	call   f010432d <strchr>
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
f0100a62:	68 d7 4b 10 f0       	push   $0xf0104bd7
f0100a67:	e8 a9 26 00 00       	call   f0103115 <cprintf>
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
f0100a8b:	68 d2 4b 10 f0       	push   $0xf0104bd2
f0100a90:	e8 98 38 00 00       	call   f010432d <strchr>
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
f0100ab9:	ff 34 85 c0 4f 10 f0 	pushl  -0xfefb040(,%eax,4)
f0100ac0:	ff 75 a8             	pushl  -0x58(%ebp)
f0100ac3:	e8 07 38 00 00       	call   f01042cf <strcmp>
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
f0100add:	ff 14 85 c8 4f 10 f0 	call   *-0xfefb038(,%eax,4)
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
f0100aff:	68 f4 4b 10 f0       	push   $0xf0104bf4
f0100b04:	e8 0c 26 00 00       	call   f0103115 <cprintf>
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
f0100b2f:	3b 0d 04 e1 17 f0    	cmp    0xf017e104,%ecx
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
f0100b3e:	68 08 50 10 f0       	push   $0xf0105008
f0100b43:	68 32 03 00 00       	push   $0x332
f0100b48:	68 5d 58 10 f0       	push   $0xf010585d
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
f0100b83:	83 3d 18 d4 17 f0 00 	cmpl   $0x0,0xf017d418
f0100b8a:	75 11                	jne    f0100b9d <boot_alloc+0x20>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100b8c:	ba 0f f1 17 f0       	mov    $0xf017f10f,%edx
f0100b91:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b97:	89 15 18 d4 17 f0    	mov    %edx,0xf017d418
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	
	if(n != 0){
f0100b9d:	85 c0                	test   %eax,%eax
f0100b9f:	74 5f                	je     f0100c00 <boot_alloc+0x83>
		char *start = nextfree;
f0100ba1:	8b 0d 18 d4 17 f0    	mov    0xf017d418,%ecx
		nextfree += n;
		nextfree = ROUNDUP((char*)nextfree, PGSIZE);
f0100ba7:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f0100bae:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100bb4:	89 15 18 d4 17 f0    	mov    %edx,0xf017d418
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100bba:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0100bc0:	77 12                	ja     f0100bd4 <boot_alloc+0x57>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100bc2:	52                   	push   %edx
f0100bc3:	68 2c 50 10 f0       	push   $0xf010502c
f0100bc8:	6a 6d                	push   $0x6d
f0100bca:	68 5d 58 10 f0       	push   $0xf010585d
f0100bcf:	e8 cc f4 ff ff       	call   f01000a0 <_panic>
		if(PADDR(nextfree) > npages * PGSIZE){
f0100bd4:	a1 04 e1 17 f0       	mov    0xf017e104,%eax
f0100bd9:	c1 e0 0c             	shl    $0xc,%eax
	return (physaddr_t)kva - KERNBASE;
f0100bdc:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0100be2:	39 d0                	cmp    %edx,%eax
f0100be4:	73 21                	jae    f0100c07 <boot_alloc+0x8a>
			nextfree = start;
f0100be6:	89 0d 18 d4 17 f0    	mov    %ecx,0xf017d418
			panic("Run out of memory");
f0100bec:	83 ec 04             	sub    $0x4,%esp
f0100bef:	68 69 58 10 f0       	push   $0xf0105869
f0100bf4:	6a 6f                	push   $0x6f
f0100bf6:	68 5d 58 10 f0       	push   $0xf010585d
f0100bfb:	e8 a0 f4 ff ff       	call   f01000a0 <_panic>
		}
		return start;
	}
	else{
		return nextfree;
f0100c00:	a1 18 d4 17 f0       	mov    0xf017d418,%eax
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
f0100c24:	68 50 50 10 f0       	push   $0xf0105050
f0100c29:	68 6d 02 00 00       	push   $0x26d
f0100c2e:	68 5d 58 10 f0       	push   $0xf010585d
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
f0100c46:	2b 15 0c e1 17 f0    	sub    0xf017e10c,%edx
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
f0100c7c:	a3 1c d4 17 f0       	mov    %eax,0xf017d41c
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
f0100c86:	8b 1d 1c d4 17 f0    	mov    0xf017d41c,%ebx
f0100c8c:	eb 53                	jmp    f0100ce1 <check_page_free_list+0xd6>
f0100c8e:	89 d8                	mov    %ebx,%eax
f0100c90:	2b 05 0c e1 17 f0    	sub    0xf017e10c,%eax
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
f0100caa:	3b 15 04 e1 17 f0    	cmp    0xf017e104,%edx
f0100cb0:	72 12                	jb     f0100cc4 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cb2:	50                   	push   %eax
f0100cb3:	68 08 50 10 f0       	push   $0xf0105008
f0100cb8:	6a 56                	push   $0x56
f0100cba:	68 7b 58 10 f0       	push   $0xf010587b
f0100cbf:	e8 dc f3 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100cc4:	83 ec 04             	sub    $0x4,%esp
f0100cc7:	68 80 00 00 00       	push   $0x80
f0100ccc:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100cd1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100cd6:	50                   	push   %eax
f0100cd7:	e8 8e 36 00 00       	call   f010436a <memset>
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
f0100cf2:	8b 15 1c d4 17 f0    	mov    0xf017d41c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100cf8:	8b 0d 0c e1 17 f0    	mov    0xf017e10c,%ecx
		assert(pp < pages + npages);
f0100cfe:	a1 04 e1 17 f0       	mov    0xf017e104,%eax
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
f0100d22:	68 89 58 10 f0       	push   $0xf0105889
f0100d27:	68 95 58 10 f0       	push   $0xf0105895
f0100d2c:	68 87 02 00 00       	push   $0x287
f0100d31:	68 5d 58 10 f0       	push   $0xf010585d
f0100d36:	e8 65 f3 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100d3b:	39 da                	cmp    %ebx,%edx
f0100d3d:	72 19                	jb     f0100d58 <check_page_free_list+0x14d>
f0100d3f:	68 aa 58 10 f0       	push   $0xf01058aa
f0100d44:	68 95 58 10 f0       	push   $0xf0105895
f0100d49:	68 88 02 00 00       	push   $0x288
f0100d4e:	68 5d 58 10 f0       	push   $0xf010585d
f0100d53:	e8 48 f3 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d58:	89 d0                	mov    %edx,%eax
f0100d5a:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100d5d:	a8 07                	test   $0x7,%al
f0100d5f:	74 19                	je     f0100d7a <check_page_free_list+0x16f>
f0100d61:	68 74 50 10 f0       	push   $0xf0105074
f0100d66:	68 95 58 10 f0       	push   $0xf0105895
f0100d6b:	68 89 02 00 00       	push   $0x289
f0100d70:	68 5d 58 10 f0       	push   $0xf010585d
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
f0100d84:	68 be 58 10 f0       	push   $0xf01058be
f0100d89:	68 95 58 10 f0       	push   $0xf0105895
f0100d8e:	68 8c 02 00 00       	push   $0x28c
f0100d93:	68 5d 58 10 f0       	push   $0xf010585d
f0100d98:	e8 03 f3 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d9d:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100da2:	75 19                	jne    f0100dbd <check_page_free_list+0x1b2>
f0100da4:	68 cf 58 10 f0       	push   $0xf01058cf
f0100da9:	68 95 58 10 f0       	push   $0xf0105895
f0100dae:	68 8d 02 00 00       	push   $0x28d
f0100db3:	68 5d 58 10 f0       	push   $0xf010585d
f0100db8:	e8 e3 f2 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100dbd:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100dc2:	75 19                	jne    f0100ddd <check_page_free_list+0x1d2>
f0100dc4:	68 a8 50 10 f0       	push   $0xf01050a8
f0100dc9:	68 95 58 10 f0       	push   $0xf0105895
f0100dce:	68 8e 02 00 00       	push   $0x28e
f0100dd3:	68 5d 58 10 f0       	push   $0xf010585d
f0100dd8:	e8 c3 f2 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100ddd:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100de2:	75 19                	jne    f0100dfd <check_page_free_list+0x1f2>
f0100de4:	68 e8 58 10 f0       	push   $0xf01058e8
f0100de9:	68 95 58 10 f0       	push   $0xf0105895
f0100dee:	68 8f 02 00 00       	push   $0x28f
f0100df3:	68 5d 58 10 f0       	push   $0xf010585d
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
f0100e12:	68 08 50 10 f0       	push   $0xf0105008
f0100e17:	6a 56                	push   $0x56
f0100e19:	68 7b 58 10 f0       	push   $0xf010587b
f0100e1e:	e8 7d f2 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0100e23:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e28:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100e2b:	76 1e                	jbe    f0100e4b <check_page_free_list+0x240>
f0100e2d:	68 cc 50 10 f0       	push   $0xf01050cc
f0100e32:	68 95 58 10 f0       	push   $0xf0105895
f0100e37:	68 90 02 00 00       	push   $0x290
f0100e3c:	68 5d 58 10 f0       	push   $0xf010585d
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
f0100e60:	68 02 59 10 f0       	push   $0xf0105902
f0100e65:	68 95 58 10 f0       	push   $0xf0105895
f0100e6a:	68 98 02 00 00       	push   $0x298
f0100e6f:	68 5d 58 10 f0       	push   $0xf010585d
f0100e74:	e8 27 f2 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100e79:	85 f6                	test   %esi,%esi
f0100e7b:	7f 42                	jg     f0100ebf <check_page_free_list+0x2b4>
f0100e7d:	68 14 59 10 f0       	push   $0xf0105914
f0100e82:	68 95 58 10 f0       	push   $0xf0105895
f0100e87:	68 99 02 00 00       	push   $0x299
f0100e8c:	68 5d 58 10 f0       	push   $0xf010585d
f0100e91:	e8 0a f2 ff ff       	call   f01000a0 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100e96:	a1 1c d4 17 f0       	mov    0xf017d41c,%eax
f0100e9b:	85 c0                	test   %eax,%eax
f0100e9d:	0f 85 95 fd ff ff    	jne    f0100c38 <check_page_free_list+0x2d>
f0100ea3:	e9 79 fd ff ff       	jmp    f0100c21 <check_page_free_list+0x16>
f0100ea8:	83 3d 1c d4 17 f0 00 	cmpl   $0x0,0xf017d41c
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
f0100efd:	68 2c 50 10 f0       	push   $0xf010502c
f0100f02:	68 32 01 00 00       	push   $0x132
f0100f07:	68 5d 58 10 f0       	push   $0xf010585d
f0100f0c:	e8 8f f1 ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100f11:	05 00 00 00 10       	add    $0x10000000,%eax
f0100f16:	39 c7                	cmp    %eax,%edi
f0100f18:	72 22                	jb     f0100f3c <page_init+0x75>
		pages[i].pp_ref = 0;
f0100f1a:	89 d8                	mov    %ebx,%eax
f0100f1c:	03 05 0c e1 17 f0    	add    0xf017e10c,%eax
f0100f22:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
		pages[i].pp_link = page_free_list;
f0100f28:	8b 15 1c d4 17 f0    	mov    0xf017d41c,%edx
f0100f2e:	89 10                	mov    %edx,(%eax)
		page_free_list = &pages[i];
f0100f30:	03 1d 0c e1 17 f0    	add    0xf017e10c,%ebx
f0100f36:	89 1d 1c d4 17 f0    	mov    %ebx,0xf017d41c
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 1; i < npages; i++) {
f0100f3c:	83 c6 01             	add    $0x1,%esi
f0100f3f:	3b 35 04 e1 17 f0    	cmp    0xf017e104,%esi
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
f0100f56:	8b 1d 1c d4 17 f0    	mov    0xf017d41c,%ebx
f0100f5c:	85 db                	test   %ebx,%ebx
f0100f5e:	74 58                	je     f0100fb8 <page_alloc+0x69>
	struct PageInfo *ret = page_free_list; //fetch the head of the page list
	page_free_list = page_free_list->pp_link;
f0100f60:	8b 03                	mov    (%ebx),%eax
f0100f62:	a3 1c d4 17 f0       	mov    %eax,0xf017d41c
	if(alloc_flags && ALLOC_ZERO){
f0100f67:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100f6b:	74 45                	je     f0100fb2 <page_alloc+0x63>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f6d:	89 d8                	mov    %ebx,%eax
f0100f6f:	2b 05 0c e1 17 f0    	sub    0xf017e10c,%eax
f0100f75:	c1 f8 03             	sar    $0x3,%eax
f0100f78:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f7b:	89 c2                	mov    %eax,%edx
f0100f7d:	c1 ea 0c             	shr    $0xc,%edx
f0100f80:	3b 15 04 e1 17 f0    	cmp    0xf017e104,%edx
f0100f86:	72 12                	jb     f0100f9a <page_alloc+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f88:	50                   	push   %eax
f0100f89:	68 08 50 10 f0       	push   $0xf0105008
f0100f8e:	6a 56                	push   $0x56
f0100f90:	68 7b 58 10 f0       	push   $0xf010587b
f0100f95:	e8 06 f1 ff ff       	call   f01000a0 <_panic>
		memset(page2kva(ret), '\0', PGSIZE);
f0100f9a:	83 ec 04             	sub    $0x4,%esp
f0100f9d:	68 00 10 00 00       	push   $0x1000
f0100fa2:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0100fa4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100fa9:	50                   	push   %eax
f0100faa:	e8 bb 33 00 00       	call   f010436a <memset>
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
f0100fd7:	68 14 51 10 f0       	push   $0xf0105114
f0100fdc:	68 5f 01 00 00       	push   $0x15f
f0100fe1:	68 5d 58 10 f0       	push   $0xf010585d
f0100fe6:	e8 b5 f0 ff ff       	call   f01000a0 <_panic>
	}
	pp->pp_ref = 0;
f0100feb:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
	struct PageInfo* tmp = page_free_list;
f0100ff1:	8b 15 1c d4 17 f0    	mov    0xf017d41c,%edx
	page_free_list = pp;
f0100ff7:	a3 1c d4 17 f0       	mov    %eax,0xf017d41c
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
f0101064:	2b 05 0c e1 17 f0    	sub    0xf017e10c,%eax
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
f0101081:	3b 15 04 e1 17 f0    	cmp    0xf017e104,%edx
f0101087:	72 15                	jb     f010109e <pgdir_walk+0x77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101089:	50                   	push   %eax
f010108a:	68 08 50 10 f0       	push   $0xf0105008
f010108f:	68 9e 01 00 00       	push   $0x19e
f0101094:	68 5d 58 10 f0       	push   $0xf010585d
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
f0101100:	68 44 51 10 f0       	push   $0xf0105144
f0101105:	68 b6 01 00 00       	push   $0x1b6
f010110a:	68 5d 58 10 f0       	push   $0xf010585d
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
f010115f:	3b 05 04 e1 17 f0    	cmp    0xf017e104,%eax
f0101165:	72 14                	jb     f010117b <page_lookup+0x4a>
		panic("pa2page called with invalid pa");
f0101167:	83 ec 04             	sub    $0x4,%esp
f010116a:	68 74 51 10 f0       	push   $0xf0105174
f010116f:	6a 4f                	push   $0x4f
f0101171:	68 7b 58 10 f0       	push   $0xf010587b
f0101176:	e8 25 ef ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f010117b:	8b 15 0c e1 17 f0    	mov    0xf017e10c,%edx
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
f0101225:	2b 05 0c e1 17 f0    	sub    0xf017e10c,%eax
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
f0101254:	e8 5b 1e 00 00       	call   f01030b4 <mc146818_read>
f0101259:	89 c3                	mov    %eax,%ebx
f010125b:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101262:	e8 4d 1e 00 00       	call   f01030b4 <mc146818_read>
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
f010127d:	a3 20 d4 17 f0       	mov    %eax,0xf017d420
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101282:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101289:	e8 26 1e 00 00       	call   f01030b4 <mc146818_read>
f010128e:	89 c6                	mov    %eax,%esi
f0101290:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101297:	e8 18 1e 00 00       	call   f01030b4 <mc146818_read>
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
f01012b8:	ff 35 20 d4 17 f0    	pushl  0xf017d420
f01012be:	68 94 51 10 f0       	push   $0xf0105194
f01012c3:	e8 4d 1e 00 00       	call   f0103115 <cprintf>

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01012c8:	83 c4 10             	add    $0x10,%esp
f01012cb:	85 db                	test   %ebx,%ebx
f01012cd:	74 0d                	je     f01012dc <mem_init+0x93>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01012cf:	8d 83 00 01 00 00    	lea    0x100(%ebx),%eax
f01012d5:	a3 04 e1 17 f0       	mov    %eax,0xf017e104
f01012da:	eb 0a                	jmp    f01012e6 <mem_init+0x9d>
	else
		npages = npages_basemem;
f01012dc:	a1 20 d4 17 f0       	mov    0xf017d420,%eax
f01012e1:	a3 04 e1 17 f0       	mov    %eax,0xf017e104

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
f01012ed:	a1 20 d4 17 f0       	mov    0xf017d420,%eax
f01012f2:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012f5:	c1 e8 0a             	shr    $0xa,%eax
f01012f8:	50                   	push   %eax
		npages * PGSIZE / 1024,
f01012f9:	a1 04 e1 17 f0       	mov    0xf017e104,%eax
f01012fe:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101301:	c1 e8 0a             	shr    $0xa,%eax
f0101304:	50                   	push   %eax
f0101305:	68 bc 51 10 f0       	push   $0xf01051bc
f010130a:	e8 06 1e 00 00       	call   f0103115 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010130f:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101314:	e8 64 f8 ff ff       	call   f0100b7d <boot_alloc>
f0101319:	a3 08 e1 17 f0       	mov    %eax,0xf017e108
	memset(kern_pgdir, 0, PGSIZE);
f010131e:	83 c4 0c             	add    $0xc,%esp
f0101321:	68 00 10 00 00       	push   $0x1000
f0101326:	6a 00                	push   $0x0
f0101328:	50                   	push   %eax
f0101329:	e8 3c 30 00 00       	call   f010436a <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010132e:	a1 08 e1 17 f0       	mov    0xf017e108,%eax
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
f010133e:	68 2c 50 10 f0       	push   $0xf010502c
f0101343:	68 9a 00 00 00       	push   $0x9a
f0101348:	68 5d 58 10 f0       	push   $0xf010585d
f010134d:	e8 4e ed ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101352:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101358:	83 ca 05             	or     $0x5,%edx
f010135b:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	cprintf("UVPT is %x\n" ,UVPT);
f0101361:	83 ec 08             	sub    $0x8,%esp
f0101364:	68 00 00 40 ef       	push   $0xef400000
f0101369:	68 25 59 10 f0       	push   $0xf0105925
f010136e:	e8 a2 1d 00 00       	call   f0103115 <cprintf>
	cprintf("UPAGES is %x\n", UPAGES);
f0101373:	83 c4 08             	add    $0x8,%esp
f0101376:	68 00 00 00 ef       	push   $0xef000000
f010137b:	68 31 59 10 f0       	push   $0xf0105931
f0101380:	e8 90 1d 00 00       	call   f0103115 <cprintf>
	cprintf("Physical address of kern_pgdir: %x\n", PADDR(kern_pgdir));
f0101385:	a1 08 e1 17 f0       	mov    0xf017e108,%eax
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
f0101395:	68 2c 50 10 f0       	push   $0xf010502c
f010139a:	68 9d 00 00 00       	push   $0x9d
f010139f:	68 5d 58 10 f0       	push   $0xf010585d
f01013a4:	e8 f7 ec ff ff       	call   f01000a0 <_panic>
f01013a9:	83 ec 08             	sub    $0x8,%esp
	return (physaddr_t)kva - KERNBASE;
f01013ac:	05 00 00 00 10       	add    $0x10000000,%eax
f01013b1:	50                   	push   %eax
f01013b2:	68 f8 51 10 f0       	push   $0xf01051f8
f01013b7:	e8 59 1d 00 00       	call   f0103115 <cprintf>
	cprintf("Virtual address of kern_pgdir: %x\n", kern_pgdir);
f01013bc:	83 c4 08             	add    $0x8,%esp
f01013bf:	ff 35 08 e1 17 f0    	pushl  0xf017e108
f01013c5:	68 1c 52 10 f0       	push   $0xf010521c
f01013ca:	e8 46 1d 00 00       	call   f0103115 <cprintf>
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:

	pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
f01013cf:	a1 04 e1 17 f0       	mov    0xf017e104,%eax
f01013d4:	c1 e0 03             	shl    $0x3,%eax
f01013d7:	e8 a1 f7 ff ff       	call   f0100b7d <boot_alloc>
f01013dc:	a3 0c e1 17 f0       	mov    %eax,0xf017e10c
	memset(pages, 0, npages*sizeof(struct PageInfo));
f01013e1:	83 c4 0c             	add    $0xc,%esp
f01013e4:	8b 3d 04 e1 17 f0    	mov    0xf017e104,%edi
f01013ea:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f01013f1:	52                   	push   %edx
f01013f2:	6a 00                	push   $0x0
f01013f4:	50                   	push   %eax
f01013f5:	e8 70 2f 00 00       	call   f010436a <memset>
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env*)boot_alloc(NENV * sizeof(struct Env));	
f01013fa:	b8 00 80 01 00       	mov    $0x18000,%eax
f01013ff:	e8 79 f7 ff ff       	call   f0100b7d <boot_alloc>
f0101404:	a3 28 d4 17 f0       	mov    %eax,0xf017d428
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
f010141b:	83 3d 0c e1 17 f0 00 	cmpl   $0x0,0xf017e10c
f0101422:	75 17                	jne    f010143b <mem_init+0x1f2>
		panic("'pages' is a null pointer!");
f0101424:	83 ec 04             	sub    $0x4,%esp
f0101427:	68 3f 59 10 f0       	push   $0xf010593f
f010142c:	68 aa 02 00 00       	push   $0x2aa
f0101431:	68 5d 58 10 f0       	push   $0xf010585d
f0101436:	e8 65 ec ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010143b:	a1 1c d4 17 f0       	mov    0xf017d41c,%eax
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
f0101463:	68 5a 59 10 f0       	push   $0xf010595a
f0101468:	68 95 58 10 f0       	push   $0xf0105895
f010146d:	68 b2 02 00 00       	push   $0x2b2
f0101472:	68 5d 58 10 f0       	push   $0xf010585d
f0101477:	e8 24 ec ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010147c:	83 ec 0c             	sub    $0xc,%esp
f010147f:	6a 00                	push   $0x0
f0101481:	e8 c9 fa ff ff       	call   f0100f4f <page_alloc>
f0101486:	89 c6                	mov    %eax,%esi
f0101488:	83 c4 10             	add    $0x10,%esp
f010148b:	85 c0                	test   %eax,%eax
f010148d:	75 19                	jne    f01014a8 <mem_init+0x25f>
f010148f:	68 70 59 10 f0       	push   $0xf0105970
f0101494:	68 95 58 10 f0       	push   $0xf0105895
f0101499:	68 b3 02 00 00       	push   $0x2b3
f010149e:	68 5d 58 10 f0       	push   $0xf010585d
f01014a3:	e8 f8 eb ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01014a8:	83 ec 0c             	sub    $0xc,%esp
f01014ab:	6a 00                	push   $0x0
f01014ad:	e8 9d fa ff ff       	call   f0100f4f <page_alloc>
f01014b2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014b5:	83 c4 10             	add    $0x10,%esp
f01014b8:	85 c0                	test   %eax,%eax
f01014ba:	75 19                	jne    f01014d5 <mem_init+0x28c>
f01014bc:	68 86 59 10 f0       	push   $0xf0105986
f01014c1:	68 95 58 10 f0       	push   $0xf0105895
f01014c6:	68 b4 02 00 00       	push   $0x2b4
f01014cb:	68 5d 58 10 f0       	push   $0xf010585d
f01014d0:	e8 cb eb ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01014d5:	39 f7                	cmp    %esi,%edi
f01014d7:	75 19                	jne    f01014f2 <mem_init+0x2a9>
f01014d9:	68 9c 59 10 f0       	push   $0xf010599c
f01014de:	68 95 58 10 f0       	push   $0xf0105895
f01014e3:	68 b7 02 00 00       	push   $0x2b7
f01014e8:	68 5d 58 10 f0       	push   $0xf010585d
f01014ed:	e8 ae eb ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014f2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014f5:	39 c7                	cmp    %eax,%edi
f01014f7:	74 04                	je     f01014fd <mem_init+0x2b4>
f01014f9:	39 c6                	cmp    %eax,%esi
f01014fb:	75 19                	jne    f0101516 <mem_init+0x2cd>
f01014fd:	68 40 52 10 f0       	push   $0xf0105240
f0101502:	68 95 58 10 f0       	push   $0xf0105895
f0101507:	68 b8 02 00 00       	push   $0x2b8
f010150c:	68 5d 58 10 f0       	push   $0xf010585d
f0101511:	e8 8a eb ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101516:	8b 0d 0c e1 17 f0    	mov    0xf017e10c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010151c:	8b 15 04 e1 17 f0    	mov    0xf017e104,%edx
f0101522:	c1 e2 0c             	shl    $0xc,%edx
f0101525:	89 f8                	mov    %edi,%eax
f0101527:	29 c8                	sub    %ecx,%eax
f0101529:	c1 f8 03             	sar    $0x3,%eax
f010152c:	c1 e0 0c             	shl    $0xc,%eax
f010152f:	39 d0                	cmp    %edx,%eax
f0101531:	72 19                	jb     f010154c <mem_init+0x303>
f0101533:	68 ae 59 10 f0       	push   $0xf01059ae
f0101538:	68 95 58 10 f0       	push   $0xf0105895
f010153d:	68 b9 02 00 00       	push   $0x2b9
f0101542:	68 5d 58 10 f0       	push   $0xf010585d
f0101547:	e8 54 eb ff ff       	call   f01000a0 <_panic>
f010154c:	89 f0                	mov    %esi,%eax
f010154e:	29 c8                	sub    %ecx,%eax
f0101550:	c1 f8 03             	sar    $0x3,%eax
f0101553:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f0101556:	39 c2                	cmp    %eax,%edx
f0101558:	77 19                	ja     f0101573 <mem_init+0x32a>
f010155a:	68 cb 59 10 f0       	push   $0xf01059cb
f010155f:	68 95 58 10 f0       	push   $0xf0105895
f0101564:	68 ba 02 00 00       	push   $0x2ba
f0101569:	68 5d 58 10 f0       	push   $0xf010585d
f010156e:	e8 2d eb ff ff       	call   f01000a0 <_panic>
f0101573:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101576:	29 c8                	sub    %ecx,%eax
f0101578:	c1 f8 03             	sar    $0x3,%eax
f010157b:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f010157e:	39 c2                	cmp    %eax,%edx
f0101580:	77 19                	ja     f010159b <mem_init+0x352>
f0101582:	68 e8 59 10 f0       	push   $0xf01059e8
f0101587:	68 95 58 10 f0       	push   $0xf0105895
f010158c:	68 bb 02 00 00       	push   $0x2bb
f0101591:	68 5d 58 10 f0       	push   $0xf010585d
f0101596:	e8 05 eb ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010159b:	a1 1c d4 17 f0       	mov    0xf017d41c,%eax
f01015a0:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01015a3:	c7 05 1c d4 17 f0 00 	movl   $0x0,0xf017d41c
f01015aa:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01015ad:	83 ec 0c             	sub    $0xc,%esp
f01015b0:	6a 00                	push   $0x0
f01015b2:	e8 98 f9 ff ff       	call   f0100f4f <page_alloc>
f01015b7:	83 c4 10             	add    $0x10,%esp
f01015ba:	85 c0                	test   %eax,%eax
f01015bc:	74 19                	je     f01015d7 <mem_init+0x38e>
f01015be:	68 05 5a 10 f0       	push   $0xf0105a05
f01015c3:	68 95 58 10 f0       	push   $0xf0105895
f01015c8:	68 c2 02 00 00       	push   $0x2c2
f01015cd:	68 5d 58 10 f0       	push   $0xf010585d
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
f0101608:	68 5a 59 10 f0       	push   $0xf010595a
f010160d:	68 95 58 10 f0       	push   $0xf0105895
f0101612:	68 c9 02 00 00       	push   $0x2c9
f0101617:	68 5d 58 10 f0       	push   $0xf010585d
f010161c:	e8 7f ea ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101621:	83 ec 0c             	sub    $0xc,%esp
f0101624:	6a 00                	push   $0x0
f0101626:	e8 24 f9 ff ff       	call   f0100f4f <page_alloc>
f010162b:	89 c7                	mov    %eax,%edi
f010162d:	83 c4 10             	add    $0x10,%esp
f0101630:	85 c0                	test   %eax,%eax
f0101632:	75 19                	jne    f010164d <mem_init+0x404>
f0101634:	68 70 59 10 f0       	push   $0xf0105970
f0101639:	68 95 58 10 f0       	push   $0xf0105895
f010163e:	68 ca 02 00 00       	push   $0x2ca
f0101643:	68 5d 58 10 f0       	push   $0xf010585d
f0101648:	e8 53 ea ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010164d:	83 ec 0c             	sub    $0xc,%esp
f0101650:	6a 00                	push   $0x0
f0101652:	e8 f8 f8 ff ff       	call   f0100f4f <page_alloc>
f0101657:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010165a:	83 c4 10             	add    $0x10,%esp
f010165d:	85 c0                	test   %eax,%eax
f010165f:	75 19                	jne    f010167a <mem_init+0x431>
f0101661:	68 86 59 10 f0       	push   $0xf0105986
f0101666:	68 95 58 10 f0       	push   $0xf0105895
f010166b:	68 cb 02 00 00       	push   $0x2cb
f0101670:	68 5d 58 10 f0       	push   $0xf010585d
f0101675:	e8 26 ea ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010167a:	39 fe                	cmp    %edi,%esi
f010167c:	75 19                	jne    f0101697 <mem_init+0x44e>
f010167e:	68 9c 59 10 f0       	push   $0xf010599c
f0101683:	68 95 58 10 f0       	push   $0xf0105895
f0101688:	68 cd 02 00 00       	push   $0x2cd
f010168d:	68 5d 58 10 f0       	push   $0xf010585d
f0101692:	e8 09 ea ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101697:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010169a:	39 c6                	cmp    %eax,%esi
f010169c:	74 04                	je     f01016a2 <mem_init+0x459>
f010169e:	39 c7                	cmp    %eax,%edi
f01016a0:	75 19                	jne    f01016bb <mem_init+0x472>
f01016a2:	68 40 52 10 f0       	push   $0xf0105240
f01016a7:	68 95 58 10 f0       	push   $0xf0105895
f01016ac:	68 ce 02 00 00       	push   $0x2ce
f01016b1:	68 5d 58 10 f0       	push   $0xf010585d
f01016b6:	e8 e5 e9 ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f01016bb:	83 ec 0c             	sub    $0xc,%esp
f01016be:	6a 00                	push   $0x0
f01016c0:	e8 8a f8 ff ff       	call   f0100f4f <page_alloc>
f01016c5:	83 c4 10             	add    $0x10,%esp
f01016c8:	85 c0                	test   %eax,%eax
f01016ca:	74 19                	je     f01016e5 <mem_init+0x49c>
f01016cc:	68 05 5a 10 f0       	push   $0xf0105a05
f01016d1:	68 95 58 10 f0       	push   $0xf0105895
f01016d6:	68 cf 02 00 00       	push   $0x2cf
f01016db:	68 5d 58 10 f0       	push   $0xf010585d
f01016e0:	e8 bb e9 ff ff       	call   f01000a0 <_panic>
f01016e5:	89 f0                	mov    %esi,%eax
f01016e7:	2b 05 0c e1 17 f0    	sub    0xf017e10c,%eax
f01016ed:	c1 f8 03             	sar    $0x3,%eax
f01016f0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01016f3:	89 c2                	mov    %eax,%edx
f01016f5:	c1 ea 0c             	shr    $0xc,%edx
f01016f8:	3b 15 04 e1 17 f0    	cmp    0xf017e104,%edx
f01016fe:	72 12                	jb     f0101712 <mem_init+0x4c9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101700:	50                   	push   %eax
f0101701:	68 08 50 10 f0       	push   $0xf0105008
f0101706:	6a 56                	push   $0x56
f0101708:	68 7b 58 10 f0       	push   $0xf010587b
f010170d:	e8 8e e9 ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101712:	83 ec 04             	sub    $0x4,%esp
f0101715:	68 00 10 00 00       	push   $0x1000
f010171a:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f010171c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101721:	50                   	push   %eax
f0101722:	e8 43 2c 00 00       	call   f010436a <memset>
	page_free(pp0);
f0101727:	89 34 24             	mov    %esi,(%esp)
f010172a:	e8 90 f8 ff ff       	call   f0100fbf <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010172f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101736:	e8 14 f8 ff ff       	call   f0100f4f <page_alloc>
f010173b:	83 c4 10             	add    $0x10,%esp
f010173e:	85 c0                	test   %eax,%eax
f0101740:	75 19                	jne    f010175b <mem_init+0x512>
f0101742:	68 14 5a 10 f0       	push   $0xf0105a14
f0101747:	68 95 58 10 f0       	push   $0xf0105895
f010174c:	68 d4 02 00 00       	push   $0x2d4
f0101751:	68 5d 58 10 f0       	push   $0xf010585d
f0101756:	e8 45 e9 ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f010175b:	39 c6                	cmp    %eax,%esi
f010175d:	74 19                	je     f0101778 <mem_init+0x52f>
f010175f:	68 32 5a 10 f0       	push   $0xf0105a32
f0101764:	68 95 58 10 f0       	push   $0xf0105895
f0101769:	68 d5 02 00 00       	push   $0x2d5
f010176e:	68 5d 58 10 f0       	push   $0xf010585d
f0101773:	e8 28 e9 ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101778:	89 f0                	mov    %esi,%eax
f010177a:	2b 05 0c e1 17 f0    	sub    0xf017e10c,%eax
f0101780:	c1 f8 03             	sar    $0x3,%eax
f0101783:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101786:	89 c2                	mov    %eax,%edx
f0101788:	c1 ea 0c             	shr    $0xc,%edx
f010178b:	3b 15 04 e1 17 f0    	cmp    0xf017e104,%edx
f0101791:	72 12                	jb     f01017a5 <mem_init+0x55c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101793:	50                   	push   %eax
f0101794:	68 08 50 10 f0       	push   $0xf0105008
f0101799:	6a 56                	push   $0x56
f010179b:	68 7b 58 10 f0       	push   $0xf010587b
f01017a0:	e8 fb e8 ff ff       	call   f01000a0 <_panic>
f01017a5:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01017ab:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01017b1:	80 38 00             	cmpb   $0x0,(%eax)
f01017b4:	74 19                	je     f01017cf <mem_init+0x586>
f01017b6:	68 42 5a 10 f0       	push   $0xf0105a42
f01017bb:	68 95 58 10 f0       	push   $0xf0105895
f01017c0:	68 d8 02 00 00       	push   $0x2d8
f01017c5:	68 5d 58 10 f0       	push   $0xf010585d
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
f01017d9:	a3 1c d4 17 f0       	mov    %eax,0xf017d41c

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
f01017fa:	a1 1c d4 17 f0       	mov    0xf017d41c,%eax
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
f0101811:	68 4c 5a 10 f0       	push   $0xf0105a4c
f0101816:	68 95 58 10 f0       	push   $0xf0105895
f010181b:	68 e5 02 00 00       	push   $0x2e5
f0101820:	68 5d 58 10 f0       	push   $0xf010585d
f0101825:	e8 76 e8 ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010182a:	83 ec 0c             	sub    $0xc,%esp
f010182d:	68 60 52 10 f0       	push   $0xf0105260
f0101832:	e8 de 18 00 00       	call   f0103115 <cprintf>
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
f010184d:	68 5a 59 10 f0       	push   $0xf010595a
f0101852:	68 95 58 10 f0       	push   $0xf0105895
f0101857:	68 46 03 00 00       	push   $0x346
f010185c:	68 5d 58 10 f0       	push   $0xf010585d
f0101861:	e8 3a e8 ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101866:	83 ec 0c             	sub    $0xc,%esp
f0101869:	6a 00                	push   $0x0
f010186b:	e8 df f6 ff ff       	call   f0100f4f <page_alloc>
f0101870:	89 c3                	mov    %eax,%ebx
f0101872:	83 c4 10             	add    $0x10,%esp
f0101875:	85 c0                	test   %eax,%eax
f0101877:	75 19                	jne    f0101892 <mem_init+0x649>
f0101879:	68 70 59 10 f0       	push   $0xf0105970
f010187e:	68 95 58 10 f0       	push   $0xf0105895
f0101883:	68 47 03 00 00       	push   $0x347
f0101888:	68 5d 58 10 f0       	push   $0xf010585d
f010188d:	e8 0e e8 ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101892:	83 ec 0c             	sub    $0xc,%esp
f0101895:	6a 00                	push   $0x0
f0101897:	e8 b3 f6 ff ff       	call   f0100f4f <page_alloc>
f010189c:	89 c6                	mov    %eax,%esi
f010189e:	83 c4 10             	add    $0x10,%esp
f01018a1:	85 c0                	test   %eax,%eax
f01018a3:	75 19                	jne    f01018be <mem_init+0x675>
f01018a5:	68 86 59 10 f0       	push   $0xf0105986
f01018aa:	68 95 58 10 f0       	push   $0xf0105895
f01018af:	68 48 03 00 00       	push   $0x348
f01018b4:	68 5d 58 10 f0       	push   $0xf010585d
f01018b9:	e8 e2 e7 ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01018be:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01018c1:	75 19                	jne    f01018dc <mem_init+0x693>
f01018c3:	68 9c 59 10 f0       	push   $0xf010599c
f01018c8:	68 95 58 10 f0       	push   $0xf0105895
f01018cd:	68 4b 03 00 00       	push   $0x34b
f01018d2:	68 5d 58 10 f0       	push   $0xf010585d
f01018d7:	e8 c4 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018dc:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01018df:	74 04                	je     f01018e5 <mem_init+0x69c>
f01018e1:	39 c3                	cmp    %eax,%ebx
f01018e3:	75 19                	jne    f01018fe <mem_init+0x6b5>
f01018e5:	68 40 52 10 f0       	push   $0xf0105240
f01018ea:	68 95 58 10 f0       	push   $0xf0105895
f01018ef:	68 4c 03 00 00       	push   $0x34c
f01018f4:	68 5d 58 10 f0       	push   $0xf010585d
f01018f9:	e8 a2 e7 ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01018fe:	a1 1c d4 17 f0       	mov    0xf017d41c,%eax
f0101903:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101906:	c7 05 1c d4 17 f0 00 	movl   $0x0,0xf017d41c
f010190d:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101910:	83 ec 0c             	sub    $0xc,%esp
f0101913:	6a 00                	push   $0x0
f0101915:	e8 35 f6 ff ff       	call   f0100f4f <page_alloc>
f010191a:	83 c4 10             	add    $0x10,%esp
f010191d:	85 c0                	test   %eax,%eax
f010191f:	74 19                	je     f010193a <mem_init+0x6f1>
f0101921:	68 05 5a 10 f0       	push   $0xf0105a05
f0101926:	68 95 58 10 f0       	push   $0xf0105895
f010192b:	68 53 03 00 00       	push   $0x353
f0101930:	68 5d 58 10 f0       	push   $0xf010585d
f0101935:	e8 66 e7 ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010193a:	83 ec 04             	sub    $0x4,%esp
f010193d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101940:	50                   	push   %eax
f0101941:	6a 00                	push   $0x0
f0101943:	ff 35 08 e1 17 f0    	pushl  0xf017e108
f0101949:	e8 e3 f7 ff ff       	call   f0101131 <page_lookup>
f010194e:	83 c4 10             	add    $0x10,%esp
f0101951:	85 c0                	test   %eax,%eax
f0101953:	74 19                	je     f010196e <mem_init+0x725>
f0101955:	68 80 52 10 f0       	push   $0xf0105280
f010195a:	68 95 58 10 f0       	push   $0xf0105895
f010195f:	68 56 03 00 00       	push   $0x356
f0101964:	68 5d 58 10 f0       	push   $0xf010585d
f0101969:	e8 32 e7 ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010196e:	6a 02                	push   $0x2
f0101970:	6a 00                	push   $0x0
f0101972:	53                   	push   %ebx
f0101973:	ff 35 08 e1 17 f0    	pushl  0xf017e108
f0101979:	e8 63 f8 ff ff       	call   f01011e1 <page_insert>
f010197e:	83 c4 10             	add    $0x10,%esp
f0101981:	85 c0                	test   %eax,%eax
f0101983:	78 19                	js     f010199e <mem_init+0x755>
f0101985:	68 b8 52 10 f0       	push   $0xf01052b8
f010198a:	68 95 58 10 f0       	push   $0xf0105895
f010198f:	68 59 03 00 00       	push   $0x359
f0101994:	68 5d 58 10 f0       	push   $0xf010585d
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
f01019ae:	ff 35 08 e1 17 f0    	pushl  0xf017e108
f01019b4:	e8 28 f8 ff ff       	call   f01011e1 <page_insert>
f01019b9:	83 c4 20             	add    $0x20,%esp
f01019bc:	85 c0                	test   %eax,%eax
f01019be:	74 19                	je     f01019d9 <mem_init+0x790>
f01019c0:	68 e8 52 10 f0       	push   $0xf01052e8
f01019c5:	68 95 58 10 f0       	push   $0xf0105895
f01019ca:	68 5d 03 00 00       	push   $0x35d
f01019cf:	68 5d 58 10 f0       	push   $0xf010585d
f01019d4:	e8 c7 e6 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01019d9:	8b 3d 08 e1 17 f0    	mov    0xf017e108,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01019df:	a1 0c e1 17 f0       	mov    0xf017e10c,%eax
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
f0101a00:	68 18 53 10 f0       	push   $0xf0105318
f0101a05:	68 95 58 10 f0       	push   $0xf0105895
f0101a0a:	68 5e 03 00 00       	push   $0x35e
f0101a0f:	68 5d 58 10 f0       	push   $0xf010585d
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
f0101a34:	68 40 53 10 f0       	push   $0xf0105340
f0101a39:	68 95 58 10 f0       	push   $0xf0105895
f0101a3e:	68 5f 03 00 00       	push   $0x35f
f0101a43:	68 5d 58 10 f0       	push   $0xf010585d
f0101a48:	e8 53 e6 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101a4d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101a52:	74 19                	je     f0101a6d <mem_init+0x824>
f0101a54:	68 57 5a 10 f0       	push   $0xf0105a57
f0101a59:	68 95 58 10 f0       	push   $0xf0105895
f0101a5e:	68 60 03 00 00       	push   $0x360
f0101a63:	68 5d 58 10 f0       	push   $0xf010585d
f0101a68:	e8 33 e6 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f0101a6d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a70:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a75:	74 19                	je     f0101a90 <mem_init+0x847>
f0101a77:	68 68 5a 10 f0       	push   $0xf0105a68
f0101a7c:	68 95 58 10 f0       	push   $0xf0105895
f0101a81:	68 61 03 00 00       	push   $0x361
f0101a86:	68 5d 58 10 f0       	push   $0xf010585d
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
f0101aa5:	68 70 53 10 f0       	push   $0xf0105370
f0101aaa:	68 95 58 10 f0       	push   $0xf0105895
f0101aaf:	68 64 03 00 00       	push   $0x364
f0101ab4:	68 5d 58 10 f0       	push   $0xf010585d
f0101ab9:	e8 e2 e5 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101abe:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ac3:	a1 08 e1 17 f0       	mov    0xf017e108,%eax
f0101ac8:	e8 4c f0 ff ff       	call   f0100b19 <check_va2pa>
f0101acd:	89 f2                	mov    %esi,%edx
f0101acf:	2b 15 0c e1 17 f0    	sub    0xf017e10c,%edx
f0101ad5:	c1 fa 03             	sar    $0x3,%edx
f0101ad8:	c1 e2 0c             	shl    $0xc,%edx
f0101adb:	39 d0                	cmp    %edx,%eax
f0101add:	74 19                	je     f0101af8 <mem_init+0x8af>
f0101adf:	68 ac 53 10 f0       	push   $0xf01053ac
f0101ae4:	68 95 58 10 f0       	push   $0xf0105895
f0101ae9:	68 65 03 00 00       	push   $0x365
f0101aee:	68 5d 58 10 f0       	push   $0xf010585d
f0101af3:	e8 a8 e5 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101af8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101afd:	74 19                	je     f0101b18 <mem_init+0x8cf>
f0101aff:	68 79 5a 10 f0       	push   $0xf0105a79
f0101b04:	68 95 58 10 f0       	push   $0xf0105895
f0101b09:	68 66 03 00 00       	push   $0x366
f0101b0e:	68 5d 58 10 f0       	push   $0xf010585d
f0101b13:	e8 88 e5 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101b18:	83 ec 0c             	sub    $0xc,%esp
f0101b1b:	6a 00                	push   $0x0
f0101b1d:	e8 2d f4 ff ff       	call   f0100f4f <page_alloc>
f0101b22:	83 c4 10             	add    $0x10,%esp
f0101b25:	85 c0                	test   %eax,%eax
f0101b27:	74 19                	je     f0101b42 <mem_init+0x8f9>
f0101b29:	68 05 5a 10 f0       	push   $0xf0105a05
f0101b2e:	68 95 58 10 f0       	push   $0xf0105895
f0101b33:	68 69 03 00 00       	push   $0x369
f0101b38:	68 5d 58 10 f0       	push   $0xf010585d
f0101b3d:	e8 5e e5 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b42:	6a 02                	push   $0x2
f0101b44:	68 00 10 00 00       	push   $0x1000
f0101b49:	56                   	push   %esi
f0101b4a:	ff 35 08 e1 17 f0    	pushl  0xf017e108
f0101b50:	e8 8c f6 ff ff       	call   f01011e1 <page_insert>
f0101b55:	83 c4 10             	add    $0x10,%esp
f0101b58:	85 c0                	test   %eax,%eax
f0101b5a:	74 19                	je     f0101b75 <mem_init+0x92c>
f0101b5c:	68 70 53 10 f0       	push   $0xf0105370
f0101b61:	68 95 58 10 f0       	push   $0xf0105895
f0101b66:	68 6c 03 00 00       	push   $0x36c
f0101b6b:	68 5d 58 10 f0       	push   $0xf010585d
f0101b70:	e8 2b e5 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b75:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b7a:	a1 08 e1 17 f0       	mov    0xf017e108,%eax
f0101b7f:	e8 95 ef ff ff       	call   f0100b19 <check_va2pa>
f0101b84:	89 f2                	mov    %esi,%edx
f0101b86:	2b 15 0c e1 17 f0    	sub    0xf017e10c,%edx
f0101b8c:	c1 fa 03             	sar    $0x3,%edx
f0101b8f:	c1 e2 0c             	shl    $0xc,%edx
f0101b92:	39 d0                	cmp    %edx,%eax
f0101b94:	74 19                	je     f0101baf <mem_init+0x966>
f0101b96:	68 ac 53 10 f0       	push   $0xf01053ac
f0101b9b:	68 95 58 10 f0       	push   $0xf0105895
f0101ba0:	68 6d 03 00 00       	push   $0x36d
f0101ba5:	68 5d 58 10 f0       	push   $0xf010585d
f0101baa:	e8 f1 e4 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101baf:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101bb4:	74 19                	je     f0101bcf <mem_init+0x986>
f0101bb6:	68 79 5a 10 f0       	push   $0xf0105a79
f0101bbb:	68 95 58 10 f0       	push   $0xf0105895
f0101bc0:	68 6e 03 00 00       	push   $0x36e
f0101bc5:	68 5d 58 10 f0       	push   $0xf010585d
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
f0101be0:	68 05 5a 10 f0       	push   $0xf0105a05
f0101be5:	68 95 58 10 f0       	push   $0xf0105895
f0101bea:	68 72 03 00 00       	push   $0x372
f0101bef:	68 5d 58 10 f0       	push   $0xf010585d
f0101bf4:	e8 a7 e4 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101bf9:	8b 15 08 e1 17 f0    	mov    0xf017e108,%edx
f0101bff:	8b 02                	mov    (%edx),%eax
f0101c01:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101c06:	89 c1                	mov    %eax,%ecx
f0101c08:	c1 e9 0c             	shr    $0xc,%ecx
f0101c0b:	3b 0d 04 e1 17 f0    	cmp    0xf017e104,%ecx
f0101c11:	72 15                	jb     f0101c28 <mem_init+0x9df>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101c13:	50                   	push   %eax
f0101c14:	68 08 50 10 f0       	push   $0xf0105008
f0101c19:	68 75 03 00 00       	push   $0x375
f0101c1e:	68 5d 58 10 f0       	push   $0xf010585d
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
f0101c4d:	68 dc 53 10 f0       	push   $0xf01053dc
f0101c52:	68 95 58 10 f0       	push   $0xf0105895
f0101c57:	68 76 03 00 00       	push   $0x376
f0101c5c:	68 5d 58 10 f0       	push   $0xf010585d
f0101c61:	e8 3a e4 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c66:	6a 06                	push   $0x6
f0101c68:	68 00 10 00 00       	push   $0x1000
f0101c6d:	56                   	push   %esi
f0101c6e:	ff 35 08 e1 17 f0    	pushl  0xf017e108
f0101c74:	e8 68 f5 ff ff       	call   f01011e1 <page_insert>
f0101c79:	83 c4 10             	add    $0x10,%esp
f0101c7c:	85 c0                	test   %eax,%eax
f0101c7e:	74 19                	je     f0101c99 <mem_init+0xa50>
f0101c80:	68 1c 54 10 f0       	push   $0xf010541c
f0101c85:	68 95 58 10 f0       	push   $0xf0105895
f0101c8a:	68 79 03 00 00       	push   $0x379
f0101c8f:	68 5d 58 10 f0       	push   $0xf010585d
f0101c94:	e8 07 e4 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c99:	8b 3d 08 e1 17 f0    	mov    0xf017e108,%edi
f0101c9f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ca4:	89 f8                	mov    %edi,%eax
f0101ca6:	e8 6e ee ff ff       	call   f0100b19 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101cab:	89 f2                	mov    %esi,%edx
f0101cad:	2b 15 0c e1 17 f0    	sub    0xf017e10c,%edx
f0101cb3:	c1 fa 03             	sar    $0x3,%edx
f0101cb6:	c1 e2 0c             	shl    $0xc,%edx
f0101cb9:	39 d0                	cmp    %edx,%eax
f0101cbb:	74 19                	je     f0101cd6 <mem_init+0xa8d>
f0101cbd:	68 ac 53 10 f0       	push   $0xf01053ac
f0101cc2:	68 95 58 10 f0       	push   $0xf0105895
f0101cc7:	68 7a 03 00 00       	push   $0x37a
f0101ccc:	68 5d 58 10 f0       	push   $0xf010585d
f0101cd1:	e8 ca e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101cd6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101cdb:	74 19                	je     f0101cf6 <mem_init+0xaad>
f0101cdd:	68 79 5a 10 f0       	push   $0xf0105a79
f0101ce2:	68 95 58 10 f0       	push   $0xf0105895
f0101ce7:	68 7b 03 00 00       	push   $0x37b
f0101cec:	68 5d 58 10 f0       	push   $0xf010585d
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
f0101d0e:	68 5c 54 10 f0       	push   $0xf010545c
f0101d13:	68 95 58 10 f0       	push   $0xf0105895
f0101d18:	68 7c 03 00 00       	push   $0x37c
f0101d1d:	68 5d 58 10 f0       	push   $0xf010585d
f0101d22:	e8 79 e3 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101d27:	a1 08 e1 17 f0       	mov    0xf017e108,%eax
f0101d2c:	f6 00 04             	testb  $0x4,(%eax)
f0101d2f:	75 19                	jne    f0101d4a <mem_init+0xb01>
f0101d31:	68 8a 5a 10 f0       	push   $0xf0105a8a
f0101d36:	68 95 58 10 f0       	push   $0xf0105895
f0101d3b:	68 7d 03 00 00       	push   $0x37d
f0101d40:	68 5d 58 10 f0       	push   $0xf010585d
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
f0101d5f:	68 70 53 10 f0       	push   $0xf0105370
f0101d64:	68 95 58 10 f0       	push   $0xf0105895
f0101d69:	68 80 03 00 00       	push   $0x380
f0101d6e:	68 5d 58 10 f0       	push   $0xf010585d
f0101d73:	e8 28 e3 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101d78:	83 ec 04             	sub    $0x4,%esp
f0101d7b:	6a 00                	push   $0x0
f0101d7d:	68 00 10 00 00       	push   $0x1000
f0101d82:	ff 35 08 e1 17 f0    	pushl  0xf017e108
f0101d88:	e8 9a f2 ff ff       	call   f0101027 <pgdir_walk>
f0101d8d:	83 c4 10             	add    $0x10,%esp
f0101d90:	f6 00 02             	testb  $0x2,(%eax)
f0101d93:	75 19                	jne    f0101dae <mem_init+0xb65>
f0101d95:	68 90 54 10 f0       	push   $0xf0105490
f0101d9a:	68 95 58 10 f0       	push   $0xf0105895
f0101d9f:	68 81 03 00 00       	push   $0x381
f0101da4:	68 5d 58 10 f0       	push   $0xf010585d
f0101da9:	e8 f2 e2 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101dae:	83 ec 04             	sub    $0x4,%esp
f0101db1:	6a 00                	push   $0x0
f0101db3:	68 00 10 00 00       	push   $0x1000
f0101db8:	ff 35 08 e1 17 f0    	pushl  0xf017e108
f0101dbe:	e8 64 f2 ff ff       	call   f0101027 <pgdir_walk>
f0101dc3:	83 c4 10             	add    $0x10,%esp
f0101dc6:	f6 00 04             	testb  $0x4,(%eax)
f0101dc9:	74 19                	je     f0101de4 <mem_init+0xb9b>
f0101dcb:	68 c4 54 10 f0       	push   $0xf01054c4
f0101dd0:	68 95 58 10 f0       	push   $0xf0105895
f0101dd5:	68 82 03 00 00       	push   $0x382
f0101dda:	68 5d 58 10 f0       	push   $0xf010585d
f0101ddf:	e8 bc e2 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101de4:	6a 02                	push   $0x2
f0101de6:	68 00 00 40 00       	push   $0x400000
f0101deb:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101dee:	ff 35 08 e1 17 f0    	pushl  0xf017e108
f0101df4:	e8 e8 f3 ff ff       	call   f01011e1 <page_insert>
f0101df9:	83 c4 10             	add    $0x10,%esp
f0101dfc:	85 c0                	test   %eax,%eax
f0101dfe:	78 19                	js     f0101e19 <mem_init+0xbd0>
f0101e00:	68 fc 54 10 f0       	push   $0xf01054fc
f0101e05:	68 95 58 10 f0       	push   $0xf0105895
f0101e0a:	68 85 03 00 00       	push   $0x385
f0101e0f:	68 5d 58 10 f0       	push   $0xf010585d
f0101e14:	e8 87 e2 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101e19:	6a 02                	push   $0x2
f0101e1b:	68 00 10 00 00       	push   $0x1000
f0101e20:	53                   	push   %ebx
f0101e21:	ff 35 08 e1 17 f0    	pushl  0xf017e108
f0101e27:	e8 b5 f3 ff ff       	call   f01011e1 <page_insert>
f0101e2c:	83 c4 10             	add    $0x10,%esp
f0101e2f:	85 c0                	test   %eax,%eax
f0101e31:	74 19                	je     f0101e4c <mem_init+0xc03>
f0101e33:	68 34 55 10 f0       	push   $0xf0105534
f0101e38:	68 95 58 10 f0       	push   $0xf0105895
f0101e3d:	68 88 03 00 00       	push   $0x388
f0101e42:	68 5d 58 10 f0       	push   $0xf010585d
f0101e47:	e8 54 e2 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e4c:	83 ec 04             	sub    $0x4,%esp
f0101e4f:	6a 00                	push   $0x0
f0101e51:	68 00 10 00 00       	push   $0x1000
f0101e56:	ff 35 08 e1 17 f0    	pushl  0xf017e108
f0101e5c:	e8 c6 f1 ff ff       	call   f0101027 <pgdir_walk>
f0101e61:	83 c4 10             	add    $0x10,%esp
f0101e64:	f6 00 04             	testb  $0x4,(%eax)
f0101e67:	74 19                	je     f0101e82 <mem_init+0xc39>
f0101e69:	68 c4 54 10 f0       	push   $0xf01054c4
f0101e6e:	68 95 58 10 f0       	push   $0xf0105895
f0101e73:	68 89 03 00 00       	push   $0x389
f0101e78:	68 5d 58 10 f0       	push   $0xf010585d
f0101e7d:	e8 1e e2 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101e82:	8b 3d 08 e1 17 f0    	mov    0xf017e108,%edi
f0101e88:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e8d:	89 f8                	mov    %edi,%eax
f0101e8f:	e8 85 ec ff ff       	call   f0100b19 <check_va2pa>
f0101e94:	89 c1                	mov    %eax,%ecx
f0101e96:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e99:	89 d8                	mov    %ebx,%eax
f0101e9b:	2b 05 0c e1 17 f0    	sub    0xf017e10c,%eax
f0101ea1:	c1 f8 03             	sar    $0x3,%eax
f0101ea4:	c1 e0 0c             	shl    $0xc,%eax
f0101ea7:	39 c1                	cmp    %eax,%ecx
f0101ea9:	74 19                	je     f0101ec4 <mem_init+0xc7b>
f0101eab:	68 70 55 10 f0       	push   $0xf0105570
f0101eb0:	68 95 58 10 f0       	push   $0xf0105895
f0101eb5:	68 8c 03 00 00       	push   $0x38c
f0101eba:	68 5d 58 10 f0       	push   $0xf010585d
f0101ebf:	e8 dc e1 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ec4:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ec9:	89 f8                	mov    %edi,%eax
f0101ecb:	e8 49 ec ff ff       	call   f0100b19 <check_va2pa>
f0101ed0:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101ed3:	74 19                	je     f0101eee <mem_init+0xca5>
f0101ed5:	68 9c 55 10 f0       	push   $0xf010559c
f0101eda:	68 95 58 10 f0       	push   $0xf0105895
f0101edf:	68 8d 03 00 00       	push   $0x38d
f0101ee4:	68 5d 58 10 f0       	push   $0xf010585d
f0101ee9:	e8 b2 e1 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101eee:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101ef3:	74 19                	je     f0101f0e <mem_init+0xcc5>
f0101ef5:	68 a0 5a 10 f0       	push   $0xf0105aa0
f0101efa:	68 95 58 10 f0       	push   $0xf0105895
f0101eff:	68 8f 03 00 00       	push   $0x38f
f0101f04:	68 5d 58 10 f0       	push   $0xf010585d
f0101f09:	e8 92 e1 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101f0e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f13:	74 19                	je     f0101f2e <mem_init+0xce5>
f0101f15:	68 b1 5a 10 f0       	push   $0xf0105ab1
f0101f1a:	68 95 58 10 f0       	push   $0xf0105895
f0101f1f:	68 90 03 00 00       	push   $0x390
f0101f24:	68 5d 58 10 f0       	push   $0xf010585d
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
f0101f43:	68 cc 55 10 f0       	push   $0xf01055cc
f0101f48:	68 95 58 10 f0       	push   $0xf0105895
f0101f4d:	68 93 03 00 00       	push   $0x393
f0101f52:	68 5d 58 10 f0       	push   $0xf010585d
f0101f57:	e8 44 e1 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101f5c:	83 ec 08             	sub    $0x8,%esp
f0101f5f:	6a 00                	push   $0x0
f0101f61:	ff 35 08 e1 17 f0    	pushl  0xf017e108
f0101f67:	e8 2b f2 ff ff       	call   f0101197 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f6c:	8b 3d 08 e1 17 f0    	mov    0xf017e108,%edi
f0101f72:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f77:	89 f8                	mov    %edi,%eax
f0101f79:	e8 9b eb ff ff       	call   f0100b19 <check_va2pa>
f0101f7e:	83 c4 10             	add    $0x10,%esp
f0101f81:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f84:	74 19                	je     f0101f9f <mem_init+0xd56>
f0101f86:	68 f0 55 10 f0       	push   $0xf01055f0
f0101f8b:	68 95 58 10 f0       	push   $0xf0105895
f0101f90:	68 97 03 00 00       	push   $0x397
f0101f95:	68 5d 58 10 f0       	push   $0xf010585d
f0101f9a:	e8 01 e1 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f9f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fa4:	89 f8                	mov    %edi,%eax
f0101fa6:	e8 6e eb ff ff       	call   f0100b19 <check_va2pa>
f0101fab:	89 da                	mov    %ebx,%edx
f0101fad:	2b 15 0c e1 17 f0    	sub    0xf017e10c,%edx
f0101fb3:	c1 fa 03             	sar    $0x3,%edx
f0101fb6:	c1 e2 0c             	shl    $0xc,%edx
f0101fb9:	39 d0                	cmp    %edx,%eax
f0101fbb:	74 19                	je     f0101fd6 <mem_init+0xd8d>
f0101fbd:	68 9c 55 10 f0       	push   $0xf010559c
f0101fc2:	68 95 58 10 f0       	push   $0xf0105895
f0101fc7:	68 98 03 00 00       	push   $0x398
f0101fcc:	68 5d 58 10 f0       	push   $0xf010585d
f0101fd1:	e8 ca e0 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101fd6:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101fdb:	74 19                	je     f0101ff6 <mem_init+0xdad>
f0101fdd:	68 57 5a 10 f0       	push   $0xf0105a57
f0101fe2:	68 95 58 10 f0       	push   $0xf0105895
f0101fe7:	68 99 03 00 00       	push   $0x399
f0101fec:	68 5d 58 10 f0       	push   $0xf010585d
f0101ff1:	e8 aa e0 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101ff6:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ffb:	74 19                	je     f0102016 <mem_init+0xdcd>
f0101ffd:	68 b1 5a 10 f0       	push   $0xf0105ab1
f0102002:	68 95 58 10 f0       	push   $0xf0105895
f0102007:	68 9a 03 00 00       	push   $0x39a
f010200c:	68 5d 58 10 f0       	push   $0xf010585d
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
f010202b:	68 14 56 10 f0       	push   $0xf0105614
f0102030:	68 95 58 10 f0       	push   $0xf0105895
f0102035:	68 9d 03 00 00       	push   $0x39d
f010203a:	68 5d 58 10 f0       	push   $0xf010585d
f010203f:	e8 5c e0 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0102044:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102049:	75 19                	jne    f0102064 <mem_init+0xe1b>
f010204b:	68 c2 5a 10 f0       	push   $0xf0105ac2
f0102050:	68 95 58 10 f0       	push   $0xf0105895
f0102055:	68 9e 03 00 00       	push   $0x39e
f010205a:	68 5d 58 10 f0       	push   $0xf010585d
f010205f:	e8 3c e0 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0102064:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102067:	74 19                	je     f0102082 <mem_init+0xe39>
f0102069:	68 ce 5a 10 f0       	push   $0xf0105ace
f010206e:	68 95 58 10 f0       	push   $0xf0105895
f0102073:	68 9f 03 00 00       	push   $0x39f
f0102078:	68 5d 58 10 f0       	push   $0xf010585d
f010207d:	e8 1e e0 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102082:	83 ec 08             	sub    $0x8,%esp
f0102085:	68 00 10 00 00       	push   $0x1000
f010208a:	ff 35 08 e1 17 f0    	pushl  0xf017e108
f0102090:	e8 02 f1 ff ff       	call   f0101197 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102095:	8b 3d 08 e1 17 f0    	mov    0xf017e108,%edi
f010209b:	ba 00 00 00 00       	mov    $0x0,%edx
f01020a0:	89 f8                	mov    %edi,%eax
f01020a2:	e8 72 ea ff ff       	call   f0100b19 <check_va2pa>
f01020a7:	83 c4 10             	add    $0x10,%esp
f01020aa:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020ad:	74 19                	je     f01020c8 <mem_init+0xe7f>
f01020af:	68 f0 55 10 f0       	push   $0xf01055f0
f01020b4:	68 95 58 10 f0       	push   $0xf0105895
f01020b9:	68 a3 03 00 00       	push   $0x3a3
f01020be:	68 5d 58 10 f0       	push   $0xf010585d
f01020c3:	e8 d8 df ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01020c8:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020cd:	89 f8                	mov    %edi,%eax
f01020cf:	e8 45 ea ff ff       	call   f0100b19 <check_va2pa>
f01020d4:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020d7:	74 19                	je     f01020f2 <mem_init+0xea9>
f01020d9:	68 4c 56 10 f0       	push   $0xf010564c
f01020de:	68 95 58 10 f0       	push   $0xf0105895
f01020e3:	68 a4 03 00 00       	push   $0x3a4
f01020e8:	68 5d 58 10 f0       	push   $0xf010585d
f01020ed:	e8 ae df ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f01020f2:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01020f7:	74 19                	je     f0102112 <mem_init+0xec9>
f01020f9:	68 e3 5a 10 f0       	push   $0xf0105ae3
f01020fe:	68 95 58 10 f0       	push   $0xf0105895
f0102103:	68 a5 03 00 00       	push   $0x3a5
f0102108:	68 5d 58 10 f0       	push   $0xf010585d
f010210d:	e8 8e df ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0102112:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102117:	74 19                	je     f0102132 <mem_init+0xee9>
f0102119:	68 b1 5a 10 f0       	push   $0xf0105ab1
f010211e:	68 95 58 10 f0       	push   $0xf0105895
f0102123:	68 a6 03 00 00       	push   $0x3a6
f0102128:	68 5d 58 10 f0       	push   $0xf010585d
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
f0102147:	68 74 56 10 f0       	push   $0xf0105674
f010214c:	68 95 58 10 f0       	push   $0xf0105895
f0102151:	68 a9 03 00 00       	push   $0x3a9
f0102156:	68 5d 58 10 f0       	push   $0xf010585d
f010215b:	e8 40 df ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102160:	83 ec 0c             	sub    $0xc,%esp
f0102163:	6a 00                	push   $0x0
f0102165:	e8 e5 ed ff ff       	call   f0100f4f <page_alloc>
f010216a:	83 c4 10             	add    $0x10,%esp
f010216d:	85 c0                	test   %eax,%eax
f010216f:	74 19                	je     f010218a <mem_init+0xf41>
f0102171:	68 05 5a 10 f0       	push   $0xf0105a05
f0102176:	68 95 58 10 f0       	push   $0xf0105895
f010217b:	68 ac 03 00 00       	push   $0x3ac
f0102180:	68 5d 58 10 f0       	push   $0xf010585d
f0102185:	e8 16 df ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010218a:	8b 0d 08 e1 17 f0    	mov    0xf017e108,%ecx
f0102190:	8b 11                	mov    (%ecx),%edx
f0102192:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102198:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010219b:	2b 05 0c e1 17 f0    	sub    0xf017e10c,%eax
f01021a1:	c1 f8 03             	sar    $0x3,%eax
f01021a4:	c1 e0 0c             	shl    $0xc,%eax
f01021a7:	39 c2                	cmp    %eax,%edx
f01021a9:	74 19                	je     f01021c4 <mem_init+0xf7b>
f01021ab:	68 18 53 10 f0       	push   $0xf0105318
f01021b0:	68 95 58 10 f0       	push   $0xf0105895
f01021b5:	68 af 03 00 00       	push   $0x3af
f01021ba:	68 5d 58 10 f0       	push   $0xf010585d
f01021bf:	e8 dc de ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f01021c4:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01021ca:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021cd:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01021d2:	74 19                	je     f01021ed <mem_init+0xfa4>
f01021d4:	68 68 5a 10 f0       	push   $0xf0105a68
f01021d9:	68 95 58 10 f0       	push   $0xf0105895
f01021de:	68 b1 03 00 00       	push   $0x3b1
f01021e3:	68 5d 58 10 f0       	push   $0xf010585d
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
f0102209:	ff 35 08 e1 17 f0    	pushl  0xf017e108
f010220f:	e8 13 ee ff ff       	call   f0101027 <pgdir_walk>
f0102214:	89 c7                	mov    %eax,%edi
f0102216:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102219:	a1 08 e1 17 f0       	mov    0xf017e108,%eax
f010221e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102221:	8b 40 04             	mov    0x4(%eax),%eax
f0102224:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102229:	8b 0d 04 e1 17 f0    	mov    0xf017e104,%ecx
f010222f:	89 c2                	mov    %eax,%edx
f0102231:	c1 ea 0c             	shr    $0xc,%edx
f0102234:	83 c4 10             	add    $0x10,%esp
f0102237:	39 ca                	cmp    %ecx,%edx
f0102239:	72 15                	jb     f0102250 <mem_init+0x1007>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010223b:	50                   	push   %eax
f010223c:	68 08 50 10 f0       	push   $0xf0105008
f0102241:	68 b8 03 00 00       	push   $0x3b8
f0102246:	68 5d 58 10 f0       	push   $0xf010585d
f010224b:	e8 50 de ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102250:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0102255:	39 c7                	cmp    %eax,%edi
f0102257:	74 19                	je     f0102272 <mem_init+0x1029>
f0102259:	68 f4 5a 10 f0       	push   $0xf0105af4
f010225e:	68 95 58 10 f0       	push   $0xf0105895
f0102263:	68 b9 03 00 00       	push   $0x3b9
f0102268:	68 5d 58 10 f0       	push   $0xf010585d
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
f0102285:	2b 05 0c e1 17 f0    	sub    0xf017e10c,%eax
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
f010229b:	68 08 50 10 f0       	push   $0xf0105008
f01022a0:	6a 56                	push   $0x56
f01022a2:	68 7b 58 10 f0       	push   $0xf010587b
f01022a7:	e8 f4 dd ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01022ac:	83 ec 04             	sub    $0x4,%esp
f01022af:	68 00 10 00 00       	push   $0x1000
f01022b4:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f01022b9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01022be:	50                   	push   %eax
f01022bf:	e8 a6 20 00 00       	call   f010436a <memset>
	page_free(pp0);
f01022c4:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01022c7:	89 3c 24             	mov    %edi,(%esp)
f01022ca:	e8 f0 ec ff ff       	call   f0100fbf <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01022cf:	83 c4 0c             	add    $0xc,%esp
f01022d2:	6a 01                	push   $0x1
f01022d4:	6a 00                	push   $0x0
f01022d6:	ff 35 08 e1 17 f0    	pushl  0xf017e108
f01022dc:	e8 46 ed ff ff       	call   f0101027 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01022e1:	89 fa                	mov    %edi,%edx
f01022e3:	2b 15 0c e1 17 f0    	sub    0xf017e10c,%edx
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
f01022f7:	3b 05 04 e1 17 f0    	cmp    0xf017e104,%eax
f01022fd:	72 12                	jb     f0102311 <mem_init+0x10c8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01022ff:	52                   	push   %edx
f0102300:	68 08 50 10 f0       	push   $0xf0105008
f0102305:	6a 56                	push   $0x56
f0102307:	68 7b 58 10 f0       	push   $0xf010587b
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
f0102325:	68 0c 5b 10 f0       	push   $0xf0105b0c
f010232a:	68 95 58 10 f0       	push   $0xf0105895
f010232f:	68 c3 03 00 00       	push   $0x3c3
f0102334:	68 5d 58 10 f0       	push   $0xf010585d
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
f0102345:	a1 08 e1 17 f0       	mov    0xf017e108,%eax
f010234a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102350:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102353:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102359:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010235c:	89 3d 1c d4 17 f0    	mov    %edi,0xf017d41c

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
f010237b:	c7 04 24 23 5b 10 f0 	movl   $0xf0105b23,(%esp)
f0102382:	e8 8e 0d 00 00       	call   f0103115 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U|PTE_P);
f0102387:	a1 0c e1 17 f0       	mov    0xf017e10c,%eax
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
f0102397:	68 2c 50 10 f0       	push   $0xf010502c
f010239c:	68 c4 00 00 00       	push   $0xc4
f01023a1:	68 5d 58 10 f0       	push   $0xf010585d
f01023a6:	e8 f5 dc ff ff       	call   f01000a0 <_panic>
f01023ab:	83 ec 08             	sub    $0x8,%esp
f01023ae:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f01023b0:	05 00 00 00 10       	add    $0x10000000,%eax
f01023b5:	50                   	push   %eax
f01023b6:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01023bb:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01023c0:	a1 08 e1 17 f0       	mov    0xf017e108,%eax
f01023c5:	e8 f0 ec ff ff       	call   f01010ba <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U);
f01023ca:	a1 28 d4 17 f0       	mov    0xf017d428,%eax
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
f01023da:	68 2c 50 10 f0       	push   $0xf010502c
f01023df:	68 cd 00 00 00       	push   $0xcd
f01023e4:	68 5d 58 10 f0       	push   $0xf010585d
f01023e9:	e8 b2 dc ff ff       	call   f01000a0 <_panic>
f01023ee:	83 ec 08             	sub    $0x8,%esp
f01023f1:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f01023f3:	05 00 00 00 10       	add    $0x10000000,%eax
f01023f8:	50                   	push   %eax
f01023f9:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01023fe:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102403:	a1 08 e1 17 f0       	mov    0xf017e108,%eax
f0102408:	e8 ad ec ff ff       	call   f01010ba <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010240d:	83 c4 10             	add    $0x10,%esp
f0102410:	b8 00 10 11 f0       	mov    $0xf0111000,%eax
f0102415:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010241a:	77 15                	ja     f0102431 <mem_init+0x11e8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010241c:	50                   	push   %eax
f010241d:	68 2c 50 10 f0       	push   $0xf010502c
f0102422:	68 da 00 00 00       	push   $0xda
f0102427:	68 5d 58 10 f0       	push   $0xf010585d
f010242c:	e8 6f dc ff ff       	call   f01000a0 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102431:	83 ec 08             	sub    $0x8,%esp
f0102434:	6a 02                	push   $0x2
f0102436:	68 00 10 11 00       	push   $0x111000
f010243b:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102440:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102445:	a1 08 e1 17 f0       	mov    0xf017e108,%eax
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
f0102460:	a1 08 e1 17 f0       	mov    0xf017e108,%eax
f0102465:	e8 50 ec ff ff       	call   f01010ba <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010246a:	8b 1d 08 e1 17 f0    	mov    0xf017e108,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102470:	a1 04 e1 17 f0       	mov    0xf017e104,%eax
f0102475:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102478:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010247f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102484:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102487:	8b 3d 0c e1 17 f0    	mov    0xf017e10c,%edi
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
f01024b1:	68 2c 50 10 f0       	push   $0xf010502c
f01024b6:	68 fd 02 00 00       	push   $0x2fd
f01024bb:	68 5d 58 10 f0       	push   $0xf010585d
f01024c0:	e8 db db ff ff       	call   f01000a0 <_panic>
f01024c5:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f01024cc:	39 c2                	cmp    %eax,%edx
f01024ce:	74 19                	je     f01024e9 <mem_init+0x12a0>
f01024d0:	68 98 56 10 f0       	push   $0xf0105698
f01024d5:	68 95 58 10 f0       	push   $0xf0105895
f01024da:	68 fd 02 00 00       	push   $0x2fd
f01024df:	68 5d 58 10 f0       	push   $0xf010585d
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
f01024f4:	8b 3d 28 d4 17 f0    	mov    0xf017d428,%edi
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
f0102515:	68 2c 50 10 f0       	push   $0xf010502c
f010251a:	68 02 03 00 00       	push   $0x302
f010251f:	68 5d 58 10 f0       	push   $0xf010585d
f0102524:	e8 77 db ff ff       	call   f01000a0 <_panic>
f0102529:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f0102530:	39 c2                	cmp    %eax,%edx
f0102532:	74 19                	je     f010254d <mem_init+0x1304>
f0102534:	68 cc 56 10 f0       	push   $0xf01056cc
f0102539:	68 95 58 10 f0       	push   $0xf0105895
f010253e:	68 02 03 00 00       	push   $0x302
f0102543:	68 5d 58 10 f0       	push   $0xf010585d
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
f0102579:	68 00 57 10 f0       	push   $0xf0105700
f010257e:	68 95 58 10 f0       	push   $0xf0105895
f0102583:	68 06 03 00 00       	push   $0x306
f0102588:	68 5d 58 10 f0       	push   $0xf010585d
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
f01025aa:	8d 96 00 90 11 10    	lea    0x10119000(%esi),%edx
f01025b0:	39 c2                	cmp    %eax,%edx
f01025b2:	74 19                	je     f01025cd <mem_init+0x1384>
f01025b4:	68 28 57 10 f0       	push   $0xf0105728
f01025b9:	68 95 58 10 f0       	push   $0xf0105895
f01025be:	68 0a 03 00 00       	push   $0x30a
f01025c3:	68 5d 58 10 f0       	push   $0xf010585d
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
f01025ec:	68 70 57 10 f0       	push   $0xf0105770
f01025f1:	68 95 58 10 f0       	push   $0xf0105895
f01025f6:	68 0b 03 00 00       	push   $0x30b
f01025fb:	68 5d 58 10 f0       	push   $0xf010585d
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
f0102624:	68 3c 5b 10 f0       	push   $0xf0105b3c
f0102629:	68 95 58 10 f0       	push   $0xf0105895
f010262e:	68 14 03 00 00       	push   $0x314
f0102633:	68 5d 58 10 f0       	push   $0xf010585d
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
f0102651:	68 3c 5b 10 f0       	push   $0xf0105b3c
f0102656:	68 95 58 10 f0       	push   $0xf0105895
f010265b:	68 18 03 00 00       	push   $0x318
f0102660:	68 5d 58 10 f0       	push   $0xf010585d
f0102665:	e8 36 da ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f010266a:	f6 c2 02             	test   $0x2,%dl
f010266d:	75 38                	jne    f01026a7 <mem_init+0x145e>
f010266f:	68 4d 5b 10 f0       	push   $0xf0105b4d
f0102674:	68 95 58 10 f0       	push   $0xf0105895
f0102679:	68 19 03 00 00       	push   $0x319
f010267e:	68 5d 58 10 f0       	push   $0xf010585d
f0102683:	e8 18 da ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102688:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f010268c:	74 19                	je     f01026a7 <mem_init+0x145e>
f010268e:	68 5e 5b 10 f0       	push   $0xf0105b5e
f0102693:	68 95 58 10 f0       	push   $0xf0105895
f0102698:	68 1b 03 00 00       	push   $0x31b
f010269d:	68 5d 58 10 f0       	push   $0xf010585d
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
f01026b8:	68 a0 57 10 f0       	push   $0xf01057a0
f01026bd:	e8 53 0a 00 00       	call   f0103115 <cprintf>
		uintptr_t paddress = 0;
		for(paddress = 0; paddress < ((uintptr_t)0x10000000); paddress += PTSIZE){
		invlpg((void*)(KERNBASE + paddress));
	}
	}*/
	lcr3(PADDR(kern_pgdir));
f01026c2:	a1 08 e1 17 f0       	mov    0xf017e108,%eax
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
f01026d2:	68 2c 50 10 f0       	push   $0xf010502c
f01026d7:	68 01 01 00 00       	push   $0x101
f01026dc:	68 5d 58 10 f0       	push   $0xf010585d
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
f0102719:	68 5a 59 10 f0       	push   $0xf010595a
f010271e:	68 95 58 10 f0       	push   $0xf0105895
f0102723:	68 de 03 00 00       	push   $0x3de
f0102728:	68 5d 58 10 f0       	push   $0xf010585d
f010272d:	e8 6e d9 ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0102732:	83 ec 0c             	sub    $0xc,%esp
f0102735:	6a 00                	push   $0x0
f0102737:	e8 13 e8 ff ff       	call   f0100f4f <page_alloc>
f010273c:	89 c7                	mov    %eax,%edi
f010273e:	83 c4 10             	add    $0x10,%esp
f0102741:	85 c0                	test   %eax,%eax
f0102743:	75 19                	jne    f010275e <mem_init+0x1515>
f0102745:	68 70 59 10 f0       	push   $0xf0105970
f010274a:	68 95 58 10 f0       	push   $0xf0105895
f010274f:	68 df 03 00 00       	push   $0x3df
f0102754:	68 5d 58 10 f0       	push   $0xf010585d
f0102759:	e8 42 d9 ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010275e:	83 ec 0c             	sub    $0xc,%esp
f0102761:	6a 00                	push   $0x0
f0102763:	e8 e7 e7 ff ff       	call   f0100f4f <page_alloc>
f0102768:	89 c6                	mov    %eax,%esi
f010276a:	83 c4 10             	add    $0x10,%esp
f010276d:	85 c0                	test   %eax,%eax
f010276f:	75 19                	jne    f010278a <mem_init+0x1541>
f0102771:	68 86 59 10 f0       	push   $0xf0105986
f0102776:	68 95 58 10 f0       	push   $0xf0105895
f010277b:	68 e0 03 00 00       	push   $0x3e0
f0102780:	68 5d 58 10 f0       	push   $0xf010585d
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
f0102795:	2b 05 0c e1 17 f0    	sub    0xf017e10c,%eax
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
f01027a9:	3b 15 04 e1 17 f0    	cmp    0xf017e104,%edx
f01027af:	72 12                	jb     f01027c3 <mem_init+0x157a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01027b1:	50                   	push   %eax
f01027b2:	68 08 50 10 f0       	push   $0xf0105008
f01027b7:	6a 56                	push   $0x56
f01027b9:	68 7b 58 10 f0       	push   $0xf010587b
f01027be:	e8 dd d8 ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01027c3:	83 ec 04             	sub    $0x4,%esp
f01027c6:	68 00 10 00 00       	push   $0x1000
f01027cb:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f01027cd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01027d2:	50                   	push   %eax
f01027d3:	e8 92 1b 00 00       	call   f010436a <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01027d8:	89 f0                	mov    %esi,%eax
f01027da:	2b 05 0c e1 17 f0    	sub    0xf017e10c,%eax
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
f01027ee:	3b 15 04 e1 17 f0    	cmp    0xf017e104,%edx
f01027f4:	72 12                	jb     f0102808 <mem_init+0x15bf>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01027f6:	50                   	push   %eax
f01027f7:	68 08 50 10 f0       	push   $0xf0105008
f01027fc:	6a 56                	push   $0x56
f01027fe:	68 7b 58 10 f0       	push   $0xf010587b
f0102803:	e8 98 d8 ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102808:	83 ec 04             	sub    $0x4,%esp
f010280b:	68 00 10 00 00       	push   $0x1000
f0102810:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102812:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102817:	50                   	push   %eax
f0102818:	e8 4d 1b 00 00       	call   f010436a <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010281d:	6a 02                	push   $0x2
f010281f:	68 00 10 00 00       	push   $0x1000
f0102824:	57                   	push   %edi
f0102825:	ff 35 08 e1 17 f0    	pushl  0xf017e108
f010282b:	e8 b1 e9 ff ff       	call   f01011e1 <page_insert>
	assert(pp1->pp_ref == 1);
f0102830:	83 c4 20             	add    $0x20,%esp
f0102833:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102838:	74 19                	je     f0102853 <mem_init+0x160a>
f010283a:	68 57 5a 10 f0       	push   $0xf0105a57
f010283f:	68 95 58 10 f0       	push   $0xf0105895
f0102844:	68 e5 03 00 00       	push   $0x3e5
f0102849:	68 5d 58 10 f0       	push   $0xf010585d
f010284e:	e8 4d d8 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102853:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f010285a:	01 01 01 
f010285d:	74 19                	je     f0102878 <mem_init+0x162f>
f010285f:	68 c0 57 10 f0       	push   $0xf01057c0
f0102864:	68 95 58 10 f0       	push   $0xf0105895
f0102869:	68 e6 03 00 00       	push   $0x3e6
f010286e:	68 5d 58 10 f0       	push   $0xf010585d
f0102873:	e8 28 d8 ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102878:	6a 02                	push   $0x2
f010287a:	68 00 10 00 00       	push   $0x1000
f010287f:	56                   	push   %esi
f0102880:	ff 35 08 e1 17 f0    	pushl  0xf017e108
f0102886:	e8 56 e9 ff ff       	call   f01011e1 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010288b:	83 c4 10             	add    $0x10,%esp
f010288e:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102895:	02 02 02 
f0102898:	74 19                	je     f01028b3 <mem_init+0x166a>
f010289a:	68 e4 57 10 f0       	push   $0xf01057e4
f010289f:	68 95 58 10 f0       	push   $0xf0105895
f01028a4:	68 e8 03 00 00       	push   $0x3e8
f01028a9:	68 5d 58 10 f0       	push   $0xf010585d
f01028ae:	e8 ed d7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01028b3:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01028b8:	74 19                	je     f01028d3 <mem_init+0x168a>
f01028ba:	68 79 5a 10 f0       	push   $0xf0105a79
f01028bf:	68 95 58 10 f0       	push   $0xf0105895
f01028c4:	68 e9 03 00 00       	push   $0x3e9
f01028c9:	68 5d 58 10 f0       	push   $0xf010585d
f01028ce:	e8 cd d7 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f01028d3:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01028d8:	74 19                	je     f01028f3 <mem_init+0x16aa>
f01028da:	68 e3 5a 10 f0       	push   $0xf0105ae3
f01028df:	68 95 58 10 f0       	push   $0xf0105895
f01028e4:	68 ea 03 00 00       	push   $0x3ea
f01028e9:	68 5d 58 10 f0       	push   $0xf010585d
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
f01028ff:	2b 05 0c e1 17 f0    	sub    0xf017e10c,%eax
f0102905:	c1 f8 03             	sar    $0x3,%eax
f0102908:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010290b:	89 c2                	mov    %eax,%edx
f010290d:	c1 ea 0c             	shr    $0xc,%edx
f0102910:	3b 15 04 e1 17 f0    	cmp    0xf017e104,%edx
f0102916:	72 12                	jb     f010292a <mem_init+0x16e1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102918:	50                   	push   %eax
f0102919:	68 08 50 10 f0       	push   $0xf0105008
f010291e:	6a 56                	push   $0x56
f0102920:	68 7b 58 10 f0       	push   $0xf010587b
f0102925:	e8 76 d7 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f010292a:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102931:	03 03 03 
f0102934:	74 19                	je     f010294f <mem_init+0x1706>
f0102936:	68 08 58 10 f0       	push   $0xf0105808
f010293b:	68 95 58 10 f0       	push   $0xf0105895
f0102940:	68 ec 03 00 00       	push   $0x3ec
f0102945:	68 5d 58 10 f0       	push   $0xf010585d
f010294a:	e8 51 d7 ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f010294f:	83 ec 08             	sub    $0x8,%esp
f0102952:	68 00 10 00 00       	push   $0x1000
f0102957:	ff 35 08 e1 17 f0    	pushl  0xf017e108
f010295d:	e8 35 e8 ff ff       	call   f0101197 <page_remove>
	assert(pp2->pp_ref == 0);
f0102962:	83 c4 10             	add    $0x10,%esp
f0102965:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010296a:	74 19                	je     f0102985 <mem_init+0x173c>
f010296c:	68 b1 5a 10 f0       	push   $0xf0105ab1
f0102971:	68 95 58 10 f0       	push   $0xf0105895
f0102976:	68 ee 03 00 00       	push   $0x3ee
f010297b:	68 5d 58 10 f0       	push   $0xf010585d
f0102980:	e8 1b d7 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102985:	8b 0d 08 e1 17 f0    	mov    0xf017e108,%ecx
f010298b:	8b 11                	mov    (%ecx),%edx
f010298d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102993:	89 d8                	mov    %ebx,%eax
f0102995:	2b 05 0c e1 17 f0    	sub    0xf017e10c,%eax
f010299b:	c1 f8 03             	sar    $0x3,%eax
f010299e:	c1 e0 0c             	shl    $0xc,%eax
f01029a1:	39 c2                	cmp    %eax,%edx
f01029a3:	74 19                	je     f01029be <mem_init+0x1775>
f01029a5:	68 18 53 10 f0       	push   $0xf0105318
f01029aa:	68 95 58 10 f0       	push   $0xf0105895
f01029af:	68 f1 03 00 00       	push   $0x3f1
f01029b4:	68 5d 58 10 f0       	push   $0xf010585d
f01029b9:	e8 e2 d6 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f01029be:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01029c4:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01029c9:	74 19                	je     f01029e4 <mem_init+0x179b>
f01029cb:	68 68 5a 10 f0       	push   $0xf0105a68
f01029d0:	68 95 58 10 f0       	push   $0xf0105895
f01029d5:	68 f3 03 00 00       	push   $0x3f3
f01029da:	68 5d 58 10 f0       	push   $0xf010585d
f01029df:	e8 bc d6 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f01029e4:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01029ea:	83 ec 0c             	sub    $0xc,%esp
f01029ed:	53                   	push   %ebx
f01029ee:	e8 cc e5 ff ff       	call   f0100fbf <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01029f3:	c7 04 24 34 58 10 f0 	movl   $0xf0105834,(%esp)
f01029fa:	e8 16 07 00 00       	call   f0103115 <cprintf>
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
	// LAB 3: Your code here.

	return 0;
}
f0102a18:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a1d:	5d                   	pop    %ebp
f0102a1e:	c3                   	ret    

f0102a1f <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102a1f:	55                   	push   %ebp
f0102a20:	89 e5                	mov    %esp,%ebp
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
		cprintf("[%08x] user_mem_check assertion failure for "
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
	}
}
f0102a22:	5d                   	pop    %ebp
f0102a23:	c3                   	ret    

f0102a24 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102a24:	55                   	push   %ebp
f0102a25:	89 e5                	mov    %esp,%ebp
f0102a27:	57                   	push   %edi
f0102a28:	56                   	push   %esi
f0102a29:	53                   	push   %ebx
f0102a2a:	83 ec 0c             	sub    $0xc,%esp
f0102a2d:	89 c7                	mov    %eax,%edi
	// LAB 3: Your code here.
	// (But only if you need it for load_icode.)
	//
	void *begin = ROUNDDOWN(va, PGSIZE), *end = ROUNDUP(va+len, PGSIZE);
f0102a2f:	89 d3                	mov    %edx,%ebx
f0102a31:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0102a37:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102a3e:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	for (; begin < end; begin += PGSIZE) {
f0102a44:	eb 3d                	jmp    f0102a83 <region_alloc+0x5f>
		struct PageInfo *pg = page_alloc(0);
f0102a46:	83 ec 0c             	sub    $0xc,%esp
f0102a49:	6a 00                	push   $0x0
f0102a4b:	e8 ff e4 ff ff       	call   f0100f4f <page_alloc>
		if (!pg) panic("region_alloc failed!");
f0102a50:	83 c4 10             	add    $0x10,%esp
f0102a53:	85 c0                	test   %eax,%eax
f0102a55:	75 17                	jne    f0102a6e <region_alloc+0x4a>
f0102a57:	83 ec 04             	sub    $0x4,%esp
f0102a5a:	68 6c 5b 10 f0       	push   $0xf0105b6c
f0102a5f:	68 20 01 00 00       	push   $0x120
f0102a64:	68 81 5b 10 f0       	push   $0xf0105b81
f0102a69:	e8 32 d6 ff ff       	call   f01000a0 <_panic>
		page_insert(e->env_pgdir, pg, begin, PTE_W | PTE_U);
f0102a6e:	6a 06                	push   $0x6
f0102a70:	53                   	push   %ebx
f0102a71:	50                   	push   %eax
f0102a72:	ff 77 5c             	pushl  0x5c(%edi)
f0102a75:	e8 67 e7 ff ff       	call   f01011e1 <page_insert>
{
	// LAB 3: Your code here.
	// (But only if you need it for load_icode.)
	//
	void *begin = ROUNDDOWN(va, PGSIZE), *end = ROUNDUP(va+len, PGSIZE);
	for (; begin < end; begin += PGSIZE) {
f0102a7a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102a80:	83 c4 10             	add    $0x10,%esp
f0102a83:	39 f3                	cmp    %esi,%ebx
f0102a85:	72 bf                	jb     f0102a46 <region_alloc+0x22>

	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
}
f0102a87:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a8a:	5b                   	pop    %ebx
f0102a8b:	5e                   	pop    %esi
f0102a8c:	5f                   	pop    %edi
f0102a8d:	5d                   	pop    %ebp
f0102a8e:	c3                   	ret    

f0102a8f <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102a8f:	55                   	push   %ebp
f0102a90:	89 e5                	mov    %esp,%ebp
f0102a92:	8b 55 08             	mov    0x8(%ebp),%edx
f0102a95:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102a98:	85 d2                	test   %edx,%edx
f0102a9a:	75 11                	jne    f0102aad <envid2env+0x1e>
		*env_store = curenv;
f0102a9c:	a1 24 d4 17 f0       	mov    0xf017d424,%eax
f0102aa1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102aa4:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102aa6:	b8 00 00 00 00       	mov    $0x0,%eax
f0102aab:	eb 5e                	jmp    f0102b0b <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102aad:	89 d0                	mov    %edx,%eax
f0102aaf:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102ab4:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102ab7:	c1 e0 05             	shl    $0x5,%eax
f0102aba:	03 05 28 d4 17 f0    	add    0xf017d428,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102ac0:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0102ac4:	74 05                	je     f0102acb <envid2env+0x3c>
f0102ac6:	39 50 48             	cmp    %edx,0x48(%eax)
f0102ac9:	74 10                	je     f0102adb <envid2env+0x4c>
		*env_store = 0;
f0102acb:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ace:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102ad4:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102ad9:	eb 30                	jmp    f0102b0b <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102adb:	84 c9                	test   %cl,%cl
f0102add:	74 22                	je     f0102b01 <envid2env+0x72>
f0102adf:	8b 15 24 d4 17 f0    	mov    0xf017d424,%edx
f0102ae5:	39 d0                	cmp    %edx,%eax
f0102ae7:	74 18                	je     f0102b01 <envid2env+0x72>
f0102ae9:	8b 4a 48             	mov    0x48(%edx),%ecx
f0102aec:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f0102aef:	74 10                	je     f0102b01 <envid2env+0x72>
		*env_store = 0;
f0102af1:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102af4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102afa:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102aff:	eb 0a                	jmp    f0102b0b <envid2env+0x7c>
	}

	*env_store = e;
f0102b01:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102b04:	89 01                	mov    %eax,(%ecx)
	return 0;
f0102b06:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102b0b:	5d                   	pop    %ebp
f0102b0c:	c3                   	ret    

f0102b0d <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102b0d:	55                   	push   %ebp
f0102b0e:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0102b10:	b8 00 b3 11 f0       	mov    $0xf011b300,%eax
f0102b15:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0102b18:	b8 23 00 00 00       	mov    $0x23,%eax
f0102b1d:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0102b1f:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0102b21:	b0 10                	mov    $0x10,%al
f0102b23:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0102b25:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0102b27:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f0102b29:	ea 30 2b 10 f0 08 00 	ljmp   $0x8,$0xf0102b30
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0102b30:	b0 00                	mov    $0x0,%al
f0102b32:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102b35:	5d                   	pop    %ebp
f0102b36:	c3                   	ret    

f0102b37 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102b37:	55                   	push   %ebp
f0102b38:	89 e5                	mov    %esp,%ebp
f0102b3a:	56                   	push   %esi
f0102b3b:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i = NENV - 1; i >= 0; --i){
		envs[i].env_id = 0;
f0102b3c:	8b 35 28 d4 17 f0    	mov    0xf017d428,%esi
f0102b42:	8b 15 2c d4 17 f0    	mov    0xf017d42c,%edx
f0102b48:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f0102b4e:	8d 5e a0             	lea    -0x60(%esi),%ebx
f0102b51:	89 c1                	mov    %eax,%ecx
f0102b53:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
//		envs[i].env_runs = 0;
//		envs[i].env_type = ENV_TYPE_USER;
//		envs[i].env_status = ENV_FREE;
		envs[i].env_link = env_free_list;
f0102b5a:	89 50 44             	mov    %edx,0x44(%eax)
f0102b5d:	83 e8 60             	sub    $0x60,%eax
		env_free_list = envs + i;
f0102b60:	89 ca                	mov    %ecx,%edx
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i = NENV - 1; i >= 0; --i){
f0102b62:	39 d8                	cmp    %ebx,%eax
f0102b64:	75 eb                	jne    f0102b51 <env_init+0x1a>
f0102b66:	89 35 2c d4 17 f0    	mov    %esi,0xf017d42c
		envs[i].env_link = env_free_list;
		env_free_list = envs + i;
	}

	// Per-CPU part of the initialization
	env_init_percpu();
f0102b6c:	e8 9c ff ff ff       	call   f0102b0d <env_init_percpu>
}
f0102b71:	5b                   	pop    %ebx
f0102b72:	5e                   	pop    %esi
f0102b73:	5d                   	pop    %ebp
f0102b74:	c3                   	ret    

f0102b75 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102b75:	55                   	push   %ebp
f0102b76:	89 e5                	mov    %esp,%ebp
f0102b78:	53                   	push   %ebx
f0102b79:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102b7c:	8b 1d 2c d4 17 f0    	mov    0xf017d42c,%ebx
f0102b82:	85 db                	test   %ebx,%ebx
f0102b84:	0f 84 43 01 00 00    	je     f0102ccd <env_alloc+0x158>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102b8a:	83 ec 0c             	sub    $0xc,%esp
f0102b8d:	6a 01                	push   $0x1
f0102b8f:	e8 bb e3 ff ff       	call   f0100f4f <page_alloc>
f0102b94:	83 c4 10             	add    $0x10,%esp
f0102b97:	85 c0                	test   %eax,%eax
f0102b99:	0f 84 35 01 00 00    	je     f0102cd4 <env_alloc+0x15f>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f0102b9f:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
f0102ba4:	2b 05 0c e1 17 f0    	sub    0xf017e10c,%eax
f0102baa:	c1 f8 03             	sar    $0x3,%eax
f0102bad:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bb0:	89 c2                	mov    %eax,%edx
f0102bb2:	c1 ea 0c             	shr    $0xc,%edx
f0102bb5:	3b 15 04 e1 17 f0    	cmp    0xf017e104,%edx
f0102bbb:	72 12                	jb     f0102bcf <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bbd:	50                   	push   %eax
f0102bbe:	68 08 50 10 f0       	push   $0xf0105008
f0102bc3:	6a 56                	push   $0x56
f0102bc5:	68 7b 58 10 f0       	push   $0xf010587b
f0102bca:	e8 d1 d4 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0102bcf:	2d 00 00 00 10       	sub    $0x10000000,%eax
	e->env_pgdir = (pde_t *) page2kva(p);
f0102bd4:	89 43 5c             	mov    %eax,0x5c(%ebx)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f0102bd7:	83 ec 04             	sub    $0x4,%esp
f0102bda:	68 00 10 00 00       	push   $0x1000
f0102bdf:	ff 35 08 e1 17 f0    	pushl  0xf017e108
f0102be5:	50                   	push   %eax
f0102be6:	e8 34 18 00 00       	call   f010441f <memcpy>

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102beb:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102bee:	83 c4 10             	add    $0x10,%esp
f0102bf1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102bf6:	77 15                	ja     f0102c0d <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102bf8:	50                   	push   %eax
f0102bf9:	68 2c 50 10 f0       	push   $0xf010502c
f0102bfe:	68 c5 00 00 00       	push   $0xc5
f0102c03:	68 81 5b 10 f0       	push   $0xf0105b81
f0102c08:	e8 93 d4 ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102c0d:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102c13:	83 ca 05             	or     $0x5,%edx
f0102c16:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102c1c:	8b 43 48             	mov    0x48(%ebx),%eax
f0102c1f:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102c24:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102c29:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102c2e:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102c31:	89 da                	mov    %ebx,%edx
f0102c33:	2b 15 28 d4 17 f0    	sub    0xf017d428,%edx
f0102c39:	c1 fa 05             	sar    $0x5,%edx
f0102c3c:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102c42:	09 d0                	or     %edx,%eax
f0102c44:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102c47:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102c4a:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102c4d:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102c54:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102c5b:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102c62:	83 ec 04             	sub    $0x4,%esp
f0102c65:	6a 44                	push   $0x44
f0102c67:	6a 00                	push   $0x0
f0102c69:	53                   	push   %ebx
f0102c6a:	e8 fb 16 00 00       	call   f010436a <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102c6f:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102c75:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102c7b:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102c81:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102c88:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102c8e:	8b 43 44             	mov    0x44(%ebx),%eax
f0102c91:	a3 2c d4 17 f0       	mov    %eax,0xf017d42c
	*newenv_store = e;
f0102c96:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c99:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102c9b:	8b 53 48             	mov    0x48(%ebx),%edx
f0102c9e:	a1 24 d4 17 f0       	mov    0xf017d424,%eax
f0102ca3:	83 c4 10             	add    $0x10,%esp
f0102ca6:	85 c0                	test   %eax,%eax
f0102ca8:	74 05                	je     f0102caf <env_alloc+0x13a>
f0102caa:	8b 40 48             	mov    0x48(%eax),%eax
f0102cad:	eb 05                	jmp    f0102cb4 <env_alloc+0x13f>
f0102caf:	b8 00 00 00 00       	mov    $0x0,%eax
f0102cb4:	83 ec 04             	sub    $0x4,%esp
f0102cb7:	52                   	push   %edx
f0102cb8:	50                   	push   %eax
f0102cb9:	68 8c 5b 10 f0       	push   $0xf0105b8c
f0102cbe:	e8 52 04 00 00       	call   f0103115 <cprintf>
	return 0;
f0102cc3:	83 c4 10             	add    $0x10,%esp
f0102cc6:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ccb:	eb 0c                	jmp    f0102cd9 <env_alloc+0x164>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102ccd:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102cd2:	eb 05                	jmp    f0102cd9 <env_alloc+0x164>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102cd4:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102cd9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102cdc:	c9                   	leave  
f0102cdd:	c3                   	ret    

f0102cde <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102cde:	55                   	push   %ebp
f0102cdf:	89 e5                	mov    %esp,%ebp
f0102ce1:	57                   	push   %edi
f0102ce2:	56                   	push   %esi
f0102ce3:	53                   	push   %ebx
f0102ce4:	83 ec 34             	sub    $0x34,%esp
f0102ce7:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env* env;
	int ret = env_alloc(&env, 0);
f0102cea:	6a 00                	push   $0x0
f0102cec:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102cef:	50                   	push   %eax
f0102cf0:	e8 80 fe ff ff       	call   f0102b75 <env_alloc>
	if(ret != 0){
f0102cf5:	83 c4 10             	add    $0x10,%esp
f0102cf8:	85 c0                	test   %eax,%eax
f0102cfa:	74 17                	je     f0102d13 <env_create+0x35>
		panic("Env_create: allocate a new env failed!\n");
f0102cfc:	83 ec 04             	sub    $0x4,%esp
f0102cff:	68 08 5c 10 f0       	push   $0xf0105c08
f0102d04:	68 b7 01 00 00       	push   $0x1b7
f0102d09:	68 81 5b 10 f0       	push   $0xf0105b81
f0102d0e:	e8 8d d3 ff ff       	call   f01000a0 <_panic>
	}
	load_icode(env, binary);
f0102d13:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102d16:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// LAB 3: Your code here.
	struct Elf *ELFHDR = (struct Elf *) binary;
	struct Proghdr *ph, *eph;

	if (ELFHDR->e_magic != ELF_MAGIC)
f0102d19:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102d1f:	74 17                	je     f0102d38 <env_create+0x5a>
		panic("Not executable!");
f0102d21:	83 ec 04             	sub    $0x4,%esp
f0102d24:	68 a1 5b 10 f0       	push   $0xf0105ba1
f0102d29:	68 6d 01 00 00       	push   $0x16d
f0102d2e:	68 81 5b 10 f0       	push   $0xf0105b81
f0102d33:	e8 68 d3 ff ff       	call   f01000a0 <_panic>
	
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
f0102d38:	89 fb                	mov    %edi,%ebx
f0102d3a:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + ELFHDR->e_phnum;
f0102d3d:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0102d41:	c1 e6 05             	shl    $0x5,%esi
f0102d44:	01 de                	add    %ebx,%esi
	//  The ph->p_filesz bytes from the ELF binary, starting at
	//  'binary + ph->p_offset', should be copied to virtual address
	//  ph->p_va.  Any remaining memory bytes should be cleared to zero.
	//  (The ELF header should have ph->p_filesz <= ph->p_memsz.)
	//  Use functions from the previous lab to allocate and map pages.
	lcr3(PADDR(e->env_pgdir));
f0102d46:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d49:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d4c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d51:	77 15                	ja     f0102d68 <env_create+0x8a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d53:	50                   	push   %eax
f0102d54:	68 2c 50 10 f0       	push   $0xf010502c
f0102d59:	68 79 01 00 00       	push   $0x179
f0102d5e:	68 81 5b 10 f0       	push   $0xf0105b81
f0102d63:	e8 38 d3 ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102d68:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102d6d:	0f 22 d8             	mov    %eax,%cr3
f0102d70:	eb 50                	jmp    f0102dc2 <env_create+0xe4>
	//it's silly to use kern_pgdir here.
	for (; ph < eph; ph++)
		if (ph->p_type == ELF_PROG_LOAD) {
f0102d72:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102d75:	75 48                	jne    f0102dbf <env_create+0xe1>
			region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f0102d77:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102d7a:	8b 53 08             	mov    0x8(%ebx),%edx
f0102d7d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d80:	e8 9f fc ff ff       	call   f0102a24 <region_alloc>
			memset((void *)ph->p_va, 0, ph->p_memsz);
f0102d85:	83 ec 04             	sub    $0x4,%esp
f0102d88:	ff 73 14             	pushl  0x14(%ebx)
f0102d8b:	6a 00                	push   $0x0
f0102d8d:	ff 73 08             	pushl  0x8(%ebx)
f0102d90:	e8 d5 15 00 00       	call   f010436a <memset>
			memcpy((void *)ph->p_va, binary+ph->p_offset, ph->p_filesz);
f0102d95:	83 c4 0c             	add    $0xc,%esp
f0102d98:	ff 73 10             	pushl  0x10(%ebx)
f0102d9b:	89 f8                	mov    %edi,%eax
f0102d9d:	03 43 04             	add    0x4(%ebx),%eax
f0102da0:	50                   	push   %eax
f0102da1:	ff 73 08             	pushl  0x8(%ebx)
f0102da4:	e8 76 16 00 00       	call   f010441f <memcpy>
			//but I'm curious about how exactly p_memsz and p_filesz differs
			cprintf("p_memsz: %x, p_filesz: %x\n", ph->p_memsz, ph->p_filesz);
f0102da9:	83 c4 0c             	add    $0xc,%esp
f0102dac:	ff 73 10             	pushl  0x10(%ebx)
f0102daf:	ff 73 14             	pushl  0x14(%ebx)
f0102db2:	68 b1 5b 10 f0       	push   $0xf0105bb1
f0102db7:	e8 59 03 00 00       	call   f0103115 <cprintf>
f0102dbc:	83 c4 10             	add    $0x10,%esp
	//  ph->p_va.  Any remaining memory bytes should be cleared to zero.
	//  (The ELF header should have ph->p_filesz <= ph->p_memsz.)
	//  Use functions from the previous lab to allocate and map pages.
	lcr3(PADDR(e->env_pgdir));
	//it's silly to use kern_pgdir here.
	for (; ph < eph; ph++)
f0102dbf:	83 c3 20             	add    $0x20,%ebx
f0102dc2:	39 de                	cmp    %ebx,%esi
f0102dc4:	77 ac                	ja     f0102d72 <env_create+0x94>
			memcpy((void *)ph->p_va, binary+ph->p_offset, ph->p_filesz);
			//but I'm curious about how exactly p_memsz and p_filesz differs
			cprintf("p_memsz: %x, p_filesz: %x\n", ph->p_memsz, ph->p_filesz);
		}
	//we can use this because kern_pgdir is a subset of e->env_pgdir
	lcr3(PADDR(kern_pgdir));
f0102dc6:	a1 08 e1 17 f0       	mov    0xf017e108,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102dcb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102dd0:	77 15                	ja     f0102de7 <env_create+0x109>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102dd2:	50                   	push   %eax
f0102dd3:	68 2c 50 10 f0       	push   $0xf010502c
f0102dd8:	68 84 01 00 00       	push   $0x184
f0102ddd:	68 81 5b 10 f0       	push   $0xf0105b81
f0102de2:	e8 b9 d2 ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102de7:	05 00 00 00 10       	add    $0x10000000,%eax
f0102dec:	0f 22 d8             	mov    %eax,%cr3
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.
	// LAB 3: Your code here.
	e->env_tf.tf_eip = ELFHDR->e_entry;
f0102def:	8b 47 18             	mov    0x18(%edi),%eax
f0102df2:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102df5:	89 47 30             	mov    %eax,0x30(%edi)
	region_alloc(e, (void *) (USTACKTOP - PGSIZE), PGSIZE);
f0102df8:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102dfd:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102e02:	89 f8                	mov    %edi,%eax
f0102e04:	e8 1b fc ff ff       	call   f0102a24 <region_alloc>
	int ret = env_alloc(&env, 0);
	if(ret != 0){
		panic("Env_create: allocate a new env failed!\n");
	}
	load_icode(env, binary);
	cprintf("env_create: finished!\n");
f0102e09:	83 ec 0c             	sub    $0xc,%esp
f0102e0c:	68 cc 5b 10 f0       	push   $0xf0105bcc
f0102e11:	e8 ff 02 00 00       	call   f0103115 <cprintf>
	env->env_type = ENV_TYPE_USER;	
f0102e16:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102e19:	c7 40 50 00 00 00 00 	movl   $0x0,0x50(%eax)
	env->env_parent_id = 0;
f0102e20:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
f0102e27:	83 c4 10             	add    $0x10,%esp
}
f0102e2a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e2d:	5b                   	pop    %ebx
f0102e2e:	5e                   	pop    %esi
f0102e2f:	5f                   	pop    %edi
f0102e30:	5d                   	pop    %ebp
f0102e31:	c3                   	ret    

f0102e32 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102e32:	55                   	push   %ebp
f0102e33:	89 e5                	mov    %esp,%ebp
f0102e35:	57                   	push   %edi
f0102e36:	56                   	push   %esi
f0102e37:	53                   	push   %ebx
f0102e38:	83 ec 1c             	sub    $0x1c,%esp
f0102e3b:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102e3e:	8b 15 24 d4 17 f0    	mov    0xf017d424,%edx
f0102e44:	39 d7                	cmp    %edx,%edi
f0102e46:	75 29                	jne    f0102e71 <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102e48:	a1 08 e1 17 f0       	mov    0xf017e108,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e4d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102e52:	77 15                	ja     f0102e69 <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e54:	50                   	push   %eax
f0102e55:	68 2c 50 10 f0       	push   $0xf010502c
f0102e5a:	68 cd 01 00 00       	push   $0x1cd
f0102e5f:	68 81 5b 10 f0       	push   $0xf0105b81
f0102e64:	e8 37 d2 ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102e69:	05 00 00 00 10       	add    $0x10000000,%eax
f0102e6e:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102e71:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102e74:	85 d2                	test   %edx,%edx
f0102e76:	74 05                	je     f0102e7d <env_free+0x4b>
f0102e78:	8b 42 48             	mov    0x48(%edx),%eax
f0102e7b:	eb 05                	jmp    f0102e82 <env_free+0x50>
f0102e7d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e82:	83 ec 04             	sub    $0x4,%esp
f0102e85:	51                   	push   %ecx
f0102e86:	50                   	push   %eax
f0102e87:	68 e3 5b 10 f0       	push   $0xf0105be3
f0102e8c:	e8 84 02 00 00       	call   f0103115 <cprintf>
f0102e91:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102e94:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102e9b:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102e9e:	89 d0                	mov    %edx,%eax
f0102ea0:	c1 e0 02             	shl    $0x2,%eax
f0102ea3:	89 45 d8             	mov    %eax,-0x28(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102ea6:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102ea9:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102eac:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102eb2:	0f 84 a8 00 00 00    	je     f0102f60 <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102eb8:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ebe:	89 f0                	mov    %esi,%eax
f0102ec0:	c1 e8 0c             	shr    $0xc,%eax
f0102ec3:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0102ec6:	3b 05 04 e1 17 f0    	cmp    0xf017e104,%eax
f0102ecc:	72 15                	jb     f0102ee3 <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ece:	56                   	push   %esi
f0102ecf:	68 08 50 10 f0       	push   $0xf0105008
f0102ed4:	68 dc 01 00 00       	push   $0x1dc
f0102ed9:	68 81 5b 10 f0       	push   $0xf0105b81
f0102ede:	e8 bd d1 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102ee3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102ee6:	c1 e0 16             	shl    $0x16,%eax
f0102ee9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102eec:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102ef1:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102ef8:	01 
f0102ef9:	74 17                	je     f0102f12 <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102efb:	83 ec 08             	sub    $0x8,%esp
f0102efe:	89 d8                	mov    %ebx,%eax
f0102f00:	c1 e0 0c             	shl    $0xc,%eax
f0102f03:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102f06:	50                   	push   %eax
f0102f07:	ff 77 5c             	pushl  0x5c(%edi)
f0102f0a:	e8 88 e2 ff ff       	call   f0101197 <page_remove>
f0102f0f:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102f12:	83 c3 01             	add    $0x1,%ebx
f0102f15:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102f1b:	75 d4                	jne    f0102ef1 <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102f1d:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102f20:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102f23:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102f2a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102f2d:	3b 05 04 e1 17 f0    	cmp    0xf017e104,%eax
f0102f33:	72 14                	jb     f0102f49 <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102f35:	83 ec 04             	sub    $0x4,%esp
f0102f38:	68 74 51 10 f0       	push   $0xf0105174
f0102f3d:	6a 4f                	push   $0x4f
f0102f3f:	68 7b 58 10 f0       	push   $0xf010587b
f0102f44:	e8 57 d1 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102f49:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0102f4c:	a1 0c e1 17 f0       	mov    0xf017e10c,%eax
f0102f51:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102f54:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102f57:	50                   	push   %eax
f0102f58:	e8 a3 e0 ff ff       	call   f0101000 <page_decref>
f0102f5d:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102f60:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102f64:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102f67:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102f6c:	0f 85 29 ff ff ff    	jne    f0102e9b <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102f72:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f75:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102f7a:	77 15                	ja     f0102f91 <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f7c:	50                   	push   %eax
f0102f7d:	68 2c 50 10 f0       	push   $0xf010502c
f0102f82:	68 ea 01 00 00       	push   $0x1ea
f0102f87:	68 81 5b 10 f0       	push   $0xf0105b81
f0102f8c:	e8 0f d1 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102f91:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	return (physaddr_t)kva - KERNBASE;
f0102f98:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102f9d:	c1 e8 0c             	shr    $0xc,%eax
f0102fa0:	3b 05 04 e1 17 f0    	cmp    0xf017e104,%eax
f0102fa6:	72 14                	jb     f0102fbc <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102fa8:	83 ec 04             	sub    $0x4,%esp
f0102fab:	68 74 51 10 f0       	push   $0xf0105174
f0102fb0:	6a 4f                	push   $0x4f
f0102fb2:	68 7b 58 10 f0       	push   $0xf010587b
f0102fb7:	e8 e4 d0 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102fbc:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0102fbf:	8b 15 0c e1 17 f0    	mov    0xf017e10c,%edx
f0102fc5:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102fc8:	50                   	push   %eax
f0102fc9:	e8 32 e0 ff ff       	call   f0101000 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102fce:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102fd5:	a1 2c d4 17 f0       	mov    0xf017d42c,%eax
f0102fda:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102fdd:	89 3d 2c d4 17 f0    	mov    %edi,0xf017d42c
f0102fe3:	83 c4 10             	add    $0x10,%esp
}
f0102fe6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102fe9:	5b                   	pop    %ebx
f0102fea:	5e                   	pop    %esi
f0102feb:	5f                   	pop    %edi
f0102fec:	5d                   	pop    %ebp
f0102fed:	c3                   	ret    

f0102fee <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102fee:	55                   	push   %ebp
f0102fef:	89 e5                	mov    %esp,%ebp
f0102ff1:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102ff4:	ff 75 08             	pushl  0x8(%ebp)
f0102ff7:	e8 36 fe ff ff       	call   f0102e32 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102ffc:	c7 04 24 30 5c 10 f0 	movl   $0xf0105c30,(%esp)
f0103003:	e8 0d 01 00 00       	call   f0103115 <cprintf>
f0103008:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f010300b:	83 ec 0c             	sub    $0xc,%esp
f010300e:	6a 00                	push   $0x0
f0103010:	e8 7b d9 ff ff       	call   f0100990 <monitor>
f0103015:	83 c4 10             	add    $0x10,%esp
f0103018:	eb f1                	jmp    f010300b <env_destroy+0x1d>

f010301a <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f010301a:	55                   	push   %ebp
f010301b:	89 e5                	mov    %esp,%ebp
f010301d:	83 ec 0c             	sub    $0xc,%esp
	__asm __volatile("movl %0,%%esp\n"
f0103020:	8b 65 08             	mov    0x8(%ebp),%esp
f0103023:	61                   	popa   
f0103024:	07                   	pop    %es
f0103025:	1f                   	pop    %ds
f0103026:	83 c4 08             	add    $0x8,%esp
f0103029:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f010302a:	68 f9 5b 10 f0       	push   $0xf0105bf9
f010302f:	68 12 02 00 00       	push   $0x212
f0103034:	68 81 5b 10 f0       	push   $0xf0105b81
f0103039:	e8 62 d0 ff ff       	call   f01000a0 <_panic>

f010303e <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f010303e:	55                   	push   %ebp
f010303f:	89 e5                	mov    %esp,%ebp
f0103041:	83 ec 08             	sub    $0x8,%esp
f0103044:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(e != curenv){ //a context switch, since a new environment is running
f0103047:	8b 15 24 d4 17 f0    	mov    0xf017d424,%edx
f010304d:	39 d0                	cmp    %edx,%eax
f010304f:	74 48                	je     f0103099 <env_run+0x5b>
		if(curenv != NULL){
f0103051:	85 d2                	test   %edx,%edx
f0103053:	74 0d                	je     f0103062 <env_run+0x24>
			if(curenv->env_status == ENV_RUNNING) curenv->env_status = ENV_RUNNABLE;
f0103055:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0103059:	75 07                	jne    f0103062 <env_run+0x24>
f010305b:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
		}
		curenv = e;
f0103062:	a3 24 d4 17 f0       	mov    %eax,0xf017d424
		curenv->env_runs++;
f0103067:	83 40 58 01          	addl   $0x1,0x58(%eax)
		curenv->env_status = ENV_RUNNING;
f010306b:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
		lcr3(PADDR(curenv->env_pgdir));
f0103072:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103075:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010307a:	77 15                	ja     f0103091 <env_run+0x53>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010307c:	50                   	push   %eax
f010307d:	68 2c 50 10 f0       	push   $0xf010502c
f0103082:	68 37 02 00 00       	push   $0x237
f0103087:	68 81 5b 10 f0       	push   $0xf0105b81
f010308c:	e8 0f d0 ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103091:	05 00 00 00 10       	add    $0x10000000,%eax
f0103096:	0f 22 d8             	mov    %eax,%cr3
	}
	cprintf("up to now everything goes well!\n");
f0103099:	83 ec 0c             	sub    $0xc,%esp
f010309c:	68 68 5c 10 f0       	push   $0xf0105c68
f01030a1:	e8 6f 00 00 00       	call   f0103115 <cprintf>
	env_pop_tf(&curenv->env_tf);
f01030a6:	83 c4 04             	add    $0x4,%esp
f01030a9:	ff 35 24 d4 17 f0    	pushl  0xf017d424
f01030af:	e8 66 ff ff ff       	call   f010301a <env_pop_tf>

f01030b4 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01030b4:	55                   	push   %ebp
f01030b5:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01030b7:	ba 70 00 00 00       	mov    $0x70,%edx
f01030bc:	8b 45 08             	mov    0x8(%ebp),%eax
f01030bf:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01030c0:	b2 71                	mov    $0x71,%dl
f01030c2:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01030c3:	0f b6 c0             	movzbl %al,%eax
}
f01030c6:	5d                   	pop    %ebp
f01030c7:	c3                   	ret    

f01030c8 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01030c8:	55                   	push   %ebp
f01030c9:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01030cb:	ba 70 00 00 00       	mov    $0x70,%edx
f01030d0:	8b 45 08             	mov    0x8(%ebp),%eax
f01030d3:	ee                   	out    %al,(%dx)
f01030d4:	b2 71                	mov    $0x71,%dl
f01030d6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030d9:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01030da:	5d                   	pop    %ebp
f01030db:	c3                   	ret    

f01030dc <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01030dc:	55                   	push   %ebp
f01030dd:	89 e5                	mov    %esp,%ebp
f01030df:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01030e2:	ff 75 08             	pushl  0x8(%ebp)
f01030e5:	e8 0a d5 ff ff       	call   f01005f4 <cputchar>
f01030ea:	83 c4 10             	add    $0x10,%esp
	*cnt++;
}
f01030ed:	c9                   	leave  
f01030ee:	c3                   	ret    

f01030ef <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01030ef:	55                   	push   %ebp
f01030f0:	89 e5                	mov    %esp,%ebp
f01030f2:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01030f5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01030fc:	ff 75 0c             	pushl  0xc(%ebp)
f01030ff:	ff 75 08             	pushl  0x8(%ebp)
f0103102:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103105:	50                   	push   %eax
f0103106:	68 dc 30 10 f0       	push   $0xf01030dc
f010310b:	e8 15 09 00 00       	call   f0103a25 <vprintfmt>
	return cnt;
}
f0103110:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103113:	c9                   	leave  
f0103114:	c3                   	ret    

f0103115 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103115:	55                   	push   %ebp
f0103116:	89 e5                	mov    %esp,%ebp
f0103118:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010311b:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010311e:	50                   	push   %eax
f010311f:	ff 75 08             	pushl  0x8(%ebp)
f0103122:	e8 c8 ff ff ff       	call   f01030ef <vcprintf>
	va_end(ap);

	return cnt;
}
f0103127:	c9                   	leave  
f0103128:	c3                   	ret    

f0103129 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103129:	55                   	push   %ebp
f010312a:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f010312c:	b8 80 dc 17 f0       	mov    $0xf017dc80,%eax
f0103131:	c7 05 84 dc 17 f0 00 	movl   $0xf0000000,0xf017dc84
f0103138:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f010313b:	66 c7 05 88 dc 17 f0 	movw   $0x10,0xf017dc88
f0103142:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0103144:	66 c7 05 48 b3 11 f0 	movw   $0x67,0xf011b348
f010314b:	67 00 
f010314d:	66 a3 4a b3 11 f0    	mov    %ax,0xf011b34a
f0103153:	89 c2                	mov    %eax,%edx
f0103155:	c1 ea 10             	shr    $0x10,%edx
f0103158:	88 15 4c b3 11 f0    	mov    %dl,0xf011b34c
f010315e:	c6 05 4e b3 11 f0 40 	movb   $0x40,0xf011b34e
f0103165:	c1 e8 18             	shr    $0x18,%eax
f0103168:	a2 4f b3 11 f0       	mov    %al,0xf011b34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f010316d:	c6 05 4d b3 11 f0 89 	movb   $0x89,0xf011b34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f0103174:	b8 28 00 00 00       	mov    $0x28,%eax
f0103179:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f010317c:	b8 50 b3 11 f0       	mov    $0xf011b350,%eax
f0103181:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0103184:	5d                   	pop    %ebp
f0103185:	c3                   	ret    

f0103186 <trap_init>:
{
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	int i = 0;
	for(i = 0; i < 17; i++){
f0103186:	b8 00 00 00 00       	mov    $0x0,%eax
		SETGATE(idt[i], 0, GD_KT, thdl[i], 0);
f010318b:	8b 14 85 56 b3 11 f0 	mov    -0xfee4caa(,%eax,4),%edx
f0103192:	66 89 14 c5 40 d4 17 	mov    %dx,-0xfe82bc0(,%eax,8)
f0103199:	f0 
f010319a:	66 c7 04 c5 42 d4 17 	movw   $0x8,-0xfe82bbe(,%eax,8)
f01031a1:	f0 08 00 
f01031a4:	c6 04 c5 44 d4 17 f0 	movb   $0x0,-0xfe82bbc(,%eax,8)
f01031ab:	00 
f01031ac:	c6 04 c5 45 d4 17 f0 	movb   $0x8e,-0xfe82bbb(,%eax,8)
f01031b3:	8e 
f01031b4:	c1 ea 10             	shr    $0x10,%edx
f01031b7:	66 89 14 c5 46 d4 17 	mov    %dx,-0xfe82bba(,%eax,8)
f01031be:	f0 
{
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	int i = 0;
	for(i = 0; i < 17; i++){
f01031bf:	83 c0 01             	add    $0x1,%eax
f01031c2:	83 f8 11             	cmp    $0x11,%eax
f01031c5:	75 c4                	jne    f010318b <trap_init+0x5>
}

extern uint32_t thdl[];
void
trap_init(void)
{
f01031c7:	55                   	push   %ebp
f01031c8:	89 e5                	mov    %esp,%ebp
	for(i = 0; i < 17; i++){
		SETGATE(idt[i], 0, GD_KT, thdl[i], 0);
	}
	
	// Per-CPU setup 
	trap_init_percpu();
f01031ca:	e8 5a ff ff ff       	call   f0103129 <trap_init_percpu>
}
f01031cf:	5d                   	pop    %ebp
f01031d0:	c3                   	ret    

f01031d1 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01031d1:	55                   	push   %ebp
f01031d2:	89 e5                	mov    %esp,%ebp
f01031d4:	53                   	push   %ebx
f01031d5:	83 ec 0c             	sub    $0xc,%esp
f01031d8:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01031db:	ff 33                	pushl  (%ebx)
f01031dd:	68 89 5c 10 f0       	push   $0xf0105c89
f01031e2:	e8 2e ff ff ff       	call   f0103115 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01031e7:	83 c4 08             	add    $0x8,%esp
f01031ea:	ff 73 04             	pushl  0x4(%ebx)
f01031ed:	68 98 5c 10 f0       	push   $0xf0105c98
f01031f2:	e8 1e ff ff ff       	call   f0103115 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01031f7:	83 c4 08             	add    $0x8,%esp
f01031fa:	ff 73 08             	pushl  0x8(%ebx)
f01031fd:	68 a7 5c 10 f0       	push   $0xf0105ca7
f0103202:	e8 0e ff ff ff       	call   f0103115 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103207:	83 c4 08             	add    $0x8,%esp
f010320a:	ff 73 0c             	pushl  0xc(%ebx)
f010320d:	68 b6 5c 10 f0       	push   $0xf0105cb6
f0103212:	e8 fe fe ff ff       	call   f0103115 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103217:	83 c4 08             	add    $0x8,%esp
f010321a:	ff 73 10             	pushl  0x10(%ebx)
f010321d:	68 c5 5c 10 f0       	push   $0xf0105cc5
f0103222:	e8 ee fe ff ff       	call   f0103115 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103227:	83 c4 08             	add    $0x8,%esp
f010322a:	ff 73 14             	pushl  0x14(%ebx)
f010322d:	68 d4 5c 10 f0       	push   $0xf0105cd4
f0103232:	e8 de fe ff ff       	call   f0103115 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103237:	83 c4 08             	add    $0x8,%esp
f010323a:	ff 73 18             	pushl  0x18(%ebx)
f010323d:	68 e3 5c 10 f0       	push   $0xf0105ce3
f0103242:	e8 ce fe ff ff       	call   f0103115 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103247:	83 c4 08             	add    $0x8,%esp
f010324a:	ff 73 1c             	pushl  0x1c(%ebx)
f010324d:	68 f2 5c 10 f0       	push   $0xf0105cf2
f0103252:	e8 be fe ff ff       	call   f0103115 <cprintf>
f0103257:	83 c4 10             	add    $0x10,%esp
}
f010325a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010325d:	c9                   	leave  
f010325e:	c3                   	ret    

f010325f <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f010325f:	55                   	push   %ebp
f0103260:	89 e5                	mov    %esp,%ebp
f0103262:	56                   	push   %esi
f0103263:	53                   	push   %ebx
f0103264:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103267:	83 ec 08             	sub    $0x8,%esp
f010326a:	53                   	push   %ebx
f010326b:	68 28 5e 10 f0       	push   $0xf0105e28
f0103270:	e8 a0 fe ff ff       	call   f0103115 <cprintf>
	print_regs(&tf->tf_regs);
f0103275:	89 1c 24             	mov    %ebx,(%esp)
f0103278:	e8 54 ff ff ff       	call   f01031d1 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f010327d:	83 c4 08             	add    $0x8,%esp
f0103280:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103284:	50                   	push   %eax
f0103285:	68 43 5d 10 f0       	push   $0xf0105d43
f010328a:	e8 86 fe ff ff       	call   f0103115 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f010328f:	83 c4 08             	add    $0x8,%esp
f0103292:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103296:	50                   	push   %eax
f0103297:	68 56 5d 10 f0       	push   $0xf0105d56
f010329c:	e8 74 fe ff ff       	call   f0103115 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01032a1:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f01032a4:	83 c4 10             	add    $0x10,%esp
f01032a7:	83 f8 13             	cmp    $0x13,%eax
f01032aa:	77 09                	ja     f01032b5 <print_trapframe+0x56>
		return excnames[trapno];
f01032ac:	8b 14 85 00 60 10 f0 	mov    -0xfefa000(,%eax,4),%edx
f01032b3:	eb 10                	jmp    f01032c5 <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f01032b5:	83 f8 30             	cmp    $0x30,%eax
f01032b8:	b9 0d 5d 10 f0       	mov    $0xf0105d0d,%ecx
f01032bd:	ba 01 5d 10 f0       	mov    $0xf0105d01,%edx
f01032c2:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01032c5:	83 ec 04             	sub    $0x4,%esp
f01032c8:	52                   	push   %edx
f01032c9:	50                   	push   %eax
f01032ca:	68 69 5d 10 f0       	push   $0xf0105d69
f01032cf:	e8 41 fe ff ff       	call   f0103115 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01032d4:	83 c4 10             	add    $0x10,%esp
f01032d7:	3b 1d 40 dc 17 f0    	cmp    0xf017dc40,%ebx
f01032dd:	75 1a                	jne    f01032f9 <print_trapframe+0x9a>
f01032df:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01032e3:	75 14                	jne    f01032f9 <print_trapframe+0x9a>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f01032e5:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01032e8:	83 ec 08             	sub    $0x8,%esp
f01032eb:	50                   	push   %eax
f01032ec:	68 7b 5d 10 f0       	push   $0xf0105d7b
f01032f1:	e8 1f fe ff ff       	call   f0103115 <cprintf>
f01032f6:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f01032f9:	83 ec 08             	sub    $0x8,%esp
f01032fc:	ff 73 2c             	pushl  0x2c(%ebx)
f01032ff:	68 8a 5d 10 f0       	push   $0xf0105d8a
f0103304:	e8 0c fe ff ff       	call   f0103115 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103309:	83 c4 10             	add    $0x10,%esp
f010330c:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103310:	75 49                	jne    f010335b <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103312:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103315:	89 c2                	mov    %eax,%edx
f0103317:	83 e2 01             	and    $0x1,%edx
f010331a:	ba 27 5d 10 f0       	mov    $0xf0105d27,%edx
f010331f:	b9 1c 5d 10 f0       	mov    $0xf0105d1c,%ecx
f0103324:	0f 44 ca             	cmove  %edx,%ecx
f0103327:	89 c2                	mov    %eax,%edx
f0103329:	83 e2 02             	and    $0x2,%edx
f010332c:	ba 39 5d 10 f0       	mov    $0xf0105d39,%edx
f0103331:	be 33 5d 10 f0       	mov    $0xf0105d33,%esi
f0103336:	0f 45 d6             	cmovne %esi,%edx
f0103339:	83 e0 04             	and    $0x4,%eax
f010333c:	be 53 5e 10 f0       	mov    $0xf0105e53,%esi
f0103341:	b8 3e 5d 10 f0       	mov    $0xf0105d3e,%eax
f0103346:	0f 44 c6             	cmove  %esi,%eax
f0103349:	51                   	push   %ecx
f010334a:	52                   	push   %edx
f010334b:	50                   	push   %eax
f010334c:	68 98 5d 10 f0       	push   $0xf0105d98
f0103351:	e8 bf fd ff ff       	call   f0103115 <cprintf>
f0103356:	83 c4 10             	add    $0x10,%esp
f0103359:	eb 10                	jmp    f010336b <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f010335b:	83 ec 0c             	sub    $0xc,%esp
f010335e:	68 3a 5b 10 f0       	push   $0xf0105b3a
f0103363:	e8 ad fd ff ff       	call   f0103115 <cprintf>
f0103368:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f010336b:	83 ec 08             	sub    $0x8,%esp
f010336e:	ff 73 30             	pushl  0x30(%ebx)
f0103371:	68 a7 5d 10 f0       	push   $0xf0105da7
f0103376:	e8 9a fd ff ff       	call   f0103115 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f010337b:	83 c4 08             	add    $0x8,%esp
f010337e:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103382:	50                   	push   %eax
f0103383:	68 b6 5d 10 f0       	push   $0xf0105db6
f0103388:	e8 88 fd ff ff       	call   f0103115 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f010338d:	83 c4 08             	add    $0x8,%esp
f0103390:	ff 73 38             	pushl  0x38(%ebx)
f0103393:	68 c9 5d 10 f0       	push   $0xf0105dc9
f0103398:	e8 78 fd ff ff       	call   f0103115 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f010339d:	83 c4 10             	add    $0x10,%esp
f01033a0:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01033a4:	74 25                	je     f01033cb <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01033a6:	83 ec 08             	sub    $0x8,%esp
f01033a9:	ff 73 3c             	pushl  0x3c(%ebx)
f01033ac:	68 d8 5d 10 f0       	push   $0xf0105dd8
f01033b1:	e8 5f fd ff ff       	call   f0103115 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01033b6:	83 c4 08             	add    $0x8,%esp
f01033b9:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f01033bd:	50                   	push   %eax
f01033be:	68 e7 5d 10 f0       	push   $0xf0105de7
f01033c3:	e8 4d fd ff ff       	call   f0103115 <cprintf>
f01033c8:	83 c4 10             	add    $0x10,%esp
	}
}
f01033cb:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01033ce:	5b                   	pop    %ebx
f01033cf:	5e                   	pop    %esi
f01033d0:	5d                   	pop    %ebp
f01033d1:	c3                   	ret    

f01033d2 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f01033d2:	55                   	push   %ebp
f01033d3:	89 e5                	mov    %esp,%ebp
f01033d5:	57                   	push   %edi
f01033d6:	56                   	push   %esi
f01033d7:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f01033da:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f01033db:	9c                   	pushf  
f01033dc:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f01033dd:	f6 c4 02             	test   $0x2,%ah
f01033e0:	74 19                	je     f01033fb <trap+0x29>
f01033e2:	68 fa 5d 10 f0       	push   $0xf0105dfa
f01033e7:	68 95 58 10 f0       	push   $0xf0105895
f01033ec:	68 ab 00 00 00       	push   $0xab
f01033f1:	68 13 5e 10 f0       	push   $0xf0105e13
f01033f6:	e8 a5 cc ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f01033fb:	83 ec 08             	sub    $0x8,%esp
f01033fe:	56                   	push   %esi
f01033ff:	68 1f 5e 10 f0       	push   $0xf0105e1f
f0103404:	e8 0c fd ff ff       	call   f0103115 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103409:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f010340d:	83 e0 03             	and    $0x3,%eax
f0103410:	83 c4 10             	add    $0x10,%esp
f0103413:	66 83 f8 03          	cmp    $0x3,%ax
f0103417:	75 31                	jne    f010344a <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f0103419:	a1 24 d4 17 f0       	mov    0xf017d424,%eax
f010341e:	85 c0                	test   %eax,%eax
f0103420:	75 19                	jne    f010343b <trap+0x69>
f0103422:	68 3a 5e 10 f0       	push   $0xf0105e3a
f0103427:	68 95 58 10 f0       	push   $0xf0105895
f010342c:	68 b1 00 00 00       	push   $0xb1
f0103431:	68 13 5e 10 f0       	push   $0xf0105e13
f0103436:	e8 65 cc ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f010343b:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103440:	89 c7                	mov    %eax,%edi
f0103442:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103444:	8b 35 24 d4 17 f0    	mov    0xf017d424,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f010344a:	89 35 40 dc 17 f0    	mov    %esi,0xf017dc40
{
	// Handle processor exceptions.
	// LAB 3: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103450:	83 ec 0c             	sub    $0xc,%esp
f0103453:	56                   	push   %esi
f0103454:	e8 06 fe ff ff       	call   f010325f <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103459:	83 c4 10             	add    $0x10,%esp
f010345c:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103461:	75 17                	jne    f010347a <trap+0xa8>
		panic("unhandled trap in kernel");
f0103463:	83 ec 04             	sub    $0x4,%esp
f0103466:	68 41 5e 10 f0       	push   $0xf0105e41
f010346b:	68 9a 00 00 00       	push   $0x9a
f0103470:	68 13 5e 10 f0       	push   $0xf0105e13
f0103475:	e8 26 cc ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f010347a:	83 ec 0c             	sub    $0xc,%esp
f010347d:	ff 35 24 d4 17 f0    	pushl  0xf017d424
f0103483:	e8 66 fb ff ff       	call   f0102fee <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103488:	a1 24 d4 17 f0       	mov    0xf017d424,%eax
f010348d:	83 c4 10             	add    $0x10,%esp
f0103490:	85 c0                	test   %eax,%eax
f0103492:	74 06                	je     f010349a <trap+0xc8>
f0103494:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103498:	74 19                	je     f01034b3 <trap+0xe1>
f010349a:	68 a0 5f 10 f0       	push   $0xf0105fa0
f010349f:	68 95 58 10 f0       	push   $0xf0105895
f01034a4:	68 c3 00 00 00       	push   $0xc3
f01034a9:	68 13 5e 10 f0       	push   $0xf0105e13
f01034ae:	e8 ed cb ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f01034b3:	83 ec 0c             	sub    $0xc,%esp
f01034b6:	50                   	push   %eax
f01034b7:	e8 82 fb ff ff       	call   f010303e <env_run>

f01034bc <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f01034bc:	55                   	push   %ebp
f01034bd:	89 e5                	mov    %esp,%ebp
f01034bf:	53                   	push   %ebx
f01034c0:	83 ec 04             	sub    $0x4,%esp
f01034c3:	8b 5d 08             	mov    0x8(%ebp),%ebx

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f01034c6:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01034c9:	ff 73 30             	pushl  0x30(%ebx)
f01034cc:	50                   	push   %eax
f01034cd:	a1 24 d4 17 f0       	mov    0xf017d424,%eax
f01034d2:	ff 70 48             	pushl  0x48(%eax)
f01034d5:	68 cc 5f 10 f0       	push   $0xf0105fcc
f01034da:	e8 36 fc ff ff       	call   f0103115 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f01034df:	89 1c 24             	mov    %ebx,(%esp)
f01034e2:	e8 78 fd ff ff       	call   f010325f <print_trapframe>
	env_destroy(curenv);
f01034e7:	83 c4 04             	add    $0x4,%esp
f01034ea:	ff 35 24 d4 17 f0    	pushl  0xf017d424
f01034f0:	e8 f9 fa ff ff       	call   f0102fee <env_destroy>
f01034f5:	83 c4 10             	add    $0x10,%esp
}
f01034f8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01034fb:	c9                   	leave  
f01034fc:	c3                   	ret    
f01034fd:	90                   	nop

f01034fe <thdl0>:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER_NOEC(thdl0, T_DIVIDE)
f01034fe:	6a 00                	push   $0x0
f0103500:	6a 00                	push   $0x0
f0103502:	e9 94 00 00 00       	jmp    f010359b <_alltraps>
f0103507:	90                   	nop

f0103508 <thdl1>:
TRAPHANDLER_NOEC(thdl1, T_DEBUG)
f0103508:	6a 00                	push   $0x0
f010350a:	6a 01                	push   $0x1
f010350c:	e9 8a 00 00 00       	jmp    f010359b <_alltraps>
f0103511:	90                   	nop

f0103512 <thdl2>:
TRAPHANDLER_NOEC(thdl2, 2)
f0103512:	6a 00                	push   $0x0
f0103514:	6a 02                	push   $0x2
f0103516:	e9 80 00 00 00       	jmp    f010359b <_alltraps>
f010351b:	90                   	nop

f010351c <thdl3>:
TRAPHANDLER_NOEC(thdl3, T_BRKPT)
f010351c:	6a 00                	push   $0x0
f010351e:	6a 03                	push   $0x3
f0103520:	e9 76 00 00 00       	jmp    f010359b <_alltraps>
f0103525:	90                   	nop

f0103526 <thdl4>:
TRAPHANDLER_NOEC(thdl4, T_OFLOW)
f0103526:	6a 00                	push   $0x0
f0103528:	6a 04                	push   $0x4
f010352a:	e9 6c 00 00 00       	jmp    f010359b <_alltraps>
f010352f:	90                   	nop

f0103530 <thdl5>:
TRAPHANDLER_NOEC(thdl5, T_BOUND)
f0103530:	6a 00                	push   $0x0
f0103532:	6a 05                	push   $0x5
f0103534:	e9 62 00 00 00       	jmp    f010359b <_alltraps>
f0103539:	90                   	nop

f010353a <thdl6>:
TRAPHANDLER_NOEC(thdl6, T_ILLOP)
f010353a:	6a 00                	push   $0x0
f010353c:	6a 06                	push   $0x6
f010353e:	e9 58 00 00 00       	jmp    f010359b <_alltraps>
f0103543:	90                   	nop

f0103544 <thdl7>:
TRAPHANDLER_NOEC(thdl7, T_DEVICE)
f0103544:	6a 00                	push   $0x0
f0103546:	6a 07                	push   $0x7
f0103548:	e9 4e 00 00 00       	jmp    f010359b <_alltraps>
f010354d:	90                   	nop

f010354e <thdl8>:
TRAPHANDLER(thdl8, T_DBLFLT)
f010354e:	6a 08                	push   $0x8
f0103550:	e9 46 00 00 00       	jmp    f010359b <_alltraps>
f0103555:	90                   	nop

f0103556 <thdl9>:
TRAPHANDLER_NOEC(thdl9, 9)
f0103556:	6a 00                	push   $0x0
f0103558:	6a 09                	push   $0x9
f010355a:	e9 3c 00 00 00       	jmp    f010359b <_alltraps>
f010355f:	90                   	nop

f0103560 <thdl10>:
/*interrupt 9 will not be generated by recent processors so T_COPROC is not defined in inc/trap.h*/
TRAPHANDLER(thdl10, T_TSS)
f0103560:	6a 0a                	push   $0xa
f0103562:	e9 34 00 00 00       	jmp    f010359b <_alltraps>
f0103567:	90                   	nop

f0103568 <thdl11>:
TRAPHANDLER(thdl11, T_SEGNP)
f0103568:	6a 0b                	push   $0xb
f010356a:	e9 2c 00 00 00       	jmp    f010359b <_alltraps>
f010356f:	90                   	nop

f0103570 <thdl12>:
TRAPHANDLER(thdl12, T_STACK)
f0103570:	6a 0c                	push   $0xc
f0103572:	e9 24 00 00 00       	jmp    f010359b <_alltraps>
f0103577:	90                   	nop

f0103578 <thdl13>:
TRAPHANDLER(thdl13, T_GPFLT)
f0103578:	6a 0d                	push   $0xd
f010357a:	e9 1c 00 00 00       	jmp    f010359b <_alltraps>
f010357f:	90                   	nop

f0103580 <thdl14>:
TRAPHANDLER(thdl14, T_PGFLT)
f0103580:	6a 0e                	push   $0xe
f0103582:	e9 14 00 00 00       	jmp    f010359b <_alltraps>
f0103587:	90                   	nop

f0103588 <thdl15>:
TRAPHANDLER_NOEC(thdl15, 15) //reserved 
f0103588:	6a 00                	push   $0x0
f010358a:	6a 0f                	push   $0xf
f010358c:	e9 0a 00 00 00       	jmp    f010359b <_alltraps>
f0103591:	90                   	nop

f0103592 <thdl16>:
TRAPHANDLER_NOEC(thdl16,16)
f0103592:	6a 00                	push   $0x0
f0103594:	6a 10                	push   $0x10
f0103596:	e9 00 00 00 00       	jmp    f010359b <_alltraps>

f010359b <_alltraps>:

  //Lab 3: Your code here for _alltraps

.globl _alltraps
_alltraps:
	pushl %ds
f010359b:	1e                   	push   %ds
	pushl %es
f010359c:	06                   	push   %es
	pushal
f010359d:	60                   	pusha  
	movw $GD_KD, %ax
f010359e:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f01035a2:	8e d8                	mov    %eax,%ds
	movw %ax, %es	
f01035a4:	8e c0                	mov    %eax,%es
		
	pushl %esp
f01035a6:	54                   	push   %esp
	call trap
f01035a7:	e8 26 fe ff ff       	call   f01033d2 <trap>

f01035ac <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01035ac:	55                   	push   %ebp
f01035ad:	89 e5                	mov    %esp,%ebp
f01035af:	83 ec 0c             	sub    $0xc,%esp
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	panic("syscall not implemented");
f01035b2:	68 50 60 10 f0       	push   $0xf0106050
f01035b7:	6a 49                	push   $0x49
f01035b9:	68 68 60 10 f0       	push   $0xf0106068
f01035be:	e8 dd ca ff ff       	call   f01000a0 <_panic>

f01035c3 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01035c3:	55                   	push   %ebp
f01035c4:	89 e5                	mov    %esp,%ebp
f01035c6:	57                   	push   %edi
f01035c7:	56                   	push   %esi
f01035c8:	53                   	push   %ebx
f01035c9:	83 ec 14             	sub    $0x14,%esp
f01035cc:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01035cf:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01035d2:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01035d5:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01035d8:	8b 1a                	mov    (%edx),%ebx
f01035da:	8b 01                	mov    (%ecx),%eax
f01035dc:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01035df:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01035e6:	e9 88 00 00 00       	jmp    f0103673 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f01035eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01035ee:	01 d8                	add    %ebx,%eax
f01035f0:	89 c6                	mov    %eax,%esi
f01035f2:	c1 ee 1f             	shr    $0x1f,%esi
f01035f5:	01 c6                	add    %eax,%esi
f01035f7:	d1 fe                	sar    %esi
f01035f9:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01035fc:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01035ff:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103602:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103604:	eb 03                	jmp    f0103609 <stab_binsearch+0x46>
			m--;
f0103606:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103609:	39 c3                	cmp    %eax,%ebx
f010360b:	7f 1f                	jg     f010362c <stab_binsearch+0x69>
f010360d:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103611:	83 ea 0c             	sub    $0xc,%edx
f0103614:	39 f9                	cmp    %edi,%ecx
f0103616:	75 ee                	jne    f0103606 <stab_binsearch+0x43>
f0103618:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010361b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010361e:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103621:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103625:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103628:	76 18                	jbe    f0103642 <stab_binsearch+0x7f>
f010362a:	eb 05                	jmp    f0103631 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010362c:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f010362f:	eb 42                	jmp    f0103673 <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0103631:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103634:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0103636:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103639:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103640:	eb 31                	jmp    f0103673 <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103642:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103645:	73 17                	jae    f010365e <stab_binsearch+0x9b>
			*region_right = m - 1;
f0103647:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010364a:	83 e8 01             	sub    $0x1,%eax
f010364d:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103650:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103653:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103655:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010365c:	eb 15                	jmp    f0103673 <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010365e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103661:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0103664:	89 1e                	mov    %ebx,(%esi)
			l = m;
			addr++;
f0103666:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010366a:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010366c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103673:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0103676:	0f 8e 6f ff ff ff    	jle    f01035eb <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010367c:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103680:	75 0f                	jne    f0103691 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0103682:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103685:	8b 00                	mov    (%eax),%eax
f0103687:	83 e8 01             	sub    $0x1,%eax
f010368a:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010368d:	89 06                	mov    %eax,(%esi)
f010368f:	eb 2c                	jmp    f01036bd <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103691:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103694:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103696:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103699:	8b 0e                	mov    (%esi),%ecx
f010369b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010369e:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01036a1:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01036a4:	eb 03                	jmp    f01036a9 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01036a6:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01036a9:	39 c8                	cmp    %ecx,%eax
f01036ab:	7e 0b                	jle    f01036b8 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f01036ad:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01036b1:	83 ea 0c             	sub    $0xc,%edx
f01036b4:	39 fb                	cmp    %edi,%ebx
f01036b6:	75 ee                	jne    f01036a6 <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f01036b8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01036bb:	89 06                	mov    %eax,(%esi)
	}
}
f01036bd:	83 c4 14             	add    $0x14,%esp
f01036c0:	5b                   	pop    %ebx
f01036c1:	5e                   	pop    %esi
f01036c2:	5f                   	pop    %edi
f01036c3:	5d                   	pop    %ebp
f01036c4:	c3                   	ret    

f01036c5 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01036c5:	55                   	push   %ebp
f01036c6:	89 e5                	mov    %esp,%ebp
f01036c8:	57                   	push   %edi
f01036c9:	56                   	push   %esi
f01036ca:	53                   	push   %ebx
f01036cb:	83 ec 3c             	sub    $0x3c,%esp
f01036ce:	8b 75 08             	mov    0x8(%ebp),%esi
f01036d1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01036d4:	c7 03 77 60 10 f0    	movl   $0xf0106077,(%ebx)
	info->eip_line = 0;
f01036da:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01036e1:	c7 43 08 77 60 10 f0 	movl   $0xf0106077,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01036e8:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01036ef:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01036f2:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01036f9:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01036ff:	77 21                	ja     f0103722 <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0103701:	a1 00 00 20 00       	mov    0x200000,%eax
f0103706:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		stab_end = usd->stab_end;
f0103709:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f010370e:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f0103714:	89 7d c0             	mov    %edi,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f0103717:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f010371d:	89 7d bc             	mov    %edi,-0x44(%ebp)
f0103720:	eb 1a                	jmp    f010373c <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103722:	c7 45 bc 7d 0f 11 f0 	movl   $0xf0110f7d,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103729:	c7 45 c0 7d e4 10 f0 	movl   $0xf010e47d,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103730:	b8 7c e4 10 f0       	mov    $0xf010e47c,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103735:	c7 45 c4 b0 62 10 f0 	movl   $0xf01062b0,-0x3c(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010373c:	8b 7d bc             	mov    -0x44(%ebp),%edi
f010373f:	39 7d c0             	cmp    %edi,-0x40(%ebp)
f0103742:	0f 83 72 01 00 00    	jae    f01038ba <debuginfo_eip+0x1f5>
f0103748:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f010374c:	0f 85 6f 01 00 00    	jne    f01038c1 <debuginfo_eip+0x1fc>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103752:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103759:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010375c:	29 f8                	sub    %edi,%eax
f010375e:	c1 f8 02             	sar    $0x2,%eax
f0103761:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103767:	83 e8 01             	sub    $0x1,%eax
f010376a:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010376d:	56                   	push   %esi
f010376e:	6a 64                	push   $0x64
f0103770:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103773:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103776:	89 f8                	mov    %edi,%eax
f0103778:	e8 46 fe ff ff       	call   f01035c3 <stab_binsearch>
	if (lfile == 0)
f010377d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103780:	83 c4 08             	add    $0x8,%esp
f0103783:	85 c0                	test   %eax,%eax
f0103785:	0f 84 3d 01 00 00    	je     f01038c8 <debuginfo_eip+0x203>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010378b:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010378e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103791:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103794:	56                   	push   %esi
f0103795:	6a 24                	push   $0x24
f0103797:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010379a:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010379d:	89 f8                	mov    %edi,%eax
f010379f:	e8 1f fe ff ff       	call   f01035c3 <stab_binsearch>

	if (lfun <= rfun) {
f01037a4:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01037a7:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f01037aa:	83 c4 08             	add    $0x8,%esp
f01037ad:	39 c8                	cmp    %ecx,%eax
f01037af:	7f 32                	jg     f01037e3 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01037b1:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01037b4:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01037b7:	8d 3c 97             	lea    (%edi,%edx,4),%edi
f01037ba:	8b 17                	mov    (%edi),%edx
f01037bc:	89 55 b8             	mov    %edx,-0x48(%ebp)
f01037bf:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01037c2:	2b 55 c0             	sub    -0x40(%ebp),%edx
f01037c5:	39 55 b8             	cmp    %edx,-0x48(%ebp)
f01037c8:	73 09                	jae    f01037d3 <debuginfo_eip+0x10e>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01037ca:	8b 55 b8             	mov    -0x48(%ebp),%edx
f01037cd:	03 55 c0             	add    -0x40(%ebp),%edx
f01037d0:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01037d3:	8b 57 08             	mov    0x8(%edi),%edx
f01037d6:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01037d9:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01037db:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01037de:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f01037e1:	eb 0f                	jmp    f01037f2 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01037e3:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01037e6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01037e9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01037ec:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01037ef:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01037f2:	83 ec 08             	sub    $0x8,%esp
f01037f5:	6a 3a                	push   $0x3a
f01037f7:	ff 73 08             	pushl  0x8(%ebx)
f01037fa:	e8 4f 0b 00 00       	call   f010434e <strfind>
f01037ff:	2b 43 08             	sub    0x8(%ebx),%eax
f0103802:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103805:	83 c4 08             	add    $0x8,%esp
f0103808:	56                   	push   %esi
f0103809:	6a 44                	push   $0x44
f010380b:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f010380e:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103811:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0103814:	89 f0                	mov    %esi,%eax
f0103816:	e8 a8 fd ff ff       	call   f01035c3 <stab_binsearch>
	if(lline <= rline){
f010381b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010381e:	83 c4 10             	add    $0x10,%esp
f0103821:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103824:	0f 8f a5 00 00 00    	jg     f01038cf <debuginfo_eip+0x20a>
		info->eip_line = stabs[lline].n_desc;
f010382a:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010382d:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0103832:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103835:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103838:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010383b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010383e:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0103841:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103844:	eb 06                	jmp    f010384c <debuginfo_eip+0x187>
f0103846:	83 e8 01             	sub    $0x1,%eax
f0103849:	83 ea 0c             	sub    $0xc,%edx
f010384c:	39 c7                	cmp    %eax,%edi
f010384e:	7f 27                	jg     f0103877 <debuginfo_eip+0x1b2>
	       && stabs[lline].n_type != N_SOL
f0103850:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103854:	80 f9 84             	cmp    $0x84,%cl
f0103857:	0f 84 80 00 00 00    	je     f01038dd <debuginfo_eip+0x218>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010385d:	80 f9 64             	cmp    $0x64,%cl
f0103860:	75 e4                	jne    f0103846 <debuginfo_eip+0x181>
f0103862:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103866:	74 de                	je     f0103846 <debuginfo_eip+0x181>
f0103868:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010386b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010386e:	eb 73                	jmp    f01038e3 <debuginfo_eip+0x21e>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103870:	03 55 c0             	add    -0x40(%ebp),%edx
f0103873:	89 13                	mov    %edx,(%ebx)
f0103875:	eb 03                	jmp    f010387a <debuginfo_eip+0x1b5>
f0103877:	8b 5d 0c             	mov    0xc(%ebp),%ebx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010387a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010387d:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103880:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103885:	39 f2                	cmp    %esi,%edx
f0103887:	7d 76                	jge    f01038ff <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
f0103889:	83 c2 01             	add    $0x1,%edx
f010388c:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010388f:	89 d0                	mov    %edx,%eax
f0103891:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103894:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0103897:	8d 14 97             	lea    (%edi,%edx,4),%edx
f010389a:	eb 04                	jmp    f01038a0 <debuginfo_eip+0x1db>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010389c:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01038a0:	39 c6                	cmp    %eax,%esi
f01038a2:	7e 32                	jle    f01038d6 <debuginfo_eip+0x211>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01038a4:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01038a8:	83 c0 01             	add    $0x1,%eax
f01038ab:	83 c2 0c             	add    $0xc,%edx
f01038ae:	80 f9 a0             	cmp    $0xa0,%cl
f01038b1:	74 e9                	je     f010389c <debuginfo_eip+0x1d7>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01038b3:	b8 00 00 00 00       	mov    $0x0,%eax
f01038b8:	eb 45                	jmp    f01038ff <debuginfo_eip+0x23a>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01038ba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01038bf:	eb 3e                	jmp    f01038ff <debuginfo_eip+0x23a>
f01038c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01038c6:	eb 37                	jmp    f01038ff <debuginfo_eip+0x23a>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01038c8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01038cd:	eb 30                	jmp    f01038ff <debuginfo_eip+0x23a>
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if(lline <= rline){
		info->eip_line = stabs[lline].n_desc;
	}
	else{
		return -1;
f01038cf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01038d4:	eb 29                	jmp    f01038ff <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01038d6:	b8 00 00 00 00       	mov    $0x0,%eax
f01038db:	eb 22                	jmp    f01038ff <debuginfo_eip+0x23a>
f01038dd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01038e0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01038e3:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01038e6:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01038e9:	8b 14 87             	mov    (%edi,%eax,4),%edx
f01038ec:	8b 45 bc             	mov    -0x44(%ebp),%eax
f01038ef:	2b 45 c0             	sub    -0x40(%ebp),%eax
f01038f2:	39 c2                	cmp    %eax,%edx
f01038f4:	0f 82 76 ff ff ff    	jb     f0103870 <debuginfo_eip+0x1ab>
f01038fa:	e9 7b ff ff ff       	jmp    f010387a <debuginfo_eip+0x1b5>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
}
f01038ff:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103902:	5b                   	pop    %ebx
f0103903:	5e                   	pop    %esi
f0103904:	5f                   	pop    %edi
f0103905:	5d                   	pop    %ebp
f0103906:	c3                   	ret    

f0103907 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103907:	55                   	push   %ebp
f0103908:	89 e5                	mov    %esp,%ebp
f010390a:	57                   	push   %edi
f010390b:	56                   	push   %esi
f010390c:	53                   	push   %ebx
f010390d:	83 ec 1c             	sub    $0x1c,%esp
f0103910:	89 c7                	mov    %eax,%edi
f0103912:	89 d6                	mov    %edx,%esi
f0103914:	8b 45 08             	mov    0x8(%ebp),%eax
f0103917:	8b 55 0c             	mov    0xc(%ebp),%edx
f010391a:	89 d1                	mov    %edx,%ecx
f010391c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010391f:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103922:	8b 45 10             	mov    0x10(%ebp),%eax
f0103925:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103928:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010392b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0103932:	39 4d e4             	cmp    %ecx,-0x1c(%ebp)
f0103935:	72 05                	jb     f010393c <printnum+0x35>
f0103937:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f010393a:	77 3e                	ja     f010397a <printnum+0x73>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010393c:	83 ec 0c             	sub    $0xc,%esp
f010393f:	ff 75 18             	pushl  0x18(%ebp)
f0103942:	83 eb 01             	sub    $0x1,%ebx
f0103945:	53                   	push   %ebx
f0103946:	50                   	push   %eax
f0103947:	83 ec 08             	sub    $0x8,%esp
f010394a:	ff 75 e4             	pushl  -0x1c(%ebp)
f010394d:	ff 75 e0             	pushl  -0x20(%ebp)
f0103950:	ff 75 dc             	pushl  -0x24(%ebp)
f0103953:	ff 75 d8             	pushl  -0x28(%ebp)
f0103956:	e8 25 0c 00 00       	call   f0104580 <__udivdi3>
f010395b:	83 c4 18             	add    $0x18,%esp
f010395e:	52                   	push   %edx
f010395f:	50                   	push   %eax
f0103960:	89 f2                	mov    %esi,%edx
f0103962:	89 f8                	mov    %edi,%eax
f0103964:	e8 9e ff ff ff       	call   f0103907 <printnum>
f0103969:	83 c4 20             	add    $0x20,%esp
f010396c:	eb 13                	jmp    f0103981 <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010396e:	83 ec 08             	sub    $0x8,%esp
f0103971:	56                   	push   %esi
f0103972:	ff 75 18             	pushl  0x18(%ebp)
f0103975:	ff d7                	call   *%edi
f0103977:	83 c4 10             	add    $0x10,%esp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f010397a:	83 eb 01             	sub    $0x1,%ebx
f010397d:	85 db                	test   %ebx,%ebx
f010397f:	7f ed                	jg     f010396e <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103981:	83 ec 08             	sub    $0x8,%esp
f0103984:	56                   	push   %esi
f0103985:	83 ec 04             	sub    $0x4,%esp
f0103988:	ff 75 e4             	pushl  -0x1c(%ebp)
f010398b:	ff 75 e0             	pushl  -0x20(%ebp)
f010398e:	ff 75 dc             	pushl  -0x24(%ebp)
f0103991:	ff 75 d8             	pushl  -0x28(%ebp)
f0103994:	e8 17 0d 00 00       	call   f01046b0 <__umoddi3>
f0103999:	83 c4 14             	add    $0x14,%esp
f010399c:	0f be 80 81 60 10 f0 	movsbl -0xfef9f7f(%eax),%eax
f01039a3:	50                   	push   %eax
f01039a4:	ff d7                	call   *%edi
f01039a6:	83 c4 10             	add    $0x10,%esp
}
f01039a9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01039ac:	5b                   	pop    %ebx
f01039ad:	5e                   	pop    %esi
f01039ae:	5f                   	pop    %edi
f01039af:	5d                   	pop    %ebp
f01039b0:	c3                   	ret    

f01039b1 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01039b1:	55                   	push   %ebp
f01039b2:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01039b4:	83 fa 01             	cmp    $0x1,%edx
f01039b7:	7e 0e                	jle    f01039c7 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01039b9:	8b 10                	mov    (%eax),%edx
f01039bb:	8d 4a 08             	lea    0x8(%edx),%ecx
f01039be:	89 08                	mov    %ecx,(%eax)
f01039c0:	8b 02                	mov    (%edx),%eax
f01039c2:	8b 52 04             	mov    0x4(%edx),%edx
f01039c5:	eb 22                	jmp    f01039e9 <getuint+0x38>
	else if (lflag)
f01039c7:	85 d2                	test   %edx,%edx
f01039c9:	74 10                	je     f01039db <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01039cb:	8b 10                	mov    (%eax),%edx
f01039cd:	8d 4a 04             	lea    0x4(%edx),%ecx
f01039d0:	89 08                	mov    %ecx,(%eax)
f01039d2:	8b 02                	mov    (%edx),%eax
f01039d4:	ba 00 00 00 00       	mov    $0x0,%edx
f01039d9:	eb 0e                	jmp    f01039e9 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01039db:	8b 10                	mov    (%eax),%edx
f01039dd:	8d 4a 04             	lea    0x4(%edx),%ecx
f01039e0:	89 08                	mov    %ecx,(%eax)
f01039e2:	8b 02                	mov    (%edx),%eax
f01039e4:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01039e9:	5d                   	pop    %ebp
f01039ea:	c3                   	ret    

f01039eb <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01039eb:	55                   	push   %ebp
f01039ec:	89 e5                	mov    %esp,%ebp
f01039ee:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01039f1:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01039f5:	8b 10                	mov    (%eax),%edx
f01039f7:	3b 50 04             	cmp    0x4(%eax),%edx
f01039fa:	73 0a                	jae    f0103a06 <sprintputch+0x1b>
		*b->buf++ = ch;
f01039fc:	8d 4a 01             	lea    0x1(%edx),%ecx
f01039ff:	89 08                	mov    %ecx,(%eax)
f0103a01:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a04:	88 02                	mov    %al,(%edx)
}
f0103a06:	5d                   	pop    %ebp
f0103a07:	c3                   	ret    

f0103a08 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103a08:	55                   	push   %ebp
f0103a09:	89 e5                	mov    %esp,%ebp
f0103a0b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103a0e:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103a11:	50                   	push   %eax
f0103a12:	ff 75 10             	pushl  0x10(%ebp)
f0103a15:	ff 75 0c             	pushl  0xc(%ebp)
f0103a18:	ff 75 08             	pushl  0x8(%ebp)
f0103a1b:	e8 05 00 00 00       	call   f0103a25 <vprintfmt>
	va_end(ap);
f0103a20:	83 c4 10             	add    $0x10,%esp
}
f0103a23:	c9                   	leave  
f0103a24:	c3                   	ret    

f0103a25 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103a25:	55                   	push   %ebp
f0103a26:	89 e5                	mov    %esp,%ebp
f0103a28:	57                   	push   %edi
f0103a29:	56                   	push   %esi
f0103a2a:	53                   	push   %ebx
f0103a2b:	83 ec 3c             	sub    $0x3c,%esp
f0103a2e:	8b 75 08             	mov    0x8(%ebp),%esi
f0103a31:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103a34:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103a37:	eb 12                	jmp    f0103a4b <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;
	char colorcontrol[5];
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103a39:	85 c0                	test   %eax,%eax
f0103a3b:	0f 84 62 06 00 00    	je     f01040a3 <vprintfmt+0x67e>
				return;
			putch(ch, putdat);
f0103a41:	83 ec 08             	sub    $0x8,%esp
f0103a44:	53                   	push   %ebx
f0103a45:	50                   	push   %eax
f0103a46:	ff d6                	call   *%esi
f0103a48:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;
	char colorcontrol[5];
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103a4b:	83 c7 01             	add    $0x1,%edi
f0103a4e:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103a52:	83 f8 25             	cmp    $0x25,%eax
f0103a55:	75 e2                	jne    f0103a39 <vprintfmt+0x14>
f0103a57:	c6 45 c4 20          	movb   $0x20,-0x3c(%ebp)
f0103a5b:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
f0103a62:	c7 45 c0 ff ff ff ff 	movl   $0xffffffff,-0x40(%ebp)
f0103a69:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103a70:	ba 00 00 00 00       	mov    $0x0,%edx
f0103a75:	eb 07                	jmp    f0103a7e <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103a77:	8b 7d d4             	mov    -0x2c(%ebp),%edi
					colr = COLR_BLACK;
			}
			colr |= highlight;
			break;
		case '-':
			padc = '-';
f0103a7a:	c6 45 c4 2d          	movb   $0x2d,-0x3c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103a7e:	8d 47 01             	lea    0x1(%edi),%eax
f0103a81:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103a84:	0f b6 07             	movzbl (%edi),%eax
f0103a87:	0f b6 c8             	movzbl %al,%ecx
f0103a8a:	83 e8 23             	sub    $0x23,%eax
f0103a8d:	3c 55                	cmp    $0x55,%al
f0103a8f:	0f 87 f3 05 00 00    	ja     f0104088 <vprintfmt+0x663>
f0103a95:	0f b6 c0             	movzbl %al,%eax
f0103a98:	ff 24 85 20 61 10 f0 	jmp    *-0xfef9ee0(,%eax,4)
f0103a9f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103aa2:	c6 45 c4 30          	movb   $0x30,-0x3c(%ebp)
f0103aa6:	eb d6                	jmp    f0103a7e <vprintfmt+0x59>
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {

		// flag to pad on the right
		case 'C':
			memmove(colorcontrol, fmt, sizeof(unsigned char)*3);
f0103aa8:	83 ec 04             	sub    $0x4,%esp
f0103aab:	6a 03                	push   $0x3
f0103aad:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103ab0:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103ab3:	50                   	push   %eax
f0103ab4:	e8 fe 08 00 00       	call   f01043b7 <memmove>
			colorcontrol[3] = '\0';
f0103ab9:	c6 45 e6 00          	movb   $0x0,-0x1a(%ebp)
			fmt += 3;
f0103abd:	83 c7 04             	add    $0x4,%edi
			if(colorcontrol[0] >= '0' && colorcontrol[0] <= '9'){
f0103ac0:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f0103ac4:	8d 50 d0             	lea    -0x30(%eax),%edx
f0103ac7:	83 c4 10             	add    $0x10,%esp
f0103aca:	80 fa 09             	cmp    $0x9,%dl
f0103acd:	77 29                	ja     f0103af8 <vprintfmt+0xd3>
				colr = (colorcontrol[0] - '0') * 100 + (colorcontrol[1] - '0') * 10 + (colorcontrol[2] - '0');
f0103acf:	0f be c0             	movsbl %al,%eax
f0103ad2:	83 e8 30             	sub    $0x30,%eax
f0103ad5:	6b c0 64             	imul   $0x64,%eax,%eax
f0103ad8:	0f be 55 e4          	movsbl -0x1c(%ebp),%edx
f0103adc:	8d 94 92 10 ff ff ff 	lea    -0xf0(%edx,%edx,4),%edx
f0103ae3:	8d 14 50             	lea    (%eax,%edx,2),%edx
f0103ae6:	0f be 45 e5          	movsbl -0x1b(%ebp),%eax
f0103aea:	8d 44 02 d0          	lea    -0x30(%edx,%eax,1),%eax
f0103aee:	a3 ec dc 17 f0       	mov    %eax,0xf017dcec
f0103af3:	e9 53 ff ff ff       	jmp    f0103a4b <vprintfmt+0x26>
			}
			else{
				if(strcmp(colorcontrol, "ble") == 0) colr = COLR_BLUE
f0103af8:	83 ec 08             	sub    $0x8,%esp
f0103afb:	68 cd 5e 10 f0       	push   $0xf0105ecd
f0103b00:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103b03:	50                   	push   %eax
f0103b04:	e8 c6 07 00 00       	call   f01042cf <strcmp>
f0103b09:	83 c4 10             	add    $0x10,%esp
f0103b0c:	85 c0                	test   %eax,%eax
f0103b0e:	75 0f                	jne    f0103b1f <vprintfmt+0xfa>
f0103b10:	c7 05 ec dc 17 f0 01 	movl   $0x1,0xf017dcec
f0103b17:	00 00 00 
f0103b1a:	e9 2c ff ff ff       	jmp    f0103a4b <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "grn") == 0) colr = COLR_GREEN
f0103b1f:	83 ec 08             	sub    $0x8,%esp
f0103b22:	68 99 60 10 f0       	push   $0xf0106099
f0103b27:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103b2a:	50                   	push   %eax
f0103b2b:	e8 9f 07 00 00       	call   f01042cf <strcmp>
f0103b30:	83 c4 10             	add    $0x10,%esp
f0103b33:	85 c0                	test   %eax,%eax
f0103b35:	75 0f                	jne    f0103b46 <vprintfmt+0x121>
f0103b37:	c7 05 ec dc 17 f0 02 	movl   $0x2,0xf017dcec
f0103b3e:	00 00 00 
f0103b41:	e9 05 ff ff ff       	jmp    f0103a4b <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "cyn") == 0) colr = COLR_CYAN
f0103b46:	83 ec 08             	sub    $0x8,%esp
f0103b49:	68 9d 60 10 f0       	push   $0xf010609d
f0103b4e:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103b51:	50                   	push   %eax
f0103b52:	e8 78 07 00 00       	call   f01042cf <strcmp>
f0103b57:	83 c4 10             	add    $0x10,%esp
f0103b5a:	85 c0                	test   %eax,%eax
f0103b5c:	75 0f                	jne    f0103b6d <vprintfmt+0x148>
f0103b5e:	c7 05 ec dc 17 f0 03 	movl   $0x3,0xf017dcec
f0103b65:	00 00 00 
f0103b68:	e9 de fe ff ff       	jmp    f0103a4b <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "red") == 0) colr = COLR_RED
f0103b6d:	83 ec 08             	sub    $0x8,%esp
f0103b70:	68 a1 60 10 f0       	push   $0xf01060a1
f0103b75:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103b78:	50                   	push   %eax
f0103b79:	e8 51 07 00 00       	call   f01042cf <strcmp>
f0103b7e:	83 c4 10             	add    $0x10,%esp
f0103b81:	85 c0                	test   %eax,%eax
f0103b83:	75 0f                	jne    f0103b94 <vprintfmt+0x16f>
f0103b85:	c7 05 ec dc 17 f0 04 	movl   $0x4,0xf017dcec
f0103b8c:	00 00 00 
f0103b8f:	e9 b7 fe ff ff       	jmp    f0103a4b <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "mag") == 0) colr = COLR_MAGENTA
f0103b94:	83 ec 08             	sub    $0x8,%esp
f0103b97:	68 a5 60 10 f0       	push   $0xf01060a5
f0103b9c:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103b9f:	50                   	push   %eax
f0103ba0:	e8 2a 07 00 00       	call   f01042cf <strcmp>
f0103ba5:	83 c4 10             	add    $0x10,%esp
f0103ba8:	85 c0                	test   %eax,%eax
f0103baa:	75 0f                	jne    f0103bbb <vprintfmt+0x196>
f0103bac:	c7 05 ec dc 17 f0 05 	movl   $0x5,0xf017dcec
f0103bb3:	00 00 00 
f0103bb6:	e9 90 fe ff ff       	jmp    f0103a4b <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "brw")== 0) colr = COLR_BROWN
f0103bbb:	83 ec 08             	sub    $0x8,%esp
f0103bbe:	68 a9 60 10 f0       	push   $0xf01060a9
f0103bc3:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103bc6:	50                   	push   %eax
f0103bc7:	e8 03 07 00 00       	call   f01042cf <strcmp>
f0103bcc:	83 c4 10             	add    $0x10,%esp
f0103bcf:	85 c0                	test   %eax,%eax
f0103bd1:	75 0f                	jne    f0103be2 <vprintfmt+0x1bd>
f0103bd3:	c7 05 ec dc 17 f0 06 	movl   $0x6,0xf017dcec
f0103bda:	00 00 00 
f0103bdd:	e9 69 fe ff ff       	jmp    f0103a4b <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "gry") == 0) colr = COLR_GRAY
f0103be2:	83 ec 08             	sub    $0x8,%esp
f0103be5:	68 ad 60 10 f0       	push   $0xf01060ad
f0103bea:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103bed:	50                   	push   %eax
f0103bee:	e8 dc 06 00 00       	call   f01042cf <strcmp>
f0103bf3:	83 c4 10             	add    $0x10,%esp
f0103bf6:	83 f8 01             	cmp    $0x1,%eax
f0103bf9:	19 c0                	sbb    %eax,%eax
f0103bfb:	83 e0 07             	and    $0x7,%eax
f0103bfe:	a3 ec dc 17 f0       	mov    %eax,0xf017dcec
f0103c03:	e9 43 fe ff ff       	jmp    f0103a4b <vprintfmt+0x26>
					colr = COLR_BLACK;
			}
			break;
				
		case 'I':
			highlight = COLR_HIGHLIGHT;
f0103c08:	c7 05 e8 dc 17 f0 08 	movl   $0x8,0xf017dce8
f0103c0f:	00 00 00 
			memmove(colorcontrol, fmt, sizeof(unsigned char)*3);
f0103c12:	83 ec 04             	sub    $0x4,%esp
f0103c15:	6a 03                	push   $0x3
f0103c17:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103c1a:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103c1d:	50                   	push   %eax
f0103c1e:	e8 94 07 00 00       	call   f01043b7 <memmove>
			colorcontrol[3] = '\0';
f0103c23:	c6 45 e6 00          	movb   $0x0,-0x1a(%ebp)
			fmt += 3;
f0103c27:	83 c7 04             	add    $0x4,%edi
			if(colorcontrol[0] >= '0' && colorcontrol[0] <= '9'){
f0103c2a:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f0103c2e:	8d 50 d0             	lea    -0x30(%eax),%edx
f0103c31:	83 c4 10             	add    $0x10,%esp
f0103c34:	80 fa 09             	cmp    $0x9,%dl
f0103c37:	77 29                	ja     f0103c62 <vprintfmt+0x23d>
				colr = (colorcontrol[0] - '0') * 100 + (colorcontrol[1] - '0') * 10 + (colorcontrol[2] - '0');
f0103c39:	0f be c0             	movsbl %al,%eax
f0103c3c:	83 e8 30             	sub    $0x30,%eax
f0103c3f:	6b c0 64             	imul   $0x64,%eax,%eax
f0103c42:	0f be 55 e4          	movsbl -0x1c(%ebp),%edx
f0103c46:	8d 94 92 10 ff ff ff 	lea    -0xf0(%edx,%edx,4),%edx
f0103c4d:	8d 14 50             	lea    (%eax,%edx,2),%edx
f0103c50:	0f be 45 e5          	movsbl -0x1b(%ebp),%eax
f0103c54:	8d 44 02 d0          	lea    -0x30(%edx,%eax,1),%eax
f0103c58:	a3 ec dc 17 f0       	mov    %eax,0xf017dcec
f0103c5d:	e9 02 01 00 00       	jmp    f0103d64 <vprintfmt+0x33f>
			}
			else{
				if(strcmp(colorcontrol, "ble") == 0) colr = COLR_BLUE
f0103c62:	83 ec 08             	sub    $0x8,%esp
f0103c65:	68 cd 5e 10 f0       	push   $0xf0105ecd
f0103c6a:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103c6d:	50                   	push   %eax
f0103c6e:	e8 5c 06 00 00       	call   f01042cf <strcmp>
f0103c73:	83 c4 10             	add    $0x10,%esp
f0103c76:	85 c0                	test   %eax,%eax
f0103c78:	75 0f                	jne    f0103c89 <vprintfmt+0x264>
f0103c7a:	c7 05 ec dc 17 f0 01 	movl   $0x1,0xf017dcec
f0103c81:	00 00 00 
f0103c84:	e9 db 00 00 00       	jmp    f0103d64 <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "grn") == 0) colr = COLR_GREEN
f0103c89:	83 ec 08             	sub    $0x8,%esp
f0103c8c:	68 99 60 10 f0       	push   $0xf0106099
f0103c91:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103c94:	50                   	push   %eax
f0103c95:	e8 35 06 00 00       	call   f01042cf <strcmp>
f0103c9a:	83 c4 10             	add    $0x10,%esp
f0103c9d:	85 c0                	test   %eax,%eax
f0103c9f:	75 0f                	jne    f0103cb0 <vprintfmt+0x28b>
f0103ca1:	c7 05 ec dc 17 f0 02 	movl   $0x2,0xf017dcec
f0103ca8:	00 00 00 
f0103cab:	e9 b4 00 00 00       	jmp    f0103d64 <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "cyn") == 0) colr = COLR_CYAN
f0103cb0:	83 ec 08             	sub    $0x8,%esp
f0103cb3:	68 9d 60 10 f0       	push   $0xf010609d
f0103cb8:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103cbb:	50                   	push   %eax
f0103cbc:	e8 0e 06 00 00       	call   f01042cf <strcmp>
f0103cc1:	83 c4 10             	add    $0x10,%esp
f0103cc4:	85 c0                	test   %eax,%eax
f0103cc6:	75 0f                	jne    f0103cd7 <vprintfmt+0x2b2>
f0103cc8:	c7 05 ec dc 17 f0 03 	movl   $0x3,0xf017dcec
f0103ccf:	00 00 00 
f0103cd2:	e9 8d 00 00 00       	jmp    f0103d64 <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "red") == 0) colr = COLR_RED
f0103cd7:	83 ec 08             	sub    $0x8,%esp
f0103cda:	68 a1 60 10 f0       	push   $0xf01060a1
f0103cdf:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103ce2:	50                   	push   %eax
f0103ce3:	e8 e7 05 00 00       	call   f01042cf <strcmp>
f0103ce8:	83 c4 10             	add    $0x10,%esp
f0103ceb:	85 c0                	test   %eax,%eax
f0103ced:	75 0c                	jne    f0103cfb <vprintfmt+0x2d6>
f0103cef:	c7 05 ec dc 17 f0 04 	movl   $0x4,0xf017dcec
f0103cf6:	00 00 00 
f0103cf9:	eb 69                	jmp    f0103d64 <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "mag") == 0) colr = COLR_MAGENTA
f0103cfb:	83 ec 08             	sub    $0x8,%esp
f0103cfe:	68 a5 60 10 f0       	push   $0xf01060a5
f0103d03:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103d06:	50                   	push   %eax
f0103d07:	e8 c3 05 00 00       	call   f01042cf <strcmp>
f0103d0c:	83 c4 10             	add    $0x10,%esp
f0103d0f:	85 c0                	test   %eax,%eax
f0103d11:	75 0c                	jne    f0103d1f <vprintfmt+0x2fa>
f0103d13:	c7 05 ec dc 17 f0 05 	movl   $0x5,0xf017dcec
f0103d1a:	00 00 00 
f0103d1d:	eb 45                	jmp    f0103d64 <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "brw")== 0) colr = COLR_BROWN
f0103d1f:	83 ec 08             	sub    $0x8,%esp
f0103d22:	68 a9 60 10 f0       	push   $0xf01060a9
f0103d27:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103d2a:	50                   	push   %eax
f0103d2b:	e8 9f 05 00 00       	call   f01042cf <strcmp>
f0103d30:	83 c4 10             	add    $0x10,%esp
f0103d33:	85 c0                	test   %eax,%eax
f0103d35:	75 0c                	jne    f0103d43 <vprintfmt+0x31e>
f0103d37:	c7 05 ec dc 17 f0 06 	movl   $0x6,0xf017dcec
f0103d3e:	00 00 00 
f0103d41:	eb 21                	jmp    f0103d64 <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "gry") == 0) colr = COLR_GRAY
f0103d43:	83 ec 08             	sub    $0x8,%esp
f0103d46:	68 ad 60 10 f0       	push   $0xf01060ad
f0103d4b:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103d4e:	50                   	push   %eax
f0103d4f:	e8 7b 05 00 00       	call   f01042cf <strcmp>
f0103d54:	83 c4 10             	add    $0x10,%esp
f0103d57:	83 f8 01             	cmp    $0x1,%eax
f0103d5a:	19 c0                	sbb    %eax,%eax
f0103d5c:	83 e0 07             	and    $0x7,%eax
f0103d5f:	a3 ec dc 17 f0       	mov    %eax,0xf017dcec
				else
					colr = COLR_BLACK;
			}
			colr |= highlight;
f0103d64:	a1 e8 dc 17 f0       	mov    0xf017dce8,%eax
f0103d69:	09 05 ec dc 17 f0    	or     %eax,0xf017dcec
			break;
f0103d6f:	e9 d7 fc ff ff       	jmp    f0103a4b <vprintfmt+0x26>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d74:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103d77:	b8 00 00 00 00       	mov    $0x0,%eax
f0103d7c:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103d7f:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103d82:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0103d86:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0103d89:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0103d8c:	83 fa 09             	cmp    $0x9,%edx
f0103d8f:	77 3f                	ja     f0103dd0 <vprintfmt+0x3ab>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103d91:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103d94:	eb e9                	jmp    f0103d7f <vprintfmt+0x35a>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103d96:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d99:	8d 48 04             	lea    0x4(%eax),%ecx
f0103d9c:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103d9f:	8b 00                	mov    (%eax),%eax
f0103da1:	89 45 c0             	mov    %eax,-0x40(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103da4:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103da7:	eb 2d                	jmp    f0103dd6 <vprintfmt+0x3b1>
f0103da9:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103dac:	85 c0                	test   %eax,%eax
f0103dae:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103db3:	0f 49 c8             	cmovns %eax,%ecx
f0103db6:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103db9:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103dbc:	e9 bd fc ff ff       	jmp    f0103a7e <vprintfmt+0x59>
f0103dc1:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103dc4:	c7 45 c8 01 00 00 00 	movl   $0x1,-0x38(%ebp)
			goto reswitch;
f0103dcb:	e9 ae fc ff ff       	jmp    f0103a7e <vprintfmt+0x59>
f0103dd0:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103dd3:	89 45 c0             	mov    %eax,-0x40(%ebp)

		process_precision:
			if (width < 0)
f0103dd6:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0103dda:	0f 89 9e fc ff ff    	jns    f0103a7e <vprintfmt+0x59>
				width = precision, precision = -1;
f0103de0:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0103de3:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103de6:	c7 45 c0 ff ff ff ff 	movl   $0xffffffff,-0x40(%ebp)
f0103ded:	e9 8c fc ff ff       	jmp    f0103a7e <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103df2:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103df5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103df8:	e9 81 fc ff ff       	jmp    f0103a7e <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103dfd:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e00:	8d 50 04             	lea    0x4(%eax),%edx
f0103e03:	89 55 14             	mov    %edx,0x14(%ebp)
f0103e06:	83 ec 08             	sub    $0x8,%esp
f0103e09:	53                   	push   %ebx
f0103e0a:	ff 30                	pushl  (%eax)
f0103e0c:	ff d6                	call   *%esi
			break;
f0103e0e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e11:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103e14:	e9 32 fc ff ff       	jmp    f0103a4b <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103e19:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e1c:	8d 50 04             	lea    0x4(%eax),%edx
f0103e1f:	89 55 14             	mov    %edx,0x14(%ebp)
f0103e22:	8b 00                	mov    (%eax),%eax
f0103e24:	99                   	cltd   
f0103e25:	31 d0                	xor    %edx,%eax
f0103e27:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103e29:	83 f8 07             	cmp    $0x7,%eax
f0103e2c:	7f 0b                	jg     f0103e39 <vprintfmt+0x414>
f0103e2e:	8b 14 85 80 62 10 f0 	mov    -0xfef9d80(,%eax,4),%edx
f0103e35:	85 d2                	test   %edx,%edx
f0103e37:	75 18                	jne    f0103e51 <vprintfmt+0x42c>
				printfmt(putch, putdat, "error %d", err);
f0103e39:	50                   	push   %eax
f0103e3a:	68 b1 60 10 f0       	push   $0xf01060b1
f0103e3f:	53                   	push   %ebx
f0103e40:	56                   	push   %esi
f0103e41:	e8 c2 fb ff ff       	call   f0103a08 <printfmt>
f0103e46:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e49:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103e4c:	e9 fa fb ff ff       	jmp    f0103a4b <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103e51:	52                   	push   %edx
f0103e52:	68 a7 58 10 f0       	push   $0xf01058a7
f0103e57:	53                   	push   %ebx
f0103e58:	56                   	push   %esi
f0103e59:	e8 aa fb ff ff       	call   f0103a08 <printfmt>
f0103e5e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e61:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103e64:	e9 e2 fb ff ff       	jmp    f0103a4b <vprintfmt+0x26>
f0103e69:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0103e6c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103e6f:	89 45 bc             	mov    %eax,-0x44(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103e72:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e75:	8d 48 04             	lea    0x4(%eax),%ecx
f0103e78:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103e7b:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103e7d:	85 ff                	test   %edi,%edi
f0103e7f:	b8 92 60 10 f0       	mov    $0xf0106092,%eax
f0103e84:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103e87:	80 7d c4 2d          	cmpb   $0x2d,-0x3c(%ebp)
f0103e8b:	0f 84 92 00 00 00    	je     f0103f23 <vprintfmt+0x4fe>
f0103e91:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
f0103e95:	0f 8e 96 00 00 00    	jle    f0103f31 <vprintfmt+0x50c>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103e9b:	83 ec 08             	sub    $0x8,%esp
f0103e9e:	52                   	push   %edx
f0103e9f:	57                   	push   %edi
f0103ea0:	e8 5f 03 00 00       	call   f0104204 <strnlen>
f0103ea5:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0103ea8:	29 c1                	sub    %eax,%ecx
f0103eaa:	89 4d bc             	mov    %ecx,-0x44(%ebp)
f0103ead:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103eb0:	0f be 45 c4          	movsbl -0x3c(%ebp),%eax
f0103eb4:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103eb7:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0103eba:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103ebc:	eb 0f                	jmp    f0103ecd <vprintfmt+0x4a8>
					putch(padc, putdat);
f0103ebe:	83 ec 08             	sub    $0x8,%esp
f0103ec1:	53                   	push   %ebx
f0103ec2:	ff 75 d0             	pushl  -0x30(%ebp)
f0103ec5:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103ec7:	83 ef 01             	sub    $0x1,%edi
f0103eca:	83 c4 10             	add    $0x10,%esp
f0103ecd:	85 ff                	test   %edi,%edi
f0103ecf:	7f ed                	jg     f0103ebe <vprintfmt+0x499>
f0103ed1:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0103ed4:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0103ed7:	85 c9                	test   %ecx,%ecx
f0103ed9:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ede:	0f 49 c1             	cmovns %ecx,%eax
f0103ee1:	29 c1                	sub    %eax,%ecx
f0103ee3:	89 75 08             	mov    %esi,0x8(%ebp)
f0103ee6:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0103ee9:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103eec:	89 cb                	mov    %ecx,%ebx
f0103eee:	eb 4d                	jmp    f0103f3d <vprintfmt+0x518>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103ef0:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
f0103ef4:	74 1b                	je     f0103f11 <vprintfmt+0x4ec>
f0103ef6:	0f be c0             	movsbl %al,%eax
f0103ef9:	83 e8 20             	sub    $0x20,%eax
f0103efc:	83 f8 5e             	cmp    $0x5e,%eax
f0103eff:	76 10                	jbe    f0103f11 <vprintfmt+0x4ec>
					putch('?', putdat);
f0103f01:	83 ec 08             	sub    $0x8,%esp
f0103f04:	ff 75 0c             	pushl  0xc(%ebp)
f0103f07:	6a 3f                	push   $0x3f
f0103f09:	ff 55 08             	call   *0x8(%ebp)
f0103f0c:	83 c4 10             	add    $0x10,%esp
f0103f0f:	eb 0d                	jmp    f0103f1e <vprintfmt+0x4f9>
				else
					putch(ch, putdat);
f0103f11:	83 ec 08             	sub    $0x8,%esp
f0103f14:	ff 75 0c             	pushl  0xc(%ebp)
f0103f17:	52                   	push   %edx
f0103f18:	ff 55 08             	call   *0x8(%ebp)
f0103f1b:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103f1e:	83 eb 01             	sub    $0x1,%ebx
f0103f21:	eb 1a                	jmp    f0103f3d <vprintfmt+0x518>
f0103f23:	89 75 08             	mov    %esi,0x8(%ebp)
f0103f26:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0103f29:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103f2c:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0103f2f:	eb 0c                	jmp    f0103f3d <vprintfmt+0x518>
f0103f31:	89 75 08             	mov    %esi,0x8(%ebp)
f0103f34:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0103f37:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103f3a:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0103f3d:	83 c7 01             	add    $0x1,%edi
f0103f40:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103f44:	0f be d0             	movsbl %al,%edx
f0103f47:	85 d2                	test   %edx,%edx
f0103f49:	74 23                	je     f0103f6e <vprintfmt+0x549>
f0103f4b:	85 f6                	test   %esi,%esi
f0103f4d:	78 a1                	js     f0103ef0 <vprintfmt+0x4cb>
f0103f4f:	83 ee 01             	sub    $0x1,%esi
f0103f52:	79 9c                	jns    f0103ef0 <vprintfmt+0x4cb>
f0103f54:	89 df                	mov    %ebx,%edi
f0103f56:	8b 75 08             	mov    0x8(%ebp),%esi
f0103f59:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103f5c:	eb 18                	jmp    f0103f76 <vprintfmt+0x551>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103f5e:	83 ec 08             	sub    $0x8,%esp
f0103f61:	53                   	push   %ebx
f0103f62:	6a 20                	push   $0x20
f0103f64:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103f66:	83 ef 01             	sub    $0x1,%edi
f0103f69:	83 c4 10             	add    $0x10,%esp
f0103f6c:	eb 08                	jmp    f0103f76 <vprintfmt+0x551>
f0103f6e:	89 df                	mov    %ebx,%edi
f0103f70:	8b 75 08             	mov    0x8(%ebp),%esi
f0103f73:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103f76:	85 ff                	test   %edi,%edi
f0103f78:	7f e4                	jg     f0103f5e <vprintfmt+0x539>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103f7a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103f7d:	e9 c9 fa ff ff       	jmp    f0103a4b <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103f82:	83 fa 01             	cmp    $0x1,%edx
f0103f85:	7e 16                	jle    f0103f9d <vprintfmt+0x578>
		return va_arg(*ap, long long);
f0103f87:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f8a:	8d 50 08             	lea    0x8(%eax),%edx
f0103f8d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103f90:	8b 50 04             	mov    0x4(%eax),%edx
f0103f93:	8b 00                	mov    (%eax),%eax
f0103f95:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0103f98:	89 55 cc             	mov    %edx,-0x34(%ebp)
f0103f9b:	eb 32                	jmp    f0103fcf <vprintfmt+0x5aa>
	else if (lflag)
f0103f9d:	85 d2                	test   %edx,%edx
f0103f9f:	74 18                	je     f0103fb9 <vprintfmt+0x594>
		return va_arg(*ap, long);
f0103fa1:	8b 45 14             	mov    0x14(%ebp),%eax
f0103fa4:	8d 50 04             	lea    0x4(%eax),%edx
f0103fa7:	89 55 14             	mov    %edx,0x14(%ebp)
f0103faa:	8b 00                	mov    (%eax),%eax
f0103fac:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0103faf:	89 c1                	mov    %eax,%ecx
f0103fb1:	c1 f9 1f             	sar    $0x1f,%ecx
f0103fb4:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0103fb7:	eb 16                	jmp    f0103fcf <vprintfmt+0x5aa>
	else
		return va_arg(*ap, int);
f0103fb9:	8b 45 14             	mov    0x14(%ebp),%eax
f0103fbc:	8d 50 04             	lea    0x4(%eax),%edx
f0103fbf:	89 55 14             	mov    %edx,0x14(%ebp)
f0103fc2:	8b 00                	mov    (%eax),%eax
f0103fc4:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0103fc7:	89 c1                	mov    %eax,%ecx
f0103fc9:	c1 f9 1f             	sar    $0x1f,%ecx
f0103fcc:	89 4d cc             	mov    %ecx,-0x34(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103fcf:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0103fd2:	8b 55 cc             	mov    -0x34(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103fd5:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103fda:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0103fde:	79 74                	jns    f0104054 <vprintfmt+0x62f>
				putch('-', putdat);
f0103fe0:	83 ec 08             	sub    $0x8,%esp
f0103fe3:	53                   	push   %ebx
f0103fe4:	6a 2d                	push   $0x2d
f0103fe6:	ff d6                	call   *%esi
				num = -(long long) num;
f0103fe8:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0103feb:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0103fee:	f7 d8                	neg    %eax
f0103ff0:	83 d2 00             	adc    $0x0,%edx
f0103ff3:	f7 da                	neg    %edx
f0103ff5:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103ff8:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103ffd:	eb 55                	jmp    f0104054 <vprintfmt+0x62f>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103fff:	8d 45 14             	lea    0x14(%ebp),%eax
f0104002:	e8 aa f9 ff ff       	call   f01039b1 <getuint>
			base = 10;
f0104007:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f010400c:	eb 46                	jmp    f0104054 <vprintfmt+0x62f>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f010400e:	8d 45 14             	lea    0x14(%ebp),%eax
f0104011:	e8 9b f9 ff ff       	call   f01039b1 <getuint>
			base = 8;
f0104016:	b9 08 00 00 00       	mov    $0x8,%ecx

			goto number;
f010401b:	eb 37                	jmp    f0104054 <vprintfmt+0x62f>
		// pointer
		case 'p':
			putch('0', putdat);
f010401d:	83 ec 08             	sub    $0x8,%esp
f0104020:	53                   	push   %ebx
f0104021:	6a 30                	push   $0x30
f0104023:	ff d6                	call   *%esi
			putch('x', putdat);
f0104025:	83 c4 08             	add    $0x8,%esp
f0104028:	53                   	push   %ebx
f0104029:	6a 78                	push   $0x78
f010402b:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010402d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104030:	8d 50 04             	lea    0x4(%eax),%edx
f0104033:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104036:	8b 00                	mov    (%eax),%eax
f0104038:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010403d:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0104040:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0104045:	eb 0d                	jmp    f0104054 <vprintfmt+0x62f>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0104047:	8d 45 14             	lea    0x14(%ebp),%eax
f010404a:	e8 62 f9 ff ff       	call   f01039b1 <getuint>
			base = 16;
f010404f:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104054:	83 ec 0c             	sub    $0xc,%esp
f0104057:	0f be 7d c4          	movsbl -0x3c(%ebp),%edi
f010405b:	57                   	push   %edi
f010405c:	ff 75 d0             	pushl  -0x30(%ebp)
f010405f:	51                   	push   %ecx
f0104060:	52                   	push   %edx
f0104061:	50                   	push   %eax
f0104062:	89 da                	mov    %ebx,%edx
f0104064:	89 f0                	mov    %esi,%eax
f0104066:	e8 9c f8 ff ff       	call   f0103907 <printnum>
			break;
f010406b:	83 c4 20             	add    $0x20,%esp
f010406e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104071:	e9 d5 f9 ff ff       	jmp    f0103a4b <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104076:	83 ec 08             	sub    $0x8,%esp
f0104079:	53                   	push   %ebx
f010407a:	51                   	push   %ecx
f010407b:	ff d6                	call   *%esi
			break;
f010407d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104080:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0104083:	e9 c3 f9 ff ff       	jmp    f0103a4b <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104088:	83 ec 08             	sub    $0x8,%esp
f010408b:	53                   	push   %ebx
f010408c:	6a 25                	push   $0x25
f010408e:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104090:	83 c4 10             	add    $0x10,%esp
f0104093:	eb 03                	jmp    f0104098 <vprintfmt+0x673>
f0104095:	83 ef 01             	sub    $0x1,%edi
f0104098:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f010409c:	75 f7                	jne    f0104095 <vprintfmt+0x670>
f010409e:	e9 a8 f9 ff ff       	jmp    f0103a4b <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01040a3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01040a6:	5b                   	pop    %ebx
f01040a7:	5e                   	pop    %esi
f01040a8:	5f                   	pop    %edi
f01040a9:	5d                   	pop    %ebp
f01040aa:	c3                   	ret    

f01040ab <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01040ab:	55                   	push   %ebp
f01040ac:	89 e5                	mov    %esp,%ebp
f01040ae:	83 ec 18             	sub    $0x18,%esp
f01040b1:	8b 45 08             	mov    0x8(%ebp),%eax
f01040b4:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01040b7:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01040ba:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01040be:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01040c1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01040c8:	85 c0                	test   %eax,%eax
f01040ca:	74 26                	je     f01040f2 <vsnprintf+0x47>
f01040cc:	85 d2                	test   %edx,%edx
f01040ce:	7e 22                	jle    f01040f2 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01040d0:	ff 75 14             	pushl  0x14(%ebp)
f01040d3:	ff 75 10             	pushl  0x10(%ebp)
f01040d6:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01040d9:	50                   	push   %eax
f01040da:	68 eb 39 10 f0       	push   $0xf01039eb
f01040df:	e8 41 f9 ff ff       	call   f0103a25 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01040e4:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01040e7:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01040ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01040ed:	83 c4 10             	add    $0x10,%esp
f01040f0:	eb 05                	jmp    f01040f7 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01040f2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01040f7:	c9                   	leave  
f01040f8:	c3                   	ret    

f01040f9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01040f9:	55                   	push   %ebp
f01040fa:	89 e5                	mov    %esp,%ebp
f01040fc:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01040ff:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104102:	50                   	push   %eax
f0104103:	ff 75 10             	pushl  0x10(%ebp)
f0104106:	ff 75 0c             	pushl  0xc(%ebp)
f0104109:	ff 75 08             	pushl  0x8(%ebp)
f010410c:	e8 9a ff ff ff       	call   f01040ab <vsnprintf>
	va_end(ap);

	return rc;
}
f0104111:	c9                   	leave  
f0104112:	c3                   	ret    

f0104113 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104113:	55                   	push   %ebp
f0104114:	89 e5                	mov    %esp,%ebp
f0104116:	57                   	push   %edi
f0104117:	56                   	push   %esi
f0104118:	53                   	push   %ebx
f0104119:	83 ec 0c             	sub    $0xc,%esp
f010411c:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010411f:	85 c0                	test   %eax,%eax
f0104121:	74 11                	je     f0104134 <readline+0x21>
		cprintf("%s", prompt);
f0104123:	83 ec 08             	sub    $0x8,%esp
f0104126:	50                   	push   %eax
f0104127:	68 a7 58 10 f0       	push   $0xf01058a7
f010412c:	e8 e4 ef ff ff       	call   f0103115 <cprintf>
f0104131:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104134:	83 ec 0c             	sub    $0xc,%esp
f0104137:	6a 00                	push   $0x0
f0104139:	e8 d7 c4 ff ff       	call   f0100615 <iscons>
f010413e:	89 c7                	mov    %eax,%edi
f0104140:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104143:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104148:	e8 b7 c4 ff ff       	call   f0100604 <getchar>
f010414d:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010414f:	85 c0                	test   %eax,%eax
f0104151:	79 18                	jns    f010416b <readline+0x58>
			cprintf("read error: %e\n", c);
f0104153:	83 ec 08             	sub    $0x8,%esp
f0104156:	50                   	push   %eax
f0104157:	68 a0 62 10 f0       	push   $0xf01062a0
f010415c:	e8 b4 ef ff ff       	call   f0103115 <cprintf>
			return NULL;
f0104161:	83 c4 10             	add    $0x10,%esp
f0104164:	b8 00 00 00 00       	mov    $0x0,%eax
f0104169:	eb 79                	jmp    f01041e4 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010416b:	83 f8 7f             	cmp    $0x7f,%eax
f010416e:	0f 94 c2             	sete   %dl
f0104171:	83 f8 08             	cmp    $0x8,%eax
f0104174:	0f 94 c0             	sete   %al
f0104177:	08 c2                	or     %al,%dl
f0104179:	74 1a                	je     f0104195 <readline+0x82>
f010417b:	85 f6                	test   %esi,%esi
f010417d:	7e 16                	jle    f0104195 <readline+0x82>
			if (echoing)
f010417f:	85 ff                	test   %edi,%edi
f0104181:	74 0d                	je     f0104190 <readline+0x7d>
				cputchar('\b');
f0104183:	83 ec 0c             	sub    $0xc,%esp
f0104186:	6a 08                	push   $0x8
f0104188:	e8 67 c4 ff ff       	call   f01005f4 <cputchar>
f010418d:	83 c4 10             	add    $0x10,%esp
			i--;
f0104190:	83 ee 01             	sub    $0x1,%esi
f0104193:	eb b3                	jmp    f0104148 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104195:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010419b:	7f 20                	jg     f01041bd <readline+0xaa>
f010419d:	83 fb 1f             	cmp    $0x1f,%ebx
f01041a0:	7e 1b                	jle    f01041bd <readline+0xaa>
			if (echoing)
f01041a2:	85 ff                	test   %edi,%edi
f01041a4:	74 0c                	je     f01041b2 <readline+0x9f>
				cputchar(c);
f01041a6:	83 ec 0c             	sub    $0xc,%esp
f01041a9:	53                   	push   %ebx
f01041aa:	e8 45 c4 ff ff       	call   f01005f4 <cputchar>
f01041af:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01041b2:	88 9e 00 dd 17 f0    	mov    %bl,-0xfe82300(%esi)
f01041b8:	8d 76 01             	lea    0x1(%esi),%esi
f01041bb:	eb 8b                	jmp    f0104148 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01041bd:	83 fb 0d             	cmp    $0xd,%ebx
f01041c0:	74 05                	je     f01041c7 <readline+0xb4>
f01041c2:	83 fb 0a             	cmp    $0xa,%ebx
f01041c5:	75 81                	jne    f0104148 <readline+0x35>
			if (echoing)
f01041c7:	85 ff                	test   %edi,%edi
f01041c9:	74 0d                	je     f01041d8 <readline+0xc5>
				cputchar('\n');
f01041cb:	83 ec 0c             	sub    $0xc,%esp
f01041ce:	6a 0a                	push   $0xa
f01041d0:	e8 1f c4 ff ff       	call   f01005f4 <cputchar>
f01041d5:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01041d8:	c6 86 00 dd 17 f0 00 	movb   $0x0,-0xfe82300(%esi)
			return buf;
f01041df:	b8 00 dd 17 f0       	mov    $0xf017dd00,%eax
		}
	}
}
f01041e4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01041e7:	5b                   	pop    %ebx
f01041e8:	5e                   	pop    %esi
f01041e9:	5f                   	pop    %edi
f01041ea:	5d                   	pop    %ebp
f01041eb:	c3                   	ret    

f01041ec <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01041ec:	55                   	push   %ebp
f01041ed:	89 e5                	mov    %esp,%ebp
f01041ef:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01041f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01041f7:	eb 03                	jmp    f01041fc <strlen+0x10>
		n++;
f01041f9:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01041fc:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104200:	75 f7                	jne    f01041f9 <strlen+0xd>
		n++;
	return n;
}
f0104202:	5d                   	pop    %ebp
f0104203:	c3                   	ret    

f0104204 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104204:	55                   	push   %ebp
f0104205:	89 e5                	mov    %esp,%ebp
f0104207:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010420a:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010420d:	ba 00 00 00 00       	mov    $0x0,%edx
f0104212:	eb 03                	jmp    f0104217 <strnlen+0x13>
		n++;
f0104214:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104217:	39 c2                	cmp    %eax,%edx
f0104219:	74 08                	je     f0104223 <strnlen+0x1f>
f010421b:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010421f:	75 f3                	jne    f0104214 <strnlen+0x10>
f0104221:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0104223:	5d                   	pop    %ebp
f0104224:	c3                   	ret    

f0104225 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104225:	55                   	push   %ebp
f0104226:	89 e5                	mov    %esp,%ebp
f0104228:	53                   	push   %ebx
f0104229:	8b 45 08             	mov    0x8(%ebp),%eax
f010422c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010422f:	89 c2                	mov    %eax,%edx
f0104231:	83 c2 01             	add    $0x1,%edx
f0104234:	83 c1 01             	add    $0x1,%ecx
f0104237:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010423b:	88 5a ff             	mov    %bl,-0x1(%edx)
f010423e:	84 db                	test   %bl,%bl
f0104240:	75 ef                	jne    f0104231 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104242:	5b                   	pop    %ebx
f0104243:	5d                   	pop    %ebp
f0104244:	c3                   	ret    

f0104245 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104245:	55                   	push   %ebp
f0104246:	89 e5                	mov    %esp,%ebp
f0104248:	53                   	push   %ebx
f0104249:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010424c:	53                   	push   %ebx
f010424d:	e8 9a ff ff ff       	call   f01041ec <strlen>
f0104252:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104255:	ff 75 0c             	pushl  0xc(%ebp)
f0104258:	01 d8                	add    %ebx,%eax
f010425a:	50                   	push   %eax
f010425b:	e8 c5 ff ff ff       	call   f0104225 <strcpy>
	return dst;
}
f0104260:	89 d8                	mov    %ebx,%eax
f0104262:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104265:	c9                   	leave  
f0104266:	c3                   	ret    

f0104267 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104267:	55                   	push   %ebp
f0104268:	89 e5                	mov    %esp,%ebp
f010426a:	56                   	push   %esi
f010426b:	53                   	push   %ebx
f010426c:	8b 75 08             	mov    0x8(%ebp),%esi
f010426f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104272:	89 f3                	mov    %esi,%ebx
f0104274:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104277:	89 f2                	mov    %esi,%edx
f0104279:	eb 0f                	jmp    f010428a <strncpy+0x23>
		*dst++ = *src;
f010427b:	83 c2 01             	add    $0x1,%edx
f010427e:	0f b6 01             	movzbl (%ecx),%eax
f0104281:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104284:	80 39 01             	cmpb   $0x1,(%ecx)
f0104287:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010428a:	39 da                	cmp    %ebx,%edx
f010428c:	75 ed                	jne    f010427b <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010428e:	89 f0                	mov    %esi,%eax
f0104290:	5b                   	pop    %ebx
f0104291:	5e                   	pop    %esi
f0104292:	5d                   	pop    %ebp
f0104293:	c3                   	ret    

f0104294 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104294:	55                   	push   %ebp
f0104295:	89 e5                	mov    %esp,%ebp
f0104297:	56                   	push   %esi
f0104298:	53                   	push   %ebx
f0104299:	8b 75 08             	mov    0x8(%ebp),%esi
f010429c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010429f:	8b 55 10             	mov    0x10(%ebp),%edx
f01042a2:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01042a4:	85 d2                	test   %edx,%edx
f01042a6:	74 21                	je     f01042c9 <strlcpy+0x35>
f01042a8:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01042ac:	89 f2                	mov    %esi,%edx
f01042ae:	eb 09                	jmp    f01042b9 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01042b0:	83 c2 01             	add    $0x1,%edx
f01042b3:	83 c1 01             	add    $0x1,%ecx
f01042b6:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01042b9:	39 c2                	cmp    %eax,%edx
f01042bb:	74 09                	je     f01042c6 <strlcpy+0x32>
f01042bd:	0f b6 19             	movzbl (%ecx),%ebx
f01042c0:	84 db                	test   %bl,%bl
f01042c2:	75 ec                	jne    f01042b0 <strlcpy+0x1c>
f01042c4:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01042c6:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01042c9:	29 f0                	sub    %esi,%eax
}
f01042cb:	5b                   	pop    %ebx
f01042cc:	5e                   	pop    %esi
f01042cd:	5d                   	pop    %ebp
f01042ce:	c3                   	ret    

f01042cf <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01042cf:	55                   	push   %ebp
f01042d0:	89 e5                	mov    %esp,%ebp
f01042d2:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01042d5:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01042d8:	eb 06                	jmp    f01042e0 <strcmp+0x11>
		p++, q++;
f01042da:	83 c1 01             	add    $0x1,%ecx
f01042dd:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01042e0:	0f b6 01             	movzbl (%ecx),%eax
f01042e3:	84 c0                	test   %al,%al
f01042e5:	74 04                	je     f01042eb <strcmp+0x1c>
f01042e7:	3a 02                	cmp    (%edx),%al
f01042e9:	74 ef                	je     f01042da <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01042eb:	0f b6 c0             	movzbl %al,%eax
f01042ee:	0f b6 12             	movzbl (%edx),%edx
f01042f1:	29 d0                	sub    %edx,%eax
}
f01042f3:	5d                   	pop    %ebp
f01042f4:	c3                   	ret    

f01042f5 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01042f5:	55                   	push   %ebp
f01042f6:	89 e5                	mov    %esp,%ebp
f01042f8:	53                   	push   %ebx
f01042f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01042fc:	8b 55 0c             	mov    0xc(%ebp),%edx
f01042ff:	89 c3                	mov    %eax,%ebx
f0104301:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104304:	eb 06                	jmp    f010430c <strncmp+0x17>
		n--, p++, q++;
f0104306:	83 c0 01             	add    $0x1,%eax
f0104309:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010430c:	39 d8                	cmp    %ebx,%eax
f010430e:	74 15                	je     f0104325 <strncmp+0x30>
f0104310:	0f b6 08             	movzbl (%eax),%ecx
f0104313:	84 c9                	test   %cl,%cl
f0104315:	74 04                	je     f010431b <strncmp+0x26>
f0104317:	3a 0a                	cmp    (%edx),%cl
f0104319:	74 eb                	je     f0104306 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010431b:	0f b6 00             	movzbl (%eax),%eax
f010431e:	0f b6 12             	movzbl (%edx),%edx
f0104321:	29 d0                	sub    %edx,%eax
f0104323:	eb 05                	jmp    f010432a <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104325:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010432a:	5b                   	pop    %ebx
f010432b:	5d                   	pop    %ebp
f010432c:	c3                   	ret    

f010432d <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010432d:	55                   	push   %ebp
f010432e:	89 e5                	mov    %esp,%ebp
f0104330:	8b 45 08             	mov    0x8(%ebp),%eax
f0104333:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104337:	eb 07                	jmp    f0104340 <strchr+0x13>
		if (*s == c)
f0104339:	38 ca                	cmp    %cl,%dl
f010433b:	74 0f                	je     f010434c <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010433d:	83 c0 01             	add    $0x1,%eax
f0104340:	0f b6 10             	movzbl (%eax),%edx
f0104343:	84 d2                	test   %dl,%dl
f0104345:	75 f2                	jne    f0104339 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104347:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010434c:	5d                   	pop    %ebp
f010434d:	c3                   	ret    

f010434e <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010434e:	55                   	push   %ebp
f010434f:	89 e5                	mov    %esp,%ebp
f0104351:	8b 45 08             	mov    0x8(%ebp),%eax
f0104354:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104358:	eb 03                	jmp    f010435d <strfind+0xf>
f010435a:	83 c0 01             	add    $0x1,%eax
f010435d:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104360:	84 d2                	test   %dl,%dl
f0104362:	74 04                	je     f0104368 <strfind+0x1a>
f0104364:	38 ca                	cmp    %cl,%dl
f0104366:	75 f2                	jne    f010435a <strfind+0xc>
			break;
	return (char *) s;
}
f0104368:	5d                   	pop    %ebp
f0104369:	c3                   	ret    

f010436a <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010436a:	55                   	push   %ebp
f010436b:	89 e5                	mov    %esp,%ebp
f010436d:	57                   	push   %edi
f010436e:	56                   	push   %esi
f010436f:	53                   	push   %ebx
f0104370:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104373:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104376:	85 c9                	test   %ecx,%ecx
f0104378:	74 36                	je     f01043b0 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010437a:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104380:	75 28                	jne    f01043aa <memset+0x40>
f0104382:	f6 c1 03             	test   $0x3,%cl
f0104385:	75 23                	jne    f01043aa <memset+0x40>
		c &= 0xFF;
f0104387:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010438b:	89 d3                	mov    %edx,%ebx
f010438d:	c1 e3 08             	shl    $0x8,%ebx
f0104390:	89 d6                	mov    %edx,%esi
f0104392:	c1 e6 18             	shl    $0x18,%esi
f0104395:	89 d0                	mov    %edx,%eax
f0104397:	c1 e0 10             	shl    $0x10,%eax
f010439a:	09 f0                	or     %esi,%eax
f010439c:	09 c2                	or     %eax,%edx
f010439e:	89 d0                	mov    %edx,%eax
f01043a0:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01043a2:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01043a5:	fc                   	cld    
f01043a6:	f3 ab                	rep stos %eax,%es:(%edi)
f01043a8:	eb 06                	jmp    f01043b0 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01043aa:	8b 45 0c             	mov    0xc(%ebp),%eax
f01043ad:	fc                   	cld    
f01043ae:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01043b0:	89 f8                	mov    %edi,%eax
f01043b2:	5b                   	pop    %ebx
f01043b3:	5e                   	pop    %esi
f01043b4:	5f                   	pop    %edi
f01043b5:	5d                   	pop    %ebp
f01043b6:	c3                   	ret    

f01043b7 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01043b7:	55                   	push   %ebp
f01043b8:	89 e5                	mov    %esp,%ebp
f01043ba:	57                   	push   %edi
f01043bb:	56                   	push   %esi
f01043bc:	8b 45 08             	mov    0x8(%ebp),%eax
f01043bf:	8b 75 0c             	mov    0xc(%ebp),%esi
f01043c2:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01043c5:	39 c6                	cmp    %eax,%esi
f01043c7:	73 35                	jae    f01043fe <memmove+0x47>
f01043c9:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01043cc:	39 d0                	cmp    %edx,%eax
f01043ce:	73 2e                	jae    f01043fe <memmove+0x47>
		s += n;
		d += n;
f01043d0:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01043d3:	89 d6                	mov    %edx,%esi
f01043d5:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01043d7:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01043dd:	75 13                	jne    f01043f2 <memmove+0x3b>
f01043df:	f6 c1 03             	test   $0x3,%cl
f01043e2:	75 0e                	jne    f01043f2 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01043e4:	83 ef 04             	sub    $0x4,%edi
f01043e7:	8d 72 fc             	lea    -0x4(%edx),%esi
f01043ea:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01043ed:	fd                   	std    
f01043ee:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01043f0:	eb 09                	jmp    f01043fb <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01043f2:	83 ef 01             	sub    $0x1,%edi
f01043f5:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01043f8:	fd                   	std    
f01043f9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01043fb:	fc                   	cld    
f01043fc:	eb 1d                	jmp    f010441b <memmove+0x64>
f01043fe:	89 f2                	mov    %esi,%edx
f0104400:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104402:	f6 c2 03             	test   $0x3,%dl
f0104405:	75 0f                	jne    f0104416 <memmove+0x5f>
f0104407:	f6 c1 03             	test   $0x3,%cl
f010440a:	75 0a                	jne    f0104416 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010440c:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010440f:	89 c7                	mov    %eax,%edi
f0104411:	fc                   	cld    
f0104412:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104414:	eb 05                	jmp    f010441b <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104416:	89 c7                	mov    %eax,%edi
f0104418:	fc                   	cld    
f0104419:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010441b:	5e                   	pop    %esi
f010441c:	5f                   	pop    %edi
f010441d:	5d                   	pop    %ebp
f010441e:	c3                   	ret    

f010441f <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010441f:	55                   	push   %ebp
f0104420:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0104422:	ff 75 10             	pushl  0x10(%ebp)
f0104425:	ff 75 0c             	pushl  0xc(%ebp)
f0104428:	ff 75 08             	pushl  0x8(%ebp)
f010442b:	e8 87 ff ff ff       	call   f01043b7 <memmove>
}
f0104430:	c9                   	leave  
f0104431:	c3                   	ret    

f0104432 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104432:	55                   	push   %ebp
f0104433:	89 e5                	mov    %esp,%ebp
f0104435:	56                   	push   %esi
f0104436:	53                   	push   %ebx
f0104437:	8b 45 08             	mov    0x8(%ebp),%eax
f010443a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010443d:	89 c6                	mov    %eax,%esi
f010443f:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104442:	eb 1a                	jmp    f010445e <memcmp+0x2c>
		if (*s1 != *s2)
f0104444:	0f b6 08             	movzbl (%eax),%ecx
f0104447:	0f b6 1a             	movzbl (%edx),%ebx
f010444a:	38 d9                	cmp    %bl,%cl
f010444c:	74 0a                	je     f0104458 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010444e:	0f b6 c1             	movzbl %cl,%eax
f0104451:	0f b6 db             	movzbl %bl,%ebx
f0104454:	29 d8                	sub    %ebx,%eax
f0104456:	eb 0f                	jmp    f0104467 <memcmp+0x35>
		s1++, s2++;
f0104458:	83 c0 01             	add    $0x1,%eax
f010445b:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010445e:	39 f0                	cmp    %esi,%eax
f0104460:	75 e2                	jne    f0104444 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104462:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104467:	5b                   	pop    %ebx
f0104468:	5e                   	pop    %esi
f0104469:	5d                   	pop    %ebp
f010446a:	c3                   	ret    

f010446b <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010446b:	55                   	push   %ebp
f010446c:	89 e5                	mov    %esp,%ebp
f010446e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104471:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0104474:	89 c2                	mov    %eax,%edx
f0104476:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104479:	eb 07                	jmp    f0104482 <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f010447b:	38 08                	cmp    %cl,(%eax)
f010447d:	74 07                	je     f0104486 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010447f:	83 c0 01             	add    $0x1,%eax
f0104482:	39 d0                	cmp    %edx,%eax
f0104484:	72 f5                	jb     f010447b <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104486:	5d                   	pop    %ebp
f0104487:	c3                   	ret    

f0104488 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104488:	55                   	push   %ebp
f0104489:	89 e5                	mov    %esp,%ebp
f010448b:	57                   	push   %edi
f010448c:	56                   	push   %esi
f010448d:	53                   	push   %ebx
f010448e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104491:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104494:	eb 03                	jmp    f0104499 <strtol+0x11>
		s++;
f0104496:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104499:	0f b6 01             	movzbl (%ecx),%eax
f010449c:	3c 09                	cmp    $0x9,%al
f010449e:	74 f6                	je     f0104496 <strtol+0xe>
f01044a0:	3c 20                	cmp    $0x20,%al
f01044a2:	74 f2                	je     f0104496 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01044a4:	3c 2b                	cmp    $0x2b,%al
f01044a6:	75 0a                	jne    f01044b2 <strtol+0x2a>
		s++;
f01044a8:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01044ab:	bf 00 00 00 00       	mov    $0x0,%edi
f01044b0:	eb 10                	jmp    f01044c2 <strtol+0x3a>
f01044b2:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01044b7:	3c 2d                	cmp    $0x2d,%al
f01044b9:	75 07                	jne    f01044c2 <strtol+0x3a>
		s++, neg = 1;
f01044bb:	8d 49 01             	lea    0x1(%ecx),%ecx
f01044be:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01044c2:	85 db                	test   %ebx,%ebx
f01044c4:	0f 94 c0             	sete   %al
f01044c7:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01044cd:	75 19                	jne    f01044e8 <strtol+0x60>
f01044cf:	80 39 30             	cmpb   $0x30,(%ecx)
f01044d2:	75 14                	jne    f01044e8 <strtol+0x60>
f01044d4:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01044d8:	0f 85 82 00 00 00    	jne    f0104560 <strtol+0xd8>
		s += 2, base = 16;
f01044de:	83 c1 02             	add    $0x2,%ecx
f01044e1:	bb 10 00 00 00       	mov    $0x10,%ebx
f01044e6:	eb 16                	jmp    f01044fe <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f01044e8:	84 c0                	test   %al,%al
f01044ea:	74 12                	je     f01044fe <strtol+0x76>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01044ec:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01044f1:	80 39 30             	cmpb   $0x30,(%ecx)
f01044f4:	75 08                	jne    f01044fe <strtol+0x76>
		s++, base = 8;
f01044f6:	83 c1 01             	add    $0x1,%ecx
f01044f9:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01044fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0104503:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104506:	0f b6 11             	movzbl (%ecx),%edx
f0104509:	8d 72 d0             	lea    -0x30(%edx),%esi
f010450c:	89 f3                	mov    %esi,%ebx
f010450e:	80 fb 09             	cmp    $0x9,%bl
f0104511:	77 08                	ja     f010451b <strtol+0x93>
			dig = *s - '0';
f0104513:	0f be d2             	movsbl %dl,%edx
f0104516:	83 ea 30             	sub    $0x30,%edx
f0104519:	eb 22                	jmp    f010453d <strtol+0xb5>
		else if (*s >= 'a' && *s <= 'z')
f010451b:	8d 72 9f             	lea    -0x61(%edx),%esi
f010451e:	89 f3                	mov    %esi,%ebx
f0104520:	80 fb 19             	cmp    $0x19,%bl
f0104523:	77 08                	ja     f010452d <strtol+0xa5>
			dig = *s - 'a' + 10;
f0104525:	0f be d2             	movsbl %dl,%edx
f0104528:	83 ea 57             	sub    $0x57,%edx
f010452b:	eb 10                	jmp    f010453d <strtol+0xb5>
		else if (*s >= 'A' && *s <= 'Z')
f010452d:	8d 72 bf             	lea    -0x41(%edx),%esi
f0104530:	89 f3                	mov    %esi,%ebx
f0104532:	80 fb 19             	cmp    $0x19,%bl
f0104535:	77 16                	ja     f010454d <strtol+0xc5>
			dig = *s - 'A' + 10;
f0104537:	0f be d2             	movsbl %dl,%edx
f010453a:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010453d:	3b 55 10             	cmp    0x10(%ebp),%edx
f0104540:	7d 0f                	jge    f0104551 <strtol+0xc9>
			break;
		s++, val = (val * base) + dig;
f0104542:	83 c1 01             	add    $0x1,%ecx
f0104545:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104549:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010454b:	eb b9                	jmp    f0104506 <strtol+0x7e>
f010454d:	89 c2                	mov    %eax,%edx
f010454f:	eb 02                	jmp    f0104553 <strtol+0xcb>
f0104551:	89 c2                	mov    %eax,%edx

	if (endptr)
f0104553:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104557:	74 0d                	je     f0104566 <strtol+0xde>
		*endptr = (char *) s;
f0104559:	8b 75 0c             	mov    0xc(%ebp),%esi
f010455c:	89 0e                	mov    %ecx,(%esi)
f010455e:	eb 06                	jmp    f0104566 <strtol+0xde>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104560:	84 c0                	test   %al,%al
f0104562:	75 92                	jne    f01044f6 <strtol+0x6e>
f0104564:	eb 98                	jmp    f01044fe <strtol+0x76>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0104566:	f7 da                	neg    %edx
f0104568:	85 ff                	test   %edi,%edi
f010456a:	0f 45 c2             	cmovne %edx,%eax
}
f010456d:	5b                   	pop    %ebx
f010456e:	5e                   	pop    %esi
f010456f:	5f                   	pop    %edi
f0104570:	5d                   	pop    %ebp
f0104571:	c3                   	ret    
f0104572:	66 90                	xchg   %ax,%ax
f0104574:	66 90                	xchg   %ax,%ax
f0104576:	66 90                	xchg   %ax,%ax
f0104578:	66 90                	xchg   %ax,%ax
f010457a:	66 90                	xchg   %ax,%ax
f010457c:	66 90                	xchg   %ax,%ax
f010457e:	66 90                	xchg   %ax,%ax

f0104580 <__udivdi3>:
f0104580:	55                   	push   %ebp
f0104581:	57                   	push   %edi
f0104582:	56                   	push   %esi
f0104583:	83 ec 10             	sub    $0x10,%esp
f0104586:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f010458a:	8b 7c 24 20          	mov    0x20(%esp),%edi
f010458e:	8b 74 24 24          	mov    0x24(%esp),%esi
f0104592:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0104596:	85 d2                	test   %edx,%edx
f0104598:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010459c:	89 34 24             	mov    %esi,(%esp)
f010459f:	89 c8                	mov    %ecx,%eax
f01045a1:	75 35                	jne    f01045d8 <__udivdi3+0x58>
f01045a3:	39 f1                	cmp    %esi,%ecx
f01045a5:	0f 87 bd 00 00 00    	ja     f0104668 <__udivdi3+0xe8>
f01045ab:	85 c9                	test   %ecx,%ecx
f01045ad:	89 cd                	mov    %ecx,%ebp
f01045af:	75 0b                	jne    f01045bc <__udivdi3+0x3c>
f01045b1:	b8 01 00 00 00       	mov    $0x1,%eax
f01045b6:	31 d2                	xor    %edx,%edx
f01045b8:	f7 f1                	div    %ecx
f01045ba:	89 c5                	mov    %eax,%ebp
f01045bc:	89 f0                	mov    %esi,%eax
f01045be:	31 d2                	xor    %edx,%edx
f01045c0:	f7 f5                	div    %ebp
f01045c2:	89 c6                	mov    %eax,%esi
f01045c4:	89 f8                	mov    %edi,%eax
f01045c6:	f7 f5                	div    %ebp
f01045c8:	89 f2                	mov    %esi,%edx
f01045ca:	83 c4 10             	add    $0x10,%esp
f01045cd:	5e                   	pop    %esi
f01045ce:	5f                   	pop    %edi
f01045cf:	5d                   	pop    %ebp
f01045d0:	c3                   	ret    
f01045d1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01045d8:	3b 14 24             	cmp    (%esp),%edx
f01045db:	77 7b                	ja     f0104658 <__udivdi3+0xd8>
f01045dd:	0f bd f2             	bsr    %edx,%esi
f01045e0:	83 f6 1f             	xor    $0x1f,%esi
f01045e3:	0f 84 97 00 00 00    	je     f0104680 <__udivdi3+0x100>
f01045e9:	bd 20 00 00 00       	mov    $0x20,%ebp
f01045ee:	89 d7                	mov    %edx,%edi
f01045f0:	89 f1                	mov    %esi,%ecx
f01045f2:	29 f5                	sub    %esi,%ebp
f01045f4:	d3 e7                	shl    %cl,%edi
f01045f6:	89 c2                	mov    %eax,%edx
f01045f8:	89 e9                	mov    %ebp,%ecx
f01045fa:	d3 ea                	shr    %cl,%edx
f01045fc:	89 f1                	mov    %esi,%ecx
f01045fe:	09 fa                	or     %edi,%edx
f0104600:	8b 3c 24             	mov    (%esp),%edi
f0104603:	d3 e0                	shl    %cl,%eax
f0104605:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104609:	89 e9                	mov    %ebp,%ecx
f010460b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010460f:	8b 44 24 04          	mov    0x4(%esp),%eax
f0104613:	89 fa                	mov    %edi,%edx
f0104615:	d3 ea                	shr    %cl,%edx
f0104617:	89 f1                	mov    %esi,%ecx
f0104619:	d3 e7                	shl    %cl,%edi
f010461b:	89 e9                	mov    %ebp,%ecx
f010461d:	d3 e8                	shr    %cl,%eax
f010461f:	09 c7                	or     %eax,%edi
f0104621:	89 f8                	mov    %edi,%eax
f0104623:	f7 74 24 08          	divl   0x8(%esp)
f0104627:	89 d5                	mov    %edx,%ebp
f0104629:	89 c7                	mov    %eax,%edi
f010462b:	f7 64 24 0c          	mull   0xc(%esp)
f010462f:	39 d5                	cmp    %edx,%ebp
f0104631:	89 14 24             	mov    %edx,(%esp)
f0104634:	72 11                	jb     f0104647 <__udivdi3+0xc7>
f0104636:	8b 54 24 04          	mov    0x4(%esp),%edx
f010463a:	89 f1                	mov    %esi,%ecx
f010463c:	d3 e2                	shl    %cl,%edx
f010463e:	39 c2                	cmp    %eax,%edx
f0104640:	73 5e                	jae    f01046a0 <__udivdi3+0x120>
f0104642:	3b 2c 24             	cmp    (%esp),%ebp
f0104645:	75 59                	jne    f01046a0 <__udivdi3+0x120>
f0104647:	8d 47 ff             	lea    -0x1(%edi),%eax
f010464a:	31 f6                	xor    %esi,%esi
f010464c:	89 f2                	mov    %esi,%edx
f010464e:	83 c4 10             	add    $0x10,%esp
f0104651:	5e                   	pop    %esi
f0104652:	5f                   	pop    %edi
f0104653:	5d                   	pop    %ebp
f0104654:	c3                   	ret    
f0104655:	8d 76 00             	lea    0x0(%esi),%esi
f0104658:	31 f6                	xor    %esi,%esi
f010465a:	31 c0                	xor    %eax,%eax
f010465c:	89 f2                	mov    %esi,%edx
f010465e:	83 c4 10             	add    $0x10,%esp
f0104661:	5e                   	pop    %esi
f0104662:	5f                   	pop    %edi
f0104663:	5d                   	pop    %ebp
f0104664:	c3                   	ret    
f0104665:	8d 76 00             	lea    0x0(%esi),%esi
f0104668:	89 f2                	mov    %esi,%edx
f010466a:	31 f6                	xor    %esi,%esi
f010466c:	89 f8                	mov    %edi,%eax
f010466e:	f7 f1                	div    %ecx
f0104670:	89 f2                	mov    %esi,%edx
f0104672:	83 c4 10             	add    $0x10,%esp
f0104675:	5e                   	pop    %esi
f0104676:	5f                   	pop    %edi
f0104677:	5d                   	pop    %ebp
f0104678:	c3                   	ret    
f0104679:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104680:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f0104684:	76 0b                	jbe    f0104691 <__udivdi3+0x111>
f0104686:	31 c0                	xor    %eax,%eax
f0104688:	3b 14 24             	cmp    (%esp),%edx
f010468b:	0f 83 37 ff ff ff    	jae    f01045c8 <__udivdi3+0x48>
f0104691:	b8 01 00 00 00       	mov    $0x1,%eax
f0104696:	e9 2d ff ff ff       	jmp    f01045c8 <__udivdi3+0x48>
f010469b:	90                   	nop
f010469c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01046a0:	89 f8                	mov    %edi,%eax
f01046a2:	31 f6                	xor    %esi,%esi
f01046a4:	e9 1f ff ff ff       	jmp    f01045c8 <__udivdi3+0x48>
f01046a9:	66 90                	xchg   %ax,%ax
f01046ab:	66 90                	xchg   %ax,%ax
f01046ad:	66 90                	xchg   %ax,%ax
f01046af:	90                   	nop

f01046b0 <__umoddi3>:
f01046b0:	55                   	push   %ebp
f01046b1:	57                   	push   %edi
f01046b2:	56                   	push   %esi
f01046b3:	83 ec 20             	sub    $0x20,%esp
f01046b6:	8b 44 24 34          	mov    0x34(%esp),%eax
f01046ba:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01046be:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01046c2:	89 c6                	mov    %eax,%esi
f01046c4:	89 44 24 10          	mov    %eax,0x10(%esp)
f01046c8:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f01046cc:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f01046d0:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01046d4:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f01046d8:	89 74 24 18          	mov    %esi,0x18(%esp)
f01046dc:	85 c0                	test   %eax,%eax
f01046de:	89 c2                	mov    %eax,%edx
f01046e0:	75 1e                	jne    f0104700 <__umoddi3+0x50>
f01046e2:	39 f7                	cmp    %esi,%edi
f01046e4:	76 52                	jbe    f0104738 <__umoddi3+0x88>
f01046e6:	89 c8                	mov    %ecx,%eax
f01046e8:	89 f2                	mov    %esi,%edx
f01046ea:	f7 f7                	div    %edi
f01046ec:	89 d0                	mov    %edx,%eax
f01046ee:	31 d2                	xor    %edx,%edx
f01046f0:	83 c4 20             	add    $0x20,%esp
f01046f3:	5e                   	pop    %esi
f01046f4:	5f                   	pop    %edi
f01046f5:	5d                   	pop    %ebp
f01046f6:	c3                   	ret    
f01046f7:	89 f6                	mov    %esi,%esi
f01046f9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0104700:	39 f0                	cmp    %esi,%eax
f0104702:	77 5c                	ja     f0104760 <__umoddi3+0xb0>
f0104704:	0f bd e8             	bsr    %eax,%ebp
f0104707:	83 f5 1f             	xor    $0x1f,%ebp
f010470a:	75 64                	jne    f0104770 <__umoddi3+0xc0>
f010470c:	8b 6c 24 14          	mov    0x14(%esp),%ebp
f0104710:	39 6c 24 0c          	cmp    %ebp,0xc(%esp)
f0104714:	0f 86 f6 00 00 00    	jbe    f0104810 <__umoddi3+0x160>
f010471a:	3b 44 24 18          	cmp    0x18(%esp),%eax
f010471e:	0f 82 ec 00 00 00    	jb     f0104810 <__umoddi3+0x160>
f0104724:	8b 44 24 14          	mov    0x14(%esp),%eax
f0104728:	8b 54 24 18          	mov    0x18(%esp),%edx
f010472c:	83 c4 20             	add    $0x20,%esp
f010472f:	5e                   	pop    %esi
f0104730:	5f                   	pop    %edi
f0104731:	5d                   	pop    %ebp
f0104732:	c3                   	ret    
f0104733:	90                   	nop
f0104734:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104738:	85 ff                	test   %edi,%edi
f010473a:	89 fd                	mov    %edi,%ebp
f010473c:	75 0b                	jne    f0104749 <__umoddi3+0x99>
f010473e:	b8 01 00 00 00       	mov    $0x1,%eax
f0104743:	31 d2                	xor    %edx,%edx
f0104745:	f7 f7                	div    %edi
f0104747:	89 c5                	mov    %eax,%ebp
f0104749:	8b 44 24 10          	mov    0x10(%esp),%eax
f010474d:	31 d2                	xor    %edx,%edx
f010474f:	f7 f5                	div    %ebp
f0104751:	89 c8                	mov    %ecx,%eax
f0104753:	f7 f5                	div    %ebp
f0104755:	eb 95                	jmp    f01046ec <__umoddi3+0x3c>
f0104757:	89 f6                	mov    %esi,%esi
f0104759:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0104760:	89 c8                	mov    %ecx,%eax
f0104762:	89 f2                	mov    %esi,%edx
f0104764:	83 c4 20             	add    $0x20,%esp
f0104767:	5e                   	pop    %esi
f0104768:	5f                   	pop    %edi
f0104769:	5d                   	pop    %ebp
f010476a:	c3                   	ret    
f010476b:	90                   	nop
f010476c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104770:	b8 20 00 00 00       	mov    $0x20,%eax
f0104775:	89 e9                	mov    %ebp,%ecx
f0104777:	29 e8                	sub    %ebp,%eax
f0104779:	d3 e2                	shl    %cl,%edx
f010477b:	89 c7                	mov    %eax,%edi
f010477d:	89 44 24 18          	mov    %eax,0x18(%esp)
f0104781:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0104785:	89 f9                	mov    %edi,%ecx
f0104787:	d3 e8                	shr    %cl,%eax
f0104789:	89 c1                	mov    %eax,%ecx
f010478b:	8b 44 24 0c          	mov    0xc(%esp),%eax
f010478f:	09 d1                	or     %edx,%ecx
f0104791:	89 fa                	mov    %edi,%edx
f0104793:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0104797:	89 e9                	mov    %ebp,%ecx
f0104799:	d3 e0                	shl    %cl,%eax
f010479b:	89 f9                	mov    %edi,%ecx
f010479d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01047a1:	89 f0                	mov    %esi,%eax
f01047a3:	d3 e8                	shr    %cl,%eax
f01047a5:	89 e9                	mov    %ebp,%ecx
f01047a7:	89 c7                	mov    %eax,%edi
f01047a9:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f01047ad:	d3 e6                	shl    %cl,%esi
f01047af:	89 d1                	mov    %edx,%ecx
f01047b1:	89 fa                	mov    %edi,%edx
f01047b3:	d3 e8                	shr    %cl,%eax
f01047b5:	89 e9                	mov    %ebp,%ecx
f01047b7:	09 f0                	or     %esi,%eax
f01047b9:	8b 74 24 1c          	mov    0x1c(%esp),%esi
f01047bd:	f7 74 24 10          	divl   0x10(%esp)
f01047c1:	d3 e6                	shl    %cl,%esi
f01047c3:	89 d1                	mov    %edx,%ecx
f01047c5:	f7 64 24 0c          	mull   0xc(%esp)
f01047c9:	39 d1                	cmp    %edx,%ecx
f01047cb:	89 74 24 14          	mov    %esi,0x14(%esp)
f01047cf:	89 d7                	mov    %edx,%edi
f01047d1:	89 c6                	mov    %eax,%esi
f01047d3:	72 0a                	jb     f01047df <__umoddi3+0x12f>
f01047d5:	39 44 24 14          	cmp    %eax,0x14(%esp)
f01047d9:	73 10                	jae    f01047eb <__umoddi3+0x13b>
f01047db:	39 d1                	cmp    %edx,%ecx
f01047dd:	75 0c                	jne    f01047eb <__umoddi3+0x13b>
f01047df:	89 d7                	mov    %edx,%edi
f01047e1:	89 c6                	mov    %eax,%esi
f01047e3:	2b 74 24 0c          	sub    0xc(%esp),%esi
f01047e7:	1b 7c 24 10          	sbb    0x10(%esp),%edi
f01047eb:	89 ca                	mov    %ecx,%edx
f01047ed:	89 e9                	mov    %ebp,%ecx
f01047ef:	8b 44 24 14          	mov    0x14(%esp),%eax
f01047f3:	29 f0                	sub    %esi,%eax
f01047f5:	19 fa                	sbb    %edi,%edx
f01047f7:	d3 e8                	shr    %cl,%eax
f01047f9:	0f b6 4c 24 18       	movzbl 0x18(%esp),%ecx
f01047fe:	89 d7                	mov    %edx,%edi
f0104800:	d3 e7                	shl    %cl,%edi
f0104802:	89 e9                	mov    %ebp,%ecx
f0104804:	09 f8                	or     %edi,%eax
f0104806:	d3 ea                	shr    %cl,%edx
f0104808:	83 c4 20             	add    $0x20,%esp
f010480b:	5e                   	pop    %esi
f010480c:	5f                   	pop    %edi
f010480d:	5d                   	pop    %ebp
f010480e:	c3                   	ret    
f010480f:	90                   	nop
f0104810:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104814:	29 f9                	sub    %edi,%ecx
f0104816:	19 c6                	sbb    %eax,%esi
f0104818:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f010481c:	89 74 24 18          	mov    %esi,0x18(%esp)
f0104820:	e9 ff fe ff ff       	jmp    f0104724 <__umoddi3+0x74>
