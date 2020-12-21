MIPS_COMPILER = mipsel-linux-gnu-gcc
MIPS_OBJ_COPY = mipsel-linux-gnu-objcopy
MIPS_OBJ_DUMP = mipsel-linux-gnu-objdump
MIPS_CPP_FLAGS = -W -Wall -O3 -ffunction-sections -fno-builtin -fno-stack-protector -mfp32 -march=mips1 -EL
MIPS_LD_FLAGS = -nostdlib -Wl,-melf32btsmip -nostartfiles -mno-check-zero-division -Wl,--gpsize=0 -static -Wl,-Bstatic -Wl,--build-id=none

# Turns C file into MIPS object file
%.mips.o: %.c
	$(MIPS_COMPILER) $(MIPS_CPP_FLAGS) -c $< -o $@

# Turns MIPS assembly file into MIPS object file
%.mips.o: %.s
	$(MIPS_COMPILER) $(MIPS_CPP_FLAGS) -c $< -o $@

# Turns C file into MIPS assembly
%.s: %.c
	$(MIPS_COMPILER) $(MIPS_CPP_FLAGS) -S $< -o $@

# Link MIPS object file storing instructions at 0xBFC00000 and storing data at 0xBFC20000
%.mips.elf: %.mips.o
	$(MIPS_COMPILER) $(MIPS_CPP_FLAGS) $(MIPS_LD_FLAGS) -T linker.ld $< -o $@

# Disassemble to make assembly code
%.mips.s : %.mips.elf
	$(MIPS_OBJ_DUMP) -j .text -D $< > $@

# Renames MIPS assembly to match naming in testbench
%.asm: %.mips.s
	mv $< 0-assembly/$@

# Extracts binary from linked object file
%.mips.bin: %.mips.elf
	$(MIPS_OBJ_COPY) -O binary --only-section=.text $< $@

%.mips.data.bin: %.mips.elf
	$(MIPS_OBJ_COPY) -O binary --only-section=.data $< $@

# Converts binary into hex, place values into RAM_INIT_FILE
%.hex.txt : %.mips.bin
	od -An -w4 -v -t x4 $< > $@; sed -i '1 s/^/@BFC00000\n/' $@

# This corresponds to line 32769 in RAM_INIT_FILE
%.hex.data.txt : %.mips.data.bin
	od -An -w4 -v -t x4 $< > $@; sed -i '1 s/^/@BFC20000\n/' $@; \
	if [ ! -s $@ ]; then\
  		printf "@BFC20000\n" > $@; \
	fi

# Use qemu-mipsel to generate reference output (value is in decimal)
%.bin: %.c
	$(MIPS_COMPILER) $(MIPS_CPP_FLAGS) $< -o $@

%.ref.txt : %.bin
	qemu-mipsel -L /usr/mipsel-linux-gnu $<; echo $$? > $@

clean :
	rm *.txt
