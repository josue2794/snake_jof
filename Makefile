CC = nasm
NFLAGS = -f bin
FFLAGS = mkfs.vfat -I
BOOTLOADER = bootloader
SNAKE = snake
QEMU = qemu-system-i386
RM = rm -f

all: boot game image gen

exec: format load

image:
	@dd if=/dev/zero of=snake.img bs=1024 count=720
	@echo Snake disk image has been created successfully...

gen: $(BOOTLOADER).bin $(SNAKE).img $(SNAKE).bin
	@sudo dd if=$(BOOTLOADER).bin of=$(SNAKE).img conv=notrunc
	@sudo dd if=$(SNAKE).bin of=$(SNAKE).img bs=512 seek=1 conv=notrunc
	@echo All copies has been finished...

emul: $(SNAKE).img
	@$(QEMU) $(SNAKE).img

boot: $(BOOTLOADER).asm
	@$(CC) $(NFLAGS) $(BOOTLOADER).asm -o $(BOOTLOADER).bin
	@echo Bootloader bin file has been generated successfully...

game: $(SNAKE).asm
	@$(CC) $(NFLAGS) $(SNAKE).asm -o $(SNAKE).bin
	@echo Snake bin file has been generated successfully...

#format: SHELL:=/bin/bash
format:
	@echo Device selected is $(path)
	@read -p "Continue (y/n)? " param ; \
	case $$param in [Yy] ) sudo $(FFLAGS) $(path);; [Nn]) exit;; *) echo "Invalid input";; esac

load: $(SNAKE).img
	@sudo dd if=$(SNAKE).img of=$(path)

clean:
	@$(RM) *bin
	@$(RM) *img
	@echo All files has been deleted...
