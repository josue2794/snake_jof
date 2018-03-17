CC = nasm
FLAGS = -f bin
BOOT = bootloader
SNAKE = snake
ASM = .asm
BIN = .bin
IMG = .iso
DD = dd
ZERO = /dev/zero
QEMU = qemu-system-i386

all: bin image

bin:
		$(CC) $(FLAGS) $(BOOT)$(ASM) -o $(BOOT)$(BIN)
		$(CC) $(FLAGS) $(SNAKE)$(ASM) -o $(SNAKE)$(BIN)

image:
		$(DD) if=$(ZERO) of=$(SNAKE)$(IMG) bs=1024 count=1024
		$(DD) if=$(BOOT)$(BIN) of=$(SNAKE)$(IMG) conv=notrunc
		$(DD) if=$(SNAKE)$(BIN) of=$(SNAKE)$(IMG) bs=1024 seek=1 conv=notrunc

usb:
		$(DD) if=$(SNAKE)$(IMG) of=$(DIR)

emul:
		$(QEMU) $(SNAKE)$(IMG)

clean:
		rm $(BOOT)$(BIN) $(SNAKE)$(BIN) $(SNAKE)$(IMG)

help:
	@echo "To compile, generate the .iso file and 'burn' it into the USB, execute the following command: \"sudo make DIR=/dev/sdX\""
	@echo "the 'X' on the USB path may be changed with a correct letter on the system."
	@echo "\nTry typing \"sudo fdisk -l\" on terminal to get the USB drive path"
	@echo "\nIf you want to emulate the program, insert the following command: \"make emul\""
