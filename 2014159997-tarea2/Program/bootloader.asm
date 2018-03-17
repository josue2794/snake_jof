[BITS 16]			; Tell nasm that we are running in real mode
[ORG 0x7C00]    		; Bootloader starts at physical address 0x07c00

%define INT_RSM 0x13		; Define interrupt that reads sectors into memory

%macro PROC 0
	xor AX, AX   		; Reset value of register
	int INT_RSM		; Read sectors into memory
	jc main        		; If failure, run init again
%endmacro

%macro ASSIGN 0
	mov AH, 0x2  		; 2 = Read USB drive
	mov AL, 0x8  		; Read eight sectors
	mov CH, 0x0  		; Track 1
	mov CL, 0x2  		; Sector 2, track 1
	mov DH, 0x0  		; Head 1
%endmacro

start:
	jmp main		; Init boot proccess

main:
	xor AX, AX		; Reset value of register

	cli
	mov SS, AX 		; SS = 0x0000
    	mov SP, 0x7C00		; SP = 0x7c00
	sti

	PROC
	mov AX, 0x1000		; When we read the sector, we are going to read address 0x1000
	mov ES, AX     		; Set ES with 0x1000

set_game:
	xor BX, BX   		; Reset value of register to ensure that the buffer offset is 0
	ASSIGN
	int INT_RSM		; Read sectors into memory
	jc set_game   		; If failure, run set_game again.

	jmp 0x1000:0000 	; Jump to 0x1000, starting the snake

TIMES 510 - ($ - $$) DB 0	; Fill the rest of the sector with zeros
DW 0xAA55   			; Boot signature 
