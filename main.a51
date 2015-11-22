;======================================================================|
; REPENTINA RELOJ ALARMA, FUNDAMENTOS DE MICROPROCESADORES, ITESO.     |
; AUTORES:                                                             |
;       -ALEJANDRO WALLS        is693215@iteso.mx                      |
;       -MARIO EUGENIO ZUÑIGA   ie693110@iteso.mx                      |
;======================================================================|

;P0.0 - P 0.7 Disp Seg
;P3.2 - P3.3  Botones switch y edit
;P2.2 - P2.7  Transistores
;P3.7         Buzzer

                ;TODO
                ;Set interrupt priority for T2 on high, others on low
                ;Pick RAM locations for clock, alarm and tick values
                ;Set button external interruption
                ;Research interrupt times 
                ;Figure out if using second timer will solve T2 problem when interrupting
                ;Save all possible values of displays to memory location
                ;Figure out rotation of displays
                ;MOOOREEEEEEEEEEEEEEE

                ;IE EQU 0A8H                 ;INTERRUPT ENABLE REGISTRY (MAY NOT BE NEEDED)
                ;IP EQU 0B8H                 ;INTERRUPT PRIORITY REGISTRY
                CLKVAL_H EQU 0              ;Clock hour value address
                CLKVAL_M EQU 0              ;Clock minute value address
                CLKVAL_S EQU 0              ;Clock second value address
                    
                ALRVAL_H EQU 0              ;Alarm hour value address
                ALRVAL_M EQU 0              ;Alarm minute value address   
                ALRVAL_S EQU 0              ;Alarm second value address
                    
                TICKCOUNT_2 EQU 0             ;Tick count address
                TICKCOUNT_4 EQU 0
                TICKCOUNT_500 EQU 0
                    
                TR_DISPLAYS EQU 0

                ORG     0000H               ;RESET INTERRUPT
                JMP     START               ;go to start on reset
                
                ORG     0003H               ;EXT0 INTERRUPT SWITCH BUTTON
                JMP     EXT0IRS             
                
                ORG     0013H               ;EXT1 INTERRUPT EDIT BUTTON
                JMP     EXT1IRS             
                
                ORG     002BH               ;T2 INTERRUPT
                JMP     T2IRS               ;Go to interrupt routine                

                ORG     0040H
START:          CPL     P3.7                ;BEEP BEEP MOTHERFUCKER
                MOV     IE, #10100101b      ;enable global interrupt, enable timer 2 interrupt, enable ext1, enable ext0
                MOV     IP, #00100000b      ;enable highest priority for timer 2
                MOV     T2CON, #00000000b   ;reset T2 settings
                
                MOV     TICKCOUNT_2, #2d     ;reset tick count
                MOV     TICKCOUNT_4, #4d
                MOV     TICKCOUNT_500, #500d
                
                MOV     CLKVAL_H, #0d       ;Reset hour
                MOV     CLKVAL_M, #0d       ;Reset minute
                MOV     CLKVAL_S, #0d       ;Reset second
                
                MOV     TR_DISPLAYS, #1111 1011b
                
                
                MOV     RCAP2H, #0F8H       ;Load F830H into reload value (65536 - 2000) 2ms tick
                MOV     RCAP2L, #30H        ; ^
                
                
                MOV     T2CON, #00000100b   ;Start T2
                JMP     $                   ;wait for interrupts


;Triggered every T2 interrupt
T2IRS:          PUSH    PSW
                PUSH    ACC    
                MOV     IE, #00000000b      ;disable interrupts
                MOV     T2CON, #00000000b   ;reset T2 settings
                JMP     TICK                ;go to tick routine
EXIT_T2IRS:     MOV     IE, #10100000b      ;enable interruptions again
                POP     ACC
                POP     PSW    
                RETI

;SWITCH BUTTON (SWITCHED CLK/ALARM DISPLAY)
;Triggered every ext0 interrupt
EXT0IRS:        RETI

;EDIT BUTTON   (EDITS CLK/ALARM VALUE, INCREASING BY ONE)
;Triggered every ext1 interrupt
EXT1IRS:        RETI

;Triggered evertime the clock ticks
TICK:           ;DJNZ TICKCOUNT_2, UPDTDISP
                ;DJNZ TICKCOUNT_4, UPDTBUTTONS
                DJNZ    TICKCOUNT_500, EXIT_T2IRS
                JMP     UPDTCLK

;Update Clock
;Triggered every 500 ticks
UPDTCLK:        MOV     TICKCOUNT_500, #500d    ;reset tick count
                INC     CLKVAL_S                ;increase seconds
                MOV     A, CLKVAL_S             ;move seconds to accumulator for comparison
                CJNE    A, #60d, EXIT_T2IRS     ;if seconds is not 60 yet, jump back
                MOV     CLKVAL_S, #0d           ;one minute passed, reset seconds    
                INC     CLKVAL_M                ;one minute has passed, increase minutes
                MOV     A, CLKVAL_M             ;move minutes to acc for comparison
                CJNE    A, #60d, EXIT_T2IRS
                MOV     CLKVAL_M, #0d           ;one hour passed, reset minutes
                INC     CLKVAL_H
                MOV     A, CLKVAL_H
                CJNE    A, #24d, EXIT_T2IRS     ;check if 24 hours have passed     
                MOV     CLKVAL_H, #0d           ;reset hours
                JMP     EXIT_T2IRS

;Update Display
;Triggered every 2 ticks
UPDTDISP:       MOV     TICKCOUNT_2, #2d;
                MOV     P2, TR_DISPLAYS
                MOV     A, TR_DISPLAYS
                RL      A
                MOV     TR_DISPLAYS, A
                JMP     EXIT_T2IRS

;Update button status
;Triggered every 4 ticks
UPDTBUTTONS:    MOV     TICKCOUNT_4, #4d;
                RET











