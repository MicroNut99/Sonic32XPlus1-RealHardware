# Builds sh2.bin (master + slave SH2 program), included by sonic.asm when Mars = 1.
PREFIX ?= /opt/toolchains/sega/sh-elf/bin/sh-elf-
CFLAGS = -m2 -mb -O2 -ffreestanding -fno-builtin -nostdlib -Wall
sh2.bin: sh2.elf
	$(PREFIX)objcopy -O binary $< $@
sh2.elf: crt0.o master.o slave.o sh2.ld
	$(PREFIX)gcc -m2 -mb -nostdlib -T sh2.ld crt0.o master.o slave.o -lgcc -o $@
crt0.o: crt0.s
	$(PREFIX)as --big $< -o $@
%.o: %.c mars.h
	$(PREFIX)gcc $(CFLAGS) -c $< -o $@
clean:
	rm -f *.o sh2.elf sh2.bin
