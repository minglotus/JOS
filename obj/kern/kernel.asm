
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
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 40 1c 10 f0       	push   $0xf0101c40
f0100050:	e8 3a 09 00 00       	call   f010098f <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 e9 06 00 00       	call   f0100764 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 5c 1c 10 f0       	push   $0xf0101c5c
f0100087:	e8 03 09 00 00       	call   f010098f <cprintf>
f010008c:	83 c4 10             	add    $0x10,%esp
}
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 84 29 11 f0       	mov    $0xf0112984,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 9c 16 00 00       	call   f010174d <memset>
//	int x = 1, y = 3, z = 4;
//	cprintf("x %d, y %x, z %d\n", x, y, z);
	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 8b 04 00 00       	call   f0100541 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 77 1c 10 f0       	push   $0xf0101c77
f01000c3:	e8 c7 08 00 00       	call   f010098f <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 04 07 00 00       	call   f01007e5 <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 80 29 11 f0 00 	cmpl   $0x0,0xf0112980
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 80 29 11 f0    	mov    %esi,0xf0112980

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 92 1c 10 f0       	push   $0xf0101c92
f0100110:	e8 7a 08 00 00       	call   f010098f <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 4a 08 00 00       	call   f0100969 <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 ce 1c 10 f0 	movl   $0xf0101cce,(%esp)
f0100126:	e8 64 08 00 00       	call   f010098f <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 ad 06 00 00       	call   f01007e5 <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 aa 1c 10 f0       	push   $0xf0101caa
f0100152:	e8 38 08 00 00       	call   f010098f <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 06 08 00 00       	call   f0100969 <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 ce 1c 10 f0 	movl   $0xf0101cce,(%esp)
f010016a:	e8 20 08 00 00       	call   f010098f <cprintf>
	va_end(ap);
f010016f:	83 c4 10             	add    $0x10,%esp
}
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    

f0100177 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100180:	a8 01                	test   $0x1,%al
f0100182:	74 08                	je     f010018c <serial_proc_data+0x15>
f0100184:	b2 f8                	mov    $0xf8,%dl
f0100186:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100187:	0f b6 c0             	movzbl %al,%eax
f010018a:	eb 05                	jmp    f0100191 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010018c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100191:	5d                   	pop    %ebp
f0100192:	c3                   	ret    

f0100193 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100193:	55                   	push   %ebp
f0100194:	89 e5                	mov    %esp,%ebp
f0100196:	53                   	push   %ebx
f0100197:	83 ec 04             	sub    $0x4,%esp
f010019a:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019c:	eb 2a                	jmp    f01001c8 <cons_intr+0x35>
		if (c == 0)
f010019e:	85 d2                	test   %edx,%edx
f01001a0:	74 26                	je     f01001c8 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a2:	a1 44 25 11 f0       	mov    0xf0112544,%eax
f01001a7:	8d 48 01             	lea    0x1(%eax),%ecx
f01001aa:	89 0d 44 25 11 f0    	mov    %ecx,0xf0112544
f01001b0:	88 90 40 23 11 f0    	mov    %dl,-0xfeedcc0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001b6:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001bc:	75 0a                	jne    f01001c8 <cons_intr+0x35>
			cons.wpos = 0;
f01001be:	c7 05 44 25 11 f0 00 	movl   $0x0,0xf0112544
f01001c5:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001c8:	ff d3                	call   *%ebx
f01001ca:	89 c2                	mov    %eax,%edx
f01001cc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001cf:	75 cd                	jne    f010019e <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d1:	83 c4 04             	add    $0x4,%esp
f01001d4:	5b                   	pop    %ebx
f01001d5:	5d                   	pop    %ebp
f01001d6:	c3                   	ret    

f01001d7 <kbd_proc_data>:
f01001d7:	ba 64 00 00 00       	mov    $0x64,%edx
f01001dc:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001dd:	a8 01                	test   $0x1,%al
f01001df:	0f 84 f0 00 00 00    	je     f01002d5 <kbd_proc_data+0xfe>
f01001e5:	b2 60                	mov    $0x60,%dl
f01001e7:	ec                   	in     (%dx),%al
f01001e8:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001ea:	3c e0                	cmp    $0xe0,%al
f01001ec:	75 0d                	jne    f01001fb <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f01001ee:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f01001f5:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001fa:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001fb:	55                   	push   %ebp
f01001fc:	89 e5                	mov    %esp,%ebp
f01001fe:	53                   	push   %ebx
f01001ff:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100202:	84 c0                	test   %al,%al
f0100204:	79 36                	jns    f010023c <kbd_proc_data+0x65>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100206:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010020c:	89 cb                	mov    %ecx,%ebx
f010020e:	83 e3 40             	and    $0x40,%ebx
f0100211:	83 e0 7f             	and    $0x7f,%eax
f0100214:	85 db                	test   %ebx,%ebx
f0100216:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100219:	0f b6 d2             	movzbl %dl,%edx
f010021c:	0f b6 82 40 1e 10 f0 	movzbl -0xfefe1c0(%edx),%eax
f0100223:	83 c8 40             	or     $0x40,%eax
f0100226:	0f b6 c0             	movzbl %al,%eax
f0100229:	f7 d0                	not    %eax
f010022b:	21 c8                	and    %ecx,%eax
f010022d:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f0100232:	b8 00 00 00 00       	mov    $0x0,%eax
f0100237:	e9 a1 00 00 00       	jmp    f01002dd <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f010023c:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100242:	f6 c1 40             	test   $0x40,%cl
f0100245:	74 0e                	je     f0100255 <kbd_proc_data+0x7e>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100247:	83 c8 80             	or     $0xffffff80,%eax
f010024a:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010024c:	83 e1 bf             	and    $0xffffffbf,%ecx
f010024f:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f0100255:	0f b6 c2             	movzbl %dl,%eax
f0100258:	0f b6 90 40 1e 10 f0 	movzbl -0xfefe1c0(%eax),%edx
f010025f:	0b 15 00 23 11 f0    	or     0xf0112300,%edx
	shift ^= togglecode[data];
f0100265:	0f b6 88 40 1d 10 f0 	movzbl -0xfefe2c0(%eax),%ecx
f010026c:	31 ca                	xor    %ecx,%edx
f010026e:	89 15 00 23 11 f0    	mov    %edx,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100274:	89 d1                	mov    %edx,%ecx
f0100276:	83 e1 03             	and    $0x3,%ecx
f0100279:	8b 0c 8d 00 1d 10 f0 	mov    -0xfefe300(,%ecx,4),%ecx
f0100280:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f0100284:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f0100287:	f6 c2 08             	test   $0x8,%dl
f010028a:	74 1b                	je     f01002a7 <kbd_proc_data+0xd0>
		if ('a' <= c && c <= 'z')
f010028c:	89 d8                	mov    %ebx,%eax
f010028e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100291:	83 f9 19             	cmp    $0x19,%ecx
f0100294:	77 05                	ja     f010029b <kbd_proc_data+0xc4>
			c += 'A' - 'a';
f0100296:	83 eb 20             	sub    $0x20,%ebx
f0100299:	eb 0c                	jmp    f01002a7 <kbd_proc_data+0xd0>
		else if ('A' <= c && c <= 'Z')
f010029b:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f010029e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002a1:	83 f8 19             	cmp    $0x19,%eax
f01002a4:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002a7:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002ad:	75 2c                	jne    f01002db <kbd_proc_data+0x104>
f01002af:	f7 d2                	not    %edx
f01002b1:	f6 c2 06             	test   $0x6,%dl
f01002b4:	75 25                	jne    f01002db <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01002b6:	83 ec 0c             	sub    $0xc,%esp
f01002b9:	68 c4 1c 10 f0       	push   $0xf0101cc4
f01002be:	e8 cc 06 00 00       	call   f010098f <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c3:	ba 92 00 00 00       	mov    $0x92,%edx
f01002c8:	b8 03 00 00 00       	mov    $0x3,%eax
f01002cd:	ee                   	out    %al,(%dx)
f01002ce:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d1:	89 d8                	mov    %ebx,%eax
f01002d3:	eb 08                	jmp    f01002dd <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002da:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002db:	89 d8                	mov    %ebx,%eax
}
f01002dd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002e0:	c9                   	leave  
f01002e1:	c3                   	ret    

f01002e2 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002e2:	55                   	push   %ebp
f01002e3:	89 e5                	mov    %esp,%ebp
f01002e5:	57                   	push   %edi
f01002e6:	56                   	push   %esi
f01002e7:	53                   	push   %ebx
f01002e8:	83 ec 0c             	sub    $0xc,%esp
f01002eb:	89 c6                	mov    %eax,%esi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002ed:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f2:	bf fd 03 00 00       	mov    $0x3fd,%edi
f01002f7:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002fc:	eb 09                	jmp    f0100307 <cons_putc+0x25>
f01002fe:	89 ca                	mov    %ecx,%edx
f0100300:	ec                   	in     (%dx),%al
f0100301:	ec                   	in     (%dx),%al
f0100302:	ec                   	in     (%dx),%al
f0100303:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100304:	83 c3 01             	add    $0x1,%ebx
f0100307:	89 fa                	mov    %edi,%edx
f0100309:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010030a:	a8 20                	test   $0x20,%al
f010030c:	75 08                	jne    f0100316 <cons_putc+0x34>
f010030e:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100314:	7e e8                	jle    f01002fe <cons_putc+0x1c>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100316:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010031b:	89 f0                	mov    %esi,%eax
f010031d:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010031e:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100323:	bf 79 03 00 00       	mov    $0x379,%edi
f0100328:	b9 84 00 00 00       	mov    $0x84,%ecx
f010032d:	eb 09                	jmp    f0100338 <cons_putc+0x56>
f010032f:	89 ca                	mov    %ecx,%edx
f0100331:	ec                   	in     (%dx),%al
f0100332:	ec                   	in     (%dx),%al
f0100333:	ec                   	in     (%dx),%al
f0100334:	ec                   	in     (%dx),%al
f0100335:	83 c3 01             	add    $0x1,%ebx
f0100338:	89 fa                	mov    %edi,%edx
f010033a:	ec                   	in     (%dx),%al
f010033b:	84 c0                	test   %al,%al
f010033d:	78 08                	js     f0100347 <cons_putc+0x65>
f010033f:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100345:	7e e8                	jle    f010032f <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100347:	ba 78 03 00 00       	mov    $0x378,%edx
f010034c:	89 f0                	mov    %esi,%eax
f010034e:	ee                   	out    %al,(%dx)
f010034f:	b2 7a                	mov    $0x7a,%dl
f0100351:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100356:	ee                   	out    %al,(%dx)
f0100357:	b8 08 00 00 00       	mov    $0x8,%eax
f010035c:	ee                   	out    %al,(%dx)


static void
cga_putc(int c)
{
	c = c + (colr << 8);
f010035d:	a1 5c 25 11 f0       	mov    0xf011255c,%eax
f0100362:	c1 e0 08             	shl    $0x8,%eax
f0100365:	01 f0                	add    %esi,%eax
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100367:	89 c1                	mov    %eax,%ecx
f0100369:	81 e1 00 ff ff ff    	and    $0xffffff00,%ecx
		c |= 0x0700;
f010036f:	89 c2                	mov    %eax,%edx
f0100371:	80 ce 07             	or     $0x7,%dh
f0100374:	85 c9                	test   %ecx,%ecx
f0100376:	0f 44 c2             	cmove  %edx,%eax

	switch (c & 0xff) {
f0100379:	0f b6 d0             	movzbl %al,%edx
f010037c:	83 fa 09             	cmp    $0x9,%edx
f010037f:	74 72                	je     f01003f3 <cons_putc+0x111>
f0100381:	83 fa 09             	cmp    $0x9,%edx
f0100384:	7f 0a                	jg     f0100390 <cons_putc+0xae>
f0100386:	83 fa 08             	cmp    $0x8,%edx
f0100389:	74 14                	je     f010039f <cons_putc+0xbd>
f010038b:	e9 97 00 00 00       	jmp    f0100427 <cons_putc+0x145>
f0100390:	83 fa 0a             	cmp    $0xa,%edx
f0100393:	74 38                	je     f01003cd <cons_putc+0xeb>
f0100395:	83 fa 0d             	cmp    $0xd,%edx
f0100398:	74 3b                	je     f01003d5 <cons_putc+0xf3>
f010039a:	e9 88 00 00 00       	jmp    f0100427 <cons_putc+0x145>
	case '\b':
		if (crt_pos > 0) {
f010039f:	0f b7 15 48 25 11 f0 	movzwl 0xf0112548,%edx
f01003a6:	66 85 d2             	test   %dx,%dx
f01003a9:	0f 84 e4 00 00 00    	je     f0100493 <cons_putc+0x1b1>
			crt_pos--;
f01003af:	83 ea 01             	sub    $0x1,%edx
f01003b2:	66 89 15 48 25 11 f0 	mov    %dx,0xf0112548
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003b9:	0f b7 d2             	movzwl %dx,%edx
f01003bc:	b0 00                	mov    $0x0,%al
f01003be:	83 c8 20             	or     $0x20,%eax
f01003c1:	8b 0d 4c 25 11 f0    	mov    0xf011254c,%ecx
f01003c7:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f01003cb:	eb 78                	jmp    f0100445 <cons_putc+0x163>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003cd:	66 83 05 48 25 11 f0 	addw   $0x50,0xf0112548
f01003d4:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003d5:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f01003dc:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003e2:	c1 e8 16             	shr    $0x16,%eax
f01003e5:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003e8:	c1 e0 04             	shl    $0x4,%eax
f01003eb:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
f01003f1:	eb 52                	jmp    f0100445 <cons_putc+0x163>
		break;
	case '\t':
		cons_putc(' ');
f01003f3:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f8:	e8 e5 fe ff ff       	call   f01002e2 <cons_putc>
		cons_putc(' ');
f01003fd:	b8 20 00 00 00       	mov    $0x20,%eax
f0100402:	e8 db fe ff ff       	call   f01002e2 <cons_putc>
		cons_putc(' ');
f0100407:	b8 20 00 00 00       	mov    $0x20,%eax
f010040c:	e8 d1 fe ff ff       	call   f01002e2 <cons_putc>
		cons_putc(' ');
f0100411:	b8 20 00 00 00       	mov    $0x20,%eax
f0100416:	e8 c7 fe ff ff       	call   f01002e2 <cons_putc>
		cons_putc(' ');
f010041b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100420:	e8 bd fe ff ff       	call   f01002e2 <cons_putc>
f0100425:	eb 1e                	jmp    f0100445 <cons_putc+0x163>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100427:	0f b7 15 48 25 11 f0 	movzwl 0xf0112548,%edx
f010042e:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100431:	66 89 0d 48 25 11 f0 	mov    %cx,0xf0112548
f0100438:	0f b7 d2             	movzwl %dx,%edx
f010043b:	8b 0d 4c 25 11 f0    	mov    0xf011254c,%ecx
f0100441:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100445:	66 81 3d 48 25 11 f0 	cmpw   $0x7cf,0xf0112548
f010044c:	cf 07 
f010044e:	76 43                	jbe    f0100493 <cons_putc+0x1b1>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100450:	a1 4c 25 11 f0       	mov    0xf011254c,%eax
f0100455:	83 ec 04             	sub    $0x4,%esp
f0100458:	68 00 0f 00 00       	push   $0xf00
f010045d:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100463:	52                   	push   %edx
f0100464:	50                   	push   %eax
f0100465:	e8 30 13 00 00       	call   f010179a <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010046a:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f0100470:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100476:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010047c:	83 c4 10             	add    $0x10,%esp
f010047f:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100484:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100487:	39 d0                	cmp    %edx,%eax
f0100489:	75 f4                	jne    f010047f <cons_putc+0x19d>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010048b:	66 83 2d 48 25 11 f0 	subw   $0x50,0xf0112548
f0100492:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100493:	8b 0d 50 25 11 f0    	mov    0xf0112550,%ecx
f0100499:	b8 0e 00 00 00       	mov    $0xe,%eax
f010049e:	89 ca                	mov    %ecx,%edx
f01004a0:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004a1:	0f b7 1d 48 25 11 f0 	movzwl 0xf0112548,%ebx
f01004a8:	8d 71 01             	lea    0x1(%ecx),%esi
f01004ab:	89 d8                	mov    %ebx,%eax
f01004ad:	66 c1 e8 08          	shr    $0x8,%ax
f01004b1:	89 f2                	mov    %esi,%edx
f01004b3:	ee                   	out    %al,(%dx)
f01004b4:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004b9:	89 ca                	mov    %ecx,%edx
f01004bb:	ee                   	out    %al,(%dx)
f01004bc:	89 d8                	mov    %ebx,%eax
f01004be:	89 f2                	mov    %esi,%edx
f01004c0:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004c1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004c4:	5b                   	pop    %ebx
f01004c5:	5e                   	pop    %esi
f01004c6:	5f                   	pop    %edi
f01004c7:	5d                   	pop    %ebp
f01004c8:	c3                   	ret    

f01004c9 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004c9:	80 3d 54 25 11 f0 00 	cmpb   $0x0,0xf0112554
f01004d0:	74 11                	je     f01004e3 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004d2:	55                   	push   %ebp
f01004d3:	89 e5                	mov    %esp,%ebp
f01004d5:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004d8:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f01004dd:	e8 b1 fc ff ff       	call   f0100193 <cons_intr>
}
f01004e2:	c9                   	leave  
f01004e3:	f3 c3                	repz ret 

f01004e5 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004e5:	55                   	push   %ebp
f01004e6:	89 e5                	mov    %esp,%ebp
f01004e8:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004eb:	b8 d7 01 10 f0       	mov    $0xf01001d7,%eax
f01004f0:	e8 9e fc ff ff       	call   f0100193 <cons_intr>
}
f01004f5:	c9                   	leave  
f01004f6:	c3                   	ret    

f01004f7 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004f7:	55                   	push   %ebp
f01004f8:	89 e5                	mov    %esp,%ebp
f01004fa:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004fd:	e8 c7 ff ff ff       	call   f01004c9 <serial_intr>
	kbd_intr();
f0100502:	e8 de ff ff ff       	call   f01004e5 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100507:	a1 40 25 11 f0       	mov    0xf0112540,%eax
f010050c:	3b 05 44 25 11 f0    	cmp    0xf0112544,%eax
f0100512:	74 26                	je     f010053a <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100514:	8d 50 01             	lea    0x1(%eax),%edx
f0100517:	89 15 40 25 11 f0    	mov    %edx,0xf0112540
f010051d:	0f b6 88 40 23 11 f0 	movzbl -0xfeedcc0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100524:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100526:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010052c:	75 11                	jne    f010053f <cons_getc+0x48>
			cons.rpos = 0;
f010052e:	c7 05 40 25 11 f0 00 	movl   $0x0,0xf0112540
f0100535:	00 00 00 
f0100538:	eb 05                	jmp    f010053f <cons_getc+0x48>
		return c;
	}
	return 0;
f010053a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010053f:	c9                   	leave  
f0100540:	c3                   	ret    

f0100541 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100541:	55                   	push   %ebp
f0100542:	89 e5                	mov    %esp,%ebp
f0100544:	57                   	push   %edi
f0100545:	56                   	push   %esi
f0100546:	53                   	push   %ebx
f0100547:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010054a:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100551:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100558:	5a a5 
	if (*cp != 0xA55A) {
f010055a:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100561:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100565:	74 11                	je     f0100578 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100567:	c7 05 50 25 11 f0 b4 	movl   $0x3b4,0xf0112550
f010056e:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100571:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100576:	eb 16                	jmp    f010058e <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100578:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010057f:	c7 05 50 25 11 f0 d4 	movl   $0x3d4,0xf0112550
f0100586:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100589:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010058e:	8b 3d 50 25 11 f0    	mov    0xf0112550,%edi
f0100594:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100599:	89 fa                	mov    %edi,%edx
f010059b:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010059c:	8d 4f 01             	lea    0x1(%edi),%ecx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010059f:	89 ca                	mov    %ecx,%edx
f01005a1:	ec                   	in     (%dx),%al
f01005a2:	0f b6 c0             	movzbl %al,%eax
f01005a5:	c1 e0 08             	shl    $0x8,%eax
f01005a8:	89 c3                	mov    %eax,%ebx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005aa:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005af:	89 fa                	mov    %edi,%edx
f01005b1:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b2:	89 ca                	mov    %ecx,%edx
f01005b4:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005b5:	89 35 4c 25 11 f0    	mov    %esi,0xf011254c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005bb:	0f b6 c8             	movzbl %al,%ecx
f01005be:	89 d8                	mov    %ebx,%eax
f01005c0:	09 c8                	or     %ecx,%eax

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005c2:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c8:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01005cd:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d2:	89 da                	mov    %ebx,%edx
f01005d4:	ee                   	out    %al,(%dx)
f01005d5:	b2 fb                	mov    $0xfb,%dl
f01005d7:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005dc:	ee                   	out    %al,(%dx)
f01005dd:	be f8 03 00 00       	mov    $0x3f8,%esi
f01005e2:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005e7:	89 f2                	mov    %esi,%edx
f01005e9:	ee                   	out    %al,(%dx)
f01005ea:	b2 f9                	mov    $0xf9,%dl
f01005ec:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f1:	ee                   	out    %al,(%dx)
f01005f2:	b2 fb                	mov    $0xfb,%dl
f01005f4:	b8 03 00 00 00       	mov    $0x3,%eax
f01005f9:	ee                   	out    %al,(%dx)
f01005fa:	b2 fc                	mov    $0xfc,%dl
f01005fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0100601:	ee                   	out    %al,(%dx)
f0100602:	b2 f9                	mov    $0xf9,%dl
f0100604:	b8 01 00 00 00       	mov    $0x1,%eax
f0100609:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010060a:	b2 fd                	mov    $0xfd,%dl
f010060c:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010060d:	3c ff                	cmp    $0xff,%al
f010060f:	0f 95 c1             	setne  %cl
f0100612:	88 0d 54 25 11 f0    	mov    %cl,0xf0112554
f0100618:	89 da                	mov    %ebx,%edx
f010061a:	ec                   	in     (%dx),%al
f010061b:	89 f2                	mov    %esi,%edx
f010061d:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010061e:	84 c9                	test   %cl,%cl
f0100620:	75 10                	jne    f0100632 <cons_init+0xf1>
		cprintf("Serial port does not exist!\n");
f0100622:	83 ec 0c             	sub    $0xc,%esp
f0100625:	68 d0 1c 10 f0       	push   $0xf0101cd0
f010062a:	e8 60 03 00 00       	call   f010098f <cprintf>
f010062f:	83 c4 10             	add    $0x10,%esp
}
f0100632:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100635:	5b                   	pop    %ebx
f0100636:	5e                   	pop    %esi
f0100637:	5f                   	pop    %edi
f0100638:	5d                   	pop    %ebp
f0100639:	c3                   	ret    

f010063a <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010063a:	55                   	push   %ebp
f010063b:	89 e5                	mov    %esp,%ebp
f010063d:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100640:	8b 45 08             	mov    0x8(%ebp),%eax
f0100643:	e8 9a fc ff ff       	call   f01002e2 <cons_putc>
}
f0100648:	c9                   	leave  
f0100649:	c3                   	ret    

f010064a <getchar>:

int
getchar(void)
{
f010064a:	55                   	push   %ebp
f010064b:	89 e5                	mov    %esp,%ebp
f010064d:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100650:	e8 a2 fe ff ff       	call   f01004f7 <cons_getc>
f0100655:	85 c0                	test   %eax,%eax
f0100657:	74 f7                	je     f0100650 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100659:	c9                   	leave  
f010065a:	c3                   	ret    

f010065b <iscons>:

int
iscons(int fdnum)
{
f010065b:	55                   	push   %ebp
f010065c:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010065e:	b8 01 00 00 00       	mov    $0x1,%eax
f0100663:	5d                   	pop    %ebp
f0100664:	c3                   	ret    

f0100665 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100665:	55                   	push   %ebp
f0100666:	89 e5                	mov    %esp,%ebp
f0100668:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010066b:	68 40 1f 10 f0       	push   $0xf0101f40
f0100670:	68 5e 1f 10 f0       	push   $0xf0101f5e
f0100675:	68 63 1f 10 f0       	push   $0xf0101f63
f010067a:	e8 10 03 00 00       	call   f010098f <cprintf>
f010067f:	83 c4 0c             	add    $0xc,%esp
f0100682:	68 14 20 10 f0       	push   $0xf0102014
f0100687:	68 6c 1f 10 f0       	push   $0xf0101f6c
f010068c:	68 63 1f 10 f0       	push   $0xf0101f63
f0100691:	e8 f9 02 00 00       	call   f010098f <cprintf>
f0100696:	83 c4 0c             	add    $0xc,%esp
f0100699:	68 3c 20 10 f0       	push   $0xf010203c
f010069e:	68 75 1f 10 f0       	push   $0xf0101f75
f01006a3:	68 63 1f 10 f0       	push   $0xf0101f63
f01006a8:	e8 e2 02 00 00       	call   f010098f <cprintf>
	return 0;
}
f01006ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01006b2:	c9                   	leave  
f01006b3:	c3                   	ret    

f01006b4 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006b4:	55                   	push   %ebp
f01006b5:	89 e5                	mov    %esp,%ebp
f01006b7:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006ba:	68 7f 1f 10 f0       	push   $0xf0101f7f
f01006bf:	e8 cb 02 00 00       	call   f010098f <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006c4:	83 c4 08             	add    $0x8,%esp
f01006c7:	68 0c 00 10 00       	push   $0x10000c
f01006cc:	68 6c 20 10 f0       	push   $0xf010206c
f01006d1:	e8 b9 02 00 00       	call   f010098f <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006d6:	83 c4 0c             	add    $0xc,%esp
f01006d9:	68 0c 00 10 00       	push   $0x10000c
f01006de:	68 0c 00 10 f0       	push   $0xf010000c
f01006e3:	68 94 20 10 f0       	push   $0xf0102094
f01006e8:	e8 a2 02 00 00       	call   f010098f <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006ed:	83 c4 0c             	add    $0xc,%esp
f01006f0:	68 05 1c 10 00       	push   $0x101c05
f01006f5:	68 05 1c 10 f0       	push   $0xf0101c05
f01006fa:	68 b8 20 10 f0       	push   $0xf01020b8
f01006ff:	e8 8b 02 00 00       	call   f010098f <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100704:	83 c4 0c             	add    $0xc,%esp
f0100707:	68 00 23 11 00       	push   $0x112300
f010070c:	68 00 23 11 f0       	push   $0xf0112300
f0100711:	68 dc 20 10 f0       	push   $0xf01020dc
f0100716:	e8 74 02 00 00       	call   f010098f <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010071b:	83 c4 0c             	add    $0xc,%esp
f010071e:	68 84 29 11 00       	push   $0x112984
f0100723:	68 84 29 11 f0       	push   $0xf0112984
f0100728:	68 00 21 10 f0       	push   $0xf0102100
f010072d:	e8 5d 02 00 00       	call   f010098f <cprintf>
f0100732:	b8 83 2d 11 f0       	mov    $0xf0112d83,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100737:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010073c:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f010073f:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100744:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010074a:	85 c0                	test   %eax,%eax
f010074c:	0f 48 c2             	cmovs  %edx,%eax
f010074f:	c1 f8 0a             	sar    $0xa,%eax
f0100752:	50                   	push   %eax
f0100753:	68 24 21 10 f0       	push   $0xf0102124
f0100758:	e8 32 02 00 00       	call   f010098f <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010075d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100762:	c9                   	leave  
f0100763:	c3                   	ret    

f0100764 <mon_backtrace>:
}*/


int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100764:	55                   	push   %ebp
f0100765:	89 e5                	mov    %esp,%ebp
f0100767:	57                   	push   %edi
f0100768:	56                   	push   %esi
f0100769:	53                   	push   %ebx
f010076a:	83 ec 38             	sub    $0x38,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010076d:	89 ee                	mov    %ebp,%esi
	uint32_t *ebp = (uint32_t*)read_ebp();
f010076f:	89 f3                	mov    %esi,%ebx
	uint32_t *eip = ebp + 1;
f0100771:	83 c6 04             	add    $0x4,%esi
	cprintf("Stack backtrace:\n");
f0100774:	68 98 1f 10 f0       	push   $0xf0101f98
f0100779:	e8 11 02 00 00       	call   f010098f <cprintf>
	while(ebp){
f010077e:	83 c4 10             	add    $0x10,%esp
		cprintf("ebp %08x   eip %08x  args %08x %08x %08x %08x %08x\n",ebp, *eip, *(ebp + 2), *(ebp+3),*(ebp + 4), *(ebp + 5), *(ebp + 6));
		struct Eipdebuginfo info;
		debuginfo_eip(*eip,&info);
f0100781:	8d 7d d0             	lea    -0x30(%ebp),%edi
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t *ebp = (uint32_t*)read_ebp();
	uint32_t *eip = ebp + 1;
	cprintf("Stack backtrace:\n");
	while(ebp){
f0100784:	eb 4e                	jmp    f01007d4 <mon_backtrace+0x70>
		cprintf("ebp %08x   eip %08x  args %08x %08x %08x %08x %08x\n",ebp, *eip, *(ebp + 2), *(ebp+3),*(ebp + 4), *(ebp + 5), *(ebp + 6));
f0100786:	ff 73 18             	pushl  0x18(%ebx)
f0100789:	ff 73 14             	pushl  0x14(%ebx)
f010078c:	ff 73 10             	pushl  0x10(%ebx)
f010078f:	ff 73 0c             	pushl  0xc(%ebx)
f0100792:	ff 73 08             	pushl  0x8(%ebx)
f0100795:	ff 36                	pushl  (%esi)
f0100797:	53                   	push   %ebx
f0100798:	68 50 21 10 f0       	push   $0xf0102150
f010079d:	e8 ed 01 00 00       	call   f010098f <cprintf>
		struct Eipdebuginfo info;
		debuginfo_eip(*eip,&info);
f01007a2:	83 c4 18             	add    $0x18,%esp
f01007a5:	57                   	push   %edi
f01007a6:	ff 36                	pushl  (%esi)
f01007a8:	e8 f8 02 00 00       	call   f0100aa5 <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,(*eip) - info.eip_fn_addr);
f01007ad:	83 c4 08             	add    $0x8,%esp
f01007b0:	8b 06                	mov    (%esi),%eax
f01007b2:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01007b5:	50                   	push   %eax
f01007b6:	ff 75 d8             	pushl  -0x28(%ebp)
f01007b9:	ff 75 dc             	pushl  -0x24(%ebp)
f01007bc:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007bf:	ff 75 d0             	pushl  -0x30(%ebp)
f01007c2:	68 aa 1f 10 f0       	push   $0xf0101faa
f01007c7:	e8 c3 01 00 00       	call   f010098f <cprintf>
		ebp = (uint32_t*)*ebp;
f01007cc:	8b 1b                	mov    (%ebx),%ebx
		eip = (uint32_t*)ebp + 1;
f01007ce:	8d 73 04             	lea    0x4(%ebx),%esi
f01007d1:	83 c4 20             	add    $0x20,%esp
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t *ebp = (uint32_t*)read_ebp();
	uint32_t *eip = ebp + 1;
	cprintf("Stack backtrace:\n");
	while(ebp){
f01007d4:	85 db                	test   %ebx,%ebx
f01007d6:	75 ae                	jne    f0100786 <mon_backtrace+0x22>
		ebp = (uint32_t*)*ebp;
		eip = (uint32_t*)ebp + 1;
	}
	
	return 0;
}
f01007d8:	b8 00 00 00 00       	mov    $0x0,%eax
f01007dd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007e0:	5b                   	pop    %ebx
f01007e1:	5e                   	pop    %esi
f01007e2:	5f                   	pop    %edi
f01007e3:	5d                   	pop    %ebp
f01007e4:	c3                   	ret    

f01007e5 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007e5:	55                   	push   %ebp
f01007e6:	89 e5                	mov    %esp,%ebp
f01007e8:	57                   	push   %edi
f01007e9:	56                   	push   %esi
f01007ea:	53                   	push   %ebx
f01007eb:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007ee:	68 84 21 10 f0       	push   $0xf0102184
f01007f3:	e8 97 01 00 00       	call   f010098f <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007f8:	c7 04 24 a8 21 10 f0 	movl   $0xf01021a8,(%esp)
f01007ff:	e8 8b 01 00 00       	call   f010098f <cprintf>
	cprintf("%Ccyn Colored scheme with no highlight.\n");
f0100804:	c7 04 24 d0 21 10 f0 	movl   $0xf01021d0,(%esp)
f010080b:	e8 7f 01 00 00       	call   f010098f <cprintf>
	cprintf("%Cble Hello%Cred World. %Cmag Test for colorization.\n");
f0100810:	c7 04 24 fc 21 10 f0 	movl   $0xf01021fc,(%esp)
f0100817:	e8 73 01 00 00       	call   f010098f <cprintf>
	cprintf("%Ibrw Colored scheme with highlight.\n");
f010081c:	c7 04 24 34 22 10 f0 	movl   $0xf0102234,(%esp)
f0100823:	e8 67 01 00 00       	call   f010098f <cprintf>
	cprintf("%Ible Hello%Ired World. %Imag Test for colorization.\n");
f0100828:	c7 04 24 5c 22 10 f0 	movl   $0xf010225c,(%esp)
f010082f:	e8 5b 01 00 00       	call   f010098f <cprintf>
	cprintf("%Cwht Return to default!\n");
f0100834:	c7 04 24 bb 1f 10 f0 	movl   $0xf0101fbb,(%esp)
f010083b:	e8 4f 01 00 00       	call   f010098f <cprintf>
f0100840:	83 c4 10             	add    $0x10,%esp
	while (1) {
		buf = readline("K> ");
f0100843:	83 ec 0c             	sub    $0xc,%esp
f0100846:	68 d5 1f 10 f0       	push   $0xf0101fd5
f010084b:	e8 a6 0c 00 00       	call   f01014f6 <readline>
f0100850:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100852:	83 c4 10             	add    $0x10,%esp
f0100855:	85 c0                	test   %eax,%eax
f0100857:	74 ea                	je     f0100843 <monitor+0x5e>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100859:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100860:	be 00 00 00 00       	mov    $0x0,%esi
f0100865:	eb 0a                	jmp    f0100871 <monitor+0x8c>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100867:	c6 03 00             	movb   $0x0,(%ebx)
f010086a:	89 f7                	mov    %esi,%edi
f010086c:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010086f:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100871:	0f b6 03             	movzbl (%ebx),%eax
f0100874:	84 c0                	test   %al,%al
f0100876:	74 63                	je     f01008db <monitor+0xf6>
f0100878:	83 ec 08             	sub    $0x8,%esp
f010087b:	0f be c0             	movsbl %al,%eax
f010087e:	50                   	push   %eax
f010087f:	68 d9 1f 10 f0       	push   $0xf0101fd9
f0100884:	e8 87 0e 00 00       	call   f0101710 <strchr>
f0100889:	83 c4 10             	add    $0x10,%esp
f010088c:	85 c0                	test   %eax,%eax
f010088e:	75 d7                	jne    f0100867 <monitor+0x82>
			*buf++ = 0;
		if (*buf == 0)
f0100890:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100893:	74 46                	je     f01008db <monitor+0xf6>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100895:	83 fe 0f             	cmp    $0xf,%esi
f0100898:	75 14                	jne    f01008ae <monitor+0xc9>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010089a:	83 ec 08             	sub    $0x8,%esp
f010089d:	6a 10                	push   $0x10
f010089f:	68 de 1f 10 f0       	push   $0xf0101fde
f01008a4:	e8 e6 00 00 00       	call   f010098f <cprintf>
f01008a9:	83 c4 10             	add    $0x10,%esp
f01008ac:	eb 95                	jmp    f0100843 <monitor+0x5e>
			return 0;
		}
		argv[argc++] = buf;
f01008ae:	8d 7e 01             	lea    0x1(%esi),%edi
f01008b1:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008b5:	eb 03                	jmp    f01008ba <monitor+0xd5>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008b7:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008ba:	0f b6 03             	movzbl (%ebx),%eax
f01008bd:	84 c0                	test   %al,%al
f01008bf:	74 ae                	je     f010086f <monitor+0x8a>
f01008c1:	83 ec 08             	sub    $0x8,%esp
f01008c4:	0f be c0             	movsbl %al,%eax
f01008c7:	50                   	push   %eax
f01008c8:	68 d9 1f 10 f0       	push   $0xf0101fd9
f01008cd:	e8 3e 0e 00 00       	call   f0101710 <strchr>
f01008d2:	83 c4 10             	add    $0x10,%esp
f01008d5:	85 c0                	test   %eax,%eax
f01008d7:	74 de                	je     f01008b7 <monitor+0xd2>
f01008d9:	eb 94                	jmp    f010086f <monitor+0x8a>
			buf++;
	}
	argv[argc] = 0;
f01008db:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008e2:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008e3:	85 f6                	test   %esi,%esi
f01008e5:	0f 84 58 ff ff ff    	je     f0100843 <monitor+0x5e>
f01008eb:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008f0:	83 ec 08             	sub    $0x8,%esp
f01008f3:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008f6:	ff 34 85 a0 22 10 f0 	pushl  -0xfefdd60(,%eax,4)
f01008fd:	ff 75 a8             	pushl  -0x58(%ebp)
f0100900:	e8 ad 0d 00 00       	call   f01016b2 <strcmp>
f0100905:	83 c4 10             	add    $0x10,%esp
f0100908:	85 c0                	test   %eax,%eax
f010090a:	75 22                	jne    f010092e <monitor+0x149>
			return commands[i].func(argc, argv, tf);
f010090c:	83 ec 04             	sub    $0x4,%esp
f010090f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100912:	ff 75 08             	pushl  0x8(%ebp)
f0100915:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100918:	52                   	push   %edx
f0100919:	56                   	push   %esi
f010091a:	ff 14 85 a8 22 10 f0 	call   *-0xfefdd58(,%eax,4)
	cprintf("%Ible Hello%Ired World. %Imag Test for colorization.\n");
	cprintf("%Cwht Return to default!\n");
	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100921:	83 c4 10             	add    $0x10,%esp
f0100924:	85 c0                	test   %eax,%eax
f0100926:	0f 89 17 ff ff ff    	jns    f0100843 <monitor+0x5e>
f010092c:	eb 20                	jmp    f010094e <monitor+0x169>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f010092e:	83 c3 01             	add    $0x1,%ebx
f0100931:	83 fb 03             	cmp    $0x3,%ebx
f0100934:	75 ba                	jne    f01008f0 <monitor+0x10b>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100936:	83 ec 08             	sub    $0x8,%esp
f0100939:	ff 75 a8             	pushl  -0x58(%ebp)
f010093c:	68 fb 1f 10 f0       	push   $0xf0101ffb
f0100941:	e8 49 00 00 00       	call   f010098f <cprintf>
f0100946:	83 c4 10             	add    $0x10,%esp
f0100949:	e9 f5 fe ff ff       	jmp    f0100843 <monitor+0x5e>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010094e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100951:	5b                   	pop    %ebx
f0100952:	5e                   	pop    %esi
f0100953:	5f                   	pop    %edi
f0100954:	5d                   	pop    %ebp
f0100955:	c3                   	ret    

f0100956 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100956:	55                   	push   %ebp
f0100957:	89 e5                	mov    %esp,%ebp
f0100959:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010095c:	ff 75 08             	pushl  0x8(%ebp)
f010095f:	e8 d6 fc ff ff       	call   f010063a <cputchar>
f0100964:	83 c4 10             	add    $0x10,%esp
	*cnt++;
}
f0100967:	c9                   	leave  
f0100968:	c3                   	ret    

f0100969 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100969:	55                   	push   %ebp
f010096a:	89 e5                	mov    %esp,%ebp
f010096c:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010096f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100976:	ff 75 0c             	pushl  0xc(%ebp)
f0100979:	ff 75 08             	pushl  0x8(%ebp)
f010097c:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010097f:	50                   	push   %eax
f0100980:	68 56 09 10 f0       	push   $0xf0100956
f0100985:	e8 7e 04 00 00       	call   f0100e08 <vprintfmt>
	return cnt;
}
f010098a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010098d:	c9                   	leave  
f010098e:	c3                   	ret    

f010098f <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010098f:	55                   	push   %ebp
f0100990:	89 e5                	mov    %esp,%ebp
f0100992:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100995:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100998:	50                   	push   %eax
f0100999:	ff 75 08             	pushl  0x8(%ebp)
f010099c:	e8 c8 ff ff ff       	call   f0100969 <vcprintf>
	va_end(ap);

	return cnt;
}
f01009a1:	c9                   	leave  
f01009a2:	c3                   	ret    

f01009a3 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009a3:	55                   	push   %ebp
f01009a4:	89 e5                	mov    %esp,%ebp
f01009a6:	57                   	push   %edi
f01009a7:	56                   	push   %esi
f01009a8:	53                   	push   %ebx
f01009a9:	83 ec 14             	sub    $0x14,%esp
f01009ac:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01009af:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01009b2:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01009b5:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009b8:	8b 1a                	mov    (%edx),%ebx
f01009ba:	8b 01                	mov    (%ecx),%eax
f01009bc:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009bf:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01009c6:	e9 88 00 00 00       	jmp    f0100a53 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f01009cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01009ce:	01 d8                	add    %ebx,%eax
f01009d0:	89 c6                	mov    %eax,%esi
f01009d2:	c1 ee 1f             	shr    $0x1f,%esi
f01009d5:	01 c6                	add    %eax,%esi
f01009d7:	d1 fe                	sar    %esi
f01009d9:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01009dc:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009df:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01009e2:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009e4:	eb 03                	jmp    f01009e9 <stab_binsearch+0x46>
			m--;
f01009e6:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009e9:	39 c3                	cmp    %eax,%ebx
f01009eb:	7f 1f                	jg     f0100a0c <stab_binsearch+0x69>
f01009ed:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01009f1:	83 ea 0c             	sub    $0xc,%edx
f01009f4:	39 f9                	cmp    %edi,%ecx
f01009f6:	75 ee                	jne    f01009e6 <stab_binsearch+0x43>
f01009f8:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01009fb:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01009fe:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a01:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100a05:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a08:	76 18                	jbe    f0100a22 <stab_binsearch+0x7f>
f0100a0a:	eb 05                	jmp    f0100a11 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a0c:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0100a0f:	eb 42                	jmp    f0100a53 <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a11:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100a14:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100a16:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a19:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a20:	eb 31                	jmp    f0100a53 <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a22:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a25:	73 17                	jae    f0100a3e <stab_binsearch+0x9b>
			*region_right = m - 1;
f0100a27:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a2a:	83 e8 01             	sub    $0x1,%eax
f0100a2d:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a30:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a33:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a35:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a3c:	eb 15                	jmp    f0100a53 <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a3e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a41:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a44:	89 1e                	mov    %ebx,(%esi)
			l = m;
			addr++;
f0100a46:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100a4a:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a4c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a53:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a56:	0f 8e 6f ff ff ff    	jle    f01009cb <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a5c:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100a60:	75 0f                	jne    f0100a71 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0100a62:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a65:	8b 00                	mov    (%eax),%eax
f0100a67:	83 e8 01             	sub    $0x1,%eax
f0100a6a:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a6d:	89 06                	mov    %eax,(%esi)
f0100a6f:	eb 2c                	jmp    f0100a9d <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a71:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a74:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a76:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a79:	8b 0e                	mov    (%esi),%ecx
f0100a7b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a7e:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100a81:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a84:	eb 03                	jmp    f0100a89 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a86:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a89:	39 c8                	cmp    %ecx,%eax
f0100a8b:	7e 0b                	jle    f0100a98 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0100a8d:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100a91:	83 ea 0c             	sub    $0xc,%edx
f0100a94:	39 fb                	cmp    %edi,%ebx
f0100a96:	75 ee                	jne    f0100a86 <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a98:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a9b:	89 06                	mov    %eax,(%esi)
	}
}
f0100a9d:	83 c4 14             	add    $0x14,%esp
f0100aa0:	5b                   	pop    %ebx
f0100aa1:	5e                   	pop    %esi
f0100aa2:	5f                   	pop    %edi
f0100aa3:	5d                   	pop    %ebp
f0100aa4:	c3                   	ret    

f0100aa5 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100aa5:	55                   	push   %ebp
f0100aa6:	89 e5                	mov    %esp,%ebp
f0100aa8:	57                   	push   %edi
f0100aa9:	56                   	push   %esi
f0100aaa:	53                   	push   %ebx
f0100aab:	83 ec 3c             	sub    $0x3c,%esp
f0100aae:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ab1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100ab4:	c7 03 c4 22 10 f0    	movl   $0xf01022c4,(%ebx)
	info->eip_line = 0;
f0100aba:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100ac1:	c7 43 08 c4 22 10 f0 	movl   $0xf01022c4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100ac8:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100acf:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100ad2:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100ad9:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100adf:	76 11                	jbe    f0100af2 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ae1:	b8 63 7a 10 f0       	mov    $0xf0107a63,%eax
f0100ae6:	3d 25 61 10 f0       	cmp    $0xf0106125,%eax
f0100aeb:	77 19                	ja     f0100b06 <debuginfo_eip+0x61>
f0100aed:	e9 a9 01 00 00       	jmp    f0100c9b <debuginfo_eip+0x1f6>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100af2:	83 ec 04             	sub    $0x4,%esp
f0100af5:	68 ce 22 10 f0       	push   $0xf01022ce
f0100afa:	6a 7f                	push   $0x7f
f0100afc:	68 db 22 10 f0       	push   $0xf01022db
f0100b01:	e8 e0 f5 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b06:	80 3d 62 7a 10 f0 00 	cmpb   $0x0,0xf0107a62
f0100b0d:	0f 85 8f 01 00 00    	jne    f0100ca2 <debuginfo_eip+0x1fd>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b13:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b1a:	b8 24 61 10 f0       	mov    $0xf0106124,%eax
f0100b1f:	2d 30 25 10 f0       	sub    $0xf0102530,%eax
f0100b24:	c1 f8 02             	sar    $0x2,%eax
f0100b27:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b2d:	83 e8 01             	sub    $0x1,%eax
f0100b30:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b33:	83 ec 08             	sub    $0x8,%esp
f0100b36:	56                   	push   %esi
f0100b37:	6a 64                	push   $0x64
f0100b39:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b3c:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b3f:	b8 30 25 10 f0       	mov    $0xf0102530,%eax
f0100b44:	e8 5a fe ff ff       	call   f01009a3 <stab_binsearch>
	if (lfile == 0)
f0100b49:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b4c:	83 c4 10             	add    $0x10,%esp
f0100b4f:	85 c0                	test   %eax,%eax
f0100b51:	0f 84 52 01 00 00    	je     f0100ca9 <debuginfo_eip+0x204>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b57:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b5a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b5d:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b60:	83 ec 08             	sub    $0x8,%esp
f0100b63:	56                   	push   %esi
f0100b64:	6a 24                	push   $0x24
f0100b66:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b69:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b6c:	b8 30 25 10 f0       	mov    $0xf0102530,%eax
f0100b71:	e8 2d fe ff ff       	call   f01009a3 <stab_binsearch>

	if (lfun <= rfun) {
f0100b76:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100b79:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100b7c:	83 c4 10             	add    $0x10,%esp
f0100b7f:	39 d0                	cmp    %edx,%eax
f0100b81:	7f 40                	jg     f0100bc3 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b83:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100b86:	c1 e1 02             	shl    $0x2,%ecx
f0100b89:	8d b9 30 25 10 f0    	lea    -0xfefdad0(%ecx),%edi
f0100b8f:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100b92:	8b b9 30 25 10 f0    	mov    -0xfefdad0(%ecx),%edi
f0100b98:	b9 63 7a 10 f0       	mov    $0xf0107a63,%ecx
f0100b9d:	81 e9 25 61 10 f0    	sub    $0xf0106125,%ecx
f0100ba3:	39 cf                	cmp    %ecx,%edi
f0100ba5:	73 09                	jae    f0100bb0 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100ba7:	81 c7 25 61 10 f0    	add    $0xf0106125,%edi
f0100bad:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100bb0:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100bb3:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100bb6:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100bb9:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100bbb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100bbe:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100bc1:	eb 0f                	jmp    f0100bd2 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bc3:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100bc6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bc9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100bcc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bcf:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bd2:	83 ec 08             	sub    $0x8,%esp
f0100bd5:	6a 3a                	push   $0x3a
f0100bd7:	ff 73 08             	pushl  0x8(%ebx)
f0100bda:	e8 52 0b 00 00       	call   f0101731 <strfind>
f0100bdf:	2b 43 08             	sub    0x8(%ebx),%eax
f0100be2:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100be5:	83 c4 08             	add    $0x8,%esp
f0100be8:	56                   	push   %esi
f0100be9:	6a 44                	push   $0x44
f0100beb:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100bee:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100bf1:	b8 30 25 10 f0       	mov    $0xf0102530,%eax
f0100bf6:	e8 a8 fd ff ff       	call   f01009a3 <stab_binsearch>
	if(lline <= rline){
f0100bfb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100bfe:	83 c4 10             	add    $0x10,%esp
f0100c01:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100c04:	0f 8f a6 00 00 00    	jg     f0100cb0 <debuginfo_eip+0x20b>
		info->eip_line = stabs[lline].n_desc;
f0100c0a:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100c0d:	0f b7 04 85 36 25 10 	movzwl -0xfefdaca(,%eax,4),%eax
f0100c14:	f0 
f0100c15:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c18:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c1b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c1e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100c21:	8d 14 95 30 25 10 f0 	lea    -0xfefdad0(,%edx,4),%edx
f0100c28:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100c2b:	eb 06                	jmp    f0100c33 <debuginfo_eip+0x18e>
f0100c2d:	83 e8 01             	sub    $0x1,%eax
f0100c30:	83 ea 0c             	sub    $0xc,%edx
f0100c33:	39 c7                	cmp    %eax,%edi
f0100c35:	7f 23                	jg     f0100c5a <debuginfo_eip+0x1b5>
	       && stabs[lline].n_type != N_SOL
f0100c37:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100c3b:	80 f9 84             	cmp    $0x84,%cl
f0100c3e:	74 7e                	je     f0100cbe <debuginfo_eip+0x219>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c40:	80 f9 64             	cmp    $0x64,%cl
f0100c43:	75 e8                	jne    f0100c2d <debuginfo_eip+0x188>
f0100c45:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0100c49:	74 e2                	je     f0100c2d <debuginfo_eip+0x188>
f0100c4b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100c4e:	eb 71                	jmp    f0100cc1 <debuginfo_eip+0x21c>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c50:	81 c2 25 61 10 f0    	add    $0xf0106125,%edx
f0100c56:	89 13                	mov    %edx,(%ebx)
f0100c58:	eb 03                	jmp    f0100c5d <debuginfo_eip+0x1b8>
f0100c5a:	8b 5d 0c             	mov    0xc(%ebp),%ebx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c5d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c60:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c63:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c68:	39 f2                	cmp    %esi,%edx
f0100c6a:	7d 76                	jge    f0100ce2 <debuginfo_eip+0x23d>
		for (lline = lfun + 1;
f0100c6c:	83 c2 01             	add    $0x1,%edx
f0100c6f:	89 d0                	mov    %edx,%eax
f0100c71:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100c74:	8d 14 95 30 25 10 f0 	lea    -0xfefdad0(,%edx,4),%edx
f0100c7b:	eb 04                	jmp    f0100c81 <debuginfo_eip+0x1dc>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c7d:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c81:	39 c6                	cmp    %eax,%esi
f0100c83:	7e 32                	jle    f0100cb7 <debuginfo_eip+0x212>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c85:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100c89:	83 c0 01             	add    $0x1,%eax
f0100c8c:	83 c2 0c             	add    $0xc,%edx
f0100c8f:	80 f9 a0             	cmp    $0xa0,%cl
f0100c92:	74 e9                	je     f0100c7d <debuginfo_eip+0x1d8>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c94:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c99:	eb 47                	jmp    f0100ce2 <debuginfo_eip+0x23d>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c9b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ca0:	eb 40                	jmp    f0100ce2 <debuginfo_eip+0x23d>
f0100ca2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ca7:	eb 39                	jmp    f0100ce2 <debuginfo_eip+0x23d>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100ca9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cae:	eb 32                	jmp    f0100ce2 <debuginfo_eip+0x23d>
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if(lline <= rline){
		info->eip_line = stabs[lline].n_desc;
	}
	else{
		return -1;
f0100cb0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cb5:	eb 2b                	jmp    f0100ce2 <debuginfo_eip+0x23d>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cb7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cbc:	eb 24                	jmp    f0100ce2 <debuginfo_eip+0x23d>
f0100cbe:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100cc1:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100cc4:	8b 14 85 30 25 10 f0 	mov    -0xfefdad0(,%eax,4),%edx
f0100ccb:	b8 63 7a 10 f0       	mov    $0xf0107a63,%eax
f0100cd0:	2d 25 61 10 f0       	sub    $0xf0106125,%eax
f0100cd5:	39 c2                	cmp    %eax,%edx
f0100cd7:	0f 82 73 ff ff ff    	jb     f0100c50 <debuginfo_eip+0x1ab>
f0100cdd:	e9 7b ff ff ff       	jmp    f0100c5d <debuginfo_eip+0x1b8>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
}
f0100ce2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ce5:	5b                   	pop    %ebx
f0100ce6:	5e                   	pop    %esi
f0100ce7:	5f                   	pop    %edi
f0100ce8:	5d                   	pop    %ebp
f0100ce9:	c3                   	ret    

f0100cea <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100cea:	55                   	push   %ebp
f0100ceb:	89 e5                	mov    %esp,%ebp
f0100ced:	57                   	push   %edi
f0100cee:	56                   	push   %esi
f0100cef:	53                   	push   %ebx
f0100cf0:	83 ec 1c             	sub    $0x1c,%esp
f0100cf3:	89 c7                	mov    %eax,%edi
f0100cf5:	89 d6                	mov    %edx,%esi
f0100cf7:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cfa:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100cfd:	89 d1                	mov    %edx,%ecx
f0100cff:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d02:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100d05:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d08:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d0b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d0e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100d15:	39 4d e4             	cmp    %ecx,-0x1c(%ebp)
f0100d18:	72 05                	jb     f0100d1f <printnum+0x35>
f0100d1a:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0100d1d:	77 3e                	ja     f0100d5d <printnum+0x73>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d1f:	83 ec 0c             	sub    $0xc,%esp
f0100d22:	ff 75 18             	pushl  0x18(%ebp)
f0100d25:	83 eb 01             	sub    $0x1,%ebx
f0100d28:	53                   	push   %ebx
f0100d29:	50                   	push   %eax
f0100d2a:	83 ec 08             	sub    $0x8,%esp
f0100d2d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d30:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d33:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d36:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d39:	e8 22 0c 00 00       	call   f0101960 <__udivdi3>
f0100d3e:	83 c4 18             	add    $0x18,%esp
f0100d41:	52                   	push   %edx
f0100d42:	50                   	push   %eax
f0100d43:	89 f2                	mov    %esi,%edx
f0100d45:	89 f8                	mov    %edi,%eax
f0100d47:	e8 9e ff ff ff       	call   f0100cea <printnum>
f0100d4c:	83 c4 20             	add    $0x20,%esp
f0100d4f:	eb 13                	jmp    f0100d64 <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d51:	83 ec 08             	sub    $0x8,%esp
f0100d54:	56                   	push   %esi
f0100d55:	ff 75 18             	pushl  0x18(%ebp)
f0100d58:	ff d7                	call   *%edi
f0100d5a:	83 c4 10             	add    $0x10,%esp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d5d:	83 eb 01             	sub    $0x1,%ebx
f0100d60:	85 db                	test   %ebx,%ebx
f0100d62:	7f ed                	jg     f0100d51 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d64:	83 ec 08             	sub    $0x8,%esp
f0100d67:	56                   	push   %esi
f0100d68:	83 ec 04             	sub    $0x4,%esp
f0100d6b:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d6e:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d71:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d74:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d77:	e8 14 0d 00 00       	call   f0101a90 <__umoddi3>
f0100d7c:	83 c4 14             	add    $0x14,%esp
f0100d7f:	0f be 80 e9 22 10 f0 	movsbl -0xfefdd17(%eax),%eax
f0100d86:	50                   	push   %eax
f0100d87:	ff d7                	call   *%edi
f0100d89:	83 c4 10             	add    $0x10,%esp
}
f0100d8c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d8f:	5b                   	pop    %ebx
f0100d90:	5e                   	pop    %esi
f0100d91:	5f                   	pop    %edi
f0100d92:	5d                   	pop    %ebp
f0100d93:	c3                   	ret    

f0100d94 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d94:	55                   	push   %ebp
f0100d95:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d97:	83 fa 01             	cmp    $0x1,%edx
f0100d9a:	7e 0e                	jle    f0100daa <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100d9c:	8b 10                	mov    (%eax),%edx
f0100d9e:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100da1:	89 08                	mov    %ecx,(%eax)
f0100da3:	8b 02                	mov    (%edx),%eax
f0100da5:	8b 52 04             	mov    0x4(%edx),%edx
f0100da8:	eb 22                	jmp    f0100dcc <getuint+0x38>
	else if (lflag)
f0100daa:	85 d2                	test   %edx,%edx
f0100dac:	74 10                	je     f0100dbe <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100dae:	8b 10                	mov    (%eax),%edx
f0100db0:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100db3:	89 08                	mov    %ecx,(%eax)
f0100db5:	8b 02                	mov    (%edx),%eax
f0100db7:	ba 00 00 00 00       	mov    $0x0,%edx
f0100dbc:	eb 0e                	jmp    f0100dcc <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100dbe:	8b 10                	mov    (%eax),%edx
f0100dc0:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100dc3:	89 08                	mov    %ecx,(%eax)
f0100dc5:	8b 02                	mov    (%edx),%eax
f0100dc7:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100dcc:	5d                   	pop    %ebp
f0100dcd:	c3                   	ret    

f0100dce <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100dce:	55                   	push   %ebp
f0100dcf:	89 e5                	mov    %esp,%ebp
f0100dd1:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100dd4:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100dd8:	8b 10                	mov    (%eax),%edx
f0100dda:	3b 50 04             	cmp    0x4(%eax),%edx
f0100ddd:	73 0a                	jae    f0100de9 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100ddf:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100de2:	89 08                	mov    %ecx,(%eax)
f0100de4:	8b 45 08             	mov    0x8(%ebp),%eax
f0100de7:	88 02                	mov    %al,(%edx)
}
f0100de9:	5d                   	pop    %ebp
f0100dea:	c3                   	ret    

f0100deb <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100deb:	55                   	push   %ebp
f0100dec:	89 e5                	mov    %esp,%ebp
f0100dee:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100df1:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100df4:	50                   	push   %eax
f0100df5:	ff 75 10             	pushl  0x10(%ebp)
f0100df8:	ff 75 0c             	pushl  0xc(%ebp)
f0100dfb:	ff 75 08             	pushl  0x8(%ebp)
f0100dfe:	e8 05 00 00 00       	call   f0100e08 <vprintfmt>
	va_end(ap);
f0100e03:	83 c4 10             	add    $0x10,%esp
}
f0100e06:	c9                   	leave  
f0100e07:	c3                   	ret    

f0100e08 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100e08:	55                   	push   %ebp
f0100e09:	89 e5                	mov    %esp,%ebp
f0100e0b:	57                   	push   %edi
f0100e0c:	56                   	push   %esi
f0100e0d:	53                   	push   %ebx
f0100e0e:	83 ec 3c             	sub    $0x3c,%esp
f0100e11:	8b 75 08             	mov    0x8(%ebp),%esi
f0100e14:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100e17:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100e1a:	eb 12                	jmp    f0100e2e <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;
	char colorcontrol[5];
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100e1c:	85 c0                	test   %eax,%eax
f0100e1e:	0f 84 62 06 00 00    	je     f0101486 <vprintfmt+0x67e>
				return;
			putch(ch, putdat);
f0100e24:	83 ec 08             	sub    $0x8,%esp
f0100e27:	53                   	push   %ebx
f0100e28:	50                   	push   %eax
f0100e29:	ff d6                	call   *%esi
f0100e2b:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;
	char colorcontrol[5];
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e2e:	83 c7 01             	add    $0x1,%edi
f0100e31:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100e35:	83 f8 25             	cmp    $0x25,%eax
f0100e38:	75 e2                	jne    f0100e1c <vprintfmt+0x14>
f0100e3a:	c6 45 c4 20          	movb   $0x20,-0x3c(%ebp)
f0100e3e:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
f0100e45:	c7 45 c0 ff ff ff ff 	movl   $0xffffffff,-0x40(%ebp)
f0100e4c:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100e53:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e58:	eb 07                	jmp    f0100e61 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e5a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
					colr = COLR_BLACK;
			}
			colr |= highlight;
			break;
		case '-':
			padc = '-';
f0100e5d:	c6 45 c4 2d          	movb   $0x2d,-0x3c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e61:	8d 47 01             	lea    0x1(%edi),%eax
f0100e64:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100e67:	0f b6 07             	movzbl (%edi),%eax
f0100e6a:	0f b6 c8             	movzbl %al,%ecx
f0100e6d:	83 e8 23             	sub    $0x23,%eax
f0100e70:	3c 55                	cmp    $0x55,%al
f0100e72:	0f 87 f3 05 00 00    	ja     f010146b <vprintfmt+0x663>
f0100e78:	0f b6 c0             	movzbl %al,%eax
f0100e7b:	ff 24 85 a0 23 10 f0 	jmp    *-0xfefdc60(,%eax,4)
f0100e82:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e85:	c6 45 c4 30          	movb   $0x30,-0x3c(%ebp)
f0100e89:	eb d6                	jmp    f0100e61 <vprintfmt+0x59>
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {

		// flag to pad on the right
		case 'C':
			memmove(colorcontrol, fmt, sizeof(unsigned char)*3);
f0100e8b:	83 ec 04             	sub    $0x4,%esp
f0100e8e:	6a 03                	push   $0x3
f0100e90:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100e93:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0100e96:	50                   	push   %eax
f0100e97:	e8 fe 08 00 00       	call   f010179a <memmove>
			colorcontrol[3] = '\0';
f0100e9c:	c6 45 e6 00          	movb   $0x0,-0x1a(%ebp)
			fmt += 3;
f0100ea0:	83 c7 04             	add    $0x4,%edi
			if(colorcontrol[0] >= '0' && colorcontrol[0] <= '9'){
f0100ea3:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f0100ea7:	8d 50 d0             	lea    -0x30(%eax),%edx
f0100eaa:	83 c4 10             	add    $0x10,%esp
f0100ead:	80 fa 09             	cmp    $0x9,%dl
f0100eb0:	77 29                	ja     f0100edb <vprintfmt+0xd3>
				colr = (colorcontrol[0] - '0') * 100 + (colorcontrol[1] - '0') * 10 + (colorcontrol[2] - '0');
f0100eb2:	0f be c0             	movsbl %al,%eax
f0100eb5:	83 e8 30             	sub    $0x30,%eax
f0100eb8:	6b c0 64             	imul   $0x64,%eax,%eax
f0100ebb:	0f be 55 e4          	movsbl -0x1c(%ebp),%edx
f0100ebf:	8d 94 92 10 ff ff ff 	lea    -0xf0(%edx,%edx,4),%edx
f0100ec6:	8d 14 50             	lea    (%eax,%edx,2),%edx
f0100ec9:	0f be 45 e5          	movsbl -0x1b(%ebp),%eax
f0100ecd:	8d 44 02 d0          	lea    -0x30(%edx,%eax,1),%eax
f0100ed1:	a3 5c 25 11 f0       	mov    %eax,0xf011255c
f0100ed6:	e9 53 ff ff ff       	jmp    f0100e2e <vprintfmt+0x26>
			}
			else{
				if(strcmp(colorcontrol, "ble") == 0) colr = COLR_BLUE
f0100edb:	83 ec 08             	sub    $0x8,%esp
f0100ede:	68 01 23 10 f0       	push   $0xf0102301
f0100ee3:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0100ee6:	50                   	push   %eax
f0100ee7:	e8 c6 07 00 00       	call   f01016b2 <strcmp>
f0100eec:	83 c4 10             	add    $0x10,%esp
f0100eef:	85 c0                	test   %eax,%eax
f0100ef1:	75 0f                	jne    f0100f02 <vprintfmt+0xfa>
f0100ef3:	c7 05 5c 25 11 f0 01 	movl   $0x1,0xf011255c
f0100efa:	00 00 00 
f0100efd:	e9 2c ff ff ff       	jmp    f0100e2e <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "grn") == 0) colr = COLR_GREEN
f0100f02:	83 ec 08             	sub    $0x8,%esp
f0100f05:	68 05 23 10 f0       	push   $0xf0102305
f0100f0a:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0100f0d:	50                   	push   %eax
f0100f0e:	e8 9f 07 00 00       	call   f01016b2 <strcmp>
f0100f13:	83 c4 10             	add    $0x10,%esp
f0100f16:	85 c0                	test   %eax,%eax
f0100f18:	75 0f                	jne    f0100f29 <vprintfmt+0x121>
f0100f1a:	c7 05 5c 25 11 f0 02 	movl   $0x2,0xf011255c
f0100f21:	00 00 00 
f0100f24:	e9 05 ff ff ff       	jmp    f0100e2e <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "cyn") == 0) colr = COLR_CYAN
f0100f29:	83 ec 08             	sub    $0x8,%esp
f0100f2c:	68 09 23 10 f0       	push   $0xf0102309
f0100f31:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0100f34:	50                   	push   %eax
f0100f35:	e8 78 07 00 00       	call   f01016b2 <strcmp>
f0100f3a:	83 c4 10             	add    $0x10,%esp
f0100f3d:	85 c0                	test   %eax,%eax
f0100f3f:	75 0f                	jne    f0100f50 <vprintfmt+0x148>
f0100f41:	c7 05 5c 25 11 f0 03 	movl   $0x3,0xf011255c
f0100f48:	00 00 00 
f0100f4b:	e9 de fe ff ff       	jmp    f0100e2e <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "red") == 0) colr = COLR_RED
f0100f50:	83 ec 08             	sub    $0x8,%esp
f0100f53:	68 0d 23 10 f0       	push   $0xf010230d
f0100f58:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0100f5b:	50                   	push   %eax
f0100f5c:	e8 51 07 00 00       	call   f01016b2 <strcmp>
f0100f61:	83 c4 10             	add    $0x10,%esp
f0100f64:	85 c0                	test   %eax,%eax
f0100f66:	75 0f                	jne    f0100f77 <vprintfmt+0x16f>
f0100f68:	c7 05 5c 25 11 f0 04 	movl   $0x4,0xf011255c
f0100f6f:	00 00 00 
f0100f72:	e9 b7 fe ff ff       	jmp    f0100e2e <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "mag") == 0) colr = COLR_MAGENTA
f0100f77:	83 ec 08             	sub    $0x8,%esp
f0100f7a:	68 11 23 10 f0       	push   $0xf0102311
f0100f7f:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0100f82:	50                   	push   %eax
f0100f83:	e8 2a 07 00 00       	call   f01016b2 <strcmp>
f0100f88:	83 c4 10             	add    $0x10,%esp
f0100f8b:	85 c0                	test   %eax,%eax
f0100f8d:	75 0f                	jne    f0100f9e <vprintfmt+0x196>
f0100f8f:	c7 05 5c 25 11 f0 05 	movl   $0x5,0xf011255c
f0100f96:	00 00 00 
f0100f99:	e9 90 fe ff ff       	jmp    f0100e2e <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "brw")== 0) colr = COLR_BROWN
f0100f9e:	83 ec 08             	sub    $0x8,%esp
f0100fa1:	68 15 23 10 f0       	push   $0xf0102315
f0100fa6:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0100fa9:	50                   	push   %eax
f0100faa:	e8 03 07 00 00       	call   f01016b2 <strcmp>
f0100faf:	83 c4 10             	add    $0x10,%esp
f0100fb2:	85 c0                	test   %eax,%eax
f0100fb4:	75 0f                	jne    f0100fc5 <vprintfmt+0x1bd>
f0100fb6:	c7 05 5c 25 11 f0 06 	movl   $0x6,0xf011255c
f0100fbd:	00 00 00 
f0100fc0:	e9 69 fe ff ff       	jmp    f0100e2e <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "gry") == 0) colr = COLR_GRAY
f0100fc5:	83 ec 08             	sub    $0x8,%esp
f0100fc8:	68 19 23 10 f0       	push   $0xf0102319
f0100fcd:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0100fd0:	50                   	push   %eax
f0100fd1:	e8 dc 06 00 00       	call   f01016b2 <strcmp>
f0100fd6:	83 c4 10             	add    $0x10,%esp
f0100fd9:	83 f8 01             	cmp    $0x1,%eax
f0100fdc:	19 c0                	sbb    %eax,%eax
f0100fde:	83 e0 07             	and    $0x7,%eax
f0100fe1:	a3 5c 25 11 f0       	mov    %eax,0xf011255c
f0100fe6:	e9 43 fe ff ff       	jmp    f0100e2e <vprintfmt+0x26>
					colr = COLR_BLACK;
			}
			break;
				
		case 'I':
			highlight = COLR_HIGHLIGHT;
f0100feb:	c7 05 58 25 11 f0 08 	movl   $0x8,0xf0112558
f0100ff2:	00 00 00 
			memmove(colorcontrol, fmt, sizeof(unsigned char)*3);
f0100ff5:	83 ec 04             	sub    $0x4,%esp
f0100ff8:	6a 03                	push   $0x3
f0100ffa:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100ffd:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0101000:	50                   	push   %eax
f0101001:	e8 94 07 00 00       	call   f010179a <memmove>
			colorcontrol[3] = '\0';
f0101006:	c6 45 e6 00          	movb   $0x0,-0x1a(%ebp)
			fmt += 3;
f010100a:	83 c7 04             	add    $0x4,%edi
			if(colorcontrol[0] >= '0' && colorcontrol[0] <= '9'){
f010100d:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f0101011:	8d 50 d0             	lea    -0x30(%eax),%edx
f0101014:	83 c4 10             	add    $0x10,%esp
f0101017:	80 fa 09             	cmp    $0x9,%dl
f010101a:	77 29                	ja     f0101045 <vprintfmt+0x23d>
				colr = (colorcontrol[0] - '0') * 100 + (colorcontrol[1] - '0') * 10 + (colorcontrol[2] - '0');
f010101c:	0f be c0             	movsbl %al,%eax
f010101f:	83 e8 30             	sub    $0x30,%eax
f0101022:	6b c0 64             	imul   $0x64,%eax,%eax
f0101025:	0f be 55 e4          	movsbl -0x1c(%ebp),%edx
f0101029:	8d 94 92 10 ff ff ff 	lea    -0xf0(%edx,%edx,4),%edx
f0101030:	8d 14 50             	lea    (%eax,%edx,2),%edx
f0101033:	0f be 45 e5          	movsbl -0x1b(%ebp),%eax
f0101037:	8d 44 02 d0          	lea    -0x30(%edx,%eax,1),%eax
f010103b:	a3 5c 25 11 f0       	mov    %eax,0xf011255c
f0101040:	e9 02 01 00 00       	jmp    f0101147 <vprintfmt+0x33f>
			}
			else{
				if(strcmp(colorcontrol, "ble") == 0) colr = COLR_BLUE
f0101045:	83 ec 08             	sub    $0x8,%esp
f0101048:	68 01 23 10 f0       	push   $0xf0102301
f010104d:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0101050:	50                   	push   %eax
f0101051:	e8 5c 06 00 00       	call   f01016b2 <strcmp>
f0101056:	83 c4 10             	add    $0x10,%esp
f0101059:	85 c0                	test   %eax,%eax
f010105b:	75 0f                	jne    f010106c <vprintfmt+0x264>
f010105d:	c7 05 5c 25 11 f0 01 	movl   $0x1,0xf011255c
f0101064:	00 00 00 
f0101067:	e9 db 00 00 00       	jmp    f0101147 <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "grn") == 0) colr = COLR_GREEN
f010106c:	83 ec 08             	sub    $0x8,%esp
f010106f:	68 05 23 10 f0       	push   $0xf0102305
f0101074:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0101077:	50                   	push   %eax
f0101078:	e8 35 06 00 00       	call   f01016b2 <strcmp>
f010107d:	83 c4 10             	add    $0x10,%esp
f0101080:	85 c0                	test   %eax,%eax
f0101082:	75 0f                	jne    f0101093 <vprintfmt+0x28b>
f0101084:	c7 05 5c 25 11 f0 02 	movl   $0x2,0xf011255c
f010108b:	00 00 00 
f010108e:	e9 b4 00 00 00       	jmp    f0101147 <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "cyn") == 0) colr = COLR_CYAN
f0101093:	83 ec 08             	sub    $0x8,%esp
f0101096:	68 09 23 10 f0       	push   $0xf0102309
f010109b:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f010109e:	50                   	push   %eax
f010109f:	e8 0e 06 00 00       	call   f01016b2 <strcmp>
f01010a4:	83 c4 10             	add    $0x10,%esp
f01010a7:	85 c0                	test   %eax,%eax
f01010a9:	75 0f                	jne    f01010ba <vprintfmt+0x2b2>
f01010ab:	c7 05 5c 25 11 f0 03 	movl   $0x3,0xf011255c
f01010b2:	00 00 00 
f01010b5:	e9 8d 00 00 00       	jmp    f0101147 <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "red") == 0) colr = COLR_RED
f01010ba:	83 ec 08             	sub    $0x8,%esp
f01010bd:	68 0d 23 10 f0       	push   $0xf010230d
f01010c2:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f01010c5:	50                   	push   %eax
f01010c6:	e8 e7 05 00 00       	call   f01016b2 <strcmp>
f01010cb:	83 c4 10             	add    $0x10,%esp
f01010ce:	85 c0                	test   %eax,%eax
f01010d0:	75 0c                	jne    f01010de <vprintfmt+0x2d6>
f01010d2:	c7 05 5c 25 11 f0 04 	movl   $0x4,0xf011255c
f01010d9:	00 00 00 
f01010dc:	eb 69                	jmp    f0101147 <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "mag") == 0) colr = COLR_MAGENTA
f01010de:	83 ec 08             	sub    $0x8,%esp
f01010e1:	68 11 23 10 f0       	push   $0xf0102311
f01010e6:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f01010e9:	50                   	push   %eax
f01010ea:	e8 c3 05 00 00       	call   f01016b2 <strcmp>
f01010ef:	83 c4 10             	add    $0x10,%esp
f01010f2:	85 c0                	test   %eax,%eax
f01010f4:	75 0c                	jne    f0101102 <vprintfmt+0x2fa>
f01010f6:	c7 05 5c 25 11 f0 05 	movl   $0x5,0xf011255c
f01010fd:	00 00 00 
f0101100:	eb 45                	jmp    f0101147 <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "brw")== 0) colr = COLR_BROWN
f0101102:	83 ec 08             	sub    $0x8,%esp
f0101105:	68 15 23 10 f0       	push   $0xf0102315
f010110a:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f010110d:	50                   	push   %eax
f010110e:	e8 9f 05 00 00       	call   f01016b2 <strcmp>
f0101113:	83 c4 10             	add    $0x10,%esp
f0101116:	85 c0                	test   %eax,%eax
f0101118:	75 0c                	jne    f0101126 <vprintfmt+0x31e>
f010111a:	c7 05 5c 25 11 f0 06 	movl   $0x6,0xf011255c
f0101121:	00 00 00 
f0101124:	eb 21                	jmp    f0101147 <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "gry") == 0) colr = COLR_GRAY
f0101126:	83 ec 08             	sub    $0x8,%esp
f0101129:	68 19 23 10 f0       	push   $0xf0102319
f010112e:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0101131:	50                   	push   %eax
f0101132:	e8 7b 05 00 00       	call   f01016b2 <strcmp>
f0101137:	83 c4 10             	add    $0x10,%esp
f010113a:	83 f8 01             	cmp    $0x1,%eax
f010113d:	19 c0                	sbb    %eax,%eax
f010113f:	83 e0 07             	and    $0x7,%eax
f0101142:	a3 5c 25 11 f0       	mov    %eax,0xf011255c
				else
					colr = COLR_BLACK;
			}
			colr |= highlight;
f0101147:	a1 58 25 11 f0       	mov    0xf0112558,%eax
f010114c:	09 05 5c 25 11 f0    	or     %eax,0xf011255c
			break;
f0101152:	e9 d7 fc ff ff       	jmp    f0100e2e <vprintfmt+0x26>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101157:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010115a:	b8 00 00 00 00       	mov    $0x0,%eax
f010115f:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0101162:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0101165:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0101169:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f010116c:	8d 51 d0             	lea    -0x30(%ecx),%edx
f010116f:	83 fa 09             	cmp    $0x9,%edx
f0101172:	77 3f                	ja     f01011b3 <vprintfmt+0x3ab>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0101174:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0101177:	eb e9                	jmp    f0101162 <vprintfmt+0x35a>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0101179:	8b 45 14             	mov    0x14(%ebp),%eax
f010117c:	8d 48 04             	lea    0x4(%eax),%ecx
f010117f:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0101182:	8b 00                	mov    (%eax),%eax
f0101184:	89 45 c0             	mov    %eax,-0x40(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101187:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f010118a:	eb 2d                	jmp    f01011b9 <vprintfmt+0x3b1>
f010118c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010118f:	85 c0                	test   %eax,%eax
f0101191:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101196:	0f 49 c8             	cmovns %eax,%ecx
f0101199:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010119c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010119f:	e9 bd fc ff ff       	jmp    f0100e61 <vprintfmt+0x59>
f01011a4:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01011a7:	c7 45 c8 01 00 00 00 	movl   $0x1,-0x38(%ebp)
			goto reswitch;
f01011ae:	e9 ae fc ff ff       	jmp    f0100e61 <vprintfmt+0x59>
f01011b3:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01011b6:	89 45 c0             	mov    %eax,-0x40(%ebp)

		process_precision:
			if (width < 0)
f01011b9:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01011bd:	0f 89 9e fc ff ff    	jns    f0100e61 <vprintfmt+0x59>
				width = precision, precision = -1;
f01011c3:	8b 45 c0             	mov    -0x40(%ebp),%eax
f01011c6:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01011c9:	c7 45 c0 ff ff ff ff 	movl   $0xffffffff,-0x40(%ebp)
f01011d0:	e9 8c fc ff ff       	jmp    f0100e61 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01011d5:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011d8:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01011db:	e9 81 fc ff ff       	jmp    f0100e61 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01011e0:	8b 45 14             	mov    0x14(%ebp),%eax
f01011e3:	8d 50 04             	lea    0x4(%eax),%edx
f01011e6:	89 55 14             	mov    %edx,0x14(%ebp)
f01011e9:	83 ec 08             	sub    $0x8,%esp
f01011ec:	53                   	push   %ebx
f01011ed:	ff 30                	pushl  (%eax)
f01011ef:	ff d6                	call   *%esi
			break;
f01011f1:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011f4:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f01011f7:	e9 32 fc ff ff       	jmp    f0100e2e <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01011fc:	8b 45 14             	mov    0x14(%ebp),%eax
f01011ff:	8d 50 04             	lea    0x4(%eax),%edx
f0101202:	89 55 14             	mov    %edx,0x14(%ebp)
f0101205:	8b 00                	mov    (%eax),%eax
f0101207:	99                   	cltd   
f0101208:	31 d0                	xor    %edx,%eax
f010120a:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010120c:	83 f8 07             	cmp    $0x7,%eax
f010120f:	7f 0b                	jg     f010121c <vprintfmt+0x414>
f0101211:	8b 14 85 00 25 10 f0 	mov    -0xfefdb00(,%eax,4),%edx
f0101218:	85 d2                	test   %edx,%edx
f010121a:	75 18                	jne    f0101234 <vprintfmt+0x42c>
				printfmt(putch, putdat, "error %d", err);
f010121c:	50                   	push   %eax
f010121d:	68 1d 23 10 f0       	push   $0xf010231d
f0101222:	53                   	push   %ebx
f0101223:	56                   	push   %esi
f0101224:	e8 c2 fb ff ff       	call   f0100deb <printfmt>
f0101229:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010122c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010122f:	e9 fa fb ff ff       	jmp    f0100e2e <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0101234:	52                   	push   %edx
f0101235:	68 26 23 10 f0       	push   $0xf0102326
f010123a:	53                   	push   %ebx
f010123b:	56                   	push   %esi
f010123c:	e8 aa fb ff ff       	call   f0100deb <printfmt>
f0101241:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101244:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101247:	e9 e2 fb ff ff       	jmp    f0100e2e <vprintfmt+0x26>
f010124c:	8b 55 c0             	mov    -0x40(%ebp),%edx
f010124f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101252:	89 45 bc             	mov    %eax,-0x44(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101255:	8b 45 14             	mov    0x14(%ebp),%eax
f0101258:	8d 48 04             	lea    0x4(%eax),%ecx
f010125b:	89 4d 14             	mov    %ecx,0x14(%ebp)
f010125e:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101260:	85 ff                	test   %edi,%edi
f0101262:	b8 fa 22 10 f0       	mov    $0xf01022fa,%eax
f0101267:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010126a:	80 7d c4 2d          	cmpb   $0x2d,-0x3c(%ebp)
f010126e:	0f 84 92 00 00 00    	je     f0101306 <vprintfmt+0x4fe>
f0101274:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
f0101278:	0f 8e 96 00 00 00    	jle    f0101314 <vprintfmt+0x50c>
				for (width -= strnlen(p, precision); width > 0; width--)
f010127e:	83 ec 08             	sub    $0x8,%esp
f0101281:	52                   	push   %edx
f0101282:	57                   	push   %edi
f0101283:	e8 5f 03 00 00       	call   f01015e7 <strnlen>
f0101288:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f010128b:	29 c1                	sub    %eax,%ecx
f010128d:	89 4d bc             	mov    %ecx,-0x44(%ebp)
f0101290:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0101293:	0f be 45 c4          	movsbl -0x3c(%ebp),%eax
f0101297:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010129a:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f010129d:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010129f:	eb 0f                	jmp    f01012b0 <vprintfmt+0x4a8>
					putch(padc, putdat);
f01012a1:	83 ec 08             	sub    $0x8,%esp
f01012a4:	53                   	push   %ebx
f01012a5:	ff 75 d0             	pushl  -0x30(%ebp)
f01012a8:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01012aa:	83 ef 01             	sub    $0x1,%edi
f01012ad:	83 c4 10             	add    $0x10,%esp
f01012b0:	85 ff                	test   %edi,%edi
f01012b2:	7f ed                	jg     f01012a1 <vprintfmt+0x499>
f01012b4:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01012b7:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f01012ba:	85 c9                	test   %ecx,%ecx
f01012bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01012c1:	0f 49 c1             	cmovns %ecx,%eax
f01012c4:	29 c1                	sub    %eax,%ecx
f01012c6:	89 75 08             	mov    %esi,0x8(%ebp)
f01012c9:	8b 75 c0             	mov    -0x40(%ebp),%esi
f01012cc:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01012cf:	89 cb                	mov    %ecx,%ebx
f01012d1:	eb 4d                	jmp    f0101320 <vprintfmt+0x518>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01012d3:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
f01012d7:	74 1b                	je     f01012f4 <vprintfmt+0x4ec>
f01012d9:	0f be c0             	movsbl %al,%eax
f01012dc:	83 e8 20             	sub    $0x20,%eax
f01012df:	83 f8 5e             	cmp    $0x5e,%eax
f01012e2:	76 10                	jbe    f01012f4 <vprintfmt+0x4ec>
					putch('?', putdat);
f01012e4:	83 ec 08             	sub    $0x8,%esp
f01012e7:	ff 75 0c             	pushl  0xc(%ebp)
f01012ea:	6a 3f                	push   $0x3f
f01012ec:	ff 55 08             	call   *0x8(%ebp)
f01012ef:	83 c4 10             	add    $0x10,%esp
f01012f2:	eb 0d                	jmp    f0101301 <vprintfmt+0x4f9>
				else
					putch(ch, putdat);
f01012f4:	83 ec 08             	sub    $0x8,%esp
f01012f7:	ff 75 0c             	pushl  0xc(%ebp)
f01012fa:	52                   	push   %edx
f01012fb:	ff 55 08             	call   *0x8(%ebp)
f01012fe:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101301:	83 eb 01             	sub    $0x1,%ebx
f0101304:	eb 1a                	jmp    f0101320 <vprintfmt+0x518>
f0101306:	89 75 08             	mov    %esi,0x8(%ebp)
f0101309:	8b 75 c0             	mov    -0x40(%ebp),%esi
f010130c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010130f:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101312:	eb 0c                	jmp    f0101320 <vprintfmt+0x518>
f0101314:	89 75 08             	mov    %esi,0x8(%ebp)
f0101317:	8b 75 c0             	mov    -0x40(%ebp),%esi
f010131a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010131d:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101320:	83 c7 01             	add    $0x1,%edi
f0101323:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101327:	0f be d0             	movsbl %al,%edx
f010132a:	85 d2                	test   %edx,%edx
f010132c:	74 23                	je     f0101351 <vprintfmt+0x549>
f010132e:	85 f6                	test   %esi,%esi
f0101330:	78 a1                	js     f01012d3 <vprintfmt+0x4cb>
f0101332:	83 ee 01             	sub    $0x1,%esi
f0101335:	79 9c                	jns    f01012d3 <vprintfmt+0x4cb>
f0101337:	89 df                	mov    %ebx,%edi
f0101339:	8b 75 08             	mov    0x8(%ebp),%esi
f010133c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010133f:	eb 18                	jmp    f0101359 <vprintfmt+0x551>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101341:	83 ec 08             	sub    $0x8,%esp
f0101344:	53                   	push   %ebx
f0101345:	6a 20                	push   $0x20
f0101347:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101349:	83 ef 01             	sub    $0x1,%edi
f010134c:	83 c4 10             	add    $0x10,%esp
f010134f:	eb 08                	jmp    f0101359 <vprintfmt+0x551>
f0101351:	89 df                	mov    %ebx,%edi
f0101353:	8b 75 08             	mov    0x8(%ebp),%esi
f0101356:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101359:	85 ff                	test   %edi,%edi
f010135b:	7f e4                	jg     f0101341 <vprintfmt+0x539>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010135d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101360:	e9 c9 fa ff ff       	jmp    f0100e2e <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101365:	83 fa 01             	cmp    $0x1,%edx
f0101368:	7e 16                	jle    f0101380 <vprintfmt+0x578>
		return va_arg(*ap, long long);
f010136a:	8b 45 14             	mov    0x14(%ebp),%eax
f010136d:	8d 50 08             	lea    0x8(%eax),%edx
f0101370:	89 55 14             	mov    %edx,0x14(%ebp)
f0101373:	8b 50 04             	mov    0x4(%eax),%edx
f0101376:	8b 00                	mov    (%eax),%eax
f0101378:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010137b:	89 55 cc             	mov    %edx,-0x34(%ebp)
f010137e:	eb 32                	jmp    f01013b2 <vprintfmt+0x5aa>
	else if (lflag)
f0101380:	85 d2                	test   %edx,%edx
f0101382:	74 18                	je     f010139c <vprintfmt+0x594>
		return va_arg(*ap, long);
f0101384:	8b 45 14             	mov    0x14(%ebp),%eax
f0101387:	8d 50 04             	lea    0x4(%eax),%edx
f010138a:	89 55 14             	mov    %edx,0x14(%ebp)
f010138d:	8b 00                	mov    (%eax),%eax
f010138f:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0101392:	89 c1                	mov    %eax,%ecx
f0101394:	c1 f9 1f             	sar    $0x1f,%ecx
f0101397:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f010139a:	eb 16                	jmp    f01013b2 <vprintfmt+0x5aa>
	else
		return va_arg(*ap, int);
f010139c:	8b 45 14             	mov    0x14(%ebp),%eax
f010139f:	8d 50 04             	lea    0x4(%eax),%edx
f01013a2:	89 55 14             	mov    %edx,0x14(%ebp)
f01013a5:	8b 00                	mov    (%eax),%eax
f01013a7:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01013aa:	89 c1                	mov    %eax,%ecx
f01013ac:	c1 f9 1f             	sar    $0x1f,%ecx
f01013af:	89 4d cc             	mov    %ecx,-0x34(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01013b2:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01013b5:	8b 55 cc             	mov    -0x34(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01013b8:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01013bd:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f01013c1:	79 74                	jns    f0101437 <vprintfmt+0x62f>
				putch('-', putdat);
f01013c3:	83 ec 08             	sub    $0x8,%esp
f01013c6:	53                   	push   %ebx
f01013c7:	6a 2d                	push   $0x2d
f01013c9:	ff d6                	call   *%esi
				num = -(long long) num;
f01013cb:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01013ce:	8b 55 cc             	mov    -0x34(%ebp),%edx
f01013d1:	f7 d8                	neg    %eax
f01013d3:	83 d2 00             	adc    $0x0,%edx
f01013d6:	f7 da                	neg    %edx
f01013d8:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01013db:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01013e0:	eb 55                	jmp    f0101437 <vprintfmt+0x62f>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01013e2:	8d 45 14             	lea    0x14(%ebp),%eax
f01013e5:	e8 aa f9 ff ff       	call   f0100d94 <getuint>
			base = 10;
f01013ea:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01013ef:	eb 46                	jmp    f0101437 <vprintfmt+0x62f>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01013f1:	8d 45 14             	lea    0x14(%ebp),%eax
f01013f4:	e8 9b f9 ff ff       	call   f0100d94 <getuint>
			base = 8;
f01013f9:	b9 08 00 00 00       	mov    $0x8,%ecx

			goto number;
f01013fe:	eb 37                	jmp    f0101437 <vprintfmt+0x62f>
		// pointer
		case 'p':
			putch('0', putdat);
f0101400:	83 ec 08             	sub    $0x8,%esp
f0101403:	53                   	push   %ebx
f0101404:	6a 30                	push   $0x30
f0101406:	ff d6                	call   *%esi
			putch('x', putdat);
f0101408:	83 c4 08             	add    $0x8,%esp
f010140b:	53                   	push   %ebx
f010140c:	6a 78                	push   $0x78
f010140e:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101410:	8b 45 14             	mov    0x14(%ebp),%eax
f0101413:	8d 50 04             	lea    0x4(%eax),%edx
f0101416:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101419:	8b 00                	mov    (%eax),%eax
f010141b:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101420:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101423:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101428:	eb 0d                	jmp    f0101437 <vprintfmt+0x62f>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010142a:	8d 45 14             	lea    0x14(%ebp),%eax
f010142d:	e8 62 f9 ff ff       	call   f0100d94 <getuint>
			base = 16;
f0101432:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101437:	83 ec 0c             	sub    $0xc,%esp
f010143a:	0f be 7d c4          	movsbl -0x3c(%ebp),%edi
f010143e:	57                   	push   %edi
f010143f:	ff 75 d0             	pushl  -0x30(%ebp)
f0101442:	51                   	push   %ecx
f0101443:	52                   	push   %edx
f0101444:	50                   	push   %eax
f0101445:	89 da                	mov    %ebx,%edx
f0101447:	89 f0                	mov    %esi,%eax
f0101449:	e8 9c f8 ff ff       	call   f0100cea <printnum>
			break;
f010144e:	83 c4 20             	add    $0x20,%esp
f0101451:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101454:	e9 d5 f9 ff ff       	jmp    f0100e2e <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101459:	83 ec 08             	sub    $0x8,%esp
f010145c:	53                   	push   %ebx
f010145d:	51                   	push   %ecx
f010145e:	ff d6                	call   *%esi
			break;
f0101460:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101463:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101466:	e9 c3 f9 ff ff       	jmp    f0100e2e <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010146b:	83 ec 08             	sub    $0x8,%esp
f010146e:	53                   	push   %ebx
f010146f:	6a 25                	push   $0x25
f0101471:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101473:	83 c4 10             	add    $0x10,%esp
f0101476:	eb 03                	jmp    f010147b <vprintfmt+0x673>
f0101478:	83 ef 01             	sub    $0x1,%edi
f010147b:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f010147f:	75 f7                	jne    f0101478 <vprintfmt+0x670>
f0101481:	e9 a8 f9 ff ff       	jmp    f0100e2e <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101486:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101489:	5b                   	pop    %ebx
f010148a:	5e                   	pop    %esi
f010148b:	5f                   	pop    %edi
f010148c:	5d                   	pop    %ebp
f010148d:	c3                   	ret    

f010148e <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010148e:	55                   	push   %ebp
f010148f:	89 e5                	mov    %esp,%ebp
f0101491:	83 ec 18             	sub    $0x18,%esp
f0101494:	8b 45 08             	mov    0x8(%ebp),%eax
f0101497:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010149a:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010149d:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01014a1:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01014a4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01014ab:	85 c0                	test   %eax,%eax
f01014ad:	74 26                	je     f01014d5 <vsnprintf+0x47>
f01014af:	85 d2                	test   %edx,%edx
f01014b1:	7e 22                	jle    f01014d5 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01014b3:	ff 75 14             	pushl  0x14(%ebp)
f01014b6:	ff 75 10             	pushl  0x10(%ebp)
f01014b9:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01014bc:	50                   	push   %eax
f01014bd:	68 ce 0d 10 f0       	push   $0xf0100dce
f01014c2:	e8 41 f9 ff ff       	call   f0100e08 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01014c7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01014ca:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01014cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01014d0:	83 c4 10             	add    $0x10,%esp
f01014d3:	eb 05                	jmp    f01014da <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01014d5:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01014da:	c9                   	leave  
f01014db:	c3                   	ret    

f01014dc <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01014dc:	55                   	push   %ebp
f01014dd:	89 e5                	mov    %esp,%ebp
f01014df:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01014e2:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01014e5:	50                   	push   %eax
f01014e6:	ff 75 10             	pushl  0x10(%ebp)
f01014e9:	ff 75 0c             	pushl  0xc(%ebp)
f01014ec:	ff 75 08             	pushl  0x8(%ebp)
f01014ef:	e8 9a ff ff ff       	call   f010148e <vsnprintf>
	va_end(ap);

	return rc;
}
f01014f4:	c9                   	leave  
f01014f5:	c3                   	ret    

f01014f6 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01014f6:	55                   	push   %ebp
f01014f7:	89 e5                	mov    %esp,%ebp
f01014f9:	57                   	push   %edi
f01014fa:	56                   	push   %esi
f01014fb:	53                   	push   %ebx
f01014fc:	83 ec 0c             	sub    $0xc,%esp
f01014ff:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101502:	85 c0                	test   %eax,%eax
f0101504:	74 11                	je     f0101517 <readline+0x21>
		cprintf("%s", prompt);
f0101506:	83 ec 08             	sub    $0x8,%esp
f0101509:	50                   	push   %eax
f010150a:	68 26 23 10 f0       	push   $0xf0102326
f010150f:	e8 7b f4 ff ff       	call   f010098f <cprintf>
f0101514:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101517:	83 ec 0c             	sub    $0xc,%esp
f010151a:	6a 00                	push   $0x0
f010151c:	e8 3a f1 ff ff       	call   f010065b <iscons>
f0101521:	89 c7                	mov    %eax,%edi
f0101523:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101526:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010152b:	e8 1a f1 ff ff       	call   f010064a <getchar>
f0101530:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101532:	85 c0                	test   %eax,%eax
f0101534:	79 18                	jns    f010154e <readline+0x58>
			cprintf("read error: %e\n", c);
f0101536:	83 ec 08             	sub    $0x8,%esp
f0101539:	50                   	push   %eax
f010153a:	68 20 25 10 f0       	push   $0xf0102520
f010153f:	e8 4b f4 ff ff       	call   f010098f <cprintf>
			return NULL;
f0101544:	83 c4 10             	add    $0x10,%esp
f0101547:	b8 00 00 00 00       	mov    $0x0,%eax
f010154c:	eb 79                	jmp    f01015c7 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010154e:	83 f8 7f             	cmp    $0x7f,%eax
f0101551:	0f 94 c2             	sete   %dl
f0101554:	83 f8 08             	cmp    $0x8,%eax
f0101557:	0f 94 c0             	sete   %al
f010155a:	08 c2                	or     %al,%dl
f010155c:	74 1a                	je     f0101578 <readline+0x82>
f010155e:	85 f6                	test   %esi,%esi
f0101560:	7e 16                	jle    f0101578 <readline+0x82>
			if (echoing)
f0101562:	85 ff                	test   %edi,%edi
f0101564:	74 0d                	je     f0101573 <readline+0x7d>
				cputchar('\b');
f0101566:	83 ec 0c             	sub    $0xc,%esp
f0101569:	6a 08                	push   $0x8
f010156b:	e8 ca f0 ff ff       	call   f010063a <cputchar>
f0101570:	83 c4 10             	add    $0x10,%esp
			i--;
f0101573:	83 ee 01             	sub    $0x1,%esi
f0101576:	eb b3                	jmp    f010152b <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101578:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010157e:	7f 20                	jg     f01015a0 <readline+0xaa>
f0101580:	83 fb 1f             	cmp    $0x1f,%ebx
f0101583:	7e 1b                	jle    f01015a0 <readline+0xaa>
			if (echoing)
f0101585:	85 ff                	test   %edi,%edi
f0101587:	74 0c                	je     f0101595 <readline+0x9f>
				cputchar(c);
f0101589:	83 ec 0c             	sub    $0xc,%esp
f010158c:	53                   	push   %ebx
f010158d:	e8 a8 f0 ff ff       	call   f010063a <cputchar>
f0101592:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101595:	88 9e 80 25 11 f0    	mov    %bl,-0xfeeda80(%esi)
f010159b:	8d 76 01             	lea    0x1(%esi),%esi
f010159e:	eb 8b                	jmp    f010152b <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01015a0:	83 fb 0d             	cmp    $0xd,%ebx
f01015a3:	74 05                	je     f01015aa <readline+0xb4>
f01015a5:	83 fb 0a             	cmp    $0xa,%ebx
f01015a8:	75 81                	jne    f010152b <readline+0x35>
			if (echoing)
f01015aa:	85 ff                	test   %edi,%edi
f01015ac:	74 0d                	je     f01015bb <readline+0xc5>
				cputchar('\n');
f01015ae:	83 ec 0c             	sub    $0xc,%esp
f01015b1:	6a 0a                	push   $0xa
f01015b3:	e8 82 f0 ff ff       	call   f010063a <cputchar>
f01015b8:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01015bb:	c6 86 80 25 11 f0 00 	movb   $0x0,-0xfeeda80(%esi)
			return buf;
f01015c2:	b8 80 25 11 f0       	mov    $0xf0112580,%eax
		}
	}
}
f01015c7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01015ca:	5b                   	pop    %ebx
f01015cb:	5e                   	pop    %esi
f01015cc:	5f                   	pop    %edi
f01015cd:	5d                   	pop    %ebp
f01015ce:	c3                   	ret    

f01015cf <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01015cf:	55                   	push   %ebp
f01015d0:	89 e5                	mov    %esp,%ebp
f01015d2:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01015d5:	b8 00 00 00 00       	mov    $0x0,%eax
f01015da:	eb 03                	jmp    f01015df <strlen+0x10>
		n++;
f01015dc:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01015df:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01015e3:	75 f7                	jne    f01015dc <strlen+0xd>
		n++;
	return n;
}
f01015e5:	5d                   	pop    %ebp
f01015e6:	c3                   	ret    

f01015e7 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01015e7:	55                   	push   %ebp
f01015e8:	89 e5                	mov    %esp,%ebp
f01015ea:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01015ed:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01015f0:	ba 00 00 00 00       	mov    $0x0,%edx
f01015f5:	eb 03                	jmp    f01015fa <strnlen+0x13>
		n++;
f01015f7:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01015fa:	39 c2                	cmp    %eax,%edx
f01015fc:	74 08                	je     f0101606 <strnlen+0x1f>
f01015fe:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101602:	75 f3                	jne    f01015f7 <strnlen+0x10>
f0101604:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101606:	5d                   	pop    %ebp
f0101607:	c3                   	ret    

f0101608 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101608:	55                   	push   %ebp
f0101609:	89 e5                	mov    %esp,%ebp
f010160b:	53                   	push   %ebx
f010160c:	8b 45 08             	mov    0x8(%ebp),%eax
f010160f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101612:	89 c2                	mov    %eax,%edx
f0101614:	83 c2 01             	add    $0x1,%edx
f0101617:	83 c1 01             	add    $0x1,%ecx
f010161a:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010161e:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101621:	84 db                	test   %bl,%bl
f0101623:	75 ef                	jne    f0101614 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101625:	5b                   	pop    %ebx
f0101626:	5d                   	pop    %ebp
f0101627:	c3                   	ret    

f0101628 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101628:	55                   	push   %ebp
f0101629:	89 e5                	mov    %esp,%ebp
f010162b:	53                   	push   %ebx
f010162c:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010162f:	53                   	push   %ebx
f0101630:	e8 9a ff ff ff       	call   f01015cf <strlen>
f0101635:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101638:	ff 75 0c             	pushl  0xc(%ebp)
f010163b:	01 d8                	add    %ebx,%eax
f010163d:	50                   	push   %eax
f010163e:	e8 c5 ff ff ff       	call   f0101608 <strcpy>
	return dst;
}
f0101643:	89 d8                	mov    %ebx,%eax
f0101645:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101648:	c9                   	leave  
f0101649:	c3                   	ret    

f010164a <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010164a:	55                   	push   %ebp
f010164b:	89 e5                	mov    %esp,%ebp
f010164d:	56                   	push   %esi
f010164e:	53                   	push   %ebx
f010164f:	8b 75 08             	mov    0x8(%ebp),%esi
f0101652:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101655:	89 f3                	mov    %esi,%ebx
f0101657:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010165a:	89 f2                	mov    %esi,%edx
f010165c:	eb 0f                	jmp    f010166d <strncpy+0x23>
		*dst++ = *src;
f010165e:	83 c2 01             	add    $0x1,%edx
f0101661:	0f b6 01             	movzbl (%ecx),%eax
f0101664:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101667:	80 39 01             	cmpb   $0x1,(%ecx)
f010166a:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010166d:	39 da                	cmp    %ebx,%edx
f010166f:	75 ed                	jne    f010165e <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101671:	89 f0                	mov    %esi,%eax
f0101673:	5b                   	pop    %ebx
f0101674:	5e                   	pop    %esi
f0101675:	5d                   	pop    %ebp
f0101676:	c3                   	ret    

f0101677 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101677:	55                   	push   %ebp
f0101678:	89 e5                	mov    %esp,%ebp
f010167a:	56                   	push   %esi
f010167b:	53                   	push   %ebx
f010167c:	8b 75 08             	mov    0x8(%ebp),%esi
f010167f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101682:	8b 55 10             	mov    0x10(%ebp),%edx
f0101685:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101687:	85 d2                	test   %edx,%edx
f0101689:	74 21                	je     f01016ac <strlcpy+0x35>
f010168b:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010168f:	89 f2                	mov    %esi,%edx
f0101691:	eb 09                	jmp    f010169c <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101693:	83 c2 01             	add    $0x1,%edx
f0101696:	83 c1 01             	add    $0x1,%ecx
f0101699:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010169c:	39 c2                	cmp    %eax,%edx
f010169e:	74 09                	je     f01016a9 <strlcpy+0x32>
f01016a0:	0f b6 19             	movzbl (%ecx),%ebx
f01016a3:	84 db                	test   %bl,%bl
f01016a5:	75 ec                	jne    f0101693 <strlcpy+0x1c>
f01016a7:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01016a9:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01016ac:	29 f0                	sub    %esi,%eax
}
f01016ae:	5b                   	pop    %ebx
f01016af:	5e                   	pop    %esi
f01016b0:	5d                   	pop    %ebp
f01016b1:	c3                   	ret    

f01016b2 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01016b2:	55                   	push   %ebp
f01016b3:	89 e5                	mov    %esp,%ebp
f01016b5:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01016b8:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01016bb:	eb 06                	jmp    f01016c3 <strcmp+0x11>
		p++, q++;
f01016bd:	83 c1 01             	add    $0x1,%ecx
f01016c0:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01016c3:	0f b6 01             	movzbl (%ecx),%eax
f01016c6:	84 c0                	test   %al,%al
f01016c8:	74 04                	je     f01016ce <strcmp+0x1c>
f01016ca:	3a 02                	cmp    (%edx),%al
f01016cc:	74 ef                	je     f01016bd <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01016ce:	0f b6 c0             	movzbl %al,%eax
f01016d1:	0f b6 12             	movzbl (%edx),%edx
f01016d4:	29 d0                	sub    %edx,%eax
}
f01016d6:	5d                   	pop    %ebp
f01016d7:	c3                   	ret    

f01016d8 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01016d8:	55                   	push   %ebp
f01016d9:	89 e5                	mov    %esp,%ebp
f01016db:	53                   	push   %ebx
f01016dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01016df:	8b 55 0c             	mov    0xc(%ebp),%edx
f01016e2:	89 c3                	mov    %eax,%ebx
f01016e4:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01016e7:	eb 06                	jmp    f01016ef <strncmp+0x17>
		n--, p++, q++;
f01016e9:	83 c0 01             	add    $0x1,%eax
f01016ec:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01016ef:	39 d8                	cmp    %ebx,%eax
f01016f1:	74 15                	je     f0101708 <strncmp+0x30>
f01016f3:	0f b6 08             	movzbl (%eax),%ecx
f01016f6:	84 c9                	test   %cl,%cl
f01016f8:	74 04                	je     f01016fe <strncmp+0x26>
f01016fa:	3a 0a                	cmp    (%edx),%cl
f01016fc:	74 eb                	je     f01016e9 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01016fe:	0f b6 00             	movzbl (%eax),%eax
f0101701:	0f b6 12             	movzbl (%edx),%edx
f0101704:	29 d0                	sub    %edx,%eax
f0101706:	eb 05                	jmp    f010170d <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101708:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010170d:	5b                   	pop    %ebx
f010170e:	5d                   	pop    %ebp
f010170f:	c3                   	ret    

f0101710 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101710:	55                   	push   %ebp
f0101711:	89 e5                	mov    %esp,%ebp
f0101713:	8b 45 08             	mov    0x8(%ebp),%eax
f0101716:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010171a:	eb 07                	jmp    f0101723 <strchr+0x13>
		if (*s == c)
f010171c:	38 ca                	cmp    %cl,%dl
f010171e:	74 0f                	je     f010172f <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101720:	83 c0 01             	add    $0x1,%eax
f0101723:	0f b6 10             	movzbl (%eax),%edx
f0101726:	84 d2                	test   %dl,%dl
f0101728:	75 f2                	jne    f010171c <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010172a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010172f:	5d                   	pop    %ebp
f0101730:	c3                   	ret    

f0101731 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101731:	55                   	push   %ebp
f0101732:	89 e5                	mov    %esp,%ebp
f0101734:	8b 45 08             	mov    0x8(%ebp),%eax
f0101737:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010173b:	eb 03                	jmp    f0101740 <strfind+0xf>
f010173d:	83 c0 01             	add    $0x1,%eax
f0101740:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101743:	84 d2                	test   %dl,%dl
f0101745:	74 04                	je     f010174b <strfind+0x1a>
f0101747:	38 ca                	cmp    %cl,%dl
f0101749:	75 f2                	jne    f010173d <strfind+0xc>
			break;
	return (char *) s;
}
f010174b:	5d                   	pop    %ebp
f010174c:	c3                   	ret    

f010174d <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010174d:	55                   	push   %ebp
f010174e:	89 e5                	mov    %esp,%ebp
f0101750:	57                   	push   %edi
f0101751:	56                   	push   %esi
f0101752:	53                   	push   %ebx
f0101753:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101756:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101759:	85 c9                	test   %ecx,%ecx
f010175b:	74 36                	je     f0101793 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010175d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101763:	75 28                	jne    f010178d <memset+0x40>
f0101765:	f6 c1 03             	test   $0x3,%cl
f0101768:	75 23                	jne    f010178d <memset+0x40>
		c &= 0xFF;
f010176a:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010176e:	89 d3                	mov    %edx,%ebx
f0101770:	c1 e3 08             	shl    $0x8,%ebx
f0101773:	89 d6                	mov    %edx,%esi
f0101775:	c1 e6 18             	shl    $0x18,%esi
f0101778:	89 d0                	mov    %edx,%eax
f010177a:	c1 e0 10             	shl    $0x10,%eax
f010177d:	09 f0                	or     %esi,%eax
f010177f:	09 c2                	or     %eax,%edx
f0101781:	89 d0                	mov    %edx,%eax
f0101783:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101785:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101788:	fc                   	cld    
f0101789:	f3 ab                	rep stos %eax,%es:(%edi)
f010178b:	eb 06                	jmp    f0101793 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010178d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101790:	fc                   	cld    
f0101791:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101793:	89 f8                	mov    %edi,%eax
f0101795:	5b                   	pop    %ebx
f0101796:	5e                   	pop    %esi
f0101797:	5f                   	pop    %edi
f0101798:	5d                   	pop    %ebp
f0101799:	c3                   	ret    

f010179a <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010179a:	55                   	push   %ebp
f010179b:	89 e5                	mov    %esp,%ebp
f010179d:	57                   	push   %edi
f010179e:	56                   	push   %esi
f010179f:	8b 45 08             	mov    0x8(%ebp),%eax
f01017a2:	8b 75 0c             	mov    0xc(%ebp),%esi
f01017a5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01017a8:	39 c6                	cmp    %eax,%esi
f01017aa:	73 35                	jae    f01017e1 <memmove+0x47>
f01017ac:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01017af:	39 d0                	cmp    %edx,%eax
f01017b1:	73 2e                	jae    f01017e1 <memmove+0x47>
		s += n;
		d += n;
f01017b3:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01017b6:	89 d6                	mov    %edx,%esi
f01017b8:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01017ba:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01017c0:	75 13                	jne    f01017d5 <memmove+0x3b>
f01017c2:	f6 c1 03             	test   $0x3,%cl
f01017c5:	75 0e                	jne    f01017d5 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01017c7:	83 ef 04             	sub    $0x4,%edi
f01017ca:	8d 72 fc             	lea    -0x4(%edx),%esi
f01017cd:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01017d0:	fd                   	std    
f01017d1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01017d3:	eb 09                	jmp    f01017de <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01017d5:	83 ef 01             	sub    $0x1,%edi
f01017d8:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01017db:	fd                   	std    
f01017dc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01017de:	fc                   	cld    
f01017df:	eb 1d                	jmp    f01017fe <memmove+0x64>
f01017e1:	89 f2                	mov    %esi,%edx
f01017e3:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01017e5:	f6 c2 03             	test   $0x3,%dl
f01017e8:	75 0f                	jne    f01017f9 <memmove+0x5f>
f01017ea:	f6 c1 03             	test   $0x3,%cl
f01017ed:	75 0a                	jne    f01017f9 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01017ef:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01017f2:	89 c7                	mov    %eax,%edi
f01017f4:	fc                   	cld    
f01017f5:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01017f7:	eb 05                	jmp    f01017fe <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01017f9:	89 c7                	mov    %eax,%edi
f01017fb:	fc                   	cld    
f01017fc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01017fe:	5e                   	pop    %esi
f01017ff:	5f                   	pop    %edi
f0101800:	5d                   	pop    %ebp
f0101801:	c3                   	ret    

f0101802 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101802:	55                   	push   %ebp
f0101803:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101805:	ff 75 10             	pushl  0x10(%ebp)
f0101808:	ff 75 0c             	pushl  0xc(%ebp)
f010180b:	ff 75 08             	pushl  0x8(%ebp)
f010180e:	e8 87 ff ff ff       	call   f010179a <memmove>
}
f0101813:	c9                   	leave  
f0101814:	c3                   	ret    

f0101815 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101815:	55                   	push   %ebp
f0101816:	89 e5                	mov    %esp,%ebp
f0101818:	56                   	push   %esi
f0101819:	53                   	push   %ebx
f010181a:	8b 45 08             	mov    0x8(%ebp),%eax
f010181d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101820:	89 c6                	mov    %eax,%esi
f0101822:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101825:	eb 1a                	jmp    f0101841 <memcmp+0x2c>
		if (*s1 != *s2)
f0101827:	0f b6 08             	movzbl (%eax),%ecx
f010182a:	0f b6 1a             	movzbl (%edx),%ebx
f010182d:	38 d9                	cmp    %bl,%cl
f010182f:	74 0a                	je     f010183b <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101831:	0f b6 c1             	movzbl %cl,%eax
f0101834:	0f b6 db             	movzbl %bl,%ebx
f0101837:	29 d8                	sub    %ebx,%eax
f0101839:	eb 0f                	jmp    f010184a <memcmp+0x35>
		s1++, s2++;
f010183b:	83 c0 01             	add    $0x1,%eax
f010183e:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101841:	39 f0                	cmp    %esi,%eax
f0101843:	75 e2                	jne    f0101827 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101845:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010184a:	5b                   	pop    %ebx
f010184b:	5e                   	pop    %esi
f010184c:	5d                   	pop    %ebp
f010184d:	c3                   	ret    

f010184e <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010184e:	55                   	push   %ebp
f010184f:	89 e5                	mov    %esp,%ebp
f0101851:	8b 45 08             	mov    0x8(%ebp),%eax
f0101854:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0101857:	89 c2                	mov    %eax,%edx
f0101859:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010185c:	eb 07                	jmp    f0101865 <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f010185e:	38 08                	cmp    %cl,(%eax)
f0101860:	74 07                	je     f0101869 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101862:	83 c0 01             	add    $0x1,%eax
f0101865:	39 d0                	cmp    %edx,%eax
f0101867:	72 f5                	jb     f010185e <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101869:	5d                   	pop    %ebp
f010186a:	c3                   	ret    

f010186b <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010186b:	55                   	push   %ebp
f010186c:	89 e5                	mov    %esp,%ebp
f010186e:	57                   	push   %edi
f010186f:	56                   	push   %esi
f0101870:	53                   	push   %ebx
f0101871:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101874:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101877:	eb 03                	jmp    f010187c <strtol+0x11>
		s++;
f0101879:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010187c:	0f b6 01             	movzbl (%ecx),%eax
f010187f:	3c 09                	cmp    $0x9,%al
f0101881:	74 f6                	je     f0101879 <strtol+0xe>
f0101883:	3c 20                	cmp    $0x20,%al
f0101885:	74 f2                	je     f0101879 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101887:	3c 2b                	cmp    $0x2b,%al
f0101889:	75 0a                	jne    f0101895 <strtol+0x2a>
		s++;
f010188b:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010188e:	bf 00 00 00 00       	mov    $0x0,%edi
f0101893:	eb 10                	jmp    f01018a5 <strtol+0x3a>
f0101895:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010189a:	3c 2d                	cmp    $0x2d,%al
f010189c:	75 07                	jne    f01018a5 <strtol+0x3a>
		s++, neg = 1;
f010189e:	8d 49 01             	lea    0x1(%ecx),%ecx
f01018a1:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01018a5:	85 db                	test   %ebx,%ebx
f01018a7:	0f 94 c0             	sete   %al
f01018aa:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01018b0:	75 19                	jne    f01018cb <strtol+0x60>
f01018b2:	80 39 30             	cmpb   $0x30,(%ecx)
f01018b5:	75 14                	jne    f01018cb <strtol+0x60>
f01018b7:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01018bb:	0f 85 82 00 00 00    	jne    f0101943 <strtol+0xd8>
		s += 2, base = 16;
f01018c1:	83 c1 02             	add    $0x2,%ecx
f01018c4:	bb 10 00 00 00       	mov    $0x10,%ebx
f01018c9:	eb 16                	jmp    f01018e1 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f01018cb:	84 c0                	test   %al,%al
f01018cd:	74 12                	je     f01018e1 <strtol+0x76>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01018cf:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01018d4:	80 39 30             	cmpb   $0x30,(%ecx)
f01018d7:	75 08                	jne    f01018e1 <strtol+0x76>
		s++, base = 8;
f01018d9:	83 c1 01             	add    $0x1,%ecx
f01018dc:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01018e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01018e6:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01018e9:	0f b6 11             	movzbl (%ecx),%edx
f01018ec:	8d 72 d0             	lea    -0x30(%edx),%esi
f01018ef:	89 f3                	mov    %esi,%ebx
f01018f1:	80 fb 09             	cmp    $0x9,%bl
f01018f4:	77 08                	ja     f01018fe <strtol+0x93>
			dig = *s - '0';
f01018f6:	0f be d2             	movsbl %dl,%edx
f01018f9:	83 ea 30             	sub    $0x30,%edx
f01018fc:	eb 22                	jmp    f0101920 <strtol+0xb5>
		else if (*s >= 'a' && *s <= 'z')
f01018fe:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101901:	89 f3                	mov    %esi,%ebx
f0101903:	80 fb 19             	cmp    $0x19,%bl
f0101906:	77 08                	ja     f0101910 <strtol+0xa5>
			dig = *s - 'a' + 10;
f0101908:	0f be d2             	movsbl %dl,%edx
f010190b:	83 ea 57             	sub    $0x57,%edx
f010190e:	eb 10                	jmp    f0101920 <strtol+0xb5>
		else if (*s >= 'A' && *s <= 'Z')
f0101910:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101913:	89 f3                	mov    %esi,%ebx
f0101915:	80 fb 19             	cmp    $0x19,%bl
f0101918:	77 16                	ja     f0101930 <strtol+0xc5>
			dig = *s - 'A' + 10;
f010191a:	0f be d2             	movsbl %dl,%edx
f010191d:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0101920:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101923:	7d 0f                	jge    f0101934 <strtol+0xc9>
			break;
		s++, val = (val * base) + dig;
f0101925:	83 c1 01             	add    $0x1,%ecx
f0101928:	0f af 45 10          	imul   0x10(%ebp),%eax
f010192c:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010192e:	eb b9                	jmp    f01018e9 <strtol+0x7e>
f0101930:	89 c2                	mov    %eax,%edx
f0101932:	eb 02                	jmp    f0101936 <strtol+0xcb>
f0101934:	89 c2                	mov    %eax,%edx

	if (endptr)
f0101936:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010193a:	74 0d                	je     f0101949 <strtol+0xde>
		*endptr = (char *) s;
f010193c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010193f:	89 0e                	mov    %ecx,(%esi)
f0101941:	eb 06                	jmp    f0101949 <strtol+0xde>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101943:	84 c0                	test   %al,%al
f0101945:	75 92                	jne    f01018d9 <strtol+0x6e>
f0101947:	eb 98                	jmp    f01018e1 <strtol+0x76>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0101949:	f7 da                	neg    %edx
f010194b:	85 ff                	test   %edi,%edi
f010194d:	0f 45 c2             	cmovne %edx,%eax
}
f0101950:	5b                   	pop    %ebx
f0101951:	5e                   	pop    %esi
f0101952:	5f                   	pop    %edi
f0101953:	5d                   	pop    %ebp
f0101954:	c3                   	ret    
f0101955:	66 90                	xchg   %ax,%ax
f0101957:	66 90                	xchg   %ax,%ax
f0101959:	66 90                	xchg   %ax,%ax
f010195b:	66 90                	xchg   %ax,%ax
f010195d:	66 90                	xchg   %ax,%ax
f010195f:	90                   	nop

f0101960 <__udivdi3>:
f0101960:	55                   	push   %ebp
f0101961:	57                   	push   %edi
f0101962:	56                   	push   %esi
f0101963:	83 ec 10             	sub    $0x10,%esp
f0101966:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f010196a:	8b 7c 24 20          	mov    0x20(%esp),%edi
f010196e:	8b 74 24 24          	mov    0x24(%esp),%esi
f0101972:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101976:	85 d2                	test   %edx,%edx
f0101978:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010197c:	89 34 24             	mov    %esi,(%esp)
f010197f:	89 c8                	mov    %ecx,%eax
f0101981:	75 35                	jne    f01019b8 <__udivdi3+0x58>
f0101983:	39 f1                	cmp    %esi,%ecx
f0101985:	0f 87 bd 00 00 00    	ja     f0101a48 <__udivdi3+0xe8>
f010198b:	85 c9                	test   %ecx,%ecx
f010198d:	89 cd                	mov    %ecx,%ebp
f010198f:	75 0b                	jne    f010199c <__udivdi3+0x3c>
f0101991:	b8 01 00 00 00       	mov    $0x1,%eax
f0101996:	31 d2                	xor    %edx,%edx
f0101998:	f7 f1                	div    %ecx
f010199a:	89 c5                	mov    %eax,%ebp
f010199c:	89 f0                	mov    %esi,%eax
f010199e:	31 d2                	xor    %edx,%edx
f01019a0:	f7 f5                	div    %ebp
f01019a2:	89 c6                	mov    %eax,%esi
f01019a4:	89 f8                	mov    %edi,%eax
f01019a6:	f7 f5                	div    %ebp
f01019a8:	89 f2                	mov    %esi,%edx
f01019aa:	83 c4 10             	add    $0x10,%esp
f01019ad:	5e                   	pop    %esi
f01019ae:	5f                   	pop    %edi
f01019af:	5d                   	pop    %ebp
f01019b0:	c3                   	ret    
f01019b1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01019b8:	3b 14 24             	cmp    (%esp),%edx
f01019bb:	77 7b                	ja     f0101a38 <__udivdi3+0xd8>
f01019bd:	0f bd f2             	bsr    %edx,%esi
f01019c0:	83 f6 1f             	xor    $0x1f,%esi
f01019c3:	0f 84 97 00 00 00    	je     f0101a60 <__udivdi3+0x100>
f01019c9:	bd 20 00 00 00       	mov    $0x20,%ebp
f01019ce:	89 d7                	mov    %edx,%edi
f01019d0:	89 f1                	mov    %esi,%ecx
f01019d2:	29 f5                	sub    %esi,%ebp
f01019d4:	d3 e7                	shl    %cl,%edi
f01019d6:	89 c2                	mov    %eax,%edx
f01019d8:	89 e9                	mov    %ebp,%ecx
f01019da:	d3 ea                	shr    %cl,%edx
f01019dc:	89 f1                	mov    %esi,%ecx
f01019de:	09 fa                	or     %edi,%edx
f01019e0:	8b 3c 24             	mov    (%esp),%edi
f01019e3:	d3 e0                	shl    %cl,%eax
f01019e5:	89 54 24 08          	mov    %edx,0x8(%esp)
f01019e9:	89 e9                	mov    %ebp,%ecx
f01019eb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01019ef:	8b 44 24 04          	mov    0x4(%esp),%eax
f01019f3:	89 fa                	mov    %edi,%edx
f01019f5:	d3 ea                	shr    %cl,%edx
f01019f7:	89 f1                	mov    %esi,%ecx
f01019f9:	d3 e7                	shl    %cl,%edi
f01019fb:	89 e9                	mov    %ebp,%ecx
f01019fd:	d3 e8                	shr    %cl,%eax
f01019ff:	09 c7                	or     %eax,%edi
f0101a01:	89 f8                	mov    %edi,%eax
f0101a03:	f7 74 24 08          	divl   0x8(%esp)
f0101a07:	89 d5                	mov    %edx,%ebp
f0101a09:	89 c7                	mov    %eax,%edi
f0101a0b:	f7 64 24 0c          	mull   0xc(%esp)
f0101a0f:	39 d5                	cmp    %edx,%ebp
f0101a11:	89 14 24             	mov    %edx,(%esp)
f0101a14:	72 11                	jb     f0101a27 <__udivdi3+0xc7>
f0101a16:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101a1a:	89 f1                	mov    %esi,%ecx
f0101a1c:	d3 e2                	shl    %cl,%edx
f0101a1e:	39 c2                	cmp    %eax,%edx
f0101a20:	73 5e                	jae    f0101a80 <__udivdi3+0x120>
f0101a22:	3b 2c 24             	cmp    (%esp),%ebp
f0101a25:	75 59                	jne    f0101a80 <__udivdi3+0x120>
f0101a27:	8d 47 ff             	lea    -0x1(%edi),%eax
f0101a2a:	31 f6                	xor    %esi,%esi
f0101a2c:	89 f2                	mov    %esi,%edx
f0101a2e:	83 c4 10             	add    $0x10,%esp
f0101a31:	5e                   	pop    %esi
f0101a32:	5f                   	pop    %edi
f0101a33:	5d                   	pop    %ebp
f0101a34:	c3                   	ret    
f0101a35:	8d 76 00             	lea    0x0(%esi),%esi
f0101a38:	31 f6                	xor    %esi,%esi
f0101a3a:	31 c0                	xor    %eax,%eax
f0101a3c:	89 f2                	mov    %esi,%edx
f0101a3e:	83 c4 10             	add    $0x10,%esp
f0101a41:	5e                   	pop    %esi
f0101a42:	5f                   	pop    %edi
f0101a43:	5d                   	pop    %ebp
f0101a44:	c3                   	ret    
f0101a45:	8d 76 00             	lea    0x0(%esi),%esi
f0101a48:	89 f2                	mov    %esi,%edx
f0101a4a:	31 f6                	xor    %esi,%esi
f0101a4c:	89 f8                	mov    %edi,%eax
f0101a4e:	f7 f1                	div    %ecx
f0101a50:	89 f2                	mov    %esi,%edx
f0101a52:	83 c4 10             	add    $0x10,%esp
f0101a55:	5e                   	pop    %esi
f0101a56:	5f                   	pop    %edi
f0101a57:	5d                   	pop    %ebp
f0101a58:	c3                   	ret    
f0101a59:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101a60:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f0101a64:	76 0b                	jbe    f0101a71 <__udivdi3+0x111>
f0101a66:	31 c0                	xor    %eax,%eax
f0101a68:	3b 14 24             	cmp    (%esp),%edx
f0101a6b:	0f 83 37 ff ff ff    	jae    f01019a8 <__udivdi3+0x48>
f0101a71:	b8 01 00 00 00       	mov    $0x1,%eax
f0101a76:	e9 2d ff ff ff       	jmp    f01019a8 <__udivdi3+0x48>
f0101a7b:	90                   	nop
f0101a7c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a80:	89 f8                	mov    %edi,%eax
f0101a82:	31 f6                	xor    %esi,%esi
f0101a84:	e9 1f ff ff ff       	jmp    f01019a8 <__udivdi3+0x48>
f0101a89:	66 90                	xchg   %ax,%ax
f0101a8b:	66 90                	xchg   %ax,%ax
f0101a8d:	66 90                	xchg   %ax,%ax
f0101a8f:	90                   	nop

f0101a90 <__umoddi3>:
f0101a90:	55                   	push   %ebp
f0101a91:	57                   	push   %edi
f0101a92:	56                   	push   %esi
f0101a93:	83 ec 20             	sub    $0x20,%esp
f0101a96:	8b 44 24 34          	mov    0x34(%esp),%eax
f0101a9a:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0101a9e:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101aa2:	89 c6                	mov    %eax,%esi
f0101aa4:	89 44 24 10          	mov    %eax,0x10(%esp)
f0101aa8:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0101aac:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0101ab0:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101ab4:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0101ab8:	89 74 24 18          	mov    %esi,0x18(%esp)
f0101abc:	85 c0                	test   %eax,%eax
f0101abe:	89 c2                	mov    %eax,%edx
f0101ac0:	75 1e                	jne    f0101ae0 <__umoddi3+0x50>
f0101ac2:	39 f7                	cmp    %esi,%edi
f0101ac4:	76 52                	jbe    f0101b18 <__umoddi3+0x88>
f0101ac6:	89 c8                	mov    %ecx,%eax
f0101ac8:	89 f2                	mov    %esi,%edx
f0101aca:	f7 f7                	div    %edi
f0101acc:	89 d0                	mov    %edx,%eax
f0101ace:	31 d2                	xor    %edx,%edx
f0101ad0:	83 c4 20             	add    $0x20,%esp
f0101ad3:	5e                   	pop    %esi
f0101ad4:	5f                   	pop    %edi
f0101ad5:	5d                   	pop    %ebp
f0101ad6:	c3                   	ret    
f0101ad7:	89 f6                	mov    %esi,%esi
f0101ad9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0101ae0:	39 f0                	cmp    %esi,%eax
f0101ae2:	77 5c                	ja     f0101b40 <__umoddi3+0xb0>
f0101ae4:	0f bd e8             	bsr    %eax,%ebp
f0101ae7:	83 f5 1f             	xor    $0x1f,%ebp
f0101aea:	75 64                	jne    f0101b50 <__umoddi3+0xc0>
f0101aec:	8b 6c 24 14          	mov    0x14(%esp),%ebp
f0101af0:	39 6c 24 0c          	cmp    %ebp,0xc(%esp)
f0101af4:	0f 86 f6 00 00 00    	jbe    f0101bf0 <__umoddi3+0x160>
f0101afa:	3b 44 24 18          	cmp    0x18(%esp),%eax
f0101afe:	0f 82 ec 00 00 00    	jb     f0101bf0 <__umoddi3+0x160>
f0101b04:	8b 44 24 14          	mov    0x14(%esp),%eax
f0101b08:	8b 54 24 18          	mov    0x18(%esp),%edx
f0101b0c:	83 c4 20             	add    $0x20,%esp
f0101b0f:	5e                   	pop    %esi
f0101b10:	5f                   	pop    %edi
f0101b11:	5d                   	pop    %ebp
f0101b12:	c3                   	ret    
f0101b13:	90                   	nop
f0101b14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101b18:	85 ff                	test   %edi,%edi
f0101b1a:	89 fd                	mov    %edi,%ebp
f0101b1c:	75 0b                	jne    f0101b29 <__umoddi3+0x99>
f0101b1e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101b23:	31 d2                	xor    %edx,%edx
f0101b25:	f7 f7                	div    %edi
f0101b27:	89 c5                	mov    %eax,%ebp
f0101b29:	8b 44 24 10          	mov    0x10(%esp),%eax
f0101b2d:	31 d2                	xor    %edx,%edx
f0101b2f:	f7 f5                	div    %ebp
f0101b31:	89 c8                	mov    %ecx,%eax
f0101b33:	f7 f5                	div    %ebp
f0101b35:	eb 95                	jmp    f0101acc <__umoddi3+0x3c>
f0101b37:	89 f6                	mov    %esi,%esi
f0101b39:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0101b40:	89 c8                	mov    %ecx,%eax
f0101b42:	89 f2                	mov    %esi,%edx
f0101b44:	83 c4 20             	add    $0x20,%esp
f0101b47:	5e                   	pop    %esi
f0101b48:	5f                   	pop    %edi
f0101b49:	5d                   	pop    %ebp
f0101b4a:	c3                   	ret    
f0101b4b:	90                   	nop
f0101b4c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101b50:	b8 20 00 00 00       	mov    $0x20,%eax
f0101b55:	89 e9                	mov    %ebp,%ecx
f0101b57:	29 e8                	sub    %ebp,%eax
f0101b59:	d3 e2                	shl    %cl,%edx
f0101b5b:	89 c7                	mov    %eax,%edi
f0101b5d:	89 44 24 18          	mov    %eax,0x18(%esp)
f0101b61:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101b65:	89 f9                	mov    %edi,%ecx
f0101b67:	d3 e8                	shr    %cl,%eax
f0101b69:	89 c1                	mov    %eax,%ecx
f0101b6b:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101b6f:	09 d1                	or     %edx,%ecx
f0101b71:	89 fa                	mov    %edi,%edx
f0101b73:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101b77:	89 e9                	mov    %ebp,%ecx
f0101b79:	d3 e0                	shl    %cl,%eax
f0101b7b:	89 f9                	mov    %edi,%ecx
f0101b7d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101b81:	89 f0                	mov    %esi,%eax
f0101b83:	d3 e8                	shr    %cl,%eax
f0101b85:	89 e9                	mov    %ebp,%ecx
f0101b87:	89 c7                	mov    %eax,%edi
f0101b89:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0101b8d:	d3 e6                	shl    %cl,%esi
f0101b8f:	89 d1                	mov    %edx,%ecx
f0101b91:	89 fa                	mov    %edi,%edx
f0101b93:	d3 e8                	shr    %cl,%eax
f0101b95:	89 e9                	mov    %ebp,%ecx
f0101b97:	09 f0                	or     %esi,%eax
f0101b99:	8b 74 24 1c          	mov    0x1c(%esp),%esi
f0101b9d:	f7 74 24 10          	divl   0x10(%esp)
f0101ba1:	d3 e6                	shl    %cl,%esi
f0101ba3:	89 d1                	mov    %edx,%ecx
f0101ba5:	f7 64 24 0c          	mull   0xc(%esp)
f0101ba9:	39 d1                	cmp    %edx,%ecx
f0101bab:	89 74 24 14          	mov    %esi,0x14(%esp)
f0101baf:	89 d7                	mov    %edx,%edi
f0101bb1:	89 c6                	mov    %eax,%esi
f0101bb3:	72 0a                	jb     f0101bbf <__umoddi3+0x12f>
f0101bb5:	39 44 24 14          	cmp    %eax,0x14(%esp)
f0101bb9:	73 10                	jae    f0101bcb <__umoddi3+0x13b>
f0101bbb:	39 d1                	cmp    %edx,%ecx
f0101bbd:	75 0c                	jne    f0101bcb <__umoddi3+0x13b>
f0101bbf:	89 d7                	mov    %edx,%edi
f0101bc1:	89 c6                	mov    %eax,%esi
f0101bc3:	2b 74 24 0c          	sub    0xc(%esp),%esi
f0101bc7:	1b 7c 24 10          	sbb    0x10(%esp),%edi
f0101bcb:	89 ca                	mov    %ecx,%edx
f0101bcd:	89 e9                	mov    %ebp,%ecx
f0101bcf:	8b 44 24 14          	mov    0x14(%esp),%eax
f0101bd3:	29 f0                	sub    %esi,%eax
f0101bd5:	19 fa                	sbb    %edi,%edx
f0101bd7:	d3 e8                	shr    %cl,%eax
f0101bd9:	0f b6 4c 24 18       	movzbl 0x18(%esp),%ecx
f0101bde:	89 d7                	mov    %edx,%edi
f0101be0:	d3 e7                	shl    %cl,%edi
f0101be2:	89 e9                	mov    %ebp,%ecx
f0101be4:	09 f8                	or     %edi,%eax
f0101be6:	d3 ea                	shr    %cl,%edx
f0101be8:	83 c4 20             	add    $0x20,%esp
f0101beb:	5e                   	pop    %esi
f0101bec:	5f                   	pop    %edi
f0101bed:	5d                   	pop    %ebp
f0101bee:	c3                   	ret    
f0101bef:	90                   	nop
f0101bf0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101bf4:	29 f9                	sub    %edi,%ecx
f0101bf6:	19 c6                	sbb    %eax,%esi
f0101bf8:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0101bfc:	89 74 24 18          	mov    %esi,0x18(%esp)
f0101c00:	e9 ff fe ff ff       	jmp    f0101b04 <__umoddi3+0x74>
