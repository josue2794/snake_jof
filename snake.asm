;Snake!
[BITS 16]
[ORG 0x0000]

TOTAL_SEGMENTS equ 0x42

ZERO equ 0x00
SIZE_PIX equ 0x02

maxScreenX equ 0x32
maxScreenY equ 0x32


DOWN equ 0x50
UP equ 0x48
LEFT equ 0x4B
RIGHT equ 0x4D



section .data:
    msg1 db 'SNAKE', 0x00

section .bss
  x_coord   RESW TOTAL_SEGMENTS ; [x_coord] is the head, [x_coord+2] is the next cell, etc. ;arreglo de coordenadas x
  y_coord   RESW TOTAL_SEGMENTS ; Same here
  t1        RESB 2
  t2        RESB 2
  enabled   RESB 2  ; parece ser la cantidad de elemetos de la serpiente
  x_apple   RESB 2
  y_apple   RESB 2

  last_move RESB 2


section  .text
global_start:

_start:
    MOV AH, 0x00
    MOV AL, 0x13
    INT 0x10
    ;call SetVideoMode
    jmp MainMenu   ; Llama al menu para que sea lo primero que muestre
    ;MOV DX, 0x77
    ;MOV [last_move], DX
    ;CALL SetVideoMode
    ;CALL SetInitialCoords
    ;CALL SetScreen
    ;mov	ax, 0x0305
    ;mov	bx, 0x031F
    ;int	0x16		; increase delay before keybort repeat
    ;CALL ListenForInput

; DX cursor position
move_cursor:
  mov ah, 0x02
  xor bh, 0
  int 0x10
  ret

print_string:
    mov si, msg1
    mov dl, 17
    mov dh, 3
    call move_cursor
.loop:
    mov al, [si]
    cmp al, 0x00
    je .done
    call print_char
    inc si
    inc dl
    jmp .loop
.done:
    ret

print:
    call print_char
    inc dl
    call move_cursor
    ret

print_char:
    mov ah, 0x0E
    mov bh, 0x00

    int 0x10
    ret

MainMenu:
    .print_title:
        mov bl, 0xE
        mov dl, 17
        mov dh, 3
        call move_cursor
        mov al, 'S'
        call print
        mov al, 'N'
        call print
        mov al, 'A'
        call print
        mov al, 'K'
        call print
        mov al, 'E'
        call print
    .print_level1:
        mov bl, 0x2
        mov dl, 13
        mov dh, 9
        call move_cursor
        mov al, 'L'
        call print
        mov al, 'V'
        call print
        mov al, 'L'
        call print
        mov al, ' '
        call print
        mov al, '1'
        call print
        mov al, '-'
        call print
        mov al, 'P'
        call print
        mov al, 'R'
        call print
        mov al, 'E'
        call print
        mov al, 'S'
        call print
        mov al, 'S'
        call print
        mov al, ' '
        call print
        mov al, '1'
        call print
    .print_level2:
        mov dl, 13
        mov dh, 12
        call move_cursor
        mov al, 'L'
        call print
        mov al, 'V'
        call print
        mov al, 'L'
        call print
        mov al, ' '
        call print
        mov al, '2'
        call print
        mov al, '-'
        call print
        mov al, 'P'
        call print
        mov al, 'R'
        call print
        mov al, 'E'
        call print
        mov al, 'S'
        call print
        mov al, 'S'
        call print
        mov al, ' '
        call print
        mov al, '2'
        call print
    .print_level3:
        mov dl, 13
        mov dh, 15
        call move_cursor
        mov al, 'L'
        call print
        mov al, 'V'
        call print
        mov al, 'L'
        call print
        mov al, ' '
        call print
        mov al, '3'
        call print
        mov al, '-'
        call print
        mov al, 'P'
        call print
        mov al, 'R'
        call print
        mov al, 'E'
        call print
        mov al, 'S'
        call print
        mov al, 'S'
        call print
        mov al, ' '
        call print
        mov al, '3'
        call print


        ;call print_string
    mov ah, 0x00
    int 0x16    ; Teclado

    call read_level_keys
    jmp MainMenu

;       This area of code waits a keyboard interruption to select the level
;       of the game while in the main menu
read_level_keys:
    cmp al, '1' ; Try with key 02
    ;   if tecla == 1 -> Start the game in the first level
    je start_level_1
    cmp al, '2'
    je start_level_2
    cmp al, '3'
    je start_level_3
    ret

start_level_1:
    mov dx, SCOREL1
    mov [score], dx
    mov dx, LEVEL1
    mov [SpeedLVL], dx
    jmp start
start_level_2:
    mov dx, SCOREL2
    mov [score], dx
    mov dx, LEVEL2
    mov [SpeedLVL], dx
    jmp start
start_level_3:
    mov dx, SCOREL3
    mov [score], dx
    mov dx, LEVEL3
    mov [SpeedLVL], dx
    jmp start
;        ;call SetVideoMode
;        mov al, 1
;        mov bh, 0
;        mov bl, 0xF ;color
;        mov cx, msg1end - msg1 ; calculate message size.
;        mov dl, 17
;        mov dh, 3
;        push cs
;        pop es
;        mov bp, msg1
;        mov ah, 13h
;        int 10h
;        jmp msg1end

;        msg1end:
;        jmp MainMenu



SetVideoMode:
  MOV AH, 0x00
  MOV AL, 0x13
  INT 0x10
  RET




;TIMES (510 - $) db 0  ;Fill the rest of sector with 0
TIMES 510 - ($ - $$) db 0  ;Fill the rest of sector with 0
DW 0xAA55      ;Add boot signature at the end of bootloader
