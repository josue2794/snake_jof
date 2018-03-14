[bits 16]
[ORG 0x7c00]		;This 0x07c00 is the physical address where the bootloader starts 

jmp reset		;Jump to reset tag
reset:          	;Resets drive
    			;BIOS sets DL to boot drive before jumping to the bootloader

    
    xor ax, ax		;Data Segment (DS) is set accordingly.
    mov ds, ax        	;DS=0

    cli               	;Turn off interrupts to avoid a problem with buggy 8088 CPUs
                      	
    mov ss, ax        	;SS = 0x0000
    mov sp, 0x7c00    	;SP = 0x7c00 We'll set the stack starting just below
                      	
    sti               	;Turn interrupts back on

    xor ax,ax   	;0 = Reset device disk
    int 0x13
    jc reset        	;If carry flag was set, try again

    mov ax,0x1000   	;When we read the sector, we are going to read address 0x1000
    mov es,ax       	;Set ES with 0x1000

device:
    xor bx,bx   	;Ensure that the buffer offset is 0!
    mov ah,0x2  	;2 = Read device
    mov al,0x1  	;Reading one sector
    mov ch,0x0  	;Track 1
    mov cl,0x2  	;Sector 2, track 1
    mov dh,0x0  	;Head 1
    int 0x13
    jc device   	;If carry flag was set, try again
    jmp 0x1000:0000 	;Jump to 0x1000, start of the pacman game

times 510-($-$$) db 0   ;Fill the rest of sector with 0
dw 0xAA55   		;This is the boot signature