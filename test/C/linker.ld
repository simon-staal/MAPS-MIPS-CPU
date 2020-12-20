ENTRY(main)
SECTIONS
{
. = 0xBFC00000;
.text : { *(.entry_section) }
.text : { *(.text.main) }
.text : { *(.text*) }
.text : { *(.text.startup) }
.text : { *(.rodata) }
.text : { *(.rodata.*) }

 . = 0xBFC0FF00;
.data : { *(.data) }
.bss : { *(.bss) }
}
