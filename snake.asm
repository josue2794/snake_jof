;Snake game
[BITS 16] 		  ; Set in real mode 	
[ORG 0x0000]      ; This code is intended to be loaded starting at 0x1000:0x0000

TOTAL_SEGMENTS equ 0x42

ZERO equ 0x00
SIZE_PIX equ 0x02

maxScreenX equ 0x32
maxScreenY equ 0x32


DOWN equ 0x50
UP equ 0x48
LEFT equ 0x4B
RIGHT equ 0x4D

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
  MOV DX, 0x77
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

  .initialize_loop_begin: ; parece que esta porcion le asigna un valor de la coordenada a cada elemento dentro de los arreglos x,y
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
    mov	al, [last_move]	; no keys, so we use the last one

  continue:
  CALL InterpretKeypress

  sleep:
    mov	cx, 0x0002	; Sleep for 0,15 seconds (cx:dx)
    mov	dx, 0x49F0	; 0x000249F0 = 150000
    mov	ah, 0x86
    int	0x15		; Sleep



  CALL ListenForInput
  RET



InterpretKeypress:
  CMP AL, 0x77  ; compara la tecla presionada con w
  MOV	[last_move], AL	; save the direction
  JE .u_pressed


  CMP AL, 0x61 ;compara la tecla presionada con a
  MOV	[last_move], AL	; save the direction
  JE .l_pressed


  CMP AL, 0x73 ; compara la tecla presionada con s
  MOV	[last_move], AL	; save the direction
  JE .d_pressed

  CMP AL, 0x64 ; compara la tecla presionada con d
  MOV	[last_move], AL	; save the direction
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
  CALL CheckWallCollision
  CALL CheckAppleCollision
  CALL ShiftArray
  CALL DrawSnake
  CALL DrawApple
  RET

CheckAppleCollision:
  CMP AX, [x_apple] ;verifica si la posicion x de la manzana es igual a la cabeza del snake
  JNE .no_collision

  CMP BX, [y_apple] ;verifica si la posicion y de la manzana es igual a la cabeza del snake
  JNE .no_collision

  MOV AX, [enabled] ; Cuando colisiona con la manzana se incrementa en 1 enabled
  INC AX
  MOV [enabled], AX

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
  JE .collision_w

  CMP BX, ZERO ;verifica si la posicion y de la manzana es igual a la cabeza del snake
  JE .collision_w

  RET
  ;Colocar mensaje de perder


  .collision_w:
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
    MOV AL, 0x0A
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
  RET
