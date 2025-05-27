	.equ SCREEN_WIDTH, 		640
	.equ SCREEN_HEIGH, 		480
	.equ BITS_PER_PIXEL,  	32

	.equ GPIO_BASE,      0x3f200000
	.equ GPIO_GPFSEL0,   0x00
	.equ GPIO_GPLEV0,    0x34

	.globl main

//---------------------------------FRAMEBUFFER---------------------------
fill_framebuffer:
	mov 	x2, SCREEN_HEIGH         // Y Size
loop1:
	mov 	x1, SCREEN_WIDTH         // X Size
loop0:
	stur 	w10,[x0]   // Colorear el pixel N
	add 	x0,x0,4	   // Siguiente pixel
	sub 	x1,x1,1	   // Decrementar contador X
	cbnz 	x1,loop0   // Si no terminó la fila, salto
	sub 	x2,x2,1	   // Decrementar contador Y
	cbnz 	x2,loop1   // Si no es la última fila, salto
ret_fb:
	ret

//----------------------------------RECTANGULO-----------------------------
draw_rectangle:
    // x0 = fb, x1 = screen_width, x2 = x, x3 = y, x4 = w, x5 = h, x6 = color

    mov     x7, #0              // fila actual

fila_loop_r:
    cmp     x7, x5				// terminamos con las filas?
    b.ge    ret_rectangle		// si fila actual >= alto del rectangulo, salta a ret_rectangle

	// calcular dirección de inicio de la fila: 
    // offset = ((y + fila) * 640 + x) * 4
    add     x8, x3, x7			// x8 = (y + fila)
    mul     x8, x8, x1			// x8 = (y + fila) * 640
    add     x8, x8, x2			// x8 = (y + fila) * 640 + x
    lsl     x8, x8, #2			// x8 = ((y + fila) * 640 + x) * 4 bytes por píxel
    add     x9, x0, x8			// x9 = puntero a inicio de fila = x20 + (y + fila) * 640 + x) * 4 bytes por píxel

    mov     x10, #0             // columna actual
col_loop_r:
    cmp     x10, x4				// terminamos con las columnas?
    b.ge    fin_fila_r			// si columna actual es >= que ancho del rectangulo, salta a fin_fila_r

    str     w6, [x9]			// pinta pixel
    add     x9, x9, #4			// avanza puntero
    add     x10, x10, #1		// aumenta en 1 el valor de columna actual (x10)
    b       col_loop_r			// salto incondicional a col_loop_r

fin_fila_r:
    add     x7, x7, #1			// aumenta en 1 el valor de fila actual (x7)
    b       fila_loop_r			// salto incondicional a fila_loop_r

ret_rectangle:
    ret


//----------------------------------TRIANGULO-----------------------------
draw_triangle:
    // x0 = fb, x1 = screen_width, x2 = x0, x3 = y0, x4 = altura, x5 = color

    mov     x6, #0				 // fila actual (desde 0 hasta altura - 1)

fila_loop_t:
    cmp     x6, x4
    b.ge    ret_triangle

	// Calcular cantidad de píxeles a dibujar en esta fila: ancho = 2*fila + 1
    lsl     x7, x6, #1			 // x7 = 2 * fila
    add     x7, x7, #1           // ancho fila = 2 * fila + 1

	// Calcular x inicial: x0 - fila
    sub     x8, x2, x6           // columna inicial para esta fila = x
	// Calcular y actual: y0 + fila
    add     x9, x3, x6           // fila actual = y

	// Calcular offset: ((y0 + fila) * 640 + (x0 - fila)) * 4
    mul     x10, x9, x1			 // x10 = y * ancho
    add     x10, x10, x8		 // x10 = (y * ancho) + x 
    lsl     x10, x10, #2		 // x10 = ((y * ancho) + x ) * 4
    add     x11, x0, x10		 // x11 = direccion base de la fila

	// Bucle para dibujar píxeles en esta fila
    mov     x12, #0				 // contador de píxeles
pix_loop_t:
    cmp     x12, x7
    b.ge    fin_fila_t

    str     w5, [x11]			 // pinta pixel
    add     x11, x11, #4		 // avanzar al siguiente píxel
    add     x12, x12, #1		 // aumenta en 1 el valor de x12
    b       pix_loop_t			 // salto incondicional a pix_loop_t

fin_fila_t:
    add     x6, x6, #1			 // aumenta en 1 el valor de x6
    b       fila_loop_t			 // salto incondicional a fila_loop_t

ret_triangle:
    ret

//----------------------------------CIRCULO--------------------------
draw_circle:
    // x0 = fb, x1 = screen_width, x2 = cx, x3 = cy, x4 = r, x5 = color

    sub     x6, x2, x4           // min_x = centro x - radio r
    add     x7, x2, x4           // max_x = centro x + radio r
    sub     x8, x3, x4           // min_y = centro y - radio r
    add     x9, x3, x4           // max_y = centro y + radio r
    mul     x10, x4, x4          // x10 = r^2

	// Bucle por y
    mov     x11, x8              // y = min_y

y_loop_c:
    cmp     x11, x9				 // compara y con max_y
    b.gt    ret_circle			 // si y > max_y, salta a ret_circle

    mov     x12, x6              // x = min_x

x_loop_c:
    cmp     x12, x7				 // compara x con max_x
    b.gt    next_y_c			 // si x > max_x, salta a next_y_c

	//dx = x - cx
    sub     x13, x12, x2
    mul     x14, x13, x13        // x14 = dx^2

	//dy = y - cy
    sub     x15, x11, x3
    mul     x16, x15, x15        // x16 = dy^2

    add     x17, x14, x16		 // x17 = dx^2 + dy^2
    cmp     x17, x10			 // compara x17(dx^2 + dy^2) con x10(r^2)
    b.gt    skip_c				 // si x17 > x10(esta fuera del circulo), salta a skip_c

	//pintar el pixel 
    mul     x18, x11, x1
    add     x18, x18, x12
    lsl     x18, x18, #2
    add     x18, x0, x18
    str     w5, [x18]			 // pinta pixel

skip_c:
    add     x12, x12, #1		 // incrementa x12 en 1
    b       x_loop_c			 // salto incondicional a x_loop_c

next_y_c:
    add     x11, x11, #1		 // incrementa x11 en 1
    b       y_loop_c			 // salto incondicional a y_loop_c

ret_circle:
    ret


main:
	// x0 contiene la direccion base del framebuffer
 	mov 	x20, x0				 // Guarda la dirección base del framebuffer en x20

	movz 	x10, 0x00, lsl 16
	movk 	x10, 0x9900, lsl 00
	bl 		fill_framebuffer

//-----------------RECTANGULO SUELO-----------------------------------------
 
    // Dibuja rectángulo
    mov     x0, x20              // framebuffer base
    mov     x1, #SCREEN_WIDTH
    mov     x2, #0            	 // x = columna inicial
    mov     x3, #0            	 // y = fila inicial
    mov     x4, #SCREEN_WIDTH    // ancho del rectangulo
    mov     x5, #250           	 // alto del rectangulo
    movz    x6, 0x00, lsl 16	 // color
    movk    x6, 0x1076, lsl 0	 // color
    bl      draw_rectangle
    
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ CARRETERA (BASE NEGRA DERECHA ) ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// Dibuja triángulo
    mov     x0, x20		  // framebuffer base
    mov     x1, #SCREEN_WIDTH     // Ancho de pantalla
    mov     x2, #320		  // x0: columna del vértice superior del triángulo
    mov     x3, #242	          // y0: fila del vértice superior
    mov     x4, #480		  // Altura del triángulo (en píxeles)
    movz    x5, 0x26, lsl 16      // Color 
    movk    x5, 0x2525, lsl 0     // Color
    bl      draw_triangle

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ CARRETERA (BASE NEGRA IZQUIERDA) ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// Dibuja triángulo
    mov     x0, x20			// framebuffer base
    mov     x1, #SCREEN_WIDTH		// Ancho de pantalla
    mov     x2, #280		        // x0: columna del vértice superior del triángulo
    mov     x3, #240			// y0: fila del vértice superior
    mov     x4, #480            	// Altura del triángulo (en píxeles)
    movz    x5, 0x26, lsl 16		// Color 
    movk    x5, 0x2525, lsl 0		// Color
    bl      draw_triangle


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ CARRETERA (BORDE BLANCO DERECHO) ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// Dibuja triángulo
    mov     x0, x20			// framebuffer base
    mov     x1, #SCREEN_WIDTH		// Ancho de pantalla
    mov     x2, #310			// x0: columna del vértice superior del triángulo
    mov     x3, #241     	        // y0: fila del vértice superior
    mov     x4, #480            	// Altura del triángulo (en píxeles)
    movz    x5, 0xff, lsl 16		// Color 
    movk    x5, 0xffff, lsl 0		// Color
    bl      draw_triangle

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ CARRETERA (BORDE BLANCO IZQUIERDO) ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// Dibuja triángulo
    mov     x0, x20		        // framebuffer base
    mov     x1, #SCREEN_WIDTH		// Ancho de pantalla
    mov     x2, #290			// x0: columna del vértice superior del triángulo
    mov     x3, #241	                // y0: fila del vértice superior
    mov     x4, #480            	// Altura del triángulo (en píxeles)
    movz    x5, 0xff, lsl 16		// Color 
    movk    x5, 0xffff, lsl 0		// Color
    bl      draw_triangle


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ CARRETERA (CENTRAL) ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// Dibuja triángulo
    mov     x0, x20		        // framebuffer base
    mov     x1, #SCREEN_WIDTH		// Ancho de pantalla
    mov     x2, #300			    // x0: columna del vértice superior del triángulo
    mov     x3, #238				// y0: fila del vértice superior
    mov     x4, #480            	// Altura del triángulo (en píxeles)
    movz    x5, 0x26, lsl 16		// Color 
    movk    x5, 0x2525, lsl 0		// Color
    bl      draw_triangle


//-------------------TRIANGULO MONTAÑA IZQ-----------------------------------
    // Dibuja triángulo
    mov     x0, x20					// framebuffer base
    mov     x1, #SCREEN_WIDTH		// Ancho de pantalla
    mov     x2, #100				// x0: columna del vértice superior del triángulo
    mov     x3, #100				// y0: fila del vértice superior
    mov     x4, #150				// Altura del triángulo (en píxeles)
    movz    x5, 0x91, lsl 16		// Color 
    movk    x5, 0x7506, lsl 0		// Color
    bl      draw_triangle

//-------------------TRIANGULO MONTAÑA MEDIO------------------------------------
    // Dibuja triángulo
    mov     x0, x20					// framebuffer base
    mov     x1, #SCREEN_WIDTH		// Ancho de pantalla
    mov     x2, #400				// x0: columna del vértice superior del triángulo
    mov     x3, #100				// y0: fila del vértice superior
    mov     x4, #150				// Altura del triángulo (en píxeles)
    movz    x5, 0x69, lsl 16		// Color 
    movk    x5, 0x4720, lsl 0		// Color
    bl      draw_triangle
//-------------------TRIANGULO MONTANA DER-------------------------------------
    // Dibuja triángulo
    mov     x0, x20					// framebuffer base
    mov     x1, #SCREEN_WIDTH		// Ancho de pantalla
    mov     x2, #550				// x0: columna del vértice superior del triángulo
    mov     x3, #100				// y0: fila del vértice superior
    mov     x4, #150				// Altura del triángulo (en píxeles)
    movz    x5, 0x91, lsl 16		// Color 
    movk    x5, 0x7506, lsl 0		// Color
    bl      draw_triangle

//--------------------------CIRCULO LUNA---------------------------------------
    // Dibuja círculo	
    mov     x0, x20					 // framebuffer base
    mov     x1, #SCREEN_WIDTH		 // Ancho de pantalla
    mov     x2, #250				 // cx (centro x)
    mov     x3, #100				 // cy (centro y)
    mov     x4, #30			         // radio r
    movz    x5, 0xFF, lsl 16		 // color
    movk    x5, 0xFFFF, lsl 0		 // color
    bl      draw_circle
//~~~~~~~~~~ POSTE DERECHO  ~~~~~~~~~~~~~

    // Dibuja rectángulo
    mov     x0, x20              // framebuffer base
    mov     x1, #SCREEN_WIDTH
    mov     x2, #140             // x = columna inicial
    mov     x3, #180             // y = fila inicial
    mov     x4, #15              // ancho del rectangulo
    mov     x5, #180          	 // alto del rectangulo
    movz    x6, 0x56, lsl 16	 // color
    movk    x6, 0x5757, lsl 0	 // color
    bl      draw_rectangle

//~~~~~~~~~~ SOPORTE DEL POSTE  ~~~~~~~~~~~~~

    // Dibuja rectángulo
    mov     x0, x20              // framebuffer base
    mov     x1, #SCREEN_WIDTH
    mov     x2, #140             // x = columna inicial
    mov     x3, #180             // y = fila inicial
    mov     x4, #300              // ancho del rectangulo
    mov     x5, #15         	 // alto del rectangulo
    movz    x6, 0x56, lsl 16	 // color
    movk    x6, 0x5757, lsl 0	 // color
    bl      draw_rectangle

//~~~~~~~~~~ POSTE IZQUIERDO  ~~~~~~~~~~~~~

    // Dibuja rectángulo
    mov     x0, x20              // framebuffer base
    mov     x1, #SCREEN_WIDTH
    mov     x2, #440            // x = columna inicial
    mov     x3, #180             // y = fila inicial
    mov     x4, #15              // ancho del rectangulo
    mov     x5, #180          	 // alto del rectangulo
    movz    x6, 0x56, lsl 16	 // color
    movk    x6, 0x5757, lsl 0	 // color
    bl      draw_rectangle


//~~~~~~~~~~ CARTEL BASE BLANCA ~~~~~~~~~~~~~
  
    // Dibuja rectángulo
    mov     x0, x20              // framebuffer base
    mov     x1, #SCREEN_WIDTH
    mov     x2, #196         	 // x = columna inicial
    mov     x3, #165         	 // y = fila inicial
    mov     x4, #208             // ancho del rectangulo
    mov     x5, #75       	     // alto del rectangulo
    movz    x6, 0xff, lsl 16	 // color
    movk    x6, 0xffff, lsl 0	 // color
    bl      draw_rectangle


//~~~~~~~~~~ CARTEL BASE VERDE ~~~~~~~~~~~~~
  
    // Dibuja rectángulo
    mov     x0, x20                // framebuffer base
    mov     x1, #SCREEN_WIDTH
    mov     x2, #200          	   // x = columna inicial
    mov     x3, #168              // y = fila inicial
    mov     x4, #200               // ancho del rectangulo
    mov     x5, #70     	      // alto del rectangulo
    movz    x6, 0x12, lsl 16	  // color
    movk    x6, 0x5d28, lsl 0	  // color
    bl      draw_rectangle

	// Ejemplo de uso de gpios
	mov x9, GPIO_BASE

	// Atención: se utilizan registros w porque la documentación de broadcom
	// indica que los registros que estamos leyendo y escribiendo son de 32 bits

	// Setea gpios 0 - 9 como lectura
	str wzr, [x9, GPIO_GPFSEL0]

	// Lee el estado de los GPIO 0 - 31
	ldr w10, [x9, GPIO_GPLEV0]

	// And bit a bit mantiene el resultado del bit 2 en w10
	and w11, w10, 0b10

	// w11 será 1 si había un 1 en la posición 2 de w10, si no será 0
	// efectivamente, su valor representará si GPIO 2 está activo
	lsr w11, w11, 1

	//---------------------------------------------------------------
	// Infinite Loop

InfLoop:
	b InfLoop
