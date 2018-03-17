;Snake!
[BITS 16]
[ORG 0x0000]


%assign SYS_EXIT        1
%assign SYS_WRITE       4
%assign STDOUT          1

TOTAL_SEGMENTS equ 0xC8

ZERO equ 0x00

maxScreenX equ 0x32
maxScreenY equ 0x32

UP equ 0x48
LEFT equ 0x4B
RIGHT equ 0x4D
DOWN equ 0x50

LEVEL1 equ 0x0002
LEVEL2 equ 0x0001
LEVEL3 equ 0x0000


SCOREL1 equ 0x0
SCOREL2 equ 0x64 ;100
SCOREL3 equ 0xC8 ;200

section .bss
  x_coord   RESW TOTAL_SEGMENTS ; [x_coord] is the head, [x_coord+2] is the next cell, etc.
  y_coord   RESW TOTAL_SEGMENTS ; Same here
  t1        RESB 2
  t2        RESB 2
  enabled   RESB 2  ;amount of elements of the snake
  x_apple   RESB 2 ;position x for the apple
  y_apple   RESB 2 ;position y for the apple

  last_x   RESB 2 ;last position of the snake
  last_y   RESB 2 ;last position of the snake
  collision RESB 2 ;variable to verify collisions

  last_move RESB 2 ;last move of the snake

  score     RESB 2 ; variable to keep the score

  SpeedLVL  RESB 4


section  .text
global_start

_start:         ;init the game with the main menu and prepare all to play
    CALL SetVideoMode
    CALL MainMenu
    CALL read_level_keys
    MOV DX, UP
    MOV [last_move], DX
    CALL SetInitialCoords
    CALL SetScreen
    JMP ListenForInput




score_label: ;label to print the word "score" in the display
    mov bl, 0x0F
    mov dl, 0
    mov dh, 7
    call move_cursor
    mov al, 'S'
    call print
    mov al, 'C'
    call print
    mov al, 'O'
    call print
    mov al, 'R'
    call print
    mov al, 'E'
    call print
    mov al, ':'
    call print
    RET

game_over_label: ;label thar prints the word "END!"
    mov bl, 0x0F
    mov dl, 17
    mov dh, 5
    call move_cursor
    mov al, 'E'
    call print
    mov al, 'N'
    call print
    mov al, 'D'
    call print
    mov al, '!'
    call print
    RET

MainMenu:   ; structure of the sign to display as main menu, it is ordered letter by letter
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
    mov al, '1'
    call print
    mov al, '-'
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
    mov al, '2'
    call print
    mov al, '-'
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
    mov al, '3'
    call print
    mov al, '-'
    call print
    mov al, ' '
    call print
    mov al, '3'
    call print
    RET



move_cursor: ; function that assign the position of the cursor to print characters
  mov ah, 0x02
  xor bh, 0
  int 0x10
  ret

print:    ; auxiliar function to print strings
  call print_char
  inc dl
  call move_cursor
  ret

print_char: ;print a single character in the display
  mov ah, 0x0E
  mov bh, 0x00
  int 0x10
  ret


halt: ;function to restart the game when the players has lost
	mov ah, 0x0		;Set ah to 0
	int 0x16		;Get keystroke interrupt
	cmp ah, 0x1C	;Restart if enter arrow pressed
	je _start
	jmp halt

SetVideoMode: ;sets the video mode to graphics mode with 256 colors
  MOV AH, 0x00
  MOV AL, 0x13
  INT 0x10
  RET

SetScreen: ;print the game area
  MOV CX, 0x00 ;initial coordinate in x
  MOV DX, 0x00 ;initial coordinate in y
  MOV AL, 0x08 ; screen color
  MOV BH, 0x00
  MOV AH, 0x0C ; writePixel mode
  .x_loop_begin:
   MOV CX, 0x00
   .y_loop_begin:
    INT 0x10
    INC CX
    CMP CX, maxScreenX ; end of the game area in x
    JNAE .y_loop_begin
   .y_loop_end:
   INC DX
   CMP DX, maxScreenY ; end of the game area in y
   JNAE .x_loop_begin
  .x_loop_end:
  CALL score_label
  RET

SetInitialCoords:
  MOV AX, 0x0F ; Initial x/y coord
  MOV BX, 0x00
  MOV DX, TOTAL_SEGMENTS
  ADD DX, DX

  .initialize_loop_begin: ;assign a specific value to each space of the coordinate array
   MOV [x_coord+BX], AX
   MOV [y_coord+BX], AX
   ADD BX, 0x02
   CMP BX, DX
   JNE .initialize_loop_begin

  MOV AX, ZERO
  MOV [t1]       , AX
  MOV [t2]       , AX
  MOV AX, 3             ; number of elements that the snake start, length of the snake
  MOV [enabled]  , AX

  CALL RandomNumber ;set first apple
  MOV [x_apple], AX
  CALL RandomNumber
  MOV [y_apple], AX
  RET

ListenForInput:  ;Repeatedly check for keyboard input
  MOV	AH, 0x01	; check if key available
  INT	0x16
  JZ .done_clear
  MOV	AH, 0x00	; if there was a key, remove it from buffer
  INT	0x16
  JMP .continue

  .done_clear:
    MOV	AH, [last_move]	; no keys, so we use the last one

  .continue:
  CALL InterpretKeypress

  .sleep:
    MOV	cx, [SpeedLVL]	; Sleep for control the leves
    MOV dx, 0x49F0	;
    MOV	ah, 0x86
    INT	0x15		; Sleep

  CALL ListenForInput
  RET

InterpretKeypress:
  CMP AH, UP  ; compare the pressed key with the up arrow
  MOV	[last_move], AH	; save the direction
  JE .u_pressed

  CMP AH, LEFT ;compare the pressed key with the left arrow
  MOV	[last_move], AH	; save the direction
  JE .l_pressed

  CMP AH, DOWN ; compare the pressed key with the down arrow
  MOV	[last_move], AH	; save the direction
  JE .d_pressed

  CMP AH, RIGHT ; compare the pressed key with the right arrow
  MOV	[last_move], AH	; save the direction
  JE .r_pressed

  RET ; Invalid keypress, start listening again

  .u_pressed:
  MOV AX, [x_coord]
  MOV BX, [y_coord]
  DEC BX
  JMP .after_control_handle

  .l_pressed:
  MOV AX, [x_coord]
  MOV BX, [y_coord]
  DEC AX
  JMP .after_control_handle

  .d_pressed:
  MOV AX, [x_coord]
  MOV BX, [y_coord]
  INC BX
  JMP .after_control_handle

  .r_pressed:
  MOV AX, [x_coord]
  MOV BX, [y_coord]
  INC AX

  .after_control_handle:  ; set the last position and verify all the collisions and draw the new apple and the current snake
  MOV [t1], AX
  MOV [t2], BX
  MOV [last_x], AX
  MOV [last_y], BX
  CALL CheckWallCollision
  CALL CheckAppleCollision
  CALL CheckSelfCollision
  CALL ShiftArray
  CALL DrawSnake
  CALL DrawApple
  CALL CheckLVL
  CALL PrintScore
  RET

PrintScore: ;print the score in the screen
    MOV bl, 0x0F
    MOV dl, 0x0
    MOV dh, 0x8
    CALL move_cursor
    MOV	AX, [score]	; move the score into ax
    CALL	print_int	; print it
    RET

CheckLVL: ;compare the score with the limits to take changes in the level speed
    MOV DX, [score]
    CMP DX, SCOREL2
    JE .setLVL2
    CMP DX, SCOREL3
    JE .setLVL3
    JMP .end

  .setLVL2:
    MOV DX, LEVEL2
    MOV [SpeedLVL], DX
    CALL SetScreen
    CALL SetInitialCoords
    MOV DX, [score]
    INC DX
    MOV [score], DX
    JMP .end

  .setLVL3:
    MOV DX, LEVEL3
    MOV [SpeedLVL], DX
    CALL SetScreen
    CALL SetInitialCoords
    MOV DX, [score]
    INC DX
    MOV [score], DX

  .end:

    RET


CheckAppleCollision:
  CMP AX, [x_apple] ;verifica si la posicion x de la manzana es igual a la cabeza del snake
  JNE .no_collision

  CMP BX, [y_apple] ;verifica si la posicion y de la manzana es igual a la cabeza del snake
  JNE .no_collision

  MOV AX, [enabled] ; Cuando colisiona con la manzana se incrementa en 1 enabled
  INC AX
  MOV [enabled], AX

  MOV AX, [score] ; Cuando colisiona con la manzana se incrementa en 1 score
  INC AX
  MOV [score], AX

  CALL RandomNumber
  MOV [x_apple], AX
  CALL RandomNumber
  MOV [y_apple], AX

  .no_collision:
  RET

CheckWallCollision:
  CMP AX, maxScreenX ;verifica si la posicion x de la pared es igual a la cabeza del snake
  JE .collision_w
  CMP BX, maxScreenY ;verifica si la posicion y de la manzana es igual a la cabeza del snake
  JE .collision_w
  CMP AX, ZERO ;verifica si la posicion x de la manzana es igual a la cabeza del snake
  JL .collision_w
  CMP BX, ZERO ;verifica si la posicion y de la manzana es igual a la cabeza del snake
  JL .collision_w
  RET
  ;Colocar mensaje de perder
  .collision_w:
  JMP game_over ; reinicia el juego si choca

CheckSelfCollision:
  MOV BX, [enabled]
  MOV [collision], BX

  .snake_collision_loop_begin:
   CMP BX, ZERO
   JBE .skip_self
   MOV [collision], BX
   ADD BX, BX
   MOV CX, [x_coord+BX]
   MOV DX, [y_coord+BX]
   MOV BX, [collision]
   DEC BX
   CMP CX, [last_x]
   JNE .snake_collision_loop_begin
   CMP DX, [last_y]
   JNE .snake_collision_loop_begin

   JMP game_over ; si ambos son iguales reinicie program

  .skip_self:
  RET

game_over:
    CALL game_over_label
    JMP halt

DrawApple:
  MOV CX, [x_apple] ; posicion x del Pixel
  MOV DX, [y_apple] ; posicion y del Pixel
  MOV AL, 0x0C   ; Color del pixel
  CALL DrawPixel
  RET

DrawSnake:
   MOV BX, [enabled]
   MOV AL, 0x08
   MOV [t1], BX

   .draw_snake_loop_begin:
    CMP BX, ZERO
    JBE .skip_draw
    MOV [t1], BX
    ADD BX, BX
    MOV CX, [x_coord+BX]
    MOV DX, [y_coord+BX]
    CALL DrawPixel
    MOV AL, 0x0A ;cambio color para que el siguiente pixel se imprima del mismo color que la pantalla
    MOV CX, [x_coord]
    MOV DX, [y_coord]
    CALL DrawPixel
    MOV BX, [t1]
    DEC BX
    JMP .draw_snake_loop_begin

  .skip_draw:
  RET

ShiftArray:
  MOV BX, TOTAL_SEGMENTS ; mueve el arreglo de posiciones del Snake
  DEC BX
  ADD BX, BX            ;BX vale dos veces la cantidad maxima de elementos de snake
  .loop_begin:
   ADD BX, -2           ;resta 2 a BX
   MOV DX, [x_coord+BX] ;asigna la N-1 posicion de x a DX
   MOV CX, [y_coord+BX] ;asigna la N-1 posicion de y a CX
   ADD BX, 2            ; suma 2 a BX
   MOV [x_coord+BX], DX ; hace un swap de la N-1 posicion a la N posicion
   MOV [y_coord+BX], CX
   ADD BX, -2
   CMP BX, ZERO
   JNE .loop_begin
  MOV DX, [t1]
  MOV [x_coord], DX
  MOV DX, [t2]
  MOV [y_coord], DX
  RET

DrawPixel:
  MOV AH, 0x0C     ; Draw mode ; Coloca en modo write pixel
  MOV BH, 0x00     ; Pg 0
  INT 0x10         ; Draw
  RET

RandomNumber: ;genera un numero aleatorio
  RDTSC
  AND EAX, 0xF
  CMP AX, ZERO
  JL RandomNumber
  CMP AX, maxScreenX
  JG RandomNumber
  RET

  print_int: ; print the int in ax
  push bp ; save bp on the stack
  mov bp, sp ; set bp = stack pointer

  push_digits:
  xor dx, dx ; clear dx for division
  mov bx, 10 ; set bx to 10
  div bx ; divide by 10
  push dx ; store remainder on stack
  test ax, ax ; check if quotient is 0
  jnz push_digits ; if not, loop

  pop_and_print_digits:
  pop ax ; get first digit from stack
  add al, '0' ; turn it into ascii digits
  call print_char_int ; print it
  cmp sp, bp ; is the stack pointer is at where we began?
  jne pop_and_print_digits ; if not, loop
  pop bp ; if yes, restore bp
  ret

  print_char_int:
  mov ah, 0x0E ;t ell BIOS that we need to print one charater on screen
  mov bh, 0x00 ; page number
  mov bl, 0x07 ; text attribute 0x07 is lightgrey font on black background
  int 0x10
  ret

read_level_keys:
  mov ah, 0x00
  int 0x16
  cmp al, '1' ; Try with key 02
  ;   if tecla == 1 -> Start the game in the first level
  je .start_level_1
  cmp al, '2'
  je .start_level_2
  cmp al, '3'
  je .start_level_3
  CALL read_level_keys
  RET

  .start_level_1:
      mov dx, SCOREL1
      mov [score], dx
      mov dx, LEVEL1
      mov [SpeedLVL], dx
      RET

  .start_level_2:
      mov dx, SCOREL2
      mov [score], dx
      mov dx, LEVEL2
      mov [SpeedLVL], dx
      RET

  .start_level_3:
      mov dx, SCOREL3
      mov [score], dx
      mov dx, LEVEL3
      mov [SpeedLVL], dx
      RET
