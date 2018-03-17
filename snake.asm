;Snake!
[BITS 16]
[ORG 0x0000]

TOTAL_SEGMENTS equ 0x42

ZERO equ 0x00
SIZE_PIX equ 0x02

maxScreenX equ 50d
maxScreenY equ 50d



UP equ 0x48
LEFT equ 0x4B
RIGHT equ 0x4D
DOWN equ 0x50

LEVEL1 equ 0x0004
LEVEL2 equ 0x0002
LEVEL3 equ 0x0001


SCOREL1 equ 0x0
SCOREL2 equ 0x5 ;0x64 100
SCOREL3 equ 0xA ;0xC8 200

;checkScore
;grow score
;print score

section .bss
  x_coord   RESW TOTAL_SEGMENTS ; [x_coord] is the head, [x_coord+2] is the next cell, etc.
  y_coord   RESW TOTAL_SEGMENTS ; Same here
  t1        RESB 2
  t2        RESB 2
  enabled   RESB 2  ;cantidad de elemetos de la serpiente
  x_apple   RESB 2
  y_apple   RESB 2

  last_x   RESB 2
  last_y   RESB 2
  collision RESB 2

  last_move RESB 2

  score     RESB 2

  SpeedLVL  RESB 2


section  .text
global_start

_start:
  MOV DX, LEVEL1  ;CONFIGURATE LVL
  MOV [SpeedLVL], DX

  MOV DX, 0x00
  MOV [score], DX

  MOV DX, UP
  MOV [last_move], DX
  CALL SetVideoMode
  CALL SetInitialCoords
  CALL SetScreen
  mov	ax, 0x0305
	mov	bx, 0x031F
	int	0x16		; increase delay before keybort repeat
  CALL ListenForInput

SetVideoMode:
  MOV AH, 0x00
  MOV AL, 0x13
  INT 0x10
  RET

SetScreen:
  MOV CX, 0x00 ;Coordenada de inicio en x o y
  MOV DX, 0x00 ;Coordenada de inicio en x o y
  MOV AL, 0x08 ; Color de la pantalla
  MOV BH, 0x00
  MOV AH, 0x0C ;modo writePixel
  .x_loop_begin:
   MOV CX, 0x00
   .y_loop_begin:
    INT 0x10
    INC CX
    CMP CX, maxScreenX ; final de la pantalla en x
    JNAE .y_loop_begin
   .y_loop_end:
   INC DX
   CMP DX, maxScreenY ; final de la pantalla en y
   JNAE .x_loop_begin
  .x_loop_end:
  RET

SetInitialCoords:
  MOV AX, 0x0F ; Initial x/y coord
  MOV BX, 0x00
  MOV DX, TOTAL_SEGMENTS
  ADD DX, DX

  .initialize_loop_begin: ;esta porcion le asigna un valor de la coordenada a cada elemento dentro de los arreglos x,y
   MOV [x_coord+BX], AX
   MOV [y_coord+BX], AX
   ADD BX, SIZE_PIX
   CMP BX, DX
   JNE .initialize_loop_begin

  MOV AX, ZERO
  MOV [t1]       , AX
  MOV [t2]       , AX
  MOV AX, 5             ;numero de elementos con el que va a iniciar
  MOV [enabled]  , AX

  CALL RandomNumber ;set first apple
  MOV [x_apple], AX
  CALL RandomNumber
  MOV [y_apple], AX
  RET

ListenForInput:  ;Repeatedly check for keyboard input
  mov	ah, 0x01	; check if key available
  int	0x16
  jz done_clear
  mov	ah, 0x00	; if there was a key, remove it from buffer
  int	0x16
  JMP continue

  done_clear:
    mov	ah, [last_move]	; no keys, so we use the last one

  continue:
  CALL InterpretKeypress

  sleep:
    mov	cx, [SpeedLVL]	; Sleep for 0,15 seconds (cx:dx)
    mov	dx, 0x49F0	; 0x000249F0 = 150000
    mov	ah, 0x86
    int	0x15		; Sleep

  CALL ListenForInput
  RET

InterpretKeypress:
  CMP AH, UP  ; compara la tecla presionada con w
  MOV	[last_move], AH	; save the direction
  JE .u_pressed

  CMP AH, LEFT ;compara la tecla presionada con a
  MOV	[last_move], AH	; save the direction
  JE .l_pressed

  CMP AH, DOWN ; compara la tecla presionada con s
  MOV	[last_move], AH	; save the direction
  JE .d_pressed

  CMP AH, RIGHT ; compara la tecla presionada con d
  MOV	[last_move], AH	; save the direction
  JE .r_pressed

  RET ; Invalid keypress, start listening again

  .u_pressed:
  MOV AX, [x_coord]
  MOV BX, [y_coord]
  DEC BX                    ; para decrementar la posicion de los pixeles se debe tomar en cuenta el tamaño del pixel
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

  .after_control_handle:  ; coloca en t1 y t2 posicion capturada al mover la serpiente
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
  RET

CheckLVL:
    MOV DX, [score]
    CMP DX, SCOREL2
    JE .setLVL2
    CMP DX, SCOREL3
    JE .setLVL3
    JMP .end

  .setLVL2:
    MOV DX, LEVEL2
    MOV [SpeedLVL], DX
    JMP .end

  .setLVL3:
    MOV DX, LEVEL3
    MOV [SpeedLVL], DX

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
  CMP AX, maxScreenX ;verifica si la posicion x de la manzana es igual a la cabeza del snake
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
  CALL game_over ; reinicia el juego si choca

CheckSelfCollision:
  MOV BX, [enabled]
  ;MOV [col], BX

  .snake_collision_loop_begin:
   CMP BX, ZERO
   JBE .skip
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
   CALL game_over ; si ambos son iguales reinicie program

  .skip:
  RET

game_over:
    JMP _start

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
    JBE .skip
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

  .skip:
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
