;*******************************************************************************
;                                                                              *
;    Filename: Snake PIC                                                       *
;    Date: 27/maio/2020 - 10/junho/2020                                        *
;    File Version: 1.0.0                                                       *
;    Author: Lucas Rezende , Riccardo Cafagna                                  *
;    Company: Senai Cimatec                                                    *
;    Description: Por meio das teclas 2, 4, 6 e 8 do teclado matricial,        *
;    controle uma cobrinha que passeia pelos 4 displays de 7 segmentos         *
;                                                                              *
;*******************************************************************************

#include    "p16f877a.inc"
    
;*******************************************************************************
; Configuration Word Setup
;*******************************************************************************
    
 __CONFIG _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CP_OFF

    
;*******************************************************************************
; Variable Definitions
;*******************************************************************************

; Byte to set display 4
DSP4E	EQU	B'00100000'
; Byte to set display 3
DSP3E	EQU	B'00010000'
; Byte to set display 2
DSP2E	EQU	B'00001000'
; Byte to set display 1
DSP1E	EQU	B'00000100'
	
UDIR	EQU	D'0'
DDIR	EQU	D'1'
RDIR	EQU	D'2'
LDIR	EQU	D'3'
	
; Bit display 1
DSP1P    EQU    D'2'
; Bit display 2
DSP2P    EQU    D'3'
; Bit display 3
DSP3P    EQU    D'4'
; Bit display 4
DSP4P    EQU    D'5'
	
; Timer to set interrupt timer
TMRVAL  EQU    D'12'
    
; Bit - 0 if looking down, 1 if looking up
VER	EQU	D'0'
; Bit - 0 if looking right, 1 if looking left
HOR	EQU	D'1'
	
; North display position
_N	EQU	D'0'
; North East display position
_NE	EQU	D'1'
; South East display position
_SE	EQU	D'2'
; South display position
_S	EQU	D'3'
; South West display position
_SW	EQU	D'4'
; North West display position
_NW	EQU	D'5'
; Center display position
_C	EQU	D'6'
; Dot (food) display position
_DOT	EQU	D'7'
 
; Varaibles declaration
GPR_VAR	UDATA
; Byte to be set on PORTD for display 1
DSP1	RES	1
; Byte to be set on PORTD for display 2
DSP2	RES	1
; Byte to be set on PORTD for display 3
DSP3	RES	1
; Byte to be set on PORTD for display 4
DSP4	RES	1
; Iterator to update DSPIT times the display
DSPIT	RES	1
; Iterator to update KBRDIT times the display
KBRDIT	RES	1
; Variable to make 1MS delay
_1MS	RES	1
; The head snake position
SNKPOS0	RES	1
; The tail snake position
SNKPOS1	RES	1
; The head snake display bit
SNKDSP0	RES	1
; The tail snake display bit
SNKDSP1	RES	1
; Which 'arrow' direction the player has pressed
DIR	RES	1
; The head byte where the snake is looking
HEAD	RES	1
; A temporary variable
VALUE	RES	1
; The food display position
FOOD    RES	1
; The next food value to be setted
NXTF    RES	1
; A auxiliary counter for timer interruption
AUXC    RES	1
	
;*******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000
    GOTO    START

;*******************************************************************************
; Interrupt Service Routines
;*******************************************************************************

ISR       CODE    0x0004
    ; Check if the timer interruption flag is setted
    BTFSC   INTCON, TMR0IF
    ; Then get a random food value to NXTF
    CALL    RNDFOOD
    RETFIE

;*******************************************************************************
; Functions
;*******************************************************************************
    
; Bank functions set
BANK0	MACRO ; Bank 0 - 00
    BCF	    STATUS, RP1
    BCF	    STATUS, RP0
    ENDM
    
BANK1	MACRO ; Bank 1 - 01
    BCF	    STATUS, RP1
    BSF	    STATUS, RP0
    ENDM
    
; Resets snake values
SNK_RST MACRO
    ; Clear snake head position and set initial value
    CLRF    SNKPOS0
    BSF	    SNKPOS0, _N
    ; Clear snake tail position and set initial value
    CLRF    SNKPOS1
    BSF	    SNKPOS1, _NW
    ; Set the head and tail display to be the first
    MOVLW   DSP1E
    MOVWF   SNKDSP0
    MOVWF   SNKDSP1
    ; Set the head to be looking at south east
    BSF	    HEAD, HOR
    BCF	    HEAD, VER
    ; Set a initial value for the food variables
    MOVLW   B'00100000'
    MOVWF   NXTF
    MOVWF   FOOD
    ENDM
    
;*******************************************************************************

; Set the snake position with value setted regards to the display
SET_POS
    MOVFW   SNKPOS0
    MOVWF   SNKPOS1
    MOVFW   VALUE
    MOVWF   SNKPOS0
    RETURN
; Set the display to the tail with the value of the head display
SET_DSP
    MOVFW   SNKDSP0
    MOVWF   SNKDSP1
    RETURN
    
;*******************************************************************************
; move logic
;*******************************************************************************
    
; Manages the up event
UP_MANAGER
    ; Clear the temporary value
    CLRF    VALUE
    
    ; Check the snake position
    BTFSC   SNKPOS0, _N
    GOTO    KBRD_LOOP	; There's nothing up there, go back to loop
    BTFSC   SNKPOS0, _NE
    GOTO    KBRD_LOOP	; There's nothing up there, go back to loop
    BTFSC   SNKPOS0, _SE
    GOTO    UP_SE	; Check if the snake can go to South East
    BTFSC   SNKPOS0, _S
    GOTO    UP_S	; Check if the snake can go to South
    BTFSC   SNKPOS0, _SW
    GOTO    UP_SW	; Check if the snake can go to South West
    BTFSC   SNKPOS0, _NW
    GOTO    KBRD_LOOP	; There's nothing up there, go back to loop
    BTFSC   SNKPOS0, _C
    GOTO    UP_C	; Check if the snake can go to the Center
END_UP			; Finalize the up movement
    BSF	    HEAD, VER	; Set the head to be looking upward
    CALL    SET_POS	; Set the position
    CALL    SET_DSP	; Set the tail display
    RETURN

UP_SE			; Trying to go up to South East
    BTFSC   HEAD, VER	; if looking upward
    BSF	    VALUE, _NE	;   then go to North East
    BTFSS   HEAD, VER	; else if looking downward
    GOTO    KBRD_LOOP	;   don't move
    GOTO    END_UP	; Finalize movement
UP_S			; Trying to go up to South
    BTFSC   HEAD, HOR	; if looking at East
    BSF	    VALUE, _SE	;   go to South East
    BTFSS   HEAD, HOR	; if looking at West
    BSF	    VALUE, _SW	;   go to South West
    GOTO    END_UP
UP_SW			; Trying to go up to South West
    BTFSC   HEAD, VER	; if looking upward
    BSF	    VALUE, _NW	;   go to North West
    BTFSS   HEAD, VER	; else if looking downward
    GOTO    KBRD_LOOP	;   don't move
    GOTO    END_UP	; Finalize
UP_C			; Trying to go up to Center
    BTFSC   HEAD, HOR	; if looking at East
    BSF	    VALUE, _NE	;   go to North East
    BTFSS   HEAD, HOR	; else if looking at West
    BSF	    VALUE, _NW	;   go to North West
    GOTO    END_UP	; Finalize  
 
DOWN_MANAGER ; Same Logic of Up, however for the down movement
    CLRF    VALUE
    
    BTFSC   SNKPOS0, _N
    GOTO    DOWN_N
    BTFSC   SNKPOS0, _NE
    GOTO    DOWN_NE
    BTFSC   SNKPOS0, _SE
    GOTO    KBRD_LOOP
    BTFSC   SNKPOS0, _S
    GOTO    KBRD_LOOP
    BTFSC   SNKPOS0, _SW
    GOTO    KBRD_LOOP
    BTFSC   SNKPOS0, _NW
    GOTO    DOWN_NW
    BTFSC   SNKPOS0, _C
    GOTO    DOWN_C
END_DOWN
    BCF	    HEAD, VER
    CALL    SET_POS
    CALL    SET_DSP
    RETURN

DOWN_N			; Trying to go down at North
    BTFSC   HEAD, HOR	; if looking East
    BSF	    VALUE, _NE	;   go to North East
    BTFSS   HEAD, HOR	; else if looking West
    BSF	    VALUE, _NW	;   go to North West
    GOTO    END_DOWN	; Finalize
DOWN_NE			; Trying to go down at North East
    BTFSC   HEAD, VER	; if looking upward
    GOTO    KBRD_LOOP	;   don't move
    BTFSS   HEAD, VER	; else if looking downward
    BSF	    VALUE, _SE	;   go to South East
    GOTO    END_DOWN	; Finalize
DOWN_NW			; Trying to go down at North West
    BTFSC   HEAD, VER	; if looking upward
    GOTO    KBRD_LOOP	;   don't move
    BTFSS   HEAD, VER	; else if looking downward
    BSF	    VALUE, _SW	;   go to South West
    GOTO    END_DOWN	; Finalize
DOWN_C			; Trying to go down at Center
    BTFSC   HEAD, HOR	; if looking East
    BSF	    VALUE, _SE	;   go to South East
    BTFSS   HEAD, HOR	; else if looking West
    BSF	    VALUE, _SW	;   go to South West
    GOTO    END_DOWN	; Finalize

RIGHT_MANAGER	; Same logic, but has a rotation of display.
    CLRF    VALUE
    
    BTFSC   SNKPOS0, _N
    GOTO    JUST_RIGHT	; Left Rotate display and just goes to east
    BTFSC   SNKPOS0, _NE
    GOTO    RIGHT_NE
    BTFSC   SNKPOS0, _SE
    GOTO    RIGHT_SE
    BTFSC   SNKPOS0, _S
    GOTO    JUST_RIGHT	; Left Rotate display and just goes to east
    BTFSC   SNKPOS0, _SW
    GOTO    RIGHT_SW
    BTFSC   SNKPOS0, _NW
    GOTO    RIGHT_NW
    BTFSC   SNKPOS0, _C
    GOTO    JUST_RIGHT	; Left Rotate display and just goes to east
END_RIGHT
    BSF	    HEAD, HOR
    CALL    SET_POS
    RETURN

RR_DSP	    ; Try go to next display
    BTFSS   HEAD, HOR	    ; if looking to west
    RETURN		    ;   don't move
    BTFSC   SNKDSP0, DSP4P  ; if the snake is at Display 4
    RETURN		    ;	don't move
    BTFSS   SNKDSP0, DSP4P  ; else
    CALL    RR_IF	    ;   Go to next display
    GOTO    END_RIGHT
RR_IF
    CALL    SET_DSP	    ; Set tail display to be previous head display
    RLF	    SNKDSP0, F	    ; Left Rotate the snake display
    RETURN
    
RIGHT_NE		; Trying to go east at North East
    BTFSC   HEAD, VER	; if looking upward
    BSF	    VALUE, _N	;   go to North
    BTFSS   HEAD, VER	; else 
    BSF	    VALUE, _C	;   go to Center
    GOTO    RR_DSP	; Try go to next display
RIGHT_SE		; Trying to go East at South East
    BTFSC   HEAD, VER	; if looking upward
    BSF	    VALUE, _C	;   go to Center
    BTFSS   HEAD, VER	; else
    BSF	    VALUE, _S	;   go to South
    GOTO    RR_DSP	; Try go to next display
RIGHT_SW		; Trying to go to east at South West
    BTFSC   HEAD, VER	; if looking upward
    BSF	    VALUE, _C	;   go to Center
    BTFSS   HEAD, VER	; else 
    BSF	    VALUE, _S	;   go to South
    GOTO    END_RIGHT	; Finalize
RIGHT_NW		; Trying to go to east at North West
    BTFSC   HEAD, VER	; if looking upward
    BSF	    VALUE, _N	;   go to North
    BTFSS   HEAD, VER	; else 
    BSF	    VALUE, _C	;   got to Center
    GOTO    END_RIGHT	; Finalize
JUST_RIGHT  ; Just goes to East Display without changing position (middle positions)
    MOVFW   SNKPOS0
    MOVWF   VALUE
    GOTO    RR_DSP

LEFT_MANAGER ; Same Logic of Right, however for the west movement
    CLRF   VALUE
    
    BTFSC   SNKPOS0, _N
    GOTO    JUST_LEFT
    BTFSC   SNKPOS0, _NE
    GOTO    LEFT_NE
    BTFSC   SNKPOS0, _SE
    GOTO    LEFT_SE
    BTFSC   SNKPOS0, _S
    GOTO    JUST_LEFT
    BTFSC   SNKPOS0, _SW
    GOTO    LEFT_SW
    BTFSC   SNKPOS0, _NW
    GOTO    LEFT_NW
    BTFSC   SNKPOS0, _C
    GOTO    JUST_LEFT
END_LEFT
    BCF	    HEAD, HOR
    CALL    SET_POS
    RETURN

RL_DSP			    ; Try go to previous display
    BTFSC   HEAD, HOR	    ; if looking at East
    RETURN		    ;   don't move
    BTFSC   SNKDSP0, DSP1P  ; else if at Display 1
    RETURN		    ;	don't move
    BTFSS   SNKDSP0, DSP1P  ; else 
    CALL    RL_IF	    ;   go to previous display
    GOTO    END_LEFT	    ; Finalize
RL_IF
    CALL    SET_DSP	    ; Set tail display to be previous head
    RRF	    SNKDSP0, F	    ; Right Rotate display
    RETURN

LEFT_NE			; Trying to go west at North East
    BTFSC   HEAD, VER	; if looking upward
    BSF	    VALUE, _N	;   go to North
    BTFSS   HEAD, VER	; else 
    BSF	    VALUE, _C	;   go to Center
    GOTO    END_LEFT
LEFT_SE			; Trying to go west at South East
    BTFSC   HEAD, VER	; if looking upward
    BSF	    VALUE, _C	;   go to Center
    BTFSS   HEAD, VER	; else
    BSF	    VALUE, _S	;   go to South
    GOTO    END_LEFT
LEFT_SW			; Trying to go west at South West
    BTFSC   HEAD, VER	; if looking upward
    BSF	    VALUE, _C	;   go to Center
    BTFSS   HEAD, VER	; else
    BSF	    VALUE, _S	;   go to South
    GOTO    RL_DSP	; Change display
LEFT_NW			; Trying to go west at North West
    BTFSC   HEAD, VER	; if looking upward
    BSF	    VALUE, _N	;   go to North
    BTFSS   HEAD, VER	; else
    BSF	    VALUE, _C	;   go to Center
    GOTO    RL_DSP	; go to previous display
JUST_LEFT
    MOVFW   SNKPOS0
    MOVWF   VALUE
    GOTO    RL_DSP
    
SNKMOV
    ; if up arrow pressed, manages up movement
    BTFSC   DIR, UDIR
    CALL    UP_MANAGER
    
    ; if down arrow pressed, manages down movement
    BTFSC   DIR, DDIR
    CALL    DOWN_MANAGER
    
    ; if right arrow pressed, manages right movement
    BTFSC   DIR, RDIR
    CALL    RIGHT_MANAGER
    
    ; if left arrow pressed, manages left movement
    BTFSC   DIR, LDIR
    CALL    LEFT_MANAGER
    
    ; Clear all positions
    CLRF    DSP1
    CLRF    DSP2
    CLRF    DSP3
    CLRF    DSP4

    ; Move snake head position to W
    MOVFW   SNKPOS0
    
    ; Check which display the snake head is
    BTFSC   SNKDSP0, DSP1P
    CALL    MNG_DSP1
    
    BTFSC   SNKDSP0, DSP2P
    CALL    MNG_DSP2
    
    BTFSC   SNKDSP0, DSP3P
    CALL    MNG_DSP3
    
    BTFSC   SNKDSP0, DSP4P
    CALL    MNG_DSP4
 
    ; Move snake tail position to W
    MOVFW   SNKPOS1
    
    ; Check which display the tail position is
    BTFSC   SNKDSP1, DSP1P
    IORWF   DSP1	; inclusive or to add the tail position to display
    BTFSC   SNKDSP1, DSP2P
    IORWF   DSP2
    BTFSC   SNKDSP1, DSP3P
    IORWF   DSP3
    BTFSC   SNKDSP1, DSP4P
    IORWF   DSP4
    
    RETURN

MNG_DSP1		; With the head position in W
    MOVWF   DSP1	; Moves W to Display
    BTFSC   FOOD, DSP1P ; Check if there's a food in this display
    CALL    GETFOOD	    ; Then get the food
    RETURN		
    
MNG_DSP2
    MOVWF   DSP2
    BTFSC   FOOD, DSP2P
    CALL    GETFOOD
    RETURN
    
MNG_DSP3
    MOVWF   DSP3
    BTFSC   FOOD, DSP3P
    CALL    GETFOOD
    RETURN
    
MNG_DSP4
    MOVWF   DSP4
    BTFSC   FOOD, DSP4P
    CALL    GETFOOD
    RETURN
    
;***************** FOOD LOGIC ******************
SHOWFOOD ; check in which display the food is
    BTFSC   FOOD, DSP1P	; if display 1
    BSF     DSP1, _DOT	; set the dot bit
    
    BTFSC   FOOD, DSP2P	; if display 2
    BSF     DSP2, _DOT	; set the dot bit
    
    BTFSC   FOOD, DSP3P	; if display 3
    BSF     DSP3, _DOT	; set the dot bit
    
    BTFSC   FOOD, DSP4P	; if display 4
    BSF     DSP4, _DOT	; set the dot bit
    RETURN
    
CONFIG_INTER ; timer interruption config
    BANK1
    CLRF    TRISD
    
    BCF     OPTION_REG, PSA ; set PSA flag to 0, to activate timer0
    BSF     OPTION_REG, PS2 
    BSF     OPTION_REG, PS1
    BSF     OPTION_REG, PS0 ; set the time rate to be 256
    BANK0
    
    MOVLW   D'12' ; set the TMR0 to 12
    MOVWF   TMR0
    
    MOVLW   TMRVAL  ; set a auxiliar value
    MOVWF   AUXC
 
    BCF     INTCON, TMR0IF  ; clear the timer interruption flag
    BSF	    INTCON, TMR0IE  ; enable the timer interruption
    BSF	    INTCON, GIE	    ; enable the global interruption
    RETURN
    
RNDFOOD ; get a pseudo-random food position
    BCF	    INTCON, TMR0IF ; clear the timer interruption flag
    
    ; decrements auxc
    DECFSZ  AUXC
    RETURN
    
    ; shift right next food bit
    RRF     NXTF, 1
    ; clamp the next food to be between 2 and 5
    BTFSC   NXTF, 1
    CALL    CLAMPFOOD
    BTFSC   NXTF, 0
    CALL    CLAMPFOOD
    BTFSC   NXTF, 7
    CALL    CLAMPFOOD
    BTFSC   NXTF, 6
    CALL    CLAMPFOOD
    
    ; Reset auxiliar variable
    MOVLW   TMRVAL
    MOVWF   AUXC
    
    RETURN

CLAMPFOOD ; Indeed, it just ceil to 4
    CLRF    NXTF
    BSF     NXTF, DSP4P 
    RETURN
    
GETFOOD ; attribute the next food value
    MOVFW   NXTF
    MOVWF   FOOD
    CALL    CLAMPFOOD
    RETURN
    
;*******************************************************************************
    
DISPLAY	    ; manages the 7 segment display
    BANK1   ; set the right bank
    CLRF    TRISA
    CLRF    TRISD
    BANK0
    
    MOVLW   DSP4E ; set display 4
    MOVWF   PORTA
    MOVFW   DSP4
    MOVWF   PORTD
    CALL    DELAY_2MS
    
    MOVLW   DSP3E ; set display 3
    MOVWF   PORTA
    MOVFW   DSP3
    MOVWF   PORTD
    CALL    DELAY_2MS
    
    MOVLW   DSP2E ; set display 2
    MOVWF   PORTA
    MOVFW   DSP2
    MOVWF   PORTD
    CALL    DELAY_2MS
    
    MOVLW   DSP1E ; set display 1
    MOVWF   PORTA
    MOVFW   DSP1
    MOVWF   PORTD
    CALL    DELAY_2MS
    RETURN
    
KBRD_READ ; push-button keyboard read
    CALL    KBRD_CONFIG ; configurate the keyboard
    
    BCF	    PORTB, RB0 
    CALL    DELAY_2MS
    BTFSS   TRISD, RD2	; left
    CALL    PRESS_LEFT
    CALL    DELAY_2MS
    BSF	    PORTB, RB0
    CALL    DELAY_2MS
    
    BCF	    PORTB, RB1
    CALL    DELAY_2MS
    BTFSS   TRISD, RD1	; down
    CALL    PRESS_DOWN
    CALL    DELAY_2MS
    BTFSS   TRISD, RD3	; up
    CALL    PRESS_UP
    BSF	    PORTB, RB1
    CALL    DELAY_2MS
    
    BCF	    PORTB, RB2
    CALL    DELAY_2MS
    BTFSS   TRISD, RD2	; right
    CALL    PRESS_RIGHT
    BSF	    PORTB, RB2
    CALL    DELAY_2MS
    RETURN

PRESS_UP ; if pressed 2 (up)
    CLRF    DIR ; set the new direction
    BSF	    DIR, UDIR
    CALL    SNKMOV ; moves the snake
    RETURN
PRESS_DOWN ; if pressed 8 (down)
    CLRF    DIR ; set the new direction
    BSF	    DIR, DDIR
    CALL    SNKMOV ; moves the snake
    RETURN
PRESS_RIGHT ; if pressed 6 (right)
    CLRF    DIR ; set the new direction
    BSF	    DIR, RDIR
    CALL    SNKMOV ; moves the snake
    RETURN
PRESS_LEFT ; if pressed 4 (left)
    CLRF    DIR ; set the new direction
    BSF	    DIR, LDIR
    CALL    SNKMOV ; moves the snake
    RETURN
    
KBRD_CONFIG ; keyboard configuration
    BANK1
    CLRF    TRISB
    MOVLW   B'00001111'
    MOVWF   TRISD
    MOVLW   B'00001111'
    MOVWF   TRISA
    BANK0
    RETURN
    
DELAY_2MS ; delay
    CALL    DELAY_1MS
    CALL    DELAY_1MS
    RETURN
DELAY_1MS
    MOVLW   D'165'
    MOVWF   _1MS
DELAY_LOOP
    DECFSZ  _1MS, 1
    GOTO    DELAY_LOOP
    RETURN
    
;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE

START
    SNK_RST ; reset the snake to his initial state
    CALL    CONFIG_INTER ; configurate the interruption
    CALL    SNKMOV ; make the first move
    
    MOVLW   D'1' ; set the keyboard iterator
    MOVWF   KBRDIT
    MOVLW   D'16' ; set the display iterator
    MOVWF   DSPIT
 
KBRD_LOOP
    CALL    KBRD_READ ; read keyboard
    DECFSZ  KBRDIT ; count iterator
    GOTO    KBRD_LOOP ; loop keyboard until iterator goes to 0
    MOVLW   D'1' ; reset
    MOVWF   KBRDIT
    GOTO    DSP_LOOP ; go to display
    
DSP_LOOP
    CALL    DISPLAY ; write display values
    CALL    SHOWFOOD ; show the food bit
    DECFSZ  DSPIT ; count iterator
    GOTO    DSP_LOOP ; loop display until iterator goes to 0
    MOVLW   D'16' ; reset
    MOVWF   DSPIT
    GOTO    KBRD_LOOP ; go to keyboard
    
    END