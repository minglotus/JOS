
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
f0100015:	b8 00 60 11 00       	mov    $0x116000,%eax
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
f0100034:	bc 00 60 11 f0       	mov    $0xf0116000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


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
f0100046:	b8 90 89 11 f0       	mov    $0xf0118990,%eax
f010004b:	2d 00 83 11 f0       	sub    $0xf0118300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 83 11 f0       	push   $0xf0118300
f0100058:	e8 b2 37 00 00       	call   f010380f <memset>
//	int x = 1, y = 3, z = 4;
//	cprintf("x %d, y %x, z %d\n", x, y, z);
	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 84 04 00 00       	call   f01004e6 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 00 3d 10 f0       	push   $0xf0103d00
f010006f:	e8 dd 29 00 00       	call   f0102a51 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 be 11 00 00       	call   f0101237 <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 f5 08 00 00       	call   f010097b <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 80 89 11 f0 00 	cmpl   $0x0,0xf0118980
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 80 89 11 f0    	mov    %esi,0xf0118980

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 1b 3d 10 f0       	push   $0xf0103d1b
f01000b5:	e8 97 29 00 00       	call   f0102a51 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 67 29 00 00       	call   f0102a2b <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 c9 4f 10 f0 	movl   $0xf0104fc9,(%esp)
f01000cb:	e8 81 29 00 00       	call   f0102a51 <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 9e 08 00 00       	call   f010097b <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 33 3d 10 f0       	push   $0xf0103d33
f01000f7:	e8 55 29 00 00       	call   f0102a51 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 23 29 00 00       	call   f0102a2b <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 c9 4f 10 f0 	movl   $0xf0104fc9,(%esp)
f010010f:	e8 3d 29 00 00       	call   f0102a51 <cprintf>
	va_end(ap);
f0100114:	83 c4 10             	add    $0x10,%esp
}
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 08                	je     f0100131 <serial_proc_data+0x15>
f0100129:	b2 f8                	mov    $0xf8,%dl
f010012b:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012c:	0f b6 c0             	movzbl %al,%eax
f010012f:	eb 05                	jmp    f0100136 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100131:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    

f0100138 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100138:	55                   	push   %ebp
f0100139:	89 e5                	mov    %esp,%ebp
f010013b:	53                   	push   %ebx
f010013c:	83 ec 04             	sub    $0x4,%esp
f010013f:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100141:	eb 2a                	jmp    f010016d <cons_intr+0x35>
		if (c == 0)
f0100143:	85 d2                	test   %edx,%edx
f0100145:	74 26                	je     f010016d <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f0100147:	a1 44 85 11 f0       	mov    0xf0118544,%eax
f010014c:	8d 48 01             	lea    0x1(%eax),%ecx
f010014f:	89 0d 44 85 11 f0    	mov    %ecx,0xf0118544
f0100155:	88 90 40 83 11 f0    	mov    %dl,-0xfee7cc0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010015b:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100161:	75 0a                	jne    f010016d <cons_intr+0x35>
			cons.wpos = 0;
f0100163:	c7 05 44 85 11 f0 00 	movl   $0x0,0xf0118544
f010016a:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f010016d:	ff d3                	call   *%ebx
f010016f:	89 c2                	mov    %eax,%edx
f0100171:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100174:	75 cd                	jne    f0100143 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100176:	83 c4 04             	add    $0x4,%esp
f0100179:	5b                   	pop    %ebx
f010017a:	5d                   	pop    %ebp
f010017b:	c3                   	ret    

f010017c <kbd_proc_data>:
f010017c:	ba 64 00 00 00       	mov    $0x64,%edx
f0100181:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100182:	a8 01                	test   $0x1,%al
f0100184:	0f 84 f0 00 00 00    	je     f010027a <kbd_proc_data+0xfe>
f010018a:	b2 60                	mov    $0x60,%dl
f010018c:	ec                   	in     (%dx),%al
f010018d:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010018f:	3c e0                	cmp    $0xe0,%al
f0100191:	75 0d                	jne    f01001a0 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100193:	83 0d 00 83 11 f0 40 	orl    $0x40,0xf0118300
		return 0;
f010019a:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010019f:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp
f01001a3:	53                   	push   %ebx
f01001a4:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001a7:	84 c0                	test   %al,%al
f01001a9:	79 36                	jns    f01001e1 <kbd_proc_data+0x65>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001ab:	8b 0d 00 83 11 f0    	mov    0xf0118300,%ecx
f01001b1:	89 cb                	mov    %ecx,%ebx
f01001b3:	83 e3 40             	and    $0x40,%ebx
f01001b6:	83 e0 7f             	and    $0x7f,%eax
f01001b9:	85 db                	test   %ebx,%ebx
f01001bb:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001be:	0f b6 d2             	movzbl %dl,%edx
f01001c1:	0f b6 82 c0 3e 10 f0 	movzbl -0xfefc140(%edx),%eax
f01001c8:	83 c8 40             	or     $0x40,%eax
f01001cb:	0f b6 c0             	movzbl %al,%eax
f01001ce:	f7 d0                	not    %eax
f01001d0:	21 c8                	and    %ecx,%eax
f01001d2:	a3 00 83 11 f0       	mov    %eax,0xf0118300
		return 0;
f01001d7:	b8 00 00 00 00       	mov    $0x0,%eax
f01001dc:	e9 a1 00 00 00       	jmp    f0100282 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001e1:	8b 0d 00 83 11 f0    	mov    0xf0118300,%ecx
f01001e7:	f6 c1 40             	test   $0x40,%cl
f01001ea:	74 0e                	je     f01001fa <kbd_proc_data+0x7e>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001ec:	83 c8 80             	or     $0xffffff80,%eax
f01001ef:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001f1:	83 e1 bf             	and    $0xffffffbf,%ecx
f01001f4:	89 0d 00 83 11 f0    	mov    %ecx,0xf0118300
	}

	shift |= shiftcode[data];
f01001fa:	0f b6 c2             	movzbl %dl,%eax
f01001fd:	0f b6 90 c0 3e 10 f0 	movzbl -0xfefc140(%eax),%edx
f0100204:	0b 15 00 83 11 f0    	or     0xf0118300,%edx
	shift ^= togglecode[data];
f010020a:	0f b6 88 c0 3d 10 f0 	movzbl -0xfefc240(%eax),%ecx
f0100211:	31 ca                	xor    %ecx,%edx
f0100213:	89 15 00 83 11 f0    	mov    %edx,0xf0118300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100219:	89 d1                	mov    %edx,%ecx
f010021b:	83 e1 03             	and    $0x3,%ecx
f010021e:	8b 0c 8d 80 3d 10 f0 	mov    -0xfefc280(,%ecx,4),%ecx
f0100225:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f0100229:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f010022c:	f6 c2 08             	test   $0x8,%dl
f010022f:	74 1b                	je     f010024c <kbd_proc_data+0xd0>
		if ('a' <= c && c <= 'z')
f0100231:	89 d8                	mov    %ebx,%eax
f0100233:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100236:	83 f9 19             	cmp    $0x19,%ecx
f0100239:	77 05                	ja     f0100240 <kbd_proc_data+0xc4>
			c += 'A' - 'a';
f010023b:	83 eb 20             	sub    $0x20,%ebx
f010023e:	eb 0c                	jmp    f010024c <kbd_proc_data+0xd0>
		else if ('A' <= c && c <= 'Z')
f0100240:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f0100243:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100246:	83 f8 19             	cmp    $0x19,%eax
f0100249:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010024c:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100252:	75 2c                	jne    f0100280 <kbd_proc_data+0x104>
f0100254:	f7 d2                	not    %edx
f0100256:	f6 c2 06             	test   $0x6,%dl
f0100259:	75 25                	jne    f0100280 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f010025b:	83 ec 0c             	sub    $0xc,%esp
f010025e:	68 4d 3d 10 f0       	push   $0xf0103d4d
f0100263:	e8 e9 27 00 00       	call   f0102a51 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100268:	ba 92 00 00 00       	mov    $0x92,%edx
f010026d:	b8 03 00 00 00       	mov    $0x3,%eax
f0100272:	ee                   	out    %al,(%dx)
f0100273:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100276:	89 d8                	mov    %ebx,%eax
f0100278:	eb 08                	jmp    f0100282 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010027a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010027f:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100280:	89 d8                	mov    %ebx,%eax
}
f0100282:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100285:	c9                   	leave  
f0100286:	c3                   	ret    

f0100287 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100287:	55                   	push   %ebp
f0100288:	89 e5                	mov    %esp,%ebp
f010028a:	57                   	push   %edi
f010028b:	56                   	push   %esi
f010028c:	53                   	push   %ebx
f010028d:	83 ec 0c             	sub    $0xc,%esp
f0100290:	89 c6                	mov    %eax,%esi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100292:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100297:	bf fd 03 00 00       	mov    $0x3fd,%edi
f010029c:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002a1:	eb 09                	jmp    f01002ac <cons_putc+0x25>
f01002a3:	89 ca                	mov    %ecx,%edx
f01002a5:	ec                   	in     (%dx),%al
f01002a6:	ec                   	in     (%dx),%al
f01002a7:	ec                   	in     (%dx),%al
f01002a8:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002a9:	83 c3 01             	add    $0x1,%ebx
f01002ac:	89 fa                	mov    %edi,%edx
f01002ae:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002af:	a8 20                	test   $0x20,%al
f01002b1:	75 08                	jne    f01002bb <cons_putc+0x34>
f01002b3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002b9:	7e e8                	jle    f01002a3 <cons_putc+0x1c>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002bb:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002c0:	89 f0                	mov    %esi,%eax
f01002c2:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002c3:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002c8:	bf 79 03 00 00       	mov    $0x379,%edi
f01002cd:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002d2:	eb 09                	jmp    f01002dd <cons_putc+0x56>
f01002d4:	89 ca                	mov    %ecx,%edx
f01002d6:	ec                   	in     (%dx),%al
f01002d7:	ec                   	in     (%dx),%al
f01002d8:	ec                   	in     (%dx),%al
f01002d9:	ec                   	in     (%dx),%al
f01002da:	83 c3 01             	add    $0x1,%ebx
f01002dd:	89 fa                	mov    %edi,%edx
f01002df:	ec                   	in     (%dx),%al
f01002e0:	84 c0                	test   %al,%al
f01002e2:	78 08                	js     f01002ec <cons_putc+0x65>
f01002e4:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002ea:	7e e8                	jle    f01002d4 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ec:	ba 78 03 00 00       	mov    $0x378,%edx
f01002f1:	89 f0                	mov    %esi,%eax
f01002f3:	ee                   	out    %al,(%dx)
f01002f4:	b2 7a                	mov    $0x7a,%dl
f01002f6:	b8 0d 00 00 00       	mov    $0xd,%eax
f01002fb:	ee                   	out    %al,(%dx)
f01002fc:	b8 08 00 00 00       	mov    $0x8,%eax
f0100301:	ee                   	out    %al,(%dx)


static void
cga_putc(int c)
{
	c = c + (colr << 8);
f0100302:	a1 6c 85 11 f0       	mov    0xf011856c,%eax
f0100307:	c1 e0 08             	shl    $0x8,%eax
f010030a:	01 f0                	add    %esi,%eax
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010030c:	89 c1                	mov    %eax,%ecx
f010030e:	81 e1 00 ff ff ff    	and    $0xffffff00,%ecx
		c |= 0x0700;
f0100314:	89 c2                	mov    %eax,%edx
f0100316:	80 ce 07             	or     $0x7,%dh
f0100319:	85 c9                	test   %ecx,%ecx
f010031b:	0f 44 c2             	cmove  %edx,%eax

	switch (c & 0xff) {
f010031e:	0f b6 d0             	movzbl %al,%edx
f0100321:	83 fa 09             	cmp    $0x9,%edx
f0100324:	74 72                	je     f0100398 <cons_putc+0x111>
f0100326:	83 fa 09             	cmp    $0x9,%edx
f0100329:	7f 0a                	jg     f0100335 <cons_putc+0xae>
f010032b:	83 fa 08             	cmp    $0x8,%edx
f010032e:	74 14                	je     f0100344 <cons_putc+0xbd>
f0100330:	e9 97 00 00 00       	jmp    f01003cc <cons_putc+0x145>
f0100335:	83 fa 0a             	cmp    $0xa,%edx
f0100338:	74 38                	je     f0100372 <cons_putc+0xeb>
f010033a:	83 fa 0d             	cmp    $0xd,%edx
f010033d:	74 3b                	je     f010037a <cons_putc+0xf3>
f010033f:	e9 88 00 00 00       	jmp    f01003cc <cons_putc+0x145>
	case '\b':
		if (crt_pos > 0) {
f0100344:	0f b7 15 48 85 11 f0 	movzwl 0xf0118548,%edx
f010034b:	66 85 d2             	test   %dx,%dx
f010034e:	0f 84 e4 00 00 00    	je     f0100438 <cons_putc+0x1b1>
			crt_pos--;
f0100354:	83 ea 01             	sub    $0x1,%edx
f0100357:	66 89 15 48 85 11 f0 	mov    %dx,0xf0118548
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010035e:	0f b7 d2             	movzwl %dx,%edx
f0100361:	b0 00                	mov    $0x0,%al
f0100363:	83 c8 20             	or     $0x20,%eax
f0100366:	8b 0d 4c 85 11 f0    	mov    0xf011854c,%ecx
f010036c:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f0100370:	eb 78                	jmp    f01003ea <cons_putc+0x163>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100372:	66 83 05 48 85 11 f0 	addw   $0x50,0xf0118548
f0100379:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010037a:	0f b7 05 48 85 11 f0 	movzwl 0xf0118548,%eax
f0100381:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100387:	c1 e8 16             	shr    $0x16,%eax
f010038a:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010038d:	c1 e0 04             	shl    $0x4,%eax
f0100390:	66 a3 48 85 11 f0    	mov    %ax,0xf0118548
f0100396:	eb 52                	jmp    f01003ea <cons_putc+0x163>
		break;
	case '\t':
		cons_putc(' ');
f0100398:	b8 20 00 00 00       	mov    $0x20,%eax
f010039d:	e8 e5 fe ff ff       	call   f0100287 <cons_putc>
		cons_putc(' ');
f01003a2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003a7:	e8 db fe ff ff       	call   f0100287 <cons_putc>
		cons_putc(' ');
f01003ac:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b1:	e8 d1 fe ff ff       	call   f0100287 <cons_putc>
		cons_putc(' ');
f01003b6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003bb:	e8 c7 fe ff ff       	call   f0100287 <cons_putc>
		cons_putc(' ');
f01003c0:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c5:	e8 bd fe ff ff       	call   f0100287 <cons_putc>
f01003ca:	eb 1e                	jmp    f01003ea <cons_putc+0x163>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003cc:	0f b7 15 48 85 11 f0 	movzwl 0xf0118548,%edx
f01003d3:	8d 4a 01             	lea    0x1(%edx),%ecx
f01003d6:	66 89 0d 48 85 11 f0 	mov    %cx,0xf0118548
f01003dd:	0f b7 d2             	movzwl %dx,%edx
f01003e0:	8b 0d 4c 85 11 f0    	mov    0xf011854c,%ecx
f01003e6:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003ea:	66 81 3d 48 85 11 f0 	cmpw   $0x7cf,0xf0118548
f01003f1:	cf 07 
f01003f3:	76 43                	jbe    f0100438 <cons_putc+0x1b1>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01003f5:	a1 4c 85 11 f0       	mov    0xf011854c,%eax
f01003fa:	83 ec 04             	sub    $0x4,%esp
f01003fd:	68 00 0f 00 00       	push   $0xf00
f0100402:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100408:	52                   	push   %edx
f0100409:	50                   	push   %eax
f010040a:	e8 4d 34 00 00       	call   f010385c <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010040f:	8b 15 4c 85 11 f0    	mov    0xf011854c,%edx
f0100415:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010041b:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100421:	83 c4 10             	add    $0x10,%esp
f0100424:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100429:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010042c:	39 d0                	cmp    %edx,%eax
f010042e:	75 f4                	jne    f0100424 <cons_putc+0x19d>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100430:	66 83 2d 48 85 11 f0 	subw   $0x50,0xf0118548
f0100437:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100438:	8b 0d 50 85 11 f0    	mov    0xf0118550,%ecx
f010043e:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100443:	89 ca                	mov    %ecx,%edx
f0100445:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100446:	0f b7 1d 48 85 11 f0 	movzwl 0xf0118548,%ebx
f010044d:	8d 71 01             	lea    0x1(%ecx),%esi
f0100450:	89 d8                	mov    %ebx,%eax
f0100452:	66 c1 e8 08          	shr    $0x8,%ax
f0100456:	89 f2                	mov    %esi,%edx
f0100458:	ee                   	out    %al,(%dx)
f0100459:	b8 0f 00 00 00       	mov    $0xf,%eax
f010045e:	89 ca                	mov    %ecx,%edx
f0100460:	ee                   	out    %al,(%dx)
f0100461:	89 d8                	mov    %ebx,%eax
f0100463:	89 f2                	mov    %esi,%edx
f0100465:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100466:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100469:	5b                   	pop    %ebx
f010046a:	5e                   	pop    %esi
f010046b:	5f                   	pop    %edi
f010046c:	5d                   	pop    %ebp
f010046d:	c3                   	ret    

f010046e <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f010046e:	80 3d 54 85 11 f0 00 	cmpb   $0x0,0xf0118554
f0100475:	74 11                	je     f0100488 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100477:	55                   	push   %ebp
f0100478:	89 e5                	mov    %esp,%ebp
f010047a:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010047d:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100482:	e8 b1 fc ff ff       	call   f0100138 <cons_intr>
}
f0100487:	c9                   	leave  
f0100488:	f3 c3                	repz ret 

f010048a <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010048a:	55                   	push   %ebp
f010048b:	89 e5                	mov    %esp,%ebp
f010048d:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100490:	b8 7c 01 10 f0       	mov    $0xf010017c,%eax
f0100495:	e8 9e fc ff ff       	call   f0100138 <cons_intr>
}
f010049a:	c9                   	leave  
f010049b:	c3                   	ret    

f010049c <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f010049c:	55                   	push   %ebp
f010049d:	89 e5                	mov    %esp,%ebp
f010049f:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004a2:	e8 c7 ff ff ff       	call   f010046e <serial_intr>
	kbd_intr();
f01004a7:	e8 de ff ff ff       	call   f010048a <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004ac:	a1 40 85 11 f0       	mov    0xf0118540,%eax
f01004b1:	3b 05 44 85 11 f0    	cmp    0xf0118544,%eax
f01004b7:	74 26                	je     f01004df <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004b9:	8d 50 01             	lea    0x1(%eax),%edx
f01004bc:	89 15 40 85 11 f0    	mov    %edx,0xf0118540
f01004c2:	0f b6 88 40 83 11 f0 	movzbl -0xfee7cc0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004c9:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004cb:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004d1:	75 11                	jne    f01004e4 <cons_getc+0x48>
			cons.rpos = 0;
f01004d3:	c7 05 40 85 11 f0 00 	movl   $0x0,0xf0118540
f01004da:	00 00 00 
f01004dd:	eb 05                	jmp    f01004e4 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004df:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004e4:	c9                   	leave  
f01004e5:	c3                   	ret    

f01004e6 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004e6:	55                   	push   %ebp
f01004e7:	89 e5                	mov    %esp,%ebp
f01004e9:	57                   	push   %edi
f01004ea:	56                   	push   %esi
f01004eb:	53                   	push   %ebx
f01004ec:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01004ef:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01004f6:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01004fd:	5a a5 
	if (*cp != 0xA55A) {
f01004ff:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100506:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010050a:	74 11                	je     f010051d <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010050c:	c7 05 50 85 11 f0 b4 	movl   $0x3b4,0xf0118550
f0100513:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100516:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010051b:	eb 16                	jmp    f0100533 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010051d:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100524:	c7 05 50 85 11 f0 d4 	movl   $0x3d4,0xf0118550
f010052b:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010052e:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100533:	8b 3d 50 85 11 f0    	mov    0xf0118550,%edi
f0100539:	b8 0e 00 00 00       	mov    $0xe,%eax
f010053e:	89 fa                	mov    %edi,%edx
f0100540:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100541:	8d 4f 01             	lea    0x1(%edi),%ecx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100544:	89 ca                	mov    %ecx,%edx
f0100546:	ec                   	in     (%dx),%al
f0100547:	0f b6 c0             	movzbl %al,%eax
f010054a:	c1 e0 08             	shl    $0x8,%eax
f010054d:	89 c3                	mov    %eax,%ebx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010054f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100554:	89 fa                	mov    %edi,%edx
f0100556:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100557:	89 ca                	mov    %ecx,%edx
f0100559:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010055a:	89 35 4c 85 11 f0    	mov    %esi,0xf011854c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100560:	0f b6 c8             	movzbl %al,%ecx
f0100563:	89 d8                	mov    %ebx,%eax
f0100565:	09 c8                	or     %ecx,%eax

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100567:	66 a3 48 85 11 f0    	mov    %ax,0xf0118548
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010056d:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f0100572:	b8 00 00 00 00       	mov    $0x0,%eax
f0100577:	89 da                	mov    %ebx,%edx
f0100579:	ee                   	out    %al,(%dx)
f010057a:	b2 fb                	mov    $0xfb,%dl
f010057c:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100581:	ee                   	out    %al,(%dx)
f0100582:	be f8 03 00 00       	mov    $0x3f8,%esi
f0100587:	b8 0c 00 00 00       	mov    $0xc,%eax
f010058c:	89 f2                	mov    %esi,%edx
f010058e:	ee                   	out    %al,(%dx)
f010058f:	b2 f9                	mov    $0xf9,%dl
f0100591:	b8 00 00 00 00       	mov    $0x0,%eax
f0100596:	ee                   	out    %al,(%dx)
f0100597:	b2 fb                	mov    $0xfb,%dl
f0100599:	b8 03 00 00 00       	mov    $0x3,%eax
f010059e:	ee                   	out    %al,(%dx)
f010059f:	b2 fc                	mov    $0xfc,%dl
f01005a1:	b8 00 00 00 00       	mov    $0x0,%eax
f01005a6:	ee                   	out    %al,(%dx)
f01005a7:	b2 f9                	mov    $0xf9,%dl
f01005a9:	b8 01 00 00 00       	mov    $0x1,%eax
f01005ae:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005af:	b2 fd                	mov    $0xfd,%dl
f01005b1:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005b2:	3c ff                	cmp    $0xff,%al
f01005b4:	0f 95 c1             	setne  %cl
f01005b7:	88 0d 54 85 11 f0    	mov    %cl,0xf0118554
f01005bd:	89 da                	mov    %ebx,%edx
f01005bf:	ec                   	in     (%dx),%al
f01005c0:	89 f2                	mov    %esi,%edx
f01005c2:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005c3:	84 c9                	test   %cl,%cl
f01005c5:	75 10                	jne    f01005d7 <cons_init+0xf1>
		cprintf("Serial port does not exist!\n");
f01005c7:	83 ec 0c             	sub    $0xc,%esp
f01005ca:	68 59 3d 10 f0       	push   $0xf0103d59
f01005cf:	e8 7d 24 00 00       	call   f0102a51 <cprintf>
f01005d4:	83 c4 10             	add    $0x10,%esp
}
f01005d7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005da:	5b                   	pop    %ebx
f01005db:	5e                   	pop    %esi
f01005dc:	5f                   	pop    %edi
f01005dd:	5d                   	pop    %ebp
f01005de:	c3                   	ret    

f01005df <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005df:	55                   	push   %ebp
f01005e0:	89 e5                	mov    %esp,%ebp
f01005e2:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005e5:	8b 45 08             	mov    0x8(%ebp),%eax
f01005e8:	e8 9a fc ff ff       	call   f0100287 <cons_putc>
}
f01005ed:	c9                   	leave  
f01005ee:	c3                   	ret    

f01005ef <getchar>:

int
getchar(void)
{
f01005ef:	55                   	push   %ebp
f01005f0:	89 e5                	mov    %esp,%ebp
f01005f2:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01005f5:	e8 a2 fe ff ff       	call   f010049c <cons_getc>
f01005fa:	85 c0                	test   %eax,%eax
f01005fc:	74 f7                	je     f01005f5 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01005fe:	c9                   	leave  
f01005ff:	c3                   	ret    

f0100600 <iscons>:

int
iscons(int fdnum)
{
f0100600:	55                   	push   %ebp
f0100601:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100603:	b8 01 00 00 00       	mov    $0x1,%eax
f0100608:	5d                   	pop    %ebp
f0100609:	c3                   	ret    

f010060a <xtoi>:
	const char *name;
	const char *desc;
	// return -1 to force monitor to exit
	int (*func)(int argc, char** argv, struct Trapframe* tf);
};
static uint32_t xtoi(char*buf){
f010060a:	55                   	push   %ebp
f010060b:	89 e5                	mov    %esp,%ebp
	uint32_t res = 0;
	buf += 2;
f010060d:	8d 50 02             	lea    0x2(%eax),%edx
	const char *desc;
	// return -1 to force monitor to exit
	int (*func)(int argc, char** argv, struct Trapframe* tf);
};
static uint32_t xtoi(char*buf){
	uint32_t res = 0;
f0100610:	b8 00 00 00 00       	mov    $0x0,%eax
	buf += 2;
	while(*buf){
f0100615:	eb 17                	jmp    f010062e <xtoi+0x24>
		if(*buf >= 'a') *buf = *buf - 'a' + '0' + 10;
f0100617:	80 f9 60             	cmp    $0x60,%cl
f010061a:	7e 05                	jle    f0100621 <xtoi+0x17>
f010061c:	83 e9 27             	sub    $0x27,%ecx
f010061f:	88 0a                	mov    %cl,(%edx)
		res = res * 16 + *buf - '0';
f0100621:	c1 e0 04             	shl    $0x4,%eax
f0100624:	0f be 0a             	movsbl (%edx),%ecx
f0100627:	8d 44 08 d0          	lea    -0x30(%eax,%ecx,1),%eax
		++buf;
f010062b:	83 c2 01             	add    $0x1,%edx
	int (*func)(int argc, char** argv, struct Trapframe* tf);
};
static uint32_t xtoi(char*buf){
	uint32_t res = 0;
	buf += 2;
	while(*buf){
f010062e:	0f b6 0a             	movzbl (%edx),%ecx
f0100631:	84 c9                	test   %cl,%cl
f0100633:	75 e2                	jne    f0100617 <xtoi+0xd>
		if(*buf >= 'a') *buf = *buf - 'a' + '0' + 10;
		res = res * 16 + *buf - '0';
		++buf;
	}
	return res;
}
f0100635:	5d                   	pop    %ebp
f0100636:	c3                   	ret    

f0100637 <showvm>:
	else
		*pte = *pte | perm;
	return 0;
};

int showvm(int argc, char**argv, struct Trapframe*ft){
f0100637:	55                   	push   %ebp
f0100638:	89 e5                	mov    %esp,%ebp
f010063a:	57                   	push   %edi
f010063b:	56                   	push   %esi
f010063c:	53                   	push   %ebx
f010063d:	83 ec 0c             	sub    $0xc,%esp
f0100640:	8b 75 0c             	mov    0xc(%ebp),%esi
	if(argc == 1){
f0100643:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
f0100647:	75 12                	jne    f010065b <showvm+0x24>
		cprintf("Usage: showvm 0xaddr 0x\n");
f0100649:	83 ec 0c             	sub    $0xc,%esp
f010064c:	68 c0 3f 10 f0       	push   $0xf0103fc0
f0100651:	e8 fb 23 00 00       	call   f0102a51 <cprintf>
		return 0;
f0100656:	83 c4 10             	add    $0x10,%esp
f0100659:	eb 38                	jmp    f0100693 <showvm+0x5c>
	}
	void**addr = (void**)xtoi(argv[1]);
f010065b:	8b 46 04             	mov    0x4(%esi),%eax
f010065e:	e8 a7 ff ff ff       	call   f010060a <xtoi>
f0100663:	89 c3                	mov    %eax,%ebx
	uint32_t n = xtoi(argv[2]);
f0100665:	8b 46 08             	mov    0x8(%esi),%eax
f0100668:	e8 9d ff ff ff       	call   f010060a <xtoi>
f010066d:	89 c6                	mov    %eax,%esi
	int i;
	for(i = 0; i < n; ++i){
f010066f:	bf 00 00 00 00       	mov    $0x0,%edi
f0100674:	eb 19                	jmp    f010068f <showvm+0x58>
		cprintf("VM at %x is %x\n", addr+i,addr[i]);
f0100676:	83 ec 04             	sub    $0x4,%esp
f0100679:	ff 33                	pushl  (%ebx)
f010067b:	53                   	push   %ebx
f010067c:	68 d9 3f 10 f0       	push   $0xf0103fd9
f0100681:	e8 cb 23 00 00       	call   f0102a51 <cprintf>
		return 0;
	}
	void**addr = (void**)xtoi(argv[1]);
	uint32_t n = xtoi(argv[2]);
	int i;
	for(i = 0; i < n; ++i){
f0100686:	83 c7 01             	add    $0x1,%edi
f0100689:	83 c3 04             	add    $0x4,%ebx
f010068c:	83 c4 10             	add    $0x10,%esp
f010068f:	39 f7                	cmp    %esi,%edi
f0100691:	75 e3                	jne    f0100676 <showvm+0x3f>
		cprintf("VM at %x is %x\n", addr+i,addr[i]);
	}
	return 0;
}
f0100693:	b8 00 00 00 00       	mov    $0x0,%eax
f0100698:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010069b:	5b                   	pop    %ebx
f010069c:	5e                   	pop    %esi
f010069d:	5f                   	pop    %edi
f010069e:	5d                   	pop    %ebp
f010069f:	c3                   	ret    

f01006a0 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006a0:	55                   	push   %ebp
f01006a1:	89 e5                	mov    %esp,%ebp
f01006a3:	56                   	push   %esi
f01006a4:	53                   	push   %ebx
f01006a5:	bb 84 44 10 f0       	mov    $0xf0104484,%ebx
f01006aa:	be cc 44 10 f0       	mov    $0xf01044cc,%esi
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006af:	83 ec 04             	sub    $0x4,%esp
f01006b2:	ff 33                	pushl  (%ebx)
f01006b4:	ff 73 fc             	pushl  -0x4(%ebx)
f01006b7:	68 e9 3f 10 f0       	push   $0xf0103fe9
f01006bc:	e8 90 23 00 00       	call   f0102a51 <cprintf>
f01006c1:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f01006c4:	83 c4 10             	add    $0x10,%esp
f01006c7:	39 f3                	cmp    %esi,%ebx
f01006c9:	75 e4                	jne    f01006af <mon_help+0xf>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f01006cb:	b8 00 00 00 00       	mov    $0x0,%eax
f01006d0:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01006d3:	5b                   	pop    %ebx
f01006d4:	5e                   	pop    %esi
f01006d5:	5d                   	pop    %ebp
f01006d6:	c3                   	ret    

f01006d7 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006d7:	55                   	push   %ebp
f01006d8:	89 e5                	mov    %esp,%ebp
f01006da:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006dd:	68 f2 3f 10 f0       	push   $0xf0103ff2
f01006e2:	e8 6a 23 00 00       	call   f0102a51 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006e7:	83 c4 08             	add    $0x8,%esp
f01006ea:	68 0c 00 10 00       	push   $0x10000c
f01006ef:	68 48 41 10 f0       	push   $0xf0104148
f01006f4:	e8 58 23 00 00       	call   f0102a51 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006f9:	83 c4 0c             	add    $0xc,%esp
f01006fc:	68 0c 00 10 00       	push   $0x10000c
f0100701:	68 0c 00 10 f0       	push   $0xf010000c
f0100706:	68 70 41 10 f0       	push   $0xf0104170
f010070b:	e8 41 23 00 00       	call   f0102a51 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100710:	83 c4 0c             	add    $0xc,%esp
f0100713:	68 c5 3c 10 00       	push   $0x103cc5
f0100718:	68 c5 3c 10 f0       	push   $0xf0103cc5
f010071d:	68 94 41 10 f0       	push   $0xf0104194
f0100722:	e8 2a 23 00 00       	call   f0102a51 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100727:	83 c4 0c             	add    $0xc,%esp
f010072a:	68 00 83 11 00       	push   $0x118300
f010072f:	68 00 83 11 f0       	push   $0xf0118300
f0100734:	68 b8 41 10 f0       	push   $0xf01041b8
f0100739:	e8 13 23 00 00       	call   f0102a51 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010073e:	83 c4 0c             	add    $0xc,%esp
f0100741:	68 90 89 11 00       	push   $0x118990
f0100746:	68 90 89 11 f0       	push   $0xf0118990
f010074b:	68 dc 41 10 f0       	push   $0xf01041dc
f0100750:	e8 fc 22 00 00       	call   f0102a51 <cprintf>
f0100755:	b8 8f 8d 11 f0       	mov    $0xf0118d8f,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010075a:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010075f:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100762:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100767:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010076d:	85 c0                	test   %eax,%eax
f010076f:	0f 48 c2             	cmovs  %edx,%eax
f0100772:	c1 f8 0a             	sar    $0xa,%eax
f0100775:	50                   	push   %eax
f0100776:	68 00 42 10 f0       	push   $0xf0104200
f010077b:	e8 d1 22 00 00       	call   f0102a51 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100780:	b8 00 00 00 00       	mov    $0x0,%eax
f0100785:	c9                   	leave  
f0100786:	c3                   	ret    

f0100787 <setpte>:
			cprintf("page not exist: %x\n",begin);
		}
	}
	return 0;
}
int setpte(int argc, char**argv, struct Trapframe*tf){
f0100787:	55                   	push   %ebp
f0100788:	89 e5                	mov    %esp,%ebp
f010078a:	56                   	push   %esi
f010078b:	53                   	push   %ebx
f010078c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	if(argc == 1){
f010078f:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
f0100793:	75 12                	jne    f01007a7 <setpte+0x20>
		cprintf("Usage: setpte 0xaddress [0|1] [W|P|U]\n");
f0100795:	83 ec 0c             	sub    $0xc,%esp
f0100798:	68 2c 42 10 f0       	push   $0xf010422c
f010079d:	e8 af 22 00 00       	call   f0102a51 <cprintf>
		return 0;
f01007a2:	83 c4 10             	add    $0x10,%esp
f01007a5:	eb 6e                	jmp    f0100815 <setpte+0x8e>
	}
	uint32_t addr = xtoi(argv[1]);
f01007a7:	8b 43 04             	mov    0x4(%ebx),%eax
f01007aa:	e8 5b fe ff ff       	call   f010060a <xtoi>
	pte_t *pte = pgdir_walk(kern_pgdir,(void*)addr, 1);
f01007af:	83 ec 04             	sub    $0x4,%esp
f01007b2:	6a 01                	push   $0x1
f01007b4:	50                   	push   %eax
f01007b5:	ff 35 88 89 11 f0    	pushl  0xf0118988
f01007bb:	e8 55 08 00 00       	call   f0101015 <pgdir_walk>
f01007c0:	89 c6                	mov    %eax,%esi
	cprintf("PTE_P: %x, PTE_W, %x, PTE_U, %x\n", *pte&PTE_P, *pte&PTE_W, *pte&PTE_U);
f01007c2:	8b 10                	mov    (%eax),%edx
f01007c4:	89 d0                	mov    %edx,%eax
f01007c6:	83 e0 04             	and    $0x4,%eax
f01007c9:	50                   	push   %eax
f01007ca:	89 d0                	mov    %edx,%eax
f01007cc:	83 e0 02             	and    $0x2,%eax
f01007cf:	50                   	push   %eax
f01007d0:	83 e2 01             	and    $0x1,%edx
f01007d3:	52                   	push   %edx
f01007d4:	68 54 42 10 f0       	push   $0xf0104254
f01007d9:	e8 73 22 00 00       	call   f0102a51 <cprintf>
	uint32_t perm = 0; 
	if(argv[3][0] =='P') perm = PTE_P;
f01007de:	8b 43 0c             	mov    0xc(%ebx),%eax
f01007e1:	0f b6 10             	movzbl (%eax),%edx
f01007e4:	83 c4 20             	add    $0x20,%esp
f01007e7:	80 fa 50             	cmp    $0x50,%dl
f01007ea:	0f 94 c0             	sete   %al
f01007ed:	0f b6 c0             	movzbl %al,%eax
	if(argv[3][0] =='W') perm |= PTE_W;
f01007f0:	80 fa 57             	cmp    $0x57,%dl
f01007f3:	75 05                	jne    f01007fa <setpte+0x73>
f01007f5:	83 c8 02             	or     $0x2,%eax
f01007f8:	eb 0b                	jmp    f0100805 <setpte+0x7e>
	if(argv[3][0] =='U') perm |= PTE_U;
f01007fa:	89 c1                	mov    %eax,%ecx
f01007fc:	83 c9 04             	or     $0x4,%ecx
f01007ff:	80 fa 55             	cmp    $0x55,%dl
f0100802:	0f 44 c1             	cmove  %ecx,%eax
	if(argv[2][0] == '0')
f0100805:	8b 53 08             	mov    0x8(%ebx),%edx
f0100808:	80 3a 30             	cmpb   $0x30,(%edx)
f010080b:	75 06                	jne    f0100813 <setpte+0x8c>
		*pte = *pte & ~perm;
f010080d:	f7 d0                	not    %eax
f010080f:	21 06                	and    %eax,(%esi)
f0100811:	eb 02                	jmp    f0100815 <setpte+0x8e>
	else
		*pte = *pte | perm;
f0100813:	09 06                	or     %eax,(%esi)
	return 0;
};
f0100815:	b8 00 00 00 00       	mov    $0x0,%eax
f010081a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010081d:	5b                   	pop    %ebx
f010081e:	5e                   	pop    %esi
f010081f:	5d                   	pop    %ebp
f0100820:	c3                   	ret    

f0100821 <showmap>:
		++buf;
	}
	return res;
}

int showmap(int argc, char**argv, struct Trapframe*tf){
f0100821:	55                   	push   %ebp
f0100822:	89 e5                	mov    %esp,%ebp
f0100824:	57                   	push   %edi
f0100825:	56                   	push   %esi
f0100826:	53                   	push   %ebx
f0100827:	83 ec 0c             	sub    $0xc,%esp
f010082a:	8b 75 0c             	mov    0xc(%ebp),%esi
	if(argc == 1){	
f010082d:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
f0100831:	75 15                	jne    f0100848 <showmap+0x27>
		cprintf("Usage: showmappings 0xbegin_addr 0xend_addr\n");
f0100833:	83 ec 0c             	sub    $0xc,%esp
f0100836:	68 78 42 10 f0       	push   $0xf0104278
f010083b:	e8 11 22 00 00       	call   f0102a51 <cprintf>
		return 0;
f0100840:	83 c4 10             	add    $0x10,%esp
f0100843:	e9 a5 00 00 00       	jmp    f01008ed <showmap+0xcc>
	}
	uint32_t begin = xtoi(argv[1]), end = xtoi(argv[2]);
f0100848:	8b 46 04             	mov    0x4(%esi),%eax
f010084b:	e8 ba fd ff ff       	call   f010060a <xtoi>
f0100850:	89 c3                	mov    %eax,%ebx
f0100852:	8b 46 08             	mov    0x8(%esi),%eax
f0100855:	e8 b0 fd ff ff       	call   f010060a <xtoi>
f010085a:	89 c7                	mov    %eax,%edi
	cprintf("begin : %x, end: %x\n", begin, end);
f010085c:	83 ec 04             	sub    $0x4,%esp
f010085f:	50                   	push   %eax
f0100860:	53                   	push   %ebx
f0100861:	68 0b 40 10 f0       	push   $0xf010400b
f0100866:	e8 e6 21 00 00       	call   f0102a51 <cprintf>
	for(; begin <= end; begin += PGSIZE){
f010086b:	83 c4 10             	add    $0x10,%esp
f010086e:	eb 79                	jmp    f01008e9 <showmap+0xc8>
		pte_t *pte = pgdir_walk(kern_pgdir,(void*)begin, 1);
f0100870:	83 ec 04             	sub    $0x4,%esp
f0100873:	6a 01                	push   $0x1
f0100875:	53                   	push   %ebx
f0100876:	ff 35 88 89 11 f0    	pushl  0xf0118988
f010087c:	e8 94 07 00 00       	call   f0101015 <pgdir_walk>
f0100881:	89 c6                	mov    %eax,%esi
		if(!pte) panic("boot map region panic, out of memory");
f0100883:	83 c4 10             	add    $0x10,%esp
f0100886:	85 c0                	test   %eax,%eax
f0100888:	75 14                	jne    f010089e <showmap+0x7d>
f010088a:	83 ec 04             	sub    $0x4,%esp
f010088d:	68 a8 42 10 f0       	push   $0xf01042a8
f0100892:	6a 29                	push   $0x29
f0100894:	68 20 40 10 f0       	push   $0xf0104020
f0100899:	e8 ed f7 ff ff       	call   f010008b <_panic>
		if(*pte & PTE_P){
f010089e:	f6 00 01             	testb  $0x1,(%eax)
f01008a1:	74 2f                	je     f01008d2 <showmap+0xb1>
			cprintf("page %x with ", begin);
f01008a3:	83 ec 08             	sub    $0x8,%esp
f01008a6:	53                   	push   %ebx
f01008a7:	68 2f 40 10 f0       	push   $0xf010402f
f01008ac:	e8 a0 21 00 00       	call   f0102a51 <cprintf>
			cprintf("PTE_P: %x, PTE_W, %x, PTE_U, %x\n", *pte&PTE_P, *pte&PTE_W, *pte&PTE_U);
f01008b1:	8b 06                	mov    (%esi),%eax
f01008b3:	89 c2                	mov    %eax,%edx
f01008b5:	83 e2 04             	and    $0x4,%edx
f01008b8:	52                   	push   %edx
f01008b9:	89 c2                	mov    %eax,%edx
f01008bb:	83 e2 02             	and    $0x2,%edx
f01008be:	52                   	push   %edx
f01008bf:	83 e0 01             	and    $0x1,%eax
f01008c2:	50                   	push   %eax
f01008c3:	68 54 42 10 f0       	push   $0xf0104254
f01008c8:	e8 84 21 00 00       	call   f0102a51 <cprintf>
f01008cd:	83 c4 20             	add    $0x20,%esp
f01008d0:	eb 11                	jmp    f01008e3 <showmap+0xc2>
		}
		else{
			cprintf("page not exist: %x\n",begin);
f01008d2:	83 ec 08             	sub    $0x8,%esp
f01008d5:	53                   	push   %ebx
f01008d6:	68 3d 40 10 f0       	push   $0xf010403d
f01008db:	e8 71 21 00 00       	call   f0102a51 <cprintf>
f01008e0:	83 c4 10             	add    $0x10,%esp
		cprintf("Usage: showmappings 0xbegin_addr 0xend_addr\n");
		return 0;
	}
	uint32_t begin = xtoi(argv[1]), end = xtoi(argv[2]);
	cprintf("begin : %x, end: %x\n", begin, end);
	for(; begin <= end; begin += PGSIZE){
f01008e3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01008e9:	39 fb                	cmp    %edi,%ebx
f01008eb:	76 83                	jbe    f0100870 <showmap+0x4f>
		else{
			cprintf("page not exist: %x\n",begin);
		}
	}
	return 0;
}
f01008ed:	b8 00 00 00 00       	mov    $0x0,%eax
f01008f2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008f5:	5b                   	pop    %ebx
f01008f6:	5e                   	pop    %esi
f01008f7:	5f                   	pop    %edi
f01008f8:	5d                   	pop    %ebp
f01008f9:	c3                   	ret    

f01008fa <mon_backtrace>:
}*/


int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008fa:	55                   	push   %ebp
f01008fb:	89 e5                	mov    %esp,%ebp
f01008fd:	57                   	push   %edi
f01008fe:	56                   	push   %esi
f01008ff:	53                   	push   %ebx
f0100900:	83 ec 38             	sub    $0x38,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100903:	89 ee                	mov    %ebp,%esi
	uint32_t *ebp = (uint32_t*)read_ebp();
f0100905:	89 f3                	mov    %esi,%ebx
	uint32_t *eip = ebp + 1;
f0100907:	83 c6 04             	add    $0x4,%esi
	cprintf("Stack backtrace:\n");
f010090a:	68 51 40 10 f0       	push   $0xf0104051
f010090f:	e8 3d 21 00 00       	call   f0102a51 <cprintf>
	while(ebp){
f0100914:	83 c4 10             	add    $0x10,%esp
		cprintf("ebp %08x   eip %08x  args %08x %08x %08x %08x %08x\n",ebp, *eip, *(ebp + 2), *(ebp+3),*(ebp + 4), *(ebp + 5), *(ebp + 6));
		struct Eipdebuginfo info;
		debuginfo_eip(*eip,&info);
f0100917:	8d 7d d0             	lea    -0x30(%ebp),%edi
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t *ebp = (uint32_t*)read_ebp();
	uint32_t *eip = ebp + 1;
	cprintf("Stack backtrace:\n");
	while(ebp){
f010091a:	eb 4e                	jmp    f010096a <mon_backtrace+0x70>
		cprintf("ebp %08x   eip %08x  args %08x %08x %08x %08x %08x\n",ebp, *eip, *(ebp + 2), *(ebp+3),*(ebp + 4), *(ebp + 5), *(ebp + 6));
f010091c:	ff 73 18             	pushl  0x18(%ebx)
f010091f:	ff 73 14             	pushl  0x14(%ebx)
f0100922:	ff 73 10             	pushl  0x10(%ebx)
f0100925:	ff 73 0c             	pushl  0xc(%ebx)
f0100928:	ff 73 08             	pushl  0x8(%ebx)
f010092b:	ff 36                	pushl  (%esi)
f010092d:	53                   	push   %ebx
f010092e:	68 d0 42 10 f0       	push   $0xf01042d0
f0100933:	e8 19 21 00 00       	call   f0102a51 <cprintf>
		struct Eipdebuginfo info;
		debuginfo_eip(*eip,&info);
f0100938:	83 c4 18             	add    $0x18,%esp
f010093b:	57                   	push   %edi
f010093c:	ff 36                	pushl  (%esi)
f010093e:	e8 24 22 00 00       	call   f0102b67 <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,(*eip) - info.eip_fn_addr);
f0100943:	83 c4 08             	add    $0x8,%esp
f0100946:	8b 06                	mov    (%esi),%eax
f0100948:	2b 45 e0             	sub    -0x20(%ebp),%eax
f010094b:	50                   	push   %eax
f010094c:	ff 75 d8             	pushl  -0x28(%ebp)
f010094f:	ff 75 dc             	pushl  -0x24(%ebp)
f0100952:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100955:	ff 75 d0             	pushl  -0x30(%ebp)
f0100958:	68 63 40 10 f0       	push   $0xf0104063
f010095d:	e8 ef 20 00 00       	call   f0102a51 <cprintf>
		ebp = (uint32_t*)*ebp;
f0100962:	8b 1b                	mov    (%ebx),%ebx
		eip = (uint32_t*)ebp + 1;
f0100964:	8d 73 04             	lea    0x4(%ebx),%esi
f0100967:	83 c4 20             	add    $0x20,%esp
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t *ebp = (uint32_t*)read_ebp();
	uint32_t *eip = ebp + 1;
	cprintf("Stack backtrace:\n");
	while(ebp){
f010096a:	85 db                	test   %ebx,%ebx
f010096c:	75 ae                	jne    f010091c <mon_backtrace+0x22>
		ebp = (uint32_t*)*ebp;
		eip = (uint32_t*)ebp + 1;
	}
	
	return 0;
}
f010096e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100973:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100976:	5b                   	pop    %ebx
f0100977:	5e                   	pop    %esi
f0100978:	5f                   	pop    %edi
f0100979:	5d                   	pop    %ebp
f010097a:	c3                   	ret    

f010097b <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010097b:	55                   	push   %ebp
f010097c:	89 e5                	mov    %esp,%ebp
f010097e:	57                   	push   %edi
f010097f:	56                   	push   %esi
f0100980:	53                   	push   %ebx
f0100981:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100984:	68 04 43 10 f0       	push   $0xf0104304
f0100989:	e8 c3 20 00 00       	call   f0102a51 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010098e:	c7 04 24 28 43 10 f0 	movl   $0xf0104328,(%esp)
f0100995:	e8 b7 20 00 00       	call   f0102a51 <cprintf>
	cprintf("%Ccyn Colored scheme with no highlight.\n");
f010099a:	c7 04 24 50 43 10 f0 	movl   $0xf0104350,(%esp)
f01009a1:	e8 ab 20 00 00       	call   f0102a51 <cprintf>
	cprintf("%Cble Hello%Cred World. %Cmag Test for colorization.\n");
f01009a6:	c7 04 24 7c 43 10 f0 	movl   $0xf010437c,(%esp)
f01009ad:	e8 9f 20 00 00       	call   f0102a51 <cprintf>
	cprintf("%Ibrw Colored scheme with highlight.\n");
f01009b2:	c7 04 24 b4 43 10 f0 	movl   $0xf01043b4,(%esp)
f01009b9:	e8 93 20 00 00       	call   f0102a51 <cprintf>
	cprintf("%Ible Hello%Ired World. %Imag Test for colorization.\n");
f01009be:	c7 04 24 dc 43 10 f0 	movl   $0xf01043dc,(%esp)
f01009c5:	e8 87 20 00 00       	call   f0102a51 <cprintf>
	cprintf("%Cwht Return to default!\n");
f01009ca:	c7 04 24 74 40 10 f0 	movl   $0xf0104074,(%esp)
f01009d1:	e8 7b 20 00 00       	call   f0102a51 <cprintf>
f01009d6:	83 c4 10             	add    $0x10,%esp
	while (1) {
		buf = readline("K> ");
f01009d9:	83 ec 0c             	sub    $0xc,%esp
f01009dc:	68 8e 40 10 f0       	push   $0xf010408e
f01009e1:	e8 d2 2b 00 00       	call   f01035b8 <readline>
f01009e6:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01009e8:	83 c4 10             	add    $0x10,%esp
f01009eb:	85 c0                	test   %eax,%eax
f01009ed:	74 ea                	je     f01009d9 <monitor+0x5e>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01009ef:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01009f6:	be 00 00 00 00       	mov    $0x0,%esi
f01009fb:	eb 0a                	jmp    f0100a07 <monitor+0x8c>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01009fd:	c6 03 00             	movb   $0x0,(%ebx)
f0100a00:	89 f7                	mov    %esi,%edi
f0100a02:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100a05:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100a07:	0f b6 03             	movzbl (%ebx),%eax
f0100a0a:	84 c0                	test   %al,%al
f0100a0c:	74 63                	je     f0100a71 <monitor+0xf6>
f0100a0e:	83 ec 08             	sub    $0x8,%esp
f0100a11:	0f be c0             	movsbl %al,%eax
f0100a14:	50                   	push   %eax
f0100a15:	68 92 40 10 f0       	push   $0xf0104092
f0100a1a:	e8 b3 2d 00 00       	call   f01037d2 <strchr>
f0100a1f:	83 c4 10             	add    $0x10,%esp
f0100a22:	85 c0                	test   %eax,%eax
f0100a24:	75 d7                	jne    f01009fd <monitor+0x82>
			*buf++ = 0;
		if (*buf == 0)
f0100a26:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100a29:	74 46                	je     f0100a71 <monitor+0xf6>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100a2b:	83 fe 0f             	cmp    $0xf,%esi
f0100a2e:	75 14                	jne    f0100a44 <monitor+0xc9>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100a30:	83 ec 08             	sub    $0x8,%esp
f0100a33:	6a 10                	push   $0x10
f0100a35:	68 97 40 10 f0       	push   $0xf0104097
f0100a3a:	e8 12 20 00 00       	call   f0102a51 <cprintf>
f0100a3f:	83 c4 10             	add    $0x10,%esp
f0100a42:	eb 95                	jmp    f01009d9 <monitor+0x5e>
			return 0;
		}
		argv[argc++] = buf;
f0100a44:	8d 7e 01             	lea    0x1(%esi),%edi
f0100a47:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100a4b:	eb 03                	jmp    f0100a50 <monitor+0xd5>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100a4d:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a50:	0f b6 03             	movzbl (%ebx),%eax
f0100a53:	84 c0                	test   %al,%al
f0100a55:	74 ae                	je     f0100a05 <monitor+0x8a>
f0100a57:	83 ec 08             	sub    $0x8,%esp
f0100a5a:	0f be c0             	movsbl %al,%eax
f0100a5d:	50                   	push   %eax
f0100a5e:	68 92 40 10 f0       	push   $0xf0104092
f0100a63:	e8 6a 2d 00 00       	call   f01037d2 <strchr>
f0100a68:	83 c4 10             	add    $0x10,%esp
f0100a6b:	85 c0                	test   %eax,%eax
f0100a6d:	74 de                	je     f0100a4d <monitor+0xd2>
f0100a6f:	eb 94                	jmp    f0100a05 <monitor+0x8a>
			buf++;
	}
	argv[argc] = 0;
f0100a71:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100a78:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100a79:	85 f6                	test   %esi,%esi
f0100a7b:	0f 84 58 ff ff ff    	je     f01009d9 <monitor+0x5e>
f0100a81:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a86:	83 ec 08             	sub    $0x8,%esp
f0100a89:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a8c:	ff 34 85 80 44 10 f0 	pushl  -0xfefbb80(,%eax,4)
f0100a93:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a96:	e8 d9 2c 00 00       	call   f0103774 <strcmp>
f0100a9b:	83 c4 10             	add    $0x10,%esp
f0100a9e:	85 c0                	test   %eax,%eax
f0100aa0:	75 22                	jne    f0100ac4 <monitor+0x149>
			return commands[i].func(argc, argv, tf);
f0100aa2:	83 ec 04             	sub    $0x4,%esp
f0100aa5:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100aa8:	ff 75 08             	pushl  0x8(%ebp)
f0100aab:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100aae:	52                   	push   %edx
f0100aaf:	56                   	push   %esi
f0100ab0:	ff 14 85 88 44 10 f0 	call   *-0xfefbb78(,%eax,4)
	cprintf("%Ible Hello%Ired World. %Imag Test for colorization.\n");
	cprintf("%Cwht Return to default!\n");
	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100ab7:	83 c4 10             	add    $0x10,%esp
f0100aba:	85 c0                	test   %eax,%eax
f0100abc:	0f 89 17 ff ff ff    	jns    f01009d9 <monitor+0x5e>
f0100ac2:	eb 20                	jmp    f0100ae4 <monitor+0x169>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100ac4:	83 c3 01             	add    $0x1,%ebx
f0100ac7:	83 fb 06             	cmp    $0x6,%ebx
f0100aca:	75 ba                	jne    f0100a86 <monitor+0x10b>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100acc:	83 ec 08             	sub    $0x8,%esp
f0100acf:	ff 75 a8             	pushl  -0x58(%ebp)
f0100ad2:	68 b4 40 10 f0       	push   $0xf01040b4
f0100ad7:	e8 75 1f 00 00       	call   f0102a51 <cprintf>
f0100adc:	83 c4 10             	add    $0x10,%esp
f0100adf:	e9 f5 fe ff ff       	jmp    f01009d9 <monitor+0x5e>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100ae4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ae7:	5b                   	pop    %ebx
f0100ae8:	5e                   	pop    %esi
f0100ae9:	5f                   	pop    %edi
f0100aea:	5d                   	pop    %ebp
f0100aeb:	c3                   	ret    

f0100aec <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100aec:	89 d1                	mov    %edx,%ecx
f0100aee:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100af1:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100af4:	a8 01                	test   $0x1,%al
f0100af6:	74 6d                	je     f0100b65 <check_va2pa+0x79>
		return ~0;
	if(pseEnbl && *pgdir & PTE_PS){
f0100af8:	83 3d 60 85 11 f0 00 	cmpl   $0x0,0xf0118560
f0100aff:	74 12                	je     f0100b13 <check_va2pa+0x27>
f0100b01:	a8 80                	test   $0x80,%al
f0100b03:	74 0e                	je     f0100b13 <check_va2pa+0x27>
		return PTE_ADDR(*pgdir) + (PTX(va) << PGSHIFT);
f0100b05:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b0a:	81 e2 00 f0 3f 00    	and    $0x3ff000,%edx
f0100b10:	01 d0                	add    %edx,%eax
f0100b12:	c3                   	ret    
	}
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100b13:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b18:	89 c1                	mov    %eax,%ecx
f0100b1a:	c1 e9 0c             	shr    $0xc,%ecx
f0100b1d:	3b 0d 84 89 11 f0    	cmp    0xf0118984,%ecx
f0100b23:	72 1b                	jb     f0100b40 <check_va2pa+0x54>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b25:	55                   	push   %ebp
f0100b26:	89 e5                	mov    %esp,%ebp
f0100b28:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b2b:	50                   	push   %eax
f0100b2c:	68 c8 44 10 f0       	push   $0xf01044c8
f0100b31:	68 f1 02 00 00       	push   $0x2f1
f0100b36:	68 ec 4c 10 f0       	push   $0xf0104cec
f0100b3b:	e8 4b f5 ff ff       	call   f010008b <_panic>
		return ~0;
	if(pseEnbl && *pgdir & PTE_PS){
		return PTE_ADDR(*pgdir) + (PTX(va) << PGSHIFT);
	}
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100b40:	c1 ea 0c             	shr    $0xc,%edx
f0100b43:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b49:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100b50:	89 c2                	mov    %eax,%edx
f0100b52:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b55:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b5a:	85 d2                	test   %edx,%edx
f0100b5c:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b61:	0f 44 c2             	cmove  %edx,%eax
f0100b64:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100b65:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	}
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100b6a:	c3                   	ret    

f0100b6b <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100b6b:	55                   	push   %ebp
f0100b6c:	89 e5                	mov    %esp,%ebp
f0100b6e:	83 ec 08             	sub    $0x8,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100b71:	83 3d 58 85 11 f0 00 	cmpl   $0x0,0xf0118558
f0100b78:	75 11                	jne    f0100b8b <boot_alloc+0x20>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100b7a:	ba 8f 99 11 f0       	mov    $0xf011998f,%edx
f0100b7f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b85:	89 15 58 85 11 f0    	mov    %edx,0xf0118558
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	
	if(n != 0){
f0100b8b:	85 c0                	test   %eax,%eax
f0100b8d:	74 5f                	je     f0100bee <boot_alloc+0x83>
		char *start = nextfree;
f0100b8f:	8b 0d 58 85 11 f0    	mov    0xf0118558,%ecx
		nextfree += n;
		nextfree = ROUNDUP((char*)nextfree, PGSIZE);
f0100b95:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f0100b9c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100ba2:	89 15 58 85 11 f0    	mov    %edx,0xf0118558
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100ba8:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0100bae:	77 12                	ja     f0100bc2 <boot_alloc+0x57>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100bb0:	52                   	push   %edx
f0100bb1:	68 ec 44 10 f0       	push   $0xf01044ec
f0100bb6:	6a 6b                	push   $0x6b
f0100bb8:	68 ec 4c 10 f0       	push   $0xf0104cec
f0100bbd:	e8 c9 f4 ff ff       	call   f010008b <_panic>
		if(PADDR(nextfree) > npages * PGSIZE){
f0100bc2:	a1 84 89 11 f0       	mov    0xf0118984,%eax
f0100bc7:	c1 e0 0c             	shl    $0xc,%eax
	return (physaddr_t)kva - KERNBASE;
f0100bca:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0100bd0:	39 d0                	cmp    %edx,%eax
f0100bd2:	73 21                	jae    f0100bf5 <boot_alloc+0x8a>
			nextfree = start;
f0100bd4:	89 0d 58 85 11 f0    	mov    %ecx,0xf0118558
			panic("Run out of memory");
f0100bda:	83 ec 04             	sub    $0x4,%esp
f0100bdd:	68 f8 4c 10 f0       	push   $0xf0104cf8
f0100be2:	6a 6d                	push   $0x6d
f0100be4:	68 ec 4c 10 f0       	push   $0xf0104cec
f0100be9:	e8 9d f4 ff ff       	call   f010008b <_panic>
		}
		return start;
	}
	else{
		return nextfree;
f0100bee:	a1 58 85 11 f0       	mov    0xf0118558,%eax
f0100bf3:	eb 02                	jmp    f0100bf7 <boot_alloc+0x8c>
		nextfree = ROUNDUP((char*)nextfree, PGSIZE);
		if(PADDR(nextfree) > npages * PGSIZE){
			nextfree = start;
			panic("Run out of memory");
		}
		return start;
f0100bf5:	89 c8                	mov    %ecx,%eax
	}
	else{
		return nextfree;
	}
//	return NULL;
}
f0100bf7:	c9                   	leave  
f0100bf8:	c3                   	ret    

f0100bf9 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100bf9:	55                   	push   %ebp
f0100bfa:	89 e5                	mov    %esp,%ebp
f0100bfc:	57                   	push   %edi
f0100bfd:	56                   	push   %esi
f0100bfe:	53                   	push   %ebx
f0100bff:	83 ec 3c             	sub    $0x3c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c02:	84 c0                	test   %al,%al
f0100c04:	0f 85 7a 02 00 00    	jne    f0100e84 <check_page_free_list+0x28b>
f0100c0a:	e9 87 02 00 00       	jmp    f0100e96 <check_page_free_list+0x29d>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100c0f:	83 ec 04             	sub    $0x4,%esp
f0100c12:	68 10 45 10 f0       	push   $0xf0104510
f0100c17:	68 31 02 00 00       	push   $0x231
f0100c1c:	68 ec 4c 10 f0       	push   $0xf0104cec
f0100c21:	e8 65 f4 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100c26:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100c29:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100c2c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c2f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c32:	89 c2                	mov    %eax,%edx
f0100c34:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100c3a:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100c40:	0f 95 c2             	setne  %dl
f0100c43:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100c46:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100c4a:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100c4c:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c50:	8b 00                	mov    (%eax),%eax
f0100c52:	85 c0                	test   %eax,%eax
f0100c54:	75 dc                	jne    f0100c32 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100c56:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c59:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100c5f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c62:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c65:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100c67:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100c6a:	a3 5c 85 11 f0       	mov    %eax,0xf011855c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c6f:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c74:	8b 1d 5c 85 11 f0    	mov    0xf011855c,%ebx
f0100c7a:	eb 53                	jmp    f0100ccf <check_page_free_list+0xd6>
f0100c7c:	89 d8                	mov    %ebx,%eax
f0100c7e:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0100c84:	c1 f8 03             	sar    $0x3,%eax
f0100c87:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100c8a:	89 c2                	mov    %eax,%edx
f0100c8c:	c1 ea 16             	shr    $0x16,%edx
f0100c8f:	39 f2                	cmp    %esi,%edx
f0100c91:	73 3a                	jae    f0100ccd <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c93:	89 c2                	mov    %eax,%edx
f0100c95:	c1 ea 0c             	shr    $0xc,%edx
f0100c98:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f0100c9e:	72 12                	jb     f0100cb2 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ca0:	50                   	push   %eax
f0100ca1:	68 c8 44 10 f0       	push   $0xf01044c8
f0100ca6:	6a 51                	push   $0x51
f0100ca8:	68 0a 4d 10 f0       	push   $0xf0104d0a
f0100cad:	e8 d9 f3 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100cb2:	83 ec 04             	sub    $0x4,%esp
f0100cb5:	68 80 00 00 00       	push   $0x80
f0100cba:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100cbf:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100cc4:	50                   	push   %eax
f0100cc5:	e8 45 2b 00 00       	call   f010380f <memset>
f0100cca:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ccd:	8b 1b                	mov    (%ebx),%ebx
f0100ccf:	85 db                	test   %ebx,%ebx
f0100cd1:	75 a9                	jne    f0100c7c <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100cd3:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cd8:	e8 8e fe ff ff       	call   f0100b6b <boot_alloc>
f0100cdd:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ce0:	8b 15 5c 85 11 f0    	mov    0xf011855c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ce6:	8b 0d 8c 89 11 f0    	mov    0xf011898c,%ecx
		assert(pp < pages + npages);
f0100cec:	a1 84 89 11 f0       	mov    0xf0118984,%eax
f0100cf1:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100cf4:	8d 1c c1             	lea    (%ecx,%eax,8),%ebx
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100cf7:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100cfa:	be 00 00 00 00       	mov    $0x0,%esi
f0100cff:	bf 00 00 00 00       	mov    $0x0,%edi
f0100d04:	89 75 cc             	mov    %esi,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d07:	e9 33 01 00 00       	jmp    f0100e3f <check_page_free_list+0x246>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100d0c:	39 ca                	cmp    %ecx,%edx
f0100d0e:	73 19                	jae    f0100d29 <check_page_free_list+0x130>
f0100d10:	68 18 4d 10 f0       	push   $0xf0104d18
f0100d15:	68 24 4d 10 f0       	push   $0xf0104d24
f0100d1a:	68 4b 02 00 00       	push   $0x24b
f0100d1f:	68 ec 4c 10 f0       	push   $0xf0104cec
f0100d24:	e8 62 f3 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100d29:	39 da                	cmp    %ebx,%edx
f0100d2b:	72 19                	jb     f0100d46 <check_page_free_list+0x14d>
f0100d2d:	68 39 4d 10 f0       	push   $0xf0104d39
f0100d32:	68 24 4d 10 f0       	push   $0xf0104d24
f0100d37:	68 4c 02 00 00       	push   $0x24c
f0100d3c:	68 ec 4c 10 f0       	push   $0xf0104cec
f0100d41:	e8 45 f3 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d46:	89 d0                	mov    %edx,%eax
f0100d48:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100d4b:	a8 07                	test   $0x7,%al
f0100d4d:	74 19                	je     f0100d68 <check_page_free_list+0x16f>
f0100d4f:	68 34 45 10 f0       	push   $0xf0104534
f0100d54:	68 24 4d 10 f0       	push   $0xf0104d24
f0100d59:	68 4d 02 00 00       	push   $0x24d
f0100d5e:	68 ec 4c 10 f0       	push   $0xf0104cec
f0100d63:	e8 23 f3 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d68:	c1 f8 03             	sar    $0x3,%eax
f0100d6b:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100d6e:	85 c0                	test   %eax,%eax
f0100d70:	75 19                	jne    f0100d8b <check_page_free_list+0x192>
f0100d72:	68 4d 4d 10 f0       	push   $0xf0104d4d
f0100d77:	68 24 4d 10 f0       	push   $0xf0104d24
f0100d7c:	68 50 02 00 00       	push   $0x250
f0100d81:	68 ec 4c 10 f0       	push   $0xf0104cec
f0100d86:	e8 00 f3 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d8b:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100d90:	75 19                	jne    f0100dab <check_page_free_list+0x1b2>
f0100d92:	68 5e 4d 10 f0       	push   $0xf0104d5e
f0100d97:	68 24 4d 10 f0       	push   $0xf0104d24
f0100d9c:	68 51 02 00 00       	push   $0x251
f0100da1:	68 ec 4c 10 f0       	push   $0xf0104cec
f0100da6:	e8 e0 f2 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100dab:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100db0:	75 19                	jne    f0100dcb <check_page_free_list+0x1d2>
f0100db2:	68 68 45 10 f0       	push   $0xf0104568
f0100db7:	68 24 4d 10 f0       	push   $0xf0104d24
f0100dbc:	68 52 02 00 00       	push   $0x252
f0100dc1:	68 ec 4c 10 f0       	push   $0xf0104cec
f0100dc6:	e8 c0 f2 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100dcb:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100dd0:	75 19                	jne    f0100deb <check_page_free_list+0x1f2>
f0100dd2:	68 77 4d 10 f0       	push   $0xf0104d77
f0100dd7:	68 24 4d 10 f0       	push   $0xf0104d24
f0100ddc:	68 53 02 00 00       	push   $0x253
f0100de1:	68 ec 4c 10 f0       	push   $0xf0104cec
f0100de6:	e8 a0 f2 ff ff       	call   f010008b <_panic>
f0100deb:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100dee:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100df3:	76 3f                	jbe    f0100e34 <check_page_free_list+0x23b>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100df5:	89 c6                	mov    %eax,%esi
f0100df7:	c1 ee 0c             	shr    $0xc,%esi
f0100dfa:	39 75 c4             	cmp    %esi,-0x3c(%ebp)
f0100dfd:	77 12                	ja     f0100e11 <check_page_free_list+0x218>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dff:	50                   	push   %eax
f0100e00:	68 c8 44 10 f0       	push   $0xf01044c8
f0100e05:	6a 51                	push   $0x51
f0100e07:	68 0a 4d 10 f0       	push   $0xf0104d0a
f0100e0c:	e8 7a f2 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0100e11:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e16:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100e19:	76 1e                	jbe    f0100e39 <check_page_free_list+0x240>
f0100e1b:	68 8c 45 10 f0       	push   $0xf010458c
f0100e20:	68 24 4d 10 f0       	push   $0xf0104d24
f0100e25:	68 54 02 00 00       	push   $0x254
f0100e2a:	68 ec 4c 10 f0       	push   $0xf0104cec
f0100e2f:	e8 57 f2 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100e34:	83 c7 01             	add    $0x1,%edi
f0100e37:	eb 04                	jmp    f0100e3d <check_page_free_list+0x244>
		else
			++nfree_extmem;
f0100e39:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100e3d:	8b 12                	mov    (%edx),%edx
f0100e3f:	85 d2                	test   %edx,%edx
f0100e41:	0f 85 c5 fe ff ff    	jne    f0100d0c <check_page_free_list+0x113>
f0100e47:	8b 75 cc             	mov    -0x34(%ebp),%esi
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100e4a:	85 ff                	test   %edi,%edi
f0100e4c:	7f 19                	jg     f0100e67 <check_page_free_list+0x26e>
f0100e4e:	68 91 4d 10 f0       	push   $0xf0104d91
f0100e53:	68 24 4d 10 f0       	push   $0xf0104d24
f0100e58:	68 5c 02 00 00       	push   $0x25c
f0100e5d:	68 ec 4c 10 f0       	push   $0xf0104cec
f0100e62:	e8 24 f2 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100e67:	85 f6                	test   %esi,%esi
f0100e69:	7f 42                	jg     f0100ead <check_page_free_list+0x2b4>
f0100e6b:	68 a3 4d 10 f0       	push   $0xf0104da3
f0100e70:	68 24 4d 10 f0       	push   $0xf0104d24
f0100e75:	68 5d 02 00 00       	push   $0x25d
f0100e7a:	68 ec 4c 10 f0       	push   $0xf0104cec
f0100e7f:	e8 07 f2 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100e84:	a1 5c 85 11 f0       	mov    0xf011855c,%eax
f0100e89:	85 c0                	test   %eax,%eax
f0100e8b:	0f 85 95 fd ff ff    	jne    f0100c26 <check_page_free_list+0x2d>
f0100e91:	e9 79 fd ff ff       	jmp    f0100c0f <check_page_free_list+0x16>
f0100e96:	83 3d 5c 85 11 f0 00 	cmpl   $0x0,0xf011855c
f0100e9d:	0f 84 6c fd ff ff    	je     f0100c0f <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ea3:	be 00 04 00 00       	mov    $0x400,%esi
f0100ea8:	e9 c7 fd ff ff       	jmp    f0100c74 <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100ead:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100eb0:	5b                   	pop    %ebx
f0100eb1:	5e                   	pop    %esi
f0100eb2:	5f                   	pop    %edi
f0100eb3:	5d                   	pop    %ebp
f0100eb4:	c3                   	ret    

f0100eb5 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100eb5:	55                   	push   %ebp
f0100eb6:	89 e5                	mov    %esp,%ebp
f0100eb8:	57                   	push   %edi
f0100eb9:	56                   	push   %esi
f0100eba:	53                   	push   %ebx
f0100ebb:	83 ec 0c             	sub    $0xc,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 1; i < npages; i++) {
f0100ebe:	be 01 00 00 00       	mov    $0x1,%esi
f0100ec3:	eb 68                	jmp    f0100f2d <page_init+0x78>
f0100ec5:	8d 1c f5 00 00 00 00 	lea    0x0(,%esi,8),%ebx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ecc:	89 df                	mov    %ebx,%edi
f0100ece:	c1 e7 09             	shl    $0x9,%edi
		if(page2pa(&pages[i]) >= IOPHYSMEM && page2pa(&pages[i]) < PADDR(boot_alloc(0))) continue;
f0100ed1:	81 ff ff ff 09 00    	cmp    $0x9ffff,%edi
f0100ed7:	76 2f                	jbe    f0100f08 <page_init+0x53>
f0100ed9:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ede:	e8 88 fc ff ff       	call   f0100b6b <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100ee3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100ee8:	77 15                	ja     f0100eff <page_init+0x4a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100eea:	50                   	push   %eax
f0100eeb:	68 ec 44 10 f0       	push   $0xf01044ec
f0100ef0:	68 23 01 00 00       	push   $0x123
f0100ef5:	68 ec 4c 10 f0       	push   $0xf0104cec
f0100efa:	e8 8c f1 ff ff       	call   f010008b <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100eff:	05 00 00 00 10       	add    $0x10000000,%eax
f0100f04:	39 c7                	cmp    %eax,%edi
f0100f06:	72 22                	jb     f0100f2a <page_init+0x75>
		pages[i].pp_ref = 0;
f0100f08:	89 d8                	mov    %ebx,%eax
f0100f0a:	03 05 8c 89 11 f0    	add    0xf011898c,%eax
f0100f10:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
		pages[i].pp_link = page_free_list;
f0100f16:	8b 15 5c 85 11 f0    	mov    0xf011855c,%edx
f0100f1c:	89 10                	mov    %edx,(%eax)
		page_free_list = &pages[i];
f0100f1e:	03 1d 8c 89 11 f0    	add    0xf011898c,%ebx
f0100f24:	89 1d 5c 85 11 f0    	mov    %ebx,0xf011855c
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 1; i < npages; i++) {
f0100f2a:	83 c6 01             	add    $0x1,%esi
f0100f2d:	3b 35 84 89 11 f0    	cmp    0xf0118984,%esi
f0100f33:	72 90                	jb     f0100ec5 <page_init+0x10>
		if(page2pa(&pages[i]) >= IOPHYSMEM && page2pa(&pages[i]) < PADDR(boot_alloc(0))) continue;
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0100f35:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f38:	5b                   	pop    %ebx
f0100f39:	5e                   	pop    %esi
f0100f3a:	5f                   	pop    %edi
f0100f3b:	5d                   	pop    %ebp
f0100f3c:	c3                   	ret    

f0100f3d <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100f3d:	55                   	push   %ebp
f0100f3e:	89 e5                	mov    %esp,%ebp
f0100f40:	53                   	push   %ebx
f0100f41:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	if(page_free_list == NULL) return NULL; //out of memory
f0100f44:	8b 1d 5c 85 11 f0    	mov    0xf011855c,%ebx
f0100f4a:	85 db                	test   %ebx,%ebx
f0100f4c:	74 58                	je     f0100fa6 <page_alloc+0x69>
	struct PageInfo *ret = page_free_list; //fetch the head of the page list
	page_free_list = page_free_list->pp_link;
f0100f4e:	8b 03                	mov    (%ebx),%eax
f0100f50:	a3 5c 85 11 f0       	mov    %eax,0xf011855c
	if(alloc_flags && ALLOC_ZERO){
f0100f55:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100f59:	74 45                	je     f0100fa0 <page_alloc+0x63>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f5b:	89 d8                	mov    %ebx,%eax
f0100f5d:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0100f63:	c1 f8 03             	sar    $0x3,%eax
f0100f66:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f69:	89 c2                	mov    %eax,%edx
f0100f6b:	c1 ea 0c             	shr    $0xc,%edx
f0100f6e:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f0100f74:	72 12                	jb     f0100f88 <page_alloc+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f76:	50                   	push   %eax
f0100f77:	68 c8 44 10 f0       	push   $0xf01044c8
f0100f7c:	6a 51                	push   $0x51
f0100f7e:	68 0a 4d 10 f0       	push   $0xf0104d0a
f0100f83:	e8 03 f1 ff ff       	call   f010008b <_panic>
		memset(page2kva(ret), '\0', PGSIZE);
f0100f88:	83 ec 04             	sub    $0x4,%esp
f0100f8b:	68 00 10 00 00       	push   $0x1000
f0100f90:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0100f92:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f97:	50                   	push   %eax
f0100f98:	e8 72 28 00 00       	call   f010380f <memset>
f0100f9d:	83 c4 10             	add    $0x10,%esp
	}
	//avoid double free error
	ret->pp_link = NULL;
f0100fa0:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	return ret;	
}
f0100fa6:	89 d8                	mov    %ebx,%eax
f0100fa8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fab:	c9                   	leave  
f0100fac:	c3                   	ret    

f0100fad <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100fad:	55                   	push   %ebp
f0100fae:	89 e5                	mov    %esp,%ebp
f0100fb0:	83 ec 08             	sub    $0x8,%esp
f0100fb3:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if(pp->pp_ref != 0 || pp->pp_link != NULL){
f0100fb6:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100fbb:	75 05                	jne    f0100fc2 <page_free+0x15>
f0100fbd:	83 38 00             	cmpl   $0x0,(%eax)
f0100fc0:	74 17                	je     f0100fd9 <page_free+0x2c>
		panic("free an occupied page, or its next is not NULL");
f0100fc2:	83 ec 04             	sub    $0x4,%esp
f0100fc5:	68 d4 45 10 f0       	push   $0xf01045d4
f0100fca:	68 50 01 00 00       	push   $0x150
f0100fcf:	68 ec 4c 10 f0       	push   $0xf0104cec
f0100fd4:	e8 b2 f0 ff ff       	call   f010008b <_panic>
	}
	pp->pp_ref = 0;
f0100fd9:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
	struct PageInfo* tmp = page_free_list;
f0100fdf:	8b 15 5c 85 11 f0    	mov    0xf011855c,%edx
	page_free_list = pp;
f0100fe5:	a3 5c 85 11 f0       	mov    %eax,0xf011855c
	pp->pp_link = tmp;
f0100fea:	89 10                	mov    %edx,(%eax)
}
f0100fec:	c9                   	leave  
f0100fed:	c3                   	ret    

f0100fee <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100fee:	55                   	push   %ebp
f0100fef:	89 e5                	mov    %esp,%ebp
f0100ff1:	83 ec 08             	sub    $0x8,%esp
f0100ff4:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100ff7:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100ffb:	83 e8 01             	sub    $0x1,%eax
f0100ffe:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101002:	66 85 c0             	test   %ax,%ax
f0101005:	75 0c                	jne    f0101013 <page_decref+0x25>
		page_free(pp);
f0101007:	83 ec 0c             	sub    $0xc,%esp
f010100a:	52                   	push   %edx
f010100b:	e8 9d ff ff ff       	call   f0100fad <page_free>
f0101010:	83 c4 10             	add    $0x10,%esp
}
f0101013:	c9                   	leave  
f0101014:	c3                   	ret    

f0101015 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101015:	55                   	push   %ebp
f0101016:	89 e5                	mov    %esp,%ebp
f0101018:	56                   	push   %esi
f0101019:	53                   	push   %ebx
f010101a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	int dirIndex = PDX(va), tabIndex = PTX(va);
f010101d:	89 de                	mov    %ebx,%esi
f010101f:	c1 ee 0c             	shr    $0xc,%esi
f0101022:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0101028:	c1 eb 16             	shr    $0x16,%ebx
 	pde_t *pde_my = pgdir + dirIndex;
f010102b:	c1 e3 02             	shl    $0x2,%ebx
f010102e:	03 5d 08             	add    0x8(%ebp),%ebx
	if(!((*pde_my) & PTE_P)){
f0101031:	f6 03 01             	testb  $0x1,(%ebx)
f0101034:	75 2d                	jne    f0101063 <pgdir_walk+0x4e>
		//if page directory entry for virtual address va is not present
		if(create){
f0101036:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010103a:	74 59                	je     f0101095 <pgdir_walk+0x80>
			//ALLOC_ZERO parameter clears the allocated page by default
			struct PageInfo *newpage = page_alloc(ALLOC_ZERO);
f010103c:	83 ec 0c             	sub    $0xc,%esp
f010103f:	6a 01                	push   $0x1
f0101041:	e8 f7 fe ff ff       	call   f0100f3d <page_alloc>
			if(newpage == NULL){
f0101046:	83 c4 10             	add    $0x10,%esp
f0101049:	85 c0                	test   %eax,%eax
f010104b:	74 4f                	je     f010109c <pgdir_walk+0x87>
				return NULL;
			}
			newpage->pp_ref++;
f010104d:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101052:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0101058:	c1 f8 03             	sar    $0x3,%eax
f010105b:	c1 e0 0c             	shl    $0xc,%eax
			pgdir[dirIndex] = page2pa(newpage) | PTE_P | PTE_U | PTE_W;
f010105e:	83 c8 07             	or     $0x7,%eax
f0101061:	89 03                	mov    %eax,(%ebx)
		else{
			return NULL;
		}
	}
	
	pte_t *retadd = (pte_t*)KADDR(PTE_ADDR(*pde_my));
f0101063:	8b 03                	mov    (%ebx),%eax
f0101065:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010106a:	89 c2                	mov    %eax,%edx
f010106c:	c1 ea 0c             	shr    $0xc,%edx
f010106f:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f0101075:	72 15                	jb     f010108c <pgdir_walk+0x77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101077:	50                   	push   %eax
f0101078:	68 c8 44 10 f0       	push   $0xf01044c8
f010107d:	68 8f 01 00 00       	push   $0x18f
f0101082:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101087:	e8 ff ef ff ff       	call   f010008b <_panic>
	return (pte_t*)(retadd + tabIndex);
f010108c:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0101093:	eb 0c                	jmp    f01010a1 <pgdir_walk+0x8c>
			}
			newpage->pp_ref++;
			pgdir[dirIndex] = page2pa(newpage) | PTE_P | PTE_U | PTE_W;
		}
		else{
			return NULL;
f0101095:	b8 00 00 00 00       	mov    $0x0,%eax
f010109a:	eb 05                	jmp    f01010a1 <pgdir_walk+0x8c>
		//if page directory entry for virtual address va is not present
		if(create){
			//ALLOC_ZERO parameter clears the allocated page by default
			struct PageInfo *newpage = page_alloc(ALLOC_ZERO);
			if(newpage == NULL){
				return NULL;
f010109c:	b8 00 00 00 00       	mov    $0x0,%eax
	}
	
	pte_t *retadd = (pte_t*)KADDR(PTE_ADDR(*pde_my));
	return (pte_t*)(retadd + tabIndex);
	return NULL;
}
f01010a1:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01010a4:	5b                   	pop    %ebx
f01010a5:	5e                   	pop    %esi
f01010a6:	5d                   	pop    %ebp
f01010a7:	c3                   	ret    

f01010a8 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01010a8:	55                   	push   %ebp
f01010a9:	89 e5                	mov    %esp,%ebp
f01010ab:	57                   	push   %edi
f01010ac:	56                   	push   %esi
f01010ad:	53                   	push   %ebx
f01010ae:	83 ec 1c             	sub    $0x1c,%esp
f01010b1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01010b4:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	int cnt;
	for(cnt = 0; cnt < size/PGSIZE; cnt++){
f01010b7:	c1 e9 0c             	shr    $0xc,%ecx
f01010ba:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01010bd:	89 c3                	mov    %eax,%ebx
f01010bf:	be 00 00 00 00       	mov    $0x0,%esi
f01010c4:	89 d7                	mov    %edx,%edi
f01010c6:	29 c7                	sub    %eax,%edi
f01010c8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010cb:	83 c8 01             	or     $0x1,%eax
f01010ce:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01010d1:	eb 3f                	jmp    f0101112 <boot_map_region+0x6a>
		pte_t* pte_entry_my = pgdir_walk(pgdir, (void*)va, 1);
f01010d3:	83 ec 04             	sub    $0x4,%esp
f01010d6:	6a 01                	push   $0x1
f01010d8:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f01010db:	50                   	push   %eax
f01010dc:	ff 75 e0             	pushl  -0x20(%ebp)
f01010df:	e8 31 ff ff ff       	call   f0101015 <pgdir_walk>
		if(!pte_entry_my){
f01010e4:	83 c4 10             	add    $0x10,%esp
f01010e7:	85 c0                	test   %eax,%eax
f01010e9:	75 17                	jne    f0101102 <boot_map_region+0x5a>
			panic("Get page table entry for va in pgdir failed!");
f01010eb:	83 ec 04             	sub    $0x4,%esp
f01010ee:	68 04 46 10 f0       	push   $0xf0104604
f01010f3:	68 a7 01 00 00       	push   $0x1a7
f01010f8:	68 ec 4c 10 f0       	push   $0xf0104cec
f01010fd:	e8 89 ef ff ff       	call   f010008b <_panic>
		}
		*(pte_entry_my) = pa | perm | PTE_P;
f0101102:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101105:	09 da                	or     %ebx,%edx
f0101107:	89 10                	mov    %edx,(%eax)
		va += PGSIZE;
		pa += PGSIZE;
f0101109:	81 c3 00 10 00 00    	add    $0x1000,%ebx
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	int cnt;
	for(cnt = 0; cnt < size/PGSIZE; cnt++){
f010110f:	83 c6 01             	add    $0x1,%esi
f0101112:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0101115:	75 bc                	jne    f01010d3 <boot_map_region+0x2b>
		}
		*(pte_entry_my) = pa | perm | PTE_P;
		va += PGSIZE;
		pa += PGSIZE;
	}
}
f0101117:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010111a:	5b                   	pop    %ebx
f010111b:	5e                   	pop    %esi
f010111c:	5f                   	pop    %edi
f010111d:	5d                   	pop    %ebp
f010111e:	c3                   	ret    

f010111f <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f010111f:	55                   	push   %ebp
f0101120:	89 e5                	mov    %esp,%ebp
f0101122:	53                   	push   %ebx
f0101123:	83 ec 08             	sub    $0x8,%esp
f0101126:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t* pte_my = pgdir_walk(pgdir, va, 0); //test if the page is present
f0101129:	6a 00                	push   $0x0
f010112b:	ff 75 0c             	pushl  0xc(%ebp)
f010112e:	ff 75 08             	pushl  0x8(%ebp)
f0101131:	e8 df fe ff ff       	call   f0101015 <pgdir_walk>
	if((!pte_my) || (!((*pte_my) & PTE_P))){
f0101136:	83 c4 10             	add    $0x10,%esp
f0101139:	85 c0                	test   %eax,%eax
f010113b:	74 37                	je     f0101174 <page_lookup+0x55>
f010113d:	f6 00 01             	testb  $0x1,(%eax)
f0101140:	74 39                	je     f010117b <page_lookup+0x5c>
		return NULL;
	}
	if(pte_store != NULL){
f0101142:	85 db                	test   %ebx,%ebx
f0101144:	74 02                	je     f0101148 <page_lookup+0x29>
		*pte_store = pte_my;
f0101146:	89 03                	mov    %eax,(%ebx)
	}
	return pa2page(PTE_ADDR(*pte_my));
f0101148:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010114a:	c1 e8 0c             	shr    $0xc,%eax
f010114d:	3b 05 84 89 11 f0    	cmp    0xf0118984,%eax
f0101153:	72 14                	jb     f0101169 <page_lookup+0x4a>
		panic("pa2page called with invalid pa");
f0101155:	83 ec 04             	sub    $0x4,%esp
f0101158:	68 34 46 10 f0       	push   $0xf0104634
f010115d:	6a 4a                	push   $0x4a
f010115f:	68 0a 4d 10 f0       	push   $0xf0104d0a
f0101164:	e8 22 ef ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0101169:	8b 15 8c 89 11 f0    	mov    0xf011898c,%edx
f010116f:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0101172:	eb 0c                	jmp    f0101180 <page_lookup+0x61>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t* pte_my = pgdir_walk(pgdir, va, 0); //test if the page is present
	if((!pte_my) || (!((*pte_my) & PTE_P))){
		return NULL;
f0101174:	b8 00 00 00 00       	mov    $0x0,%eax
f0101179:	eb 05                	jmp    f0101180 <page_lookup+0x61>
f010117b:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store != NULL){
		*pte_store = pte_my;
	}
	return pa2page(PTE_ADDR(*pte_my));
	return NULL;
}
f0101180:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101183:	c9                   	leave  
f0101184:	c3                   	ret    

f0101185 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101185:	55                   	push   %ebp
f0101186:	89 e5                	mov    %esp,%ebp
f0101188:	53                   	push   %ebx
f0101189:	83 ec 18             	sub    $0x18,%esp
f010118c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
/*	pte_t *pte_my = pgdir_walk(pgdir, va, 0); //do not allocate new page entry
 	if((pte_my == NULL) || (!(*pte_my & PTE_P))){
		return ;
	}*/
	pte_t *recpte_my = NULL;
f010118f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo* destPagePtr= page_lookup(pgdir, va, &recpte_my);
f0101196:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101199:	50                   	push   %eax
f010119a:	53                   	push   %ebx
f010119b:	ff 75 08             	pushl  0x8(%ebp)
f010119e:	e8 7c ff ff ff       	call   f010111f <page_lookup>
	if(destPagePtr == NULL || (!(*recpte_my) & PTE_P)){//no physical page at that address
f01011a3:	83 c4 10             	add    $0x10,%esp
f01011a6:	85 c0                	test   %eax,%eax
f01011a8:	74 20                	je     f01011ca <page_remove+0x45>
f01011aa:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01011ad:	83 3a 00             	cmpl   $0x0,(%edx)
f01011b0:	74 18                	je     f01011ca <page_remove+0x45>
		return;
	}
	page_decref(destPagePtr);
f01011b2:	83 ec 0c             	sub    $0xc,%esp
f01011b5:	50                   	push   %eax
f01011b6:	e8 33 fe ff ff       	call   f0100fee <page_decref>
	*recpte_my = 0;
f01011bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011be:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01011c4:	0f 01 3b             	invlpg (%ebx)
f01011c7:	83 c4 10             	add    $0x10,%esp
	tlb_invalidate(pgdir, va);	
	
}
f01011ca:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01011cd:	c9                   	leave  
f01011ce:	c3                   	ret    

f01011cf <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01011cf:	55                   	push   %ebp
f01011d0:	89 e5                	mov    %esp,%ebp
f01011d2:	57                   	push   %edi
f01011d3:	56                   	push   %esi
f01011d4:	53                   	push   %ebx
f01011d5:	83 ec 10             	sub    $0x10,%esp
f01011d8:	8b 75 0c             	mov    0xc(%ebp),%esi
f01011db:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t* pte_my = pgdir_walk(pgdir, va, 1);//create a page table entry on demand
f01011de:	6a 01                	push   $0x1
f01011e0:	57                   	push   %edi
f01011e1:	ff 75 08             	pushl  0x8(%ebp)
f01011e4:	e8 2c fe ff ff       	call   f0101015 <pgdir_walk>
f01011e9:	89 c3                	mov    %eax,%ebx
	if(!pte_my){
f01011eb:	83 c4 10             	add    $0x10,%esp
f01011ee:	85 c0                	test   %eax,%eax
f01011f0:	74 38                	je     f010122a <page_insert+0x5b>
		return 	-E_NO_MEM;
	}
	pp->pp_ref++;
f01011f2:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	if(*pte_my & PTE_P){
f01011f7:	f6 00 01             	testb  $0x1,(%eax)
f01011fa:	74 0f                	je     f010120b <page_insert+0x3c>
		page_remove(pgdir, va);
f01011fc:	83 ec 08             	sub    $0x8,%esp
f01011ff:	57                   	push   %edi
f0101200:	ff 75 08             	pushl  0x8(%ebp)
f0101203:	e8 7d ff ff ff       	call   f0101185 <page_remove>
f0101208:	83 c4 10             	add    $0x10,%esp
f010120b:	8b 55 14             	mov    0x14(%ebp),%edx
f010120e:	83 ca 01             	or     $0x1,%edx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101211:	89 f0                	mov    %esi,%eax
f0101213:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0101219:	c1 f8 03             	sar    $0x3,%eax
f010121c:	c1 e0 0c             	shl    $0xc,%eax
	}
	*pte_my = page2pa(pp) | perm | PTE_P; 
f010121f:	09 d0                	or     %edx,%eax
f0101221:	89 03                	mov    %eax,(%ebx)
	return 0;
f0101223:	b8 00 00 00 00       	mov    $0x0,%eax
f0101228:	eb 05                	jmp    f010122f <page_insert+0x60>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
	pte_t* pte_my = pgdir_walk(pgdir, va, 1);//create a page table entry on demand
	if(!pte_my){
		return 	-E_NO_MEM;
f010122a:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	if(*pte_my & PTE_P){
		page_remove(pgdir, va);
	}
	*pte_my = page2pa(pp) | perm | PTE_P; 
	return 0;
}
f010122f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101232:	5b                   	pop    %ebx
f0101233:	5e                   	pop    %esi
f0101234:	5f                   	pop    %edi
f0101235:	5d                   	pop    %ebp
f0101236:	c3                   	ret    

f0101237 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101237:	55                   	push   %ebp
f0101238:	89 e5                	mov    %esp,%ebp
f010123a:	57                   	push   %edi
f010123b:	56                   	push   %esi
f010123c:	53                   	push   %ebx
f010123d:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101240:	6a 15                	push   $0x15
f0101242:	e8 a9 17 00 00       	call   f01029f0 <mc146818_read>
f0101247:	89 c3                	mov    %eax,%ebx
f0101249:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101250:	e8 9b 17 00 00       	call   f01029f0 <mc146818_read>
f0101255:	c1 e0 08             	shl    $0x8,%eax
f0101258:	09 d8                	or     %ebx,%eax
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f010125a:	c1 e0 0a             	shl    $0xa,%eax
f010125d:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101263:	85 c0                	test   %eax,%eax
f0101265:	0f 48 c2             	cmovs  %edx,%eax
f0101268:	c1 f8 0c             	sar    $0xc,%eax
f010126b:	a3 64 85 11 f0       	mov    %eax,0xf0118564
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101270:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101277:	e8 74 17 00 00       	call   f01029f0 <mc146818_read>
f010127c:	89 c6                	mov    %eax,%esi
f010127e:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101285:	e8 66 17 00 00       	call   f01029f0 <mc146818_read>
f010128a:	c1 e0 08             	shl    $0x8,%eax
f010128d:	89 c3                	mov    %eax,%ebx
f010128f:	09 f3                	or     %esi,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101291:	c1 e3 0a             	shl    $0xa,%ebx
f0101294:	8d 93 ff 0f 00 00    	lea    0xfff(%ebx),%edx
f010129a:	83 c4 0c             	add    $0xc,%esp
f010129d:	85 db                	test   %ebx,%ebx
f010129f:	0f 48 da             	cmovs  %edx,%ebx
f01012a2:	c1 fb 0c             	sar    $0xc,%ebx
	cprintf("npages_basemem: %d\t npages_extmem: %d\n", npages_basemem, npages_extmem);
f01012a5:	53                   	push   %ebx
f01012a6:	ff 35 64 85 11 f0    	pushl  0xf0118564
f01012ac:	68 54 46 10 f0       	push   $0xf0104654
f01012b1:	e8 9b 17 00 00       	call   f0102a51 <cprintf>

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01012b6:	83 c4 10             	add    $0x10,%esp
f01012b9:	85 db                	test   %ebx,%ebx
f01012bb:	74 0d                	je     f01012ca <mem_init+0x93>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01012bd:	8d 83 00 01 00 00    	lea    0x100(%ebx),%eax
f01012c3:	a3 84 89 11 f0       	mov    %eax,0xf0118984
f01012c8:	eb 0a                	jmp    f01012d4 <mem_init+0x9d>
	else
		npages = npages_basemem;
f01012ca:	a1 64 85 11 f0       	mov    0xf0118564,%eax
f01012cf:	a3 84 89 11 f0       	mov    %eax,0xf0118984

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f01012d4:	c1 e3 0c             	shl    $0xc,%ebx
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012d7:	c1 eb 0a             	shr    $0xa,%ebx
f01012da:	53                   	push   %ebx
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f01012db:	a1 64 85 11 f0       	mov    0xf0118564,%eax
f01012e0:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012e3:	c1 e8 0a             	shr    $0xa,%eax
f01012e6:	50                   	push   %eax
		npages * PGSIZE / 1024,
f01012e7:	a1 84 89 11 f0       	mov    0xf0118984,%eax
f01012ec:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012ef:	c1 e8 0a             	shr    $0xa,%eax
f01012f2:	50                   	push   %eax
f01012f3:	68 7c 46 10 f0       	push   $0xf010467c
f01012f8:	e8 54 17 00 00       	call   f0102a51 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01012fd:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101302:	e8 64 f8 ff ff       	call   f0100b6b <boot_alloc>
f0101307:	a3 88 89 11 f0       	mov    %eax,0xf0118988
	memset(kern_pgdir, 0, PGSIZE);
f010130c:	83 c4 0c             	add    $0xc,%esp
f010130f:	68 00 10 00 00       	push   $0x1000
f0101314:	6a 00                	push   $0x0
f0101316:	50                   	push   %eax
f0101317:	e8 f3 24 00 00       	call   f010380f <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010131c:	a1 88 89 11 f0       	mov    0xf0118988,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101321:	83 c4 10             	add    $0x10,%esp
f0101324:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101329:	77 15                	ja     f0101340 <mem_init+0x109>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010132b:	50                   	push   %eax
f010132c:	68 ec 44 10 f0       	push   $0xf01044ec
f0101331:	68 98 00 00 00       	push   $0x98
f0101336:	68 ec 4c 10 f0       	push   $0xf0104cec
f010133b:	e8 4b ed ff ff       	call   f010008b <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101340:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101346:	83 ca 05             	or     $0x5,%edx
f0101349:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	cprintf("UVPT is %x\n" ,UVPT);
f010134f:	83 ec 08             	sub    $0x8,%esp
f0101352:	68 00 00 40 ef       	push   $0xef400000
f0101357:	68 b4 4d 10 f0       	push   $0xf0104db4
f010135c:	e8 f0 16 00 00       	call   f0102a51 <cprintf>
	cprintf("UPAGES is %x\n", UPAGES);
f0101361:	83 c4 08             	add    $0x8,%esp
f0101364:	68 00 00 00 ef       	push   $0xef000000
f0101369:	68 c0 4d 10 f0       	push   $0xf0104dc0
f010136e:	e8 de 16 00 00       	call   f0102a51 <cprintf>
	cprintf("Physical address of kern_pgdir: %x\n", PADDR(kern_pgdir));
f0101373:	a1 88 89 11 f0       	mov    0xf0118988,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101378:	83 c4 10             	add    $0x10,%esp
f010137b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101380:	77 15                	ja     f0101397 <mem_init+0x160>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101382:	50                   	push   %eax
f0101383:	68 ec 44 10 f0       	push   $0xf01044ec
f0101388:	68 9b 00 00 00       	push   $0x9b
f010138d:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101392:	e8 f4 ec ff ff       	call   f010008b <_panic>
f0101397:	83 ec 08             	sub    $0x8,%esp
	return (physaddr_t)kva - KERNBASE;
f010139a:	05 00 00 00 10       	add    $0x10000000,%eax
f010139f:	50                   	push   %eax
f01013a0:	68 b8 46 10 f0       	push   $0xf01046b8
f01013a5:	e8 a7 16 00 00       	call   f0102a51 <cprintf>
	cprintf("Virtual address of kern_pgdir: %x\n", kern_pgdir);
f01013aa:	83 c4 08             	add    $0x8,%esp
f01013ad:	ff 35 88 89 11 f0    	pushl  0xf0118988
f01013b3:	68 dc 46 10 f0       	push   $0xf01046dc
f01013b8:	e8 94 16 00 00       	call   f0102a51 <cprintf>
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:

	pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
f01013bd:	a1 84 89 11 f0       	mov    0xf0118984,%eax
f01013c2:	c1 e0 03             	shl    $0x3,%eax
f01013c5:	e8 a1 f7 ff ff       	call   f0100b6b <boot_alloc>
f01013ca:	a3 8c 89 11 f0       	mov    %eax,0xf011898c
	memset(pages, 0, npages*sizeof(struct PageInfo));
f01013cf:	83 c4 0c             	add    $0xc,%esp
f01013d2:	8b 3d 84 89 11 f0    	mov    0xf0118984,%edi
f01013d8:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f01013df:	52                   	push   %edx
f01013e0:	6a 00                	push   $0x0
f01013e2:	50                   	push   %eax
f01013e3:	e8 27 24 00 00       	call   f010380f <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01013e8:	e8 c8 fa ff ff       	call   f0100eb5 <page_init>

	check_page_free_list(1);
f01013ed:	b8 01 00 00 00       	mov    $0x1,%eax
f01013f2:	e8 02 f8 ff ff       	call   f0100bf9 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01013f7:	83 c4 10             	add    $0x10,%esp
f01013fa:	83 3d 8c 89 11 f0 00 	cmpl   $0x0,0xf011898c
f0101401:	75 17                	jne    f010141a <mem_init+0x1e3>
		panic("'pages' is a null pointer!");
f0101403:	83 ec 04             	sub    $0x4,%esp
f0101406:	68 ce 4d 10 f0       	push   $0xf0104dce
f010140b:	68 6e 02 00 00       	push   $0x26e
f0101410:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101415:	e8 71 ec ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010141a:	a1 5c 85 11 f0       	mov    0xf011855c,%eax
f010141f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101424:	eb 05                	jmp    f010142b <mem_init+0x1f4>
		++nfree;
f0101426:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101429:	8b 00                	mov    (%eax),%eax
f010142b:	85 c0                	test   %eax,%eax
f010142d:	75 f7                	jne    f0101426 <mem_init+0x1ef>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010142f:	83 ec 0c             	sub    $0xc,%esp
f0101432:	6a 00                	push   $0x0
f0101434:	e8 04 fb ff ff       	call   f0100f3d <page_alloc>
f0101439:	89 c7                	mov    %eax,%edi
f010143b:	83 c4 10             	add    $0x10,%esp
f010143e:	85 c0                	test   %eax,%eax
f0101440:	75 19                	jne    f010145b <mem_init+0x224>
f0101442:	68 e9 4d 10 f0       	push   $0xf0104de9
f0101447:	68 24 4d 10 f0       	push   $0xf0104d24
f010144c:	68 76 02 00 00       	push   $0x276
f0101451:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101456:	e8 30 ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010145b:	83 ec 0c             	sub    $0xc,%esp
f010145e:	6a 00                	push   $0x0
f0101460:	e8 d8 fa ff ff       	call   f0100f3d <page_alloc>
f0101465:	89 c6                	mov    %eax,%esi
f0101467:	83 c4 10             	add    $0x10,%esp
f010146a:	85 c0                	test   %eax,%eax
f010146c:	75 19                	jne    f0101487 <mem_init+0x250>
f010146e:	68 ff 4d 10 f0       	push   $0xf0104dff
f0101473:	68 24 4d 10 f0       	push   $0xf0104d24
f0101478:	68 77 02 00 00       	push   $0x277
f010147d:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101482:	e8 04 ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101487:	83 ec 0c             	sub    $0xc,%esp
f010148a:	6a 00                	push   $0x0
f010148c:	e8 ac fa ff ff       	call   f0100f3d <page_alloc>
f0101491:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101494:	83 c4 10             	add    $0x10,%esp
f0101497:	85 c0                	test   %eax,%eax
f0101499:	75 19                	jne    f01014b4 <mem_init+0x27d>
f010149b:	68 15 4e 10 f0       	push   $0xf0104e15
f01014a0:	68 24 4d 10 f0       	push   $0xf0104d24
f01014a5:	68 78 02 00 00       	push   $0x278
f01014aa:	68 ec 4c 10 f0       	push   $0xf0104cec
f01014af:	e8 d7 eb ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01014b4:	39 f7                	cmp    %esi,%edi
f01014b6:	75 19                	jne    f01014d1 <mem_init+0x29a>
f01014b8:	68 2b 4e 10 f0       	push   $0xf0104e2b
f01014bd:	68 24 4d 10 f0       	push   $0xf0104d24
f01014c2:	68 7b 02 00 00       	push   $0x27b
f01014c7:	68 ec 4c 10 f0       	push   $0xf0104cec
f01014cc:	e8 ba eb ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014d1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014d4:	39 c7                	cmp    %eax,%edi
f01014d6:	74 04                	je     f01014dc <mem_init+0x2a5>
f01014d8:	39 c6                	cmp    %eax,%esi
f01014da:	75 19                	jne    f01014f5 <mem_init+0x2be>
f01014dc:	68 00 47 10 f0       	push   $0xf0104700
f01014e1:	68 24 4d 10 f0       	push   $0xf0104d24
f01014e6:	68 7c 02 00 00       	push   $0x27c
f01014eb:	68 ec 4c 10 f0       	push   $0xf0104cec
f01014f0:	e8 96 eb ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014f5:	8b 0d 8c 89 11 f0    	mov    0xf011898c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01014fb:	8b 15 84 89 11 f0    	mov    0xf0118984,%edx
f0101501:	c1 e2 0c             	shl    $0xc,%edx
f0101504:	89 f8                	mov    %edi,%eax
f0101506:	29 c8                	sub    %ecx,%eax
f0101508:	c1 f8 03             	sar    $0x3,%eax
f010150b:	c1 e0 0c             	shl    $0xc,%eax
f010150e:	39 d0                	cmp    %edx,%eax
f0101510:	72 19                	jb     f010152b <mem_init+0x2f4>
f0101512:	68 3d 4e 10 f0       	push   $0xf0104e3d
f0101517:	68 24 4d 10 f0       	push   $0xf0104d24
f010151c:	68 7d 02 00 00       	push   $0x27d
f0101521:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101526:	e8 60 eb ff ff       	call   f010008b <_panic>
f010152b:	89 f0                	mov    %esi,%eax
f010152d:	29 c8                	sub    %ecx,%eax
f010152f:	c1 f8 03             	sar    $0x3,%eax
f0101532:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f0101535:	39 c2                	cmp    %eax,%edx
f0101537:	77 19                	ja     f0101552 <mem_init+0x31b>
f0101539:	68 5a 4e 10 f0       	push   $0xf0104e5a
f010153e:	68 24 4d 10 f0       	push   $0xf0104d24
f0101543:	68 7e 02 00 00       	push   $0x27e
f0101548:	68 ec 4c 10 f0       	push   $0xf0104cec
f010154d:	e8 39 eb ff ff       	call   f010008b <_panic>
f0101552:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101555:	29 c8                	sub    %ecx,%eax
f0101557:	c1 f8 03             	sar    $0x3,%eax
f010155a:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f010155d:	39 c2                	cmp    %eax,%edx
f010155f:	77 19                	ja     f010157a <mem_init+0x343>
f0101561:	68 77 4e 10 f0       	push   $0xf0104e77
f0101566:	68 24 4d 10 f0       	push   $0xf0104d24
f010156b:	68 7f 02 00 00       	push   $0x27f
f0101570:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101575:	e8 11 eb ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010157a:	a1 5c 85 11 f0       	mov    0xf011855c,%eax
f010157f:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101582:	c7 05 5c 85 11 f0 00 	movl   $0x0,0xf011855c
f0101589:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010158c:	83 ec 0c             	sub    $0xc,%esp
f010158f:	6a 00                	push   $0x0
f0101591:	e8 a7 f9 ff ff       	call   f0100f3d <page_alloc>
f0101596:	83 c4 10             	add    $0x10,%esp
f0101599:	85 c0                	test   %eax,%eax
f010159b:	74 19                	je     f01015b6 <mem_init+0x37f>
f010159d:	68 94 4e 10 f0       	push   $0xf0104e94
f01015a2:	68 24 4d 10 f0       	push   $0xf0104d24
f01015a7:	68 86 02 00 00       	push   $0x286
f01015ac:	68 ec 4c 10 f0       	push   $0xf0104cec
f01015b1:	e8 d5 ea ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f01015b6:	83 ec 0c             	sub    $0xc,%esp
f01015b9:	57                   	push   %edi
f01015ba:	e8 ee f9 ff ff       	call   f0100fad <page_free>
	page_free(pp1);
f01015bf:	89 34 24             	mov    %esi,(%esp)
f01015c2:	e8 e6 f9 ff ff       	call   f0100fad <page_free>
	page_free(pp2);
f01015c7:	83 c4 04             	add    $0x4,%esp
f01015ca:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015cd:	e8 db f9 ff ff       	call   f0100fad <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015d2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015d9:	e8 5f f9 ff ff       	call   f0100f3d <page_alloc>
f01015de:	89 c6                	mov    %eax,%esi
f01015e0:	83 c4 10             	add    $0x10,%esp
f01015e3:	85 c0                	test   %eax,%eax
f01015e5:	75 19                	jne    f0101600 <mem_init+0x3c9>
f01015e7:	68 e9 4d 10 f0       	push   $0xf0104de9
f01015ec:	68 24 4d 10 f0       	push   $0xf0104d24
f01015f1:	68 8d 02 00 00       	push   $0x28d
f01015f6:	68 ec 4c 10 f0       	push   $0xf0104cec
f01015fb:	e8 8b ea ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101600:	83 ec 0c             	sub    $0xc,%esp
f0101603:	6a 00                	push   $0x0
f0101605:	e8 33 f9 ff ff       	call   f0100f3d <page_alloc>
f010160a:	89 c7                	mov    %eax,%edi
f010160c:	83 c4 10             	add    $0x10,%esp
f010160f:	85 c0                	test   %eax,%eax
f0101611:	75 19                	jne    f010162c <mem_init+0x3f5>
f0101613:	68 ff 4d 10 f0       	push   $0xf0104dff
f0101618:	68 24 4d 10 f0       	push   $0xf0104d24
f010161d:	68 8e 02 00 00       	push   $0x28e
f0101622:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101627:	e8 5f ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010162c:	83 ec 0c             	sub    $0xc,%esp
f010162f:	6a 00                	push   $0x0
f0101631:	e8 07 f9 ff ff       	call   f0100f3d <page_alloc>
f0101636:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101639:	83 c4 10             	add    $0x10,%esp
f010163c:	85 c0                	test   %eax,%eax
f010163e:	75 19                	jne    f0101659 <mem_init+0x422>
f0101640:	68 15 4e 10 f0       	push   $0xf0104e15
f0101645:	68 24 4d 10 f0       	push   $0xf0104d24
f010164a:	68 8f 02 00 00       	push   $0x28f
f010164f:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101654:	e8 32 ea ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101659:	39 fe                	cmp    %edi,%esi
f010165b:	75 19                	jne    f0101676 <mem_init+0x43f>
f010165d:	68 2b 4e 10 f0       	push   $0xf0104e2b
f0101662:	68 24 4d 10 f0       	push   $0xf0104d24
f0101667:	68 91 02 00 00       	push   $0x291
f010166c:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101671:	e8 15 ea ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101676:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101679:	39 c6                	cmp    %eax,%esi
f010167b:	74 04                	je     f0101681 <mem_init+0x44a>
f010167d:	39 c7                	cmp    %eax,%edi
f010167f:	75 19                	jne    f010169a <mem_init+0x463>
f0101681:	68 00 47 10 f0       	push   $0xf0104700
f0101686:	68 24 4d 10 f0       	push   $0xf0104d24
f010168b:	68 92 02 00 00       	push   $0x292
f0101690:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101695:	e8 f1 e9 ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f010169a:	83 ec 0c             	sub    $0xc,%esp
f010169d:	6a 00                	push   $0x0
f010169f:	e8 99 f8 ff ff       	call   f0100f3d <page_alloc>
f01016a4:	83 c4 10             	add    $0x10,%esp
f01016a7:	85 c0                	test   %eax,%eax
f01016a9:	74 19                	je     f01016c4 <mem_init+0x48d>
f01016ab:	68 94 4e 10 f0       	push   $0xf0104e94
f01016b0:	68 24 4d 10 f0       	push   $0xf0104d24
f01016b5:	68 93 02 00 00       	push   $0x293
f01016ba:	68 ec 4c 10 f0       	push   $0xf0104cec
f01016bf:	e8 c7 e9 ff ff       	call   f010008b <_panic>
f01016c4:	89 f0                	mov    %esi,%eax
f01016c6:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f01016cc:	c1 f8 03             	sar    $0x3,%eax
f01016cf:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01016d2:	89 c2                	mov    %eax,%edx
f01016d4:	c1 ea 0c             	shr    $0xc,%edx
f01016d7:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f01016dd:	72 12                	jb     f01016f1 <mem_init+0x4ba>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01016df:	50                   	push   %eax
f01016e0:	68 c8 44 10 f0       	push   $0xf01044c8
f01016e5:	6a 51                	push   $0x51
f01016e7:	68 0a 4d 10 f0       	push   $0xf0104d0a
f01016ec:	e8 9a e9 ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01016f1:	83 ec 04             	sub    $0x4,%esp
f01016f4:	68 00 10 00 00       	push   $0x1000
f01016f9:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f01016fb:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101700:	50                   	push   %eax
f0101701:	e8 09 21 00 00       	call   f010380f <memset>
	page_free(pp0);
f0101706:	89 34 24             	mov    %esi,(%esp)
f0101709:	e8 9f f8 ff ff       	call   f0100fad <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010170e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101715:	e8 23 f8 ff ff       	call   f0100f3d <page_alloc>
f010171a:	83 c4 10             	add    $0x10,%esp
f010171d:	85 c0                	test   %eax,%eax
f010171f:	75 19                	jne    f010173a <mem_init+0x503>
f0101721:	68 a3 4e 10 f0       	push   $0xf0104ea3
f0101726:	68 24 4d 10 f0       	push   $0xf0104d24
f010172b:	68 98 02 00 00       	push   $0x298
f0101730:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101735:	e8 51 e9 ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f010173a:	39 c6                	cmp    %eax,%esi
f010173c:	74 19                	je     f0101757 <mem_init+0x520>
f010173e:	68 c1 4e 10 f0       	push   $0xf0104ec1
f0101743:	68 24 4d 10 f0       	push   $0xf0104d24
f0101748:	68 99 02 00 00       	push   $0x299
f010174d:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101752:	e8 34 e9 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101757:	89 f0                	mov    %esi,%eax
f0101759:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f010175f:	c1 f8 03             	sar    $0x3,%eax
f0101762:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101765:	89 c2                	mov    %eax,%edx
f0101767:	c1 ea 0c             	shr    $0xc,%edx
f010176a:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f0101770:	72 12                	jb     f0101784 <mem_init+0x54d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101772:	50                   	push   %eax
f0101773:	68 c8 44 10 f0       	push   $0xf01044c8
f0101778:	6a 51                	push   $0x51
f010177a:	68 0a 4d 10 f0       	push   $0xf0104d0a
f010177f:	e8 07 e9 ff ff       	call   f010008b <_panic>
f0101784:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010178a:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101790:	80 38 00             	cmpb   $0x0,(%eax)
f0101793:	74 19                	je     f01017ae <mem_init+0x577>
f0101795:	68 d1 4e 10 f0       	push   $0xf0104ed1
f010179a:	68 24 4d 10 f0       	push   $0xf0104d24
f010179f:	68 9c 02 00 00       	push   $0x29c
f01017a4:	68 ec 4c 10 f0       	push   $0xf0104cec
f01017a9:	e8 dd e8 ff ff       	call   f010008b <_panic>
f01017ae:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01017b1:	39 d0                	cmp    %edx,%eax
f01017b3:	75 db                	jne    f0101790 <mem_init+0x559>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01017b5:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01017b8:	a3 5c 85 11 f0       	mov    %eax,0xf011855c

	// free the pages we took
	page_free(pp0);
f01017bd:	83 ec 0c             	sub    $0xc,%esp
f01017c0:	56                   	push   %esi
f01017c1:	e8 e7 f7 ff ff       	call   f0100fad <page_free>
	page_free(pp1);
f01017c6:	89 3c 24             	mov    %edi,(%esp)
f01017c9:	e8 df f7 ff ff       	call   f0100fad <page_free>
	page_free(pp2);
f01017ce:	83 c4 04             	add    $0x4,%esp
f01017d1:	ff 75 d4             	pushl  -0x2c(%ebp)
f01017d4:	e8 d4 f7 ff ff       	call   f0100fad <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017d9:	a1 5c 85 11 f0       	mov    0xf011855c,%eax
f01017de:	83 c4 10             	add    $0x10,%esp
f01017e1:	eb 05                	jmp    f01017e8 <mem_init+0x5b1>
		--nfree;
f01017e3:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017e6:	8b 00                	mov    (%eax),%eax
f01017e8:	85 c0                	test   %eax,%eax
f01017ea:	75 f7                	jne    f01017e3 <mem_init+0x5ac>
		--nfree;
	assert(nfree == 0);
f01017ec:	85 db                	test   %ebx,%ebx
f01017ee:	74 19                	je     f0101809 <mem_init+0x5d2>
f01017f0:	68 db 4e 10 f0       	push   $0xf0104edb
f01017f5:	68 24 4d 10 f0       	push   $0xf0104d24
f01017fa:	68 a9 02 00 00       	push   $0x2a9
f01017ff:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101804:	e8 82 e8 ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101809:	83 ec 0c             	sub    $0xc,%esp
f010180c:	68 20 47 10 f0       	push   $0xf0104720
f0101811:	e8 3b 12 00 00       	call   f0102a51 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101816:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010181d:	e8 1b f7 ff ff       	call   f0100f3d <page_alloc>
f0101822:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101825:	83 c4 10             	add    $0x10,%esp
f0101828:	85 c0                	test   %eax,%eax
f010182a:	75 19                	jne    f0101845 <mem_init+0x60e>
f010182c:	68 e9 4d 10 f0       	push   $0xf0104de9
f0101831:	68 24 4d 10 f0       	push   $0xf0104d24
f0101836:	68 05 03 00 00       	push   $0x305
f010183b:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101840:	e8 46 e8 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101845:	83 ec 0c             	sub    $0xc,%esp
f0101848:	6a 00                	push   $0x0
f010184a:	e8 ee f6 ff ff       	call   f0100f3d <page_alloc>
f010184f:	89 c3                	mov    %eax,%ebx
f0101851:	83 c4 10             	add    $0x10,%esp
f0101854:	85 c0                	test   %eax,%eax
f0101856:	75 19                	jne    f0101871 <mem_init+0x63a>
f0101858:	68 ff 4d 10 f0       	push   $0xf0104dff
f010185d:	68 24 4d 10 f0       	push   $0xf0104d24
f0101862:	68 06 03 00 00       	push   $0x306
f0101867:	68 ec 4c 10 f0       	push   $0xf0104cec
f010186c:	e8 1a e8 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101871:	83 ec 0c             	sub    $0xc,%esp
f0101874:	6a 00                	push   $0x0
f0101876:	e8 c2 f6 ff ff       	call   f0100f3d <page_alloc>
f010187b:	89 c6                	mov    %eax,%esi
f010187d:	83 c4 10             	add    $0x10,%esp
f0101880:	85 c0                	test   %eax,%eax
f0101882:	75 19                	jne    f010189d <mem_init+0x666>
f0101884:	68 15 4e 10 f0       	push   $0xf0104e15
f0101889:	68 24 4d 10 f0       	push   $0xf0104d24
f010188e:	68 07 03 00 00       	push   $0x307
f0101893:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101898:	e8 ee e7 ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010189d:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01018a0:	75 19                	jne    f01018bb <mem_init+0x684>
f01018a2:	68 2b 4e 10 f0       	push   $0xf0104e2b
f01018a7:	68 24 4d 10 f0       	push   $0xf0104d24
f01018ac:	68 0a 03 00 00       	push   $0x30a
f01018b1:	68 ec 4c 10 f0       	push   $0xf0104cec
f01018b6:	e8 d0 e7 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018bb:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01018be:	74 04                	je     f01018c4 <mem_init+0x68d>
f01018c0:	39 c3                	cmp    %eax,%ebx
f01018c2:	75 19                	jne    f01018dd <mem_init+0x6a6>
f01018c4:	68 00 47 10 f0       	push   $0xf0104700
f01018c9:	68 24 4d 10 f0       	push   $0xf0104d24
f01018ce:	68 0b 03 00 00       	push   $0x30b
f01018d3:	68 ec 4c 10 f0       	push   $0xf0104cec
f01018d8:	e8 ae e7 ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01018dd:	a1 5c 85 11 f0       	mov    0xf011855c,%eax
f01018e2:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01018e5:	c7 05 5c 85 11 f0 00 	movl   $0x0,0xf011855c
f01018ec:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01018ef:	83 ec 0c             	sub    $0xc,%esp
f01018f2:	6a 00                	push   $0x0
f01018f4:	e8 44 f6 ff ff       	call   f0100f3d <page_alloc>
f01018f9:	83 c4 10             	add    $0x10,%esp
f01018fc:	85 c0                	test   %eax,%eax
f01018fe:	74 19                	je     f0101919 <mem_init+0x6e2>
f0101900:	68 94 4e 10 f0       	push   $0xf0104e94
f0101905:	68 24 4d 10 f0       	push   $0xf0104d24
f010190a:	68 12 03 00 00       	push   $0x312
f010190f:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101914:	e8 72 e7 ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101919:	83 ec 04             	sub    $0x4,%esp
f010191c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010191f:	50                   	push   %eax
f0101920:	6a 00                	push   $0x0
f0101922:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0101928:	e8 f2 f7 ff ff       	call   f010111f <page_lookup>
f010192d:	83 c4 10             	add    $0x10,%esp
f0101930:	85 c0                	test   %eax,%eax
f0101932:	74 19                	je     f010194d <mem_init+0x716>
f0101934:	68 40 47 10 f0       	push   $0xf0104740
f0101939:	68 24 4d 10 f0       	push   $0xf0104d24
f010193e:	68 15 03 00 00       	push   $0x315
f0101943:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101948:	e8 3e e7 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010194d:	6a 02                	push   $0x2
f010194f:	6a 00                	push   $0x0
f0101951:	53                   	push   %ebx
f0101952:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0101958:	e8 72 f8 ff ff       	call   f01011cf <page_insert>
f010195d:	83 c4 10             	add    $0x10,%esp
f0101960:	85 c0                	test   %eax,%eax
f0101962:	78 19                	js     f010197d <mem_init+0x746>
f0101964:	68 78 47 10 f0       	push   $0xf0104778
f0101969:	68 24 4d 10 f0       	push   $0xf0104d24
f010196e:	68 18 03 00 00       	push   $0x318
f0101973:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101978:	e8 0e e7 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f010197d:	83 ec 0c             	sub    $0xc,%esp
f0101980:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101983:	e8 25 f6 ff ff       	call   f0100fad <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101988:	6a 02                	push   $0x2
f010198a:	6a 00                	push   $0x0
f010198c:	53                   	push   %ebx
f010198d:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0101993:	e8 37 f8 ff ff       	call   f01011cf <page_insert>
f0101998:	83 c4 20             	add    $0x20,%esp
f010199b:	85 c0                	test   %eax,%eax
f010199d:	74 19                	je     f01019b8 <mem_init+0x781>
f010199f:	68 a8 47 10 f0       	push   $0xf01047a8
f01019a4:	68 24 4d 10 f0       	push   $0xf0104d24
f01019a9:	68 1c 03 00 00       	push   $0x31c
f01019ae:	68 ec 4c 10 f0       	push   $0xf0104cec
f01019b3:	e8 d3 e6 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01019b8:	8b 3d 88 89 11 f0    	mov    0xf0118988,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01019be:	a1 8c 89 11 f0       	mov    0xf011898c,%eax
f01019c3:	89 c1                	mov    %eax,%ecx
f01019c5:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01019c8:	8b 17                	mov    (%edi),%edx
f01019ca:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01019d0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019d3:	29 c8                	sub    %ecx,%eax
f01019d5:	c1 f8 03             	sar    $0x3,%eax
f01019d8:	c1 e0 0c             	shl    $0xc,%eax
f01019db:	39 c2                	cmp    %eax,%edx
f01019dd:	74 19                	je     f01019f8 <mem_init+0x7c1>
f01019df:	68 d8 47 10 f0       	push   $0xf01047d8
f01019e4:	68 24 4d 10 f0       	push   $0xf0104d24
f01019e9:	68 1d 03 00 00       	push   $0x31d
f01019ee:	68 ec 4c 10 f0       	push   $0xf0104cec
f01019f3:	e8 93 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01019f8:	ba 00 00 00 00       	mov    $0x0,%edx
f01019fd:	89 f8                	mov    %edi,%eax
f01019ff:	e8 e8 f0 ff ff       	call   f0100aec <check_va2pa>
f0101a04:	89 da                	mov    %ebx,%edx
f0101a06:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101a09:	c1 fa 03             	sar    $0x3,%edx
f0101a0c:	c1 e2 0c             	shl    $0xc,%edx
f0101a0f:	39 d0                	cmp    %edx,%eax
f0101a11:	74 19                	je     f0101a2c <mem_init+0x7f5>
f0101a13:	68 00 48 10 f0       	push   $0xf0104800
f0101a18:	68 24 4d 10 f0       	push   $0xf0104d24
f0101a1d:	68 1e 03 00 00       	push   $0x31e
f0101a22:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101a27:	e8 5f e6 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101a2c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101a31:	74 19                	je     f0101a4c <mem_init+0x815>
f0101a33:	68 e6 4e 10 f0       	push   $0xf0104ee6
f0101a38:	68 24 4d 10 f0       	push   $0xf0104d24
f0101a3d:	68 1f 03 00 00       	push   $0x31f
f0101a42:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101a47:	e8 3f e6 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f0101a4c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a4f:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a54:	74 19                	je     f0101a6f <mem_init+0x838>
f0101a56:	68 f7 4e 10 f0       	push   $0xf0104ef7
f0101a5b:	68 24 4d 10 f0       	push   $0xf0104d24
f0101a60:	68 20 03 00 00       	push   $0x320
f0101a65:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101a6a:	e8 1c e6 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a6f:	6a 02                	push   $0x2
f0101a71:	68 00 10 00 00       	push   $0x1000
f0101a76:	56                   	push   %esi
f0101a77:	57                   	push   %edi
f0101a78:	e8 52 f7 ff ff       	call   f01011cf <page_insert>
f0101a7d:	83 c4 10             	add    $0x10,%esp
f0101a80:	85 c0                	test   %eax,%eax
f0101a82:	74 19                	je     f0101a9d <mem_init+0x866>
f0101a84:	68 30 48 10 f0       	push   $0xf0104830
f0101a89:	68 24 4d 10 f0       	push   $0xf0104d24
f0101a8e:	68 23 03 00 00       	push   $0x323
f0101a93:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101a98:	e8 ee e5 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a9d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101aa2:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0101aa7:	e8 40 f0 ff ff       	call   f0100aec <check_va2pa>
f0101aac:	89 f2                	mov    %esi,%edx
f0101aae:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f0101ab4:	c1 fa 03             	sar    $0x3,%edx
f0101ab7:	c1 e2 0c             	shl    $0xc,%edx
f0101aba:	39 d0                	cmp    %edx,%eax
f0101abc:	74 19                	je     f0101ad7 <mem_init+0x8a0>
f0101abe:	68 6c 48 10 f0       	push   $0xf010486c
f0101ac3:	68 24 4d 10 f0       	push   $0xf0104d24
f0101ac8:	68 24 03 00 00       	push   $0x324
f0101acd:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101ad2:	e8 b4 e5 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101ad7:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101adc:	74 19                	je     f0101af7 <mem_init+0x8c0>
f0101ade:	68 08 4f 10 f0       	push   $0xf0104f08
f0101ae3:	68 24 4d 10 f0       	push   $0xf0104d24
f0101ae8:	68 25 03 00 00       	push   $0x325
f0101aed:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101af2:	e8 94 e5 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101af7:	83 ec 0c             	sub    $0xc,%esp
f0101afa:	6a 00                	push   $0x0
f0101afc:	e8 3c f4 ff ff       	call   f0100f3d <page_alloc>
f0101b01:	83 c4 10             	add    $0x10,%esp
f0101b04:	85 c0                	test   %eax,%eax
f0101b06:	74 19                	je     f0101b21 <mem_init+0x8ea>
f0101b08:	68 94 4e 10 f0       	push   $0xf0104e94
f0101b0d:	68 24 4d 10 f0       	push   $0xf0104d24
f0101b12:	68 28 03 00 00       	push   $0x328
f0101b17:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101b1c:	e8 6a e5 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b21:	6a 02                	push   $0x2
f0101b23:	68 00 10 00 00       	push   $0x1000
f0101b28:	56                   	push   %esi
f0101b29:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0101b2f:	e8 9b f6 ff ff       	call   f01011cf <page_insert>
f0101b34:	83 c4 10             	add    $0x10,%esp
f0101b37:	85 c0                	test   %eax,%eax
f0101b39:	74 19                	je     f0101b54 <mem_init+0x91d>
f0101b3b:	68 30 48 10 f0       	push   $0xf0104830
f0101b40:	68 24 4d 10 f0       	push   $0xf0104d24
f0101b45:	68 2b 03 00 00       	push   $0x32b
f0101b4a:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101b4f:	e8 37 e5 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b54:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b59:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0101b5e:	e8 89 ef ff ff       	call   f0100aec <check_va2pa>
f0101b63:	89 f2                	mov    %esi,%edx
f0101b65:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f0101b6b:	c1 fa 03             	sar    $0x3,%edx
f0101b6e:	c1 e2 0c             	shl    $0xc,%edx
f0101b71:	39 d0                	cmp    %edx,%eax
f0101b73:	74 19                	je     f0101b8e <mem_init+0x957>
f0101b75:	68 6c 48 10 f0       	push   $0xf010486c
f0101b7a:	68 24 4d 10 f0       	push   $0xf0104d24
f0101b7f:	68 2c 03 00 00       	push   $0x32c
f0101b84:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101b89:	e8 fd e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101b8e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b93:	74 19                	je     f0101bae <mem_init+0x977>
f0101b95:	68 08 4f 10 f0       	push   $0xf0104f08
f0101b9a:	68 24 4d 10 f0       	push   $0xf0104d24
f0101b9f:	68 2d 03 00 00       	push   $0x32d
f0101ba4:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101ba9:	e8 dd e4 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101bae:	83 ec 0c             	sub    $0xc,%esp
f0101bb1:	6a 00                	push   $0x0
f0101bb3:	e8 85 f3 ff ff       	call   f0100f3d <page_alloc>
f0101bb8:	83 c4 10             	add    $0x10,%esp
f0101bbb:	85 c0                	test   %eax,%eax
f0101bbd:	74 19                	je     f0101bd8 <mem_init+0x9a1>
f0101bbf:	68 94 4e 10 f0       	push   $0xf0104e94
f0101bc4:	68 24 4d 10 f0       	push   $0xf0104d24
f0101bc9:	68 31 03 00 00       	push   $0x331
f0101bce:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101bd3:	e8 b3 e4 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101bd8:	8b 15 88 89 11 f0    	mov    0xf0118988,%edx
f0101bde:	8b 02                	mov    (%edx),%eax
f0101be0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101be5:	89 c1                	mov    %eax,%ecx
f0101be7:	c1 e9 0c             	shr    $0xc,%ecx
f0101bea:	3b 0d 84 89 11 f0    	cmp    0xf0118984,%ecx
f0101bf0:	72 15                	jb     f0101c07 <mem_init+0x9d0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101bf2:	50                   	push   %eax
f0101bf3:	68 c8 44 10 f0       	push   $0xf01044c8
f0101bf8:	68 34 03 00 00       	push   $0x334
f0101bfd:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101c02:	e8 84 e4 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0101c07:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101c0c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101c0f:	83 ec 04             	sub    $0x4,%esp
f0101c12:	6a 00                	push   $0x0
f0101c14:	68 00 10 00 00       	push   $0x1000
f0101c19:	52                   	push   %edx
f0101c1a:	e8 f6 f3 ff ff       	call   f0101015 <pgdir_walk>
f0101c1f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101c22:	8d 57 04             	lea    0x4(%edi),%edx
f0101c25:	83 c4 10             	add    $0x10,%esp
f0101c28:	39 d0                	cmp    %edx,%eax
f0101c2a:	74 19                	je     f0101c45 <mem_init+0xa0e>
f0101c2c:	68 9c 48 10 f0       	push   $0xf010489c
f0101c31:	68 24 4d 10 f0       	push   $0xf0104d24
f0101c36:	68 35 03 00 00       	push   $0x335
f0101c3b:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101c40:	e8 46 e4 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c45:	6a 06                	push   $0x6
f0101c47:	68 00 10 00 00       	push   $0x1000
f0101c4c:	56                   	push   %esi
f0101c4d:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0101c53:	e8 77 f5 ff ff       	call   f01011cf <page_insert>
f0101c58:	83 c4 10             	add    $0x10,%esp
f0101c5b:	85 c0                	test   %eax,%eax
f0101c5d:	74 19                	je     f0101c78 <mem_init+0xa41>
f0101c5f:	68 dc 48 10 f0       	push   $0xf01048dc
f0101c64:	68 24 4d 10 f0       	push   $0xf0104d24
f0101c69:	68 38 03 00 00       	push   $0x338
f0101c6e:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101c73:	e8 13 e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c78:	8b 3d 88 89 11 f0    	mov    0xf0118988,%edi
f0101c7e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c83:	89 f8                	mov    %edi,%eax
f0101c85:	e8 62 ee ff ff       	call   f0100aec <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101c8a:	89 f2                	mov    %esi,%edx
f0101c8c:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f0101c92:	c1 fa 03             	sar    $0x3,%edx
f0101c95:	c1 e2 0c             	shl    $0xc,%edx
f0101c98:	39 d0                	cmp    %edx,%eax
f0101c9a:	74 19                	je     f0101cb5 <mem_init+0xa7e>
f0101c9c:	68 6c 48 10 f0       	push   $0xf010486c
f0101ca1:	68 24 4d 10 f0       	push   $0xf0104d24
f0101ca6:	68 39 03 00 00       	push   $0x339
f0101cab:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101cb0:	e8 d6 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101cb5:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101cba:	74 19                	je     f0101cd5 <mem_init+0xa9e>
f0101cbc:	68 08 4f 10 f0       	push   $0xf0104f08
f0101cc1:	68 24 4d 10 f0       	push   $0xf0104d24
f0101cc6:	68 3a 03 00 00       	push   $0x33a
f0101ccb:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101cd0:	e8 b6 e3 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101cd5:	83 ec 04             	sub    $0x4,%esp
f0101cd8:	6a 00                	push   $0x0
f0101cda:	68 00 10 00 00       	push   $0x1000
f0101cdf:	57                   	push   %edi
f0101ce0:	e8 30 f3 ff ff       	call   f0101015 <pgdir_walk>
f0101ce5:	83 c4 10             	add    $0x10,%esp
f0101ce8:	f6 00 04             	testb  $0x4,(%eax)
f0101ceb:	75 19                	jne    f0101d06 <mem_init+0xacf>
f0101ced:	68 1c 49 10 f0       	push   $0xf010491c
f0101cf2:	68 24 4d 10 f0       	push   $0xf0104d24
f0101cf7:	68 3b 03 00 00       	push   $0x33b
f0101cfc:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101d01:	e8 85 e3 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101d06:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0101d0b:	f6 00 04             	testb  $0x4,(%eax)
f0101d0e:	75 19                	jne    f0101d29 <mem_init+0xaf2>
f0101d10:	68 19 4f 10 f0       	push   $0xf0104f19
f0101d15:	68 24 4d 10 f0       	push   $0xf0104d24
f0101d1a:	68 3c 03 00 00       	push   $0x33c
f0101d1f:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101d24:	e8 62 e3 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d29:	6a 02                	push   $0x2
f0101d2b:	68 00 10 00 00       	push   $0x1000
f0101d30:	56                   	push   %esi
f0101d31:	50                   	push   %eax
f0101d32:	e8 98 f4 ff ff       	call   f01011cf <page_insert>
f0101d37:	83 c4 10             	add    $0x10,%esp
f0101d3a:	85 c0                	test   %eax,%eax
f0101d3c:	74 19                	je     f0101d57 <mem_init+0xb20>
f0101d3e:	68 30 48 10 f0       	push   $0xf0104830
f0101d43:	68 24 4d 10 f0       	push   $0xf0104d24
f0101d48:	68 3f 03 00 00       	push   $0x33f
f0101d4d:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101d52:	e8 34 e3 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101d57:	83 ec 04             	sub    $0x4,%esp
f0101d5a:	6a 00                	push   $0x0
f0101d5c:	68 00 10 00 00       	push   $0x1000
f0101d61:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0101d67:	e8 a9 f2 ff ff       	call   f0101015 <pgdir_walk>
f0101d6c:	83 c4 10             	add    $0x10,%esp
f0101d6f:	f6 00 02             	testb  $0x2,(%eax)
f0101d72:	75 19                	jne    f0101d8d <mem_init+0xb56>
f0101d74:	68 50 49 10 f0       	push   $0xf0104950
f0101d79:	68 24 4d 10 f0       	push   $0xf0104d24
f0101d7e:	68 40 03 00 00       	push   $0x340
f0101d83:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101d88:	e8 fe e2 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d8d:	83 ec 04             	sub    $0x4,%esp
f0101d90:	6a 00                	push   $0x0
f0101d92:	68 00 10 00 00       	push   $0x1000
f0101d97:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0101d9d:	e8 73 f2 ff ff       	call   f0101015 <pgdir_walk>
f0101da2:	83 c4 10             	add    $0x10,%esp
f0101da5:	f6 00 04             	testb  $0x4,(%eax)
f0101da8:	74 19                	je     f0101dc3 <mem_init+0xb8c>
f0101daa:	68 84 49 10 f0       	push   $0xf0104984
f0101daf:	68 24 4d 10 f0       	push   $0xf0104d24
f0101db4:	68 41 03 00 00       	push   $0x341
f0101db9:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101dbe:	e8 c8 e2 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101dc3:	6a 02                	push   $0x2
f0101dc5:	68 00 00 40 00       	push   $0x400000
f0101dca:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101dcd:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0101dd3:	e8 f7 f3 ff ff       	call   f01011cf <page_insert>
f0101dd8:	83 c4 10             	add    $0x10,%esp
f0101ddb:	85 c0                	test   %eax,%eax
f0101ddd:	78 19                	js     f0101df8 <mem_init+0xbc1>
f0101ddf:	68 bc 49 10 f0       	push   $0xf01049bc
f0101de4:	68 24 4d 10 f0       	push   $0xf0104d24
f0101de9:	68 44 03 00 00       	push   $0x344
f0101dee:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101df3:	e8 93 e2 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101df8:	6a 02                	push   $0x2
f0101dfa:	68 00 10 00 00       	push   $0x1000
f0101dff:	53                   	push   %ebx
f0101e00:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0101e06:	e8 c4 f3 ff ff       	call   f01011cf <page_insert>
f0101e0b:	83 c4 10             	add    $0x10,%esp
f0101e0e:	85 c0                	test   %eax,%eax
f0101e10:	74 19                	je     f0101e2b <mem_init+0xbf4>
f0101e12:	68 f4 49 10 f0       	push   $0xf01049f4
f0101e17:	68 24 4d 10 f0       	push   $0xf0104d24
f0101e1c:	68 47 03 00 00       	push   $0x347
f0101e21:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101e26:	e8 60 e2 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e2b:	83 ec 04             	sub    $0x4,%esp
f0101e2e:	6a 00                	push   $0x0
f0101e30:	68 00 10 00 00       	push   $0x1000
f0101e35:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0101e3b:	e8 d5 f1 ff ff       	call   f0101015 <pgdir_walk>
f0101e40:	83 c4 10             	add    $0x10,%esp
f0101e43:	f6 00 04             	testb  $0x4,(%eax)
f0101e46:	74 19                	je     f0101e61 <mem_init+0xc2a>
f0101e48:	68 84 49 10 f0       	push   $0xf0104984
f0101e4d:	68 24 4d 10 f0       	push   $0xf0104d24
f0101e52:	68 48 03 00 00       	push   $0x348
f0101e57:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101e5c:	e8 2a e2 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101e61:	8b 3d 88 89 11 f0    	mov    0xf0118988,%edi
f0101e67:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e6c:	89 f8                	mov    %edi,%eax
f0101e6e:	e8 79 ec ff ff       	call   f0100aec <check_va2pa>
f0101e73:	89 c1                	mov    %eax,%ecx
f0101e75:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e78:	89 d8                	mov    %ebx,%eax
f0101e7a:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0101e80:	c1 f8 03             	sar    $0x3,%eax
f0101e83:	c1 e0 0c             	shl    $0xc,%eax
f0101e86:	39 c1                	cmp    %eax,%ecx
f0101e88:	74 19                	je     f0101ea3 <mem_init+0xc6c>
f0101e8a:	68 30 4a 10 f0       	push   $0xf0104a30
f0101e8f:	68 24 4d 10 f0       	push   $0xf0104d24
f0101e94:	68 4b 03 00 00       	push   $0x34b
f0101e99:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101e9e:	e8 e8 e1 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ea3:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ea8:	89 f8                	mov    %edi,%eax
f0101eaa:	e8 3d ec ff ff       	call   f0100aec <check_va2pa>
f0101eaf:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101eb2:	74 19                	je     f0101ecd <mem_init+0xc96>
f0101eb4:	68 5c 4a 10 f0       	push   $0xf0104a5c
f0101eb9:	68 24 4d 10 f0       	push   $0xf0104d24
f0101ebe:	68 4c 03 00 00       	push   $0x34c
f0101ec3:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101ec8:	e8 be e1 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101ecd:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101ed2:	74 19                	je     f0101eed <mem_init+0xcb6>
f0101ed4:	68 2f 4f 10 f0       	push   $0xf0104f2f
f0101ed9:	68 24 4d 10 f0       	push   $0xf0104d24
f0101ede:	68 4e 03 00 00       	push   $0x34e
f0101ee3:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101ee8:	e8 9e e1 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101eed:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ef2:	74 19                	je     f0101f0d <mem_init+0xcd6>
f0101ef4:	68 40 4f 10 f0       	push   $0xf0104f40
f0101ef9:	68 24 4d 10 f0       	push   $0xf0104d24
f0101efe:	68 4f 03 00 00       	push   $0x34f
f0101f03:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101f08:	e8 7e e1 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101f0d:	83 ec 0c             	sub    $0xc,%esp
f0101f10:	6a 00                	push   $0x0
f0101f12:	e8 26 f0 ff ff       	call   f0100f3d <page_alloc>
f0101f17:	83 c4 10             	add    $0x10,%esp
f0101f1a:	85 c0                	test   %eax,%eax
f0101f1c:	74 04                	je     f0101f22 <mem_init+0xceb>
f0101f1e:	39 c6                	cmp    %eax,%esi
f0101f20:	74 19                	je     f0101f3b <mem_init+0xd04>
f0101f22:	68 8c 4a 10 f0       	push   $0xf0104a8c
f0101f27:	68 24 4d 10 f0       	push   $0xf0104d24
f0101f2c:	68 52 03 00 00       	push   $0x352
f0101f31:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101f36:	e8 50 e1 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101f3b:	83 ec 08             	sub    $0x8,%esp
f0101f3e:	6a 00                	push   $0x0
f0101f40:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0101f46:	e8 3a f2 ff ff       	call   f0101185 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f4b:	8b 3d 88 89 11 f0    	mov    0xf0118988,%edi
f0101f51:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f56:	89 f8                	mov    %edi,%eax
f0101f58:	e8 8f eb ff ff       	call   f0100aec <check_va2pa>
f0101f5d:	83 c4 10             	add    $0x10,%esp
f0101f60:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f63:	74 19                	je     f0101f7e <mem_init+0xd47>
f0101f65:	68 b0 4a 10 f0       	push   $0xf0104ab0
f0101f6a:	68 24 4d 10 f0       	push   $0xf0104d24
f0101f6f:	68 56 03 00 00       	push   $0x356
f0101f74:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101f79:	e8 0d e1 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f7e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f83:	89 f8                	mov    %edi,%eax
f0101f85:	e8 62 eb ff ff       	call   f0100aec <check_va2pa>
f0101f8a:	89 da                	mov    %ebx,%edx
f0101f8c:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f0101f92:	c1 fa 03             	sar    $0x3,%edx
f0101f95:	c1 e2 0c             	shl    $0xc,%edx
f0101f98:	39 d0                	cmp    %edx,%eax
f0101f9a:	74 19                	je     f0101fb5 <mem_init+0xd7e>
f0101f9c:	68 5c 4a 10 f0       	push   $0xf0104a5c
f0101fa1:	68 24 4d 10 f0       	push   $0xf0104d24
f0101fa6:	68 57 03 00 00       	push   $0x357
f0101fab:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101fb0:	e8 d6 e0 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101fb5:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101fba:	74 19                	je     f0101fd5 <mem_init+0xd9e>
f0101fbc:	68 e6 4e 10 f0       	push   $0xf0104ee6
f0101fc1:	68 24 4d 10 f0       	push   $0xf0104d24
f0101fc6:	68 58 03 00 00       	push   $0x358
f0101fcb:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101fd0:	e8 b6 e0 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101fd5:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101fda:	74 19                	je     f0101ff5 <mem_init+0xdbe>
f0101fdc:	68 40 4f 10 f0       	push   $0xf0104f40
f0101fe1:	68 24 4d 10 f0       	push   $0xf0104d24
f0101fe6:	68 59 03 00 00       	push   $0x359
f0101feb:	68 ec 4c 10 f0       	push   $0xf0104cec
f0101ff0:	e8 96 e0 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101ff5:	6a 00                	push   $0x0
f0101ff7:	68 00 10 00 00       	push   $0x1000
f0101ffc:	53                   	push   %ebx
f0101ffd:	57                   	push   %edi
f0101ffe:	e8 cc f1 ff ff       	call   f01011cf <page_insert>
f0102003:	83 c4 10             	add    $0x10,%esp
f0102006:	85 c0                	test   %eax,%eax
f0102008:	74 19                	je     f0102023 <mem_init+0xdec>
f010200a:	68 d4 4a 10 f0       	push   $0xf0104ad4
f010200f:	68 24 4d 10 f0       	push   $0xf0104d24
f0102014:	68 5c 03 00 00       	push   $0x35c
f0102019:	68 ec 4c 10 f0       	push   $0xf0104cec
f010201e:	e8 68 e0 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0102023:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102028:	75 19                	jne    f0102043 <mem_init+0xe0c>
f010202a:	68 51 4f 10 f0       	push   $0xf0104f51
f010202f:	68 24 4d 10 f0       	push   $0xf0104d24
f0102034:	68 5d 03 00 00       	push   $0x35d
f0102039:	68 ec 4c 10 f0       	push   $0xf0104cec
f010203e:	e8 48 e0 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0102043:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102046:	74 19                	je     f0102061 <mem_init+0xe2a>
f0102048:	68 5d 4f 10 f0       	push   $0xf0104f5d
f010204d:	68 24 4d 10 f0       	push   $0xf0104d24
f0102052:	68 5e 03 00 00       	push   $0x35e
f0102057:	68 ec 4c 10 f0       	push   $0xf0104cec
f010205c:	e8 2a e0 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102061:	83 ec 08             	sub    $0x8,%esp
f0102064:	68 00 10 00 00       	push   $0x1000
f0102069:	ff 35 88 89 11 f0    	pushl  0xf0118988
f010206f:	e8 11 f1 ff ff       	call   f0101185 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102074:	8b 3d 88 89 11 f0    	mov    0xf0118988,%edi
f010207a:	ba 00 00 00 00       	mov    $0x0,%edx
f010207f:	89 f8                	mov    %edi,%eax
f0102081:	e8 66 ea ff ff       	call   f0100aec <check_va2pa>
f0102086:	83 c4 10             	add    $0x10,%esp
f0102089:	83 f8 ff             	cmp    $0xffffffff,%eax
f010208c:	74 19                	je     f01020a7 <mem_init+0xe70>
f010208e:	68 b0 4a 10 f0       	push   $0xf0104ab0
f0102093:	68 24 4d 10 f0       	push   $0xf0104d24
f0102098:	68 62 03 00 00       	push   $0x362
f010209d:	68 ec 4c 10 f0       	push   $0xf0104cec
f01020a2:	e8 e4 df ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01020a7:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020ac:	89 f8                	mov    %edi,%eax
f01020ae:	e8 39 ea ff ff       	call   f0100aec <check_va2pa>
f01020b3:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020b6:	74 19                	je     f01020d1 <mem_init+0xe9a>
f01020b8:	68 0c 4b 10 f0       	push   $0xf0104b0c
f01020bd:	68 24 4d 10 f0       	push   $0xf0104d24
f01020c2:	68 63 03 00 00       	push   $0x363
f01020c7:	68 ec 4c 10 f0       	push   $0xf0104cec
f01020cc:	e8 ba df ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f01020d1:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01020d6:	74 19                	je     f01020f1 <mem_init+0xeba>
f01020d8:	68 72 4f 10 f0       	push   $0xf0104f72
f01020dd:	68 24 4d 10 f0       	push   $0xf0104d24
f01020e2:	68 64 03 00 00       	push   $0x364
f01020e7:	68 ec 4c 10 f0       	push   $0xf0104cec
f01020ec:	e8 9a df ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f01020f1:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01020f6:	74 19                	je     f0102111 <mem_init+0xeda>
f01020f8:	68 40 4f 10 f0       	push   $0xf0104f40
f01020fd:	68 24 4d 10 f0       	push   $0xf0104d24
f0102102:	68 65 03 00 00       	push   $0x365
f0102107:	68 ec 4c 10 f0       	push   $0xf0104cec
f010210c:	e8 7a df ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102111:	83 ec 0c             	sub    $0xc,%esp
f0102114:	6a 00                	push   $0x0
f0102116:	e8 22 ee ff ff       	call   f0100f3d <page_alloc>
f010211b:	83 c4 10             	add    $0x10,%esp
f010211e:	85 c0                	test   %eax,%eax
f0102120:	74 04                	je     f0102126 <mem_init+0xeef>
f0102122:	39 c3                	cmp    %eax,%ebx
f0102124:	74 19                	je     f010213f <mem_init+0xf08>
f0102126:	68 34 4b 10 f0       	push   $0xf0104b34
f010212b:	68 24 4d 10 f0       	push   $0xf0104d24
f0102130:	68 68 03 00 00       	push   $0x368
f0102135:	68 ec 4c 10 f0       	push   $0xf0104cec
f010213a:	e8 4c df ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010213f:	83 ec 0c             	sub    $0xc,%esp
f0102142:	6a 00                	push   $0x0
f0102144:	e8 f4 ed ff ff       	call   f0100f3d <page_alloc>
f0102149:	83 c4 10             	add    $0x10,%esp
f010214c:	85 c0                	test   %eax,%eax
f010214e:	74 19                	je     f0102169 <mem_init+0xf32>
f0102150:	68 94 4e 10 f0       	push   $0xf0104e94
f0102155:	68 24 4d 10 f0       	push   $0xf0104d24
f010215a:	68 6b 03 00 00       	push   $0x36b
f010215f:	68 ec 4c 10 f0       	push   $0xf0104cec
f0102164:	e8 22 df ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102169:	8b 0d 88 89 11 f0    	mov    0xf0118988,%ecx
f010216f:	8b 11                	mov    (%ecx),%edx
f0102171:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102177:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010217a:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0102180:	c1 f8 03             	sar    $0x3,%eax
f0102183:	c1 e0 0c             	shl    $0xc,%eax
f0102186:	39 c2                	cmp    %eax,%edx
f0102188:	74 19                	je     f01021a3 <mem_init+0xf6c>
f010218a:	68 d8 47 10 f0       	push   $0xf01047d8
f010218f:	68 24 4d 10 f0       	push   $0xf0104d24
f0102194:	68 6e 03 00 00       	push   $0x36e
f0102199:	68 ec 4c 10 f0       	push   $0xf0104cec
f010219e:	e8 e8 de ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f01021a3:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01021a9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021ac:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01021b1:	74 19                	je     f01021cc <mem_init+0xf95>
f01021b3:	68 f7 4e 10 f0       	push   $0xf0104ef7
f01021b8:	68 24 4d 10 f0       	push   $0xf0104d24
f01021bd:	68 70 03 00 00       	push   $0x370
f01021c2:	68 ec 4c 10 f0       	push   $0xf0104cec
f01021c7:	e8 bf de ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f01021cc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021cf:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01021d5:	83 ec 0c             	sub    $0xc,%esp
f01021d8:	50                   	push   %eax
f01021d9:	e8 cf ed ff ff       	call   f0100fad <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01021de:	83 c4 0c             	add    $0xc,%esp
f01021e1:	6a 01                	push   $0x1
f01021e3:	68 00 10 40 00       	push   $0x401000
f01021e8:	ff 35 88 89 11 f0    	pushl  0xf0118988
f01021ee:	e8 22 ee ff ff       	call   f0101015 <pgdir_walk>
f01021f3:	89 c7                	mov    %eax,%edi
f01021f5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01021f8:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f01021fd:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102200:	8b 40 04             	mov    0x4(%eax),%eax
f0102203:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102208:	8b 0d 84 89 11 f0    	mov    0xf0118984,%ecx
f010220e:	89 c2                	mov    %eax,%edx
f0102210:	c1 ea 0c             	shr    $0xc,%edx
f0102213:	83 c4 10             	add    $0x10,%esp
f0102216:	39 ca                	cmp    %ecx,%edx
f0102218:	72 15                	jb     f010222f <mem_init+0xff8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010221a:	50                   	push   %eax
f010221b:	68 c8 44 10 f0       	push   $0xf01044c8
f0102220:	68 77 03 00 00       	push   $0x377
f0102225:	68 ec 4c 10 f0       	push   $0xf0104cec
f010222a:	e8 5c de ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f010222f:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0102234:	39 c7                	cmp    %eax,%edi
f0102236:	74 19                	je     f0102251 <mem_init+0x101a>
f0102238:	68 83 4f 10 f0       	push   $0xf0104f83
f010223d:	68 24 4d 10 f0       	push   $0xf0104d24
f0102242:	68 78 03 00 00       	push   $0x378
f0102247:	68 ec 4c 10 f0       	push   $0xf0104cec
f010224c:	e8 3a de ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102251:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102254:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f010225b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010225e:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102264:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f010226a:	c1 f8 03             	sar    $0x3,%eax
f010226d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102270:	89 c2                	mov    %eax,%edx
f0102272:	c1 ea 0c             	shr    $0xc,%edx
f0102275:	39 d1                	cmp    %edx,%ecx
f0102277:	77 12                	ja     f010228b <mem_init+0x1054>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102279:	50                   	push   %eax
f010227a:	68 c8 44 10 f0       	push   $0xf01044c8
f010227f:	6a 51                	push   $0x51
f0102281:	68 0a 4d 10 f0       	push   $0xf0104d0a
f0102286:	e8 00 de ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010228b:	83 ec 04             	sub    $0x4,%esp
f010228e:	68 00 10 00 00       	push   $0x1000
f0102293:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0102298:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010229d:	50                   	push   %eax
f010229e:	e8 6c 15 00 00       	call   f010380f <memset>
	page_free(pp0);
f01022a3:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01022a6:	89 3c 24             	mov    %edi,(%esp)
f01022a9:	e8 ff ec ff ff       	call   f0100fad <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01022ae:	83 c4 0c             	add    $0xc,%esp
f01022b1:	6a 01                	push   $0x1
f01022b3:	6a 00                	push   $0x0
f01022b5:	ff 35 88 89 11 f0    	pushl  0xf0118988
f01022bb:	e8 55 ed ff ff       	call   f0101015 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01022c0:	89 fa                	mov    %edi,%edx
f01022c2:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f01022c8:	c1 fa 03             	sar    $0x3,%edx
f01022cb:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01022ce:	89 d0                	mov    %edx,%eax
f01022d0:	c1 e8 0c             	shr    $0xc,%eax
f01022d3:	83 c4 10             	add    $0x10,%esp
f01022d6:	3b 05 84 89 11 f0    	cmp    0xf0118984,%eax
f01022dc:	72 12                	jb     f01022f0 <mem_init+0x10b9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01022de:	52                   	push   %edx
f01022df:	68 c8 44 10 f0       	push   $0xf01044c8
f01022e4:	6a 51                	push   $0x51
f01022e6:	68 0a 4d 10 f0       	push   $0xf0104d0a
f01022eb:	e8 9b dd ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f01022f0:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01022f6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01022f9:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01022ff:	f6 00 01             	testb  $0x1,(%eax)
f0102302:	74 19                	je     f010231d <mem_init+0x10e6>
f0102304:	68 9b 4f 10 f0       	push   $0xf0104f9b
f0102309:	68 24 4d 10 f0       	push   $0xf0104d24
f010230e:	68 82 03 00 00       	push   $0x382
f0102313:	68 ec 4c 10 f0       	push   $0xf0104cec
f0102318:	e8 6e dd ff ff       	call   f010008b <_panic>
f010231d:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102320:	39 d0                	cmp    %edx,%eax
f0102322:	75 db                	jne    f01022ff <mem_init+0x10c8>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102324:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102329:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010232f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102332:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102338:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010233b:	89 3d 5c 85 11 f0    	mov    %edi,0xf011855c

	// free the pages we took
	page_free(pp0);
f0102341:	83 ec 0c             	sub    $0xc,%esp
f0102344:	50                   	push   %eax
f0102345:	e8 63 ec ff ff       	call   f0100fad <page_free>
	page_free(pp1);
f010234a:	89 1c 24             	mov    %ebx,(%esp)
f010234d:	e8 5b ec ff ff       	call   f0100fad <page_free>
	page_free(pp2);
f0102352:	89 34 24             	mov    %esi,(%esp)
f0102355:	e8 53 ec ff ff       	call   f0100fad <page_free>

	cprintf("check_page() succeeded!\n");
f010235a:	c7 04 24 b2 4f 10 f0 	movl   $0xf0104fb2,(%esp)
f0102361:	e8 eb 06 00 00       	call   f0102a51 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U|PTE_P);
f0102366:	a1 8c 89 11 f0       	mov    0xf011898c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010236b:	83 c4 10             	add    $0x10,%esp
f010236e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102373:	77 15                	ja     f010238a <mem_init+0x1153>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102375:	50                   	push   %eax
f0102376:	68 ec 44 10 f0       	push   $0xf01044ec
f010237b:	68 be 00 00 00       	push   $0xbe
f0102380:	68 ec 4c 10 f0       	push   $0xf0104cec
f0102385:	e8 01 dd ff ff       	call   f010008b <_panic>
f010238a:	83 ec 08             	sub    $0x8,%esp
f010238d:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f010238f:	05 00 00 00 10       	add    $0x10000000,%eax
f0102394:	50                   	push   %eax
f0102395:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010239a:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010239f:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f01023a4:	e8 ff ec ff ff       	call   f01010a8 <boot_map_region>
	boot_map_region(kern_pgdir, (uintptr_t)pages, PTSIZE, PADDR(pages), PTE_U|PTE_P|PTE_W);
f01023a9:	8b 15 8c 89 11 f0    	mov    0xf011898c,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01023af:	83 c4 10             	add    $0x10,%esp
f01023b2:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01023b8:	77 15                	ja     f01023cf <mem_init+0x1198>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01023ba:	52                   	push   %edx
f01023bb:	68 ec 44 10 f0       	push   $0xf01044ec
f01023c0:	68 bf 00 00 00       	push   $0xbf
f01023c5:	68 ec 4c 10 f0       	push   $0xf0104cec
f01023ca:	e8 bc dc ff ff       	call   f010008b <_panic>
f01023cf:	83 ec 08             	sub    $0x8,%esp
f01023d2:	6a 07                	push   $0x7
	return (physaddr_t)kva - KERNBASE;
f01023d4:	8d 82 00 00 00 10    	lea    0x10000000(%edx),%eax
f01023da:	50                   	push   %eax
f01023db:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01023e0:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f01023e5:	e8 be ec ff ff       	call   f01010a8 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01023ea:	83 c4 10             	add    $0x10,%esp
f01023ed:	b8 00 e0 10 f0       	mov    $0xf010e000,%eax
f01023f2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01023f7:	77 15                	ja     f010240e <mem_init+0x11d7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01023f9:	50                   	push   %eax
f01023fa:	68 ec 44 10 f0       	push   $0xf01044ec
f01023ff:	68 cb 00 00 00       	push   $0xcb
f0102404:	68 ec 4c 10 f0       	push   $0xf0104cec
f0102409:	e8 7d dc ff ff       	call   f010008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f010240e:	83 ec 08             	sub    $0x8,%esp
f0102411:	6a 02                	push   $0x2
f0102413:	68 00 e0 10 00       	push   $0x10e000
f0102418:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010241d:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102422:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102427:	e8 7c ec ff ff       	call   f01010a8 <boot_map_region>

static __inline void
cpuid(uint32_t info, uint32_t *eaxp, uint32_t *ebxp, uint32_t *ecxp, uint32_t *edxp)
{
	uint32_t eax, ebx, ecx, edx;
	asm volatile("cpuid"
f010242c:	b8 01 00 00 00       	mov    $0x1,%eax
f0102431:	0f a2                	cpuid  
	// Your code goes here:
	unsigned int add = 1;
	unsigned int bias = 1;
	uint32_t edx;
	cpuid(1, NULL, NULL, NULL, &edx);
	pseEnbl = (edx >> 3) & 1;
f0102433:	c1 ea 03             	shr    $0x3,%edx
f0102436:	83 e2 01             	and    $0x1,%edx
f0102439:	89 15 60 85 11 f0    	mov    %edx,0xf0118560
	if(pseEnbl){
f010243f:	83 c4 10             	add    $0x10,%esp
f0102442:	85 d2                	test   %edx,%edx
f0102444:	74 2a                	je     f0102470 <mem_init+0x1239>
f0102446:	b8 00 00 00 00       	mov    $0x0,%eax
f010244b:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
		uint32_t padd = 0;
		for(; padd < ((uintptr_t)0x10000000); padd += PTSIZE){
			kern_pgdir[PDX(KERNBASE+padd)] = padd  | PTE_PS | PTE_W| PTE_P;
f0102451:	c1 ea 16             	shr    $0x16,%edx
f0102454:	89 c3                	mov    %eax,%ebx
f0102456:	80 cb 83             	or     $0x83,%bl
f0102459:	8b 0d 88 89 11 f0    	mov    0xf0118988,%ecx
f010245f:	89 1c 91             	mov    %ebx,(%ecx,%edx,4)
	uint32_t edx;
	cpuid(1, NULL, NULL, NULL, &edx);
	pseEnbl = (edx >> 3) & 1;
	if(pseEnbl){
		uint32_t padd = 0;
		for(; padd < ((uintptr_t)0x10000000); padd += PTSIZE){
f0102462:	05 00 00 40 00       	add    $0x400000,%eax
f0102467:	3d 00 00 00 10       	cmp    $0x10000000,%eax
f010246c:	75 dd                	jne    f010244b <mem_init+0x1214>
f010246e:	eb 1e                	jmp    f010248e <mem_init+0x1257>
			kern_pgdir[PDX(KERNBASE+padd)] = padd  | PTE_PS | PTE_W| PTE_P;
		}	
	}
	else
	boot_map_region(kern_pgdir, KERNBASE, (size_t)((add<<31) + ((add<<31) - bias) - bias)-KERNBASE + bias,0 ,PTE_W);
f0102470:	83 ec 08             	sub    $0x8,%esp
f0102473:	6a 02                	push   $0x2
f0102475:	6a 00                	push   $0x0
f0102477:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f010247c:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102481:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102486:	e8 1d ec ff ff       	call   f01010a8 <boot_map_region>
f010248b:	83 c4 10             	add    $0x10,%esp
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010248e:	8b 35 88 89 11 f0    	mov    0xf0118988,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102494:	a1 84 89 11 f0       	mov    0xf0118984,%eax
f0102499:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010249c:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01024a3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01024a8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01024ab:	8b 3d 8c 89 11 f0    	mov    0xf011898c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01024b1:	89 7d d0             	mov    %edi,-0x30(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01024b4:	bb 00 00 00 00       	mov    $0x0,%ebx
f01024b9:	eb 55                	jmp    f0102510 <mem_init+0x12d9>
f01024bb:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01024c1:	89 f0                	mov    %esi,%eax
f01024c3:	e8 24 e6 ff ff       	call   f0100aec <check_va2pa>
f01024c8:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01024cf:	77 15                	ja     f01024e6 <mem_init+0x12af>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01024d1:	57                   	push   %edi
f01024d2:	68 ec 44 10 f0       	push   $0xf01044ec
f01024d7:	68 c1 02 00 00       	push   $0x2c1
f01024dc:	68 ec 4c 10 f0       	push   $0xf0104cec
f01024e1:	e8 a5 db ff ff       	call   f010008b <_panic>
f01024e6:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f01024ed:	39 c2                	cmp    %eax,%edx
f01024ef:	74 19                	je     f010250a <mem_init+0x12d3>
f01024f1:	68 58 4b 10 f0       	push   $0xf0104b58
f01024f6:	68 24 4d 10 f0       	push   $0xf0104d24
f01024fb:	68 c1 02 00 00       	push   $0x2c1
f0102500:	68 ec 4c 10 f0       	push   $0xf0104cec
f0102505:	e8 81 db ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010250a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102510:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102513:	77 a6                	ja     f01024bb <mem_init+0x1284>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102515:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102518:	c1 e7 0c             	shl    $0xc,%edi
f010251b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102520:	eb 30                	jmp    f0102552 <mem_init+0x131b>
f0102522:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102528:	89 f0                	mov    %esi,%eax
f010252a:	e8 bd e5 ff ff       	call   f0100aec <check_va2pa>
f010252f:	39 c3                	cmp    %eax,%ebx
f0102531:	74 19                	je     f010254c <mem_init+0x1315>
f0102533:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0102538:	68 24 4d 10 f0       	push   $0xf0104d24
f010253d:	68 c6 02 00 00       	push   $0x2c6
f0102542:	68 ec 4c 10 f0       	push   $0xf0104cec
f0102547:	e8 3f db ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010254c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102552:	39 fb                	cmp    %edi,%ebx
f0102554:	72 cc                	jb     f0102522 <mem_init+0x12eb>
f0102556:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010255b:	89 da                	mov    %ebx,%edx
f010255d:	89 f0                	mov    %esi,%eax
f010255f:	e8 88 e5 ff ff       	call   f0100aec <check_va2pa>
f0102564:	8d 93 00 60 11 10    	lea    0x10116000(%ebx),%edx
f010256a:	39 c2                	cmp    %eax,%edx
f010256c:	74 19                	je     f0102587 <mem_init+0x1350>
f010256e:	68 b4 4b 10 f0       	push   $0xf0104bb4
f0102573:	68 24 4d 10 f0       	push   $0xf0104d24
f0102578:	68 ca 02 00 00       	push   $0x2ca
f010257d:	68 ec 4c 10 f0       	push   $0xf0104cec
f0102582:	e8 04 db ff ff       	call   f010008b <_panic>
f0102587:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010258d:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102593:	75 c6                	jne    f010255b <mem_init+0x1324>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102595:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f010259a:	89 f0                	mov    %esi,%eax
f010259c:	e8 4b e5 ff ff       	call   f0100aec <check_va2pa>
f01025a1:	83 f8 ff             	cmp    $0xffffffff,%eax
f01025a4:	74 51                	je     f01025f7 <mem_init+0x13c0>
f01025a6:	68 fc 4b 10 f0       	push   $0xf0104bfc
f01025ab:	68 24 4d 10 f0       	push   $0xf0104d24
f01025b0:	68 cb 02 00 00       	push   $0x2cb
f01025b5:	68 ec 4c 10 f0       	push   $0xf0104cec
f01025ba:	e8 cc da ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01025bf:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f01025c4:	72 36                	jb     f01025fc <mem_init+0x13c5>
f01025c6:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01025cb:	76 07                	jbe    f01025d4 <mem_init+0x139d>
f01025cd:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01025d2:	75 28                	jne    f01025fc <mem_init+0x13c5>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01025d4:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f01025d8:	0f 85 83 00 00 00    	jne    f0102661 <mem_init+0x142a>
f01025de:	68 cb 4f 10 f0       	push   $0xf0104fcb
f01025e3:	68 24 4d 10 f0       	push   $0xf0104d24
f01025e8:	68 d3 02 00 00       	push   $0x2d3
f01025ed:	68 ec 4c 10 f0       	push   $0xf0104cec
f01025f2:	e8 94 da ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01025f7:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01025fc:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102601:	76 3f                	jbe    f0102642 <mem_init+0x140b>
				assert(pgdir[i] & PTE_P);
f0102603:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102606:	f6 c2 01             	test   $0x1,%dl
f0102609:	75 19                	jne    f0102624 <mem_init+0x13ed>
f010260b:	68 cb 4f 10 f0       	push   $0xf0104fcb
f0102610:	68 24 4d 10 f0       	push   $0xf0104d24
f0102615:	68 d7 02 00 00       	push   $0x2d7
f010261a:	68 ec 4c 10 f0       	push   $0xf0104cec
f010261f:	e8 67 da ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0102624:	f6 c2 02             	test   $0x2,%dl
f0102627:	75 38                	jne    f0102661 <mem_init+0x142a>
f0102629:	68 dc 4f 10 f0       	push   $0xf0104fdc
f010262e:	68 24 4d 10 f0       	push   $0xf0104d24
f0102633:	68 d8 02 00 00       	push   $0x2d8
f0102638:	68 ec 4c 10 f0       	push   $0xf0104cec
f010263d:	e8 49 da ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102642:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102646:	74 19                	je     f0102661 <mem_init+0x142a>
f0102648:	68 ed 4f 10 f0       	push   $0xf0104fed
f010264d:	68 24 4d 10 f0       	push   $0xf0104d24
f0102652:	68 da 02 00 00       	push   $0x2da
f0102657:	68 ec 4c 10 f0       	push   $0xf0104cec
f010265c:	e8 2a da ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102661:	83 c0 01             	add    $0x1,%eax
f0102664:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102669:	0f 86 50 ff ff ff    	jbe    f01025bf <mem_init+0x1388>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010266f:	83 ec 0c             	sub    $0xc,%esp
f0102672:	68 2c 4c 10 f0       	push   $0xf0104c2c
f0102677:	e8 d5 03 00 00       	call   f0102a51 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	if(pseEnbl){
f010267c:	83 c4 10             	add    $0x10,%esp
f010267f:	83 3d 60 85 11 f0 00 	cmpl   $0x0,0xf0118560
f0102686:	74 18                	je     f01026a0 <mem_init+0x1469>

static __inline uint32_t
rcr4(void)
{
	uint32_t cr4;
	__asm __volatile("movl %%cr4,%0" : "=r" (cr4));
f0102688:	0f 20 e0             	mov    %cr4,%eax
		lcr4(rcr4() | CR4_PSE);
f010268b:	83 c8 10             	or     $0x10,%eax
}

static __inline void
lcr4(uint32_t val)
{
	__asm __volatile("movl %0,%%cr4" : : "r" (val));
f010268e:	0f 22 e0             	mov    %eax,%cr4
f0102691:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102696:	0f 01 38             	invlpg (%eax)
		uintptr_t paddress = 0;
		for(paddress = 0; paddress < ((uintptr_t)0x10000000); paddress += PTSIZE){
f0102699:	05 00 00 40 00       	add    $0x400000,%eax
f010269e:	75 f6                	jne    f0102696 <mem_init+0x145f>
		invlpg((void*)(KERNBASE + paddress));
	}
	}
	lcr3(PADDR(kern_pgdir));
f01026a0:	a1 88 89 11 f0       	mov    0xf0118988,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026a5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01026aa:	77 15                	ja     f01026c1 <mem_init+0x148a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026ac:	50                   	push   %eax
f01026ad:	68 ec 44 10 f0       	push   $0xf01044ec
f01026b2:	68 f2 00 00 00       	push   $0xf2
f01026b7:	68 ec 4c 10 f0       	push   $0xf0104cec
f01026bc:	e8 ca d9 ff ff       	call   f010008b <_panic>
	return (physaddr_t)kva - KERNBASE;
f01026c1:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01026c6:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01026c9:	b8 00 00 00 00       	mov    $0x0,%eax
f01026ce:	e8 26 e5 ff ff       	call   f0100bf9 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01026d3:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f01026d6:	83 e0 f3             	and    $0xfffffff3,%eax
f01026d9:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01026de:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01026e1:	83 ec 0c             	sub    $0xc,%esp
f01026e4:	6a 00                	push   $0x0
f01026e6:	e8 52 e8 ff ff       	call   f0100f3d <page_alloc>
f01026eb:	89 c3                	mov    %eax,%ebx
f01026ed:	83 c4 10             	add    $0x10,%esp
f01026f0:	85 c0                	test   %eax,%eax
f01026f2:	75 19                	jne    f010270d <mem_init+0x14d6>
f01026f4:	68 e9 4d 10 f0       	push   $0xf0104de9
f01026f9:	68 24 4d 10 f0       	push   $0xf0104d24
f01026fe:	68 9d 03 00 00       	push   $0x39d
f0102703:	68 ec 4c 10 f0       	push   $0xf0104cec
f0102708:	e8 7e d9 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010270d:	83 ec 0c             	sub    $0xc,%esp
f0102710:	6a 00                	push   $0x0
f0102712:	e8 26 e8 ff ff       	call   f0100f3d <page_alloc>
f0102717:	89 c7                	mov    %eax,%edi
f0102719:	83 c4 10             	add    $0x10,%esp
f010271c:	85 c0                	test   %eax,%eax
f010271e:	75 19                	jne    f0102739 <mem_init+0x1502>
f0102720:	68 ff 4d 10 f0       	push   $0xf0104dff
f0102725:	68 24 4d 10 f0       	push   $0xf0104d24
f010272a:	68 9e 03 00 00       	push   $0x39e
f010272f:	68 ec 4c 10 f0       	push   $0xf0104cec
f0102734:	e8 52 d9 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0102739:	83 ec 0c             	sub    $0xc,%esp
f010273c:	6a 00                	push   $0x0
f010273e:	e8 fa e7 ff ff       	call   f0100f3d <page_alloc>
f0102743:	89 c6                	mov    %eax,%esi
f0102745:	83 c4 10             	add    $0x10,%esp
f0102748:	85 c0                	test   %eax,%eax
f010274a:	75 19                	jne    f0102765 <mem_init+0x152e>
f010274c:	68 15 4e 10 f0       	push   $0xf0104e15
f0102751:	68 24 4d 10 f0       	push   $0xf0104d24
f0102756:	68 9f 03 00 00       	push   $0x39f
f010275b:	68 ec 4c 10 f0       	push   $0xf0104cec
f0102760:	e8 26 d9 ff ff       	call   f010008b <_panic>
	page_free(pp0);
f0102765:	83 ec 0c             	sub    $0xc,%esp
f0102768:	53                   	push   %ebx
f0102769:	e8 3f e8 ff ff       	call   f0100fad <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010276e:	89 f8                	mov    %edi,%eax
f0102770:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0102776:	c1 f8 03             	sar    $0x3,%eax
f0102779:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010277c:	89 c2                	mov    %eax,%edx
f010277e:	c1 ea 0c             	shr    $0xc,%edx
f0102781:	83 c4 10             	add    $0x10,%esp
f0102784:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f010278a:	72 12                	jb     f010279e <mem_init+0x1567>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010278c:	50                   	push   %eax
f010278d:	68 c8 44 10 f0       	push   $0xf01044c8
f0102792:	6a 51                	push   $0x51
f0102794:	68 0a 4d 10 f0       	push   $0xf0104d0a
f0102799:	e8 ed d8 ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f010279e:	83 ec 04             	sub    $0x4,%esp
f01027a1:	68 00 10 00 00       	push   $0x1000
f01027a6:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f01027a8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01027ad:	50                   	push   %eax
f01027ae:	e8 5c 10 00 00       	call   f010380f <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01027b3:	89 f0                	mov    %esi,%eax
f01027b5:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f01027bb:	c1 f8 03             	sar    $0x3,%eax
f01027be:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01027c1:	89 c2                	mov    %eax,%edx
f01027c3:	c1 ea 0c             	shr    $0xc,%edx
f01027c6:	83 c4 10             	add    $0x10,%esp
f01027c9:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f01027cf:	72 12                	jb     f01027e3 <mem_init+0x15ac>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01027d1:	50                   	push   %eax
f01027d2:	68 c8 44 10 f0       	push   $0xf01044c8
f01027d7:	6a 51                	push   $0x51
f01027d9:	68 0a 4d 10 f0       	push   $0xf0104d0a
f01027de:	e8 a8 d8 ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01027e3:	83 ec 04             	sub    $0x4,%esp
f01027e6:	68 00 10 00 00       	push   $0x1000
f01027eb:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f01027ed:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01027f2:	50                   	push   %eax
f01027f3:	e8 17 10 00 00       	call   f010380f <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01027f8:	6a 02                	push   $0x2
f01027fa:	68 00 10 00 00       	push   $0x1000
f01027ff:	57                   	push   %edi
f0102800:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0102806:	e8 c4 e9 ff ff       	call   f01011cf <page_insert>
	assert(pp1->pp_ref == 1);
f010280b:	83 c4 20             	add    $0x20,%esp
f010280e:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102813:	74 19                	je     f010282e <mem_init+0x15f7>
f0102815:	68 e6 4e 10 f0       	push   $0xf0104ee6
f010281a:	68 24 4d 10 f0       	push   $0xf0104d24
f010281f:	68 a4 03 00 00       	push   $0x3a4
f0102824:	68 ec 4c 10 f0       	push   $0xf0104cec
f0102829:	e8 5d d8 ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010282e:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102835:	01 01 01 
f0102838:	74 19                	je     f0102853 <mem_init+0x161c>
f010283a:	68 4c 4c 10 f0       	push   $0xf0104c4c
f010283f:	68 24 4d 10 f0       	push   $0xf0104d24
f0102844:	68 a5 03 00 00       	push   $0x3a5
f0102849:	68 ec 4c 10 f0       	push   $0xf0104cec
f010284e:	e8 38 d8 ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102853:	6a 02                	push   $0x2
f0102855:	68 00 10 00 00       	push   $0x1000
f010285a:	56                   	push   %esi
f010285b:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0102861:	e8 69 e9 ff ff       	call   f01011cf <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102866:	83 c4 10             	add    $0x10,%esp
f0102869:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102870:	02 02 02 
f0102873:	74 19                	je     f010288e <mem_init+0x1657>
f0102875:	68 70 4c 10 f0       	push   $0xf0104c70
f010287a:	68 24 4d 10 f0       	push   $0xf0104d24
f010287f:	68 a7 03 00 00       	push   $0x3a7
f0102884:	68 ec 4c 10 f0       	push   $0xf0104cec
f0102889:	e8 fd d7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010288e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102893:	74 19                	je     f01028ae <mem_init+0x1677>
f0102895:	68 08 4f 10 f0       	push   $0xf0104f08
f010289a:	68 24 4d 10 f0       	push   $0xf0104d24
f010289f:	68 a8 03 00 00       	push   $0x3a8
f01028a4:	68 ec 4c 10 f0       	push   $0xf0104cec
f01028a9:	e8 dd d7 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f01028ae:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01028b3:	74 19                	je     f01028ce <mem_init+0x1697>
f01028b5:	68 72 4f 10 f0       	push   $0xf0104f72
f01028ba:	68 24 4d 10 f0       	push   $0xf0104d24
f01028bf:	68 a9 03 00 00       	push   $0x3a9
f01028c4:	68 ec 4c 10 f0       	push   $0xf0104cec
f01028c9:	e8 bd d7 ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01028ce:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01028d5:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01028d8:	89 f0                	mov    %esi,%eax
f01028da:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f01028e0:	c1 f8 03             	sar    $0x3,%eax
f01028e3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01028e6:	89 c2                	mov    %eax,%edx
f01028e8:	c1 ea 0c             	shr    $0xc,%edx
f01028eb:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f01028f1:	72 12                	jb     f0102905 <mem_init+0x16ce>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01028f3:	50                   	push   %eax
f01028f4:	68 c8 44 10 f0       	push   $0xf01044c8
f01028f9:	6a 51                	push   $0x51
f01028fb:	68 0a 4d 10 f0       	push   $0xf0104d0a
f0102900:	e8 86 d7 ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102905:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f010290c:	03 03 03 
f010290f:	74 19                	je     f010292a <mem_init+0x16f3>
f0102911:	68 94 4c 10 f0       	push   $0xf0104c94
f0102916:	68 24 4d 10 f0       	push   $0xf0104d24
f010291b:	68 ab 03 00 00       	push   $0x3ab
f0102920:	68 ec 4c 10 f0       	push   $0xf0104cec
f0102925:	e8 61 d7 ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f010292a:	83 ec 08             	sub    $0x8,%esp
f010292d:	68 00 10 00 00       	push   $0x1000
f0102932:	ff 35 88 89 11 f0    	pushl  0xf0118988
f0102938:	e8 48 e8 ff ff       	call   f0101185 <page_remove>
	assert(pp2->pp_ref == 0);
f010293d:	83 c4 10             	add    $0x10,%esp
f0102940:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102945:	74 19                	je     f0102960 <mem_init+0x1729>
f0102947:	68 40 4f 10 f0       	push   $0xf0104f40
f010294c:	68 24 4d 10 f0       	push   $0xf0104d24
f0102951:	68 ad 03 00 00       	push   $0x3ad
f0102956:	68 ec 4c 10 f0       	push   $0xf0104cec
f010295b:	e8 2b d7 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102960:	8b 0d 88 89 11 f0    	mov    0xf0118988,%ecx
f0102966:	8b 11                	mov    (%ecx),%edx
f0102968:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010296e:	89 d8                	mov    %ebx,%eax
f0102970:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0102976:	c1 f8 03             	sar    $0x3,%eax
f0102979:	c1 e0 0c             	shl    $0xc,%eax
f010297c:	39 c2                	cmp    %eax,%edx
f010297e:	74 19                	je     f0102999 <mem_init+0x1762>
f0102980:	68 d8 47 10 f0       	push   $0xf01047d8
f0102985:	68 24 4d 10 f0       	push   $0xf0104d24
f010298a:	68 b0 03 00 00       	push   $0x3b0
f010298f:	68 ec 4c 10 f0       	push   $0xf0104cec
f0102994:	e8 f2 d6 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0102999:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010299f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01029a4:	74 19                	je     f01029bf <mem_init+0x1788>
f01029a6:	68 f7 4e 10 f0       	push   $0xf0104ef7
f01029ab:	68 24 4d 10 f0       	push   $0xf0104d24
f01029b0:	68 b2 03 00 00       	push   $0x3b2
f01029b5:	68 ec 4c 10 f0       	push   $0xf0104cec
f01029ba:	e8 cc d6 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f01029bf:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01029c5:	83 ec 0c             	sub    $0xc,%esp
f01029c8:	53                   	push   %ebx
f01029c9:	e8 df e5 ff ff       	call   f0100fad <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01029ce:	c7 04 24 c0 4c 10 f0 	movl   $0xf0104cc0,(%esp)
f01029d5:	e8 77 00 00 00       	call   f0102a51 <cprintf>
f01029da:	83 c4 10             	add    $0x10,%esp
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01029dd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01029e0:	5b                   	pop    %ebx
f01029e1:	5e                   	pop    %esi
f01029e2:	5f                   	pop    %edi
f01029e3:	5d                   	pop    %ebp
f01029e4:	c3                   	ret    

f01029e5 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01029e5:	55                   	push   %ebp
f01029e6:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01029e8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01029eb:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01029ee:	5d                   	pop    %ebp
f01029ef:	c3                   	ret    

f01029f0 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01029f0:	55                   	push   %ebp
f01029f1:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01029f3:	ba 70 00 00 00       	mov    $0x70,%edx
f01029f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01029fb:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01029fc:	b2 71                	mov    $0x71,%dl
f01029fe:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01029ff:	0f b6 c0             	movzbl %al,%eax
}
f0102a02:	5d                   	pop    %ebp
f0102a03:	c3                   	ret    

f0102a04 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102a04:	55                   	push   %ebp
f0102a05:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102a07:	ba 70 00 00 00       	mov    $0x70,%edx
f0102a0c:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a0f:	ee                   	out    %al,(%dx)
f0102a10:	b2 71                	mov    $0x71,%dl
f0102a12:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102a15:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102a16:	5d                   	pop    %ebp
f0102a17:	c3                   	ret    

f0102a18 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102a18:	55                   	push   %ebp
f0102a19:	89 e5                	mov    %esp,%ebp
f0102a1b:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102a1e:	ff 75 08             	pushl  0x8(%ebp)
f0102a21:	e8 b9 db ff ff       	call   f01005df <cputchar>
f0102a26:	83 c4 10             	add    $0x10,%esp
	*cnt++;
}
f0102a29:	c9                   	leave  
f0102a2a:	c3                   	ret    

f0102a2b <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102a2b:	55                   	push   %ebp
f0102a2c:	89 e5                	mov    %esp,%ebp
f0102a2e:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102a31:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102a38:	ff 75 0c             	pushl  0xc(%ebp)
f0102a3b:	ff 75 08             	pushl  0x8(%ebp)
f0102a3e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102a41:	50                   	push   %eax
f0102a42:	68 18 2a 10 f0       	push   $0xf0102a18
f0102a47:	e8 7e 04 00 00       	call   f0102eca <vprintfmt>
	return cnt;
}
f0102a4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102a4f:	c9                   	leave  
f0102a50:	c3                   	ret    

f0102a51 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102a51:	55                   	push   %ebp
f0102a52:	89 e5                	mov    %esp,%ebp
f0102a54:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102a57:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102a5a:	50                   	push   %eax
f0102a5b:	ff 75 08             	pushl  0x8(%ebp)
f0102a5e:	e8 c8 ff ff ff       	call   f0102a2b <vcprintf>
	va_end(ap);

	return cnt;
}
f0102a63:	c9                   	leave  
f0102a64:	c3                   	ret    

f0102a65 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102a65:	55                   	push   %ebp
f0102a66:	89 e5                	mov    %esp,%ebp
f0102a68:	57                   	push   %edi
f0102a69:	56                   	push   %esi
f0102a6a:	53                   	push   %ebx
f0102a6b:	83 ec 14             	sub    $0x14,%esp
f0102a6e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102a71:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102a74:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102a77:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102a7a:	8b 1a                	mov    (%edx),%ebx
f0102a7c:	8b 01                	mov    (%ecx),%eax
f0102a7e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102a81:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102a88:	e9 88 00 00 00       	jmp    f0102b15 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0102a8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102a90:	01 d8                	add    %ebx,%eax
f0102a92:	89 c6                	mov    %eax,%esi
f0102a94:	c1 ee 1f             	shr    $0x1f,%esi
f0102a97:	01 c6                	add    %eax,%esi
f0102a99:	d1 fe                	sar    %esi
f0102a9b:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0102a9e:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102aa1:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0102aa4:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102aa6:	eb 03                	jmp    f0102aab <stab_binsearch+0x46>
			m--;
f0102aa8:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102aab:	39 c3                	cmp    %eax,%ebx
f0102aad:	7f 1f                	jg     f0102ace <stab_binsearch+0x69>
f0102aaf:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102ab3:	83 ea 0c             	sub    $0xc,%edx
f0102ab6:	39 f9                	cmp    %edi,%ecx
f0102ab8:	75 ee                	jne    f0102aa8 <stab_binsearch+0x43>
f0102aba:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102abd:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102ac0:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102ac3:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102ac7:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102aca:	76 18                	jbe    f0102ae4 <stab_binsearch+0x7f>
f0102acc:	eb 05                	jmp    f0102ad3 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102ace:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102ad1:	eb 42                	jmp    f0102b15 <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102ad3:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102ad6:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0102ad8:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102adb:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102ae2:	eb 31                	jmp    f0102b15 <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102ae4:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102ae7:	73 17                	jae    f0102b00 <stab_binsearch+0x9b>
			*region_right = m - 1;
f0102ae9:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102aec:	83 e8 01             	sub    $0x1,%eax
f0102aef:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102af2:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102af5:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102af7:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102afe:	eb 15                	jmp    f0102b15 <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102b00:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102b03:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0102b06:	89 1e                	mov    %ebx,(%esi)
			l = m;
			addr++;
f0102b08:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0102b0c:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102b0e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102b15:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102b18:	0f 8e 6f ff ff ff    	jle    f0102a8d <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102b1e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0102b22:	75 0f                	jne    f0102b33 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0102b24:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102b27:	8b 00                	mov    (%eax),%eax
f0102b29:	83 e8 01             	sub    $0x1,%eax
f0102b2c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102b2f:	89 06                	mov    %eax,(%esi)
f0102b31:	eb 2c                	jmp    f0102b5f <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102b33:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102b36:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102b38:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102b3b:	8b 0e                	mov    (%esi),%ecx
f0102b3d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102b40:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0102b43:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102b46:	eb 03                	jmp    f0102b4b <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102b48:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102b4b:	39 c8                	cmp    %ecx,%eax
f0102b4d:	7e 0b                	jle    f0102b5a <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0102b4f:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0102b53:	83 ea 0c             	sub    $0xc,%edx
f0102b56:	39 fb                	cmp    %edi,%ebx
f0102b58:	75 ee                	jne    f0102b48 <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102b5a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102b5d:	89 06                	mov    %eax,(%esi)
	}
}
f0102b5f:	83 c4 14             	add    $0x14,%esp
f0102b62:	5b                   	pop    %ebx
f0102b63:	5e                   	pop    %esi
f0102b64:	5f                   	pop    %edi
f0102b65:	5d                   	pop    %ebp
f0102b66:	c3                   	ret    

f0102b67 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102b67:	55                   	push   %ebp
f0102b68:	89 e5                	mov    %esp,%ebp
f0102b6a:	57                   	push   %edi
f0102b6b:	56                   	push   %esi
f0102b6c:	53                   	push   %ebx
f0102b6d:	83 ec 3c             	sub    $0x3c,%esp
f0102b70:	8b 75 08             	mov    0x8(%ebp),%esi
f0102b73:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102b76:	c7 03 fb 4f 10 f0    	movl   $0xf0104ffb,(%ebx)
	info->eip_line = 0;
f0102b7c:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102b83:	c7 43 08 fb 4f 10 f0 	movl   $0xf0104ffb,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102b8a:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102b91:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102b94:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102b9b:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102ba1:	76 11                	jbe    f0102bb4 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102ba3:	b8 3a d8 10 f0       	mov    $0xf010d83a,%eax
f0102ba8:	3d 59 b9 10 f0       	cmp    $0xf010b959,%eax
f0102bad:	77 19                	ja     f0102bc8 <debuginfo_eip+0x61>
f0102baf:	e9 a9 01 00 00       	jmp    f0102d5d <debuginfo_eip+0x1f6>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102bb4:	83 ec 04             	sub    $0x4,%esp
f0102bb7:	68 05 50 10 f0       	push   $0xf0105005
f0102bbc:	6a 7f                	push   $0x7f
f0102bbe:	68 12 50 10 f0       	push   $0xf0105012
f0102bc3:	e8 c3 d4 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102bc8:	80 3d 39 d8 10 f0 00 	cmpb   $0x0,0xf010d839
f0102bcf:	0f 85 8f 01 00 00    	jne    f0102d64 <debuginfo_eip+0x1fd>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102bd5:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102bdc:	b8 58 b9 10 f0       	mov    $0xf010b958,%eax
f0102be1:	2d 50 52 10 f0       	sub    $0xf0105250,%eax
f0102be6:	c1 f8 02             	sar    $0x2,%eax
f0102be9:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102bef:	83 e8 01             	sub    $0x1,%eax
f0102bf2:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102bf5:	83 ec 08             	sub    $0x8,%esp
f0102bf8:	56                   	push   %esi
f0102bf9:	6a 64                	push   $0x64
f0102bfb:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102bfe:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102c01:	b8 50 52 10 f0       	mov    $0xf0105250,%eax
f0102c06:	e8 5a fe ff ff       	call   f0102a65 <stab_binsearch>
	if (lfile == 0)
f0102c0b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102c0e:	83 c4 10             	add    $0x10,%esp
f0102c11:	85 c0                	test   %eax,%eax
f0102c13:	0f 84 52 01 00 00    	je     f0102d6b <debuginfo_eip+0x204>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102c19:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102c1c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c1f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102c22:	83 ec 08             	sub    $0x8,%esp
f0102c25:	56                   	push   %esi
f0102c26:	6a 24                	push   $0x24
f0102c28:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102c2b:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102c2e:	b8 50 52 10 f0       	mov    $0xf0105250,%eax
f0102c33:	e8 2d fe ff ff       	call   f0102a65 <stab_binsearch>

	if (lfun <= rfun) {
f0102c38:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102c3b:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102c3e:	83 c4 10             	add    $0x10,%esp
f0102c41:	39 d0                	cmp    %edx,%eax
f0102c43:	7f 40                	jg     f0102c85 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102c45:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0102c48:	c1 e1 02             	shl    $0x2,%ecx
f0102c4b:	8d b9 50 52 10 f0    	lea    -0xfefadb0(%ecx),%edi
f0102c51:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102c54:	8b b9 50 52 10 f0    	mov    -0xfefadb0(%ecx),%edi
f0102c5a:	b9 3a d8 10 f0       	mov    $0xf010d83a,%ecx
f0102c5f:	81 e9 59 b9 10 f0    	sub    $0xf010b959,%ecx
f0102c65:	39 cf                	cmp    %ecx,%edi
f0102c67:	73 09                	jae    f0102c72 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102c69:	81 c7 59 b9 10 f0    	add    $0xf010b959,%edi
f0102c6f:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102c72:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102c75:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102c78:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102c7b:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0102c7d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0102c80:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102c83:	eb 0f                	jmp    f0102c94 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102c85:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102c88:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102c8b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0102c8e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c91:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102c94:	83 ec 08             	sub    $0x8,%esp
f0102c97:	6a 3a                	push   $0x3a
f0102c99:	ff 73 08             	pushl  0x8(%ebx)
f0102c9c:	e8 52 0b 00 00       	call   f01037f3 <strfind>
f0102ca1:	2b 43 08             	sub    0x8(%ebx),%eax
f0102ca4:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0102ca7:	83 c4 08             	add    $0x8,%esp
f0102caa:	56                   	push   %esi
f0102cab:	6a 44                	push   $0x44
f0102cad:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0102cb0:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0102cb3:	b8 50 52 10 f0       	mov    $0xf0105250,%eax
f0102cb8:	e8 a8 fd ff ff       	call   f0102a65 <stab_binsearch>
	if(lline <= rline){
f0102cbd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102cc0:	83 c4 10             	add    $0x10,%esp
f0102cc3:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0102cc6:	0f 8f a6 00 00 00    	jg     f0102d72 <debuginfo_eip+0x20b>
		info->eip_line = stabs[lline].n_desc;
f0102ccc:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102ccf:	0f b7 04 85 56 52 10 	movzwl -0xfefadaa(,%eax,4),%eax
f0102cd6:	f0 
f0102cd7:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102cda:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102cdd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ce0:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102ce3:	8d 14 95 50 52 10 f0 	lea    -0xfefadb0(,%edx,4),%edx
f0102cea:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102ced:	eb 06                	jmp    f0102cf5 <debuginfo_eip+0x18e>
f0102cef:	83 e8 01             	sub    $0x1,%eax
f0102cf2:	83 ea 0c             	sub    $0xc,%edx
f0102cf5:	39 c7                	cmp    %eax,%edi
f0102cf7:	7f 23                	jg     f0102d1c <debuginfo_eip+0x1b5>
	       && stabs[lline].n_type != N_SOL
f0102cf9:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102cfd:	80 f9 84             	cmp    $0x84,%cl
f0102d00:	74 7e                	je     f0102d80 <debuginfo_eip+0x219>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102d02:	80 f9 64             	cmp    $0x64,%cl
f0102d05:	75 e8                	jne    f0102cef <debuginfo_eip+0x188>
f0102d07:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0102d0b:	74 e2                	je     f0102cef <debuginfo_eip+0x188>
f0102d0d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102d10:	eb 71                	jmp    f0102d83 <debuginfo_eip+0x21c>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102d12:	81 c2 59 b9 10 f0    	add    $0xf010b959,%edx
f0102d18:	89 13                	mov    %edx,(%ebx)
f0102d1a:	eb 03                	jmp    f0102d1f <debuginfo_eip+0x1b8>
f0102d1c:	8b 5d 0c             	mov    0xc(%ebp),%ebx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102d1f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102d22:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102d25:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102d2a:	39 f2                	cmp    %esi,%edx
f0102d2c:	7d 76                	jge    f0102da4 <debuginfo_eip+0x23d>
		for (lline = lfun + 1;
f0102d2e:	83 c2 01             	add    $0x1,%edx
f0102d31:	89 d0                	mov    %edx,%eax
f0102d33:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102d36:	8d 14 95 50 52 10 f0 	lea    -0xfefadb0(,%edx,4),%edx
f0102d3d:	eb 04                	jmp    f0102d43 <debuginfo_eip+0x1dc>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102d3f:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102d43:	39 c6                	cmp    %eax,%esi
f0102d45:	7e 32                	jle    f0102d79 <debuginfo_eip+0x212>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102d47:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102d4b:	83 c0 01             	add    $0x1,%eax
f0102d4e:	83 c2 0c             	add    $0xc,%edx
f0102d51:	80 f9 a0             	cmp    $0xa0,%cl
f0102d54:	74 e9                	je     f0102d3f <debuginfo_eip+0x1d8>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102d56:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d5b:	eb 47                	jmp    f0102da4 <debuginfo_eip+0x23d>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102d5d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102d62:	eb 40                	jmp    f0102da4 <debuginfo_eip+0x23d>
f0102d64:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102d69:	eb 39                	jmp    f0102da4 <debuginfo_eip+0x23d>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102d6b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102d70:	eb 32                	jmp    f0102da4 <debuginfo_eip+0x23d>
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if(lline <= rline){
		info->eip_line = stabs[lline].n_desc;
	}
	else{
		return -1;
f0102d72:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102d77:	eb 2b                	jmp    f0102da4 <debuginfo_eip+0x23d>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102d79:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d7e:	eb 24                	jmp    f0102da4 <debuginfo_eip+0x23d>
f0102d80:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102d83:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102d86:	8b 14 85 50 52 10 f0 	mov    -0xfefadb0(,%eax,4),%edx
f0102d8d:	b8 3a d8 10 f0       	mov    $0xf010d83a,%eax
f0102d92:	2d 59 b9 10 f0       	sub    $0xf010b959,%eax
f0102d97:	39 c2                	cmp    %eax,%edx
f0102d99:	0f 82 73 ff ff ff    	jb     f0102d12 <debuginfo_eip+0x1ab>
f0102d9f:	e9 7b ff ff ff       	jmp    f0102d1f <debuginfo_eip+0x1b8>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
}
f0102da4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102da7:	5b                   	pop    %ebx
f0102da8:	5e                   	pop    %esi
f0102da9:	5f                   	pop    %edi
f0102daa:	5d                   	pop    %ebp
f0102dab:	c3                   	ret    

f0102dac <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102dac:	55                   	push   %ebp
f0102dad:	89 e5                	mov    %esp,%ebp
f0102daf:	57                   	push   %edi
f0102db0:	56                   	push   %esi
f0102db1:	53                   	push   %ebx
f0102db2:	83 ec 1c             	sub    $0x1c,%esp
f0102db5:	89 c7                	mov    %eax,%edi
f0102db7:	89 d6                	mov    %edx,%esi
f0102db9:	8b 45 08             	mov    0x8(%ebp),%eax
f0102dbc:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102dbf:	89 d1                	mov    %edx,%ecx
f0102dc1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102dc4:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102dc7:	8b 45 10             	mov    0x10(%ebp),%eax
f0102dca:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102dcd:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102dd0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0102dd7:	39 4d e4             	cmp    %ecx,-0x1c(%ebp)
f0102dda:	72 05                	jb     f0102de1 <printnum+0x35>
f0102ddc:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0102ddf:	77 3e                	ja     f0102e1f <printnum+0x73>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102de1:	83 ec 0c             	sub    $0xc,%esp
f0102de4:	ff 75 18             	pushl  0x18(%ebp)
f0102de7:	83 eb 01             	sub    $0x1,%ebx
f0102dea:	53                   	push   %ebx
f0102deb:	50                   	push   %eax
f0102dec:	83 ec 08             	sub    $0x8,%esp
f0102def:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102df2:	ff 75 e0             	pushl  -0x20(%ebp)
f0102df5:	ff 75 dc             	pushl  -0x24(%ebp)
f0102df8:	ff 75 d8             	pushl  -0x28(%ebp)
f0102dfb:	e8 20 0c 00 00       	call   f0103a20 <__udivdi3>
f0102e00:	83 c4 18             	add    $0x18,%esp
f0102e03:	52                   	push   %edx
f0102e04:	50                   	push   %eax
f0102e05:	89 f2                	mov    %esi,%edx
f0102e07:	89 f8                	mov    %edi,%eax
f0102e09:	e8 9e ff ff ff       	call   f0102dac <printnum>
f0102e0e:	83 c4 20             	add    $0x20,%esp
f0102e11:	eb 13                	jmp    f0102e26 <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102e13:	83 ec 08             	sub    $0x8,%esp
f0102e16:	56                   	push   %esi
f0102e17:	ff 75 18             	pushl  0x18(%ebp)
f0102e1a:	ff d7                	call   *%edi
f0102e1c:	83 c4 10             	add    $0x10,%esp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102e1f:	83 eb 01             	sub    $0x1,%ebx
f0102e22:	85 db                	test   %ebx,%ebx
f0102e24:	7f ed                	jg     f0102e13 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102e26:	83 ec 08             	sub    $0x8,%esp
f0102e29:	56                   	push   %esi
f0102e2a:	83 ec 04             	sub    $0x4,%esp
f0102e2d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102e30:	ff 75 e0             	pushl  -0x20(%ebp)
f0102e33:	ff 75 dc             	pushl  -0x24(%ebp)
f0102e36:	ff 75 d8             	pushl  -0x28(%ebp)
f0102e39:	e8 12 0d 00 00       	call   f0103b50 <__umoddi3>
f0102e3e:	83 c4 14             	add    $0x14,%esp
f0102e41:	0f be 80 20 50 10 f0 	movsbl -0xfefafe0(%eax),%eax
f0102e48:	50                   	push   %eax
f0102e49:	ff d7                	call   *%edi
f0102e4b:	83 c4 10             	add    $0x10,%esp
}
f0102e4e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e51:	5b                   	pop    %ebx
f0102e52:	5e                   	pop    %esi
f0102e53:	5f                   	pop    %edi
f0102e54:	5d                   	pop    %ebp
f0102e55:	c3                   	ret    

f0102e56 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102e56:	55                   	push   %ebp
f0102e57:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102e59:	83 fa 01             	cmp    $0x1,%edx
f0102e5c:	7e 0e                	jle    f0102e6c <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102e5e:	8b 10                	mov    (%eax),%edx
f0102e60:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102e63:	89 08                	mov    %ecx,(%eax)
f0102e65:	8b 02                	mov    (%edx),%eax
f0102e67:	8b 52 04             	mov    0x4(%edx),%edx
f0102e6a:	eb 22                	jmp    f0102e8e <getuint+0x38>
	else if (lflag)
f0102e6c:	85 d2                	test   %edx,%edx
f0102e6e:	74 10                	je     f0102e80 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102e70:	8b 10                	mov    (%eax),%edx
f0102e72:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102e75:	89 08                	mov    %ecx,(%eax)
f0102e77:	8b 02                	mov    (%edx),%eax
f0102e79:	ba 00 00 00 00       	mov    $0x0,%edx
f0102e7e:	eb 0e                	jmp    f0102e8e <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102e80:	8b 10                	mov    (%eax),%edx
f0102e82:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102e85:	89 08                	mov    %ecx,(%eax)
f0102e87:	8b 02                	mov    (%edx),%eax
f0102e89:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102e8e:	5d                   	pop    %ebp
f0102e8f:	c3                   	ret    

f0102e90 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102e90:	55                   	push   %ebp
f0102e91:	89 e5                	mov    %esp,%ebp
f0102e93:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102e96:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102e9a:	8b 10                	mov    (%eax),%edx
f0102e9c:	3b 50 04             	cmp    0x4(%eax),%edx
f0102e9f:	73 0a                	jae    f0102eab <sprintputch+0x1b>
		*b->buf++ = ch;
f0102ea1:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102ea4:	89 08                	mov    %ecx,(%eax)
f0102ea6:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ea9:	88 02                	mov    %al,(%edx)
}
f0102eab:	5d                   	pop    %ebp
f0102eac:	c3                   	ret    

f0102ead <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102ead:	55                   	push   %ebp
f0102eae:	89 e5                	mov    %esp,%ebp
f0102eb0:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102eb3:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102eb6:	50                   	push   %eax
f0102eb7:	ff 75 10             	pushl  0x10(%ebp)
f0102eba:	ff 75 0c             	pushl  0xc(%ebp)
f0102ebd:	ff 75 08             	pushl  0x8(%ebp)
f0102ec0:	e8 05 00 00 00       	call   f0102eca <vprintfmt>
	va_end(ap);
f0102ec5:	83 c4 10             	add    $0x10,%esp
}
f0102ec8:	c9                   	leave  
f0102ec9:	c3                   	ret    

f0102eca <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102eca:	55                   	push   %ebp
f0102ecb:	89 e5                	mov    %esp,%ebp
f0102ecd:	57                   	push   %edi
f0102ece:	56                   	push   %esi
f0102ecf:	53                   	push   %ebx
f0102ed0:	83 ec 3c             	sub    $0x3c,%esp
f0102ed3:	8b 75 08             	mov    0x8(%ebp),%esi
f0102ed6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102ed9:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102edc:	eb 12                	jmp    f0102ef0 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;
	char colorcontrol[5];
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102ede:	85 c0                	test   %eax,%eax
f0102ee0:	0f 84 62 06 00 00    	je     f0103548 <vprintfmt+0x67e>
				return;
			putch(ch, putdat);
f0102ee6:	83 ec 08             	sub    $0x8,%esp
f0102ee9:	53                   	push   %ebx
f0102eea:	50                   	push   %eax
f0102eeb:	ff d6                	call   *%esi
f0102eed:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;
	char colorcontrol[5];
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102ef0:	83 c7 01             	add    $0x1,%edi
f0102ef3:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102ef7:	83 f8 25             	cmp    $0x25,%eax
f0102efa:	75 e2                	jne    f0102ede <vprintfmt+0x14>
f0102efc:	c6 45 c4 20          	movb   $0x20,-0x3c(%ebp)
f0102f00:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
f0102f07:	c7 45 c0 ff ff ff ff 	movl   $0xffffffff,-0x40(%ebp)
f0102f0e:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102f15:	ba 00 00 00 00       	mov    $0x0,%edx
f0102f1a:	eb 07                	jmp    f0102f23 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102f1c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
					colr = COLR_BLACK;
			}
			colr |= highlight;
			break;
		case '-':
			padc = '-';
f0102f1f:	c6 45 c4 2d          	movb   $0x2d,-0x3c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102f23:	8d 47 01             	lea    0x1(%edi),%eax
f0102f26:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102f29:	0f b6 07             	movzbl (%edi),%eax
f0102f2c:	0f b6 c8             	movzbl %al,%ecx
f0102f2f:	83 e8 23             	sub    $0x23,%eax
f0102f32:	3c 55                	cmp    $0x55,%al
f0102f34:	0f 87 f3 05 00 00    	ja     f010352d <vprintfmt+0x663>
f0102f3a:	0f b6 c0             	movzbl %al,%eax
f0102f3d:	ff 24 85 c0 50 10 f0 	jmp    *-0xfefaf40(,%eax,4)
f0102f44:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102f47:	c6 45 c4 30          	movb   $0x30,-0x3c(%ebp)
f0102f4b:	eb d6                	jmp    f0102f23 <vprintfmt+0x59>
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {

		// flag to pad on the right
		case 'C':
			memmove(colorcontrol, fmt, sizeof(unsigned char)*3);
f0102f4d:	83 ec 04             	sub    $0x4,%esp
f0102f50:	6a 03                	push   $0x3
f0102f52:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102f55:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0102f58:	50                   	push   %eax
f0102f59:	e8 fe 08 00 00       	call   f010385c <memmove>
			colorcontrol[3] = '\0';
f0102f5e:	c6 45 e6 00          	movb   $0x0,-0x1a(%ebp)
			fmt += 3;
f0102f62:	83 c7 04             	add    $0x4,%edi
			if(colorcontrol[0] >= '0' && colorcontrol[0] <= '9'){
f0102f65:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f0102f69:	8d 50 d0             	lea    -0x30(%eax),%edx
f0102f6c:	83 c4 10             	add    $0x10,%esp
f0102f6f:	80 fa 09             	cmp    $0x9,%dl
f0102f72:	77 29                	ja     f0102f9d <vprintfmt+0xd3>
				colr = (colorcontrol[0] - '0') * 100 + (colorcontrol[1] - '0') * 10 + (colorcontrol[2] - '0');
f0102f74:	0f be c0             	movsbl %al,%eax
f0102f77:	83 e8 30             	sub    $0x30,%eax
f0102f7a:	6b c0 64             	imul   $0x64,%eax,%eax
f0102f7d:	0f be 55 e4          	movsbl -0x1c(%ebp),%edx
f0102f81:	8d 94 92 10 ff ff ff 	lea    -0xf0(%edx,%edx,4),%edx
f0102f88:	8d 14 50             	lea    (%eax,%edx,2),%edx
f0102f8b:	0f be 45 e5          	movsbl -0x1b(%ebp),%eax
f0102f8f:	8d 44 02 d0          	lea    -0x30(%edx,%eax,1),%eax
f0102f93:	a3 6c 85 11 f0       	mov    %eax,0xf011856c
f0102f98:	e9 53 ff ff ff       	jmp    f0102ef0 <vprintfmt+0x26>
			}
			else{
				if(strcmp(colorcontrol, "ble") == 0) colr = COLR_BLUE
f0102f9d:	83 ec 08             	sub    $0x8,%esp
f0102fa0:	68 38 50 10 f0       	push   $0xf0105038
f0102fa5:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0102fa8:	50                   	push   %eax
f0102fa9:	e8 c6 07 00 00       	call   f0103774 <strcmp>
f0102fae:	83 c4 10             	add    $0x10,%esp
f0102fb1:	85 c0                	test   %eax,%eax
f0102fb3:	75 0f                	jne    f0102fc4 <vprintfmt+0xfa>
f0102fb5:	c7 05 6c 85 11 f0 01 	movl   $0x1,0xf011856c
f0102fbc:	00 00 00 
f0102fbf:	e9 2c ff ff ff       	jmp    f0102ef0 <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "grn") == 0) colr = COLR_GREEN
f0102fc4:	83 ec 08             	sub    $0x8,%esp
f0102fc7:	68 3c 50 10 f0       	push   $0xf010503c
f0102fcc:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0102fcf:	50                   	push   %eax
f0102fd0:	e8 9f 07 00 00       	call   f0103774 <strcmp>
f0102fd5:	83 c4 10             	add    $0x10,%esp
f0102fd8:	85 c0                	test   %eax,%eax
f0102fda:	75 0f                	jne    f0102feb <vprintfmt+0x121>
f0102fdc:	c7 05 6c 85 11 f0 02 	movl   $0x2,0xf011856c
f0102fe3:	00 00 00 
f0102fe6:	e9 05 ff ff ff       	jmp    f0102ef0 <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "cyn") == 0) colr = COLR_CYAN
f0102feb:	83 ec 08             	sub    $0x8,%esp
f0102fee:	68 40 50 10 f0       	push   $0xf0105040
f0102ff3:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0102ff6:	50                   	push   %eax
f0102ff7:	e8 78 07 00 00       	call   f0103774 <strcmp>
f0102ffc:	83 c4 10             	add    $0x10,%esp
f0102fff:	85 c0                	test   %eax,%eax
f0103001:	75 0f                	jne    f0103012 <vprintfmt+0x148>
f0103003:	c7 05 6c 85 11 f0 03 	movl   $0x3,0xf011856c
f010300a:	00 00 00 
f010300d:	e9 de fe ff ff       	jmp    f0102ef0 <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "red") == 0) colr = COLR_RED
f0103012:	83 ec 08             	sub    $0x8,%esp
f0103015:	68 44 50 10 f0       	push   $0xf0105044
f010301a:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f010301d:	50                   	push   %eax
f010301e:	e8 51 07 00 00       	call   f0103774 <strcmp>
f0103023:	83 c4 10             	add    $0x10,%esp
f0103026:	85 c0                	test   %eax,%eax
f0103028:	75 0f                	jne    f0103039 <vprintfmt+0x16f>
f010302a:	c7 05 6c 85 11 f0 04 	movl   $0x4,0xf011856c
f0103031:	00 00 00 
f0103034:	e9 b7 fe ff ff       	jmp    f0102ef0 <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "mag") == 0) colr = COLR_MAGENTA
f0103039:	83 ec 08             	sub    $0x8,%esp
f010303c:	68 48 50 10 f0       	push   $0xf0105048
f0103041:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103044:	50                   	push   %eax
f0103045:	e8 2a 07 00 00       	call   f0103774 <strcmp>
f010304a:	83 c4 10             	add    $0x10,%esp
f010304d:	85 c0                	test   %eax,%eax
f010304f:	75 0f                	jne    f0103060 <vprintfmt+0x196>
f0103051:	c7 05 6c 85 11 f0 05 	movl   $0x5,0xf011856c
f0103058:	00 00 00 
f010305b:	e9 90 fe ff ff       	jmp    f0102ef0 <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "brw")== 0) colr = COLR_BROWN
f0103060:	83 ec 08             	sub    $0x8,%esp
f0103063:	68 4c 50 10 f0       	push   $0xf010504c
f0103068:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f010306b:	50                   	push   %eax
f010306c:	e8 03 07 00 00       	call   f0103774 <strcmp>
f0103071:	83 c4 10             	add    $0x10,%esp
f0103074:	85 c0                	test   %eax,%eax
f0103076:	75 0f                	jne    f0103087 <vprintfmt+0x1bd>
f0103078:	c7 05 6c 85 11 f0 06 	movl   $0x6,0xf011856c
f010307f:	00 00 00 
f0103082:	e9 69 fe ff ff       	jmp    f0102ef0 <vprintfmt+0x26>
				else if(strcmp(colorcontrol, "gry") == 0) colr = COLR_GRAY
f0103087:	83 ec 08             	sub    $0x8,%esp
f010308a:	68 50 50 10 f0       	push   $0xf0105050
f010308f:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103092:	50                   	push   %eax
f0103093:	e8 dc 06 00 00       	call   f0103774 <strcmp>
f0103098:	83 c4 10             	add    $0x10,%esp
f010309b:	83 f8 01             	cmp    $0x1,%eax
f010309e:	19 c0                	sbb    %eax,%eax
f01030a0:	83 e0 07             	and    $0x7,%eax
f01030a3:	a3 6c 85 11 f0       	mov    %eax,0xf011856c
f01030a8:	e9 43 fe ff ff       	jmp    f0102ef0 <vprintfmt+0x26>
					colr = COLR_BLACK;
			}
			break;
				
		case 'I':
			highlight = COLR_HIGHLIGHT;
f01030ad:	c7 05 68 85 11 f0 08 	movl   $0x8,0xf0118568
f01030b4:	00 00 00 
			memmove(colorcontrol, fmt, sizeof(unsigned char)*3);
f01030b7:	83 ec 04             	sub    $0x4,%esp
f01030ba:	6a 03                	push   $0x3
f01030bc:	ff 75 d4             	pushl  -0x2c(%ebp)
f01030bf:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f01030c2:	50                   	push   %eax
f01030c3:	e8 94 07 00 00       	call   f010385c <memmove>
			colorcontrol[3] = '\0';
f01030c8:	c6 45 e6 00          	movb   $0x0,-0x1a(%ebp)
			fmt += 3;
f01030cc:	83 c7 04             	add    $0x4,%edi
			if(colorcontrol[0] >= '0' && colorcontrol[0] <= '9'){
f01030cf:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f01030d3:	8d 50 d0             	lea    -0x30(%eax),%edx
f01030d6:	83 c4 10             	add    $0x10,%esp
f01030d9:	80 fa 09             	cmp    $0x9,%dl
f01030dc:	77 29                	ja     f0103107 <vprintfmt+0x23d>
				colr = (colorcontrol[0] - '0') * 100 + (colorcontrol[1] - '0') * 10 + (colorcontrol[2] - '0');
f01030de:	0f be c0             	movsbl %al,%eax
f01030e1:	83 e8 30             	sub    $0x30,%eax
f01030e4:	6b c0 64             	imul   $0x64,%eax,%eax
f01030e7:	0f be 55 e4          	movsbl -0x1c(%ebp),%edx
f01030eb:	8d 94 92 10 ff ff ff 	lea    -0xf0(%edx,%edx,4),%edx
f01030f2:	8d 14 50             	lea    (%eax,%edx,2),%edx
f01030f5:	0f be 45 e5          	movsbl -0x1b(%ebp),%eax
f01030f9:	8d 44 02 d0          	lea    -0x30(%edx,%eax,1),%eax
f01030fd:	a3 6c 85 11 f0       	mov    %eax,0xf011856c
f0103102:	e9 02 01 00 00       	jmp    f0103209 <vprintfmt+0x33f>
			}
			else{
				if(strcmp(colorcontrol, "ble") == 0) colr = COLR_BLUE
f0103107:	83 ec 08             	sub    $0x8,%esp
f010310a:	68 38 50 10 f0       	push   $0xf0105038
f010310f:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103112:	50                   	push   %eax
f0103113:	e8 5c 06 00 00       	call   f0103774 <strcmp>
f0103118:	83 c4 10             	add    $0x10,%esp
f010311b:	85 c0                	test   %eax,%eax
f010311d:	75 0f                	jne    f010312e <vprintfmt+0x264>
f010311f:	c7 05 6c 85 11 f0 01 	movl   $0x1,0xf011856c
f0103126:	00 00 00 
f0103129:	e9 db 00 00 00       	jmp    f0103209 <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "grn") == 0) colr = COLR_GREEN
f010312e:	83 ec 08             	sub    $0x8,%esp
f0103131:	68 3c 50 10 f0       	push   $0xf010503c
f0103136:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103139:	50                   	push   %eax
f010313a:	e8 35 06 00 00       	call   f0103774 <strcmp>
f010313f:	83 c4 10             	add    $0x10,%esp
f0103142:	85 c0                	test   %eax,%eax
f0103144:	75 0f                	jne    f0103155 <vprintfmt+0x28b>
f0103146:	c7 05 6c 85 11 f0 02 	movl   $0x2,0xf011856c
f010314d:	00 00 00 
f0103150:	e9 b4 00 00 00       	jmp    f0103209 <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "cyn") == 0) colr = COLR_CYAN
f0103155:	83 ec 08             	sub    $0x8,%esp
f0103158:	68 40 50 10 f0       	push   $0xf0105040
f010315d:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103160:	50                   	push   %eax
f0103161:	e8 0e 06 00 00       	call   f0103774 <strcmp>
f0103166:	83 c4 10             	add    $0x10,%esp
f0103169:	85 c0                	test   %eax,%eax
f010316b:	75 0f                	jne    f010317c <vprintfmt+0x2b2>
f010316d:	c7 05 6c 85 11 f0 03 	movl   $0x3,0xf011856c
f0103174:	00 00 00 
f0103177:	e9 8d 00 00 00       	jmp    f0103209 <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "red") == 0) colr = COLR_RED
f010317c:	83 ec 08             	sub    $0x8,%esp
f010317f:	68 44 50 10 f0       	push   $0xf0105044
f0103184:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f0103187:	50                   	push   %eax
f0103188:	e8 e7 05 00 00       	call   f0103774 <strcmp>
f010318d:	83 c4 10             	add    $0x10,%esp
f0103190:	85 c0                	test   %eax,%eax
f0103192:	75 0c                	jne    f01031a0 <vprintfmt+0x2d6>
f0103194:	c7 05 6c 85 11 f0 04 	movl   $0x4,0xf011856c
f010319b:	00 00 00 
f010319e:	eb 69                	jmp    f0103209 <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "mag") == 0) colr = COLR_MAGENTA
f01031a0:	83 ec 08             	sub    $0x8,%esp
f01031a3:	68 48 50 10 f0       	push   $0xf0105048
f01031a8:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f01031ab:	50                   	push   %eax
f01031ac:	e8 c3 05 00 00       	call   f0103774 <strcmp>
f01031b1:	83 c4 10             	add    $0x10,%esp
f01031b4:	85 c0                	test   %eax,%eax
f01031b6:	75 0c                	jne    f01031c4 <vprintfmt+0x2fa>
f01031b8:	c7 05 6c 85 11 f0 05 	movl   $0x5,0xf011856c
f01031bf:	00 00 00 
f01031c2:	eb 45                	jmp    f0103209 <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "brw")== 0) colr = COLR_BROWN
f01031c4:	83 ec 08             	sub    $0x8,%esp
f01031c7:	68 4c 50 10 f0       	push   $0xf010504c
f01031cc:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f01031cf:	50                   	push   %eax
f01031d0:	e8 9f 05 00 00       	call   f0103774 <strcmp>
f01031d5:	83 c4 10             	add    $0x10,%esp
f01031d8:	85 c0                	test   %eax,%eax
f01031da:	75 0c                	jne    f01031e8 <vprintfmt+0x31e>
f01031dc:	c7 05 6c 85 11 f0 06 	movl   $0x6,0xf011856c
f01031e3:	00 00 00 
f01031e6:	eb 21                	jmp    f0103209 <vprintfmt+0x33f>
				else if(strcmp(colorcontrol, "gry") == 0) colr = COLR_GRAY
f01031e8:	83 ec 08             	sub    $0x8,%esp
f01031eb:	68 50 50 10 f0       	push   $0xf0105050
f01031f0:	8d 45 e3             	lea    -0x1d(%ebp),%eax
f01031f3:	50                   	push   %eax
f01031f4:	e8 7b 05 00 00       	call   f0103774 <strcmp>
f01031f9:	83 c4 10             	add    $0x10,%esp
f01031fc:	83 f8 01             	cmp    $0x1,%eax
f01031ff:	19 c0                	sbb    %eax,%eax
f0103201:	83 e0 07             	and    $0x7,%eax
f0103204:	a3 6c 85 11 f0       	mov    %eax,0xf011856c
				else
					colr = COLR_BLACK;
			}
			colr |= highlight;
f0103209:	a1 68 85 11 f0       	mov    0xf0118568,%eax
f010320e:	09 05 6c 85 11 f0    	or     %eax,0xf011856c
			break;
f0103214:	e9 d7 fc ff ff       	jmp    f0102ef0 <vprintfmt+0x26>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103219:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010321c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103221:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103224:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103227:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f010322b:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f010322e:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0103231:	83 fa 09             	cmp    $0x9,%edx
f0103234:	77 3f                	ja     f0103275 <vprintfmt+0x3ab>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103236:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103239:	eb e9                	jmp    f0103224 <vprintfmt+0x35a>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f010323b:	8b 45 14             	mov    0x14(%ebp),%eax
f010323e:	8d 48 04             	lea    0x4(%eax),%ecx
f0103241:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103244:	8b 00                	mov    (%eax),%eax
f0103246:	89 45 c0             	mov    %eax,-0x40(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103249:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f010324c:	eb 2d                	jmp    f010327b <vprintfmt+0x3b1>
f010324e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103251:	85 c0                	test   %eax,%eax
f0103253:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103258:	0f 49 c8             	cmovns %eax,%ecx
f010325b:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010325e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103261:	e9 bd fc ff ff       	jmp    f0102f23 <vprintfmt+0x59>
f0103266:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103269:	c7 45 c8 01 00 00 00 	movl   $0x1,-0x38(%ebp)
			goto reswitch;
f0103270:	e9 ae fc ff ff       	jmp    f0102f23 <vprintfmt+0x59>
f0103275:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103278:	89 45 c0             	mov    %eax,-0x40(%ebp)

		process_precision:
			if (width < 0)
f010327b:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f010327f:	0f 89 9e fc ff ff    	jns    f0102f23 <vprintfmt+0x59>
				width = precision, precision = -1;
f0103285:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0103288:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010328b:	c7 45 c0 ff ff ff ff 	movl   $0xffffffff,-0x40(%ebp)
f0103292:	e9 8c fc ff ff       	jmp    f0102f23 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103297:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010329a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010329d:	e9 81 fc ff ff       	jmp    f0102f23 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01032a2:	8b 45 14             	mov    0x14(%ebp),%eax
f01032a5:	8d 50 04             	lea    0x4(%eax),%edx
f01032a8:	89 55 14             	mov    %edx,0x14(%ebp)
f01032ab:	83 ec 08             	sub    $0x8,%esp
f01032ae:	53                   	push   %ebx
f01032af:	ff 30                	pushl  (%eax)
f01032b1:	ff d6                	call   *%esi
			break;
f01032b3:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032b6:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f01032b9:	e9 32 fc ff ff       	jmp    f0102ef0 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01032be:	8b 45 14             	mov    0x14(%ebp),%eax
f01032c1:	8d 50 04             	lea    0x4(%eax),%edx
f01032c4:	89 55 14             	mov    %edx,0x14(%ebp)
f01032c7:	8b 00                	mov    (%eax),%eax
f01032c9:	99                   	cltd   
f01032ca:	31 d0                	xor    %edx,%eax
f01032cc:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01032ce:	83 f8 07             	cmp    $0x7,%eax
f01032d1:	7f 0b                	jg     f01032de <vprintfmt+0x414>
f01032d3:	8b 14 85 20 52 10 f0 	mov    -0xfefade0(,%eax,4),%edx
f01032da:	85 d2                	test   %edx,%edx
f01032dc:	75 18                	jne    f01032f6 <vprintfmt+0x42c>
				printfmt(putch, putdat, "error %d", err);
f01032de:	50                   	push   %eax
f01032df:	68 54 50 10 f0       	push   $0xf0105054
f01032e4:	53                   	push   %ebx
f01032e5:	56                   	push   %esi
f01032e6:	e8 c2 fb ff ff       	call   f0102ead <printfmt>
f01032eb:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032ee:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01032f1:	e9 fa fb ff ff       	jmp    f0102ef0 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f01032f6:	52                   	push   %edx
f01032f7:	68 36 4d 10 f0       	push   $0xf0104d36
f01032fc:	53                   	push   %ebx
f01032fd:	56                   	push   %esi
f01032fe:	e8 aa fb ff ff       	call   f0102ead <printfmt>
f0103303:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103306:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103309:	e9 e2 fb ff ff       	jmp    f0102ef0 <vprintfmt+0x26>
f010330e:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0103311:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103314:	89 45 bc             	mov    %eax,-0x44(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103317:	8b 45 14             	mov    0x14(%ebp),%eax
f010331a:	8d 48 04             	lea    0x4(%eax),%ecx
f010331d:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103320:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103322:	85 ff                	test   %edi,%edi
f0103324:	b8 31 50 10 f0       	mov    $0xf0105031,%eax
f0103329:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010332c:	80 7d c4 2d          	cmpb   $0x2d,-0x3c(%ebp)
f0103330:	0f 84 92 00 00 00    	je     f01033c8 <vprintfmt+0x4fe>
f0103336:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
f010333a:	0f 8e 96 00 00 00    	jle    f01033d6 <vprintfmt+0x50c>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103340:	83 ec 08             	sub    $0x8,%esp
f0103343:	52                   	push   %edx
f0103344:	57                   	push   %edi
f0103345:	e8 5f 03 00 00       	call   f01036a9 <strnlen>
f010334a:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f010334d:	29 c1                	sub    %eax,%ecx
f010334f:	89 4d bc             	mov    %ecx,-0x44(%ebp)
f0103352:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103355:	0f be 45 c4          	movsbl -0x3c(%ebp),%eax
f0103359:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010335c:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f010335f:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103361:	eb 0f                	jmp    f0103372 <vprintfmt+0x4a8>
					putch(padc, putdat);
f0103363:	83 ec 08             	sub    $0x8,%esp
f0103366:	53                   	push   %ebx
f0103367:	ff 75 d0             	pushl  -0x30(%ebp)
f010336a:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010336c:	83 ef 01             	sub    $0x1,%edi
f010336f:	83 c4 10             	add    $0x10,%esp
f0103372:	85 ff                	test   %edi,%edi
f0103374:	7f ed                	jg     f0103363 <vprintfmt+0x499>
f0103376:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0103379:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f010337c:	85 c9                	test   %ecx,%ecx
f010337e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103383:	0f 49 c1             	cmovns %ecx,%eax
f0103386:	29 c1                	sub    %eax,%ecx
f0103388:	89 75 08             	mov    %esi,0x8(%ebp)
f010338b:	8b 75 c0             	mov    -0x40(%ebp),%esi
f010338e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103391:	89 cb                	mov    %ecx,%ebx
f0103393:	eb 4d                	jmp    f01033e2 <vprintfmt+0x518>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103395:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
f0103399:	74 1b                	je     f01033b6 <vprintfmt+0x4ec>
f010339b:	0f be c0             	movsbl %al,%eax
f010339e:	83 e8 20             	sub    $0x20,%eax
f01033a1:	83 f8 5e             	cmp    $0x5e,%eax
f01033a4:	76 10                	jbe    f01033b6 <vprintfmt+0x4ec>
					putch('?', putdat);
f01033a6:	83 ec 08             	sub    $0x8,%esp
f01033a9:	ff 75 0c             	pushl  0xc(%ebp)
f01033ac:	6a 3f                	push   $0x3f
f01033ae:	ff 55 08             	call   *0x8(%ebp)
f01033b1:	83 c4 10             	add    $0x10,%esp
f01033b4:	eb 0d                	jmp    f01033c3 <vprintfmt+0x4f9>
				else
					putch(ch, putdat);
f01033b6:	83 ec 08             	sub    $0x8,%esp
f01033b9:	ff 75 0c             	pushl  0xc(%ebp)
f01033bc:	52                   	push   %edx
f01033bd:	ff 55 08             	call   *0x8(%ebp)
f01033c0:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01033c3:	83 eb 01             	sub    $0x1,%ebx
f01033c6:	eb 1a                	jmp    f01033e2 <vprintfmt+0x518>
f01033c8:	89 75 08             	mov    %esi,0x8(%ebp)
f01033cb:	8b 75 c0             	mov    -0x40(%ebp),%esi
f01033ce:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01033d1:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f01033d4:	eb 0c                	jmp    f01033e2 <vprintfmt+0x518>
f01033d6:	89 75 08             	mov    %esi,0x8(%ebp)
f01033d9:	8b 75 c0             	mov    -0x40(%ebp),%esi
f01033dc:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01033df:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f01033e2:	83 c7 01             	add    $0x1,%edi
f01033e5:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01033e9:	0f be d0             	movsbl %al,%edx
f01033ec:	85 d2                	test   %edx,%edx
f01033ee:	74 23                	je     f0103413 <vprintfmt+0x549>
f01033f0:	85 f6                	test   %esi,%esi
f01033f2:	78 a1                	js     f0103395 <vprintfmt+0x4cb>
f01033f4:	83 ee 01             	sub    $0x1,%esi
f01033f7:	79 9c                	jns    f0103395 <vprintfmt+0x4cb>
f01033f9:	89 df                	mov    %ebx,%edi
f01033fb:	8b 75 08             	mov    0x8(%ebp),%esi
f01033fe:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103401:	eb 18                	jmp    f010341b <vprintfmt+0x551>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103403:	83 ec 08             	sub    $0x8,%esp
f0103406:	53                   	push   %ebx
f0103407:	6a 20                	push   $0x20
f0103409:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010340b:	83 ef 01             	sub    $0x1,%edi
f010340e:	83 c4 10             	add    $0x10,%esp
f0103411:	eb 08                	jmp    f010341b <vprintfmt+0x551>
f0103413:	89 df                	mov    %ebx,%edi
f0103415:	8b 75 08             	mov    0x8(%ebp),%esi
f0103418:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010341b:	85 ff                	test   %edi,%edi
f010341d:	7f e4                	jg     f0103403 <vprintfmt+0x539>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010341f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103422:	e9 c9 fa ff ff       	jmp    f0102ef0 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103427:	83 fa 01             	cmp    $0x1,%edx
f010342a:	7e 16                	jle    f0103442 <vprintfmt+0x578>
		return va_arg(*ap, long long);
f010342c:	8b 45 14             	mov    0x14(%ebp),%eax
f010342f:	8d 50 08             	lea    0x8(%eax),%edx
f0103432:	89 55 14             	mov    %edx,0x14(%ebp)
f0103435:	8b 50 04             	mov    0x4(%eax),%edx
f0103438:	8b 00                	mov    (%eax),%eax
f010343a:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010343d:	89 55 cc             	mov    %edx,-0x34(%ebp)
f0103440:	eb 32                	jmp    f0103474 <vprintfmt+0x5aa>
	else if (lflag)
f0103442:	85 d2                	test   %edx,%edx
f0103444:	74 18                	je     f010345e <vprintfmt+0x594>
		return va_arg(*ap, long);
f0103446:	8b 45 14             	mov    0x14(%ebp),%eax
f0103449:	8d 50 04             	lea    0x4(%eax),%edx
f010344c:	89 55 14             	mov    %edx,0x14(%ebp)
f010344f:	8b 00                	mov    (%eax),%eax
f0103451:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0103454:	89 c1                	mov    %eax,%ecx
f0103456:	c1 f9 1f             	sar    $0x1f,%ecx
f0103459:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f010345c:	eb 16                	jmp    f0103474 <vprintfmt+0x5aa>
	else
		return va_arg(*ap, int);
f010345e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103461:	8d 50 04             	lea    0x4(%eax),%edx
f0103464:	89 55 14             	mov    %edx,0x14(%ebp)
f0103467:	8b 00                	mov    (%eax),%eax
f0103469:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010346c:	89 c1                	mov    %eax,%ecx
f010346e:	c1 f9 1f             	sar    $0x1f,%ecx
f0103471:	89 4d cc             	mov    %ecx,-0x34(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103474:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0103477:	8b 55 cc             	mov    -0x34(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010347a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f010347f:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0103483:	79 74                	jns    f01034f9 <vprintfmt+0x62f>
				putch('-', putdat);
f0103485:	83 ec 08             	sub    $0x8,%esp
f0103488:	53                   	push   %ebx
f0103489:	6a 2d                	push   $0x2d
f010348b:	ff d6                	call   *%esi
				num = -(long long) num;
f010348d:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0103490:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0103493:	f7 d8                	neg    %eax
f0103495:	83 d2 00             	adc    $0x0,%edx
f0103498:	f7 da                	neg    %edx
f010349a:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f010349d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01034a2:	eb 55                	jmp    f01034f9 <vprintfmt+0x62f>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01034a4:	8d 45 14             	lea    0x14(%ebp),%eax
f01034a7:	e8 aa f9 ff ff       	call   f0102e56 <getuint>
			base = 10;
f01034ac:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01034b1:	eb 46                	jmp    f01034f9 <vprintfmt+0x62f>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01034b3:	8d 45 14             	lea    0x14(%ebp),%eax
f01034b6:	e8 9b f9 ff ff       	call   f0102e56 <getuint>
			base = 8;
f01034bb:	b9 08 00 00 00       	mov    $0x8,%ecx

			goto number;
f01034c0:	eb 37                	jmp    f01034f9 <vprintfmt+0x62f>
		// pointer
		case 'p':
			putch('0', putdat);
f01034c2:	83 ec 08             	sub    $0x8,%esp
f01034c5:	53                   	push   %ebx
f01034c6:	6a 30                	push   $0x30
f01034c8:	ff d6                	call   *%esi
			putch('x', putdat);
f01034ca:	83 c4 08             	add    $0x8,%esp
f01034cd:	53                   	push   %ebx
f01034ce:	6a 78                	push   $0x78
f01034d0:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01034d2:	8b 45 14             	mov    0x14(%ebp),%eax
f01034d5:	8d 50 04             	lea    0x4(%eax),%edx
f01034d8:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01034db:	8b 00                	mov    (%eax),%eax
f01034dd:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01034e2:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01034e5:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01034ea:	eb 0d                	jmp    f01034f9 <vprintfmt+0x62f>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01034ec:	8d 45 14             	lea    0x14(%ebp),%eax
f01034ef:	e8 62 f9 ff ff       	call   f0102e56 <getuint>
			base = 16;
f01034f4:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01034f9:	83 ec 0c             	sub    $0xc,%esp
f01034fc:	0f be 7d c4          	movsbl -0x3c(%ebp),%edi
f0103500:	57                   	push   %edi
f0103501:	ff 75 d0             	pushl  -0x30(%ebp)
f0103504:	51                   	push   %ecx
f0103505:	52                   	push   %edx
f0103506:	50                   	push   %eax
f0103507:	89 da                	mov    %ebx,%edx
f0103509:	89 f0                	mov    %esi,%eax
f010350b:	e8 9c f8 ff ff       	call   f0102dac <printnum>
			break;
f0103510:	83 c4 20             	add    $0x20,%esp
f0103513:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103516:	e9 d5 f9 ff ff       	jmp    f0102ef0 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010351b:	83 ec 08             	sub    $0x8,%esp
f010351e:	53                   	push   %ebx
f010351f:	51                   	push   %ecx
f0103520:	ff d6                	call   *%esi
			break;
f0103522:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103525:	8b 7d d4             	mov    -0x2c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103528:	e9 c3 f9 ff ff       	jmp    f0102ef0 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010352d:	83 ec 08             	sub    $0x8,%esp
f0103530:	53                   	push   %ebx
f0103531:	6a 25                	push   $0x25
f0103533:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103535:	83 c4 10             	add    $0x10,%esp
f0103538:	eb 03                	jmp    f010353d <vprintfmt+0x673>
f010353a:	83 ef 01             	sub    $0x1,%edi
f010353d:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103541:	75 f7                	jne    f010353a <vprintfmt+0x670>
f0103543:	e9 a8 f9 ff ff       	jmp    f0102ef0 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0103548:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010354b:	5b                   	pop    %ebx
f010354c:	5e                   	pop    %esi
f010354d:	5f                   	pop    %edi
f010354e:	5d                   	pop    %ebp
f010354f:	c3                   	ret    

f0103550 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103550:	55                   	push   %ebp
f0103551:	89 e5                	mov    %esp,%ebp
f0103553:	83 ec 18             	sub    $0x18,%esp
f0103556:	8b 45 08             	mov    0x8(%ebp),%eax
f0103559:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010355c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010355f:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103563:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103566:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010356d:	85 c0                	test   %eax,%eax
f010356f:	74 26                	je     f0103597 <vsnprintf+0x47>
f0103571:	85 d2                	test   %edx,%edx
f0103573:	7e 22                	jle    f0103597 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103575:	ff 75 14             	pushl  0x14(%ebp)
f0103578:	ff 75 10             	pushl  0x10(%ebp)
f010357b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010357e:	50                   	push   %eax
f010357f:	68 90 2e 10 f0       	push   $0xf0102e90
f0103584:	e8 41 f9 ff ff       	call   f0102eca <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103589:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010358c:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010358f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103592:	83 c4 10             	add    $0x10,%esp
f0103595:	eb 05                	jmp    f010359c <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103597:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010359c:	c9                   	leave  
f010359d:	c3                   	ret    

f010359e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010359e:	55                   	push   %ebp
f010359f:	89 e5                	mov    %esp,%ebp
f01035a1:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01035a4:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01035a7:	50                   	push   %eax
f01035a8:	ff 75 10             	pushl  0x10(%ebp)
f01035ab:	ff 75 0c             	pushl  0xc(%ebp)
f01035ae:	ff 75 08             	pushl  0x8(%ebp)
f01035b1:	e8 9a ff ff ff       	call   f0103550 <vsnprintf>
	va_end(ap);

	return rc;
}
f01035b6:	c9                   	leave  
f01035b7:	c3                   	ret    

f01035b8 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01035b8:	55                   	push   %ebp
f01035b9:	89 e5                	mov    %esp,%ebp
f01035bb:	57                   	push   %edi
f01035bc:	56                   	push   %esi
f01035bd:	53                   	push   %ebx
f01035be:	83 ec 0c             	sub    $0xc,%esp
f01035c1:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01035c4:	85 c0                	test   %eax,%eax
f01035c6:	74 11                	je     f01035d9 <readline+0x21>
		cprintf("%s", prompt);
f01035c8:	83 ec 08             	sub    $0x8,%esp
f01035cb:	50                   	push   %eax
f01035cc:	68 36 4d 10 f0       	push   $0xf0104d36
f01035d1:	e8 7b f4 ff ff       	call   f0102a51 <cprintf>
f01035d6:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01035d9:	83 ec 0c             	sub    $0xc,%esp
f01035dc:	6a 00                	push   $0x0
f01035de:	e8 1d d0 ff ff       	call   f0100600 <iscons>
f01035e3:	89 c7                	mov    %eax,%edi
f01035e5:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01035e8:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01035ed:	e8 fd cf ff ff       	call   f01005ef <getchar>
f01035f2:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01035f4:	85 c0                	test   %eax,%eax
f01035f6:	79 18                	jns    f0103610 <readline+0x58>
			cprintf("read error: %e\n", c);
f01035f8:	83 ec 08             	sub    $0x8,%esp
f01035fb:	50                   	push   %eax
f01035fc:	68 40 52 10 f0       	push   $0xf0105240
f0103601:	e8 4b f4 ff ff       	call   f0102a51 <cprintf>
			return NULL;
f0103606:	83 c4 10             	add    $0x10,%esp
f0103609:	b8 00 00 00 00       	mov    $0x0,%eax
f010360e:	eb 79                	jmp    f0103689 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103610:	83 f8 7f             	cmp    $0x7f,%eax
f0103613:	0f 94 c2             	sete   %dl
f0103616:	83 f8 08             	cmp    $0x8,%eax
f0103619:	0f 94 c0             	sete   %al
f010361c:	08 c2                	or     %al,%dl
f010361e:	74 1a                	je     f010363a <readline+0x82>
f0103620:	85 f6                	test   %esi,%esi
f0103622:	7e 16                	jle    f010363a <readline+0x82>
			if (echoing)
f0103624:	85 ff                	test   %edi,%edi
f0103626:	74 0d                	je     f0103635 <readline+0x7d>
				cputchar('\b');
f0103628:	83 ec 0c             	sub    $0xc,%esp
f010362b:	6a 08                	push   $0x8
f010362d:	e8 ad cf ff ff       	call   f01005df <cputchar>
f0103632:	83 c4 10             	add    $0x10,%esp
			i--;
f0103635:	83 ee 01             	sub    $0x1,%esi
f0103638:	eb b3                	jmp    f01035ed <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010363a:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103640:	7f 20                	jg     f0103662 <readline+0xaa>
f0103642:	83 fb 1f             	cmp    $0x1f,%ebx
f0103645:	7e 1b                	jle    f0103662 <readline+0xaa>
			if (echoing)
f0103647:	85 ff                	test   %edi,%edi
f0103649:	74 0c                	je     f0103657 <readline+0x9f>
				cputchar(c);
f010364b:	83 ec 0c             	sub    $0xc,%esp
f010364e:	53                   	push   %ebx
f010364f:	e8 8b cf ff ff       	call   f01005df <cputchar>
f0103654:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103657:	88 9e 80 85 11 f0    	mov    %bl,-0xfee7a80(%esi)
f010365d:	8d 76 01             	lea    0x1(%esi),%esi
f0103660:	eb 8b                	jmp    f01035ed <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103662:	83 fb 0d             	cmp    $0xd,%ebx
f0103665:	74 05                	je     f010366c <readline+0xb4>
f0103667:	83 fb 0a             	cmp    $0xa,%ebx
f010366a:	75 81                	jne    f01035ed <readline+0x35>
			if (echoing)
f010366c:	85 ff                	test   %edi,%edi
f010366e:	74 0d                	je     f010367d <readline+0xc5>
				cputchar('\n');
f0103670:	83 ec 0c             	sub    $0xc,%esp
f0103673:	6a 0a                	push   $0xa
f0103675:	e8 65 cf ff ff       	call   f01005df <cputchar>
f010367a:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010367d:	c6 86 80 85 11 f0 00 	movb   $0x0,-0xfee7a80(%esi)
			return buf;
f0103684:	b8 80 85 11 f0       	mov    $0xf0118580,%eax
		}
	}
}
f0103689:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010368c:	5b                   	pop    %ebx
f010368d:	5e                   	pop    %esi
f010368e:	5f                   	pop    %edi
f010368f:	5d                   	pop    %ebp
f0103690:	c3                   	ret    

f0103691 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103691:	55                   	push   %ebp
f0103692:	89 e5                	mov    %esp,%ebp
f0103694:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103697:	b8 00 00 00 00       	mov    $0x0,%eax
f010369c:	eb 03                	jmp    f01036a1 <strlen+0x10>
		n++;
f010369e:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01036a1:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01036a5:	75 f7                	jne    f010369e <strlen+0xd>
		n++;
	return n;
}
f01036a7:	5d                   	pop    %ebp
f01036a8:	c3                   	ret    

f01036a9 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01036a9:	55                   	push   %ebp
f01036aa:	89 e5                	mov    %esp,%ebp
f01036ac:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01036af:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01036b2:	ba 00 00 00 00       	mov    $0x0,%edx
f01036b7:	eb 03                	jmp    f01036bc <strnlen+0x13>
		n++;
f01036b9:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01036bc:	39 c2                	cmp    %eax,%edx
f01036be:	74 08                	je     f01036c8 <strnlen+0x1f>
f01036c0:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01036c4:	75 f3                	jne    f01036b9 <strnlen+0x10>
f01036c6:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01036c8:	5d                   	pop    %ebp
f01036c9:	c3                   	ret    

f01036ca <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01036ca:	55                   	push   %ebp
f01036cb:	89 e5                	mov    %esp,%ebp
f01036cd:	53                   	push   %ebx
f01036ce:	8b 45 08             	mov    0x8(%ebp),%eax
f01036d1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01036d4:	89 c2                	mov    %eax,%edx
f01036d6:	83 c2 01             	add    $0x1,%edx
f01036d9:	83 c1 01             	add    $0x1,%ecx
f01036dc:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01036e0:	88 5a ff             	mov    %bl,-0x1(%edx)
f01036e3:	84 db                	test   %bl,%bl
f01036e5:	75 ef                	jne    f01036d6 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01036e7:	5b                   	pop    %ebx
f01036e8:	5d                   	pop    %ebp
f01036e9:	c3                   	ret    

f01036ea <strcat>:

char *
strcat(char *dst, const char *src)
{
f01036ea:	55                   	push   %ebp
f01036eb:	89 e5                	mov    %esp,%ebp
f01036ed:	53                   	push   %ebx
f01036ee:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01036f1:	53                   	push   %ebx
f01036f2:	e8 9a ff ff ff       	call   f0103691 <strlen>
f01036f7:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01036fa:	ff 75 0c             	pushl  0xc(%ebp)
f01036fd:	01 d8                	add    %ebx,%eax
f01036ff:	50                   	push   %eax
f0103700:	e8 c5 ff ff ff       	call   f01036ca <strcpy>
	return dst;
}
f0103705:	89 d8                	mov    %ebx,%eax
f0103707:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010370a:	c9                   	leave  
f010370b:	c3                   	ret    

f010370c <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010370c:	55                   	push   %ebp
f010370d:	89 e5                	mov    %esp,%ebp
f010370f:	56                   	push   %esi
f0103710:	53                   	push   %ebx
f0103711:	8b 75 08             	mov    0x8(%ebp),%esi
f0103714:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103717:	89 f3                	mov    %esi,%ebx
f0103719:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010371c:	89 f2                	mov    %esi,%edx
f010371e:	eb 0f                	jmp    f010372f <strncpy+0x23>
		*dst++ = *src;
f0103720:	83 c2 01             	add    $0x1,%edx
f0103723:	0f b6 01             	movzbl (%ecx),%eax
f0103726:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103729:	80 39 01             	cmpb   $0x1,(%ecx)
f010372c:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010372f:	39 da                	cmp    %ebx,%edx
f0103731:	75 ed                	jne    f0103720 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103733:	89 f0                	mov    %esi,%eax
f0103735:	5b                   	pop    %ebx
f0103736:	5e                   	pop    %esi
f0103737:	5d                   	pop    %ebp
f0103738:	c3                   	ret    

f0103739 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103739:	55                   	push   %ebp
f010373a:	89 e5                	mov    %esp,%ebp
f010373c:	56                   	push   %esi
f010373d:	53                   	push   %ebx
f010373e:	8b 75 08             	mov    0x8(%ebp),%esi
f0103741:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103744:	8b 55 10             	mov    0x10(%ebp),%edx
f0103747:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103749:	85 d2                	test   %edx,%edx
f010374b:	74 21                	je     f010376e <strlcpy+0x35>
f010374d:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103751:	89 f2                	mov    %esi,%edx
f0103753:	eb 09                	jmp    f010375e <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103755:	83 c2 01             	add    $0x1,%edx
f0103758:	83 c1 01             	add    $0x1,%ecx
f010375b:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010375e:	39 c2                	cmp    %eax,%edx
f0103760:	74 09                	je     f010376b <strlcpy+0x32>
f0103762:	0f b6 19             	movzbl (%ecx),%ebx
f0103765:	84 db                	test   %bl,%bl
f0103767:	75 ec                	jne    f0103755 <strlcpy+0x1c>
f0103769:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010376b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010376e:	29 f0                	sub    %esi,%eax
}
f0103770:	5b                   	pop    %ebx
f0103771:	5e                   	pop    %esi
f0103772:	5d                   	pop    %ebp
f0103773:	c3                   	ret    

f0103774 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103774:	55                   	push   %ebp
f0103775:	89 e5                	mov    %esp,%ebp
f0103777:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010377a:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010377d:	eb 06                	jmp    f0103785 <strcmp+0x11>
		p++, q++;
f010377f:	83 c1 01             	add    $0x1,%ecx
f0103782:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103785:	0f b6 01             	movzbl (%ecx),%eax
f0103788:	84 c0                	test   %al,%al
f010378a:	74 04                	je     f0103790 <strcmp+0x1c>
f010378c:	3a 02                	cmp    (%edx),%al
f010378e:	74 ef                	je     f010377f <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103790:	0f b6 c0             	movzbl %al,%eax
f0103793:	0f b6 12             	movzbl (%edx),%edx
f0103796:	29 d0                	sub    %edx,%eax
}
f0103798:	5d                   	pop    %ebp
f0103799:	c3                   	ret    

f010379a <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010379a:	55                   	push   %ebp
f010379b:	89 e5                	mov    %esp,%ebp
f010379d:	53                   	push   %ebx
f010379e:	8b 45 08             	mov    0x8(%ebp),%eax
f01037a1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01037a4:	89 c3                	mov    %eax,%ebx
f01037a6:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01037a9:	eb 06                	jmp    f01037b1 <strncmp+0x17>
		n--, p++, q++;
f01037ab:	83 c0 01             	add    $0x1,%eax
f01037ae:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01037b1:	39 d8                	cmp    %ebx,%eax
f01037b3:	74 15                	je     f01037ca <strncmp+0x30>
f01037b5:	0f b6 08             	movzbl (%eax),%ecx
f01037b8:	84 c9                	test   %cl,%cl
f01037ba:	74 04                	je     f01037c0 <strncmp+0x26>
f01037bc:	3a 0a                	cmp    (%edx),%cl
f01037be:	74 eb                	je     f01037ab <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01037c0:	0f b6 00             	movzbl (%eax),%eax
f01037c3:	0f b6 12             	movzbl (%edx),%edx
f01037c6:	29 d0                	sub    %edx,%eax
f01037c8:	eb 05                	jmp    f01037cf <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01037ca:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01037cf:	5b                   	pop    %ebx
f01037d0:	5d                   	pop    %ebp
f01037d1:	c3                   	ret    

f01037d2 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01037d2:	55                   	push   %ebp
f01037d3:	89 e5                	mov    %esp,%ebp
f01037d5:	8b 45 08             	mov    0x8(%ebp),%eax
f01037d8:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01037dc:	eb 07                	jmp    f01037e5 <strchr+0x13>
		if (*s == c)
f01037de:	38 ca                	cmp    %cl,%dl
f01037e0:	74 0f                	je     f01037f1 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01037e2:	83 c0 01             	add    $0x1,%eax
f01037e5:	0f b6 10             	movzbl (%eax),%edx
f01037e8:	84 d2                	test   %dl,%dl
f01037ea:	75 f2                	jne    f01037de <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01037ec:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01037f1:	5d                   	pop    %ebp
f01037f2:	c3                   	ret    

f01037f3 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01037f3:	55                   	push   %ebp
f01037f4:	89 e5                	mov    %esp,%ebp
f01037f6:	8b 45 08             	mov    0x8(%ebp),%eax
f01037f9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01037fd:	eb 03                	jmp    f0103802 <strfind+0xf>
f01037ff:	83 c0 01             	add    $0x1,%eax
f0103802:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103805:	84 d2                	test   %dl,%dl
f0103807:	74 04                	je     f010380d <strfind+0x1a>
f0103809:	38 ca                	cmp    %cl,%dl
f010380b:	75 f2                	jne    f01037ff <strfind+0xc>
			break;
	return (char *) s;
}
f010380d:	5d                   	pop    %ebp
f010380e:	c3                   	ret    

f010380f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010380f:	55                   	push   %ebp
f0103810:	89 e5                	mov    %esp,%ebp
f0103812:	57                   	push   %edi
f0103813:	56                   	push   %esi
f0103814:	53                   	push   %ebx
f0103815:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103818:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010381b:	85 c9                	test   %ecx,%ecx
f010381d:	74 36                	je     f0103855 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010381f:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103825:	75 28                	jne    f010384f <memset+0x40>
f0103827:	f6 c1 03             	test   $0x3,%cl
f010382a:	75 23                	jne    f010384f <memset+0x40>
		c &= 0xFF;
f010382c:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103830:	89 d3                	mov    %edx,%ebx
f0103832:	c1 e3 08             	shl    $0x8,%ebx
f0103835:	89 d6                	mov    %edx,%esi
f0103837:	c1 e6 18             	shl    $0x18,%esi
f010383a:	89 d0                	mov    %edx,%eax
f010383c:	c1 e0 10             	shl    $0x10,%eax
f010383f:	09 f0                	or     %esi,%eax
f0103841:	09 c2                	or     %eax,%edx
f0103843:	89 d0                	mov    %edx,%eax
f0103845:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0103847:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f010384a:	fc                   	cld    
f010384b:	f3 ab                	rep stos %eax,%es:(%edi)
f010384d:	eb 06                	jmp    f0103855 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010384f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103852:	fc                   	cld    
f0103853:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103855:	89 f8                	mov    %edi,%eax
f0103857:	5b                   	pop    %ebx
f0103858:	5e                   	pop    %esi
f0103859:	5f                   	pop    %edi
f010385a:	5d                   	pop    %ebp
f010385b:	c3                   	ret    

f010385c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010385c:	55                   	push   %ebp
f010385d:	89 e5                	mov    %esp,%ebp
f010385f:	57                   	push   %edi
f0103860:	56                   	push   %esi
f0103861:	8b 45 08             	mov    0x8(%ebp),%eax
f0103864:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103867:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010386a:	39 c6                	cmp    %eax,%esi
f010386c:	73 35                	jae    f01038a3 <memmove+0x47>
f010386e:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103871:	39 d0                	cmp    %edx,%eax
f0103873:	73 2e                	jae    f01038a3 <memmove+0x47>
		s += n;
		d += n;
f0103875:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0103878:	89 d6                	mov    %edx,%esi
f010387a:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010387c:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103882:	75 13                	jne    f0103897 <memmove+0x3b>
f0103884:	f6 c1 03             	test   $0x3,%cl
f0103887:	75 0e                	jne    f0103897 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103889:	83 ef 04             	sub    $0x4,%edi
f010388c:	8d 72 fc             	lea    -0x4(%edx),%esi
f010388f:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0103892:	fd                   	std    
f0103893:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103895:	eb 09                	jmp    f01038a0 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103897:	83 ef 01             	sub    $0x1,%edi
f010389a:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010389d:	fd                   	std    
f010389e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01038a0:	fc                   	cld    
f01038a1:	eb 1d                	jmp    f01038c0 <memmove+0x64>
f01038a3:	89 f2                	mov    %esi,%edx
f01038a5:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01038a7:	f6 c2 03             	test   $0x3,%dl
f01038aa:	75 0f                	jne    f01038bb <memmove+0x5f>
f01038ac:	f6 c1 03             	test   $0x3,%cl
f01038af:	75 0a                	jne    f01038bb <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01038b1:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01038b4:	89 c7                	mov    %eax,%edi
f01038b6:	fc                   	cld    
f01038b7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01038b9:	eb 05                	jmp    f01038c0 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01038bb:	89 c7                	mov    %eax,%edi
f01038bd:	fc                   	cld    
f01038be:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01038c0:	5e                   	pop    %esi
f01038c1:	5f                   	pop    %edi
f01038c2:	5d                   	pop    %ebp
f01038c3:	c3                   	ret    

f01038c4 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01038c4:	55                   	push   %ebp
f01038c5:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01038c7:	ff 75 10             	pushl  0x10(%ebp)
f01038ca:	ff 75 0c             	pushl  0xc(%ebp)
f01038cd:	ff 75 08             	pushl  0x8(%ebp)
f01038d0:	e8 87 ff ff ff       	call   f010385c <memmove>
}
f01038d5:	c9                   	leave  
f01038d6:	c3                   	ret    

f01038d7 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01038d7:	55                   	push   %ebp
f01038d8:	89 e5                	mov    %esp,%ebp
f01038da:	56                   	push   %esi
f01038db:	53                   	push   %ebx
f01038dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01038df:	8b 55 0c             	mov    0xc(%ebp),%edx
f01038e2:	89 c6                	mov    %eax,%esi
f01038e4:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01038e7:	eb 1a                	jmp    f0103903 <memcmp+0x2c>
		if (*s1 != *s2)
f01038e9:	0f b6 08             	movzbl (%eax),%ecx
f01038ec:	0f b6 1a             	movzbl (%edx),%ebx
f01038ef:	38 d9                	cmp    %bl,%cl
f01038f1:	74 0a                	je     f01038fd <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01038f3:	0f b6 c1             	movzbl %cl,%eax
f01038f6:	0f b6 db             	movzbl %bl,%ebx
f01038f9:	29 d8                	sub    %ebx,%eax
f01038fb:	eb 0f                	jmp    f010390c <memcmp+0x35>
		s1++, s2++;
f01038fd:	83 c0 01             	add    $0x1,%eax
f0103900:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103903:	39 f0                	cmp    %esi,%eax
f0103905:	75 e2                	jne    f01038e9 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103907:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010390c:	5b                   	pop    %ebx
f010390d:	5e                   	pop    %esi
f010390e:	5d                   	pop    %ebp
f010390f:	c3                   	ret    

f0103910 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103910:	55                   	push   %ebp
f0103911:	89 e5                	mov    %esp,%ebp
f0103913:	8b 45 08             	mov    0x8(%ebp),%eax
f0103916:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103919:	89 c2                	mov    %eax,%edx
f010391b:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010391e:	eb 07                	jmp    f0103927 <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103920:	38 08                	cmp    %cl,(%eax)
f0103922:	74 07                	je     f010392b <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103924:	83 c0 01             	add    $0x1,%eax
f0103927:	39 d0                	cmp    %edx,%eax
f0103929:	72 f5                	jb     f0103920 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010392b:	5d                   	pop    %ebp
f010392c:	c3                   	ret    

f010392d <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010392d:	55                   	push   %ebp
f010392e:	89 e5                	mov    %esp,%ebp
f0103930:	57                   	push   %edi
f0103931:	56                   	push   %esi
f0103932:	53                   	push   %ebx
f0103933:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103936:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103939:	eb 03                	jmp    f010393e <strtol+0x11>
		s++;
f010393b:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010393e:	0f b6 01             	movzbl (%ecx),%eax
f0103941:	3c 09                	cmp    $0x9,%al
f0103943:	74 f6                	je     f010393b <strtol+0xe>
f0103945:	3c 20                	cmp    $0x20,%al
f0103947:	74 f2                	je     f010393b <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103949:	3c 2b                	cmp    $0x2b,%al
f010394b:	75 0a                	jne    f0103957 <strtol+0x2a>
		s++;
f010394d:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103950:	bf 00 00 00 00       	mov    $0x0,%edi
f0103955:	eb 10                	jmp    f0103967 <strtol+0x3a>
f0103957:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010395c:	3c 2d                	cmp    $0x2d,%al
f010395e:	75 07                	jne    f0103967 <strtol+0x3a>
		s++, neg = 1;
f0103960:	8d 49 01             	lea    0x1(%ecx),%ecx
f0103963:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103967:	85 db                	test   %ebx,%ebx
f0103969:	0f 94 c0             	sete   %al
f010396c:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103972:	75 19                	jne    f010398d <strtol+0x60>
f0103974:	80 39 30             	cmpb   $0x30,(%ecx)
f0103977:	75 14                	jne    f010398d <strtol+0x60>
f0103979:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010397d:	0f 85 82 00 00 00    	jne    f0103a05 <strtol+0xd8>
		s += 2, base = 16;
f0103983:	83 c1 02             	add    $0x2,%ecx
f0103986:	bb 10 00 00 00       	mov    $0x10,%ebx
f010398b:	eb 16                	jmp    f01039a3 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f010398d:	84 c0                	test   %al,%al
f010398f:	74 12                	je     f01039a3 <strtol+0x76>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103991:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103996:	80 39 30             	cmpb   $0x30,(%ecx)
f0103999:	75 08                	jne    f01039a3 <strtol+0x76>
		s++, base = 8;
f010399b:	83 c1 01             	add    $0x1,%ecx
f010399e:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01039a3:	b8 00 00 00 00       	mov    $0x0,%eax
f01039a8:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01039ab:	0f b6 11             	movzbl (%ecx),%edx
f01039ae:	8d 72 d0             	lea    -0x30(%edx),%esi
f01039b1:	89 f3                	mov    %esi,%ebx
f01039b3:	80 fb 09             	cmp    $0x9,%bl
f01039b6:	77 08                	ja     f01039c0 <strtol+0x93>
			dig = *s - '0';
f01039b8:	0f be d2             	movsbl %dl,%edx
f01039bb:	83 ea 30             	sub    $0x30,%edx
f01039be:	eb 22                	jmp    f01039e2 <strtol+0xb5>
		else if (*s >= 'a' && *s <= 'z')
f01039c0:	8d 72 9f             	lea    -0x61(%edx),%esi
f01039c3:	89 f3                	mov    %esi,%ebx
f01039c5:	80 fb 19             	cmp    $0x19,%bl
f01039c8:	77 08                	ja     f01039d2 <strtol+0xa5>
			dig = *s - 'a' + 10;
f01039ca:	0f be d2             	movsbl %dl,%edx
f01039cd:	83 ea 57             	sub    $0x57,%edx
f01039d0:	eb 10                	jmp    f01039e2 <strtol+0xb5>
		else if (*s >= 'A' && *s <= 'Z')
f01039d2:	8d 72 bf             	lea    -0x41(%edx),%esi
f01039d5:	89 f3                	mov    %esi,%ebx
f01039d7:	80 fb 19             	cmp    $0x19,%bl
f01039da:	77 16                	ja     f01039f2 <strtol+0xc5>
			dig = *s - 'A' + 10;
f01039dc:	0f be d2             	movsbl %dl,%edx
f01039df:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01039e2:	3b 55 10             	cmp    0x10(%ebp),%edx
f01039e5:	7d 0f                	jge    f01039f6 <strtol+0xc9>
			break;
		s++, val = (val * base) + dig;
f01039e7:	83 c1 01             	add    $0x1,%ecx
f01039ea:	0f af 45 10          	imul   0x10(%ebp),%eax
f01039ee:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01039f0:	eb b9                	jmp    f01039ab <strtol+0x7e>
f01039f2:	89 c2                	mov    %eax,%edx
f01039f4:	eb 02                	jmp    f01039f8 <strtol+0xcb>
f01039f6:	89 c2                	mov    %eax,%edx

	if (endptr)
f01039f8:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01039fc:	74 0d                	je     f0103a0b <strtol+0xde>
		*endptr = (char *) s;
f01039fe:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103a01:	89 0e                	mov    %ecx,(%esi)
f0103a03:	eb 06                	jmp    f0103a0b <strtol+0xde>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103a05:	84 c0                	test   %al,%al
f0103a07:	75 92                	jne    f010399b <strtol+0x6e>
f0103a09:	eb 98                	jmp    f01039a3 <strtol+0x76>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103a0b:	f7 da                	neg    %edx
f0103a0d:	85 ff                	test   %edi,%edi
f0103a0f:	0f 45 c2             	cmovne %edx,%eax
}
f0103a12:	5b                   	pop    %ebx
f0103a13:	5e                   	pop    %esi
f0103a14:	5f                   	pop    %edi
f0103a15:	5d                   	pop    %ebp
f0103a16:	c3                   	ret    
f0103a17:	66 90                	xchg   %ax,%ax
f0103a19:	66 90                	xchg   %ax,%ax
f0103a1b:	66 90                	xchg   %ax,%ax
f0103a1d:	66 90                	xchg   %ax,%ax
f0103a1f:	90                   	nop

f0103a20 <__udivdi3>:
f0103a20:	55                   	push   %ebp
f0103a21:	57                   	push   %edi
f0103a22:	56                   	push   %esi
f0103a23:	83 ec 10             	sub    $0x10,%esp
f0103a26:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f0103a2a:	8b 7c 24 20          	mov    0x20(%esp),%edi
f0103a2e:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103a32:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103a36:	85 d2                	test   %edx,%edx
f0103a38:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103a3c:	89 34 24             	mov    %esi,(%esp)
f0103a3f:	89 c8                	mov    %ecx,%eax
f0103a41:	75 35                	jne    f0103a78 <__udivdi3+0x58>
f0103a43:	39 f1                	cmp    %esi,%ecx
f0103a45:	0f 87 bd 00 00 00    	ja     f0103b08 <__udivdi3+0xe8>
f0103a4b:	85 c9                	test   %ecx,%ecx
f0103a4d:	89 cd                	mov    %ecx,%ebp
f0103a4f:	75 0b                	jne    f0103a5c <__udivdi3+0x3c>
f0103a51:	b8 01 00 00 00       	mov    $0x1,%eax
f0103a56:	31 d2                	xor    %edx,%edx
f0103a58:	f7 f1                	div    %ecx
f0103a5a:	89 c5                	mov    %eax,%ebp
f0103a5c:	89 f0                	mov    %esi,%eax
f0103a5e:	31 d2                	xor    %edx,%edx
f0103a60:	f7 f5                	div    %ebp
f0103a62:	89 c6                	mov    %eax,%esi
f0103a64:	89 f8                	mov    %edi,%eax
f0103a66:	f7 f5                	div    %ebp
f0103a68:	89 f2                	mov    %esi,%edx
f0103a6a:	83 c4 10             	add    $0x10,%esp
f0103a6d:	5e                   	pop    %esi
f0103a6e:	5f                   	pop    %edi
f0103a6f:	5d                   	pop    %ebp
f0103a70:	c3                   	ret    
f0103a71:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103a78:	3b 14 24             	cmp    (%esp),%edx
f0103a7b:	77 7b                	ja     f0103af8 <__udivdi3+0xd8>
f0103a7d:	0f bd f2             	bsr    %edx,%esi
f0103a80:	83 f6 1f             	xor    $0x1f,%esi
f0103a83:	0f 84 97 00 00 00    	je     f0103b20 <__udivdi3+0x100>
f0103a89:	bd 20 00 00 00       	mov    $0x20,%ebp
f0103a8e:	89 d7                	mov    %edx,%edi
f0103a90:	89 f1                	mov    %esi,%ecx
f0103a92:	29 f5                	sub    %esi,%ebp
f0103a94:	d3 e7                	shl    %cl,%edi
f0103a96:	89 c2                	mov    %eax,%edx
f0103a98:	89 e9                	mov    %ebp,%ecx
f0103a9a:	d3 ea                	shr    %cl,%edx
f0103a9c:	89 f1                	mov    %esi,%ecx
f0103a9e:	09 fa                	or     %edi,%edx
f0103aa0:	8b 3c 24             	mov    (%esp),%edi
f0103aa3:	d3 e0                	shl    %cl,%eax
f0103aa5:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103aa9:	89 e9                	mov    %ebp,%ecx
f0103aab:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103aaf:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103ab3:	89 fa                	mov    %edi,%edx
f0103ab5:	d3 ea                	shr    %cl,%edx
f0103ab7:	89 f1                	mov    %esi,%ecx
f0103ab9:	d3 e7                	shl    %cl,%edi
f0103abb:	89 e9                	mov    %ebp,%ecx
f0103abd:	d3 e8                	shr    %cl,%eax
f0103abf:	09 c7                	or     %eax,%edi
f0103ac1:	89 f8                	mov    %edi,%eax
f0103ac3:	f7 74 24 08          	divl   0x8(%esp)
f0103ac7:	89 d5                	mov    %edx,%ebp
f0103ac9:	89 c7                	mov    %eax,%edi
f0103acb:	f7 64 24 0c          	mull   0xc(%esp)
f0103acf:	39 d5                	cmp    %edx,%ebp
f0103ad1:	89 14 24             	mov    %edx,(%esp)
f0103ad4:	72 11                	jb     f0103ae7 <__udivdi3+0xc7>
f0103ad6:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103ada:	89 f1                	mov    %esi,%ecx
f0103adc:	d3 e2                	shl    %cl,%edx
f0103ade:	39 c2                	cmp    %eax,%edx
f0103ae0:	73 5e                	jae    f0103b40 <__udivdi3+0x120>
f0103ae2:	3b 2c 24             	cmp    (%esp),%ebp
f0103ae5:	75 59                	jne    f0103b40 <__udivdi3+0x120>
f0103ae7:	8d 47 ff             	lea    -0x1(%edi),%eax
f0103aea:	31 f6                	xor    %esi,%esi
f0103aec:	89 f2                	mov    %esi,%edx
f0103aee:	83 c4 10             	add    $0x10,%esp
f0103af1:	5e                   	pop    %esi
f0103af2:	5f                   	pop    %edi
f0103af3:	5d                   	pop    %ebp
f0103af4:	c3                   	ret    
f0103af5:	8d 76 00             	lea    0x0(%esi),%esi
f0103af8:	31 f6                	xor    %esi,%esi
f0103afa:	31 c0                	xor    %eax,%eax
f0103afc:	89 f2                	mov    %esi,%edx
f0103afe:	83 c4 10             	add    $0x10,%esp
f0103b01:	5e                   	pop    %esi
f0103b02:	5f                   	pop    %edi
f0103b03:	5d                   	pop    %ebp
f0103b04:	c3                   	ret    
f0103b05:	8d 76 00             	lea    0x0(%esi),%esi
f0103b08:	89 f2                	mov    %esi,%edx
f0103b0a:	31 f6                	xor    %esi,%esi
f0103b0c:	89 f8                	mov    %edi,%eax
f0103b0e:	f7 f1                	div    %ecx
f0103b10:	89 f2                	mov    %esi,%edx
f0103b12:	83 c4 10             	add    $0x10,%esp
f0103b15:	5e                   	pop    %esi
f0103b16:	5f                   	pop    %edi
f0103b17:	5d                   	pop    %ebp
f0103b18:	c3                   	ret    
f0103b19:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103b20:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f0103b24:	76 0b                	jbe    f0103b31 <__udivdi3+0x111>
f0103b26:	31 c0                	xor    %eax,%eax
f0103b28:	3b 14 24             	cmp    (%esp),%edx
f0103b2b:	0f 83 37 ff ff ff    	jae    f0103a68 <__udivdi3+0x48>
f0103b31:	b8 01 00 00 00       	mov    $0x1,%eax
f0103b36:	e9 2d ff ff ff       	jmp    f0103a68 <__udivdi3+0x48>
f0103b3b:	90                   	nop
f0103b3c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103b40:	89 f8                	mov    %edi,%eax
f0103b42:	31 f6                	xor    %esi,%esi
f0103b44:	e9 1f ff ff ff       	jmp    f0103a68 <__udivdi3+0x48>
f0103b49:	66 90                	xchg   %ax,%ax
f0103b4b:	66 90                	xchg   %ax,%ax
f0103b4d:	66 90                	xchg   %ax,%ax
f0103b4f:	90                   	nop

f0103b50 <__umoddi3>:
f0103b50:	55                   	push   %ebp
f0103b51:	57                   	push   %edi
f0103b52:	56                   	push   %esi
f0103b53:	83 ec 20             	sub    $0x20,%esp
f0103b56:	8b 44 24 34          	mov    0x34(%esp),%eax
f0103b5a:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0103b5e:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103b62:	89 c6                	mov    %eax,%esi
f0103b64:	89 44 24 10          	mov    %eax,0x10(%esp)
f0103b68:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0103b6c:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0103b70:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103b74:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0103b78:	89 74 24 18          	mov    %esi,0x18(%esp)
f0103b7c:	85 c0                	test   %eax,%eax
f0103b7e:	89 c2                	mov    %eax,%edx
f0103b80:	75 1e                	jne    f0103ba0 <__umoddi3+0x50>
f0103b82:	39 f7                	cmp    %esi,%edi
f0103b84:	76 52                	jbe    f0103bd8 <__umoddi3+0x88>
f0103b86:	89 c8                	mov    %ecx,%eax
f0103b88:	89 f2                	mov    %esi,%edx
f0103b8a:	f7 f7                	div    %edi
f0103b8c:	89 d0                	mov    %edx,%eax
f0103b8e:	31 d2                	xor    %edx,%edx
f0103b90:	83 c4 20             	add    $0x20,%esp
f0103b93:	5e                   	pop    %esi
f0103b94:	5f                   	pop    %edi
f0103b95:	5d                   	pop    %ebp
f0103b96:	c3                   	ret    
f0103b97:	89 f6                	mov    %esi,%esi
f0103b99:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0103ba0:	39 f0                	cmp    %esi,%eax
f0103ba2:	77 5c                	ja     f0103c00 <__umoddi3+0xb0>
f0103ba4:	0f bd e8             	bsr    %eax,%ebp
f0103ba7:	83 f5 1f             	xor    $0x1f,%ebp
f0103baa:	75 64                	jne    f0103c10 <__umoddi3+0xc0>
f0103bac:	8b 6c 24 14          	mov    0x14(%esp),%ebp
f0103bb0:	39 6c 24 0c          	cmp    %ebp,0xc(%esp)
f0103bb4:	0f 86 f6 00 00 00    	jbe    f0103cb0 <__umoddi3+0x160>
f0103bba:	3b 44 24 18          	cmp    0x18(%esp),%eax
f0103bbe:	0f 82 ec 00 00 00    	jb     f0103cb0 <__umoddi3+0x160>
f0103bc4:	8b 44 24 14          	mov    0x14(%esp),%eax
f0103bc8:	8b 54 24 18          	mov    0x18(%esp),%edx
f0103bcc:	83 c4 20             	add    $0x20,%esp
f0103bcf:	5e                   	pop    %esi
f0103bd0:	5f                   	pop    %edi
f0103bd1:	5d                   	pop    %ebp
f0103bd2:	c3                   	ret    
f0103bd3:	90                   	nop
f0103bd4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103bd8:	85 ff                	test   %edi,%edi
f0103bda:	89 fd                	mov    %edi,%ebp
f0103bdc:	75 0b                	jne    f0103be9 <__umoddi3+0x99>
f0103bde:	b8 01 00 00 00       	mov    $0x1,%eax
f0103be3:	31 d2                	xor    %edx,%edx
f0103be5:	f7 f7                	div    %edi
f0103be7:	89 c5                	mov    %eax,%ebp
f0103be9:	8b 44 24 10          	mov    0x10(%esp),%eax
f0103bed:	31 d2                	xor    %edx,%edx
f0103bef:	f7 f5                	div    %ebp
f0103bf1:	89 c8                	mov    %ecx,%eax
f0103bf3:	f7 f5                	div    %ebp
f0103bf5:	eb 95                	jmp    f0103b8c <__umoddi3+0x3c>
f0103bf7:	89 f6                	mov    %esi,%esi
f0103bf9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0103c00:	89 c8                	mov    %ecx,%eax
f0103c02:	89 f2                	mov    %esi,%edx
f0103c04:	83 c4 20             	add    $0x20,%esp
f0103c07:	5e                   	pop    %esi
f0103c08:	5f                   	pop    %edi
f0103c09:	5d                   	pop    %ebp
f0103c0a:	c3                   	ret    
f0103c0b:	90                   	nop
f0103c0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103c10:	b8 20 00 00 00       	mov    $0x20,%eax
f0103c15:	89 e9                	mov    %ebp,%ecx
f0103c17:	29 e8                	sub    %ebp,%eax
f0103c19:	d3 e2                	shl    %cl,%edx
f0103c1b:	89 c7                	mov    %eax,%edi
f0103c1d:	89 44 24 18          	mov    %eax,0x18(%esp)
f0103c21:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0103c25:	89 f9                	mov    %edi,%ecx
f0103c27:	d3 e8                	shr    %cl,%eax
f0103c29:	89 c1                	mov    %eax,%ecx
f0103c2b:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0103c2f:	09 d1                	or     %edx,%ecx
f0103c31:	89 fa                	mov    %edi,%edx
f0103c33:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0103c37:	89 e9                	mov    %ebp,%ecx
f0103c39:	d3 e0                	shl    %cl,%eax
f0103c3b:	89 f9                	mov    %edi,%ecx
f0103c3d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103c41:	89 f0                	mov    %esi,%eax
f0103c43:	d3 e8                	shr    %cl,%eax
f0103c45:	89 e9                	mov    %ebp,%ecx
f0103c47:	89 c7                	mov    %eax,%edi
f0103c49:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0103c4d:	d3 e6                	shl    %cl,%esi
f0103c4f:	89 d1                	mov    %edx,%ecx
f0103c51:	89 fa                	mov    %edi,%edx
f0103c53:	d3 e8                	shr    %cl,%eax
f0103c55:	89 e9                	mov    %ebp,%ecx
f0103c57:	09 f0                	or     %esi,%eax
f0103c59:	8b 74 24 1c          	mov    0x1c(%esp),%esi
f0103c5d:	f7 74 24 10          	divl   0x10(%esp)
f0103c61:	d3 e6                	shl    %cl,%esi
f0103c63:	89 d1                	mov    %edx,%ecx
f0103c65:	f7 64 24 0c          	mull   0xc(%esp)
f0103c69:	39 d1                	cmp    %edx,%ecx
f0103c6b:	89 74 24 14          	mov    %esi,0x14(%esp)
f0103c6f:	89 d7                	mov    %edx,%edi
f0103c71:	89 c6                	mov    %eax,%esi
f0103c73:	72 0a                	jb     f0103c7f <__umoddi3+0x12f>
f0103c75:	39 44 24 14          	cmp    %eax,0x14(%esp)
f0103c79:	73 10                	jae    f0103c8b <__umoddi3+0x13b>
f0103c7b:	39 d1                	cmp    %edx,%ecx
f0103c7d:	75 0c                	jne    f0103c8b <__umoddi3+0x13b>
f0103c7f:	89 d7                	mov    %edx,%edi
f0103c81:	89 c6                	mov    %eax,%esi
f0103c83:	2b 74 24 0c          	sub    0xc(%esp),%esi
f0103c87:	1b 7c 24 10          	sbb    0x10(%esp),%edi
f0103c8b:	89 ca                	mov    %ecx,%edx
f0103c8d:	89 e9                	mov    %ebp,%ecx
f0103c8f:	8b 44 24 14          	mov    0x14(%esp),%eax
f0103c93:	29 f0                	sub    %esi,%eax
f0103c95:	19 fa                	sbb    %edi,%edx
f0103c97:	d3 e8                	shr    %cl,%eax
f0103c99:	0f b6 4c 24 18       	movzbl 0x18(%esp),%ecx
f0103c9e:	89 d7                	mov    %edx,%edi
f0103ca0:	d3 e7                	shl    %cl,%edi
f0103ca2:	89 e9                	mov    %ebp,%ecx
f0103ca4:	09 f8                	or     %edi,%eax
f0103ca6:	d3 ea                	shr    %cl,%edx
f0103ca8:	83 c4 20             	add    $0x20,%esp
f0103cab:	5e                   	pop    %esi
f0103cac:	5f                   	pop    %edi
f0103cad:	5d                   	pop    %ebp
f0103cae:	c3                   	ret    
f0103caf:	90                   	nop
f0103cb0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103cb4:	29 f9                	sub    %edi,%ecx
f0103cb6:	19 c6                	sbb    %eax,%esi
f0103cb8:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0103cbc:	89 74 24 18          	mov    %esi,0x18(%esp)
f0103cc0:	e9 ff fe ff ff       	jmp    f0103bc4 <__umoddi3+0x74>
