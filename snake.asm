
bits 16
ORG 0x00


;;;;;;;;;; Sets the video mode ;;;;;;;;;;;
mov ah, 0x00 	;Set video mode
mov al, 0x13	;graphics, 320x200 res, 8x8 pixel box
int 0x10

section .text

    start:
        call show_menu

;;;;;;;; It is a cycle, so when the game ends, the execution comes back to the main menu
    show_menu:
        call show_title
        jmp show_menu

    draw_border:
            mov di, 0
        .next_x:
            mov byte [buffer + di], 255
            mov byte [buffer + 80 + di], 196
            mov byte [buffer + 1920 + di], 196
            inc di
            cmp di, 80
            jnz .next_x
            mov di, 0
        .next_y:
            mov byte [buffer + 80 + di], 179
            mov byte [buffer + 159 + di], 179
            add di,80
            cmp di, 2000
            jnz .next_y
        .corners:
            mov byte [buffer + 80], 218
            mov byte [buffer + 159], 191
            mov byte [buffer + 1920], 192
            mov byte [buffer + 1999], 217
            ret








section .bss
    buffer resb 2000
