
bootblock.o:     file format elf32-i386


Disassembly of section .text:

00007c00 <start>:
# with %cs=0 %ip=7c00.

.code16                       # Assemble for 16-bit mode
.globl start
start:
  cli                         # BIOS enabled interrupts; disable
    7c00:	fa                   	cli    

  # Zero data segment registers DS, ES, and SS.
  xorw    %ax,%ax             # Set %ax to zero
    7c01:	31 c0                	xor    %eax,%eax
  movw    %ax,%ds             # -> Data Segment
    7c03:	8e d8                	mov    %eax,%ds
  movw    %ax,%es             # -> Extra Segment
    7c05:	8e c0                	mov    %eax,%es
  movw    %ax,%ss             # -> Stack Segment
    7c07:	8e d0                	mov    %eax,%ss

00007c09 <seta20.1>:

  # Physical address line A20 is tied to zero so that the first PCs 
  # with 2 MB would run software that assumed 1 MB.  Undo that.
seta20.1:
  inb     $0x64,%al               # Wait for not busy
    7c09:	e4 64                	in     $0x64,%al
  testb   $0x2,%al
    7c0b:	a8 02                	test   $0x2,%al
  jnz     seta20.1
    7c0d:	75 fa                	jne    7c09 <seta20.1>

  movb    $0xd1,%al               # 0xd1 -> port 0x64
    7c0f:	b0 d1                	mov    $0xd1,%al
  outb    %al,$0x64
    7c11:	e6 64                	out    %al,$0x64

00007c13 <seta20.2>:

seta20.2:
  inb     $0x64,%al               # Wait for not busy
    7c13:	e4 64                	in     $0x64,%al
  testb   $0x2,%al
    7c15:	a8 02                	test   $0x2,%al
  jnz     seta20.2
    7c17:	75 fa                	jne    7c13 <seta20.2>

  movb    $0xdf,%al               # 0xdf -> port 0x60
    7c19:	b0 df                	mov    $0xdf,%al
  outb    %al,$0x60
    7c1b:	e6 60                	out    %al,$0x60

  # Switch from real to protected mode.  Use a bootstrap GDT that makes
  # virtual addresses map directly to physical addresses so that the
  # effective memory map doesn't change during the transition.
  lgdt    gdtdesc
    7c1d:	0f 01 16             	lgdtl  (%esi)
    7c20:	78 7c                	js     7c9e <readsect+0x12>
  movl    %cr0, %eax
    7c22:	0f 20 c0             	mov    %cr0,%eax
  orl     $CR0_PE, %eax
    7c25:	66 83 c8 01          	or     $0x1,%ax
  movl    %eax, %cr0
    7c29:	0f 22 c0             	mov    %eax,%cr0

//PAGEBREAK!
  # Complete the transition to 32-bit protected mode by using a long jmp
  # to reload %cs and %eip.  The segment descriptors are set up with no
  # translation, so that the mapping is still the identity mapping.
  ljmp    $(SEG_KCODE<<3), $start32
    7c2c:	ea                   	.byte 0xea
    7c2d:	31 7c 08 00          	xor    %edi,0x0(%eax,%ecx,1)

00007c31 <start32>:

.code32  # Tell assembler to generate 32-bit code now.
start32:
  # Set up the protected-mode data segment registers
  movw    $(SEG_KDATA<<3), %ax    # Our data segment selector
    7c31:	66 b8 10 00          	mov    $0x10,%ax
  movw    %ax, %ds                # -> DS: Data Segment
    7c35:	8e d8                	mov    %eax,%ds
  movw    %ax, %es                # -> ES: Extra Segment
    7c37:	8e c0                	mov    %eax,%es
  movw    %ax, %ss                # -> SS: Stack Segment
    7c39:	8e d0                	mov    %eax,%ss
  movw    $0, %ax                 # Zero segments not ready for use
    7c3b:	66 b8 00 00          	mov    $0x0,%ax
  movw    %ax, %fs                # -> FS
    7c3f:	8e e0                	mov    %eax,%fs
  movw    %ax, %gs                # -> GS
    7c41:	8e e8                	mov    %eax,%gs

  # Set up the stack pointer and call into C.
  movl    $start, %esp
    7c43:	bc 00 7c 00 00       	mov    $0x7c00,%esp
  call    bootmain
    7c48:	e8 e6 00 00 00       	call   7d33 <bootmain>

  # If bootmain returns (it shouldn't), trigger a Bochs
  # breakpoint if running under Bochs, then loop.
  movw    $0x8a00, %ax            # 0x8a00 -> port 0x8a00
    7c4d:	66 b8 00 8a          	mov    $0x8a00,%ax
  movw    %ax, %dx
    7c51:	66 89 c2             	mov    %ax,%dx
  outw    %ax, %dx
    7c54:	66 ef                	out    %ax,(%dx)
  movw    $0x8ae0, %ax            # 0x8ae0 -> port 0x8a00
    7c56:	66 b8 e0 8a          	mov    $0x8ae0,%ax
  outw    %ax, %dx
    7c5a:	66 ef                	out    %ax,(%dx)

00007c5c <spin>:
spin:
  jmp     spin
    7c5c:	eb fe                	jmp    7c5c <spin>
    7c5e:	66 90                	xchg   %ax,%ax

00007c60 <gdt>:
	...
    7c68:	ff                   	(bad)  
    7c69:	ff 00                	incl   (%eax)
    7c6b:	00 00                	add    %al,(%eax)
    7c6d:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
    7c74:	00                   	.byte 0x0
    7c75:	92                   	xchg   %eax,%edx
    7c76:	cf                   	iret   
	...

00007c78 <gdtdesc>:
    7c78:	17                   	pop    %ss
    7c79:	00 60 7c             	add    %ah,0x7c(%eax)
	...

00007c7e <waitdisk>:
    7c7e:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7c83:	ec                   	in     (%dx),%al
    7c84:	83 e0 c0             	and    $0xffffffc0,%eax
    7c87:	3c 40                	cmp    $0x40,%al
    7c89:	75 f8                	jne    7c83 <waitdisk+0x5>
    7c8b:	c3                   	ret    

00007c8c <readsect>:
    7c8c:	55                   	push   %ebp
    7c8d:	89 e5                	mov    %esp,%ebp
    7c8f:	57                   	push   %edi
    7c90:	53                   	push   %ebx
    7c91:	8b 5d 0c             	mov    0xc(%ebp),%ebx
    7c94:	e8 e5 ff ff ff       	call   7c7e <waitdisk>
    7c99:	b0 01                	mov    $0x1,%al
    7c9b:	ba f2 01 00 00       	mov    $0x1f2,%edx
    7ca0:	ee                   	out    %al,(%dx)
    7ca1:	ba f3 01 00 00       	mov    $0x1f3,%edx
    7ca6:	88 d8                	mov    %bl,%al
    7ca8:	ee                   	out    %al,(%dx)
    7ca9:	89 d8                	mov    %ebx,%eax
    7cab:	c1 e8 08             	shr    $0x8,%eax
    7cae:	ba f4 01 00 00       	mov    $0x1f4,%edx
    7cb3:	ee                   	out    %al,(%dx)
    7cb4:	89 d8                	mov    %ebx,%eax
    7cb6:	c1 e8 10             	shr    $0x10,%eax
    7cb9:	ba f5 01 00 00       	mov    $0x1f5,%edx
    7cbe:	ee                   	out    %al,(%dx)
    7cbf:	89 d8                	mov    %ebx,%eax
    7cc1:	c1 e8 18             	shr    $0x18,%eax
    7cc4:	83 c8 e0             	or     $0xffffffe0,%eax
    7cc7:	ba f6 01 00 00       	mov    $0x1f6,%edx
    7ccc:	ee                   	out    %al,(%dx)
    7ccd:	b0 20                	mov    $0x20,%al
    7ccf:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7cd4:	ee                   	out    %al,(%dx)
    7cd5:	e8 a4 ff ff ff       	call   7c7e <waitdisk>
    7cda:	8b 7d 08             	mov    0x8(%ebp),%edi
    7cdd:	b9 80 00 00 00       	mov    $0x80,%ecx
    7ce2:	ba f0 01 00 00       	mov    $0x1f0,%edx
    7ce7:	fc                   	cld    
    7ce8:	f3 6d                	rep insl (%dx),%es:(%edi)
    7cea:	5b                   	pop    %ebx
    7ceb:	5f                   	pop    %edi
    7cec:	5d                   	pop    %ebp
    7ced:	c3                   	ret    

00007cee <readseg>:
    7cee:	55                   	push   %ebp
    7cef:	89 e5                	mov    %esp,%ebp
    7cf1:	57                   	push   %edi
    7cf2:	56                   	push   %esi
    7cf3:	53                   	push   %ebx
    7cf4:	83 ec 0c             	sub    $0xc,%esp
    7cf7:	8b 5d 08             	mov    0x8(%ebp),%ebx
    7cfa:	8b 75 10             	mov    0x10(%ebp),%esi
    7cfd:	89 df                	mov    %ebx,%edi
    7cff:	03 7d 0c             	add    0xc(%ebp),%edi
    7d02:	89 f0                	mov    %esi,%eax
    7d04:	25 ff 01 00 00       	and    $0x1ff,%eax
    7d09:	29 c3                	sub    %eax,%ebx
    7d0b:	c1 ee 09             	shr    $0x9,%esi
    7d0e:	46                   	inc    %esi
    7d0f:	39 fb                	cmp    %edi,%ebx
    7d11:	73 18                	jae    7d2b <readseg+0x3d>
    7d13:	83 ec 08             	sub    $0x8,%esp
    7d16:	56                   	push   %esi
    7d17:	53                   	push   %ebx
    7d18:	e8 6f ff ff ff       	call   7c8c <readsect>
    7d1d:	81 c3 00 02 00 00    	add    $0x200,%ebx
    7d23:	46                   	inc    %esi
    7d24:	83 c4 10             	add    $0x10,%esp
    7d27:	39 fb                	cmp    %edi,%ebx
    7d29:	72 e8                	jb     7d13 <readseg+0x25>
    7d2b:	8d 65 f4             	lea    -0xc(%ebp),%esp
    7d2e:	5b                   	pop    %ebx
    7d2f:	5e                   	pop    %esi
    7d30:	5f                   	pop    %edi
    7d31:	5d                   	pop    %ebp
    7d32:	c3                   	ret    

00007d33 <bootmain>:
    7d33:	55                   	push   %ebp
    7d34:	89 e5                	mov    %esp,%ebp
    7d36:	57                   	push   %edi
    7d37:	56                   	push   %esi
    7d38:	53                   	push   %ebx
    7d39:	83 ec 10             	sub    $0x10,%esp
    7d3c:	6a 00                	push   $0x0
    7d3e:	68 00 10 00 00       	push   $0x1000
    7d43:	68 00 00 01 00       	push   $0x10000
    7d48:	e8 a1 ff ff ff       	call   7cee <readseg>
    7d4d:	83 c4 10             	add    $0x10,%esp
    7d50:	81 3d 00 00 01 00 7f 	cmpl   $0x464c457f,0x10000
    7d57:	45 4c 46 
    7d5a:	75 27                	jne    7d83 <bootmain+0x50>
    7d5c:	8b 15 1c 00 01 00    	mov    0x1001c,%edx
    7d62:	8d 9a 00 00 01 00    	lea    0x10000(%edx),%ebx
    7d68:	0f b7 05 2c 00 01 00 	movzwl 0x1002c,%eax
    7d6f:	c1 e0 05             	shl    $0x5,%eax
    7d72:	8d b4 02 00 00 01 00 	lea    0x10000(%edx,%eax,1),%esi
    7d79:	39 f3                	cmp    %esi,%ebx
    7d7b:	72 15                	jb     7d92 <bootmain+0x5f>
    7d7d:	ff 15 18 00 01 00    	call   *0x10018
    7d83:	8d 65 f4             	lea    -0xc(%ebp),%esp
    7d86:	5b                   	pop    %ebx
    7d87:	5e                   	pop    %esi
    7d88:	5f                   	pop    %edi
    7d89:	5d                   	pop    %ebp
    7d8a:	c3                   	ret    
    7d8b:	83 c3 20             	add    $0x20,%ebx
    7d8e:	39 f3                	cmp    %esi,%ebx
    7d90:	73 eb                	jae    7d7d <bootmain+0x4a>
    7d92:	8b 7b 0c             	mov    0xc(%ebx),%edi
    7d95:	83 ec 04             	sub    $0x4,%esp
    7d98:	ff 73 04             	pushl  0x4(%ebx)
    7d9b:	ff 73 10             	pushl  0x10(%ebx)
    7d9e:	57                   	push   %edi
    7d9f:	e8 4a ff ff ff       	call   7cee <readseg>
    7da4:	8b 4b 14             	mov    0x14(%ebx),%ecx
    7da7:	8b 43 10             	mov    0x10(%ebx),%eax
    7daa:	83 c4 10             	add    $0x10,%esp
    7dad:	39 c8                	cmp    %ecx,%eax
    7daf:	73 da                	jae    7d8b <bootmain+0x58>
    7db1:	01 c7                	add    %eax,%edi
    7db3:	29 c1                	sub    %eax,%ecx
    7db5:	b8 00 00 00 00       	mov    $0x0,%eax
    7dba:	fc                   	cld    
    7dbb:	f3 aa                	rep stos %al,%es:(%edi)
    7dbd:	eb cc                	jmp    7d8b <bootmain+0x58>
