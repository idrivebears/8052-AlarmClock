;======================================================================|
; REPENTINA RELOJ ALARMA, FUNDAMENTOS DE MICROPROCESADORES, ITESO.     |
; AUTORES:                                                             |
;       -ALEJANDRO WALLS        is693215@iteso.mx                      |
;       -MARIO EUGENIO ZUÑIGA   ie693110@iteso.mx                      |
;======================================================================|

;P2.0 - P2.7 Disp Seg
;P3.2 - P3.3  Botones switch y edit
;P1.0 - P1.7  Transistores
;P3.7         Buzzer



;30H - 39H      BCD map
;3AH            Tick counter 2
;3BH            Tick counter 4
;3CH            Tick counter 250_1
;3DG            Tick counter 250_2
;, 3E           Debouncer counter
;, 3F       unmapped
;40H - 45H      CLKVAL
;46H - 4BH      ALRVAL
;50H - 55H      DISP_X
;56H            CUR_DISP
;60H - 65H      Current value to display


                ;TODO
                ;Remove interrupts for buttons
                ;Figure out ONE COLD
                ;Set alarm checking
                ;Consider using interrupt for alarm switch button
                

                ;IE EQU 0A8H                 ;INTERRUPT ENABLE REGISTRY (MAY NOT BE NEEDED)
                ;IP EQU 0B8H                 ;INTERRUPT PRIORITY REGISTRY
                T2CON EQU 0C8H
                RCAP2H EQU 0CBH
                RCAP2L EQU 0CAH
                    
                T2H EQU 0CDH
                T2L EQU 0CCH
                    
                INTERRUPTS EQU 10100101b       ;Interrupt flags, Global, Timer2, Button1, Button0
                    
                
                CLKVAL_S_L EQU 40H              ;Clock second value address
                CLKVAL_S_H EQU 41H              ;Clock second value address
                CLKVAL_M_L EQU 42H              ;Clock minute value address
                CLKVAL_M_H EQU 43H              ;Clock minute value address
                CLKVAL_H_L EQU 44H              ;Clock hour value address
                CLKVAL_H_H EQU 45H              ;Clock hour value address
                    
                ALRVAL_S_L EQU 60H              ;Alarm second value address
                ALRVAL_S_H EQU 61H              ;Alarm second value address
                ALRVAL_M_L EQU 62H              ;Alarm minute value address   
                ALRVAL_M_H EQU 63H              ;Alarm minute value address   
                ALRVAL_H_L EQU 64H              ;Alarm hour value address
                ALRVAL_H_H EQU 65H              ;Alarm hour value address
                    
                TICKCOUNT_2 EQU 3AH             ;Tick counter for refreshing displays
                TICKCOUNT_4 EQU 3BH             ;Tick counter for buttons
                TICKCOUNT_250_1 EQU 3CH         ;Tick counter for seconds 1
                TICKCOUNT_250_2 EQU 3DH         ;Tick counter for seconds 2
                DEBOUNCER_COUNT EQU  3EH         ;Counter for debouncer, 20 ms   
                    
                DISP_0  EQU 50H                 ;DISP_X will hold the value for the transistor arrangement
                DISP_1  EQU 51H
                DISP_2  EQU 52H
                DISP_3  EQU 53H
                DISP_4  EQU 54H
                DISP_5  EQU 55H
                
                
                CUR_DISP EQU 56H            ;Pointer to current display  (has to be passed to RX)
                    
                EDIT_OLD_STATE EQU 20H.0    ;deprecated
                EDIT_NEW_STATE EQU 20H.1    ;deprecated
                    
                ALARM_ENABLE EQU 20H.2      ;indicates display is enabled
                ALARM_ON EQU 20H.3          ;indicates if alarm is on
                

                ORG     0000H               ;RESET INTERRUPT
                JMP     START               ;go to start on reset
                
                ORG     0003H               ;EXT0 INTERRUPT SWITCH BUTTON
                JMP     EXT0IRS             
                
                ORG     0013H               ;EXT1 INTERRUPT EDIT BUTTON
                JMP     EXT1IRS             
                
                ORG     002BH               ;T2 INTERRUPT
                JMP     T2IRS               ;Go to interrupt routine                

                ORG     0040H
START:          MOV     IE, #INTERRUPTS      ;enable global interrupt, enable timer 2 interrupt, enable ext1, enable ext0
                MOV     IP, #00100000b      ;enable highest priority for timer 2
                MOV     T2CON, #00000000b   ;reset T2 settings
                
                MOV     TICKCOUNT_2, #2d            ;reset tick count for all counters
                MOV     TICKCOUNT_4, #4d            
                MOV     TICKCOUNT_250_1, #250d
                MOV     TICKCOUNT_250_2, #250d
                MOV     DEBOUNCER_COUNT, #0d
                
                //Starts at 12:00:00
                MOV     CLKVAL_H_L, #2d       ;Reset hour low
                MOV     CLKVAL_H_H, #1d       ;Reset hour high
                MOV     CLKVAL_M_L, #0d       ;Reset minute low
                MOV     CLKVAL_M_H, #0d       ;Reset minute high
                MOV     CLKVAL_S_L, #0d       ;Reset second low
                MOV     CLKVAL_S_H, #0d       ;Reset second high
                
                ;Set alarm to 12:02:00 
                MOV     ALRVAL_H_L, #2d       ;Reset alarm hour low
                MOV     ALRVAL_H_H, #1d       ;Reset alarm hour high
                MOV     ALRVAL_M_L, #2d       ;Reset alarm minute low
                MOV     ALRVAL_M_H, #0d       ;Reset alarm minute high
                MOV     ALRVAL_S_L, #0d       ;Reset alarm second low
                MOV     ALRVAL_S_H, #0d       ;Reset alarm second high
                
                CLR     EDIT_OLD_STATE   ;old button state starts at 0
                CLR     EDIT_NEW_STATE   ;new button state starts at 0
                CLR     ALARM_ENABLE     ;start display on clock
                CLR     ALARM_ON
                
                
                ;7SEGMENT CODES=================
                MOV     30H, #40H       ;0      |         
                MOV     31H, #79H       ;1      |
                MOV     32H, #24H       ;2      |
                MOV     33H, #30H       ;3      |
                MOV     34H, #19H       ;4      |
                MOV     35H, #90H       ;5      |
                MOV     36H, #80H       ;6      |
                MOV     37H, #78H       ;7      |
                MOV     38H, #00H       ;8      |
                MOV     39H, #18H       ;9      |
                ;================================
                
                ;ONE COLD========================
                MOV     DISP_0, #11111011b       ;
                MOV     DISP_1, #11110111b       ;
                MOV     DISP_2, #11101111b       ;
                MOV     DISP_3, #11011111b       ;
                MOV     DISP_4, #10111111b       ;
                MOV     DISP_5, #01111111b       ;
                ;================================
                                                
                MOV     CUR_DISP, #DISP_5      ;start current display on DISP_5
                
                
                MOV     RCAP2H, #0F8H       ;Load F830H into reload value (65536 - 2000) 2ms tick
                MOV     RCAP2L, #30H        ; ^
                
                MOV     T2H, #0F8H
                MOV     T2L, #30H
                
                
                MOV     T2CON, #00000100b   ;Start T2
                JMP     $                   ;wait for interrupts

;Timer 2 interrupt=========================================================================================================
;Triggered every T2 interrupt
T2IRS:          PUSH    PSW
                PUSH    ACC    
                ;MOV     IE, #00000000b      ;disable interrupts
                CPL     T2CON.7             ;reset T2 settings
                CPL     T2CON.2             ;
                JMP     TICK                ;go to tick routine
EXIT_T2IRS:     POP     ACC                 ;return ACC 
                POP     PSW                 ;return PSW
                MOV     IE, #INTERRUPTS      ;enable interruptions again
                MOV     T2CON, #00000100b   ;Start T2
                RETI

;SWITCH BUTTON (SWITCHED CLK/ALARM DISPLAY==================================================================================
;Triggered every ext0 interrupt
EXT0IRS:        PUSH    PSW
                PUSH    ACC
                CLR     EX0                 ;Disable external0 interrupt
                CLR     EX1                 ;Disable external1 interrupt
                ACALL   SWITCH_DISP
EXIT_EXT0IRS:   POP     ACC
                POP     PSW
                SETB    EX0                 ;reenable ext0 interrupt
                SETB    EX1                 ;reenable ext1 interrupt
                RETI

;EDIT BUTTON   (EDITS CLK/ALARM VALUE, INCREASING BY ONE)===================================================================
;Triggered every ext1 interrupt
EXT1IRS:        PUSH    PSW
                PUSH    ACC
                CLR     EX0
                CLR     EX1
                ACALL   EDIT
EXIT_EXT1IRS:   POP     ACC
                POP     PSW
                SETB    EX0
                SETB    EX1    
                RETI
                
;TICK;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Triggered evertime the clock ticks
TICK:           INC     DEBOUNCER_COUNT             ;Always increase debouncer counter
                ACALL   UPDTDISP                    ;Call update display subroutine
                ACALL   UPDTCLK                     ;Call update clock subroutine
                ACALL   CHECK_ALARM                 ;Check if alarm should be on/off
                JMP     EXIT_T2IRS                  ;Jump back to interrupt exit

;Update Clock;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Triggered every 500 ticks
UPDTCLK:        DJNZ    TICKCOUNT_250_1, END_UPDTCLK
                MOV     TICKCOUNT_250_1, #1d         ;hack/should probably fix/probably introduces inaccuracy
                DJNZ    TICKCOUNT_250_2, END_UPDTCLK
                MOV     TICKCOUNT_250_1, #250d      ;reset tick count
                MOV     TICKCOUNT_250_2, #250d      ;reset tick count 
                ACALL   INC_TIME                    ;call inc time subroutine
END_UPDTCLK:    RET

;INCREMENT TIME;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Increments clock value each second
INC_TIME:        ;SECONDS LOW
                INC     CLKVAL_S_L                  ;increase seconds
                MOV     A, CLKVAL_S_L               ;move seconds to accumulator for comparison
                CJNE    A, #10d, END_INC_TIME       ;if seconds is not max yet, jump back
                MOV     CLKVAL_S_L, #0d             ;reset seconds low
                
                ;SECONDS HIGH
                INC     CLKVAL_S_H              ;Increment second high
                MOV     A, CLKVAL_S_H           ;Move second hight to acc for comparison
                CJNE    A, #6d, END_INC_TIME    ;Reset if it has reached max value, else jump back
                MOV     CLKVAL_S_H, #0d         ;reset minutes high value
                
                ;MINUTES LOW
                INC     CLKVAL_M_L              ;increment minutes low
                MOV     A, CLKVAL_M_L           ;move for comparison
                CJNE    A, #10d, END_INC_TIME   ;compare and jump if not 10
                MOV     CLKVAL_M_L, #0d         ;reset minutes low
                
                ;MINUTES HIGH
                INC     CLKVAL_M_H              ;increment minutes high
                MOV     A, CLKVAL_M_H           ;move for comparison
                CJNE    A, #6d, END_INC_TIME    ;compare and jump if not 6    
                MOV     CLKVAL_M_H, #0d         ;reset minutes high
                
                ;HOURS LOW
                INC     CLKVAL_H_L              ;increment hours low
                MOV     A, CLKVAL_H_L           ;move for comparison
                CJNE    A, #4d, CONTINUE_H_L    ;if its not 4, continue checkinf for 10
                MOV     A, CLKVAL_H_H           ;if its 4, move hour high to B
                CJNE    A, #2d, CONTINUE_H_L    ;if B is not 2, continue checking for 10
                MOV     CLKVAL_H_L, #0d         ;if it is 2, reset hour low to 0
                MOV     CLKVAL_H_H, #0d         ;reset hour high to 0
                JMP     END_INC_TIME
                
CONTINUE_H_L:   CJNE    A, #10d, END_INC_TIME   ;compare and jump if not 10
                MOV     CLKVAL_H_L, #0d         ;reset hour low
END_INC_TIME:   RET                

;Update Display;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Triggered every tick, 2ms
UPDTDISP:       DEC     CUR_DISP                        ;decrease current display pointer
                MOV     A, CUR_DISP                     ;move curdisplay to A
                CJNE    A, #DISP_0 - 1, END_UPDTDISP2   ;compare with disp0 - 1 to check if it needs to be reset
                MOV     CUR_DISP, #DISP_5               ;reset display pointer
END_UPDTDISP2:  MOV     R0, CUR_DISP                    ;move cur display to R0
                MOV     P1, @R0                         ;move value contained in CURDISP pointer to port 2
                
                MOV     A, CUR_DISP                     ;Move current display value to A
                JB      ALARM_ENABLE, SHOW_ALR
                SUBB    A, #10H
                JMP     CONTUPDTDS
SHOW_ALR:       ADD     A, #10H                         ;Add 10H to convert to Appropiate display value (50H -> 60H, 51H -> 61H)
CONTUPDTDS:     MOV     R1, A                           ;Display values are contained in 60H - 65H, they match up with current transistor(CUR_DISP)
                
                MOV     A, #30H                         ;move 30H to A 
                ADD     A, @R1                          ;Add DISPVAL_X_X to A to get BCD value
                MOV     R0, A                           ;Move value of A to R0
                MOV     P2, @R0                         ;Send value of BCD to Port 2
END_UPDTDISP:   RET     

;SWITCH DISPLAY ROUTINE;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Switches between Alarm display and clock display
;important: ALARM_ENABLE flag
SWITCH_DISP:    MOV     DEBOUNCER_COUNT, #0d
RECHECK1:       MOV     A, DEBOUNCER_COUNT
                CJNE    A, #20d, RECHECK1
                JNB     P3.2, EXIT_SWITCH
                CPL     ALARM_ENABLE
EXIT_SWITCH:    RET

;EDIT CLOCK/ALARM VALUE;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Increments Minutes and hours on clock or alarm
EDIT:           MOV     DEBOUNCER_COUNT, #0d
RECHECK2:       MOV     A, DEBOUNCER_COUNT
                CJNE    A, #20d, RECHECK2
                JNB     P3.3, EXIT_EDIT
                JB      ALARM_ENABLE, INC_ALARM
                
                ;INCRASE TIME VALUE BY MINUTES
                ;MINUTES LOW
                INC     CLKVAL_M_L              ;increment minutes low
                MOV     A, CLKVAL_M_L           ;move for comparison
                CJNE    A, #10d, EXIT_EDIT      ;compare and jump if not 10
                MOV     CLKVAL_M_L, #0d         ;reset minutes low
                
                ;MINUTES HIGH
                INC     CLKVAL_M_H              ;increment minutes high
                MOV     A, CLKVAL_M_H           ;move for comparison
                CJNE    A, #6d, EXIT_EDIT       ;compare and jump if not 6    
                MOV     CLKVAL_M_H, #0d         ;reset minutes high
                
                ;HOURS LOW
                INC     CLKVAL_H_L              ;increment hours low
                MOV     A, CLKVAL_H_L           ;move for comparison
                CJNE    A, #4d, CONT_H_L        ;if its not 4, continue checkinf for 10
                MOV     A, CLKVAL_H_H           ;if its 4, move hour high to B
                CJNE    A, #2d, CONT_H_L        ;if B is not 2, continue checking for 10
                MOV     CLKVAL_H_L, #0d         ;if it is 2, reset hour low to 0
                MOV     CLKVAL_H_H, #0d         ;reset hour high to 0
                JMP     EXIT_EDIT
                
CONT_H_L:       CJNE    A, #10d, EXIT_EDIT      ;compare and jump if not 10
                MOV     CLKVAL_H_L, #0d         ;reset hour low
                JMP     EXIT_EDIT
INC_ALARM:      ;INCRASE ALR VALUE BY MINUTES
                ;MINUTES LOW
                INC     ALRVAL_M_L              ;increment minutes low
                MOV     A, ALRVAL_M_L           ;move for comparison
                CJNE    A, #10d, EXIT_EDIT      ;compare and jump if not 10
                MOV     ALRVAL_M_L, #0d         ;reset minutes low
                
                ;MINUTES HIGH
                INC     ALRVAL_M_H              ;increment minutes high
                MOV     A, ALRVAL_M_H           ;move for comparison
                CJNE    A, #6d, EXIT_EDIT       ;compare and jump if not 6    
                MOV     ALRVAL_M_H, #0d         ;reset minutes high
                
                ;HOURS LOW
                INC     ALRVAL_H_L              ;increment hours low
                MOV     A, ALRVAL_H_L           ;move for comparison
                CJNE    A, #4d, CONT_H        ;if its not 4, continue checkinf for 10
                MOV     A, ALRVAL_H_H           ;if its 4, move hour high to B
                CJNE    A, #2d, CONT_H        ;if B is not 2, continue checking for 10
                MOV     ALRVAL_H_L, #0d         ;if it is 2, reset hour low to 0
                MOV     ALRVAL_H_H, #0d         ;reset hour high to 0
                JMP     EXIT_EDIT
                
CONT_H:         CJNE    A, #10d, EXIT_EDIT      ;compare and jump if not 10
                MOV     ALRVAL_H_L, #0d         ;reset hour low                
EXIT_EDIT:      RET

;CHECK ALARM SUBROUTINE;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Will check if alarm needs to be enabled/disabled
CHECK_ALARM:    JB      ALARM_ON, UPDT_ALARM
                ;Check all values of ALR with CLK, if they match, activate
                MOV     A, ALRVAL_M_L
                CJNE    A, CLKVAL_M_L, EXIT_CHECK
                MOV     A, ALRVAL_M_H
                CJNE    A, CLKVAL_M_H, EXIT_CHECK
                MOV     A, ALRVAL_H_L
                CJNE    A, CLKVAL_H_L, EXIT_CHECK
                MOV     A, ALRVAL_H_H 
                CJNE    A, CLKVAL_H_H, EXIT_CHECK
                ;Alarm and Clock have the same values, turn on alarm
                SETB    ALARM_ON
                CLR     P3.7                                    ;BEEP BEEP
                JMP     EXIT_CHECK
UPDT_ALARM:     ;Check if one minute has passed
                MOV     A, ALRVAL_M_L
                CJNE    A, CLKVAL_M_L, CHECK_SECS
                JMP     EXIT_CHECK
                ;Minutes have changed, check seconds
CHECK_SECS:     MOV     A, ALRVAL_S_L
                CJNE    A, CLKVAL_S_L, EXIT_CHECK
                MOV     A, ALRVAL_S_H
                CJNE    A, CLKVAL_S_H, EXIT_CHECK
                ;Minutes and seconds are all the same, turn off alarm
                SETB    P3.7                                    ;MEEP
                CLR     ALARM_ON
EXIT_CHECK:     RET    

END
