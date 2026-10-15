OUTPUT_FORMAT("elf32-sh")
OUTPUT_ARCH(sh)
ENTRY(_start)
MEMORY { sdram (rwx) : ORIGIN = 0x06000000, LENGTH = 0x3E000 }
SECTIONS
{
  .text : { KEEP(*(.vectors)) *(.text*) *(.rodata*) } > sdram
  .data : { *(.data*) } > sdram
  .bss  : { __bss_start = .; *(.bss*) *(COMMON) __bss_end = .; } > sdram
  /DISCARD/ : { *(.comment) }
}
