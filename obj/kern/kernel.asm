
obj/kern/kernel：     文件格式 elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
# bootloader to jump to the *physical* address of the entry point.
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# physical addresses [0, 4MB).  This 4MB region will be
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
f0100015:	b8 00 90 11 00       	mov    $0x119000,%eax
	movl	$(RELOC(entry_pgdir)), %eax
f010001a:	0f 22 d8             	mov    %eax,%cr3
	movl	%eax, %cr3
	# Turn on paging.
f010001d:	0f 20 c0             	mov    %cr0,%eax
	movl	%cr0, %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100025:	0f 22 c0             	mov    %eax,%cr0
	movl	%eax, %cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	mov	$relocated, %eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
	jmp	*%eax
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp
	movl	$0x0,%ebp			# nuke frame pointer

	# Set the stack pointer
f0100034:	bc 00 90 11 f0       	mov    $0xf0119000,%esp
	movl	$(bootstacktop),%esp

	# now to C code
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:
	call	i386_init

	# Should never get here, but in case we do, just spin.
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
f0100046:	b8 d0 e0 17 f0       	mov    $0xf017e0d0,%eax
f010004b:	2d 46 d1 17 f0       	sub    $0xf017d146,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 46 d1 17 f0       	push   $0xf017d146
f0100058:	e8 bf 42 00 00       	call   f010431c <memset>
//	int x = 1, y = 3, z = 4;
//	cprintf("x %d, y %x, z %d\n", x, y, z);
	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 99 04 00 00       	call   f01004fb <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 00 48 10 f0       	push   $0xf0104800
f010006f:	e8 43 31 00 00       	call   f01031b7 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 d0 11 00 00       	call   f0101249 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 1a 2b 00 00       	call   f0102b98 <env_init>
	//cprintf("for debug 1: reach here ! Hi, mingming! Jiayou Jiayou!");
	trap_init();
f010007e:	e8 a5 31 00 00       	call   f0103228 <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 56 b3 11 f0       	push   $0xf011b356
f010008d:	e8 a3 2c 00 00       	call   f0102d35 <env_create>
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 e8 d3 17 f0    	pushl  0xf017d3e8
f010009b:	e8 40 30 00 00       	call   f01030e0 <env_run>

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
f01000a8:	83 3d c0 e0 17 f0 00 	cmpl   $0x0,0xf017e0c0
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 c0 e0 17 f0    	mov    %esi,0xf017e0c0

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
f01000c5:	68 1b 48 10 f0       	push   $0xf010481b
f01000ca:	e8 e8 30 00 00       	call   f01031b7 <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 b8 30 00 00       	call   f0103191 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 fa 5a 10 f0 	movl   $0xf0105afa,(%esp)
f01000e0:	e8 d2 30 00 00       	call   f01031b7 <cprintf>
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
f0100107:	68 33 48 10 f0       	push   $0xf0104833
f010010c:	e8 a6 30 00 00       	call   f01031b7 <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 74 30 00 00       	call   f0103191 <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 fa 5a 10 f0 	movl   $0xf0105afa,(%esp)
f0100124:	e8 8e 30 00 00       	call   f01031b7 <cprintf>
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
f010015c:	a1 c4 d3 17 f0       	mov    0xf017d3c4,%eax
f0100161:	8d 48 01             	lea    0x1(%eax),%ecx
f0100164:	89 0d c4 d3 17 f0    	mov    %ecx,0xf017d3c4
f010016a:	88 90 c0 d1 17 f0    	mov    %dl,-0xfe82e40(%eax)
		if (cons.wpos == CONSBUFSIZE)
f0100170:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100176:	75 0a                	jne    f0100182 <cons_intr+0x35>
			cons.wpos = 0;
f0100178:	c7 05 c4 d3 17 f0 00 	movl   $0x0,0xf017d3c4
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
f01001a8:	83 0d 80 d1 17 f0 40 	orl    $0x40,0xf017d180
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
f01001c0:	8b 0d 80 d1 17 f0    	mov    0xf017d180,%ecx
f01001c6:	89 cb                	mov    %ecx,%ebx
f01001c8:	83 e3 40             	and    $0x40,%ebx
f01001cb:	83 e0 7f             	and    $0x7f,%eax
f01001ce:	85 db                	test   %ebx,%ebx
f01001d0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001d3:	0f b6 d2             	movzbl %dl,%edx
f01001d6:	0f b6 82 c0 49 10 f0 	movzbl -0xfefb640(%edx),%eax
f01001dd:	83 c8 40             	or     $0x40,%eax
f01001e0:	0f b6 c0             	movzbl %al,%eax
f01001e3:	f7 d0                	not    %eax
f01001e5:	21 c8                	and    %ecx,%eax
f01001e7:	a3 80 d1 17 f0       	mov    %eax,0xf017d180
		return 0;
f01001ec:	b8 00 00 00 00       	mov    $0x0,%eax
f01001f1:	e9 a1 00 00 00       	jmp    f0100297 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001f6:	8b 0d 80 d1 17 f0    	mov    0xf017d180,%ecx
f01001fc:	f6 c1 40             	test   $0x40,%cl
f01001ff:	74 0e                	je     f010020f <kbd_proc_data+0x7e>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100201:	83 c8 80             	or     $0xffffff80,%eax
f0100204:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100206:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100209:	89 0d 80 d1 17 f0    	mov    %ecx,0xf017d180
	}

	shift |= shiftcode[data];
f010020f:	0f b6 c2             	movzbl %dl,%eax
f0100212:	0f b6 90 c0 49 10 f0 	movzbl -0xfefb640(%eax),%edx
f0100219:	0b 15 80 d1 17 f0    	or     0xf017d180,%edx
	shift ^= togglecode[data];
f010021f:	0f b6 88 c0 48 10 f0 	movzbl -0xfefb740(%eax),%ecx
f0100226:	31 ca                	xor    %ecx,%edx
f0100228:	89 15 80 d1 17 f0    	mov    %edx,0xf017d180

	c = charcode[shift & (CTL | SHIFT)][data];
f010022e:	89 d1                	mov    %edx,%ecx
f0100230:	83 e1 03             	and    $0x3,%ecx
f0100233:	8b 0c 8d 80 48 10 f0 	mov    -0xfefb780(,%ecx,4),%ecx
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
f0100273:	68 4d 48 10 f0       	push   $0xf010484d
f0100278:	e8 3a 2f 00 00       	call   f01031b7 <cprintf>
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
f0100317:	a1 ac dc 17 f0       	mov    0xf017dcac,%eax
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
f0100359:	0f b7 15 c8 d3 17 f0 	movzwl 0xf017d3c8,%edx
f0100360:	66 85 d2             	test   %dx,%dx
f0100363:	0f 84 e4 00 00 00    	je     f010044d <cons_putc+0x1b1>
			crt_pos--;
f0100369:	83 ea 01             	sub    $0x1,%edx
f010036c:	66 89 15 c8 d3 17 f0 	mov    %dx,0xf017d3c8
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100373:	0f b7 d2             	movzwl %dx,%edx
f0100376:	b0 00                	mov    $0x0,%al
f0100378:	83 c8 20             	or     $0x20,%eax
f010037b:	8b 0d cc d3 17 f0    	mov    0xf017d3cc,%ecx
f0100381:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f0100385:	eb 78                	jmp    f01003ff <cons_putc+0x163>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100387:	66 83 05 c8 d3 17 f0 	addw   $0x50,0xf017d3c8
f010038e:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038f:	0f b7 05 c8 d3 17 f0 	movzwl 0xf017d3c8,%eax
f0100396:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010039c:	c1 e8 16             	shr    $0x16,%eax
f010039f:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003a2:	c1 e0 04             	shl    $0x4,%eax
f01003a5:	66 a3 c8 d3 17 f0    	mov    %ax,0xf017d3c8
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
f01003e1:	0f b7 15 c8 d3 17 f0 	movzwl 0xf017d3c8,%edx
f01003e8:	8d 4a 01             	lea    0x1(%edx),%ecx
f01003eb:	66 89 0d c8 d3 17 f0 	mov    %cx,0xf017d3c8
f01003f2:	0f b7 d2             	movzwl %dx,%edx
f01003f5:	8b 0d cc d3 17 f0    	mov    0xf017d3cc,%ecx
f01003fb:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003ff:	66 81 3d c8 d3 17 f0 	cmpw   $0x7cf,0xf017d3c8
f0100406:	cf 07 
f0100408:	76 43                	jbe    f010044d <cons_putc+0x1b1>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010040a:	a1 cc d3 17 f0       	mov    0xf017d3cc,%eax
f010040f:	83 ec 04             	sub    $0x4,%esp
f0100412:	68 00 0f 00 00       	push   $0xf00
f0100417:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041d:	52                   	push   %edx
f010041e:	50                   	push   %eax
f010041f:	e8 45 3f 00 00       	call   f0104369 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100424:	8b 15 cc d3 17 f0    	mov    0xf017d3cc,%edx
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
f0100445:	66 83 2d c8 d3 17 f0 	subw   $0x50,0xf017d3c8
f010044c:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044d:	8b 0d d0 d3 17 f0    	mov    0xf017d3d0,%ecx
f0100453:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100458:	89 ca                	mov    %ecx,%edx
f010045a:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010045b:	0f b7 1d c8 d3 17 f0 	movzwl 0xf017d3c8,%ebx
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
f0100483:	80 3d d4 d3 17 f0 00 	cmpb   $0x0,0xf017d3d4
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
f01004c1:	a1 c0 d3 17 f0       	mov    0xf017d3c0,%eax
f01004c6:	3b 05 c4 d3 17 f0    	cmp    0xf017d3c4,%eax
f01004cc:	74 26                	je     f01004f4 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004ce:	8d 50 01             	lea    0x1(%eax),%edx
f01004d1:	89 15 c0 d3 17 f0    	mov    %edx,0xf017d3c0
f01004d7:	0f b6 88 c0 d1 17 f0 	movzbl -0xfe82e40(%eax),%ecx
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
f01004e8:	c7 05 c0 d3 17 f0 00 	movl   $0x0,0xf017d3c0
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
f0100521:	c7 05 d0 d3 17 f0 b4 	movl   $0x3b4,0xf017d3d0
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
f0100539:	c7 05 d0 d3 17 f0 d4 	movl   $0x3d4,0xf017d3d0
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
f0100548:	8b 3d d0 d3 17 f0    	mov    0xf017d3d0,%edi
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
f010056f:	89 35 cc d3 17 f0    	mov    %esi,0xf017d3cc

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
f010057c:	66 a3 c8 d3 17 f0    	mov    %ax,0xf017d3c8
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
f01005cc:	88 0d d4 d3 17 f0    	mov    %cl,0xf017d3d4
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
f01005df:	68 59 48 10 f0       	push   $0xf0104859
f01005e4:	e8 ce 2b 00 00       	call   f01031b7 <cprintf>
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
f0100661:	68 c0 4a 10 f0       	push   $0xf0104ac0
f0100666:	e8 4c 2b 00 00       	call   f01031b7 <cprintf>
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
f0100691:	68 d9 4a 10 f0       	push   $0xf0104ad9
f0100696:	e8 1c 2b 00 00       	call   f01031b7 <cprintf>
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
f01006ba:	bb 84 4f 10 f0       	mov    $0xf0104f84,%ebx
f01006bf:	be cc 4f 10 f0       	mov    $0xf0104fcc,%esi
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006c4:	83 ec 04             	sub    $0x4,%esp
f01006c7:	ff 33                	pushl  (%ebx)
f01006c9:	ff 73 fc             	pushl  -0x4(%ebx)
f01006cc:	68 e9 4a 10 f0       	push   $0xf0104ae9
f01006d1:	e8 e1 2a 00 00       	call   f01031b7 <cprintf>
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
f01006f2:	68 f2 4a 10 f0       	push   $0xf0104af2
f01006f7:	e8 bb 2a 00 00       	call   f01031b7 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006fc:	83 c4 08             	add    $0x8,%esp
f01006ff:	68 0c 00 10 00       	push   $0x10000c
f0100704:	68 48 4c 10 f0       	push   $0xf0104c48
f0100709:	e8 a9 2a 00 00       	call   f01031b7 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010070e:	83 c4 0c             	add    $0xc,%esp
f0100711:	68 0c 00 10 00       	push   $0x10000c
f0100716:	68 0c 00 10 f0       	push   $0xf010000c
f010071b:	68 70 4c 10 f0       	push   $0xf0104c70
f0100720:	e8 92 2a 00 00       	call   f01031b7 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100725:	83 c4 0c             	add    $0xc,%esp
f0100728:	68 d5 47 10 00       	push   $0x1047d5
f010072d:	68 d5 47 10 f0       	push   $0xf01047d5
f0100732:	68 94 4c 10 f0       	push   $0xf0104c94
f0100737:	e8 7b 2a 00 00       	call   f01031b7 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010073c:	83 c4 0c             	add    $0xc,%esp
f010073f:	68 46 d1 17 00       	push   $0x17d146
f0100744:	68 46 d1 17 f0       	push   $0xf017d146
f0100749:	68 b8 4c 10 f0       	push   $0xf0104cb8
f010074e:	e8 64 2a 00 00       	call   f01031b7 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100753:	83 c4 0c             	add    $0xc,%esp
f0100756:	68 d0 e0 17 00       	push   $0x17e0d0
f010075b:	68 d0 e0 17 f0       	push   $0xf017e0d0
f0100760:	68 dc 4c 10 f0       	push   $0xf0104cdc
f0100765:	e8 4d 2a 00 00       	call   f01031b7 <cprintf>
f010076a:	b8 cf e4 17 f0       	mov    $0xf017e4cf,%eax
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
f010078b:	68 00 4d 10 f0       	push   $0xf0104d00
f0100790:	e8 22 2a 00 00       	call   f01031b7 <cprintf>
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
f01007ad:	68 2c 4d 10 f0       	push   $0xf0104d2c
f01007b2:	e8 00 2a 00 00       	call   f01031b7 <cprintf>
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
f01007ca:	ff 35 c8 e0 17 f0    	pushl  0xf017e0c8
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
f01007e9:	68 54 4d 10 f0       	push   $0xf0104d54
f01007ee:	e8 c4 29 00 00       	call   f01031b7 <cprintf>
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
f010084b:	68 78 4d 10 f0       	push   $0xf0104d78
f0100850:	e8 62 29 00 00       	call   f01031b7 <cprintf>
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
f0100876:	68 0b 4b 10 f0       	push   $0xf0104b0b
f010087b:	e8 37 29 00 00       	call   f01031b7 <cprintf>
	for(; begin <= end; begin += PGSIZE){
f0100880:	83 c4 10             	add    $0x10,%esp
f0100883:	eb 79                	jmp    f01008fe <showmap+0xc8>
		pte_t *pte = pgdir_walk(kern_pgdir,(void*)begin, 1);
f0100885:	83 ec 04             	sub    $0x4,%esp
f0100888:	6a 01                	push   $0x1
f010088a:	53                   	push   %ebx
f010088b:	ff 35 c8 e0 17 f0    	pushl  0xf017e0c8
f0100891:	e8 91 07 00 00       	call   f0101027 <pgdir_walk>
f0100896:	89 c6                	mov    %eax,%esi
		if(!pte) panic("boot map region panic, out of memory");
f0100898:	83 c4 10             	add    $0x10,%esp
f010089b:	85 c0                	test   %eax,%eax
f010089d:	75 14                	jne    f01008b3 <showmap+0x7d>
f010089f:	83 ec 04             	sub    $0x4,%esp
f01008a2:	68 a8 4d 10 f0       	push   $0xf0104da8
f01008a7:	6a 2e                	push   $0x2e
f01008a9:	68 20 4b 10 f0       	push   $0xf0104b20
f01008ae:	e8 ed f7 ff ff       	call   f01000a0 <_panic>
		if(*pte & PTE_P){
f01008b3:	f6 00 01             	testb  $0x1,(%eax)
f01008b6:	74 2f                	je     f01008e7 <showmap+0xb1>
			cprintf("page %x with ", begin);
f01008b8:	83 ec 08             	sub    $0x8,%esp
f01008bb:	53                   	push   %ebx
f01008bc:	68 2f 4b 10 f0       	push   $0xf0104b2f
f01008c1:	e8 f1 28 00 00       	call   f01031b7 <cprintf>
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
f01008d8:	68 54 4d 10 f0       	push   $0xf0104d54
f01008dd:	e8 d5 28 00 00       	call   f01031b7 <cprintf>
f01008e2:	83 c4 20             	add    $0x20,%esp
f01008e5:	eb 11                	jmp    f01008f8 <showmap+0xc2>
		}
		else{
			cprintf("page not exist: %x\n",begin);
f01008e7:	83 ec 08             	sub    $0x8,%esp
f01008ea:	53                   	push   %ebx
f01008eb:	68 3d 4b 10 f0       	push   $0xf0104b3d
f01008f0:	e8 c2 28 00 00       	call   f01031b7 <cprintf>
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
f010091f:	68 51 4b 10 f0       	push   $0xf0104b51
f0100924:	e8 8e 28 00 00       	call   f01031b7 <cprintf>
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
f0100943:	68 d0 4d 10 f0       	push   $0xf0104dd0
f0100948:	e8 6a 28 00 00       	call   f01031b7 <cprintf>
		struct Eipdebuginfo info;
		debuginfo_eip(*eip,&info);
f010094d:	83 c4 18             	add    $0x18,%esp
f0100950:	57                   	push   %edi
f0100951:	ff 36                	pushl  (%esi)
f0100953:	e8 1f 2d 00 00       	call   f0103677 <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,(*eip) - info.eip_fn_addr);
f0100958:	83 c4 08             	add    $0x8,%esp
f010095b:	8b 06                	mov    (%esi),%eax
f010095d:	2b 45 e0             	sub    -0x20(%ebp),%eax
f0100960:	50                   	push   %eax
f0100961:	ff 75 d8             	pushl  -0x28(%ebp)
f0100964:	ff 75 dc             	pushl  -0x24(%ebp)
f0100967:	ff 75 d4             	pushl  -0x2c(%ebp)
f010096a:	ff 75 d0             	pushl  -0x30(%ebp)
f010096d:	68 63 4b 10 f0       	push   $0xf0104b63
f0100972:	e8 40 28 00 00       	call   f01031b7 <cprintf>
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
f0100999:	68 04 4e 10 f0       	push   $0xf0104e04
f010099e:	e8 14 28 00 00       	call   f01031b7 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01009a3:	c7 04 24 28 4e 10 f0 	movl   $0xf0104e28,(%esp)
f01009aa:	e8 08 28 00 00       	call   f01031b7 <cprintf>

	if (tf != NULL)
f01009af:	83 c4 10             	add    $0x10,%esp
f01009b2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01009b6:	74 0e                	je     f01009c6 <monitor+0x36>
		print_trapframe(tf);
f01009b8:	83 ec 0c             	sub    $0xc,%esp
f01009bb:	ff 75 08             	pushl  0x8(%ebp)
f01009be:	e8 fd 28 00 00       	call   f01032c0 <print_trapframe>
f01009c3:	83 c4 10             	add    $0x10,%esp

	cprintf("%Ccyn Colored scheme with no highlight.\n");
f01009c6:	83 ec 0c             	sub    $0xc,%esp
f01009c9:	68 50 4e 10 f0       	push   $0xf0104e50
f01009ce:	e8 e4 27 00 00       	call   f01031b7 <cprintf>
	cprintf("%Cble Hello%Cred World. %Cmag Test for colorization.\n");
f01009d3:	c7 04 24 7c 4e 10 f0 	movl   $0xf0104e7c,(%esp)
f01009da:	e8 d8 27 00 00       	call   f01031b7 <cprintf>
	cprintf("%Ibrw Colored scheme with highlight.\n");
f01009df:	c7 04 24 b4 4e 10 f0 	movl   $0xf0104eb4,(%esp)
f01009e6:	e8 cc 27 00 00       	call   f01031b7 <cprintf>
	cprintf("%Ible Hello%Ired World. %Imag Test for colorization.\n");
f01009eb:	c7 04 24 dc 4e 10 f0 	movl   $0xf0104edc,(%esp)
f01009f2:	e8 c0 27 00 00       	call   f01031b7 <cprintf>
	cprintf("%Cwht Return to default!\n");
f01009f7:	c7 04 24 74 4b 10 f0 	movl   $0xf0104b74,(%esp)
f01009fe:	e8 b4 27 00 00       	call   f01031b7 <cprintf>
f0100a03:	83 c4 10             	add    $0x10,%esp
	while (1) {
		buf = readline("K> ");
f0100a06:	83 ec 0c             	sub    $0xc,%esp
f0100a09:	68 8e 4b 10 f0       	push   $0xf0104b8e
f0100a0e:	e8 b2 36 00 00       	call   f01040c5 <readline>
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
f0100a42:	68 92 4b 10 f0       	push   $0xf0104b92
f0100a47:	e8 93 38 00 00       	call   f01042df <strchr>
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
f0100a62:	68 97 4b 10 f0       	push   $0xf0104b97
f0100a67:	e8 4b 27 00 00       	call   f01031b7 <cprintf>
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
f0100a8b:	68 92 4b 10 f0       	push   $0xf0104b92
f0100a90:	e8 4a 38 00 00       	call   f01042df <strchr>
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
f0100ab9:	ff 34 85 80 4f 10 f0 	pushl  -0xfefb080(,%eax,4)
f0100ac0:	ff 75 a8             	pushl  -0x58(%ebp)
f0100ac3:	e8 b9 37 00 00       	call   f0104281 <strcmp>
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
f0100add:	ff 14 85 88 4f 10 f0 	call   *-0xfefb078(,%eax,4)
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
f0100aff:	68 b4 4b 10 f0       	push   $0xf0104bb4
f0100b04:	e8 ae 26 00 00       	call   f01031b7 <cprintf>
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
f0100b2f:	3b 0d c4 e0 17 f0    	cmp    0xf017e0c4,%ecx
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
f0100b3e:	68 c8 4f 10 f0       	push   $0xf0104fc8
f0100b43:	68 32 03 00 00       	push   $0x332
f0100b48:	68 1d 58 10 f0       	push   $0xf010581d
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
f0100b83:	83 3d d8 d3 17 f0 00 	cmpl   $0x0,0xf017d3d8
f0100b8a:	75 11                	jne    f0100b9d <boot_alloc+0x20>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100b8c:	ba cf f0 17 f0       	mov    $0xf017f0cf,%edx
f0100b91:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b97:	89 15 d8 d3 17 f0    	mov    %edx,0xf017d3d8
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	
	if(n != 0){
f0100b9d:	85 c0                	test   %eax,%eax
f0100b9f:	74 5f                	je     f0100c00 <boot_alloc+0x83>
		char *start = nextfree;
f0100ba1:	8b 0d d8 d3 17 f0    	mov    0xf017d3d8,%ecx
		nextfree += n;
		nextfree = ROUNDUP((char*)nextfree, PGSIZE);
f0100ba7:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f0100bae:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100bb4:	89 15 d8 d3 17 f0    	mov    %edx,0xf017d3d8
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100bba:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0100bc0:	77 12                	ja     f0100bd4 <boot_alloc+0x57>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100bc2:	52                   	push   %edx
f0100bc3:	68 ec 4f 10 f0       	push   $0xf0104fec
f0100bc8:	6a 6d                	push   $0x6d
f0100bca:	68 1d 58 10 f0       	push   $0xf010581d
f0100bcf:	e8 cc f4 ff ff       	call   f01000a0 <_panic>
		if(PADDR(nextfree) > npages * PGSIZE){
f0100bd4:	a1 c4 e0 17 f0       	mov    0xf017e0c4,%eax
f0100bd9:	c1 e0 0c             	shl    $0xc,%eax
	return (physaddr_t)kva - KERNBASE;
f0100bdc:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0100be2:	39 d0                	cmp    %edx,%eax
f0100be4:	73 21                	jae    f0100c07 <boot_alloc+0x8a>
			nextfree = start;
f0100be6:	89 0d d8 d3 17 f0    	mov    %ecx,0xf017d3d8
			panic("Run out of memory");
f0100bec:	83 ec 04             	sub    $0x4,%esp
f0100bef:	68 29 58 10 f0       	push   $0xf0105829
f0100bf4:	6a 6f                	push   $0x6f
f0100bf6:	68 1d 58 10 f0       	push   $0xf010581d
f0100bfb:	e8 a0 f4 ff ff       	call   f01000a0 <_panic>
		}
		return start;
	}
	else{
		return nextfree;
f0100c00:	a1 d8 d3 17 f0       	mov    0xf017d3d8,%eax
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
f0100c24:	68 10 50 10 f0       	push   $0xf0105010
f0100c29:	68 6d 02 00 00       	push   $0x26d
f0100c2e:	68 1d 58 10 f0       	push   $0xf010581d
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
f0100c46:	2b 15 cc e0 17 f0    	sub    0xf017e0cc,%edx
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
f0100c7c:	a3 dc d3 17 f0       	mov    %eax,0xf017d3dc
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
f0100c86:	8b 1d dc d3 17 f0    	mov    0xf017d3dc,%ebx
f0100c8c:	eb 53                	jmp    f0100ce1 <check_page_free_list+0xd6>
f0100c8e:	89 d8                	mov    %ebx,%eax
f0100c90:	2b 05 cc e0 17 f0    	sub    0xf017e0cc,%eax
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
f0100caa:	3b 15 c4 e0 17 f0    	cmp    0xf017e0c4,%edx
f0100cb0:	72 12                	jb     f0100cc4 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cb2:	50                   	push   %eax
f0100cb3:	68 c8 4f 10 f0       	push   $0xf0104fc8
f0100cb8:	6a 56                	push   $0x56
f0100cba:	68 3b 58 10 f0       	push   $0xf010583b
f0100cbf:	e8 dc f3 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100cc4:	83 ec 04             	sub    $0x4,%esp
f0100cc7:	68 80 00 00 00       	push   $0x80
f0100ccc:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100cd1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100cd6:	50                   	push   %eax
f0100cd7:	e8 40 36 00 00       	call   f010431c <memset>
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
f0100cf2:	8b 15 dc d3 17 f0    	mov    0xf017d3dc,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100cf8:	8b 0d cc e0 17 f0    	mov    0xf017e0cc,%ecx
		assert(pp < pages + npages);
f0100cfe:	a1 c4 e0 17 f0       	mov    0xf017e0c4,%eax
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
f0100d22:	68 49 58 10 f0       	push   $0xf0105849
f0100d27:	68 55 58 10 f0       	push   $0xf0105855
f0100d2c:	68 87 02 00 00       	push   $0x287
f0100d31:	68 1d 58 10 f0       	push   $0xf010581d
f0100d36:	e8 65 f3 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100d3b:	39 da                	cmp    %ebx,%edx
f0100d3d:	72 19                	jb     f0100d58 <check_page_free_list+0x14d>
f0100d3f:	68 6a 58 10 f0       	push   $0xf010586a
f0100d44:	68 55 58 10 f0       	push   $0xf0105855
f0100d49:	68 88 02 00 00       	push   $0x288
f0100d4e:	68 1d 58 10 f0       	push   $0xf010581d
f0100d53:	e8 48 f3 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d58:	89 d0                	mov    %edx,%eax
f0100d5a:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100d5d:	a8 07                	test   $0x7,%al
f0100d5f:	74 19                	je     f0100d7a <check_page_free_list+0x16f>
f0100d61:	68 34 50 10 f0       	push   $0xf0105034
f0100d66:	68 55 58 10 f0       	push   $0xf0105855
f0100d6b:	68 89 02 00 00       	push   $0x289
f0100d70:	68 1d 58 10 f0       	push   $0xf010581d
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
f0100d84:	68 7e 58 10 f0       	push   $0xf010587e
f0100d89:	68 55 58 10 f0       	push   $0xf0105855
f0100d8e:	68 8c 02 00 00       	push   $0x28c
f0100d93:	68 1d 58 10 f0       	push   $0xf010581d
f0100d98:	e8 03 f3 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d9d:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100da2:	75 19                	jne    f0100dbd <check_page_free_list+0x1b2>
f0100da4:	68 8f 58 10 f0       	push   $0xf010588f
f0100da9:	68 55 58 10 f0       	push   $0xf0105855
f0100dae:	68 8d 02 00 00       	push   $0x28d
f0100db3:	68 1d 58 10 f0       	push   $0xf010581d
f0100db8:	e8 e3 f2 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100dbd:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100dc2:	75 19                	jne    f0100ddd <check_page_free_list+0x1d2>
f0100dc4:	68 68 50 10 f0       	push   $0xf0105068
f0100dc9:	68 55 58 10 f0       	push   $0xf0105855
f0100dce:	68 8e 02 00 00       	push   $0x28e
f0100dd3:	68 1d 58 10 f0       	push   $0xf010581d
f0100dd8:	e8 c3 f2 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100ddd:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100de2:	75 19                	jne    f0100dfd <check_page_free_list+0x1f2>
f0100de4:	68 a8 58 10 f0       	push   $0xf01058a8
f0100de9:	68 55 58 10 f0       	push   $0xf0105855
f0100dee:	68 8f 02 00 00       	push   $0x28f
f0100df3:	68 1d 58 10 f0       	push   $0xf010581d
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
f0100e12:	68 c8 4f 10 f0       	push   $0xf0104fc8
f0100e17:	6a 56                	push   $0x56
f0100e19:	68 3b 58 10 f0       	push   $0xf010583b
f0100e1e:	e8 7d f2 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0100e23:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e28:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100e2b:	76 1e                	jbe    f0100e4b <check_page_free_list+0x240>
f0100e2d:	68 8c 50 10 f0       	push   $0xf010508c
f0100e32:	68 55 58 10 f0       	push   $0xf0105855
f0100e37:	68 90 02 00 00       	push   $0x290
f0100e3c:	68 1d 58 10 f0       	push   $0xf010581d
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
f0100e60:	68 c2 58 10 f0       	push   $0xf01058c2
f0100e65:	68 55 58 10 f0       	push   $0xf0105855
f0100e6a:	68 98 02 00 00       	push   $0x298
f0100e6f:	68 1d 58 10 f0       	push   $0xf010581d
f0100e74:	e8 27 f2 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100e79:	85 f6                	test   %esi,%esi
f0100e7b:	7f 42                	jg     f0100ebf <check_page_free_list+0x2b4>
f0100e7d:	68 d4 58 10 f0       	push   $0xf01058d4
f0100e82:	68 55 58 10 f0       	push   $0xf0105855
f0100e87:	68 99 02 00 00       	push   $0x299
f0100e8c:	68 1d 58 10 f0       	push   $0xf010581d
f0100e91:	e8 0a f2 ff ff       	call   f01000a0 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100e96:	a1 dc d3 17 f0       	mov    0xf017d3dc,%eax
f0100e9b:	85 c0                	test   %eax,%eax
f0100e9d:	0f 85 95 fd ff ff    	jne    f0100c38 <check_page_free_list+0x2d>
f0100ea3:	e9 79 fd ff ff       	jmp    f0100c21 <check_page_free_list+0x16>
f0100ea8:	83 3d dc d3 17 f0 00 	cmpl   $0x0,0xf017d3dc
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
f0100efd:	68 ec 4f 10 f0       	push   $0xf0104fec
f0100f02:	68 32 01 00 00       	push   $0x132
f0100f07:	68 1d 58 10 f0       	push   $0xf010581d
f0100f0c:	e8 8f f1 ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100f11:	05 00 00 00 10       	add    $0x10000000,%eax
f0100f16:	39 c7                	cmp    %eax,%edi
f0100f18:	72 22                	jb     f0100f3c <page_init+0x75>
		pages[i].pp_ref = 0;
f0100f1a:	89 d8                	mov    %ebx,%eax
f0100f1c:	03 05 cc e0 17 f0    	add    0xf017e0cc,%eax
f0100f22:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
		pages[i].pp_link = page_free_list;
f0100f28:	8b 15 dc d3 17 f0    	mov    0xf017d3dc,%edx
f0100f2e:	89 10                	mov    %edx,(%eax)
		page_free_list = &pages[i];
f0100f30:	03 1d cc e0 17 f0    	add    0xf017e0cc,%ebx
f0100f36:	89 1d dc d3 17 f0    	mov    %ebx,0xf017d3dc
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 1; i < npages; i++) {
f0100f3c:	83 c6 01             	add    $0x1,%esi
f0100f3f:	3b 35 c4 e0 17 f0    	cmp    0xf017e0c4,%esi
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
f0100f56:	8b 1d dc d3 17 f0    	mov    0xf017d3dc,%ebx
f0100f5c:	85 db                	test   %ebx,%ebx
f0100f5e:	74 58                	je     f0100fb8 <page_alloc+0x69>
	struct PageInfo *ret = page_free_list; //fetch the head of the page list
	page_free_list = page_free_list->pp_link;
f0100f60:	8b 03                	mov    (%ebx),%eax
f0100f62:	a3 dc d3 17 f0       	mov    %eax,0xf017d3dc
	if(alloc_flags && ALLOC_ZERO){
f0100f67:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100f6b:	74 45                	je     f0100fb2 <page_alloc+0x63>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f6d:	89 d8                	mov    %ebx,%eax
f0100f6f:	2b 05 cc e0 17 f0    	sub    0xf017e0cc,%eax
f0100f75:	c1 f8 03             	sar    $0x3,%eax
f0100f78:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f7b:	89 c2                	mov    %eax,%edx
f0100f7d:	c1 ea 0c             	shr    $0xc,%edx
f0100f80:	3b 15 c4 e0 17 f0    	cmp    0xf017e0c4,%edx
f0100f86:	72 12                	jb     f0100f9a <page_alloc+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f88:	50                   	push   %eax
f0100f89:	68 c8 4f 10 f0       	push   $0xf0104fc8
f0100f8e:	6a 56                	push   $0x56
f0100f90:	68 3b 58 10 f0       	push   $0xf010583b
f0100f95:	e8 06 f1 ff ff       	call   f01000a0 <_panic>
		memset(page2kva(ret), '\0', PGSIZE);
f0100f9a:	83 ec 04             	sub    $0x4,%esp
f0100f9d:	68 00 10 00 00       	push   $0x1000
f0100fa2:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0100fa4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100fa9:	50                   	push   %eax
f0100faa:	e8 6d 33 00 00       	call   f010431c <memset>
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
f0100fd7:	68 d4 50 10 f0       	push   $0xf01050d4
f0100fdc:	68 5f 01 00 00       	push   $0x15f
f0100fe1:	68 1d 58 10 f0       	push   $0xf010581d
f0100fe6:	e8 b5 f0 ff ff       	call   f01000a0 <_panic>
	}
	pp->pp_ref = 0;
f0100feb:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
	struct PageInfo* tmp = page_free_list;
f0100ff1:	8b 15 dc d3 17 f0    	mov    0xf017d3dc,%edx
	page_free_list = pp;
f0100ff7:	a3 dc d3 17 f0       	mov    %eax,0xf017d3dc
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
f0101064:	2b 05 cc e0 17 f0    	sub    0xf017e0cc,%eax
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
f0101081:	3b 15 c4 e0 17 f0    	cmp    0xf017e0c4,%edx
f0101087:	72 15                	jb     f010109e <pgdir_walk+0x77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101089:	50                   	push   %eax
f010108a:	68 c8 4f 10 f0       	push   $0xf0104fc8
f010108f:	68 9e 01 00 00       	push   $0x19e
f0101094:	68 1d 58 10 f0       	push   $0xf010581d
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
f0101100:	68 04 51 10 f0       	push   $0xf0105104
f0101105:	68 b6 01 00 00       	push   $0x1b6
f010110a:	68 1d 58 10 f0       	push   $0xf010581d
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
f010115f:	3b 05 c4 e0 17 f0    	cmp    0xf017e0c4,%eax
f0101165:	72 14                	jb     f010117b <page_lookup+0x4a>
		panic("pa2page called with invalid pa");
f0101167:	83 ec 04             	sub    $0x4,%esp
f010116a:	68 34 51 10 f0       	push   $0xf0105134
f010116f:	6a 4f                	push   $0x4f
f0101171:	68 3b 58 10 f0       	push   $0xf010583b
f0101176:	e8 25 ef ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f010117b:	8b 15 cc e0 17 f0    	mov    0xf017e0cc,%edx
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
f0101225:	2b 05 cc e0 17 f0    	sub    0xf017e0cc,%eax
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
f0101254:	e8 fd 1e 00 00       	call   f0103156 <mc146818_read>
f0101259:	89 c3                	mov    %eax,%ebx
f010125b:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101262:	e8 ef 1e 00 00       	call   f0103156 <mc146818_read>
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
f010127d:	a3 e0 d3 17 f0       	mov    %eax,0xf017d3e0
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101282:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101289:	e8 c8 1e 00 00       	call   f0103156 <mc146818_read>
f010128e:	89 c6                	mov    %eax,%esi
f0101290:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101297:	e8 ba 1e 00 00       	call   f0103156 <mc146818_read>
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
f01012b8:	ff 35 e0 d3 17 f0    	pushl  0xf017d3e0
f01012be:	68 54 51 10 f0       	push   $0xf0105154
f01012c3:	e8 ef 1e 00 00       	call   f01031b7 <cprintf>

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01012c8:	83 c4 10             	add    $0x10,%esp
f01012cb:	85 db                	test   %ebx,%ebx
f01012cd:	74 0d                	je     f01012dc <mem_init+0x93>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01012cf:	8d 83 00 01 00 00    	lea    0x100(%ebx),%eax
f01012d5:	a3 c4 e0 17 f0       	mov    %eax,0xf017e0c4
f01012da:	eb 0a                	jmp    f01012e6 <mem_init+0x9d>
	else
		npages = npages_basemem;
f01012dc:	a1 e0 d3 17 f0       	mov    0xf017d3e0,%eax
f01012e1:	a3 c4 e0 17 f0       	mov    %eax,0xf017e0c4

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
f01012ed:	a1 e0 d3 17 f0       	mov    0xf017d3e0,%eax
f01012f2:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012f5:	c1 e8 0a             	shr    $0xa,%eax
f01012f8:	50                   	push   %eax
		npages * PGSIZE / 1024,
f01012f9:	a1 c4 e0 17 f0       	mov    0xf017e0c4,%eax
f01012fe:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101301:	c1 e8 0a             	shr    $0xa,%eax
f0101304:	50                   	push   %eax
f0101305:	68 7c 51 10 f0       	push   $0xf010517c
f010130a:	e8 a8 1e 00 00       	call   f01031b7 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010130f:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101314:	e8 64 f8 ff ff       	call   f0100b7d <boot_alloc>
f0101319:	a3 c8 e0 17 f0       	mov    %eax,0xf017e0c8
	memset(kern_pgdir, 0, PGSIZE);
f010131e:	83 c4 0c             	add    $0xc,%esp
f0101321:	68 00 10 00 00       	push   $0x1000
f0101326:	6a 00                	push   $0x0
f0101328:	50                   	push   %eax
f0101329:	e8 ee 2f 00 00       	call   f010431c <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010132e:	a1 c8 e0 17 f0       	mov    0xf017e0c8,%eax
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
f010133e:	68 ec 4f 10 f0       	push   $0xf0104fec
f0101343:	68 9a 00 00 00       	push   $0x9a
f0101348:	68 1d 58 10 f0       	push   $0xf010581d
f010134d:	e8 4e ed ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101352:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101358:	83 ca 05             	or     $0x5,%edx
f010135b:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	cprintf("UVPT is %x\n" ,UVPT);
f0101361:	83 ec 08             	sub    $0x8,%esp
f0101364:	68 00 00 40 ef       	push   $0xef400000
f0101369:	68 e5 58 10 f0       	push   $0xf01058e5
f010136e:	e8 44 1e 00 00       	call   f01031b7 <cprintf>
	cprintf("UPAGES is %x\n", UPAGES);
f0101373:	83 c4 08             	add    $0x8,%esp
f0101376:	68 00 00 00 ef       	push   $0xef000000
f010137b:	68 f1 58 10 f0       	push   $0xf01058f1
f0101380:	e8 32 1e 00 00       	call   f01031b7 <cprintf>
	cprintf("Physical address of kern_pgdir: %x\n", PADDR(kern_pgdir));
f0101385:	a1 c8 e0 17 f0       	mov    0xf017e0c8,%eax
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
f0101395:	68 ec 4f 10 f0       	push   $0xf0104fec
f010139a:	68 9d 00 00 00       	push   $0x9d
f010139f:	68 1d 58 10 f0       	push   $0xf010581d
f01013a4:	e8 f7 ec ff ff       	call   f01000a0 <_panic>
f01013a9:	83 ec 08             	sub    $0x8,%esp
	return (physaddr_t)kva - KERNBASE;
f01013ac:	05 00 00 00 10       	add    $0x10000000,%eax
f01013b1:	50                   	push   %eax
f01013b2:	68 b8 51 10 f0       	push   $0xf01051b8
f01013b7:	e8 fb 1d 00 00       	call   f01031b7 <cprintf>
	cprintf("Virtual address of kern_pgdir: %x\n", kern_pgdir);
f01013bc:	83 c4 08             	add    $0x8,%esp
f01013bf:	ff 35 c8 e0 17 f0    	pushl  0xf017e0c8
f01013c5:	68 dc 51 10 f0       	push   $0xf01051dc
f01013ca:	e8 e8 1d 00 00       	call   f01031b7 <cprintf>
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:

	pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
f01013cf:	a1 c4 e0 17 f0       	mov    0xf017e0c4,%eax
f01013d4:	c1 e0 03             	shl    $0x3,%eax
f01013d7:	e8 a1 f7 ff ff       	call   f0100b7d <boot_alloc>
f01013dc:	a3 cc e0 17 f0       	mov    %eax,0xf017e0cc
	memset(pages, 0, npages*sizeof(struct PageInfo));
f01013e1:	83 c4 0c             	add    $0xc,%esp
f01013e4:	8b 3d c4 e0 17 f0    	mov    0xf017e0c4,%edi
f01013ea:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f01013f1:	52                   	push   %edx
f01013f2:	6a 00                	push   $0x0
f01013f4:	50                   	push   %eax
f01013f5:	e8 22 2f 00 00       	call   f010431c <memset>
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env*)boot_alloc(NENV * sizeof(struct Env));	
f01013fa:	b8 00 80 01 00       	mov    $0x18000,%eax
f01013ff:	e8 79 f7 ff ff       	call   f0100b7d <boot_alloc>
f0101404:	a3 e8 d3 17 f0       	mov    %eax,0xf017d3e8
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
f010141b:	83 3d cc e0 17 f0 00 	cmpl   $0x0,0xf017e0cc
f0101422:	75 17                	jne    f010143b <mem_init+0x1f2>
		panic("'pages' is a null pointer!");
f0101424:	83 ec 04             	sub    $0x4,%esp
f0101427:	68 ff 58 10 f0       	push   $0xf01058ff
f010142c:	68 aa 02 00 00       	push   $0x2aa
f0101431:	68 1d 58 10 f0       	push   $0xf010581d
f0101436:	e8 65 ec ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010143b:	a1 dc d3 17 f0       	mov    0xf017d3dc,%eax
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
f0101463:	68 1a 59 10 f0       	push   $0xf010591a
f0101468:	68 55 58 10 f0       	push   $0xf0105855
f010146d:	68 b2 02 00 00       	push   $0x2b2
f0101472:	68 1d 58 10 f0       	push   $0xf010581d
f0101477:	e8 24 ec ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010147c:	83 ec 0c             	sub    $0xc,%esp
f010147f:	6a 00                	push   $0x0
f0101481:	e8 c9 fa ff ff       	call   f0100f4f <page_alloc>
f0101486:	89 c6                	mov    %eax,%esi
f0101488:	83 c4 10             	add    $0x10,%esp
f010148b:	85 c0                	test   %eax,%eax
f010148d:	75 19                	jne    f01014a8 <mem_init+0x25f>
f010148f:	68 30 59 10 f0       	push   $0xf0105930
f0101494:	68 55 58 10 f0       	push   $0xf0105855
f0101499:	68 b3 02 00 00       	push   $0x2b3
f010149e:	68 1d 58 10 f0       	push   $0xf010581d
f01014a3:	e8 f8 eb ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01014a8:	83 ec 0c             	sub    $0xc,%esp
f01014ab:	6a 00                	push   $0x0
f01014ad:	e8 9d fa ff ff       	call   f0100f4f <page_alloc>
f01014b2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014b5:	83 c4 10             	add    $0x10,%esp
f01014b8:	85 c0                	test   %eax,%eax
f01014ba:	75 19                	jne    f01014d5 <mem_init+0x28c>
f01014bc:	68 46 59 10 f0       	push   $0xf0105946
f01014c1:	68 55 58 10 f0       	push   $0xf0105855
f01014c6:	68 b4 02 00 00       	push   $0x2b4
f01014cb:	68 1d 58 10 f0       	push   $0xf010581d
f01014d0:	e8 cb eb ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01014d5:	39 f7                	cmp    %esi,%edi
f01014d7:	75 19                	jne    f01014f2 <mem_init+0x2a9>
f01014d9:	68 5c 59 10 f0       	push   $0xf010595c
f01014de:	68 55 58 10 f0       	push   $0xf0105855
f01014e3:	68 b7 02 00 00       	push   $0x2b7
f01014e8:	68 1d 58 10 f0       	push   $0xf010581d
f01014ed:	e8 ae eb ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014f2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014f5:	39 c7                	cmp    %eax,%edi
f01014f7:	74 04                	je     f01014fd <mem_init+0x2b4>
f01014f9:	39 c6                	cmp    %eax,%esi
f01014fb:	75 19                	jne    f0101516 <mem_init+0x2cd>
f01014fd:	68 00 52 10 f0       	push   $0xf0105200
f0101502:	68 55 58 10 f0       	push   $0xf0105855
f0101507:	68 b8 02 00 00       	push   $0x2b8
f010150c:	68 1d 58 10 f0       	push   $0xf010581d
f0101511:	e8 8a eb ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101516:	8b 0d cc e0 17 f0    	mov    0xf017e0cc,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010151c:	8b 15 c4 e0 17 f0    	mov    0xf017e0c4,%edx
f0101522:	c1 e2 0c             	shl    $0xc,%edx
f0101525:	89 f8                	mov    %edi,%eax
f0101527:	29 c8                	sub    %ecx,%eax
f0101529:	c1 f8 03             	sar    $0x3,%eax
f010152c:	c1 e0 0c             	shl    $0xc,%eax
f010152f:	39 d0                	cmp    %edx,%eax
f0101531:	72 19                	jb     f010154c <mem_init+0x303>
f0101533:	68 6e 59 10 f0       	push   $0xf010596e
f0101538:	68 55 58 10 f0       	push   $0xf0105855
f010153d:	68 b9 02 00 00       	push   $0x2b9
f0101542:	68 1d 58 10 f0       	push   $0xf010581d
f0101547:	e8 54 eb ff ff       	call   f01000a0 <_panic>
f010154c:	89 f0                	mov    %esi,%eax
f010154e:	29 c8                	sub    %ecx,%eax
f0101550:	c1 f8 03             	sar    $0x3,%eax
f0101553:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f0101556:	39 c2                	cmp    %eax,%edx
f0101558:	77 19                	ja     f0101573 <mem_init+0x32a>
f010155a:	68 8b 59 10 f0       	push   $0xf010598b
f010155f:	68 55 58 10 f0       	push   $0xf0105855
f0101564:	68 ba 02 00 00       	push   $0x2ba
f0101569:	68 1d 58 10 f0       	push   $0xf010581d
f010156e:	e8 2d eb ff ff       	call   f01000a0 <_panic>
f0101573:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101576:	29 c8                	sub    %ecx,%eax
f0101578:	c1 f8 03             	sar    $0x3,%eax
f010157b:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f010157e:	39 c2                	cmp    %eax,%edx
f0101580:	77 19                	ja     f010159b <mem_init+0x352>
f0101582:	68 a8 59 10 f0       	push   $0xf01059a8
f0101587:	68 55 58 10 f0       	push   $0xf0105855
f010158c:	68 bb 02 00 00       	push   $0x2bb
f0101591:	68 1d 58 10 f0       	push   $0xf010581d
f0101596:	e8 05 eb ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010159b:	a1 dc d3 17 f0       	mov    0xf017d3dc,%eax
f01015a0:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01015a3:	c7 05 dc d3 17 f0 00 	movl   $0x0,0xf017d3dc
f01015aa:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01015ad:	83 ec 0c             	sub    $0xc,%esp
f01015b0:	6a 00                	push   $0x0
f01015b2:	e8 98 f9 ff ff       	call   f0100f4f <page_alloc>
f01015b7:	83 c4 10             	add    $0x10,%esp
f01015ba:	85 c0                	test   %eax,%eax
f01015bc:	74 19                	je     f01015d7 <mem_init+0x38e>
f01015be:	68 c5 59 10 f0       	push   $0xf01059c5
f01015c3:	68 55 58 10 f0       	push   $0xf0105855
f01015c8:	68 c2 02 00 00       	push   $0x2c2
f01015cd:	68 1d 58 10 f0       	push   $0xf010581d
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
f0101608:	68 1a 59 10 f0       	push   $0xf010591a
f010160d:	68 55 58 10 f0       	push   $0xf0105855
f0101612:	68 c9 02 00 00       	push   $0x2c9
f0101617:	68 1d 58 10 f0       	push   $0xf010581d
f010161c:	e8 7f ea ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101621:	83 ec 0c             	sub    $0xc,%esp
f0101624:	6a 00                	push   $0x0
f0101626:	e8 24 f9 ff ff       	call   f0100f4f <page_alloc>
f010162b:	89 c7                	mov    %eax,%edi
f010162d:	83 c4 10             	add    $0x10,%esp
f0101630:	85 c0                	test   %eax,%eax
f0101632:	75 19                	jne    f010164d <mem_init+0x404>
f0101634:	68 30 59 10 f0       	push   $0xf0105930
f0101639:	68 55 58 10 f0       	push   $0xf0105855
f010163e:	68 ca 02 00 00       	push   $0x2ca
f0101643:	68 1d 58 10 f0       	push   $0xf010581d
f0101648:	e8 53 ea ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010164d:	83 ec 0c             	sub    $0xc,%esp
f0101650:	6a 00                	push   $0x0
f0101652:	e8 f8 f8 ff ff       	call   f0100f4f <page_alloc>
f0101657:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010165a:	83 c4 10             	add    $0x10,%esp
f010165d:	85 c0                	test   %eax,%eax
f010165f:	75 19                	jne    f010167a <mem_init+0x431>
f0101661:	68 46 59 10 f0       	push   $0xf0105946
f0101666:	68 55 58 10 f0       	push   $0xf0105855
f010166b:	68 cb 02 00 00       	push   $0x2cb
f0101670:	68 1d 58 10 f0       	push   $0xf010581d
f0101675:	e8 26 ea ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010167a:	39 fe                	cmp    %edi,%esi
f010167c:	75 19                	jne    f0101697 <mem_init+0x44e>
f010167e:	68 5c 59 10 f0       	push   $0xf010595c
f0101683:	68 55 58 10 f0       	push   $0xf0105855
f0101688:	68 cd 02 00 00       	push   $0x2cd
f010168d:	68 1d 58 10 f0       	push   $0xf010581d
f0101692:	e8 09 ea ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101697:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010169a:	39 c6                	cmp    %eax,%esi
f010169c:	74 04                	je     f01016a2 <mem_init+0x459>
f010169e:	39 c7                	cmp    %eax,%edi
f01016a0:	75 19                	jne    f01016bb <mem_init+0x472>
f01016a2:	68 00 52 10 f0       	push   $0xf0105200
f01016a7:	68 55 58 10 f0       	push   $0xf0105855
f01016ac:	68 ce 02 00 00       	push   $0x2ce
f01016b1:	68 1d 58 10 f0       	push   $0xf010581d
f01016b6:	e8 e5 e9 ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f01016bb:	83 ec 0c             	sub    $0xc,%esp
f01016be:	6a 00                	push   $0x0
f01016c0:	e8 8a f8 ff ff       	call   f0100f4f <page_alloc>
f01016c5:	83 c4 10             	add    $0x10,%esp
f01016c8:	85 c0                	test   %eax,%eax
f01016ca:	74 19                	je     f01016e5 <mem_init+0x49c>
f01016cc:	68 c5 59 10 f0       	push   $0xf01059c5
f01016d1:	68 55 58 10 f0       	push   $0xf0105855
f01016d6:	68 cf 02 00 00       	push   $0x2cf
f01016db:	68 1d 58 10 f0       	push   $0xf010581d
f01016e0:	e8 bb e9 ff ff       	call   f01000a0 <_panic>
f01016e5:	89 f0                	mov    %esi,%eax
f01016e7:	2b 05 cc e0 17 f0    	sub    0xf017e0cc,%eax
f01016ed:	c1 f8 03             	sar    $0x3,%eax
f01016f0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01016f3:	89 c2                	mov    %eax,%edx
f01016f5:	c1 ea 0c             	shr    $0xc,%edx
f01016f8:	3b 15 c4 e0 17 f0    	cmp    0xf017e0c4,%edx
f01016fe:	72 12                	jb     f0101712 <mem_init+0x4c9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101700:	50                   	push   %eax
f0101701:	68 c8 4f 10 f0       	push   $0xf0104fc8
f0101706:	6a 56                	push   $0x56
f0101708:	68 3b 58 10 f0       	push   $0xf010583b
f010170d:	e8 8e e9 ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101712:	83 ec 04             	sub    $0x4,%esp
f0101715:	68 00 10 00 00       	push   $0x1000
f010171a:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f010171c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101721:	50                   	push   %eax
f0101722:	e8 f5 2b 00 00       	call   f010431c <memset>
	page_free(pp0);
f0101727:	89 34 24             	mov    %esi,(%esp)
f010172a:	e8 90 f8 ff ff       	call   f0100fbf <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010172f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101736:	e8 14 f8 ff ff       	call   f0100f4f <page_alloc>
f010173b:	83 c4 10             	add    $0x10,%esp
f010173e:	85 c0                	test   %eax,%eax
f0101740:	75 19                	jne    f010175b <mem_init+0x512>
f0101742:	68 d4 59 10 f0       	push   $0xf01059d4
f0101747:	68 55 58 10 f0       	push   $0xf0105855
f010174c:	68 d4 02 00 00       	push   $0x2d4
f0101751:	68 1d 58 10 f0       	push   $0xf010581d
f0101756:	e8 45 e9 ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f010175b:	39 c6                	cmp    %eax,%esi
f010175d:	74 19                	je     f0101778 <mem_init+0x52f>
f010175f:	68 f2 59 10 f0       	push   $0xf01059f2
f0101764:	68 55 58 10 f0       	push   $0xf0105855
f0101769:	68 d5 02 00 00       	push   $0x2d5
f010176e:	68 1d 58 10 f0       	push   $0xf010581d
f0101773:	e8 28 e9 ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101778:	89 f0                	mov    %esi,%eax
f010177a:	2b 05 cc e0 17 f0    	sub    0xf017e0cc,%eax
f0101780:	c1 f8 03             	sar    $0x3,%eax
f0101783:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101786:	89 c2                	mov    %eax,%edx
f0101788:	c1 ea 0c             	shr    $0xc,%edx
f010178b:	3b 15 c4 e0 17 f0    	cmp    0xf017e0c4,%edx
f0101791:	72 12                	jb     f01017a5 <mem_init+0x55c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101793:	50                   	push   %eax
f0101794:	68 c8 4f 10 f0       	push   $0xf0104fc8
f0101799:	6a 56                	push   $0x56
f010179b:	68 3b 58 10 f0       	push   $0xf010583b
f01017a0:	e8 fb e8 ff ff       	call   f01000a0 <_panic>
f01017a5:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01017ab:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01017b1:	80 38 00             	cmpb   $0x0,(%eax)
f01017b4:	74 19                	je     f01017cf <mem_init+0x586>
f01017b6:	68 02 5a 10 f0       	push   $0xf0105a02
f01017bb:	68 55 58 10 f0       	push   $0xf0105855
f01017c0:	68 d8 02 00 00       	push   $0x2d8
f01017c5:	68 1d 58 10 f0       	push   $0xf010581d
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
f01017d9:	a3 dc d3 17 f0       	mov    %eax,0xf017d3dc

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
f01017fa:	a1 dc d3 17 f0       	mov    0xf017d3dc,%eax
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
f0101811:	68 0c 5a 10 f0       	push   $0xf0105a0c
f0101816:	68 55 58 10 f0       	push   $0xf0105855
f010181b:	68 e5 02 00 00       	push   $0x2e5
f0101820:	68 1d 58 10 f0       	push   $0xf010581d
f0101825:	e8 76 e8 ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010182a:	83 ec 0c             	sub    $0xc,%esp
f010182d:	68 20 52 10 f0       	push   $0xf0105220
f0101832:	e8 80 19 00 00       	call   f01031b7 <cprintf>
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
f010184d:	68 1a 59 10 f0       	push   $0xf010591a
f0101852:	68 55 58 10 f0       	push   $0xf0105855
f0101857:	68 46 03 00 00       	push   $0x346
f010185c:	68 1d 58 10 f0       	push   $0xf010581d
f0101861:	e8 3a e8 ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101866:	83 ec 0c             	sub    $0xc,%esp
f0101869:	6a 00                	push   $0x0
f010186b:	e8 df f6 ff ff       	call   f0100f4f <page_alloc>
f0101870:	89 c3                	mov    %eax,%ebx
f0101872:	83 c4 10             	add    $0x10,%esp
f0101875:	85 c0                	test   %eax,%eax
f0101877:	75 19                	jne    f0101892 <mem_init+0x649>
f0101879:	68 30 59 10 f0       	push   $0xf0105930
f010187e:	68 55 58 10 f0       	push   $0xf0105855
f0101883:	68 47 03 00 00       	push   $0x347
f0101888:	68 1d 58 10 f0       	push   $0xf010581d
f010188d:	e8 0e e8 ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101892:	83 ec 0c             	sub    $0xc,%esp
f0101895:	6a 00                	push   $0x0
f0101897:	e8 b3 f6 ff ff       	call   f0100f4f <page_alloc>
f010189c:	89 c6                	mov    %eax,%esi
f010189e:	83 c4 10             	add    $0x10,%esp
f01018a1:	85 c0                	test   %eax,%eax
f01018a3:	75 19                	jne    f01018be <mem_init+0x675>
f01018a5:	68 46 59 10 f0       	push   $0xf0105946
f01018aa:	68 55 58 10 f0       	push   $0xf0105855
f01018af:	68 48 03 00 00       	push   $0x348
f01018b4:	68 1d 58 10 f0       	push   $0xf010581d
f01018b9:	e8 e2 e7 ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01018be:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01018c1:	75 19                	jne    f01018dc <mem_init+0x693>
f01018c3:	68 5c 59 10 f0       	push   $0xf010595c
f01018c8:	68 55 58 10 f0       	push   $0xf0105855
f01018cd:	68 4b 03 00 00       	push   $0x34b
f01018d2:	68 1d 58 10 f0       	push   $0xf010581d
f01018d7:	e8 c4 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018dc:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01018df:	74 04                	je     f01018e5 <mem_init+0x69c>
f01018e1:	39 c3                	cmp    %eax,%ebx
f01018e3:	75 19                	jne    f01018fe <mem_init+0x6b5>
f01018e5:	68 00 52 10 f0       	push   $0xf0105200
f01018ea:	68 55 58 10 f0       	push   $0xf0105855
f01018ef:	68 4c 03 00 00       	push   $0x34c
f01018f4:	68 1d 58 10 f0       	push   $0xf010581d
f01018f9:	e8 a2 e7 ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01018fe:	a1 dc d3 17 f0       	mov    0xf017d3dc,%eax
f0101903:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101906:	c7 05 dc d3 17 f0 00 	movl   $0x0,0xf017d3dc
f010190d:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101910:	83 ec 0c             	sub    $0xc,%esp
f0101913:	6a 00                	push   $0x0
f0101915:	e8 35 f6 ff ff       	call   f0100f4f <page_alloc>
f010191a:	83 c4 10             	add    $0x10,%esp
f010191d:	85 c0                	test   %eax,%eax
f010191f:	74 19                	je     f010193a <mem_init+0x6f1>
f0101921:	68 c5 59 10 f0       	push   $0xf01059c5
f0101926:	68 55 58 10 f0       	push   $0xf0105855
f010192b:	68 53 03 00 00       	push   $0x353
f0101930:	68 1d 58 10 f0       	push   $0xf010581d
f0101935:	e8 66 e7 ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010193a:	83 ec 04             	sub    $0x4,%esp
f010193d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101940:	50                   	push   %eax
f0101941:	6a 00                	push   $0x0
f0101943:	ff 35 c8 e0 17 f0    	pushl  0xf017e0c8
f0101949:	e8 e3 f7 ff ff       	call   f0101131 <page_lookup>
f010194e:	83 c4 10             	add    $0x10,%esp
f0101951:	85 c0                	test   %eax,%eax
f0101953:	74 19                	je     f010196e <mem_init+0x725>
f0101955:	68 40 52 10 f0       	push   $0xf0105240
f010195a:	68 55 58 10 f0       	push   $0xf0105855
f010195f:	68 56 03 00 00       	push   $0x356
f0101964:	68 1d 58 10 f0       	push   $0xf010581d
f0101969:	e8 32 e7 ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010196e:	6a 02                	push   $0x2
f0101970:	6a 00                	push   $0x0
f0101972:	53                   	push   %ebx
f0101973:	ff 35 c8 e0 17 f0    	pushl  0xf017e0c8
f0101979:	e8 63 f8 ff ff       	call   f01011e1 <page_insert>
f010197e:	83 c4 10             	add    $0x10,%esp
f0101981:	85 c0                	test   %eax,%eax
f0101983:	78 19                	js     f010199e <mem_init+0x755>
f0101985:	68 78 52 10 f0       	push   $0xf0105278
f010198a:	68 55 58 10 f0       	push   $0xf0105855
f010198f:	68 59 03 00 00       	push   $0x359
f0101994:	68 1d 58 10 f0       	push   $0xf010581d
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
f01019ae:	ff 35 c8 e0 17 f0    	pushl  0xf017e0c8
f01019b4:	e8 28 f8 ff ff       	call   f01011e1 <page_insert>
f01019b9:	83 c4 20             	add    $0x20,%esp
f01019bc:	85 c0                	test   %eax,%eax
f01019be:	74 19                	je     f01019d9 <mem_init+0x790>
f01019c0:	68 a8 52 10 f0       	push   $0xf01052a8
f01019c5:	68 55 58 10 f0       	push   $0xf0105855
f01019ca:	68 5d 03 00 00       	push   $0x35d
f01019cf:	68 1d 58 10 f0       	push   $0xf010581d
f01019d4:	e8 c7 e6 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01019d9:	8b 3d c8 e0 17 f0    	mov    0xf017e0c8,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01019df:	a1 cc e0 17 f0       	mov    0xf017e0cc,%eax
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
f0101a00:	68 d8 52 10 f0       	push   $0xf01052d8
f0101a05:	68 55 58 10 f0       	push   $0xf0105855
f0101a0a:	68 5e 03 00 00       	push   $0x35e
f0101a0f:	68 1d 58 10 f0       	push   $0xf010581d
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
f0101a34:	68 00 53 10 f0       	push   $0xf0105300
f0101a39:	68 55 58 10 f0       	push   $0xf0105855
f0101a3e:	68 5f 03 00 00       	push   $0x35f
f0101a43:	68 1d 58 10 f0       	push   $0xf010581d
f0101a48:	e8 53 e6 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101a4d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101a52:	74 19                	je     f0101a6d <mem_init+0x824>
f0101a54:	68 17 5a 10 f0       	push   $0xf0105a17
f0101a59:	68 55 58 10 f0       	push   $0xf0105855
f0101a5e:	68 60 03 00 00       	push   $0x360
f0101a63:	68 1d 58 10 f0       	push   $0xf010581d
f0101a68:	e8 33 e6 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f0101a6d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a70:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a75:	74 19                	je     f0101a90 <mem_init+0x847>
f0101a77:	68 28 5a 10 f0       	push   $0xf0105a28
f0101a7c:	68 55 58 10 f0       	push   $0xf0105855
f0101a81:	68 61 03 00 00       	push   $0x361
f0101a86:	68 1d 58 10 f0       	push   $0xf010581d
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
f0101aa5:	68 30 53 10 f0       	push   $0xf0105330
f0101aaa:	68 55 58 10 f0       	push   $0xf0105855
f0101aaf:	68 64 03 00 00       	push   $0x364
f0101ab4:	68 1d 58 10 f0       	push   $0xf010581d
f0101ab9:	e8 e2 e5 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101abe:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ac3:	a1 c8 e0 17 f0       	mov    0xf017e0c8,%eax
f0101ac8:	e8 4c f0 ff ff       	call   f0100b19 <check_va2pa>
f0101acd:	89 f2                	mov    %esi,%edx
f0101acf:	2b 15 cc e0 17 f0    	sub    0xf017e0cc,%edx
f0101ad5:	c1 fa 03             	sar    $0x3,%edx
f0101ad8:	c1 e2 0c             	shl    $0xc,%edx
f0101adb:	39 d0                	cmp    %edx,%eax
f0101add:	74 19                	je     f0101af8 <mem_init+0x8af>
f0101adf:	68 6c 53 10 f0       	push   $0xf010536c
f0101ae4:	68 55 58 10 f0       	push   $0xf0105855
f0101ae9:	68 65 03 00 00       	push   $0x365
f0101aee:	68 1d 58 10 f0       	push   $0xf010581d
f0101af3:	e8 a8 e5 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101af8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101afd:	74 19                	je     f0101b18 <mem_init+0x8cf>
f0101aff:	68 39 5a 10 f0       	push   $0xf0105a39
f0101b04:	68 55 58 10 f0       	push   $0xf0105855
f0101b09:	68 66 03 00 00       	push   $0x366
f0101b0e:	68 1d 58 10 f0       	push   $0xf010581d
f0101b13:	e8 88 e5 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101b18:	83 ec 0c             	sub    $0xc,%esp
f0101b1b:	6a 00                	push   $0x0
f0101b1d:	e8 2d f4 ff ff       	call   f0100f4f <page_alloc>
f0101b22:	83 c4 10             	add    $0x10,%esp
f0101b25:	85 c0                	test   %eax,%eax
f0101b27:	74 19                	je     f0101b42 <mem_init+0x8f9>
f0101b29:	68 c5 59 10 f0       	push   $0xf01059c5
f0101b2e:	68 55 58 10 f0       	push   $0xf0105855
f0101b33:	68 69 03 00 00       	push   $0x369
f0101b38:	68 1d 58 10 f0       	push   $0xf010581d
f0101b3d:	e8 5e e5 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b42:	6a 02                	push   $0x2
f0101b44:	68 00 10 00 00       	push   $0x1000
f0101b49:	56                   	push   %esi
f0101b4a:	ff 35 c8 e0 17 f0    	pushl  0xf017e0c8
f0101b50:	e8 8c f6 ff ff       	call   f01011e1 <page_insert>
f0101b55:	83 c4 10             	add    $0x10,%esp
f0101b58:	85 c0                	test   %eax,%eax
f0101b5a:	74 19                	je     f0101b75 <mem_init+0x92c>
f0101b5c:	68 30 53 10 f0       	push   $0xf0105330
f0101b61:	68 55 58 10 f0       	push   $0xf0105855
f0101b66:	68 6c 03 00 00       	push   $0x36c
f0101b6b:	68 1d 58 10 f0       	push   $0xf010581d
f0101b70:	e8 2b e5 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b75:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b7a:	a1 c8 e0 17 f0       	mov    0xf017e0c8,%eax
f0101b7f:	e8 95 ef ff ff       	call   f0100b19 <check_va2pa>
f0101b84:	89 f2                	mov    %esi,%edx
f0101b86:	2b 15 cc e0 17 f0    	sub    0xf017e0cc,%edx
f0101b8c:	c1 fa 03             	sar    $0x3,%edx
f0101b8f:	c1 e2 0c             	shl    $0xc,%edx
f0101b92:	39 d0                	cmp    %edx,%eax
f0101b94:	74 19                	je     f0101baf <mem_init+0x966>
f0101b96:	68 6c 53 10 f0       	push   $0xf010536c
f0101b9b:	68 55 58 10 f0       	push   $0xf0105855
f0101ba0:	68 6d 03 00 00       	push   $0x36d
f0101ba5:	68 1d 58 10 f0       	push   $0xf010581d
f0101baa:	e8 f1 e4 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101baf:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101bb4:	74 19                	je     f0101bcf <mem_init+0x986>
f0101bb6:	68 39 5a 10 f0       	push   $0xf0105a39
f0101bbb:	68 55 58 10 f0       	push   $0xf0105855
f0101bc0:	68 6e 03 00 00       	push   $0x36e
f0101bc5:	68 1d 58 10 f0       	push   $0xf010581d
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
f0101be0:	68 c5 59 10 f0       	push   $0xf01059c5
f0101be5:	68 55 58 10 f0       	push   $0xf0105855
f0101bea:	68 72 03 00 00       	push   $0x372
f0101bef:	68 1d 58 10 f0       	push   $0xf010581d
f0101bf4:	e8 a7 e4 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101bf9:	8b 15 c8 e0 17 f0    	mov    0xf017e0c8,%edx
f0101bff:	8b 02                	mov    (%edx),%eax
f0101c01:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101c06:	89 c1                	mov    %eax,%ecx
f0101c08:	c1 e9 0c             	shr    $0xc,%ecx
f0101c0b:	3b 0d c4 e0 17 f0    	cmp    0xf017e0c4,%ecx
f0101c11:	72 15                	jb     f0101c28 <mem_init+0x9df>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101c13:	50                   	push   %eax
f0101c14:	68 c8 4f 10 f0       	push   $0xf0104fc8
f0101c19:	68 75 03 00 00       	push   $0x375
f0101c1e:	68 1d 58 10 f0       	push   $0xf010581d
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
f0101c4d:	68 9c 53 10 f0       	push   $0xf010539c
f0101c52:	68 55 58 10 f0       	push   $0xf0105855
f0101c57:	68 76 03 00 00       	push   $0x376
f0101c5c:	68 1d 58 10 f0       	push   $0xf010581d
f0101c61:	e8 3a e4 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c66:	6a 06                	push   $0x6
f0101c68:	68 00 10 00 00       	push   $0x1000
f0101c6d:	56                   	push   %esi
f0101c6e:	ff 35 c8 e0 17 f0    	pushl  0xf017e0c8
f0101c74:	e8 68 f5 ff ff       	call   f01011e1 <page_insert>
f0101c79:	83 c4 10             	add    $0x10,%esp
f0101c7c:	85 c0                	test   %eax,%eax
f0101c7e:	74 19                	je     f0101c99 <mem_init+0xa50>
f0101c80:	68 dc 53 10 f0       	push   $0xf01053dc
f0101c85:	68 55 58 10 f0       	push   $0xf0105855
f0101c8a:	68 79 03 00 00       	push   $0x379
f0101c8f:	68 1d 58 10 f0       	push   $0xf010581d
f0101c94:	e8 07 e4 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c99:	8b 3d c8 e0 17 f0    	mov    0xf017e0c8,%edi
f0101c9f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ca4:	89 f8                	mov    %edi,%eax
f0101ca6:	e8 6e ee ff ff       	call   f0100b19 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101cab:	89 f2                	mov    %esi,%edx
f0101cad:	2b 15 cc e0 17 f0    	sub    0xf017e0cc,%edx
f0101cb3:	c1 fa 03             	sar    $0x3,%edx
f0101cb6:	c1 e2 0c             	shl    $0xc,%edx
f0101cb9:	39 d0                	cmp    %edx,%eax
f0101cbb:	74 19                	je     f0101cd6 <mem_init+0xa8d>
f0101cbd:	68 6c 53 10 f0       	push   $0xf010536c
f0101cc2:	68 55 58 10 f0       	push   $0xf0105855
f0101cc7:	68 7a 03 00 00       	push   $0x37a
f0101ccc:	68 1d 58 10 f0       	push   $0xf010581d
f0101cd1:	e8 ca e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101cd6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101cdb:	74 19                	je     f0101cf6 <mem_init+0xaad>
f0101cdd:	68 39 5a 10 f0       	push   $0xf0105a39
f0101ce2:	68 55 58 10 f0       	push   $0xf0105855
f0101ce7:	68 7b 03 00 00       	push   $0x37b
f0101cec:	68 1d 58 10 f0       	push   $0xf010581d
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
f0101d0e:	68 1c 54 10 f0       	push   $0xf010541c
f0101d13:	68 55 58 10 f0       	push   $0xf0105855
f0101d18:	68 7c 03 00 00       	push   $0x37c
f0101d1d:	68 1d 58 10 f0       	push   $0xf010581d
f0101d22:	e8 79 e3 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101d27:	a1 c8 e0 17 f0       	mov    0xf017e0c8,%eax
f0101d2c:	f6 00 04             	testb  $0x4,(%eax)
f0101d2f:	75 19                	jne    f0101d4a <mem_init+0xb01>
f0101d31:	68 4a 5a 10 f0       	push   $0xf0105a4a
f0101d36:	68 55 58 10 f0       	push   $0xf0105855
f0101d3b:	68 7d 03 00 00       	push   $0x37d
f0101d40:	68 1d 58 10 f0       	push   $0xf010581d
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
f0101d5f:	68 30 53 10 f0       	push   $0xf0105330
f0101d64:	68 55 58 10 f0       	push   $0xf0105855
f0101d69:	68 80 03 00 00       	push   $0x380
f0101d6e:	68 1d 58 10 f0       	push   $0xf010581d
f0101d73:	e8 28 e3 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101d78:	83 ec 04             	sub    $0x4,%esp
f0101d7b:	6a 00                	push   $0x0
f0101d7d:	68 00 10 00 00       	push   $0x1000
f0101d82:	ff 35 c8 e0 17 f0    	pushl  0xf017e0c8
f0101d88:	e8 9a f2 ff ff       	call   f0101027 <pgdir_walk>
f0101d8d:	83 c4 10             	add    $0x10,%esp
f0101d90:	f6 00 02             	testb  $0x2,(%eax)
f0101d93:	75 19                	jne    f0101dae <mem_init+0xb65>
f0101d95:	68 50 54 10 f0       	push   $0xf0105450
f0101d9a:	68 55 58 10 f0       	push   $0xf0105855
f0101d9f:	68 81 03 00 00       	push   $0x381
f0101da4:	68 1d 58 10 f0       	push   $0xf010581d
f0101da9:	e8 f2 e2 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101dae:	83 ec 04             	sub    $0x4,%esp
f0101db1:	6a 00                	push   $0x0
f0101db3:	68 00 10 00 00       	push   $0x1000
f0101db8:	ff 35 c8 e0 17 f0    	pushl  0xf017e0c8
f0101dbe:	e8 64 f2 ff ff       	call   f0101027 <pgdir_walk>
f0101dc3:	83 c4 10             	add    $0x10,%esp
f0101dc6:	f6 00 04             	testb  $0x4,(%eax)
f0101dc9:	74 19                	je     f0101de4 <mem_init+0xb9b>
f0101dcb:	68 84 54 10 f0       	push   $0xf0105484
f0101dd0:	68 55 58 10 f0       	push   $0xf0105855
f0101dd5:	68 82 03 00 00       	push   $0x382
f0101dda:	68 1d 58 10 f0       	push   $0xf010581d
f0101ddf:	e8 bc e2 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101de4:	6a 02                	push   $0x2
f0101de6:	68 00 00 40 00       	push   $0x400000
f0101deb:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101dee:	ff 35 c8 e0 17 f0    	pushl  0xf017e0c8
f0101df4:	e8 e8 f3 ff ff       	call   f01011e1 <page_insert>
f0101df9:	83 c4 10             	add    $0x10,%esp
f0101dfc:	85 c0                	test   %eax,%eax
f0101dfe:	78 19                	js     f0101e19 <mem_init+0xbd0>
f0101e00:	68 bc 54 10 f0       	push   $0xf01054bc
f0101e05:	68 55 58 10 f0       	push   $0xf0105855
f0101e0a:	68 85 03 00 00       	push   $0x385
f0101e0f:	68 1d 58 10 f0       	push   $0xf010581d
f0101e14:	e8 87 e2 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101e19:	6a 02                	push   $0x2
f0101e1b:	68 00 10 00 00       	push   $0x1000
f0101e20:	53                   	push   %ebx
f0101e21:	ff 35 c8 e0 17 f0    	pushl  0xf017e0c8
f0101e27:	e8 b5 f3 ff ff       	call   f01011e1 <page_insert>
f0101e2c:	83 c4 10             	add    $0x10,%esp
f0101e2f:	85 c0                	test   %eax,%eax
f0101e31:	74 19                	je     f0101e4c <mem_init+0xc03>
f0101e33:	68 f4 54 10 f0       	push   $0xf01054f4
f0101e38:	68 55 58 10 f0       	push   $0xf0105855
f0101e3d:	68 88 03 00 00       	push   $0x388
f0101e42:	68 1d 58 10 f0       	push   $0xf010581d
f0101e47:	e8 54 e2 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e4c:	83 ec 04             	sub    $0x4,%esp
f0101e4f:	6a 00                	push   $0x0
f0101e51:	68 00 10 00 00       	push   $0x1000
f0101e56:	ff 35 c8 e0 17 f0    	pushl  0xf017e0c8
f0101e5c:	e8 c6 f1 ff ff       	call   f0101027 <pgdir_walk>
f0101e61:	83 c4 10             	add    $0x10,%esp
f0101e64:	f6 00 04             	testb  $0x4,(%eax)
f0101e67:	74 19                	je     f0101e82 <mem_init+0xc39>
f0101e69:	68 84 54 10 f0       	push   $0xf0105484
f0101e6e:	68 55 58 10 f0       	push   $0xf0105855
f0101e73:	68 89 03 00 00       	push   $0x389
f0101e78:	68 1d 58 10 f0       	push   $0xf010581d
f0101e7d:	e8 1e e2 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101e82:	8b 3d c8 e0 17 f0    	mov    0xf017e0c8,%edi
f0101e88:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e8d:	89 f8                	mov    %edi,%eax
f0101e8f:	e8 85 ec ff ff       	call   f0100b19 <check_va2pa>
f0101e94:	89 c1                	mov    %eax,%ecx
f0101e96:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e99:	89 d8                	mov    %ebx,%eax
f0101e9b:	2b 05 cc e0 17 f0    	sub    0xf017e0cc,%eax
f0101ea1:	c1 f8 03             	sar    $0x3,%eax
f0101ea4:	c1 e0 0c             	shl    $0xc,%eax
f0101ea7:	39 c1                	cmp    %eax,%ecx
f0101ea9:	74 19                	je     f0101ec4 <mem_init+0xc7b>
f0101eab:	68 30 55 10 f0       	push   $0xf0105530
f0101eb0:	68 55 58 10 f0       	push   $0xf0105855
f0101eb5:	68 8c 03 00 00       	push   $0x38c
f0101eba:	68 1d 58 10 f0       	push   $0xf010581d
f0101ebf:	e8 dc e1 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ec4:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ec9:	89 f8                	mov    %edi,%eax
f0101ecb:	e8 49 ec ff ff       	call   f0100b19 <check_va2pa>
f0101ed0:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101ed3:	74 19                	je     f0101eee <mem_init+0xca5>
f0101ed5:	68 5c 55 10 f0       	push   $0xf010555c
f0101eda:	68 55 58 10 f0       	push   $0xf0105855
f0101edf:	68 8d 03 00 00       	push   $0x38d
f0101ee4:	68 1d 58 10 f0       	push   $0xf010581d
f0101ee9:	e8 b2 e1 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101eee:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101ef3:	74 19                	je     f0101f0e <mem_init+0xcc5>
f0101ef5:	68 60 5a 10 f0       	push   $0xf0105a60
f0101efa:	68 55 58 10 f0       	push   $0xf0105855
f0101eff:	68 8f 03 00 00       	push   $0x38f
f0101f04:	68 1d 58 10 f0       	push   $0xf010581d
f0101f09:	e8 92 e1 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101f0e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f13:	74 19                	je     f0101f2e <mem_init+0xce5>
f0101f15:	68 71 5a 10 f0       	push   $0xf0105a71
f0101f1a:	68 55 58 10 f0       	push   $0xf0105855
f0101f1f:	68 90 03 00 00       	push   $0x390
f0101f24:	68 1d 58 10 f0       	push   $0xf010581d
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
f0101f43:	68 8c 55 10 f0       	push   $0xf010558c
f0101f48:	68 55 58 10 f0       	push   $0xf0105855
f0101f4d:	68 93 03 00 00       	push   $0x393
f0101f52:	68 1d 58 10 f0       	push   $0xf010581d
f0101f57:	e8 44 e1 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101f5c:	83 ec 08             	sub    $0x8,%esp
f0101f5f:	6a 00                	push   $0x0
f0101f61:	ff 35 c8 e0 17 f0    	pushl  0xf017e0c8
f0101f67:	e8 2b f2 ff ff       	call   f0101197 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f6c:	8b 3d c8 e0 17 f0    	mov    0xf017e0c8,%edi
f0101f72:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f77:	89 f8                	mov    %edi,%eax
f0101f79:	e8 9b eb ff ff       	call   f0100b19 <check_va2pa>
f0101f7e:	83 c4 10             	add    $0x10,%esp
f0101f81:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f84:	74 19                	je     f0101f9f <mem_init+0xd56>
f0101f86:	68 b0 55 10 f0       	push   $0xf01055b0
f0101f8b:	68 55 58 10 f0       	push   $0xf0105855
f0101f90:	68 97 03 00 00       	push   $0x397
f0101f95:	68 1d 58 10 f0       	push   $0xf010581d
f0101f9a:	e8 01 e1 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f9f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fa4:	89 f8                	mov    %edi,%eax
f0101fa6:	e8 6e eb ff ff       	call   f0100b19 <check_va2pa>
f0101fab:	89 da                	mov    %ebx,%edx
f0101fad:	2b 15 cc e0 17 f0    	sub    0xf017e0cc,%edx
f0101fb3:	c1 fa 03             	sar    $0x3,%edx
f0101fb6:	c1 e2 0c             	shl    $0xc,%edx
f0101fb9:	39 d0                	cmp    %edx,%eax
f0101fbb:	74 19                	je     f0101fd6 <mem_init+0xd8d>
f0101fbd:	68 5c 55 10 f0       	push   $0xf010555c
f0101fc2:	68 55 58 10 f0       	push   $0xf0105855
f0101fc7:	68 98 03 00 00       	push   $0x398
f0101fcc:	68 1d 58 10 f0       	push   $0xf010581d
f0101fd1:	e8 ca e0 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101fd6:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101fdb:	74 19                	je     f0101ff6 <mem_init+0xdad>
f0101fdd:	68 17 5a 10 f0       	push   $0xf0105a17
f0101fe2:	68 55 58 10 f0       	push   $0xf0105855
f0101fe7:	68 99 03 00 00       	push   $0x399
f0101fec:	68 1d 58 10 f0       	push   $0xf010581d
f0101ff1:	e8 aa e0 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101ff6:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ffb:	74 19                	je     f0102016 <mem_init+0xdcd>
f0101ffd:	68 71 5a 10 f0       	push   $0xf0105a71
f0102002:	68 55 58 10 f0       	push   $0xf0105855
f0102007:	68 9a 03 00 00       	push   $0x39a
f010200c:	68 1d 58 10 f0       	push   $0xf010581d
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
f010202b:	68 d4 55 10 f0       	push   $0xf01055d4
f0102030:	68 55 58 10 f0       	push   $0xf0105855
f0102035:	68 9d 03 00 00       	push   $0x39d
f010203a:	68 1d 58 10 f0       	push   $0xf010581d
f010203f:	e8 5c e0 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0102044:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102049:	75 19                	jne    f0102064 <mem_init+0xe1b>
f010204b:	68 82 5a 10 f0       	push   $0xf0105a82
f0102050:	68 55 58 10 f0       	push   $0xf0105855
f0102055:	68 9e 03 00 00       	push   $0x39e
f010205a:	68 1d 58 10 f0       	push   $0xf010581d
f010205f:	e8 3c e0 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0102064:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102067:	74 19                	je     f0102082 <mem_init+0xe39>
f0102069:	68 8e 5a 10 f0       	push   $0xf0105a8e
f010206e:	68 55 58 10 f0       	push   $0xf0105855
f0102073:	68 9f 03 00 00       	push   $0x39f
f0102078:	68 1d 58 10 f0       	push   $0xf010581d
f010207d:	e8 1e e0 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102082:	83 ec 08             	sub    $0x8,%esp
f0102085:	68 00 10 00 00       	push   $0x1000
f010208a:	ff 35 c8 e0 17 f0    	pushl  0xf017e0c8
f0102090:	e8 02 f1 ff ff       	call   f0101197 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102095:	8b 3d c8 e0 17 f0    	mov    0xf017e0c8,%edi
f010209b:	ba 00 00 00 00       	mov    $0x0,%edx
f01020a0:	89 f8                	mov    %edi,%eax
f01020a2:	e8 72 ea ff ff       	call   f0100b19 <check_va2pa>
f01020a7:	83 c4 10             	add    $0x10,%esp
f01020aa:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020ad:	74 19                	je     f01020c8 <mem_init+0xe7f>
f01020af:	68 b0 55 10 f0       	push   $0xf01055b0
f01020b4:	68 55 58 10 f0       	push   $0xf0105855
f01020b9:	68 a3 03 00 00       	push   $0x3a3
f01020be:	68 1d 58 10 f0       	push   $0xf010581d
f01020c3:	e8 d8 df ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01020c8:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020cd:	89 f8                	mov    %edi,%eax
f01020cf:	e8 45 ea ff ff       	call   f0100b19 <check_va2pa>
f01020d4:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020d7:	74 19                	je     f01020f2 <mem_init+0xea9>
f01020d9:	68 0c 56 10 f0       	push   $0xf010560c
f01020de:	68 55 58 10 f0       	push   $0xf0105855
f01020e3:	68 a4 03 00 00       	push   $0x3a4
f01020e8:	68 1d 58 10 f0       	push   $0xf010581d
f01020ed:	e8 ae df ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f01020f2:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01020f7:	74 19                	je     f0102112 <mem_init+0xec9>
f01020f9:	68 a3 5a 10 f0       	push   $0xf0105aa3
f01020fe:	68 55 58 10 f0       	push   $0xf0105855
f0102103:	68 a5 03 00 00       	push   $0x3a5
f0102108:	68 1d 58 10 f0       	push   $0xf010581d
f010210d:	e8 8e df ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0102112:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102117:	74 19                	je     f0102132 <mem_init+0xee9>
f0102119:	68 71 5a 10 f0       	push   $0xf0105a71
f010211e:	68 55 58 10 f0       	push   $0xf0105855
f0102123:	68 a6 03 00 00       	push   $0x3a6
f0102128:	68 1d 58 10 f0       	push   $0xf010581d
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
f0102147:	68 34 56 10 f0       	push   $0xf0105634
f010214c:	68 55 58 10 f0       	push   $0xf0105855
f0102151:	68 a9 03 00 00       	push   $0x3a9
f0102156:	68 1d 58 10 f0       	push   $0xf010581d
f010215b:	e8 40 df ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102160:	83 ec 0c             	sub    $0xc,%esp
f0102163:	6a 00                	push   $0x0
f0102165:	e8 e5 ed ff ff       	call   f0100f4f <page_alloc>
f010216a:	83 c4 10             	add    $0x10,%esp
f010216d:	85 c0                	test   %eax,%eax
f010216f:	74 19                	je     f010218a <mem_init+0xf41>
f0102171:	68 c5 59 10 f0       	push   $0xf01059c5
f0102176:	68 55 58 10 f0       	push   $0xf0105855
f010217b:	68 ac 03 00 00       	push   $0x3ac
f0102180:	68 1d 58 10 f0       	push   $0xf010581d
f0102185:	e8 16 df ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010218a:	8b 0d c8 e0 17 f0    	mov    0xf017e0c8,%ecx
f0102190:	8b 11                	mov    (%ecx),%edx
f0102192:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102198:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010219b:	2b 05 cc e0 17 f0    	sub    0xf017e0cc,%eax
f01021a1:	c1 f8 03             	sar    $0x3,%eax
f01021a4:	c1 e0 0c             	shl    $0xc,%eax
f01021a7:	39 c2                	cmp    %eax,%edx
f01021a9:	74 19                	je     f01021c4 <mem_init+0xf7b>
f01021ab:	68 d8 52 10 f0       	push   $0xf01052d8
f01021b0:	68 55 58 10 f0       	push   $0xf0105855
f01021b5:	68 af 03 00 00       	push   $0x3af
f01021ba:	68 1d 58 10 f0       	push   $0xf010581d
f01021bf:	e8 dc de ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f01021c4:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01021ca:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021cd:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01021d2:	74 19                	je     f01021ed <mem_init+0xfa4>
f01021d4:	68 28 5a 10 f0       	push   $0xf0105a28
f01021d9:	68 55 58 10 f0       	push   $0xf0105855
f01021de:	68 b1 03 00 00       	push   $0x3b1
f01021e3:	68 1d 58 10 f0       	push   $0xf010581d
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
f0102209:	ff 35 c8 e0 17 f0    	pushl  0xf017e0c8
f010220f:	e8 13 ee ff ff       	call   f0101027 <pgdir_walk>
f0102214:	89 c7                	mov    %eax,%edi
f0102216:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102219:	a1 c8 e0 17 f0       	mov    0xf017e0c8,%eax
f010221e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102221:	8b 40 04             	mov    0x4(%eax),%eax
f0102224:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102229:	8b 0d c4 e0 17 f0    	mov    0xf017e0c4,%ecx
f010222f:	89 c2                	mov    %eax,%edx
f0102231:	c1 ea 0c             	shr    $0xc,%edx
f0102234:	83 c4 10             	add    $0x10,%esp
f0102237:	39 ca                	cmp    %ecx,%edx
f0102239:	72 15                	jb     f0102250 <mem_init+0x1007>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010223b:	50                   	push   %eax
f010223c:	68 c8 4f 10 f0       	push   $0xf0104fc8
f0102241:	68 b8 03 00 00       	push   $0x3b8
f0102246:	68 1d 58 10 f0       	push   $0xf010581d
f010224b:	e8 50 de ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102250:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0102255:	39 c7                	cmp    %eax,%edi
f0102257:	74 19                	je     f0102272 <mem_init+0x1029>
f0102259:	68 b4 5a 10 f0       	push   $0xf0105ab4
f010225e:	68 55 58 10 f0       	push   $0xf0105855
f0102263:	68 b9 03 00 00       	push   $0x3b9
f0102268:	68 1d 58 10 f0       	push   $0xf010581d
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
f0102285:	2b 05 cc e0 17 f0    	sub    0xf017e0cc,%eax
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
f010229b:	68 c8 4f 10 f0       	push   $0xf0104fc8
f01022a0:	6a 56                	push   $0x56
f01022a2:	68 3b 58 10 f0       	push   $0xf010583b
f01022a7:	e8 f4 dd ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01022ac:	83 ec 04             	sub    $0x4,%esp
f01022af:	68 00 10 00 00       	push   $0x1000
f01022b4:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f01022b9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01022be:	50                   	push   %eax
f01022bf:	e8 58 20 00 00       	call   f010431c <memset>
	page_free(pp0);
f01022c4:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01022c7:	89 3c 24             	mov    %edi,(%esp)
f01022ca:	e8 f0 ec ff ff       	call   f0100fbf <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01022cf:	83 c4 0c             	add    $0xc,%esp
f01022d2:	6a 01                	push   $0x1
f01022d4:	6a 00                	push   $0x0
f01022d6:	ff 35 c8 e0 17 f0    	pushl  0xf017e0c8
f01022dc:	e8 46 ed ff ff       	call   f0101027 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01022e1:	89 fa                	mov    %edi,%edx
f01022e3:	2b 15 cc e0 17 f0    	sub    0xf017e0cc,%edx
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
f01022f7:	3b 05 c4 e0 17 f0    	cmp    0xf017e0c4,%eax
f01022fd:	72 12                	jb     f0102311 <mem_init+0x10c8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01022ff:	52                   	push   %edx
f0102300:	68 c8 4f 10 f0       	push   $0xf0104fc8
f0102305:	6a 56                	push   $0x56
f0102307:	68 3b 58 10 f0       	push   $0xf010583b
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
f0102325:	68 cc 5a 10 f0       	push   $0xf0105acc
f010232a:	68 55 58 10 f0       	push   $0xf0105855
f010232f:	68 c3 03 00 00       	push   $0x3c3
f0102334:	68 1d 58 10 f0       	push   $0xf010581d
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
f0102345:	a1 c8 e0 17 f0       	mov    0xf017e0c8,%eax
f010234a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102350:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102353:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102359:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010235c:	89 3d dc d3 17 f0    	mov    %edi,0xf017d3dc

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
f010237b:	c7 04 24 e3 5a 10 f0 	movl   $0xf0105ae3,(%esp)
f0102382:	e8 30 0e 00 00       	call   f01031b7 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U|PTE_P);
f0102387:	a1 cc e0 17 f0       	mov    0xf017e0cc,%eax
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
f0102397:	68 ec 4f 10 f0       	push   $0xf0104fec
f010239c:	68 c4 00 00 00       	push   $0xc4
f01023a1:	68 1d 58 10 f0       	push   $0xf010581d
f01023a6:	e8 f5 dc ff ff       	call   f01000a0 <_panic>
f01023ab:	83 ec 08             	sub    $0x8,%esp
f01023ae:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f01023b0:	05 00 00 00 10       	add    $0x10000000,%eax
f01023b5:	50                   	push   %eax
f01023b6:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01023bb:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01023c0:	a1 c8 e0 17 f0       	mov    0xf017e0c8,%eax
f01023c5:	e8 f0 ec ff ff       	call   f01010ba <boot_map_region>
	boot_map_region(kern_pgdir, (uintptr_t)pages, PTSIZE, PADDR(pages), PTE_U|PTE_P|PTE_W);
f01023ca:	8b 15 cc e0 17 f0    	mov    0xf017e0cc,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01023d0:	83 c4 10             	add    $0x10,%esp
f01023d3:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01023d9:	77 15                	ja     f01023f0 <mem_init+0x11a7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01023db:	52                   	push   %edx
f01023dc:	68 ec 4f 10 f0       	push   $0xf0104fec
f01023e1:	68 c5 00 00 00       	push   $0xc5
f01023e6:	68 1d 58 10 f0       	push   $0xf010581d
f01023eb:	e8 b0 dc ff ff       	call   f01000a0 <_panic>
f01023f0:	83 ec 08             	sub    $0x8,%esp
f01023f3:	6a 07                	push   $0x7
	return (physaddr_t)kva - KERNBASE;
f01023f5:	8d 82 00 00 00 10    	lea    0x10000000(%edx),%eax
f01023fb:	50                   	push   %eax
f01023fc:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102401:	a1 c8 e0 17 f0       	mov    0xf017e0c8,%eax
f0102406:	e8 af ec ff ff       	call   f01010ba <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, ROUNDUP(sizeof(struct Env) * NENV, PGSIZE), PADDR(envs), PTE_U);
f010240b:	a1 e8 d3 17 f0       	mov    0xf017d3e8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102410:	83 c4 10             	add    $0x10,%esp
f0102413:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102418:	77 15                	ja     f010242f <mem_init+0x11e6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010241a:	50                   	push   %eax
f010241b:	68 ec 4f 10 f0       	push   $0xf0104fec
f0102420:	68 cd 00 00 00       	push   $0xcd
f0102425:	68 1d 58 10 f0       	push   $0xf010581d
f010242a:	e8 71 dc ff ff       	call   f01000a0 <_panic>
f010242f:	83 ec 08             	sub    $0x8,%esp
f0102432:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f0102434:	05 00 00 00 10       	add    $0x10000000,%eax
f0102439:	50                   	push   %eax
f010243a:	b9 00 80 01 00       	mov    $0x18000,%ecx
f010243f:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102444:	a1 c8 e0 17 f0       	mov    0xf017e0c8,%eax
f0102449:	e8 6c ec ff ff       	call   f01010ba <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010244e:	83 c4 10             	add    $0x10,%esp
f0102451:	b8 00 10 11 f0       	mov    $0xf0111000,%eax
f0102456:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010245b:	77 15                	ja     f0102472 <mem_init+0x1229>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010245d:	50                   	push   %eax
f010245e:	68 ec 4f 10 f0       	push   $0xf0104fec
f0102463:	68 da 00 00 00       	push   $0xda
f0102468:	68 1d 58 10 f0       	push   $0xf010581d
f010246d:	e8 2e dc ff ff       	call   f01000a0 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102472:	83 ec 08             	sub    $0x8,%esp
f0102475:	6a 02                	push   $0x2
f0102477:	68 00 10 11 00       	push   $0x111000
f010247c:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102481:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102486:	a1 c8 e0 17 f0       	mov    0xf017e0c8,%eax
f010248b:	e8 2a ec ff ff       	call   f01010ba <boot_map_region>
		for(; padd < ((uintptr_t)0x10000000); padd += PTSIZE){
			kern_pgdir[PDX(KERNBASE+padd)] = padd  | PTE_PS | PTE_W| PTE_P;
		}	
	}
	else*/
	boot_map_region(kern_pgdir, KERNBASE, (size_t)((add<<31) + ((add<<31) - bias) - bias)-KERNBASE + bias,0 ,PTE_W);
f0102490:	83 c4 08             	add    $0x8,%esp
f0102493:	6a 02                	push   $0x2
f0102495:	6a 00                	push   $0x0
f0102497:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f010249c:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01024a1:	a1 c8 e0 17 f0       	mov    0xf017e0c8,%eax
f01024a6:	e8 0f ec ff ff       	call   f01010ba <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01024ab:	8b 1d c8 e0 17 f0    	mov    0xf017e0c8,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01024b1:	a1 c4 e0 17 f0       	mov    0xf017e0c4,%eax
f01024b6:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01024b9:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01024c0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01024c5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01024c8:	8b 3d cc e0 17 f0    	mov    0xf017e0cc,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01024ce:	89 7d d0             	mov    %edi,-0x30(%ebp)
f01024d1:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01024d4:	be 00 00 00 00       	mov    $0x0,%esi
f01024d9:	eb 55                	jmp    f0102530 <mem_init+0x12e7>
f01024db:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01024e1:	89 d8                	mov    %ebx,%eax
f01024e3:	e8 31 e6 ff ff       	call   f0100b19 <check_va2pa>
f01024e8:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01024ef:	77 15                	ja     f0102506 <mem_init+0x12bd>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01024f1:	57                   	push   %edi
f01024f2:	68 ec 4f 10 f0       	push   $0xf0104fec
f01024f7:	68 fd 02 00 00       	push   $0x2fd
f01024fc:	68 1d 58 10 f0       	push   $0xf010581d
f0102501:	e8 9a db ff ff       	call   f01000a0 <_panic>
f0102506:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f010250d:	39 c2                	cmp    %eax,%edx
f010250f:	74 19                	je     f010252a <mem_init+0x12e1>
f0102511:	68 58 56 10 f0       	push   $0xf0105658
f0102516:	68 55 58 10 f0       	push   $0xf0105855
f010251b:	68 fd 02 00 00       	push   $0x2fd
f0102520:	68 1d 58 10 f0       	push   $0xf010581d
f0102525:	e8 76 db ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010252a:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102530:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f0102533:	77 a6                	ja     f01024db <mem_init+0x1292>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102535:	8b 3d e8 d3 17 f0    	mov    0xf017d3e8,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010253b:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010253e:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f0102543:	89 f2                	mov    %esi,%edx
f0102545:	89 d8                	mov    %ebx,%eax
f0102547:	e8 cd e5 ff ff       	call   f0100b19 <check_va2pa>
f010254c:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f0102553:	77 15                	ja     f010256a <mem_init+0x1321>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102555:	57                   	push   %edi
f0102556:	68 ec 4f 10 f0       	push   $0xf0104fec
f010255b:	68 02 03 00 00       	push   $0x302
f0102560:	68 1d 58 10 f0       	push   $0xf010581d
f0102565:	e8 36 db ff ff       	call   f01000a0 <_panic>
f010256a:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f0102571:	39 c2                	cmp    %eax,%edx
f0102573:	74 19                	je     f010258e <mem_init+0x1345>
f0102575:	68 8c 56 10 f0       	push   $0xf010568c
f010257a:	68 55 58 10 f0       	push   $0xf0105855
f010257f:	68 02 03 00 00       	push   $0x302
f0102584:	68 1d 58 10 f0       	push   $0xf010581d
f0102589:	e8 12 db ff ff       	call   f01000a0 <_panic>
f010258e:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102594:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f010259a:	75 a7                	jne    f0102543 <mem_init+0x12fa>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010259c:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010259f:	c1 e7 0c             	shl    $0xc,%edi
f01025a2:	be 00 00 00 00       	mov    $0x0,%esi
f01025a7:	eb 30                	jmp    f01025d9 <mem_init+0x1390>
f01025a9:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01025af:	89 d8                	mov    %ebx,%eax
f01025b1:	e8 63 e5 ff ff       	call   f0100b19 <check_va2pa>
f01025b6:	39 c6                	cmp    %eax,%esi
f01025b8:	74 19                	je     f01025d3 <mem_init+0x138a>
f01025ba:	68 c0 56 10 f0       	push   $0xf01056c0
f01025bf:	68 55 58 10 f0       	push   $0xf0105855
f01025c4:	68 06 03 00 00       	push   $0x306
f01025c9:	68 1d 58 10 f0       	push   $0xf010581d
f01025ce:	e8 cd da ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01025d3:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01025d9:	39 fe                	cmp    %edi,%esi
f01025db:	72 cc                	jb     f01025a9 <mem_init+0x1360>
f01025dd:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01025e2:	89 f2                	mov    %esi,%edx
f01025e4:	89 d8                	mov    %ebx,%eax
f01025e6:	e8 2e e5 ff ff       	call   f0100b19 <check_va2pa>
f01025eb:	8d 96 00 90 11 10    	lea    0x10119000(%esi),%edx
f01025f1:	39 c2                	cmp    %eax,%edx
f01025f3:	74 19                	je     f010260e <mem_init+0x13c5>
f01025f5:	68 e8 56 10 f0       	push   $0xf01056e8
f01025fa:	68 55 58 10 f0       	push   $0xf0105855
f01025ff:	68 0a 03 00 00       	push   $0x30a
f0102604:	68 1d 58 10 f0       	push   $0xf010581d
f0102609:	e8 92 da ff ff       	call   f01000a0 <_panic>
f010260e:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102614:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f010261a:	75 c6                	jne    f01025e2 <mem_init+0x1399>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010261c:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102621:	89 d8                	mov    %ebx,%eax
f0102623:	e8 f1 e4 ff ff       	call   f0100b19 <check_va2pa>
f0102628:	83 f8 ff             	cmp    $0xffffffff,%eax
f010262b:	74 51                	je     f010267e <mem_init+0x1435>
f010262d:	68 30 57 10 f0       	push   $0xf0105730
f0102632:	68 55 58 10 f0       	push   $0xf0105855
f0102637:	68 0b 03 00 00       	push   $0x30b
f010263c:	68 1d 58 10 f0       	push   $0xf010581d
f0102641:	e8 5a da ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102646:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f010264b:	72 36                	jb     f0102683 <mem_init+0x143a>
f010264d:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102652:	76 07                	jbe    f010265b <mem_init+0x1412>
f0102654:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102659:	75 28                	jne    f0102683 <mem_init+0x143a>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f010265b:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f010265f:	0f 85 83 00 00 00    	jne    f01026e8 <mem_init+0x149f>
f0102665:	68 fc 5a 10 f0       	push   $0xf0105afc
f010266a:	68 55 58 10 f0       	push   $0xf0105855
f010266f:	68 14 03 00 00       	push   $0x314
f0102674:	68 1d 58 10 f0       	push   $0xf010581d
f0102679:	e8 22 da ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010267e:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102683:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102688:	76 3f                	jbe    f01026c9 <mem_init+0x1480>
				assert(pgdir[i] & PTE_P);
f010268a:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f010268d:	f6 c2 01             	test   $0x1,%dl
f0102690:	75 19                	jne    f01026ab <mem_init+0x1462>
f0102692:	68 fc 5a 10 f0       	push   $0xf0105afc
f0102697:	68 55 58 10 f0       	push   $0xf0105855
f010269c:	68 18 03 00 00       	push   $0x318
f01026a1:	68 1d 58 10 f0       	push   $0xf010581d
f01026a6:	e8 f5 d9 ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f01026ab:	f6 c2 02             	test   $0x2,%dl
f01026ae:	75 38                	jne    f01026e8 <mem_init+0x149f>
f01026b0:	68 0d 5b 10 f0       	push   $0xf0105b0d
f01026b5:	68 55 58 10 f0       	push   $0xf0105855
f01026ba:	68 19 03 00 00       	push   $0x319
f01026bf:	68 1d 58 10 f0       	push   $0xf010581d
f01026c4:	e8 d7 d9 ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f01026c9:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f01026cd:	74 19                	je     f01026e8 <mem_init+0x149f>
f01026cf:	68 1e 5b 10 f0       	push   $0xf0105b1e
f01026d4:	68 55 58 10 f0       	push   $0xf0105855
f01026d9:	68 1b 03 00 00       	push   $0x31b
f01026de:	68 1d 58 10 f0       	push   $0xf010581d
f01026e3:	e8 b8 d9 ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01026e8:	83 c0 01             	add    $0x1,%eax
f01026eb:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01026f0:	0f 86 50 ff ff ff    	jbe    f0102646 <mem_init+0x13fd>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01026f6:	83 ec 0c             	sub    $0xc,%esp
f01026f9:	68 60 57 10 f0       	push   $0xf0105760
f01026fe:	e8 b4 0a 00 00       	call   f01031b7 <cprintf>
		uintptr_t paddress = 0;
		for(paddress = 0; paddress < ((uintptr_t)0x10000000); paddress += PTSIZE){
		invlpg((void*)(KERNBASE + paddress));
	}
	}*/
	lcr3(PADDR(kern_pgdir));
f0102703:	a1 c8 e0 17 f0       	mov    0xf017e0c8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102708:	83 c4 10             	add    $0x10,%esp
f010270b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102710:	77 15                	ja     f0102727 <mem_init+0x14de>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102712:	50                   	push   %eax
f0102713:	68 ec 4f 10 f0       	push   $0xf0104fec
f0102718:	68 01 01 00 00       	push   $0x101
f010271d:	68 1d 58 10 f0       	push   $0xf010581d
f0102722:	e8 79 d9 ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102727:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010272c:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f010272f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102734:	e8 d2 e4 ff ff       	call   f0100c0b <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102739:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f010273c:	83 e0 f3             	and    $0xfffffff3,%eax
f010273f:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102744:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102747:	83 ec 0c             	sub    $0xc,%esp
f010274a:	6a 00                	push   $0x0
f010274c:	e8 fe e7 ff ff       	call   f0100f4f <page_alloc>
f0102751:	89 c3                	mov    %eax,%ebx
f0102753:	83 c4 10             	add    $0x10,%esp
f0102756:	85 c0                	test   %eax,%eax
f0102758:	75 19                	jne    f0102773 <mem_init+0x152a>
f010275a:	68 1a 59 10 f0       	push   $0xf010591a
f010275f:	68 55 58 10 f0       	push   $0xf0105855
f0102764:	68 de 03 00 00       	push   $0x3de
f0102769:	68 1d 58 10 f0       	push   $0xf010581d
f010276e:	e8 2d d9 ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0102773:	83 ec 0c             	sub    $0xc,%esp
f0102776:	6a 00                	push   $0x0
f0102778:	e8 d2 e7 ff ff       	call   f0100f4f <page_alloc>
f010277d:	89 c7                	mov    %eax,%edi
f010277f:	83 c4 10             	add    $0x10,%esp
f0102782:	85 c0                	test   %eax,%eax
f0102784:	75 19                	jne    f010279f <mem_init+0x1556>
f0102786:	68 30 59 10 f0       	push   $0xf0105930
f010278b:	68 55 58 10 f0       	push   $0xf0105855
f0102790:	68 df 03 00 00       	push   $0x3df
f0102795:	68 1d 58 10 f0       	push   $0xf010581d
f010279a:	e8 01 d9 ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010279f:	83 ec 0c             	sub    $0xc,%esp
f01027a2:	6a 00                	push   $0x0
f01027a4:	e8 a6 e7 ff ff       	call   f0100f4f <page_alloc>
f01027a9:	89 c6                	mov    %eax,%esi
f01027ab:	83 c4 10             	add    $0x10,%esp
f01027ae:	85 c0                	test   %eax,%eax
f01027b0:	75 19                	jne    f01027cb <mem_init+0x1582>
f01027b2:	68 46 59 10 f0       	push   $0xf0105946
f01027b7:	68 55 58 10 f0       	push   $0xf0105855
f01027bc:	68 e0 03 00 00       	push   $0x3e0
f01027c1:	68 1d 58 10 f0       	push   $0xf010581d
f01027c6:	e8 d5 d8 ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f01027cb:	83 ec 0c             	sub    $0xc,%esp
f01027ce:	53                   	push   %ebx
f01027cf:	e8 eb e7 ff ff       	call   f0100fbf <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01027d4:	89 f8                	mov    %edi,%eax
f01027d6:	2b 05 cc e0 17 f0    	sub    0xf017e0cc,%eax
f01027dc:	c1 f8 03             	sar    $0x3,%eax
f01027df:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01027e2:	89 c2                	mov    %eax,%edx
f01027e4:	c1 ea 0c             	shr    $0xc,%edx
f01027e7:	83 c4 10             	add    $0x10,%esp
f01027ea:	3b 15 c4 e0 17 f0    	cmp    0xf017e0c4,%edx
f01027f0:	72 12                	jb     f0102804 <mem_init+0x15bb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01027f2:	50                   	push   %eax
f01027f3:	68 c8 4f 10 f0       	push   $0xf0104fc8
f01027f8:	6a 56                	push   $0x56
f01027fa:	68 3b 58 10 f0       	push   $0xf010583b
f01027ff:	e8 9c d8 ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102804:	83 ec 04             	sub    $0x4,%esp
f0102807:	68 00 10 00 00       	push   $0x1000
f010280c:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f010280e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102813:	50                   	push   %eax
f0102814:	e8 03 1b 00 00       	call   f010431c <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102819:	89 f0                	mov    %esi,%eax
f010281b:	2b 05 cc e0 17 f0    	sub    0xf017e0cc,%eax
f0102821:	c1 f8 03             	sar    $0x3,%eax
f0102824:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102827:	89 c2                	mov    %eax,%edx
f0102829:	c1 ea 0c             	shr    $0xc,%edx
f010282c:	83 c4 10             	add    $0x10,%esp
f010282f:	3b 15 c4 e0 17 f0    	cmp    0xf017e0c4,%edx
f0102835:	72 12                	jb     f0102849 <mem_init+0x1600>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102837:	50                   	push   %eax
f0102838:	68 c8 4f 10 f0       	push   $0xf0104fc8
f010283d:	6a 56                	push   $0x56
f010283f:	68 3b 58 10 f0       	push   $0xf010583b
f0102844:	e8 57 d8 ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102849:	83 ec 04             	sub    $0x4,%esp
f010284c:	68 00 10 00 00       	push   $0x1000
f0102851:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102853:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102858:	50                   	push   %eax
f0102859:	e8 be 1a 00 00       	call   f010431c <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010285e:	6a 02                	push   $0x2
f0102860:	68 00 10 00 00       	push   $0x1000
f0102865:	57                   	push   %edi
f0102866:	ff 35 c8 e0 17 f0    	pushl  0xf017e0c8
f010286c:	e8 70 e9 ff ff       	call   f01011e1 <page_insert>
	assert(pp1->pp_ref == 1);
f0102871:	83 c4 20             	add    $0x20,%esp
f0102874:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102879:	74 19                	je     f0102894 <mem_init+0x164b>
f010287b:	68 17 5a 10 f0       	push   $0xf0105a17
f0102880:	68 55 58 10 f0       	push   $0xf0105855
f0102885:	68 e5 03 00 00       	push   $0x3e5
f010288a:	68 1d 58 10 f0       	push   $0xf010581d
f010288f:	e8 0c d8 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102894:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f010289b:	01 01 01 
f010289e:	74 19                	je     f01028b9 <mem_init+0x1670>
f01028a0:	68 80 57 10 f0       	push   $0xf0105780
f01028a5:	68 55 58 10 f0       	push   $0xf0105855
f01028aa:	68 e6 03 00 00       	push   $0x3e6
f01028af:	68 1d 58 10 f0       	push   $0xf010581d
f01028b4:	e8 e7 d7 ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01028b9:	6a 02                	push   $0x2
f01028bb:	68 00 10 00 00       	push   $0x1000
f01028c0:	56                   	push   %esi
f01028c1:	ff 35 c8 e0 17 f0    	pushl  0xf017e0c8
f01028c7:	e8 15 e9 ff ff       	call   f01011e1 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01028cc:	83 c4 10             	add    $0x10,%esp
f01028cf:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01028d6:	02 02 02 
f01028d9:	74 19                	je     f01028f4 <mem_init+0x16ab>
f01028db:	68 a4 57 10 f0       	push   $0xf01057a4
f01028e0:	68 55 58 10 f0       	push   $0xf0105855
f01028e5:	68 e8 03 00 00       	push   $0x3e8
f01028ea:	68 1d 58 10 f0       	push   $0xf010581d
f01028ef:	e8 ac d7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01028f4:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01028f9:	74 19                	je     f0102914 <mem_init+0x16cb>
f01028fb:	68 39 5a 10 f0       	push   $0xf0105a39
f0102900:	68 55 58 10 f0       	push   $0xf0105855
f0102905:	68 e9 03 00 00       	push   $0x3e9
f010290a:	68 1d 58 10 f0       	push   $0xf010581d
f010290f:	e8 8c d7 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0102914:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102919:	74 19                	je     f0102934 <mem_init+0x16eb>
f010291b:	68 a3 5a 10 f0       	push   $0xf0105aa3
f0102920:	68 55 58 10 f0       	push   $0xf0105855
f0102925:	68 ea 03 00 00       	push   $0x3ea
f010292a:	68 1d 58 10 f0       	push   $0xf010581d
f010292f:	e8 6c d7 ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102934:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f010293b:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010293e:	89 f0                	mov    %esi,%eax
f0102940:	2b 05 cc e0 17 f0    	sub    0xf017e0cc,%eax
f0102946:	c1 f8 03             	sar    $0x3,%eax
f0102949:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010294c:	89 c2                	mov    %eax,%edx
f010294e:	c1 ea 0c             	shr    $0xc,%edx
f0102951:	3b 15 c4 e0 17 f0    	cmp    0xf017e0c4,%edx
f0102957:	72 12                	jb     f010296b <mem_init+0x1722>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102959:	50                   	push   %eax
f010295a:	68 c8 4f 10 f0       	push   $0xf0104fc8
f010295f:	6a 56                	push   $0x56
f0102961:	68 3b 58 10 f0       	push   $0xf010583b
f0102966:	e8 35 d7 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f010296b:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102972:	03 03 03 
f0102975:	74 19                	je     f0102990 <mem_init+0x1747>
f0102977:	68 c8 57 10 f0       	push   $0xf01057c8
f010297c:	68 55 58 10 f0       	push   $0xf0105855
f0102981:	68 ec 03 00 00       	push   $0x3ec
f0102986:	68 1d 58 10 f0       	push   $0xf010581d
f010298b:	e8 10 d7 ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102990:	83 ec 08             	sub    $0x8,%esp
f0102993:	68 00 10 00 00       	push   $0x1000
f0102998:	ff 35 c8 e0 17 f0    	pushl  0xf017e0c8
f010299e:	e8 f4 e7 ff ff       	call   f0101197 <page_remove>
	assert(pp2->pp_ref == 0);
f01029a3:	83 c4 10             	add    $0x10,%esp
f01029a6:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01029ab:	74 19                	je     f01029c6 <mem_init+0x177d>
f01029ad:	68 71 5a 10 f0       	push   $0xf0105a71
f01029b2:	68 55 58 10 f0       	push   $0xf0105855
f01029b7:	68 ee 03 00 00       	push   $0x3ee
f01029bc:	68 1d 58 10 f0       	push   $0xf010581d
f01029c1:	e8 da d6 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01029c6:	8b 0d c8 e0 17 f0    	mov    0xf017e0c8,%ecx
f01029cc:	8b 11                	mov    (%ecx),%edx
f01029ce:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01029d4:	89 d8                	mov    %ebx,%eax
f01029d6:	2b 05 cc e0 17 f0    	sub    0xf017e0cc,%eax
f01029dc:	c1 f8 03             	sar    $0x3,%eax
f01029df:	c1 e0 0c             	shl    $0xc,%eax
f01029e2:	39 c2                	cmp    %eax,%edx
f01029e4:	74 19                	je     f01029ff <mem_init+0x17b6>
f01029e6:	68 d8 52 10 f0       	push   $0xf01052d8
f01029eb:	68 55 58 10 f0       	push   $0xf0105855
f01029f0:	68 f1 03 00 00       	push   $0x3f1
f01029f5:	68 1d 58 10 f0       	push   $0xf010581d
f01029fa:	e8 a1 d6 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f01029ff:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102a05:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102a0a:	74 19                	je     f0102a25 <mem_init+0x17dc>
f0102a0c:	68 28 5a 10 f0       	push   $0xf0105a28
f0102a11:	68 55 58 10 f0       	push   $0xf0105855
f0102a16:	68 f3 03 00 00       	push   $0x3f3
f0102a1b:	68 1d 58 10 f0       	push   $0xf010581d
f0102a20:	e8 7b d6 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0102a25:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102a2b:	83 ec 0c             	sub    $0xc,%esp
f0102a2e:	53                   	push   %ebx
f0102a2f:	e8 8b e5 ff ff       	call   f0100fbf <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102a34:	c7 04 24 f4 57 10 f0 	movl   $0xf01057f4,(%esp)
f0102a3b:	e8 77 07 00 00       	call   f01031b7 <cprintf>
f0102a40:	83 c4 10             	add    $0x10,%esp
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102a43:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a46:	5b                   	pop    %ebx
f0102a47:	5e                   	pop    %esi
f0102a48:	5f                   	pop    %edi
f0102a49:	5d                   	pop    %ebp
f0102a4a:	c3                   	ret    

f0102a4b <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102a4b:	55                   	push   %ebp
f0102a4c:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102a4e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102a51:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102a54:	5d                   	pop    %ebp
f0102a55:	c3                   	ret    

f0102a56 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102a56:	55                   	push   %ebp
f0102a57:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.

	return 0;
}
f0102a59:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a5e:	5d                   	pop    %ebp
f0102a5f:	c3                   	ret    

f0102a60 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102a60:	55                   	push   %ebp
f0102a61:	89 e5                	mov    %esp,%ebp
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
		cprintf("[%08x] user_mem_check assertion failure for "
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
	}
}
f0102a63:	5d                   	pop    %ebp
f0102a64:	c3                   	ret    

f0102a65 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102a65:	55                   	push   %ebp
f0102a66:	89 e5                	mov    %esp,%ebp
f0102a68:	57                   	push   %edi
f0102a69:	56                   	push   %esi
f0102a6a:	53                   	push   %ebx
f0102a6b:	83 ec 1c             	sub    $0x1c,%esp
f0102a6e:	89 c7                	mov    %eax,%edi
f0102a70:	89 d6                	mov    %edx,%esi
	// LAB 3: Your code here.
	// (But only if you need it for load_icode.)
	//
	void* st = ROUNDDOWN(va, PGSIZE), *en = ROUNDUP(va + len, PGSIZE);
f0102a72:	89 d3                	mov    %edx,%ebx
f0102a74:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0102a7a:	8d 84 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%eax
f0102a81:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102a86:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(; st < en; st += PGSIZE){
f0102a89:	eb 58                	jmp    f0102ae3 <region_alloc+0x7e>
		struct PageInfo* page = page_alloc(0);
f0102a8b:	83 ec 0c             	sub    $0xc,%esp
f0102a8e:	6a 00                	push   $0x0
f0102a90:	e8 ba e4 ff ff       	call   f0100f4f <page_alloc>
		if(!page) panic("region_alloc: page_allocation failed!");
f0102a95:	83 c4 10             	add    $0x10,%esp
f0102a98:	85 c0                	test   %eax,%eax
f0102a9a:	75 17                	jne    f0102ab3 <region_alloc+0x4e>
f0102a9c:	83 ec 04             	sub    $0x4,%esp
f0102a9f:	68 2c 5b 10 f0       	push   $0xf0105b2c
f0102aa4:	68 19 01 00 00       	push   $0x119
f0102aa9:	68 41 5c 10 f0       	push   $0xf0105c41
f0102aae:	e8 ed d5 ff ff       	call   f01000a0 <_panic>
		int ret = page_insert(e->env_pgdir, page, va, PTE_W|PTE_U);
f0102ab3:	6a 06                	push   $0x6
f0102ab5:	56                   	push   %esi
f0102ab6:	50                   	push   %eax
f0102ab7:	ff 77 5c             	pushl  0x5c(%edi)
f0102aba:	e8 22 e7 ff ff       	call   f01011e1 <page_insert>
		if(ret != 0){
f0102abf:	83 c4 10             	add    $0x10,%esp
f0102ac2:	85 c0                	test   %eax,%eax
f0102ac4:	74 17                	je     f0102add <region_alloc+0x78>
			panic("region_alloc: page_mapping failed!");
f0102ac6:	83 ec 04             	sub    $0x4,%esp
f0102ac9:	68 54 5b 10 f0       	push   $0xf0105b54
f0102ace:	68 1c 01 00 00       	push   $0x11c
f0102ad3:	68 41 5c 10 f0       	push   $0xf0105c41
f0102ad8:	e8 c3 d5 ff ff       	call   f01000a0 <_panic>
{
	// LAB 3: Your code here.
	// (But only if you need it for load_icode.)
	//
	void* st = ROUNDDOWN(va, PGSIZE), *en = ROUNDUP(va + len, PGSIZE);
	for(; st < en; st += PGSIZE){
f0102add:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102ae3:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102ae6:	72 a3                	jb     f0102a8b <region_alloc+0x26>

	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
}
f0102ae8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102aeb:	5b                   	pop    %ebx
f0102aec:	5e                   	pop    %esi
f0102aed:	5f                   	pop    %edi
f0102aee:	5d                   	pop    %ebp
f0102aef:	c3                   	ret    

f0102af0 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102af0:	55                   	push   %ebp
f0102af1:	89 e5                	mov    %esp,%ebp
f0102af3:	8b 55 08             	mov    0x8(%ebp),%edx
f0102af6:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102af9:	85 d2                	test   %edx,%edx
f0102afb:	75 11                	jne    f0102b0e <envid2env+0x1e>
		*env_store = curenv;
f0102afd:	a1 e4 d3 17 f0       	mov    0xf017d3e4,%eax
f0102b02:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102b05:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102b07:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b0c:	eb 5e                	jmp    f0102b6c <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102b0e:	89 d0                	mov    %edx,%eax
f0102b10:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102b15:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102b18:	c1 e0 05             	shl    $0x5,%eax
f0102b1b:	03 05 e8 d3 17 f0    	add    0xf017d3e8,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102b21:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0102b25:	74 05                	je     f0102b2c <envid2env+0x3c>
f0102b27:	39 50 48             	cmp    %edx,0x48(%eax)
f0102b2a:	74 10                	je     f0102b3c <envid2env+0x4c>
		*env_store = 0;
f0102b2c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102b2f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102b35:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102b3a:	eb 30                	jmp    f0102b6c <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102b3c:	84 c9                	test   %cl,%cl
f0102b3e:	74 22                	je     f0102b62 <envid2env+0x72>
f0102b40:	8b 15 e4 d3 17 f0    	mov    0xf017d3e4,%edx
f0102b46:	39 d0                	cmp    %edx,%eax
f0102b48:	74 18                	je     f0102b62 <envid2env+0x72>
f0102b4a:	8b 4a 48             	mov    0x48(%edx),%ecx
f0102b4d:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f0102b50:	74 10                	je     f0102b62 <envid2env+0x72>
		*env_store = 0;
f0102b52:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102b55:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102b5b:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102b60:	eb 0a                	jmp    f0102b6c <envid2env+0x7c>
	}

	*env_store = e;
f0102b62:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102b65:	89 01                	mov    %eax,(%ecx)
	return 0;
f0102b67:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102b6c:	5d                   	pop    %ebp
f0102b6d:	c3                   	ret    

f0102b6e <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102b6e:	55                   	push   %ebp
f0102b6f:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0102b71:	b8 00 b3 11 f0       	mov    $0xf011b300,%eax
f0102b76:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0102b79:	b8 23 00 00 00       	mov    $0x23,%eax
f0102b7e:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0102b80:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0102b82:	b0 10                	mov    $0x10,%al
f0102b84:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0102b86:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0102b88:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f0102b8a:	ea 91 2b 10 f0 08 00 	ljmp   $0x8,$0xf0102b91
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0102b91:	b0 00                	mov    $0x0,%al
f0102b93:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102b96:	5d                   	pop    %ebp
f0102b97:	c3                   	ret    

f0102b98 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102b98:	55                   	push   %ebp
f0102b99:	89 e5                	mov    %esp,%ebp
f0102b9b:	56                   	push   %esi
f0102b9c:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i = NENV - 1; i >= 0; --i){
		envs[i].env_id = 0;
f0102b9d:	8b 35 e8 d3 17 f0    	mov    0xf017d3e8,%esi
f0102ba3:	8b 15 ec d3 17 f0    	mov    0xf017d3ec,%edx
f0102ba9:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f0102baf:	8d 5e a0             	lea    -0x60(%esi),%ebx
f0102bb2:	89 c1                	mov    %eax,%ecx
f0102bb4:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_runs = 0;
f0102bbb:	c7 40 58 00 00 00 00 	movl   $0x0,0x58(%eax)
		envs[i].env_type = ENV_TYPE_USER;
f0102bc2:	c7 40 50 00 00 00 00 	movl   $0x0,0x50(%eax)
		envs[i].env_status = ENV_FREE;
f0102bc9:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_link = env_free_list;
f0102bd0:	89 50 44             	mov    %edx,0x44(%eax)
f0102bd3:	83 e8 60             	sub    $0x60,%eax
		env_free_list = envs + i;
f0102bd6:	89 ca                	mov    %ecx,%edx
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i = NENV - 1; i >= 0; --i){
f0102bd8:	39 d8                	cmp    %ebx,%eax
f0102bda:	75 d6                	jne    f0102bb2 <env_init+0x1a>
f0102bdc:	89 35 ec d3 17 f0    	mov    %esi,0xf017d3ec
		envs[i].env_link = env_free_list;
		env_free_list = envs + i;
	}

	// Per-CPU part of the initialization
	env_init_percpu();
f0102be2:	e8 87 ff ff ff       	call   f0102b6e <env_init_percpu>
}
f0102be7:	5b                   	pop    %ebx
f0102be8:	5e                   	pop    %esi
f0102be9:	5d                   	pop    %ebp
f0102bea:	c3                   	ret    

f0102beb <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102beb:	55                   	push   %ebp
f0102bec:	89 e5                	mov    %esp,%ebp
f0102bee:	53                   	push   %ebx
f0102bef:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102bf2:	8b 1d ec d3 17 f0    	mov    0xf017d3ec,%ebx
f0102bf8:	85 db                	test   %ebx,%ebx
f0102bfa:	0f 84 24 01 00 00    	je     f0102d24 <env_alloc+0x139>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102c00:	83 ec 0c             	sub    $0xc,%esp
f0102c03:	6a 01                	push   $0x1
f0102c05:	e8 45 e3 ff ff       	call   f0100f4f <page_alloc>
f0102c0a:	83 c4 10             	add    $0x10,%esp
f0102c0d:	85 c0                	test   %eax,%eax
f0102c0f:	0f 84 16 01 00 00    	je     f0102d2b <env_alloc+0x140>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f0102c15:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
f0102c1a:	2b 05 cc e0 17 f0    	sub    0xf017e0cc,%eax
f0102c20:	c1 f8 03             	sar    $0x3,%eax
f0102c23:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c26:	89 c2                	mov    %eax,%edx
f0102c28:	c1 ea 0c             	shr    $0xc,%edx
f0102c2b:	3b 15 c4 e0 17 f0    	cmp    0xf017e0c4,%edx
f0102c31:	72 12                	jb     f0102c45 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c33:	50                   	push   %eax
f0102c34:	68 c8 4f 10 f0       	push   $0xf0104fc8
f0102c39:	6a 56                	push   $0x56
f0102c3b:	68 3b 58 10 f0       	push   $0xf010583b
f0102c40:	e8 5b d4 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0102c45:	2d 00 00 00 10       	sub    $0x10000000,%eax
	e->env_pgdir = (pde_t*) page2kva(p);
f0102c4a:	89 43 5c             	mov    %eax,0x5c(%ebx)
	memmove(e->env_pgdir, kern_pgdir, PGSIZE);
f0102c4d:	83 ec 04             	sub    $0x4,%esp
f0102c50:	68 00 10 00 00       	push   $0x1000
f0102c55:	ff 35 c8 e0 17 f0    	pushl  0xf017e0c8
f0102c5b:	50                   	push   %eax
f0102c5c:	e8 08 17 00 00       	call   f0104369 <memmove>
	memset(e->env_pgdir, 0, PDX(UTOP) * sizeof(pde_t));
f0102c61:	83 c4 0c             	add    $0xc,%esp
f0102c64:	68 ec 0e 00 00       	push   $0xeec
f0102c69:	6a 00                	push   $0x0
f0102c6b:	ff 73 5c             	pushl  0x5c(%ebx)
f0102c6e:	e8 a9 16 00 00       	call   f010431c <memset>
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102c73:	8b 43 48             	mov    0x48(%ebx),%eax
f0102c76:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102c7b:	83 c4 0c             	add    $0xc,%esp
f0102c7e:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102c83:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102c88:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102c8b:	89 da                	mov    %ebx,%edx
f0102c8d:	2b 15 e8 d3 17 f0    	sub    0xf017d3e8,%edx
f0102c93:	c1 fa 05             	sar    $0x5,%edx
f0102c96:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102c9c:	09 d0                	or     %edx,%eax
f0102c9e:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102ca1:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ca4:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102ca7:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102cae:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102cb5:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102cbc:	6a 44                	push   $0x44
f0102cbe:	6a 00                	push   $0x0
f0102cc0:	53                   	push   %ebx
f0102cc1:	e8 56 16 00 00       	call   f010431c <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102cc6:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102ccc:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102cd2:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102cd8:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102cdf:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102ce5:	8b 43 44             	mov    0x44(%ebx),%eax
f0102ce8:	a3 ec d3 17 f0       	mov    %eax,0xf017d3ec
	*newenv_store = e;
f0102ced:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cf0:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102cf2:	8b 53 48             	mov    0x48(%ebx),%edx
f0102cf5:	a1 e4 d3 17 f0       	mov    0xf017d3e4,%eax
f0102cfa:	83 c4 10             	add    $0x10,%esp
f0102cfd:	85 c0                	test   %eax,%eax
f0102cff:	74 05                	je     f0102d06 <env_alloc+0x11b>
f0102d01:	8b 40 48             	mov    0x48(%eax),%eax
f0102d04:	eb 05                	jmp    f0102d0b <env_alloc+0x120>
f0102d06:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d0b:	83 ec 04             	sub    $0x4,%esp
f0102d0e:	52                   	push   %edx
f0102d0f:	50                   	push   %eax
f0102d10:	68 4c 5c 10 f0       	push   $0xf0105c4c
f0102d15:	e8 9d 04 00 00       	call   f01031b7 <cprintf>
	return 0;
f0102d1a:	83 c4 10             	add    $0x10,%esp
f0102d1d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d22:	eb 0c                	jmp    f0102d30 <env_alloc+0x145>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102d24:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102d29:	eb 05                	jmp    f0102d30 <env_alloc+0x145>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102d2b:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102d30:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102d33:	c9                   	leave  
f0102d34:	c3                   	ret    

f0102d35 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102d35:	55                   	push   %ebp
f0102d36:	89 e5                	mov    %esp,%ebp
f0102d38:	57                   	push   %edi
f0102d39:	56                   	push   %esi
f0102d3a:	53                   	push   %ebx
f0102d3b:	83 ec 34             	sub    $0x34,%esp
	// LAB 3: Your code here.
	struct Env* env;
	int ret = env_alloc(&env, 0);
f0102d3e:	6a 00                	push   $0x0
f0102d40:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102d43:	50                   	push   %eax
f0102d44:	e8 a2 fe ff ff       	call   f0102beb <env_alloc>
	if(ret != 0){
f0102d49:	83 c4 10             	add    $0x10,%esp
f0102d4c:	85 c0                	test   %eax,%eax
f0102d4e:	74 17                	je     f0102d67 <env_create+0x32>
		panic("Env_create: allocate a new env failed!\n");
f0102d50:	83 ec 04             	sub    $0x4,%esp
f0102d53:	68 78 5b 10 f0       	push   $0xf0105b78
f0102d58:	68 89 01 00 00       	push   $0x189
f0102d5d:	68 41 5c 10 f0       	push   $0xf0105c41
f0102d62:	e8 39 d3 ff ff       	call   f01000a0 <_panic>
	}
	load_icode(env, binary);
f0102d67:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102d6a:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// LAB 3: Your code here.
	struct Proghdr *ph, *eph;
	struct Elf *ELFHDR;
	ELFHDR  = (struct Elf*)binary;
	if(ELFHDR->e_magic != ELF_MAGIC){
f0102d6d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d70:	81 38 7f 45 4c 46    	cmpl   $0x464c457f,(%eax)
f0102d76:	74 17                	je     f0102d8f <env_create+0x5a>
		panic("load_icode: not a valid elf file!");
f0102d78:	83 ec 04             	sub    $0x4,%esp
f0102d7b:	68 a0 5b 10 f0       	push   $0xf0105ba0
f0102d80:	68 60 01 00 00       	push   $0x160
f0102d85:	68 41 5c 10 f0       	push   $0xf0105c41
f0102d8a:	e8 11 d3 ff ff       	call   f01000a0 <_panic>
	}
	ph = (struct Proghdr*)((uint8_t*)ELFHDR + ELFHDR->e_phoff);
f0102d8f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d92:	89 c3                	mov    %eax,%ebx
f0102d94:	03 58 1c             	add    0x1c(%eax),%ebx
	eph = ph + ELFHDR->e_phnum;
f0102d97:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
f0102d9b:	c1 e0 05             	shl    $0x5,%eax
f0102d9e:	8d 3c 03             	lea    (%ebx,%eax,1),%edi
	cprintf("e_phnum is %d\n", (int)(eph - ph));
f0102da1:	83 ec 08             	sub    $0x8,%esp
f0102da4:	c1 f8 05             	sar    $0x5,%eax
f0102da7:	50                   	push   %eax
f0102da8:	68 61 5c 10 f0       	push   $0xf0105c61
f0102dad:	e8 05 04 00 00       	call   f01031b7 <cprintf>
	lcr3(PADDR(e->env_pgdir));
f0102db2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102db5:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102db8:	83 c4 10             	add    $0x10,%esp
f0102dbb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102dc0:	77 15                	ja     f0102dd7 <env_create+0xa2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102dc2:	50                   	push   %eax
f0102dc3:	68 ec 4f 10 f0       	push   $0xf0104fec
f0102dc8:	68 65 01 00 00       	push   $0x165
f0102dcd:	68 41 5c 10 f0       	push   $0xf0105c41
f0102dd2:	e8 c9 d2 ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102dd7:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102ddc:	0f 22 d8             	mov    %eax,%cr3
	int cnt = 0;
f0102ddf:	be 00 00 00 00       	mov    $0x0,%esi
f0102de4:	eb 6b                	jmp    f0102e51 <env_create+0x11c>
	for(; ph < eph; ph++){
		if(ph->p_type == ELF_PROG_LOAD){
f0102de6:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102de9:	75 4f                	jne    f0102e3a <env_create+0x105>
			cprintf("load_icode: line 368\n");	
f0102deb:	83 ec 0c             	sub    $0xc,%esp
f0102dee:	68 70 5c 10 f0       	push   $0xf0105c70
f0102df3:	e8 bf 03 00 00       	call   f01031b7 <cprintf>
			region_alloc(e,(void*)ph->p_va, ph->p_memsz);
f0102df8:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102dfb:	8b 53 08             	mov    0x8(%ebx),%edx
f0102dfe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e01:	e8 5f fc ff ff       	call   f0102a65 <region_alloc>
			memset((void*)ph->p_va, 0, (size_t)ph->p_memsz);
f0102e06:	83 c4 0c             	add    $0xc,%esp
f0102e09:	ff 73 14             	pushl  0x14(%ebx)
f0102e0c:	6a 00                	push   $0x0
f0102e0e:	ff 73 08             	pushl  0x8(%ebx)
f0102e11:	e8 06 15 00 00       	call   f010431c <memset>
			memcpy((void*)ph->p_va,(binary + ph->p_offset), ph->p_filesz);
f0102e16:	83 c4 0c             	add    $0xc,%esp
f0102e19:	ff 73 10             	pushl  0x10(%ebx)
f0102e1c:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e1f:	03 43 04             	add    0x4(%ebx),%eax
f0102e22:	50                   	push   %eax
f0102e23:	ff 73 08             	pushl  0x8(%ebx)
f0102e26:	e8 a6 15 00 00       	call   f01043d1 <memcpy>
			cprintf("region alloc in load icode right\n");
f0102e2b:	c7 04 24 c4 5b 10 f0 	movl   $0xf0105bc4,(%esp)
f0102e32:	e8 80 03 00 00       	call   f01031b7 <cprintf>
f0102e37:	83 c4 10             	add    $0x10,%esp
		}
		cprintf("now reaches %d\n", cnt);
f0102e3a:	83 ec 08             	sub    $0x8,%esp
f0102e3d:	56                   	push   %esi
f0102e3e:	68 86 5c 10 f0       	push   $0xf0105c86
f0102e43:	e8 6f 03 00 00       	call   f01031b7 <cprintf>
		cnt++;
f0102e48:	83 c6 01             	add    $0x1,%esi
	ph = (struct Proghdr*)((uint8_t*)ELFHDR + ELFHDR->e_phoff);
	eph = ph + ELFHDR->e_phnum;
	cprintf("e_phnum is %d\n", (int)(eph - ph));
	lcr3(PADDR(e->env_pgdir));
	int cnt = 0;
	for(; ph < eph; ph++){
f0102e4b:	83 c3 20             	add    $0x20,%ebx
f0102e4e:	83 c4 10             	add    $0x10,%esp
f0102e51:	39 df                	cmp    %ebx,%edi
f0102e53:	77 91                	ja     f0102de6 <env_create+0xb1>
			cprintf("region alloc in load icode right\n");
		}
		cprintf("now reaches %d\n", cnt);
		cnt++;
	}
	cprintf("Out of iteration!\n");
f0102e55:	83 ec 0c             	sub    $0xc,%esp
f0102e58:	68 96 5c 10 f0       	push   $0xf0105c96
f0102e5d:	e8 55 03 00 00       	call   f01031b7 <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102e62:	a1 c8 e0 17 f0       	mov    0xf017e0c8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e67:	83 c4 10             	add    $0x10,%esp
f0102e6a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102e6f:	77 15                	ja     f0102e86 <env_create+0x151>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e71:	50                   	push   %eax
f0102e72:	68 ec 4f 10 f0       	push   $0xf0104fec
f0102e77:	68 73 01 00 00       	push   $0x173
f0102e7c:	68 41 5c 10 f0       	push   $0xf0105c41
f0102e81:	e8 1a d2 ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102e86:	05 00 00 00 10       	add    $0x10000000,%eax
f0102e8b:	0f 22 d8             	mov    %eax,%cr3
	e->env_tf.tf_eip = ELFHDR->e_entry;
f0102e8e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e91:	8b 40 18             	mov    0x18(%eax),%eax
f0102e94:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102e97:	89 47 30             	mov    %eax,0x30(%edi)
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.
	// LAB 3: Your code here.
	region_alloc(e,(void*)(USTACKTOP - PGSIZE), PGSIZE);
f0102e9a:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102e9f:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102ea4:	89 f8                	mov    %edi,%eax
f0102ea6:	e8 ba fb ff ff       	call   f0102a65 <region_alloc>
	int ret = env_alloc(&env, 0);
	if(ret != 0){
		panic("Env_create: allocate a new env failed!\n");
	}
	load_icode(env, binary);
	cprintf("env_create: finished!\n");
f0102eab:	83 ec 0c             	sub    $0xc,%esp
f0102eae:	68 a9 5c 10 f0       	push   $0xf0105ca9
f0102eb3:	e8 ff 02 00 00       	call   f01031b7 <cprintf>
	env->env_type = ENV_TYPE_USER;	
f0102eb8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102ebb:	c7 40 50 00 00 00 00 	movl   $0x0,0x50(%eax)
	env->env_parent_id = 0;
f0102ec2:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
f0102ec9:	83 c4 10             	add    $0x10,%esp
}
f0102ecc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ecf:	5b                   	pop    %ebx
f0102ed0:	5e                   	pop    %esi
f0102ed1:	5f                   	pop    %edi
f0102ed2:	5d                   	pop    %ebp
f0102ed3:	c3                   	ret    

f0102ed4 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102ed4:	55                   	push   %ebp
f0102ed5:	89 e5                	mov    %esp,%ebp
f0102ed7:	57                   	push   %edi
f0102ed8:	56                   	push   %esi
f0102ed9:	53                   	push   %ebx
f0102eda:	83 ec 1c             	sub    $0x1c,%esp
f0102edd:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102ee0:	8b 15 e4 d3 17 f0    	mov    0xf017d3e4,%edx
f0102ee6:	39 d7                	cmp    %edx,%edi
f0102ee8:	75 29                	jne    f0102f13 <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102eea:	a1 c8 e0 17 f0       	mov    0xf017e0c8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102eef:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102ef4:	77 15                	ja     f0102f0b <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ef6:	50                   	push   %eax
f0102ef7:	68 ec 4f 10 f0       	push   $0xf0104fec
f0102efc:	68 9f 01 00 00       	push   $0x19f
f0102f01:	68 41 5c 10 f0       	push   $0xf0105c41
f0102f06:	e8 95 d1 ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102f0b:	05 00 00 00 10       	add    $0x10000000,%eax
f0102f10:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102f13:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102f16:	85 d2                	test   %edx,%edx
f0102f18:	74 05                	je     f0102f1f <env_free+0x4b>
f0102f1a:	8b 42 48             	mov    0x48(%edx),%eax
f0102f1d:	eb 05                	jmp    f0102f24 <env_free+0x50>
f0102f1f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f24:	83 ec 04             	sub    $0x4,%esp
f0102f27:	51                   	push   %ecx
f0102f28:	50                   	push   %eax
f0102f29:	68 c0 5c 10 f0       	push   $0xf0105cc0
f0102f2e:	e8 84 02 00 00       	call   f01031b7 <cprintf>
f0102f33:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102f36:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102f3d:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102f40:	89 d0                	mov    %edx,%eax
f0102f42:	c1 e0 02             	shl    $0x2,%eax
f0102f45:	89 45 d8             	mov    %eax,-0x28(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102f48:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102f4b:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102f4e:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102f54:	0f 84 a8 00 00 00    	je     f0103002 <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102f5a:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102f60:	89 f0                	mov    %esi,%eax
f0102f62:	c1 e8 0c             	shr    $0xc,%eax
f0102f65:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0102f68:	3b 05 c4 e0 17 f0    	cmp    0xf017e0c4,%eax
f0102f6e:	72 15                	jb     f0102f85 <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102f70:	56                   	push   %esi
f0102f71:	68 c8 4f 10 f0       	push   $0xf0104fc8
f0102f76:	68 ae 01 00 00       	push   $0x1ae
f0102f7b:	68 41 5c 10 f0       	push   $0xf0105c41
f0102f80:	e8 1b d1 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102f85:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102f88:	c1 e0 16             	shl    $0x16,%eax
f0102f8b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102f8e:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102f93:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102f9a:	01 
f0102f9b:	74 17                	je     f0102fb4 <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102f9d:	83 ec 08             	sub    $0x8,%esp
f0102fa0:	89 d8                	mov    %ebx,%eax
f0102fa2:	c1 e0 0c             	shl    $0xc,%eax
f0102fa5:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102fa8:	50                   	push   %eax
f0102fa9:	ff 77 5c             	pushl  0x5c(%edi)
f0102fac:	e8 e6 e1 ff ff       	call   f0101197 <page_remove>
f0102fb1:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102fb4:	83 c3 01             	add    $0x1,%ebx
f0102fb7:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102fbd:	75 d4                	jne    f0102f93 <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102fbf:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102fc2:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102fc5:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102fcc:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102fcf:	3b 05 c4 e0 17 f0    	cmp    0xf017e0c4,%eax
f0102fd5:	72 14                	jb     f0102feb <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102fd7:	83 ec 04             	sub    $0x4,%esp
f0102fda:	68 34 51 10 f0       	push   $0xf0105134
f0102fdf:	6a 4f                	push   $0x4f
f0102fe1:	68 3b 58 10 f0       	push   $0xf010583b
f0102fe6:	e8 b5 d0 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102feb:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0102fee:	a1 cc e0 17 f0       	mov    0xf017e0cc,%eax
f0102ff3:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102ff6:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102ff9:	50                   	push   %eax
f0102ffa:	e8 01 e0 ff ff       	call   f0101000 <page_decref>
f0102fff:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103002:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103006:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103009:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f010300e:	0f 85 29 ff ff ff    	jne    f0102f3d <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103014:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103017:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010301c:	77 15                	ja     f0103033 <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010301e:	50                   	push   %eax
f010301f:	68 ec 4f 10 f0       	push   $0xf0104fec
f0103024:	68 bc 01 00 00       	push   $0x1bc
f0103029:	68 41 5c 10 f0       	push   $0xf0105c41
f010302e:	e8 6d d0 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0103033:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	return (physaddr_t)kva - KERNBASE;
f010303a:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010303f:	c1 e8 0c             	shr    $0xc,%eax
f0103042:	3b 05 c4 e0 17 f0    	cmp    0xf017e0c4,%eax
f0103048:	72 14                	jb     f010305e <env_free+0x18a>
		panic("pa2page called with invalid pa");
f010304a:	83 ec 04             	sub    $0x4,%esp
f010304d:	68 34 51 10 f0       	push   $0xf0105134
f0103052:	6a 4f                	push   $0x4f
f0103054:	68 3b 58 10 f0       	push   $0xf010583b
f0103059:	e8 42 d0 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f010305e:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103061:	8b 15 cc e0 17 f0    	mov    0xf017e0cc,%edx
f0103067:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f010306a:	50                   	push   %eax
f010306b:	e8 90 df ff ff       	call   f0101000 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103070:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103077:	a1 ec d3 17 f0       	mov    0xf017d3ec,%eax
f010307c:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f010307f:	89 3d ec d3 17 f0    	mov    %edi,0xf017d3ec
f0103085:	83 c4 10             	add    $0x10,%esp
}
f0103088:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010308b:	5b                   	pop    %ebx
f010308c:	5e                   	pop    %esi
f010308d:	5f                   	pop    %edi
f010308e:	5d                   	pop    %ebp
f010308f:	c3                   	ret    

f0103090 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0103090:	55                   	push   %ebp
f0103091:	89 e5                	mov    %esp,%ebp
f0103093:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0103096:	ff 75 08             	pushl  0x8(%ebp)
f0103099:	e8 36 fe ff ff       	call   f0102ed4 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f010309e:	c7 04 24 e8 5b 10 f0 	movl   $0xf0105be8,(%esp)
f01030a5:	e8 0d 01 00 00       	call   f01031b7 <cprintf>
f01030aa:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f01030ad:	83 ec 0c             	sub    $0xc,%esp
f01030b0:	6a 00                	push   $0x0
f01030b2:	e8 d9 d8 ff ff       	call   f0100990 <monitor>
f01030b7:	83 c4 10             	add    $0x10,%esp
f01030ba:	eb f1                	jmp    f01030ad <env_destroy+0x1d>

f01030bc <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01030bc:	55                   	push   %ebp
f01030bd:	89 e5                	mov    %esp,%ebp
f01030bf:	83 ec 0c             	sub    $0xc,%esp
	__asm __volatile("movl %0,%%esp\n"
f01030c2:	8b 65 08             	mov    0x8(%ebp),%esp
f01030c5:	61                   	popa   
f01030c6:	07                   	pop    %es
f01030c7:	1f                   	pop    %ds
f01030c8:	83 c4 08             	add    $0x8,%esp
f01030cb:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f01030cc:	68 d6 5c 10 f0       	push   $0xf0105cd6
f01030d1:	68 e4 01 00 00       	push   $0x1e4
f01030d6:	68 41 5c 10 f0       	push   $0xf0105c41
f01030db:	e8 c0 cf ff ff       	call   f01000a0 <_panic>

f01030e0 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f01030e0:	55                   	push   %ebp
f01030e1:	89 e5                	mov    %esp,%ebp
f01030e3:	83 ec 08             	sub    $0x8,%esp
f01030e6:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(e != curenv){ //a context switch, since a new environment is running
f01030e9:	8b 15 e4 d3 17 f0    	mov    0xf017d3e4,%edx
f01030ef:	39 d0                	cmp    %edx,%eax
f01030f1:	74 48                	je     f010313b <env_run+0x5b>
		if(curenv != NULL){
f01030f3:	85 d2                	test   %edx,%edx
f01030f5:	74 0d                	je     f0103104 <env_run+0x24>
			if(curenv->env_status == ENV_RUNNING) curenv->env_status = ENV_RUNNABLE;
f01030f7:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f01030fb:	75 07                	jne    f0103104 <env_run+0x24>
f01030fd:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
		}
		curenv = e;
f0103104:	a3 e4 d3 17 f0       	mov    %eax,0xf017d3e4
		curenv->env_runs++;
f0103109:	83 40 58 01          	addl   $0x1,0x58(%eax)
		curenv->env_status = ENV_RUNNING;
f010310d:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
		lcr3(PADDR(curenv->env_pgdir));
f0103114:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103117:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010311c:	77 15                	ja     f0103133 <env_run+0x53>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010311e:	50                   	push   %eax
f010311f:	68 ec 4f 10 f0       	push   $0xf0104fec
f0103124:	68 09 02 00 00       	push   $0x209
f0103129:	68 41 5c 10 f0       	push   $0xf0105c41
f010312e:	e8 6d cf ff ff       	call   f01000a0 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103133:	05 00 00 00 10       	add    $0x10000000,%eax
f0103138:	0f 22 d8             	mov    %eax,%cr3
	}
	cprintf("up to now everything goes well!\n");
f010313b:	83 ec 0c             	sub    $0xc,%esp
f010313e:	68 20 5c 10 f0       	push   $0xf0105c20
f0103143:	e8 6f 00 00 00       	call   f01031b7 <cprintf>
	env_pop_tf(&curenv->env_tf);
f0103148:	83 c4 04             	add    $0x4,%esp
f010314b:	ff 35 e4 d3 17 f0    	pushl  0xf017d3e4
f0103151:	e8 66 ff ff ff       	call   f01030bc <env_pop_tf>

f0103156 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103156:	55                   	push   %ebp
f0103157:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103159:	ba 70 00 00 00       	mov    $0x70,%edx
f010315e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103161:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103162:	b2 71                	mov    $0x71,%dl
f0103164:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103165:	0f b6 c0             	movzbl %al,%eax
}
f0103168:	5d                   	pop    %ebp
f0103169:	c3                   	ret    

f010316a <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010316a:	55                   	push   %ebp
f010316b:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010316d:	ba 70 00 00 00       	mov    $0x70,%edx
f0103172:	8b 45 08             	mov    0x8(%ebp),%eax
f0103175:	ee                   	out    %al,(%dx)
f0103176:	b2 71                	mov    $0x71,%dl
f0103178:	8b 45 0c             	mov    0xc(%ebp),%eax
f010317b:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010317c:	5d                   	pop    %ebp
f010317d:	c3                   	ret    

f010317e <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010317e:	55                   	push   %ebp
f010317f:	89 e5                	mov    %esp,%ebp
f0103181:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0103184:	ff 75 08             	pushl  0x8(%ebp)
f0103187:	e8 68 d4 ff ff       	call   f01005f4 <cputchar>
f010318c:	83 c4 10             	add    $0x10,%esp
	*cnt++;
}
f010318f:	c9                   	leave  
f0103190:	c3                   	ret    

f0103191 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103191:	55                   	push   %ebp
f0103192:	89 e5                	mov    %esp,%ebp
f0103194:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0103197:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010319e:	ff 75 0c             	pushl  0xc(%ebp)
f01031a1:	ff 75 08             	pushl  0x8(%ebp)
f01031a4:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01031a7:	50                   	push   %eax
f01031a8:	68 7e 31 10 f0       	push   $0xf010317e
f01031ad:	e8 25 08 00 00       	call   f01039d7 <vprintfmt>
	return cnt;
}
f01031b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01031b5:	c9                   	leave  
f01031b6:	c3                   	ret    

f01031b7 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01031b7:	55                   	push   %ebp
f01031b8:	89 e5                	mov    %esp,%ebp
f01031ba:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01031bd:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01031c0:	50                   	push   %eax
f01031c1:	ff 75 08             	pushl  0x8(%ebp)
f01031c4:	e8 c8 ff ff ff       	call   f0103191 <vcprintf>
	va_end(ap);

	return cnt;
}
f01031c9:	c9                   	leave  
f01031ca:	c3                   	ret    

f01031cb <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01031cb:	55                   	push   %ebp
f01031cc:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f01031ce:	b8 40 dc 17 f0       	mov    $0xf017dc40,%eax
f01031d3:	c7 05 44 dc 17 f0 00 	movl   $0xf0000000,0xf017dc44
f01031da:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f01031dd:	66 c7 05 48 dc 17 f0 	movw   $0x10,0xf017dc48
f01031e4:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f01031e6:	66 c7 05 48 b3 11 f0 	movw   $0x67,0xf011b348
f01031ed:	67 00 
f01031ef:	66 a3 4a b3 11 f0    	mov    %ax,0xf011b34a
f01031f5:	89 c2                	mov    %eax,%edx
f01031f7:	c1 ea 10             	shr    $0x10,%edx
f01031fa:	88 15 4c b3 11 f0    	mov    %dl,0xf011b34c
f0103200:	c6 05 4e b3 11 f0 40 	movb   $0x40,0xf011b34e
f0103207:	c1 e8 18             	shr    $0x18,%eax
f010320a:	a2 4f b3 11 f0       	mov    %al,0xf011b34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f010320f:	c6 05 4d b3 11 f0 89 	movb   $0x89,0xf011b34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f0103216:	b8 28 00 00 00       	mov    $0x28,%eax
f010321b:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f010321e:	b8 50 b3 11 f0       	mov    $0xf011b350,%eax
f0103223:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0103226:	5d                   	pop    %ebp
f0103227:	c3                   	ret    

f0103228 <trap_init>:
}


void
trap_init(void)
{
f0103228:	55                   	push   %ebp
f0103229:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

	// Per-CPU setup 
	trap_init_percpu();
f010322b:	e8 9b ff ff ff       	call   f01031cb <trap_init_percpu>
}
f0103230:	5d                   	pop    %ebp
f0103231:	c3                   	ret    

f0103232 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103232:	55                   	push   %ebp
f0103233:	89 e5                	mov    %esp,%ebp
f0103235:	53                   	push   %ebx
f0103236:	83 ec 0c             	sub    $0xc,%esp
f0103239:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f010323c:	ff 33                	pushl  (%ebx)
f010323e:	68 e2 5c 10 f0       	push   $0xf0105ce2
f0103243:	e8 6f ff ff ff       	call   f01031b7 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103248:	83 c4 08             	add    $0x8,%esp
f010324b:	ff 73 04             	pushl  0x4(%ebx)
f010324e:	68 f1 5c 10 f0       	push   $0xf0105cf1
f0103253:	e8 5f ff ff ff       	call   f01031b7 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103258:	83 c4 08             	add    $0x8,%esp
f010325b:	ff 73 08             	pushl  0x8(%ebx)
f010325e:	68 00 5d 10 f0       	push   $0xf0105d00
f0103263:	e8 4f ff ff ff       	call   f01031b7 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103268:	83 c4 08             	add    $0x8,%esp
f010326b:	ff 73 0c             	pushl  0xc(%ebx)
f010326e:	68 0f 5d 10 f0       	push   $0xf0105d0f
f0103273:	e8 3f ff ff ff       	call   f01031b7 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103278:	83 c4 08             	add    $0x8,%esp
f010327b:	ff 73 10             	pushl  0x10(%ebx)
f010327e:	68 1e 5d 10 f0       	push   $0xf0105d1e
f0103283:	e8 2f ff ff ff       	call   f01031b7 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103288:	83 c4 08             	add    $0x8,%esp
f010328b:	ff 73 14             	pushl  0x14(%ebx)
f010328e:	68 2d 5d 10 f0       	push   $0xf0105d2d
f0103293:	e8 1f ff ff ff       	call   f01031b7 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103298:	83 c4 08             	add    $0x8,%esp
f010329b:	ff 73 18             	pushl  0x18(%ebx)
f010329e:	68 3c 5d 10 f0       	push   $0xf0105d3c
f01032a3:	e8 0f ff ff ff       	call   f01031b7 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f01032a8:	83 c4 08             	add    $0x8,%esp
f01032ab:	ff 73 1c             	pushl  0x1c(%ebx)
f01032ae:	68 4b 5d 10 f0       	push   $0xf0105d4b
f01032b3:	e8 ff fe ff ff       	call   f01031b7 <cprintf>
f01032b8:	83 c4 10             	add    $0x10,%esp
}
f01032bb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01032be:	c9                   	leave  
f01032bf:	c3                   	ret    

f01032c0 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f01032c0:	55                   	push   %ebp
f01032c1:	89 e5                	mov    %esp,%ebp
f01032c3:	56                   	push   %esi
f01032c4:	53                   	push   %ebx
f01032c5:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f01032c8:	83 ec 08             	sub    $0x8,%esp
f01032cb:	53                   	push   %ebx
f01032cc:	68 81 5e 10 f0       	push   $0xf0105e81
f01032d1:	e8 e1 fe ff ff       	call   f01031b7 <cprintf>
	print_regs(&tf->tf_regs);
f01032d6:	89 1c 24             	mov    %ebx,(%esp)
f01032d9:	e8 54 ff ff ff       	call   f0103232 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f01032de:	83 c4 08             	add    $0x8,%esp
f01032e1:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f01032e5:	50                   	push   %eax
f01032e6:	68 9c 5d 10 f0       	push   $0xf0105d9c
f01032eb:	e8 c7 fe ff ff       	call   f01031b7 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f01032f0:	83 c4 08             	add    $0x8,%esp
f01032f3:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f01032f7:	50                   	push   %eax
f01032f8:	68 af 5d 10 f0       	push   $0xf0105daf
f01032fd:	e8 b5 fe ff ff       	call   f01031b7 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103302:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103305:	83 c4 10             	add    $0x10,%esp
f0103308:	83 f8 13             	cmp    $0x13,%eax
f010330b:	77 09                	ja     f0103316 <print_trapframe+0x56>
		return excnames[trapno];
f010330d:	8b 14 85 80 60 10 f0 	mov    -0xfef9f80(,%eax,4),%edx
f0103314:	eb 10                	jmp    f0103326 <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f0103316:	83 f8 30             	cmp    $0x30,%eax
f0103319:	b9 66 5d 10 f0       	mov    $0xf0105d66,%ecx
f010331e:	ba 5a 5d 10 f0       	mov    $0xf0105d5a,%edx
f0103323:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103326:	83 ec 04             	sub    $0x4,%esp
f0103329:	52                   	push   %edx
f010332a:	50                   	push   %eax
f010332b:	68 c2 5d 10 f0       	push   $0xf0105dc2
f0103330:	e8 82 fe ff ff       	call   f01031b7 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103335:	83 c4 10             	add    $0x10,%esp
f0103338:	3b 1d 00 dc 17 f0    	cmp    0xf017dc00,%ebx
f010333e:	75 1a                	jne    f010335a <print_trapframe+0x9a>
f0103340:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103344:	75 14                	jne    f010335a <print_trapframe+0x9a>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103346:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103349:	83 ec 08             	sub    $0x8,%esp
f010334c:	50                   	push   %eax
f010334d:	68 d4 5d 10 f0       	push   $0xf0105dd4
f0103352:	e8 60 fe ff ff       	call   f01031b7 <cprintf>
f0103357:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f010335a:	83 ec 08             	sub    $0x8,%esp
f010335d:	ff 73 2c             	pushl  0x2c(%ebx)
f0103360:	68 e3 5d 10 f0       	push   $0xf0105de3
f0103365:	e8 4d fe ff ff       	call   f01031b7 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f010336a:	83 c4 10             	add    $0x10,%esp
f010336d:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103371:	75 49                	jne    f01033bc <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103373:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103376:	89 c2                	mov    %eax,%edx
f0103378:	83 e2 01             	and    $0x1,%edx
f010337b:	ba 80 5d 10 f0       	mov    $0xf0105d80,%edx
f0103380:	b9 75 5d 10 f0       	mov    $0xf0105d75,%ecx
f0103385:	0f 44 ca             	cmove  %edx,%ecx
f0103388:	89 c2                	mov    %eax,%edx
f010338a:	83 e2 02             	and    $0x2,%edx
f010338d:	ba 92 5d 10 f0       	mov    $0xf0105d92,%edx
f0103392:	be 8c 5d 10 f0       	mov    $0xf0105d8c,%esi
f0103397:	0f 45 d6             	cmovne %esi,%edx
f010339a:	83 e0 04             	and    $0x4,%eax
f010339d:	be ac 5e 10 f0       	mov    $0xf0105eac,%esi
f01033a2:	b8 97 5d 10 f0       	mov    $0xf0105d97,%eax
f01033a7:	0f 44 c6             	cmove  %esi,%eax
f01033aa:	51                   	push   %ecx
f01033ab:	52                   	push   %edx
f01033ac:	50                   	push   %eax
f01033ad:	68 f1 5d 10 f0       	push   $0xf0105df1
f01033b2:	e8 00 fe ff ff       	call   f01031b7 <cprintf>
f01033b7:	83 c4 10             	add    $0x10,%esp
f01033ba:	eb 10                	jmp    f01033cc <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f01033bc:	83 ec 0c             	sub    $0xc,%esp
f01033bf:	68 fa 5a 10 f0       	push   $0xf0105afa
f01033c4:	e8 ee fd ff ff       	call   f01031b7 <cprintf>
f01033c9:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f01033cc:	83 ec 08             	sub    $0x8,%esp
f01033cf:	ff 73 30             	pushl  0x30(%ebx)
f01033d2:	68 00 5e 10 f0       	push   $0xf0105e00
f01033d7:	e8 db fd ff ff       	call   f01031b7 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f01033dc:	83 c4 08             	add    $0x8,%esp
f01033df:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f01033e3:	50                   	push   %eax
f01033e4:	68 0f 5e 10 f0       	push   $0xf0105e0f
f01033e9:	e8 c9 fd ff ff       	call   f01031b7 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f01033ee:	83 c4 08             	add    $0x8,%esp
f01033f1:	ff 73 38             	pushl  0x38(%ebx)
f01033f4:	68 22 5e 10 f0       	push   $0xf0105e22
f01033f9:	e8 b9 fd ff ff       	call   f01031b7 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f01033fe:	83 c4 10             	add    $0x10,%esp
f0103401:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103405:	74 25                	je     f010342c <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103407:	83 ec 08             	sub    $0x8,%esp
f010340a:	ff 73 3c             	pushl  0x3c(%ebx)
f010340d:	68 31 5e 10 f0       	push   $0xf0105e31
f0103412:	e8 a0 fd ff ff       	call   f01031b7 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103417:	83 c4 08             	add    $0x8,%esp
f010341a:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f010341e:	50                   	push   %eax
f010341f:	68 40 5e 10 f0       	push   $0xf0105e40
f0103424:	e8 8e fd ff ff       	call   f01031b7 <cprintf>
f0103429:	83 c4 10             	add    $0x10,%esp
	}
}
f010342c:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010342f:	5b                   	pop    %ebx
f0103430:	5e                   	pop    %esi
f0103431:	5d                   	pop    %ebp
f0103432:	c3                   	ret    

f0103433 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103433:	55                   	push   %ebp
f0103434:	89 e5                	mov    %esp,%ebp
f0103436:	57                   	push   %edi
f0103437:	56                   	push   %esi
f0103438:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f010343b:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f010343c:	9c                   	pushf  
f010343d:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f010343e:	f6 c4 02             	test   $0x2,%ah
f0103441:	74 19                	je     f010345c <trap+0x29>
f0103443:	68 53 5e 10 f0       	push   $0xf0105e53
f0103448:	68 55 58 10 f0       	push   $0xf0105855
f010344d:	68 a7 00 00 00       	push   $0xa7
f0103452:	68 6c 5e 10 f0       	push   $0xf0105e6c
f0103457:	e8 44 cc ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f010345c:	83 ec 08             	sub    $0x8,%esp
f010345f:	56                   	push   %esi
f0103460:	68 78 5e 10 f0       	push   $0xf0105e78
f0103465:	e8 4d fd ff ff       	call   f01031b7 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f010346a:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f010346e:	83 e0 03             	and    $0x3,%eax
f0103471:	83 c4 10             	add    $0x10,%esp
f0103474:	66 83 f8 03          	cmp    $0x3,%ax
f0103478:	75 31                	jne    f01034ab <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f010347a:	a1 e4 d3 17 f0       	mov    0xf017d3e4,%eax
f010347f:	85 c0                	test   %eax,%eax
f0103481:	75 19                	jne    f010349c <trap+0x69>
f0103483:	68 93 5e 10 f0       	push   $0xf0105e93
f0103488:	68 55 58 10 f0       	push   $0xf0105855
f010348d:	68 ad 00 00 00       	push   $0xad
f0103492:	68 6c 5e 10 f0       	push   $0xf0105e6c
f0103497:	e8 04 cc ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f010349c:	b9 11 00 00 00       	mov    $0x11,%ecx
f01034a1:	89 c7                	mov    %eax,%edi
f01034a3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f01034a5:	8b 35 e4 d3 17 f0    	mov    0xf017d3e4,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f01034ab:	89 35 00 dc 17 f0    	mov    %esi,0xf017dc00
{
	// Handle processor exceptions.
	// LAB 3: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f01034b1:	83 ec 0c             	sub    $0xc,%esp
f01034b4:	56                   	push   %esi
f01034b5:	e8 06 fe ff ff       	call   f01032c0 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01034ba:	83 c4 10             	add    $0x10,%esp
f01034bd:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01034c2:	75 17                	jne    f01034db <trap+0xa8>
		panic("unhandled trap in kernel");
f01034c4:	83 ec 04             	sub    $0x4,%esp
f01034c7:	68 9a 5e 10 f0       	push   $0xf0105e9a
f01034cc:	68 96 00 00 00       	push   $0x96
f01034d1:	68 6c 5e 10 f0       	push   $0xf0105e6c
f01034d6:	e8 c5 cb ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f01034db:	83 ec 0c             	sub    $0xc,%esp
f01034de:	ff 35 e4 d3 17 f0    	pushl  0xf017d3e4
f01034e4:	e8 a7 fb ff ff       	call   f0103090 <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f01034e9:	a1 e4 d3 17 f0       	mov    0xf017d3e4,%eax
f01034ee:	83 c4 10             	add    $0x10,%esp
f01034f1:	85 c0                	test   %eax,%eax
f01034f3:	74 06                	je     f01034fb <trap+0xc8>
f01034f5:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01034f9:	74 19                	je     f0103514 <trap+0xe1>
f01034fb:	68 f8 5f 10 f0       	push   $0xf0105ff8
f0103500:	68 55 58 10 f0       	push   $0xf0105855
f0103505:	68 bf 00 00 00       	push   $0xbf
f010350a:	68 6c 5e 10 f0       	push   $0xf0105e6c
f010350f:	e8 8c cb ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f0103514:	83 ec 0c             	sub    $0xc,%esp
f0103517:	50                   	push   %eax
f0103518:	e8 c3 fb ff ff       	call   f01030e0 <env_run>

f010351d <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f010351d:	55                   	push   %ebp
f010351e:	89 e5                	mov    %esp,%ebp
f0103520:	53                   	push   %ebx
f0103521:	83 ec 04             	sub    $0x4,%esp
f0103524:	8b 5d 08             	mov    0x8(%ebp),%ebx

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103527:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f010352a:	ff 73 30             	pushl  0x30(%ebx)
f010352d:	50                   	push   %eax
f010352e:	a1 e4 d3 17 f0       	mov    0xf017d3e4,%eax
f0103533:	ff 70 48             	pushl  0x48(%eax)
f0103536:	68 24 60 10 f0       	push   $0xf0106024
f010353b:	e8 77 fc ff ff       	call   f01031b7 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103540:	89 1c 24             	mov    %ebx,(%esp)
f0103543:	e8 78 fd ff ff       	call   f01032c0 <print_trapframe>
	env_destroy(curenv);
f0103548:	83 c4 04             	add    $0x4,%esp
f010354b:	ff 35 e4 d3 17 f0    	pushl  0xf017d3e4
f0103551:	e8 3a fb ff ff       	call   f0103090 <env_destroy>
f0103556:	83 c4 10             	add    $0x10,%esp
}
f0103559:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010355c:	c9                   	leave  
f010355d:	c3                   	ret    

f010355e <syscall>:
f010355e:	55                   	push   %ebp
f010355f:	89 e5                	mov    %esp,%ebp
f0103561:	83 ec 0c             	sub    $0xc,%esp
f0103564:	68 d0 60 10 f0       	push   $0xf01060d0
f0103569:	6a 49                	push   $0x49
f010356b:	68 e8 60 10 f0       	push   $0xf01060e8
f0103570:	e8 2b cb ff ff       	call   f01000a0 <_panic>

f0103575 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103575:	55                   	push   %ebp
f0103576:	89 e5                	mov    %esp,%ebp
f0103578:	57                   	push   %edi
f0103579:	56                   	push   %esi
f010357a:	53                   	push   %ebx
f010357b:	83 ec 14             	sub    $0x14,%esp
f010357e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103581:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103584:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103587:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010358a:	8b 1a                	mov    (%edx),%ebx
f010358c:	8b 01                	mov    (%ecx),%eax
f010358e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103591:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0103598:	e9 88 00 00 00       	jmp    f0103625 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f010359d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01035a0:	01 d8                	add    %ebx,%eax
f01035a2:	89 c6                	mov    %eax,%esi
f01035a4:	c1 ee 1f             	shr    $0x1f,%esi
f01035a7:	01 c6                	add    %eax,%esi
f01035a9:	d1 fe                	sar    %esi
f01035ab:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01035ae:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01035b1:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01035b4:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01035b6:	eb 03                	jmp    f01035bb <stab_binsearch+0x46>
			m--;
f01035b8:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01035bb:	39 c3                	cmp    %eax,%ebx
f01035bd:	7f 1f                	jg     f01035de <stab_binsearch+0x69>
f01035bf:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01035c3:	83 ea 0c             	sub    $0xc,%edx
f01035c6:	39 f9                	cmp    %edi,%ecx
f01035c8:	75 ee                	jne    f01035b8 <stab_binsearch+0x43>
f01035ca:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01035cd:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01035d0:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01035d3:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01035d7:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01035da:	76 18                	jbe    f01035f4 <stab_binsearch+0x7f>
f01035dc:	eb 05                	jmp    f01035e3 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01035de:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01035e1:	eb 42                	jmp    f0103625 <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01035e3:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01035e6:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01035e8:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01035eb:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01035f2:	eb 31                	jmp    f0103625 <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01035f4:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01035f7:	73 17                	jae    f0103610 <stab_binsearch+0x9b>
			*region_right = m - 1;
f01035f9:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01035fc:	83 e8 01             	sub    $0x1,%eax
f01035ff:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103602:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103605:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103607:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010360e:	eb 15                	jmp    f0103625 <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103610:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103613:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0103616:	89 1e                	mov    %ebx,(%esi)
			l = m;
			addr++;
f0103618:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010361c:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010361e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103625:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0103628:	0f 8e 6f ff ff ff    	jle    f010359d <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010362e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103632:	75 0f                	jne    f0103643 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0103634:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103637:	8b 00                	mov    (%eax),%eax
f0103639:	83 e8 01             	sub    $0x1,%eax
f010363c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010363f:	89 06                	mov    %eax,(%esi)
f0103641:	eb 2c                	jmp    f010366f <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103643:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103646:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103648:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010364b:	8b 0e                	mov    (%esi),%ecx
f010364d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103650:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103653:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103656:	eb 03                	jmp    f010365b <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103658:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010365b:	39 c8                	cmp    %ecx,%eax
f010365d:	7e 0b                	jle    f010366a <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f010365f:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0103663:	83 ea 0c             	sub    $0xc,%edx
f0103666:	39 fb                	cmp    %edi,%ebx
f0103668:	75 ee                	jne    f0103658 <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f010366a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010366d:	89 06                	mov    %eax,(%esi)
	}
}
f010366f:	83 c4 14             	add    $0x14,%esp
f0103672:	5b                   	pop    %ebx
f0103673:	5e                   	pop    %esi
f0103674:	5f                   	pop    %edi
f0103675:	5d                   	pop    %ebp
f0103676:	c3                   	ret    

f0103677 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103677:	55                   	push   %ebp
f0103678:	89 e5                	mov    %esp,%ebp
f010367a:	57                   	push   %edi
f010367b:	56                   	push   %esi
f010367c:	53                   	push   %ebx
f010367d:	83 ec 3c             	sub    $0x3c,%esp
f0103680:	8b 75 08             	mov    0x8(%ebp),%esi
f0103683:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103686:	c7 03 f7 60 10 f0    	movl   $0xf01060f7,(%ebx)
	info->eip_line = 0;
f010368c:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0103693:	c7 43 08 f7 60 10 f0 	movl   $0xf01060f7,0x8(%ebx)
	info->eip_fn_namelen = 9;
f010369a:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01036a1:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01036a4:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01036ab:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01036b1:	77 21                	ja     f01036d4 <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f01036b3:	a1 00 00 20 00       	mov    0x200000,%eax
f01036b8:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		stab_end = usd->stab_end;
f01036bb:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f01036c0:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f01036c6:	89 7d c0             	mov    %edi,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f01036c9:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f01036cf:	89 7d bc             	mov    %edi,-0x44(%ebp)
f01036d2:	eb 1a                	jmp    f01036ee <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f01036d4:	c7 45 bc f8 0e 11 f0 	movl   $0xf0110ef8,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f01036db:	c7 45 c0 25 e4 10 f0 	movl   $0xf010e425,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f01036e2:	b8 24 e4 10 f0       	mov    $0xf010e424,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f01036e7:	c7 45 c4 30 63 10 f0 	movl   $0xf0106330,-0x3c(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01036ee:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01036f1:	39 7d c0             	cmp    %edi,-0x40(%ebp)
f01036f4:	0f 83 72 01 00 00    	jae    f010386c <debuginfo_eip+0x1f5>
f01036fa:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f01036fe:	0f 85 6f 01 00 00    	jne    f0103873 <debuginfo_eip+0x1fc>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103704:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010370b:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010370e:	29 f8                	sub    %edi,%eax
f0103710:	c1 f8 02             	sar    $0x2,%eax
f0103713:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103719:	83 e8 01             	sub    $0x1,%eax
f010371c:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010371f:	56                   	push   %esi
f0103720:	6a 64                	push   $0x64
f0103722:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103725:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103728:	89 f8                	mov    %edi,%eax
f010372a:	e8 46 fe ff ff       	call   f0103575 <stab_binsearch>
	if (lfile == 0)
f010372f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103732:	83 c4 08             	add    $0x8,%esp
f0103735:	85 c0                	test   %eax,%eax
f0103737:	0f 84 3d 01 00 00    	je     f010387a <debuginfo_eip+0x203>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010373d:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103740:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103743:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103746:	56                   	push   %esi
f0103747:	6a 24                	push   $0x24
f0103749:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010374c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010374f:	89 f8                	mov    %edi,%eax
f0103751:	e8 1f fe ff ff       	call   f0103575 <stab_binsearch>

	if (lfun <= rfun) {
f0103756:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103759:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f010375c:	83 c4 08             	add    $0x8,%esp
f010375f:	39 c8                	cmp    %ecx,%eax
f0103761:	7f 32                	jg     f0103795 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103763:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103766:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0103769:	8d 3c 97             	lea    (%edi,%edx,4),%edi
f010376c:	8b 17                	mov    (%edi),%edx
f010376e:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0103771:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0103774:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0103777:	39 55 b8             	cmp    %edx,-0x48(%ebp)
f010377a:	73 09                	jae    f0103785 <debuginfo_eip+0x10e>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010377c:	8b 55 b8             	mov    -0x48(%ebp),%edx
f010377f:	03 55 c0             	add    -0x40(%ebp),%edx
f0103782:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103785:	8b 57 08             	mov    0x8(%edi),%edx
f0103788:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f010378b:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f010378d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103790:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0103793:	eb 0f                	jmp    f01037a4 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103795:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0103798:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010379b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010379e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01037a1:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01037a4:	83 ec 08             	sub    $0x8,%esp
f01037a7:	6a 3a                	push   $0x3a
f01037a9:	ff 73 08             	pushl  0x8(%ebx)
f01037ac:	e8 4f 0b 00 00       	call   f0104300 <strfind>
f01037b1:	2b 43 08             	sub    0x8(%ebx),%eax
f01037b4:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01037b7:	83 c4 08             	add    $0x8,%esp
f01037ba:	56                   	push   %esi
f01037bb:	6a 44                	push   $0x44
f01037bd:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01037c0:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01037c3:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01037c6:	89 f0                	mov    %esi,%eax
f01037c8:	e8 a8 fd ff ff       	call   f0103575 <stab_binsearch>
	if(lline <= rline){
f01037cd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01037d0:	83 c4 10             	add    $0x10,%esp
f01037d3:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f01037d6:	0f 8f a5 00 00 00    	jg     f0103881 <debuginfo_eip+0x20a>
		info->eip_line = stabs[lline].n_desc;
f01037dc:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01037df:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f01037e4:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01037e7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01037ea:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01037ed:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01037f0:	8d 14 96             	lea    (%esi,%edx,4),%edx
f01037f3:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01037f6:	eb 06                	jmp    f01037fe <debuginfo_eip+0x187>
f01037f8:	83 e8 01             	sub    $0x1,%eax
f01037fb:	83 ea 0c             	sub    $0xc,%edx
f01037fe:	39 c7                	cmp    %eax,%edi
f0103800:	7f 27                	jg     f0103829 <debuginfo_eip+0x1b2>
	       && stabs[lline].n_type != N_SOL
f0103802:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103806:	80 f9 84             	cmp    $0x84,%cl
f0103809:	0f 84 80 00 00 00    	je     f010388f <debuginfo_eip+0x218>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010380f:	80 f9 64             	cmp    $0x64,%cl
f0103812:	75 e4                	jne    f01037f8 <debuginfo_eip+0x181>
f0103814:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103818:	74 de                	je     f01037f8 <debuginfo_eip+0x181>
f010381a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010381d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103820:	eb 73                	jmp    f0103895 <debuginfo_eip+0x21e>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103822:	03 55 c0             	add    -0x40(%ebp),%edx
f0103825:	89 13                	mov    %edx,(%ebx)
f0103827:	eb 03                	jmp    f010382c <debuginfo_eip+0x1b5>
f0103829:	8b 5d 0c             	mov    0xc(%ebp),%ebx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010382c:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010382f:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103832:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103837:	39 f2                	cmp    %esi,%edx
f0103839:	7d 76                	jge    f01038b1 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
f010383b:	83 c2 01             	add    $0x1,%edx
f010383e:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103841:	89 d0                	mov    %edx,%eax
f0103843:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103846:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0103849:	8d 14 97             	lea    (%edi,%edx,4),%edx
f010384c:	eb 04                	jmp    f0103852 <debuginfo_eip+0x1db>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010384e:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103852:	39 c6                	cmp    %eax,%esi
f0103854:	7e 32                	jle    f0103888 <debuginfo_eip+0x211>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103856:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010385a:	83 c0 01             	add    $0x1,%eax
f010385d:	83 c2 0c             	add    $0xc,%edx
f0103860:	80 f9 a0             	cmp    $0xa0,%cl
f0103863:	74 e9                	je     f010384e <debuginfo_eip+0x1d7>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103865:	b8 00 00 00 00       	mov    $0x0,%eax
f010386a:	eb 45                	jmp    f01038b1 <debuginfo_eip+0x23a>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f010386c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103871:	eb 3e                	jmp    f01038b1 <debuginfo_eip+0x23a>
f0103873:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103878:	eb 37                	jmp    f01038b1 <debuginfo_eip+0x23a>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f010387a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010387f:	eb 30                	jmp    f01038b1 <debuginfo_eip+0x23a>
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if(lline <= rline){
		info->eip_line = stabs[lline].n_desc;
	}
	else{
		return -1;
f0103881:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103886:	eb 29                	jmp    f01038b1 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103888:	b8 00 00 00 00       	mov    $0x0,%eax
f010388d:	eb 22                	jmp    f01038b1 <debuginfo_eip+0x23a>
f010388f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103892:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103895:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103898:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010389b:	8b 14 87             	mov    (%edi,%eax,4),%edx
f010389e:	8b 45 bc             	mov    -0x44(%ebp),%eax
f01038a1:	2b 45 c0             	sub    -0x40(%ebp),%eax
f01038a4:	39 c2                	cmp    %eax,%edx
f01038a6:	0f 82 76 ff ff ff    	jb     f0103822 <debuginfo_eip+0x1ab>
f01038ac:	e9 7b ff ff ff       	jmp    f010382c <debuginfo_eip+0x1b5>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
}
f01038b1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01038b4:	5b                   	pop    %ebx
f01038b5:	5e                   	pop    %esi
f01038b6:	5f                   	pop    %edi
f01038b7:	5d                   	pop    %ebp
f01038b8:	c3                   	ret    

f01038b9 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01038b9:	55                   	push   %ebp
f01038ba:	89 e5                	mov    %esp,%ebp
f01038bc:	57                   	push   %edi
f01038bd:	56                   	push   %esi
f01038be:	53                   	push   %ebx
f01038bf:	83 ec 1c             	sub    $0x1c,%esp
f01038c2:	89 c7                	mov    %eax,%edi
f01038c4:	89 d6                	mov    %edx,%esi
f01038c6:	8b 45 08             	mov    0x8(%ebp),%eax
f01038c9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01038cc:	89 d1                	mov    %edx,%ecx
f01038ce:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01038d1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01038d4:	8b 45 10             	mov    0x10(%ebp),%eax
f01038d7:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01038da:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01038dd:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f01038e4:	39 4d e4             	cmp    %ecx,-0x1c(%ebp)
f01038e7:	72 05                	jb     f01038ee <printnum+0x35>
f01038e9:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f01038ec:	77 3e                	ja     f010392c <printnum+0x73>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01038ee:	83 ec 0c             	sub    $0xc,%esp
f01038f1:	ff 75 18             	pushl  0x18(%ebp)
f01038f4:	83 eb 01             	sub    $0x1,%ebx
f01038f7:	53                   	push   %ebx
f01038f8:	50                   	push   %eax
f01038f9:	83 ec 08             	sub    $0x8,%esp
f01038fc:	ff 75 e4             	pushl  -0x1c(%ebp)
f01038ff:	ff 75 e0             	pushl  -0x20(%ebp)
f0103902:	ff 75 dc             	pushl  -0x24(%ebp)
f0103905:	ff 75 d8             	pushl  -0x28(%ebp)
f0103908:	e8 23 0c 00 00       	call   f0104530 <__udivdi3>
f010390d:	83 c4 18             	add    $0x18,%esp
f0103910:	52                   	push   %edx
f0103911:	50                   	push   %eax
f0103912:	89 f2                	mov    %esi,%edx
f0103914:	89 f8                	mov    %edi,%eax
f0103916:	e8 9e ff ff ff       	call   f01038b9 <printnum>
f010391b:	83 c4 20             	add    $0x20,%esp
f010391e:	eb 13                	jmp    f0103933 <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103920:	83 ec 08             	sub    $0x8,%esp
f0103923:	56                   	push   %esi
f0103924:	ff 75 18             	pushl  0x18(%ebp)
f0103927:	ff d7                	call   *%edi
f0103929:	83 c4 10             	add    $0x10,%esp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f010392c:	83 eb 01             	sub    $0x1,%ebx
f010392f:	85 db                	test   %ebx,%ebx
f0103931:	7f ed                	jg     f0103920 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103933:	83 ec 08             	sub    $0x8,%esp
f0103936:	56                   	push   %esi
f0103937:	83 ec 04             	sub    $0x4,%esp
f010393a:	ff 75 e4             	pushl  -0x1c(%ebp)
f010393d:	ff 75 e0             	pushl  -0x20(%ebp)
f0103940:	ff 75 dc             	pushl  -0x24(%ebp)
f0103943:	ff 75 d8             	pushl  -0x28(%ebp)
f0103946:	e8 15 0d 00 00       	call   f0104660 <__umoddi3>
f010394b:	83 c4 14             	add    $0x14,%esp
f010394e:	0f be 80 01 61 10 f0 	movsbl -0xfef9eff(%eax),%eax
f0103955:	50                   	push   %eax
f0103956:	ff d7                	call   *%edi
f0103958:	83 c4 10             	add    $0x10,%esp
}
f010395b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010395e:	5b                   	pop    %ebx
f010395f:	5e                   	pop    %esi
f0103960:	5f                   	pop    %edi
f0103961:	5d                   	pop    %ebp
f0103962:	c3                   	ret    

f0103963 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103963:	55                   	push   %ebp
f0103964:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103966:	83 fa 01             	cmp    $0x1,%edx
f0103969:	7e 0e                	jle    f0103979 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f010396b:	8b 10                	mov    (%eax),%edx
f010396d:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103970:	89 08                	mov    %ecx,(%eax)
f0103972:	8b 02                	mov    (%edx),%eax
f0103974:	8b 52 04             	mov    0x4(%edx),%edx
f0103977:	eb 22                	jmp    f010399b <getuint+0x38>
	else if (lflag)
f0103979:	85 d2                	test   %edx,%edx
f010397b:	74 10                	je     f010398d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f010397d:	8b 10                	mov    (%eax),%edx
f010397f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103982:	89 08                	mov    %ecx,(%eax)
f0103984:	8b 02                	mov    (%edx),%eax
f0103986:	ba 00 00 00 00       	mov    $0x0,%edx
f010398b:	eb 0e                	jmp    f010399b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f010398d:	8b 10                	mov    (%eax),%edx
f010398f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103992:	89 08                	mov    %ecx,(%eax)
f0103994:	8b 02                	mov    (%edx),%eax
f0103996:	ba 00 00 00 00       	mov    $0x0,%edx
}
f010399b:	5d                   	pop    %ebp
f010399c:	c3                   	ret    

f010399d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010399d:	55                   	push   %ebp
f010399e:	89 e5                	mov    %esp,%ebp
f01039a0:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01039a3:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01039a7:	8b 10                	mov    (%eax),%edx
f01039a9:	3b 50 04             	cmp    0x4(%eax),%edx
f01039ac:	73 0a                	jae    f01039b8 <sprintputch+0x1b>
		*b->buf++ = ch;
f01039ae:	8d 4a 01             	lea    0x1(%edx),%ecx
f01039b1:	89 08                	mov    %ecx,(%eax)
f01039b3:	8b 45 08             	mov    0x8(%ebp),%eax
f01039b6:	88 02                	mov    %al,(%edx)
}
f01039b8:	5d                   	pop    %ebp
f01039b9:	c3                   	ret    

f01039ba <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01039ba:	55                   	push   %ebp
f01039bb:	89 e5                	mov    %esp,%ebp
f01039bd:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01039c0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01039c3:	50                   	push   %eax
f01039c4:	ff 75 10             	pushl  0x10(%ebp)
f01039c7:	ff 75 0c             	pushl  0xc(%ebp)
f01039ca:	ff 75 08             	pushl  0x8(%ebp)
f01039cd:	e8 05 00 00 00       	call   f01039d7 <vprintfmt>
	va_end(ap);
f01039d2:	83 c4 10             	add    $0x10,%esp
}
f01039d5:	c9                   	leave  
f01039d6:	c3                   	ret    

f01039d7 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01039d7:	55                   	push   %ebp
f01039d8:	89 e5                	mov    %esp,%ebp
f01039da:	57                   	push   %edi
f01039db:	56                   	push   %esi
f01039dc:	53                   	push   %ebx
f01039dd:	83 ec 3c             	sub    $0x3c,%esp
f01039e0:	8b 75 08             	mov    0x8(%ebp),%esi
f01039e3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01039e6:	8b 7d 10             	mov    0x10(%ebp),%edi
f01039e9:	eb 12                	jmp    f01039fd <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;
	char colorcontrol[5];
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01039eb:	85 c0                	test   %eax,%eax
f01039ed:	0f 84 62 06 00 00    	je     f0104055 <vprintfmt+0x67e>
				return;
			putch(ch, putdat);
f01039f3:	83 ec 08             	sub    $0x8,%esp
f01039f6:	53                   	push   %ebx
f01039f7:	50                   	push   %eax
f01039f8:	ff d6                	call   *%esi
f01039fa:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;
	char colorcontrol[5];
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01039fd:	83 c7 01             	add    $0x1,%edi
f0103a00:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103a04:	83 f8 25             	cmp    $0x25,%eax
f0103a07:	75 e2                	jne    f01039eb <vprintfmt+0x14>
f0103a09:	c6 45 c4 20          	movb   $0x20,-0x3c(%ebp)
f0103a0d:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
f0103a14:	c7 45 c0 ff ff ff ff 	movl   $0xffffffff,-0x40(%ebp)
f0103a1b:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103a22:	ba 00 00 00 00       	mov    $0x0,%edx
f0103a27:	eb 07                	jmp    f0103a30 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103a29:	8b 7d d4             	mov    -0x2c(%ebp),%edi
					colr = COLR_BLACK;
			}
			colr |= highlight;
			break;
		case '-':
			padc = '-';
f0103a2c:	c6 45 c4 2d          	movb   $0x2d,-0x3c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103a30:	8d 47 01             	lea    0x1(%edi),%eax
f0103a33:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103a36:	0f b6 07             	movzbl (%edi),%eax
f0103a39:	0f b6 c8             	movzbl %al,%ecx
f0103a3c:	83 e8 23             	sub    $0x23,%eax
f0103a3f:	3c 55                	cmp    $0x55,%al
f0103a41:	0f 87 f3 05 00 00    	ja     f010403a <vprintfmt+0x663>
f0103a47:	0f b6 c0             	movzbl %al,%eax
f0103a4a:	ff 24 85 a0 61 10 f0 	jmp    *-0xfef9e60(,%eax,4)
f0103a51:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103a54:	c6 45 c4 30          	movb   $0x30,-0x3c(%ebp)
f0103a58:	eb d6                	jmp    f0103a30 <vprintfmt+0x59>
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {

		// flag to pad on the right
		case 'C':
			memmove(colorcontrol, fmt, sizeof(unsigned char)*3);
f0103a5a:	83 ec 04             	sub    $0x4,%esp
f0103a5d:	6a 03                	push   $0x3
f0103a5f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103a62:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103a65:	50                   	push   %eax
f0103a66:	e8 fe 08 00 00       	call   f0104369 <memmove>
			colorcontrol[3] = '\0';
f0103a6b:	c6 45 e6 00          	movb   $0x0,-0x1a(%ebp)
			fmt += 3;
f0103a6f:	83 c7 04             	add    $0x4,%edi
			if(colorcontrol[0] >= '0' && colorcontrol[0] <= '9'){
f0103a72:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f0103a76:	8d 50 d0             	lea    -0x30(%eax),%edx
f0103a79:	83 c4 10             	add    $0x10,%esp
f0103a7c:	80 fa 09             	cmp    $0x9,%dl
f0103a7f:	77 29                	ja     f0103aaa <vprintfmt+0xd3>
				colr = (colorcontrol[0] - '0') * 100 + (colorcontrol[1] - '0') * 10 + (colorcontrol[2] - '0');
f0103a81:	0f be c0             	movsbl %al,%eax
f0103a84:	83 e8 30             	sub    $0x30,%eax
f0103a87:	6b c0 64             	imul   $0x64,%eax,%eax
f0103a8a:	0f be 55 e4          	movsbl -0x1c(%ebp),%edx
f0103a8e:	8d 94 92 10 ff ff ff 	lea    -0xf0(%edx,%edx,4),%edx
f0103a95:	8d 14 50             	lea    (%eax,%edx,2),%edx
f0103a98:	0f be 45 e5          	movsbl -0x1b(%ebp),%eax
f0103a9c:	8d 44 02 d0          	lea    -0x30(%edx,%eax,1),%eax
f0103aa0:	a3 ac dc 17 f0       	mov    %eax,0xf017dcac
f0103aa5:	e9 53 ff ff ff       	jmp    f01039fd <vprintfmt+0x26>
			}
			else{
				if(strcmp(colorcontrol, "ble") == 0) colr = COLR_BLUE
f0103aaa:	83 ec 08             	sub    $0x8,%esp
f0103aad:	68 26 5f 10 f0       	push   $0xf0105f26
f0103ab2:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103ab5:	50                   	push   %eax
f0103ab6:	e8 c6 07 00 00       	call   f0104281 <strcmp>
f0103abb:	83 c4 10             	add    $0x10,%esp
f0103abe:	85 c0                	test   %eax,%eax
f0103ac0:	75 0f                	jne    f0103ad1 <vprintfmt+0xfa>
f0103ac2:	c7 05 ac dc 17 f0 01 	movl   $0x1,0xf017dcac
f0103ac9:	00 00 00 
f0103acc:	e9 2c ff ff ff       	jmp    f01039fd <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "grn") == 0) colr = COLR_GREEN
f0103ad1:	83 ec 08             	sub    $0x8,%esp
f0103ad4:	68 19 61 10 f0       	push   $0xf0106119
f0103ad9:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103adc:	50                   	push   %eax
f0103add:	e8 9f 07 00 00       	call   f0104281 <strcmp>
f0103ae2:	83 c4 10             	add    $0x10,%esp
f0103ae5:	85 c0                	test   %eax,%eax
f0103ae7:	75 0f                	jne    f0103af8 <vprintfmt+0x121>
f0103ae9:	c7 05 ac dc 17 f0 02 	movl   $0x2,0xf017dcac
f0103af0:	00 00 00 
f0103af3:	e9 05 ff ff ff       	jmp    f01039fd <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "cyn") == 0) colr = COLR_CYAN
f0103af8:	83 ec 08             	sub    $0x8,%esp
f0103afb:	68 1d 61 10 f0       	push   $0xf010611d
f0103b00:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103b03:	50                   	push   %eax
f0103b04:	e8 78 07 00 00       	call   f0104281 <strcmp>
f0103b09:	83 c4 10             	add    $0x10,%esp
f0103b0c:	85 c0                	test   %eax,%eax
f0103b0e:	75 0f                	jne    f0103b1f <vprintfmt+0x148>
f0103b10:	c7 05 ac dc 17 f0 03 	movl   $0x3,0xf017dcac
f0103b17:	00 00 00 
f0103b1a:	e9 de fe ff ff       	jmp    f01039fd <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "red") == 0) colr = COLR_RED
f0103b1f:	83 ec 08             	sub    $0x8,%esp
f0103b22:	68 21 61 10 f0       	push   $0xf0106121
f0103b27:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103b2a:	50                   	push   %eax
f0103b2b:	e8 51 07 00 00       	call   f0104281 <strcmp>
f0103b30:	83 c4 10             	add    $0x10,%esp
f0103b33:	85 c0                	test   %eax,%eax
f0103b35:	75 0f                	jne    f0103b46 <vprintfmt+0x16f>
f0103b37:	c7 05 ac dc 17 f0 04 	movl   $0x4,0xf017dcac
f0103b3e:	00 00 00 
f0103b41:	e9 b7 fe ff ff       	jmp    f01039fd <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "mag") == 0) colr = COLR_MAGENTA
f0103b46:	83 ec 08             	sub    $0x8,%esp
f0103b49:	68 25 61 10 f0       	push   $0xf0106125
f0103b4e:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103b51:	50                   	push   %eax
f0103b52:	e8 2a 07 00 00       	call   f0104281 <strcmp>
f0103b57:	83 c4 10             	add    $0x10,%esp
f0103b5a:	85 c0                	test   %eax,%eax
f0103b5c:	75 0f                	jne    f0103b6d <vprintfmt+0x196>
f0103b5e:	c7 05 ac dc 17 f0 05 	movl   $0x5,0xf017dcac
f0103b65:	00 00 00 
f0103b68:	e9 90 fe ff ff       	jmp    f01039fd <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "brw")== 0) colr = COLR_BROWN
f0103b6d:	83 ec 08             	sub    $0x8,%esp
f0103b70:	68 29 61 10 f0       	push   $0xf0106129
f0103b75:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103b78:	50                   	push   %eax
f0103b79:	e8 03 07 00 00       	call   f0104281 <strcmp>
f0103b7e:	83 c4 10             	add    $0x10,%esp
f0103b81:	85 c0                	test   %eax,%eax
f0103b83:	75 0f                	jne    f0103b94 <vprintfmt+0x1bd>
f0103b85:	c7 05 ac dc 17 f0 06 	movl   $0x6,0xf017dcac
f0103b8c:	00 00 00 
f0103b8f:	e9 69 fe ff ff       	jmp    f01039fd <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "gry") == 0) colr = COLR_GRAY
f0103b94:	83 ec 08             	sub    $0x8,%esp
f0103b97:	68 2d 61 10 f0       	push   $0xf010612d
f0103b9c:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103b9f:	50                   	push   %eax
f0103ba0:	e8 dc 06 00 00       	call   f0104281 <strcmp>
f0103ba5:	83 c4 10             	add    $0x10,%esp
f0103ba8:	83 f8 01             	cmp    $0x1,%eax
f0103bab:	19 c0                	sbb    %eax,%eax
f0103bad:	83 e0 07             	and    $0x7,%eax
f0103bb0:	a3 ac dc 17 f0       	mov    %eax,0xf017dcac
f0103bb5:	e9 43 fe ff ff       	jmp    f01039fd <vprintfmt+0x26>
					colr = COLR_BLACK;
			}
			break;
				
		case 'I':
			highlight = COLR_HIGHLIGHT;
f0103bba:	c7 05 a8 dc 17 f0 08 	movl   $0x8,0xf017dca8
f0103bc1:	00 00 00 
			memmove(colorcontrol, fmt, sizeof(unsigned char)*3);
f0103bc4:	83 ec 04             	sub    $0x4,%esp
f0103bc7:	6a 03                	push   $0x3
f0103bc9:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103bcc:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103bcf:	50                   	push   %eax
f0103bd0:	e8 94 07 00 00       	call   f0104369 <memmove>
			colorcontrol[3] = '\0';
f0103bd5:	c6 45 e6 00          	movb   $0x0,-0x1a(%ebp)
			fmt += 3;
f0103bd9:	83 c7 04             	add    $0x4,%edi
			if(colorcontrol[0] >= '0' && colorcontrol[0] <= '9'){
f0103bdc:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f0103be0:	8d 50 d0             	lea    -0x30(%eax),%edx
f0103be3:	83 c4 10             	add    $0x10,%esp
f0103be6:	80 fa 09             	cmp    $0x9,%dl
f0103be9:	77 29                	ja     f0103c14 <vprintfmt+0x23d>
				colr = (colorcontrol[0] - '0') * 100 + (colorcontrol[1] - '0') * 10 + (colorcontrol[2] - '0');
f0103beb:	0f be c0             	movsbl %al,%eax
f0103bee:	83 e8 30             	sub    $0x30,%eax
f0103bf1:	6b c0 64             	imul   $0x64,%eax,%eax
f0103bf4:	0f be 55 e4          	movsbl -0x1c(%ebp),%edx
f0103bf8:	8d 94 92 10 ff ff ff 	lea    -0xf0(%edx,%edx,4),%edx
f0103bff:	8d 14 50             	lea    (%eax,%edx,2),%edx
f0103c02:	0f be 45 e5          	movsbl -0x1b(%ebp),%eax
f0103c06:	8d 44 02 d0          	lea    -0x30(%edx,%eax,1),%eax
f0103c0a:	a3 ac dc 17 f0       	mov    %eax,0xf017dcac
f0103c0f:	e9 02 01 00 00       	jmp    f0103d16 <vprintfmt+0x33f>
			}
			else{
				if(strcmp(colorcontrol, "ble") == 0) colr = COLR_BLUE
f0103c14:	83 ec 08             	sub    $0x8,%esp
f0103c17:	68 26 5f 10 f0       	push   $0xf0105f26
f0103c1c:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103c1f:	50                   	push   %eax
f0103c20:	e8 5c 06 00 00       	call   f0104281 <strcmp>
f0103c25:	83 c4 10             	add    $0x10,%esp
f0103c28:	85 c0                	test   %eax,%eax
f0103c2a:	75 0f                	jne    f0103c3b <vprintfmt+0x264>
f0103c2c:	c7 05 ac dc 17 f0 01 	movl   $0x1,0xf017dcac
f0103c33:	00 00 00 
f0103c36:	e9 db 00 00 00       	jmp    f0103d16 <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "grn") == 0) colr = COLR_GREEN
f0103c3b:	83 ec 08             	sub    $0x8,%esp
f0103c3e:	68 19 61 10 f0       	push   $0xf0106119
f0103c43:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103c46:	50                   	push   %eax
f0103c47:	e8 35 06 00 00       	call   f0104281 <strcmp>
f0103c4c:	83 c4 10             	add    $0x10,%esp
f0103c4f:	85 c0                	test   %eax,%eax
f0103c51:	75 0f                	jne    f0103c62 <vprintfmt+0x28b>
f0103c53:	c7 05 ac dc 17 f0 02 	movl   $0x2,0xf017dcac
f0103c5a:	00 00 00 
f0103c5d:	e9 b4 00 00 00       	jmp    f0103d16 <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "cyn") == 0) colr = COLR_CYAN
f0103c62:	83 ec 08             	sub    $0x8,%esp
f0103c65:	68 1d 61 10 f0       	push   $0xf010611d
f0103c6a:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103c6d:	50                   	push   %eax
f0103c6e:	e8 0e 06 00 00       	call   f0104281 <strcmp>
f0103c73:	83 c4 10             	add    $0x10,%esp
f0103c76:	85 c0                	test   %eax,%eax
f0103c78:	75 0f                	jne    f0103c89 <vprintfmt+0x2b2>
f0103c7a:	c7 05 ac dc 17 f0 03 	movl   $0x3,0xf017dcac
f0103c81:	00 00 00 
f0103c84:	e9 8d 00 00 00       	jmp    f0103d16 <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "red") == 0) colr = COLR_RED
f0103c89:	83 ec 08             	sub    $0x8,%esp
f0103c8c:	68 21 61 10 f0       	push   $0xf0106121
f0103c91:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103c94:	50                   	push   %eax
f0103c95:	e8 e7 05 00 00       	call   f0104281 <strcmp>
f0103c9a:	83 c4 10             	add    $0x10,%esp
f0103c9d:	85 c0                	test   %eax,%eax
f0103c9f:	75 0c                	jne    f0103cad <vprintfmt+0x2d6>
f0103ca1:	c7 05 ac dc 17 f0 04 	movl   $0x4,0xf017dcac
f0103ca8:	00 00 00 
f0103cab:	eb 69                	jmp    f0103d16 <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "mag") == 0) colr = COLR_MAGENTA
f0103cad:	83 ec 08             	sub    $0x8,%esp
f0103cb0:	68 25 61 10 f0       	push   $0xf0106125
f0103cb5:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103cb8:	50                   	push   %eax
f0103cb9:	e8 c3 05 00 00       	call   f0104281 <strcmp>
f0103cbe:	83 c4 10             	add    $0x10,%esp
f0103cc1:	85 c0                	test   %eax,%eax
f0103cc3:	75 0c                	jne    f0103cd1 <vprintfmt+0x2fa>
f0103cc5:	c7 05 ac dc 17 f0 05 	movl   $0x5,0xf017dcac
f0103ccc:	00 00 00 
f0103ccf:	eb 45                	jmp    f0103d16 <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "brw")== 0) colr = COLR_BROWN
f0103cd1:	83 ec 08             	sub    $0x8,%esp
f0103cd4:	68 29 61 10 f0       	push   $0xf0106129
f0103cd9:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103cdc:	50                   	push   %eax
f0103cdd:	e8 9f 05 00 00       	call   f0104281 <strcmp>
f0103ce2:	83 c4 10             	add    $0x10,%esp
f0103ce5:	85 c0                	test   %eax,%eax
f0103ce7:	75 0c                	jne    f0103cf5 <vprintfmt+0x31e>
f0103ce9:	c7 05 ac dc 17 f0 06 	movl   $0x6,0xf017dcac
f0103cf0:	00 00 00 
f0103cf3:	eb 21                	jmp    f0103d16 <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "gry") == 0) colr = COLR_GRAY
f0103cf5:	83 ec 08             	sub    $0x8,%esp
f0103cf8:	68 2d 61 10 f0       	push   $0xf010612d
f0103cfd:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103d00:	50                   	push   %eax
f0103d01:	e8 7b 05 00 00       	call   f0104281 <strcmp>
f0103d06:	83 c4 10             	add    $0x10,%esp
f0103d09:	83 f8 01             	cmp    $0x1,%eax
f0103d0c:	19 c0                	sbb    %eax,%eax
f0103d0e:	83 e0 07             	and    $0x7,%eax
f0103d11:	a3 ac dc 17 f0       	mov    %eax,0xf017dcac
				else
					colr = COLR_BLACK;
			}
			colr |= highlight;
f0103d16:	a1 a8 dc 17 f0       	mov    0xf017dca8,%eax
f0103d1b:	09 05 ac dc 17 f0    	or     %eax,0xf017dcac
			break;
f0103d21:	e9 d7 fc ff ff       	jmp    f01039fd <vprintfmt+0x26>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d26:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103d29:	b8 00 00 00 00       	mov    $0x0,%eax
f0103d2e:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103d31:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103d34:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0103d38:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0103d3b:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0103d3e:	83 fa 09             	cmp    $0x9,%edx
f0103d41:	77 3f                	ja     f0103d82 <vprintfmt+0x3ab>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103d43:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103d46:	eb e9                	jmp    f0103d31 <vprintfmt+0x35a>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103d48:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d4b:	8d 48 04             	lea    0x4(%eax),%ecx
f0103d4e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103d51:	8b 00                	mov    (%eax),%eax
f0103d53:	89 45 c0             	mov    %eax,-0x40(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d56:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103d59:	eb 2d                	jmp    f0103d88 <vprintfmt+0x3b1>
f0103d5b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103d5e:	85 c0                	test   %eax,%eax
f0103d60:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103d65:	0f 49 c8             	cmovns %eax,%ecx
f0103d68:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d6b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103d6e:	e9 bd fc ff ff       	jmp    f0103a30 <vprintfmt+0x59>
f0103d73:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103d76:	c7 45 c8 01 00 00 00 	movl   $0x1,-0x38(%ebp)
			goto reswitch;
f0103d7d:	e9 ae fc ff ff       	jmp    f0103a30 <vprintfmt+0x59>
f0103d82:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103d85:	89 45 c0             	mov    %eax,-0x40(%ebp)

		process_precision:
			if (width < 0)
f0103d88:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0103d8c:	0f 89 9e fc ff ff    	jns    f0103a30 <vprintfmt+0x59>
				width = precision, precision = -1;
f0103d92:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0103d95:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103d98:	c7 45 c0 ff ff ff ff 	movl   $0xffffffff,-0x40(%ebp)
f0103d9f:	e9 8c fc ff ff       	jmp    f0103a30 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103da4:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103da7:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103daa:	e9 81 fc ff ff       	jmp    f0103a30 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103daf:	8b 45 14             	mov    0x14(%ebp),%eax
f0103db2:	8d 50 04             	lea    0x4(%eax),%edx
f0103db5:	89 55 14             	mov    %edx,0x14(%ebp)
f0103db8:	83 ec 08             	sub    $0x8,%esp
f0103dbb:	53                   	push   %ebx
f0103dbc:	ff 30                	pushl  (%eax)
f0103dbe:	ff d6                	call   *%esi
			break;
f0103dc0:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103dc3:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103dc6:	e9 32 fc ff ff       	jmp    f01039fd <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103dcb:	8b 45 14             	mov    0x14(%ebp),%eax
f0103dce:	8d 50 04             	lea    0x4(%eax),%edx
f0103dd1:	89 55 14             	mov    %edx,0x14(%ebp)
f0103dd4:	8b 00                	mov    (%eax),%eax
f0103dd6:	99                   	cltd   
f0103dd7:	31 d0                	xor    %edx,%eax
f0103dd9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103ddb:	83 f8 07             	cmp    $0x7,%eax
f0103dde:	7f 0b                	jg     f0103deb <vprintfmt+0x414>
f0103de0:	8b 14 85 00 63 10 f0 	mov    -0xfef9d00(,%eax,4),%edx
f0103de7:	85 d2                	test   %edx,%edx
f0103de9:	75 18                	jne    f0103e03 <vprintfmt+0x42c>
				printfmt(putch, putdat, "error %d", err);
f0103deb:	50                   	push   %eax
f0103dec:	68 31 61 10 f0       	push   $0xf0106131
f0103df1:	53                   	push   %ebx
f0103df2:	56                   	push   %esi
f0103df3:	e8 c2 fb ff ff       	call   f01039ba <printfmt>
f0103df8:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103dfb:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103dfe:	e9 fa fb ff ff       	jmp    f01039fd <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103e03:	52                   	push   %edx
f0103e04:	68 67 58 10 f0       	push   $0xf0105867
f0103e09:	53                   	push   %ebx
f0103e0a:	56                   	push   %esi
f0103e0b:	e8 aa fb ff ff       	call   f01039ba <printfmt>
f0103e10:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e13:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103e16:	e9 e2 fb ff ff       	jmp    f01039fd <vprintfmt+0x26>
f0103e1b:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0103e1e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103e21:	89 45 bc             	mov    %eax,-0x44(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103e24:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e27:	8d 48 04             	lea    0x4(%eax),%ecx
f0103e2a:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103e2d:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103e2f:	85 ff                	test   %edi,%edi
f0103e31:	b8 12 61 10 f0       	mov    $0xf0106112,%eax
f0103e36:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103e39:	80 7d c4 2d          	cmpb   $0x2d,-0x3c(%ebp)
f0103e3d:	0f 84 92 00 00 00    	je     f0103ed5 <vprintfmt+0x4fe>
f0103e43:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
f0103e47:	0f 8e 96 00 00 00    	jle    f0103ee3 <vprintfmt+0x50c>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103e4d:	83 ec 08             	sub    $0x8,%esp
f0103e50:	52                   	push   %edx
f0103e51:	57                   	push   %edi
f0103e52:	e8 5f 03 00 00       	call   f01041b6 <strnlen>
f0103e57:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0103e5a:	29 c1                	sub    %eax,%ecx
f0103e5c:	89 4d bc             	mov    %ecx,-0x44(%ebp)
f0103e5f:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103e62:	0f be 45 c4          	movsbl -0x3c(%ebp),%eax
f0103e66:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103e69:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0103e6c:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103e6e:	eb 0f                	jmp    f0103e7f <vprintfmt+0x4a8>
					putch(padc, putdat);
f0103e70:	83 ec 08             	sub    $0x8,%esp
f0103e73:	53                   	push   %ebx
f0103e74:	ff 75 d0             	pushl  -0x30(%ebp)
f0103e77:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103e79:	83 ef 01             	sub    $0x1,%edi
f0103e7c:	83 c4 10             	add    $0x10,%esp
f0103e7f:	85 ff                	test   %edi,%edi
f0103e81:	7f ed                	jg     f0103e70 <vprintfmt+0x499>
f0103e83:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0103e86:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0103e89:	85 c9                	test   %ecx,%ecx
f0103e8b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e90:	0f 49 c1             	cmovns %ecx,%eax
f0103e93:	29 c1                	sub    %eax,%ecx
f0103e95:	89 75 08             	mov    %esi,0x8(%ebp)
f0103e98:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0103e9b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103e9e:	89 cb                	mov    %ecx,%ebx
f0103ea0:	eb 4d                	jmp    f0103eef <vprintfmt+0x518>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103ea2:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
f0103ea6:	74 1b                	je     f0103ec3 <vprintfmt+0x4ec>
f0103ea8:	0f be c0             	movsbl %al,%eax
f0103eab:	83 e8 20             	sub    $0x20,%eax
f0103eae:	83 f8 5e             	cmp    $0x5e,%eax
f0103eb1:	76 10                	jbe    f0103ec3 <vprintfmt+0x4ec>
					putch('?', putdat);
f0103eb3:	83 ec 08             	sub    $0x8,%esp
f0103eb6:	ff 75 0c             	pushl  0xc(%ebp)
f0103eb9:	6a 3f                	push   $0x3f
f0103ebb:	ff 55 08             	call   *0x8(%ebp)
f0103ebe:	83 c4 10             	add    $0x10,%esp
f0103ec1:	eb 0d                	jmp    f0103ed0 <vprintfmt+0x4f9>
				else
					putch(ch, putdat);
f0103ec3:	83 ec 08             	sub    $0x8,%esp
f0103ec6:	ff 75 0c             	pushl  0xc(%ebp)
f0103ec9:	52                   	push   %edx
f0103eca:	ff 55 08             	call   *0x8(%ebp)
f0103ecd:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103ed0:	83 eb 01             	sub    $0x1,%ebx
f0103ed3:	eb 1a                	jmp    f0103eef <vprintfmt+0x518>
f0103ed5:	89 75 08             	mov    %esi,0x8(%ebp)
f0103ed8:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0103edb:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103ede:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0103ee1:	eb 0c                	jmp    f0103eef <vprintfmt+0x518>
f0103ee3:	89 75 08             	mov    %esi,0x8(%ebp)
f0103ee6:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0103ee9:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103eec:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0103eef:	83 c7 01             	add    $0x1,%edi
f0103ef2:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103ef6:	0f be d0             	movsbl %al,%edx
f0103ef9:	85 d2                	test   %edx,%edx
f0103efb:	74 23                	je     f0103f20 <vprintfmt+0x549>
f0103efd:	85 f6                	test   %esi,%esi
f0103eff:	78 a1                	js     f0103ea2 <vprintfmt+0x4cb>
f0103f01:	83 ee 01             	sub    $0x1,%esi
f0103f04:	79 9c                	jns    f0103ea2 <vprintfmt+0x4cb>
f0103f06:	89 df                	mov    %ebx,%edi
f0103f08:	8b 75 08             	mov    0x8(%ebp),%esi
f0103f0b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103f0e:	eb 18                	jmp    f0103f28 <vprintfmt+0x551>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103f10:	83 ec 08             	sub    $0x8,%esp
f0103f13:	53                   	push   %ebx
f0103f14:	6a 20                	push   $0x20
f0103f16:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103f18:	83 ef 01             	sub    $0x1,%edi
f0103f1b:	83 c4 10             	add    $0x10,%esp
f0103f1e:	eb 08                	jmp    f0103f28 <vprintfmt+0x551>
f0103f20:	89 df                	mov    %ebx,%edi
f0103f22:	8b 75 08             	mov    0x8(%ebp),%esi
f0103f25:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103f28:	85 ff                	test   %edi,%edi
f0103f2a:	7f e4                	jg     f0103f10 <vprintfmt+0x539>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103f2c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103f2f:	e9 c9 fa ff ff       	jmp    f01039fd <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103f34:	83 fa 01             	cmp    $0x1,%edx
f0103f37:	7e 16                	jle    f0103f4f <vprintfmt+0x578>
		return va_arg(*ap, long long);
f0103f39:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f3c:	8d 50 08             	lea    0x8(%eax),%edx
f0103f3f:	89 55 14             	mov    %edx,0x14(%ebp)
f0103f42:	8b 50 04             	mov    0x4(%eax),%edx
f0103f45:	8b 00                	mov    (%eax),%eax
f0103f47:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0103f4a:	89 55 cc             	mov    %edx,-0x34(%ebp)
f0103f4d:	eb 32                	jmp    f0103f81 <vprintfmt+0x5aa>
	else if (lflag)
f0103f4f:	85 d2                	test   %edx,%edx
f0103f51:	74 18                	je     f0103f6b <vprintfmt+0x594>
		return va_arg(*ap, long);
f0103f53:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f56:	8d 50 04             	lea    0x4(%eax),%edx
f0103f59:	89 55 14             	mov    %edx,0x14(%ebp)
f0103f5c:	8b 00                	mov    (%eax),%eax
f0103f5e:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0103f61:	89 c1                	mov    %eax,%ecx
f0103f63:	c1 f9 1f             	sar    $0x1f,%ecx
f0103f66:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0103f69:	eb 16                	jmp    f0103f81 <vprintfmt+0x5aa>
	else
		return va_arg(*ap, int);
f0103f6b:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f6e:	8d 50 04             	lea    0x4(%eax),%edx
f0103f71:	89 55 14             	mov    %edx,0x14(%ebp)
f0103f74:	8b 00                	mov    (%eax),%eax
f0103f76:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0103f79:	89 c1                	mov    %eax,%ecx
f0103f7b:	c1 f9 1f             	sar    $0x1f,%ecx
f0103f7e:	89 4d cc             	mov    %ecx,-0x34(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103f81:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0103f84:	8b 55 cc             	mov    -0x34(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103f87:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103f8c:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0103f90:	79 74                	jns    f0104006 <vprintfmt+0x62f>
				putch('-', putdat);
f0103f92:	83 ec 08             	sub    $0x8,%esp
f0103f95:	53                   	push   %ebx
f0103f96:	6a 2d                	push   $0x2d
f0103f98:	ff d6                	call   *%esi
				num = -(long long) num;
f0103f9a:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0103f9d:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0103fa0:	f7 d8                	neg    %eax
f0103fa2:	83 d2 00             	adc    $0x0,%edx
f0103fa5:	f7 da                	neg    %edx
f0103fa7:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103faa:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103faf:	eb 55                	jmp    f0104006 <vprintfmt+0x62f>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103fb1:	8d 45 14             	lea    0x14(%ebp),%eax
f0103fb4:	e8 aa f9 ff ff       	call   f0103963 <getuint>
			base = 10;
f0103fb9:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103fbe:	eb 46                	jmp    f0104006 <vprintfmt+0x62f>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0103fc0:	8d 45 14             	lea    0x14(%ebp),%eax
f0103fc3:	e8 9b f9 ff ff       	call   f0103963 <getuint>
			base = 8;
f0103fc8:	b9 08 00 00 00       	mov    $0x8,%ecx

			goto number;
f0103fcd:	eb 37                	jmp    f0104006 <vprintfmt+0x62f>
		// pointer
		case 'p':
			putch('0', putdat);
f0103fcf:	83 ec 08             	sub    $0x8,%esp
f0103fd2:	53                   	push   %ebx
f0103fd3:	6a 30                	push   $0x30
f0103fd5:	ff d6                	call   *%esi
			putch('x', putdat);
f0103fd7:	83 c4 08             	add    $0x8,%esp
f0103fda:	53                   	push   %ebx
f0103fdb:	6a 78                	push   $0x78
f0103fdd:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103fdf:	8b 45 14             	mov    0x14(%ebp),%eax
f0103fe2:	8d 50 04             	lea    0x4(%eax),%edx
f0103fe5:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103fe8:	8b 00                	mov    (%eax),%eax
f0103fea:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0103fef:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103ff2:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103ff7:	eb 0d                	jmp    f0104006 <vprintfmt+0x62f>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103ff9:	8d 45 14             	lea    0x14(%ebp),%eax
f0103ffc:	e8 62 f9 ff ff       	call   f0103963 <getuint>
			base = 16;
f0104001:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104006:	83 ec 0c             	sub    $0xc,%esp
f0104009:	0f be 7d c4          	movsbl -0x3c(%ebp),%edi
f010400d:	57                   	push   %edi
f010400e:	ff 75 d0             	pushl  -0x30(%ebp)
f0104011:	51                   	push   %ecx
f0104012:	52                   	push   %edx
f0104013:	50                   	push   %eax
f0104014:	89 da                	mov    %ebx,%edx
f0104016:	89 f0                	mov    %esi,%eax
f0104018:	e8 9c f8 ff ff       	call   f01038b9 <printnum>
			break;
f010401d:	83 c4 20             	add    $0x20,%esp
f0104020:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104023:	e9 d5 f9 ff ff       	jmp    f01039fd <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104028:	83 ec 08             	sub    $0x8,%esp
f010402b:	53                   	push   %ebx
f010402c:	51                   	push   %ecx
f010402d:	ff d6                	call   *%esi
			break;
f010402f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104032:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0104035:	e9 c3 f9 ff ff       	jmp    f01039fd <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010403a:	83 ec 08             	sub    $0x8,%esp
f010403d:	53                   	push   %ebx
f010403e:	6a 25                	push   $0x25
f0104040:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104042:	83 c4 10             	add    $0x10,%esp
f0104045:	eb 03                	jmp    f010404a <vprintfmt+0x673>
f0104047:	83 ef 01             	sub    $0x1,%edi
f010404a:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f010404e:	75 f7                	jne    f0104047 <vprintfmt+0x670>
f0104050:	e9 a8 f9 ff ff       	jmp    f01039fd <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0104055:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104058:	5b                   	pop    %ebx
f0104059:	5e                   	pop    %esi
f010405a:	5f                   	pop    %edi
f010405b:	5d                   	pop    %ebp
f010405c:	c3                   	ret    

f010405d <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010405d:	55                   	push   %ebp
f010405e:	89 e5                	mov    %esp,%ebp
f0104060:	83 ec 18             	sub    $0x18,%esp
f0104063:	8b 45 08             	mov    0x8(%ebp),%eax
f0104066:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104069:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010406c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104070:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104073:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010407a:	85 c0                	test   %eax,%eax
f010407c:	74 26                	je     f01040a4 <vsnprintf+0x47>
f010407e:	85 d2                	test   %edx,%edx
f0104080:	7e 22                	jle    f01040a4 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104082:	ff 75 14             	pushl  0x14(%ebp)
f0104085:	ff 75 10             	pushl  0x10(%ebp)
f0104088:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010408b:	50                   	push   %eax
f010408c:	68 9d 39 10 f0       	push   $0xf010399d
f0104091:	e8 41 f9 ff ff       	call   f01039d7 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104096:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104099:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010409c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010409f:	83 c4 10             	add    $0x10,%esp
f01040a2:	eb 05                	jmp    f01040a9 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01040a4:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01040a9:	c9                   	leave  
f01040aa:	c3                   	ret    

f01040ab <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01040ab:	55                   	push   %ebp
f01040ac:	89 e5                	mov    %esp,%ebp
f01040ae:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01040b1:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01040b4:	50                   	push   %eax
f01040b5:	ff 75 10             	pushl  0x10(%ebp)
f01040b8:	ff 75 0c             	pushl  0xc(%ebp)
f01040bb:	ff 75 08             	pushl  0x8(%ebp)
f01040be:	e8 9a ff ff ff       	call   f010405d <vsnprintf>
	va_end(ap);

	return rc;
}
f01040c3:	c9                   	leave  
f01040c4:	c3                   	ret    

f01040c5 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01040c5:	55                   	push   %ebp
f01040c6:	89 e5                	mov    %esp,%ebp
f01040c8:	57                   	push   %edi
f01040c9:	56                   	push   %esi
f01040ca:	53                   	push   %ebx
f01040cb:	83 ec 0c             	sub    $0xc,%esp
f01040ce:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01040d1:	85 c0                	test   %eax,%eax
f01040d3:	74 11                	je     f01040e6 <readline+0x21>
		cprintf("%s", prompt);
f01040d5:	83 ec 08             	sub    $0x8,%esp
f01040d8:	50                   	push   %eax
f01040d9:	68 67 58 10 f0       	push   $0xf0105867
f01040de:	e8 d4 f0 ff ff       	call   f01031b7 <cprintf>
f01040e3:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01040e6:	83 ec 0c             	sub    $0xc,%esp
f01040e9:	6a 00                	push   $0x0
f01040eb:	e8 25 c5 ff ff       	call   f0100615 <iscons>
f01040f0:	89 c7                	mov    %eax,%edi
f01040f2:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01040f5:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01040fa:	e8 05 c5 ff ff       	call   f0100604 <getchar>
f01040ff:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104101:	85 c0                	test   %eax,%eax
f0104103:	79 18                	jns    f010411d <readline+0x58>
			cprintf("read error: %e\n", c);
f0104105:	83 ec 08             	sub    $0x8,%esp
f0104108:	50                   	push   %eax
f0104109:	68 20 63 10 f0       	push   $0xf0106320
f010410e:	e8 a4 f0 ff ff       	call   f01031b7 <cprintf>
			return NULL;
f0104113:	83 c4 10             	add    $0x10,%esp
f0104116:	b8 00 00 00 00       	mov    $0x0,%eax
f010411b:	eb 79                	jmp    f0104196 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010411d:	83 f8 7f             	cmp    $0x7f,%eax
f0104120:	0f 94 c2             	sete   %dl
f0104123:	83 f8 08             	cmp    $0x8,%eax
f0104126:	0f 94 c0             	sete   %al
f0104129:	08 c2                	or     %al,%dl
f010412b:	74 1a                	je     f0104147 <readline+0x82>
f010412d:	85 f6                	test   %esi,%esi
f010412f:	7e 16                	jle    f0104147 <readline+0x82>
			if (echoing)
f0104131:	85 ff                	test   %edi,%edi
f0104133:	74 0d                	je     f0104142 <readline+0x7d>
				cputchar('\b');
f0104135:	83 ec 0c             	sub    $0xc,%esp
f0104138:	6a 08                	push   $0x8
f010413a:	e8 b5 c4 ff ff       	call   f01005f4 <cputchar>
f010413f:	83 c4 10             	add    $0x10,%esp
			i--;
f0104142:	83 ee 01             	sub    $0x1,%esi
f0104145:	eb b3                	jmp    f01040fa <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104147:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010414d:	7f 20                	jg     f010416f <readline+0xaa>
f010414f:	83 fb 1f             	cmp    $0x1f,%ebx
f0104152:	7e 1b                	jle    f010416f <readline+0xaa>
			if (echoing)
f0104154:	85 ff                	test   %edi,%edi
f0104156:	74 0c                	je     f0104164 <readline+0x9f>
				cputchar(c);
f0104158:	83 ec 0c             	sub    $0xc,%esp
f010415b:	53                   	push   %ebx
f010415c:	e8 93 c4 ff ff       	call   f01005f4 <cputchar>
f0104161:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104164:	88 9e c0 dc 17 f0    	mov    %bl,-0xfe82340(%esi)
f010416a:	8d 76 01             	lea    0x1(%esi),%esi
f010416d:	eb 8b                	jmp    f01040fa <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f010416f:	83 fb 0d             	cmp    $0xd,%ebx
f0104172:	74 05                	je     f0104179 <readline+0xb4>
f0104174:	83 fb 0a             	cmp    $0xa,%ebx
f0104177:	75 81                	jne    f01040fa <readline+0x35>
			if (echoing)
f0104179:	85 ff                	test   %edi,%edi
f010417b:	74 0d                	je     f010418a <readline+0xc5>
				cputchar('\n');
f010417d:	83 ec 0c             	sub    $0xc,%esp
f0104180:	6a 0a                	push   $0xa
f0104182:	e8 6d c4 ff ff       	call   f01005f4 <cputchar>
f0104187:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010418a:	c6 86 c0 dc 17 f0 00 	movb   $0x0,-0xfe82340(%esi)
			return buf;
f0104191:	b8 c0 dc 17 f0       	mov    $0xf017dcc0,%eax
		}
	}
}
f0104196:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104199:	5b                   	pop    %ebx
f010419a:	5e                   	pop    %esi
f010419b:	5f                   	pop    %edi
f010419c:	5d                   	pop    %ebp
f010419d:	c3                   	ret    

f010419e <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010419e:	55                   	push   %ebp
f010419f:	89 e5                	mov    %esp,%ebp
f01041a1:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01041a4:	b8 00 00 00 00       	mov    $0x0,%eax
f01041a9:	eb 03                	jmp    f01041ae <strlen+0x10>
		n++;
f01041ab:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01041ae:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01041b2:	75 f7                	jne    f01041ab <strlen+0xd>
		n++;
	return n;
}
f01041b4:	5d                   	pop    %ebp
f01041b5:	c3                   	ret    

f01041b6 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01041b6:	55                   	push   %ebp
f01041b7:	89 e5                	mov    %esp,%ebp
f01041b9:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01041bc:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01041bf:	ba 00 00 00 00       	mov    $0x0,%edx
f01041c4:	eb 03                	jmp    f01041c9 <strnlen+0x13>
		n++;
f01041c6:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01041c9:	39 c2                	cmp    %eax,%edx
f01041cb:	74 08                	je     f01041d5 <strnlen+0x1f>
f01041cd:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01041d1:	75 f3                	jne    f01041c6 <strnlen+0x10>
f01041d3:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01041d5:	5d                   	pop    %ebp
f01041d6:	c3                   	ret    

f01041d7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01041d7:	55                   	push   %ebp
f01041d8:	89 e5                	mov    %esp,%ebp
f01041da:	53                   	push   %ebx
f01041db:	8b 45 08             	mov    0x8(%ebp),%eax
f01041de:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01041e1:	89 c2                	mov    %eax,%edx
f01041e3:	83 c2 01             	add    $0x1,%edx
f01041e6:	83 c1 01             	add    $0x1,%ecx
f01041e9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01041ed:	88 5a ff             	mov    %bl,-0x1(%edx)
f01041f0:	84 db                	test   %bl,%bl
f01041f2:	75 ef                	jne    f01041e3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01041f4:	5b                   	pop    %ebx
f01041f5:	5d                   	pop    %ebp
f01041f6:	c3                   	ret    

f01041f7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01041f7:	55                   	push   %ebp
f01041f8:	89 e5                	mov    %esp,%ebp
f01041fa:	53                   	push   %ebx
f01041fb:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01041fe:	53                   	push   %ebx
f01041ff:	e8 9a ff ff ff       	call   f010419e <strlen>
f0104204:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104207:	ff 75 0c             	pushl  0xc(%ebp)
f010420a:	01 d8                	add    %ebx,%eax
f010420c:	50                   	push   %eax
f010420d:	e8 c5 ff ff ff       	call   f01041d7 <strcpy>
	return dst;
}
f0104212:	89 d8                	mov    %ebx,%eax
f0104214:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104217:	c9                   	leave  
f0104218:	c3                   	ret    

f0104219 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104219:	55                   	push   %ebp
f010421a:	89 e5                	mov    %esp,%ebp
f010421c:	56                   	push   %esi
f010421d:	53                   	push   %ebx
f010421e:	8b 75 08             	mov    0x8(%ebp),%esi
f0104221:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104224:	89 f3                	mov    %esi,%ebx
f0104226:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104229:	89 f2                	mov    %esi,%edx
f010422b:	eb 0f                	jmp    f010423c <strncpy+0x23>
		*dst++ = *src;
f010422d:	83 c2 01             	add    $0x1,%edx
f0104230:	0f b6 01             	movzbl (%ecx),%eax
f0104233:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104236:	80 39 01             	cmpb   $0x1,(%ecx)
f0104239:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010423c:	39 da                	cmp    %ebx,%edx
f010423e:	75 ed                	jne    f010422d <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104240:	89 f0                	mov    %esi,%eax
f0104242:	5b                   	pop    %ebx
f0104243:	5e                   	pop    %esi
f0104244:	5d                   	pop    %ebp
f0104245:	c3                   	ret    

f0104246 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104246:	55                   	push   %ebp
f0104247:	89 e5                	mov    %esp,%ebp
f0104249:	56                   	push   %esi
f010424a:	53                   	push   %ebx
f010424b:	8b 75 08             	mov    0x8(%ebp),%esi
f010424e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104251:	8b 55 10             	mov    0x10(%ebp),%edx
f0104254:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104256:	85 d2                	test   %edx,%edx
f0104258:	74 21                	je     f010427b <strlcpy+0x35>
f010425a:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010425e:	89 f2                	mov    %esi,%edx
f0104260:	eb 09                	jmp    f010426b <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104262:	83 c2 01             	add    $0x1,%edx
f0104265:	83 c1 01             	add    $0x1,%ecx
f0104268:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010426b:	39 c2                	cmp    %eax,%edx
f010426d:	74 09                	je     f0104278 <strlcpy+0x32>
f010426f:	0f b6 19             	movzbl (%ecx),%ebx
f0104272:	84 db                	test   %bl,%bl
f0104274:	75 ec                	jne    f0104262 <strlcpy+0x1c>
f0104276:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104278:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010427b:	29 f0                	sub    %esi,%eax
}
f010427d:	5b                   	pop    %ebx
f010427e:	5e                   	pop    %esi
f010427f:	5d                   	pop    %ebp
f0104280:	c3                   	ret    

f0104281 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104281:	55                   	push   %ebp
f0104282:	89 e5                	mov    %esp,%ebp
f0104284:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104287:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010428a:	eb 06                	jmp    f0104292 <strcmp+0x11>
		p++, q++;
f010428c:	83 c1 01             	add    $0x1,%ecx
f010428f:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104292:	0f b6 01             	movzbl (%ecx),%eax
f0104295:	84 c0                	test   %al,%al
f0104297:	74 04                	je     f010429d <strcmp+0x1c>
f0104299:	3a 02                	cmp    (%edx),%al
f010429b:	74 ef                	je     f010428c <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010429d:	0f b6 c0             	movzbl %al,%eax
f01042a0:	0f b6 12             	movzbl (%edx),%edx
f01042a3:	29 d0                	sub    %edx,%eax
}
f01042a5:	5d                   	pop    %ebp
f01042a6:	c3                   	ret    

f01042a7 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01042a7:	55                   	push   %ebp
f01042a8:	89 e5                	mov    %esp,%ebp
f01042aa:	53                   	push   %ebx
f01042ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01042ae:	8b 55 0c             	mov    0xc(%ebp),%edx
f01042b1:	89 c3                	mov    %eax,%ebx
f01042b3:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01042b6:	eb 06                	jmp    f01042be <strncmp+0x17>
		n--, p++, q++;
f01042b8:	83 c0 01             	add    $0x1,%eax
f01042bb:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01042be:	39 d8                	cmp    %ebx,%eax
f01042c0:	74 15                	je     f01042d7 <strncmp+0x30>
f01042c2:	0f b6 08             	movzbl (%eax),%ecx
f01042c5:	84 c9                	test   %cl,%cl
f01042c7:	74 04                	je     f01042cd <strncmp+0x26>
f01042c9:	3a 0a                	cmp    (%edx),%cl
f01042cb:	74 eb                	je     f01042b8 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01042cd:	0f b6 00             	movzbl (%eax),%eax
f01042d0:	0f b6 12             	movzbl (%edx),%edx
f01042d3:	29 d0                	sub    %edx,%eax
f01042d5:	eb 05                	jmp    f01042dc <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01042d7:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01042dc:	5b                   	pop    %ebx
f01042dd:	5d                   	pop    %ebp
f01042de:	c3                   	ret    

f01042df <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01042df:	55                   	push   %ebp
f01042e0:	89 e5                	mov    %esp,%ebp
f01042e2:	8b 45 08             	mov    0x8(%ebp),%eax
f01042e5:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01042e9:	eb 07                	jmp    f01042f2 <strchr+0x13>
		if (*s == c)
f01042eb:	38 ca                	cmp    %cl,%dl
f01042ed:	74 0f                	je     f01042fe <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01042ef:	83 c0 01             	add    $0x1,%eax
f01042f2:	0f b6 10             	movzbl (%eax),%edx
f01042f5:	84 d2                	test   %dl,%dl
f01042f7:	75 f2                	jne    f01042eb <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01042f9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01042fe:	5d                   	pop    %ebp
f01042ff:	c3                   	ret    

f0104300 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104300:	55                   	push   %ebp
f0104301:	89 e5                	mov    %esp,%ebp
f0104303:	8b 45 08             	mov    0x8(%ebp),%eax
f0104306:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010430a:	eb 03                	jmp    f010430f <strfind+0xf>
f010430c:	83 c0 01             	add    $0x1,%eax
f010430f:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104312:	84 d2                	test   %dl,%dl
f0104314:	74 04                	je     f010431a <strfind+0x1a>
f0104316:	38 ca                	cmp    %cl,%dl
f0104318:	75 f2                	jne    f010430c <strfind+0xc>
			break;
	return (char *) s;
}
f010431a:	5d                   	pop    %ebp
f010431b:	c3                   	ret    

f010431c <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010431c:	55                   	push   %ebp
f010431d:	89 e5                	mov    %esp,%ebp
f010431f:	57                   	push   %edi
f0104320:	56                   	push   %esi
f0104321:	53                   	push   %ebx
f0104322:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104325:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104328:	85 c9                	test   %ecx,%ecx
f010432a:	74 36                	je     f0104362 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010432c:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104332:	75 28                	jne    f010435c <memset+0x40>
f0104334:	f6 c1 03             	test   $0x3,%cl
f0104337:	75 23                	jne    f010435c <memset+0x40>
		c &= 0xFF;
f0104339:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010433d:	89 d3                	mov    %edx,%ebx
f010433f:	c1 e3 08             	shl    $0x8,%ebx
f0104342:	89 d6                	mov    %edx,%esi
f0104344:	c1 e6 18             	shl    $0x18,%esi
f0104347:	89 d0                	mov    %edx,%eax
f0104349:	c1 e0 10             	shl    $0x10,%eax
f010434c:	09 f0                	or     %esi,%eax
f010434e:	09 c2                	or     %eax,%edx
f0104350:	89 d0                	mov    %edx,%eax
f0104352:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0104354:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0104357:	fc                   	cld    
f0104358:	f3 ab                	rep stos %eax,%es:(%edi)
f010435a:	eb 06                	jmp    f0104362 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010435c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010435f:	fc                   	cld    
f0104360:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104362:	89 f8                	mov    %edi,%eax
f0104364:	5b                   	pop    %ebx
f0104365:	5e                   	pop    %esi
f0104366:	5f                   	pop    %edi
f0104367:	5d                   	pop    %ebp
f0104368:	c3                   	ret    

f0104369 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104369:	55                   	push   %ebp
f010436a:	89 e5                	mov    %esp,%ebp
f010436c:	57                   	push   %edi
f010436d:	56                   	push   %esi
f010436e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104371:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104374:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104377:	39 c6                	cmp    %eax,%esi
f0104379:	73 35                	jae    f01043b0 <memmove+0x47>
f010437b:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010437e:	39 d0                	cmp    %edx,%eax
f0104380:	73 2e                	jae    f01043b0 <memmove+0x47>
		s += n;
		d += n;
f0104382:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0104385:	89 d6                	mov    %edx,%esi
f0104387:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104389:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010438f:	75 13                	jne    f01043a4 <memmove+0x3b>
f0104391:	f6 c1 03             	test   $0x3,%cl
f0104394:	75 0e                	jne    f01043a4 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104396:	83 ef 04             	sub    $0x4,%edi
f0104399:	8d 72 fc             	lea    -0x4(%edx),%esi
f010439c:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010439f:	fd                   	std    
f01043a0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01043a2:	eb 09                	jmp    f01043ad <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01043a4:	83 ef 01             	sub    $0x1,%edi
f01043a7:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01043aa:	fd                   	std    
f01043ab:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01043ad:	fc                   	cld    
f01043ae:	eb 1d                	jmp    f01043cd <memmove+0x64>
f01043b0:	89 f2                	mov    %esi,%edx
f01043b2:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01043b4:	f6 c2 03             	test   $0x3,%dl
f01043b7:	75 0f                	jne    f01043c8 <memmove+0x5f>
f01043b9:	f6 c1 03             	test   $0x3,%cl
f01043bc:	75 0a                	jne    f01043c8 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01043be:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01043c1:	89 c7                	mov    %eax,%edi
f01043c3:	fc                   	cld    
f01043c4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01043c6:	eb 05                	jmp    f01043cd <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01043c8:	89 c7                	mov    %eax,%edi
f01043ca:	fc                   	cld    
f01043cb:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01043cd:	5e                   	pop    %esi
f01043ce:	5f                   	pop    %edi
f01043cf:	5d                   	pop    %ebp
f01043d0:	c3                   	ret    

f01043d1 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01043d1:	55                   	push   %ebp
f01043d2:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01043d4:	ff 75 10             	pushl  0x10(%ebp)
f01043d7:	ff 75 0c             	pushl  0xc(%ebp)
f01043da:	ff 75 08             	pushl  0x8(%ebp)
f01043dd:	e8 87 ff ff ff       	call   f0104369 <memmove>
}
f01043e2:	c9                   	leave  
f01043e3:	c3                   	ret    

f01043e4 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01043e4:	55                   	push   %ebp
f01043e5:	89 e5                	mov    %esp,%ebp
f01043e7:	56                   	push   %esi
f01043e8:	53                   	push   %ebx
f01043e9:	8b 45 08             	mov    0x8(%ebp),%eax
f01043ec:	8b 55 0c             	mov    0xc(%ebp),%edx
f01043ef:	89 c6                	mov    %eax,%esi
f01043f1:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01043f4:	eb 1a                	jmp    f0104410 <memcmp+0x2c>
		if (*s1 != *s2)
f01043f6:	0f b6 08             	movzbl (%eax),%ecx
f01043f9:	0f b6 1a             	movzbl (%edx),%ebx
f01043fc:	38 d9                	cmp    %bl,%cl
f01043fe:	74 0a                	je     f010440a <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104400:	0f b6 c1             	movzbl %cl,%eax
f0104403:	0f b6 db             	movzbl %bl,%ebx
f0104406:	29 d8                	sub    %ebx,%eax
f0104408:	eb 0f                	jmp    f0104419 <memcmp+0x35>
		s1++, s2++;
f010440a:	83 c0 01             	add    $0x1,%eax
f010440d:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104410:	39 f0                	cmp    %esi,%eax
f0104412:	75 e2                	jne    f01043f6 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104414:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104419:	5b                   	pop    %ebx
f010441a:	5e                   	pop    %esi
f010441b:	5d                   	pop    %ebp
f010441c:	c3                   	ret    

f010441d <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010441d:	55                   	push   %ebp
f010441e:	89 e5                	mov    %esp,%ebp
f0104420:	8b 45 08             	mov    0x8(%ebp),%eax
f0104423:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0104426:	89 c2                	mov    %eax,%edx
f0104428:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010442b:	eb 07                	jmp    f0104434 <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f010442d:	38 08                	cmp    %cl,(%eax)
f010442f:	74 07                	je     f0104438 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104431:	83 c0 01             	add    $0x1,%eax
f0104434:	39 d0                	cmp    %edx,%eax
f0104436:	72 f5                	jb     f010442d <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104438:	5d                   	pop    %ebp
f0104439:	c3                   	ret    

f010443a <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010443a:	55                   	push   %ebp
f010443b:	89 e5                	mov    %esp,%ebp
f010443d:	57                   	push   %edi
f010443e:	56                   	push   %esi
f010443f:	53                   	push   %ebx
f0104440:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104443:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104446:	eb 03                	jmp    f010444b <strtol+0x11>
		s++;
f0104448:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010444b:	0f b6 01             	movzbl (%ecx),%eax
f010444e:	3c 09                	cmp    $0x9,%al
f0104450:	74 f6                	je     f0104448 <strtol+0xe>
f0104452:	3c 20                	cmp    $0x20,%al
f0104454:	74 f2                	je     f0104448 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104456:	3c 2b                	cmp    $0x2b,%al
f0104458:	75 0a                	jne    f0104464 <strtol+0x2a>
		s++;
f010445a:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010445d:	bf 00 00 00 00       	mov    $0x0,%edi
f0104462:	eb 10                	jmp    f0104474 <strtol+0x3a>
f0104464:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104469:	3c 2d                	cmp    $0x2d,%al
f010446b:	75 07                	jne    f0104474 <strtol+0x3a>
		s++, neg = 1;
f010446d:	8d 49 01             	lea    0x1(%ecx),%ecx
f0104470:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104474:	85 db                	test   %ebx,%ebx
f0104476:	0f 94 c0             	sete   %al
f0104479:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010447f:	75 19                	jne    f010449a <strtol+0x60>
f0104481:	80 39 30             	cmpb   $0x30,(%ecx)
f0104484:	75 14                	jne    f010449a <strtol+0x60>
f0104486:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010448a:	0f 85 82 00 00 00    	jne    f0104512 <strtol+0xd8>
		s += 2, base = 16;
f0104490:	83 c1 02             	add    $0x2,%ecx
f0104493:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104498:	eb 16                	jmp    f01044b0 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f010449a:	84 c0                	test   %al,%al
f010449c:	74 12                	je     f01044b0 <strtol+0x76>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010449e:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01044a3:	80 39 30             	cmpb   $0x30,(%ecx)
f01044a6:	75 08                	jne    f01044b0 <strtol+0x76>
		s++, base = 8;
f01044a8:	83 c1 01             	add    $0x1,%ecx
f01044ab:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01044b0:	b8 00 00 00 00       	mov    $0x0,%eax
f01044b5:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01044b8:	0f b6 11             	movzbl (%ecx),%edx
f01044bb:	8d 72 d0             	lea    -0x30(%edx),%esi
f01044be:	89 f3                	mov    %esi,%ebx
f01044c0:	80 fb 09             	cmp    $0x9,%bl
f01044c3:	77 08                	ja     f01044cd <strtol+0x93>
			dig = *s - '0';
f01044c5:	0f be d2             	movsbl %dl,%edx
f01044c8:	83 ea 30             	sub    $0x30,%edx
f01044cb:	eb 22                	jmp    f01044ef <strtol+0xb5>
		else if (*s >= 'a' && *s <= 'z')
f01044cd:	8d 72 9f             	lea    -0x61(%edx),%esi
f01044d0:	89 f3                	mov    %esi,%ebx
f01044d2:	80 fb 19             	cmp    $0x19,%bl
f01044d5:	77 08                	ja     f01044df <strtol+0xa5>
			dig = *s - 'a' + 10;
f01044d7:	0f be d2             	movsbl %dl,%edx
f01044da:	83 ea 57             	sub    $0x57,%edx
f01044dd:	eb 10                	jmp    f01044ef <strtol+0xb5>
		else if (*s >= 'A' && *s <= 'Z')
f01044df:	8d 72 bf             	lea    -0x41(%edx),%esi
f01044e2:	89 f3                	mov    %esi,%ebx
f01044e4:	80 fb 19             	cmp    $0x19,%bl
f01044e7:	77 16                	ja     f01044ff <strtol+0xc5>
			dig = *s - 'A' + 10;
f01044e9:	0f be d2             	movsbl %dl,%edx
f01044ec:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01044ef:	3b 55 10             	cmp    0x10(%ebp),%edx
f01044f2:	7d 0f                	jge    f0104503 <strtol+0xc9>
			break;
		s++, val = (val * base) + dig;
f01044f4:	83 c1 01             	add    $0x1,%ecx
f01044f7:	0f af 45 10          	imul   0x10(%ebp),%eax
f01044fb:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01044fd:	eb b9                	jmp    f01044b8 <strtol+0x7e>
f01044ff:	89 c2                	mov    %eax,%edx
f0104501:	eb 02                	jmp    f0104505 <strtol+0xcb>
f0104503:	89 c2                	mov    %eax,%edx

	if (endptr)
f0104505:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104509:	74 0d                	je     f0104518 <strtol+0xde>
		*endptr = (char *) s;
f010450b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010450e:	89 0e                	mov    %ecx,(%esi)
f0104510:	eb 06                	jmp    f0104518 <strtol+0xde>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104512:	84 c0                	test   %al,%al
f0104514:	75 92                	jne    f01044a8 <strtol+0x6e>
f0104516:	eb 98                	jmp    f01044b0 <strtol+0x76>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0104518:	f7 da                	neg    %edx
f010451a:	85 ff                	test   %edi,%edi
f010451c:	0f 45 c2             	cmovne %edx,%eax
}
f010451f:	5b                   	pop    %ebx
f0104520:	5e                   	pop    %esi
f0104521:	5f                   	pop    %edi
f0104522:	5d                   	pop    %ebp
f0104523:	c3                   	ret    
f0104524:	66 90                	xchg   %ax,%ax
f0104526:	66 90                	xchg   %ax,%ax
f0104528:	66 90                	xchg   %ax,%ax
f010452a:	66 90                	xchg   %ax,%ax
f010452c:	66 90                	xchg   %ax,%ax
f010452e:	66 90                	xchg   %ax,%ax

f0104530 <__udivdi3>:
f0104530:	55                   	push   %ebp
f0104531:	57                   	push   %edi
f0104532:	56                   	push   %esi
f0104533:	83 ec 10             	sub    $0x10,%esp
f0104536:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f010453a:	8b 7c 24 20          	mov    0x20(%esp),%edi
f010453e:	8b 74 24 24          	mov    0x24(%esp),%esi
f0104542:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0104546:	85 d2                	test   %edx,%edx
f0104548:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010454c:	89 34 24             	mov    %esi,(%esp)
f010454f:	89 c8                	mov    %ecx,%eax
f0104551:	75 35                	jne    f0104588 <__udivdi3+0x58>
f0104553:	39 f1                	cmp    %esi,%ecx
f0104555:	0f 87 bd 00 00 00    	ja     f0104618 <__udivdi3+0xe8>
f010455b:	85 c9                	test   %ecx,%ecx
f010455d:	89 cd                	mov    %ecx,%ebp
f010455f:	75 0b                	jne    f010456c <__udivdi3+0x3c>
f0104561:	b8 01 00 00 00       	mov    $0x1,%eax
f0104566:	31 d2                	xor    %edx,%edx
f0104568:	f7 f1                	div    %ecx
f010456a:	89 c5                	mov    %eax,%ebp
f010456c:	89 f0                	mov    %esi,%eax
f010456e:	31 d2                	xor    %edx,%edx
f0104570:	f7 f5                	div    %ebp
f0104572:	89 c6                	mov    %eax,%esi
f0104574:	89 f8                	mov    %edi,%eax
f0104576:	f7 f5                	div    %ebp
f0104578:	89 f2                	mov    %esi,%edx
f010457a:	83 c4 10             	add    $0x10,%esp
f010457d:	5e                   	pop    %esi
f010457e:	5f                   	pop    %edi
f010457f:	5d                   	pop    %ebp
f0104580:	c3                   	ret    
f0104581:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104588:	3b 14 24             	cmp    (%esp),%edx
f010458b:	77 7b                	ja     f0104608 <__udivdi3+0xd8>
f010458d:	0f bd f2             	bsr    %edx,%esi
f0104590:	83 f6 1f             	xor    $0x1f,%esi
f0104593:	0f 84 97 00 00 00    	je     f0104630 <__udivdi3+0x100>
f0104599:	bd 20 00 00 00       	mov    $0x20,%ebp
f010459e:	89 d7                	mov    %edx,%edi
f01045a0:	89 f1                	mov    %esi,%ecx
f01045a2:	29 f5                	sub    %esi,%ebp
f01045a4:	d3 e7                	shl    %cl,%edi
f01045a6:	89 c2                	mov    %eax,%edx
f01045a8:	89 e9                	mov    %ebp,%ecx
f01045aa:	d3 ea                	shr    %cl,%edx
f01045ac:	89 f1                	mov    %esi,%ecx
f01045ae:	09 fa                	or     %edi,%edx
f01045b0:	8b 3c 24             	mov    (%esp),%edi
f01045b3:	d3 e0                	shl    %cl,%eax
f01045b5:	89 54 24 08          	mov    %edx,0x8(%esp)
f01045b9:	89 e9                	mov    %ebp,%ecx
f01045bb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01045bf:	8b 44 24 04          	mov    0x4(%esp),%eax
f01045c3:	89 fa                	mov    %edi,%edx
f01045c5:	d3 ea                	shr    %cl,%edx
f01045c7:	89 f1                	mov    %esi,%ecx
f01045c9:	d3 e7                	shl    %cl,%edi
f01045cb:	89 e9                	mov    %ebp,%ecx
f01045cd:	d3 e8                	shr    %cl,%eax
f01045cf:	09 c7                	or     %eax,%edi
f01045d1:	89 f8                	mov    %edi,%eax
f01045d3:	f7 74 24 08          	divl   0x8(%esp)
f01045d7:	89 d5                	mov    %edx,%ebp
f01045d9:	89 c7                	mov    %eax,%edi
f01045db:	f7 64 24 0c          	mull   0xc(%esp)
f01045df:	39 d5                	cmp    %edx,%ebp
f01045e1:	89 14 24             	mov    %edx,(%esp)
f01045e4:	72 11                	jb     f01045f7 <__udivdi3+0xc7>
f01045e6:	8b 54 24 04          	mov    0x4(%esp),%edx
f01045ea:	89 f1                	mov    %esi,%ecx
f01045ec:	d3 e2                	shl    %cl,%edx
f01045ee:	39 c2                	cmp    %eax,%edx
f01045f0:	73 5e                	jae    f0104650 <__udivdi3+0x120>
f01045f2:	3b 2c 24             	cmp    (%esp),%ebp
f01045f5:	75 59                	jne    f0104650 <__udivdi3+0x120>
f01045f7:	8d 47 ff             	lea    -0x1(%edi),%eax
f01045fa:	31 f6                	xor    %esi,%esi
f01045fc:	89 f2                	mov    %esi,%edx
f01045fe:	83 c4 10             	add    $0x10,%esp
f0104601:	5e                   	pop    %esi
f0104602:	5f                   	pop    %edi
f0104603:	5d                   	pop    %ebp
f0104604:	c3                   	ret    
f0104605:	8d 76 00             	lea    0x0(%esi),%esi
f0104608:	31 f6                	xor    %esi,%esi
f010460a:	31 c0                	xor    %eax,%eax
f010460c:	89 f2                	mov    %esi,%edx
f010460e:	83 c4 10             	add    $0x10,%esp
f0104611:	5e                   	pop    %esi
f0104612:	5f                   	pop    %edi
f0104613:	5d                   	pop    %ebp
f0104614:	c3                   	ret    
f0104615:	8d 76 00             	lea    0x0(%esi),%esi
f0104618:	89 f2                	mov    %esi,%edx
f010461a:	31 f6                	xor    %esi,%esi
f010461c:	89 f8                	mov    %edi,%eax
f010461e:	f7 f1                	div    %ecx
f0104620:	89 f2                	mov    %esi,%edx
f0104622:	83 c4 10             	add    $0x10,%esp
f0104625:	5e                   	pop    %esi
f0104626:	5f                   	pop    %edi
f0104627:	5d                   	pop    %ebp
f0104628:	c3                   	ret    
f0104629:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104630:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f0104634:	76 0b                	jbe    f0104641 <__udivdi3+0x111>
f0104636:	31 c0                	xor    %eax,%eax
f0104638:	3b 14 24             	cmp    (%esp),%edx
f010463b:	0f 83 37 ff ff ff    	jae    f0104578 <__udivdi3+0x48>
f0104641:	b8 01 00 00 00       	mov    $0x1,%eax
f0104646:	e9 2d ff ff ff       	jmp    f0104578 <__udivdi3+0x48>
f010464b:	90                   	nop
f010464c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104650:	89 f8                	mov    %edi,%eax
f0104652:	31 f6                	xor    %esi,%esi
f0104654:	e9 1f ff ff ff       	jmp    f0104578 <__udivdi3+0x48>
f0104659:	66 90                	xchg   %ax,%ax
f010465b:	66 90                	xchg   %ax,%ax
f010465d:	66 90                	xchg   %ax,%ax
f010465f:	90                   	nop

f0104660 <__umoddi3>:
f0104660:	55                   	push   %ebp
f0104661:	57                   	push   %edi
f0104662:	56                   	push   %esi
f0104663:	83 ec 20             	sub    $0x20,%esp
f0104666:	8b 44 24 34          	mov    0x34(%esp),%eax
f010466a:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010466e:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104672:	89 c6                	mov    %eax,%esi
f0104674:	89 44 24 10          	mov    %eax,0x10(%esp)
f0104678:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f010467c:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0104680:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104684:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0104688:	89 74 24 18          	mov    %esi,0x18(%esp)
f010468c:	85 c0                	test   %eax,%eax
f010468e:	89 c2                	mov    %eax,%edx
f0104690:	75 1e                	jne    f01046b0 <__umoddi3+0x50>
f0104692:	39 f7                	cmp    %esi,%edi
f0104694:	76 52                	jbe    f01046e8 <__umoddi3+0x88>
f0104696:	89 c8                	mov    %ecx,%eax
f0104698:	89 f2                	mov    %esi,%edx
f010469a:	f7 f7                	div    %edi
f010469c:	89 d0                	mov    %edx,%eax
f010469e:	31 d2                	xor    %edx,%edx
f01046a0:	83 c4 20             	add    $0x20,%esp
f01046a3:	5e                   	pop    %esi
f01046a4:	5f                   	pop    %edi
f01046a5:	5d                   	pop    %ebp
f01046a6:	c3                   	ret    
f01046a7:	89 f6                	mov    %esi,%esi
f01046a9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f01046b0:	39 f0                	cmp    %esi,%eax
f01046b2:	77 5c                	ja     f0104710 <__umoddi3+0xb0>
f01046b4:	0f bd e8             	bsr    %eax,%ebp
f01046b7:	83 f5 1f             	xor    $0x1f,%ebp
f01046ba:	75 64                	jne    f0104720 <__umoddi3+0xc0>
f01046bc:	8b 6c 24 14          	mov    0x14(%esp),%ebp
f01046c0:	39 6c 24 0c          	cmp    %ebp,0xc(%esp)
f01046c4:	0f 86 f6 00 00 00    	jbe    f01047c0 <__umoddi3+0x160>
f01046ca:	3b 44 24 18          	cmp    0x18(%esp),%eax
f01046ce:	0f 82 ec 00 00 00    	jb     f01047c0 <__umoddi3+0x160>
f01046d4:	8b 44 24 14          	mov    0x14(%esp),%eax
f01046d8:	8b 54 24 18          	mov    0x18(%esp),%edx
f01046dc:	83 c4 20             	add    $0x20,%esp
f01046df:	5e                   	pop    %esi
f01046e0:	5f                   	pop    %edi
f01046e1:	5d                   	pop    %ebp
f01046e2:	c3                   	ret    
f01046e3:	90                   	nop
f01046e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01046e8:	85 ff                	test   %edi,%edi
f01046ea:	89 fd                	mov    %edi,%ebp
f01046ec:	75 0b                	jne    f01046f9 <__umoddi3+0x99>
f01046ee:	b8 01 00 00 00       	mov    $0x1,%eax
f01046f3:	31 d2                	xor    %edx,%edx
f01046f5:	f7 f7                	div    %edi
f01046f7:	89 c5                	mov    %eax,%ebp
f01046f9:	8b 44 24 10          	mov    0x10(%esp),%eax
f01046fd:	31 d2                	xor    %edx,%edx
f01046ff:	f7 f5                	div    %ebp
f0104701:	89 c8                	mov    %ecx,%eax
f0104703:	f7 f5                	div    %ebp
f0104705:	eb 95                	jmp    f010469c <__umoddi3+0x3c>
f0104707:	89 f6                	mov    %esi,%esi
f0104709:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0104710:	89 c8                	mov    %ecx,%eax
f0104712:	89 f2                	mov    %esi,%edx
f0104714:	83 c4 20             	add    $0x20,%esp
f0104717:	5e                   	pop    %esi
f0104718:	5f                   	pop    %edi
f0104719:	5d                   	pop    %ebp
f010471a:	c3                   	ret    
f010471b:	90                   	nop
f010471c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104720:	b8 20 00 00 00       	mov    $0x20,%eax
f0104725:	89 e9                	mov    %ebp,%ecx
f0104727:	29 e8                	sub    %ebp,%eax
f0104729:	d3 e2                	shl    %cl,%edx
f010472b:	89 c7                	mov    %eax,%edi
f010472d:	89 44 24 18          	mov    %eax,0x18(%esp)
f0104731:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0104735:	89 f9                	mov    %edi,%ecx
f0104737:	d3 e8                	shr    %cl,%eax
f0104739:	89 c1                	mov    %eax,%ecx
f010473b:	8b 44 24 0c          	mov    0xc(%esp),%eax
f010473f:	09 d1                	or     %edx,%ecx
f0104741:	89 fa                	mov    %edi,%edx
f0104743:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0104747:	89 e9                	mov    %ebp,%ecx
f0104749:	d3 e0                	shl    %cl,%eax
f010474b:	89 f9                	mov    %edi,%ecx
f010474d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104751:	89 f0                	mov    %esi,%eax
f0104753:	d3 e8                	shr    %cl,%eax
f0104755:	89 e9                	mov    %ebp,%ecx
f0104757:	89 c7                	mov    %eax,%edi
f0104759:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f010475d:	d3 e6                	shl    %cl,%esi
f010475f:	89 d1                	mov    %edx,%ecx
f0104761:	89 fa                	mov    %edi,%edx
f0104763:	d3 e8                	shr    %cl,%eax
f0104765:	89 e9                	mov    %ebp,%ecx
f0104767:	09 f0                	or     %esi,%eax
f0104769:	8b 74 24 1c          	mov    0x1c(%esp),%esi
f010476d:	f7 74 24 10          	divl   0x10(%esp)
f0104771:	d3 e6                	shl    %cl,%esi
f0104773:	89 d1                	mov    %edx,%ecx
f0104775:	f7 64 24 0c          	mull   0xc(%esp)
f0104779:	39 d1                	cmp    %edx,%ecx
f010477b:	89 74 24 14          	mov    %esi,0x14(%esp)
f010477f:	89 d7                	mov    %edx,%edi
f0104781:	89 c6                	mov    %eax,%esi
f0104783:	72 0a                	jb     f010478f <__umoddi3+0x12f>
f0104785:	39 44 24 14          	cmp    %eax,0x14(%esp)
f0104789:	73 10                	jae    f010479b <__umoddi3+0x13b>
f010478b:	39 d1                	cmp    %edx,%ecx
f010478d:	75 0c                	jne    f010479b <__umoddi3+0x13b>
f010478f:	89 d7                	mov    %edx,%edi
f0104791:	89 c6                	mov    %eax,%esi
f0104793:	2b 74 24 0c          	sub    0xc(%esp),%esi
f0104797:	1b 7c 24 10          	sbb    0x10(%esp),%edi
f010479b:	89 ca                	mov    %ecx,%edx
f010479d:	89 e9                	mov    %ebp,%ecx
f010479f:	8b 44 24 14          	mov    0x14(%esp),%eax
f01047a3:	29 f0                	sub    %esi,%eax
f01047a5:	19 fa                	sbb    %edi,%edx
f01047a7:	d3 e8                	shr    %cl,%eax
f01047a9:	0f b6 4c 24 18       	movzbl 0x18(%esp),%ecx
f01047ae:	89 d7                	mov    %edx,%edi
f01047b0:	d3 e7                	shl    %cl,%edi
f01047b2:	89 e9                	mov    %ebp,%ecx
f01047b4:	09 f8                	or     %edi,%eax
f01047b6:	d3 ea                	shr    %cl,%edx
f01047b8:	83 c4 20             	add    $0x20,%esp
f01047bb:	5e                   	pop    %esi
f01047bc:	5f                   	pop    %edi
f01047bd:	5d                   	pop    %ebp
f01047be:	c3                   	ret    
f01047bf:	90                   	nop
f01047c0:	8b 74 24 10          	mov    0x10(%esp),%esi
f01047c4:	29 f9                	sub    %edi,%ecx
f01047c6:	19 c6                	sbb    %eax,%esi
f01047c8:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f01047cc:	89 74 24 18          	mov    %esi,0x18(%esp)
f01047d0:	e9 ff fe ff ff       	jmp    f01046d4 <__umoddi3+0x74>
