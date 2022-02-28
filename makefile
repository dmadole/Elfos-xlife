
xlife.bin: xlife.asm include/bios.inc include/kernel.inc
	asm02 -b -L xlife.asm

clean:
	-rm -f *.bin *.lst

