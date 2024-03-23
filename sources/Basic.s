; Basic.s : BASIC インタプリタ
;


; モジュール宣言
;
    .module Basic

; 参照ファイル
;
    .include    "bios.inc"
    .include    "vdp.inc"
    .include    "System.inc"
    .include	"App.inc"
    .include    "Basic.inc"

; 外部変数宣言
;
    .globl  _stack


; CODE 領域
;
    .area   _CODE

; BASIC
;
_Basic::

;; ↓ MSX ROUTINE

    ; スタックポインタの保存
    ld      (STACKPOINTER), sp

    ; ワークの初期化
    ld      hl, #(OCSW + 0x0000)
    ld      de, #(OCSW + 0x0001)
    ld      bc, #(BUFEND - OCSW - 0x0001)
    ld      (hl), #0x00
    ldir

    ; 初期値の設定
    ld      a, #0xff
    ld      (OCSW), a
    ld      hl, #START
    ld      (RANPNT), hl
    ld      hl, #TXTBGN
    ld      (TXTUNF), hl

    ; カーソルの設定
    ld      hl, #(_patternName + 40 * 24 - 40)
    ld      (CURSOR), hl
    jp      START

;; ↑ MSX ROUTINE



                                ; ;*************************************************************
                                ; ;*
                                ; ;*                TINY BASIC FOR INTEL 8080
                                ; ;*                      VERSION 1.0
                                ; ;*                    BY LI-CHEN WANG
                                ; ;*                     10 JUNE, 1976
                                ; ;*                       @COPYLEFT
                                ; ;*                  ALL WRONGS RESERVED
                                ; ;*
                                ; ;*************************************************************
                                ; ;*
                                ; ;*  *** ZERO PAGE SUBROUTINES ***
                                ; ;*
                                ; ;* THE 8080 INSTRUCTION SET LETS YOU HAVE 8 ROUTINES IN LOW
                                ; ;* MEMORY THAT MAY BE CALLED BY RST N, N BEING 0 THROUGH 7.
                                ; ;* THIS IS A ONE BYTE INSTRUCTION AND HAS THE SAME POWER AS
                                ; ;* THE THREE BYTE INSTRUCTION CALL LLHH.  TINY BASIC WILL
                                ; ;* USE RST 0 AS START OR RESTART AND RST 1 THROUGH RST 7 FOR
                                ; ;* THE SEVEN MOST FREQUENTLY USED SUBROUTINES.
                                ; ;* TWO OTHER SUBROUTINES (CRLF AND TSTNUM) ARE ALSO IN THIS
                                ; ;* SECTION.  THEY CAN BE REACHED ONLY BY 3-BYTE CALLS.
                                ; ;*
CR      =   0x0d                ; CR      EQU  0DH                        ;ASCII CR
LF      =   0x0a                ; LF      EQU  0AH                        ;ASCII LF
QT      =   0x27                ; QT      EQU  27H                        ;ASCII SINGLE QUOTE
CNTLO   =   0x0f                ; CNTLO   EQU  0FH                        ;ASCII CONTROL-O
CNTLC   =   0x03                ; CNTLC   EQU  03H                        ;ASCII CONTROL-C
DLLN    =   0x7d                ; DLLN    EQU  7DH                        ;DELETE LINE TELETYPE, BUT WE USE
CNTLU   =   0x15                ; CNTLU   EQU  15H                        ;ASCII CONTROL-U FOR DELETE LINE
BKS     =   0x5c                ; BKS     EQU  5CH                        ;ASCII BACK-SLASH
BKA     =   0x5f                ; BKA     EQU  5FH                        ;ASCII UNDERLINE (BACK-ARROW)
UPA     =   0x5e                ; UPA     EQU  5EH                        ;ASCII UP-ARROW
DEL     =   0x7f                ; DEL     EQU  7FH                        ;ASCII DEL
                                ; ;
                                ; ; MACRO TO CREATE TABLE ADDRESS ITEMS
                                ; ;
                                ; ITEM    MACRO P1
                                ;         DB   (P1 SHR 8) OR 80H
                                ;         DB   P1 AND 0FFH
                                ;         ENDM
                                ; ;
                                ;         ORG  0000H
RST0:
START:
;   di                          ; START:  DI                              ;*** START/RESTART ***
    ld      sp, (STACKPOINTER)  ;         LXI  SP,STACK                   ;INITIALIZE THE STACK
    jp      ST1                 ;         JMP  ST1                        ;GO TO THE MAIN SECTION
    .db     'L'                 ;         DB   'L'
                                ; ;
RST1:
    ex      (sp), hl            ;         XTHL                            ;*** TSTC OR RST 1 ***
    call    RST5                ;         RST  5                          ;IGNORE BLANKS AND
    cp      (hl)                ;         CMP  M                          ;TEST CHARACTER
    jp      TC1                 ;         JMP  TC1                        ;REST OF THIS IS AT TC1
                                ; ;
CRLF:
    ld      a, #CR              ; CRLF:   MVI  A,CR                       ;*** CRLF ***
                                ; ;
RST2:
    push    af                  ;         PUSH PSW                        ;*** OUTC OR RST 2 ***
    ld      a, (OCSW)           ;         LDA  OCSW                       ;PRINT CHARACTER ONLY
    or      a                   ;         ORA  A                          ;IF OCSW SWITCH IS ON
    jp      OC2                 ;         JMP  OC2                        ;REST OF THIS IS AT OC2
                                ; ;
RST3:
    call    EXPR2               ;         CALL EXPR2                      ;*** EXPR OR RST 3 ***
    push    hl                  ;         PUSH H                          ;EVALUATE AN EXPRESSION
    jp      EXPR1               ;         JMP  EXPR1                      ;REST OF IT AT EXPR1
    .db     'W'                 ;         DB   'W'
                                ; ;
RST4:
    ld      a, h                ;         MOV  A,H                        ;*** COMP OR RST 4 ***
    cp      d                   ;         CMP  D                          ;COMPARE HL WITH DE
    ret     nz                  ;         RNZ                             ;RETURN CORRECT C AND
    ld      a, l                ;         MOV  A,L                        ;Z FLAGS
    cp      e                   ;         CMP  E                          ;BUT OLD A IS LOST
    ret                         ;         RET
    .ascii  "AN"                ;         DB   'AN'
                                ; ;
RST5:
SS1:
    ld      a, (de)             ; SS1:    LDAX D                          ;*** IGNBLK/RST 5 ***
    cp      #' '                ;         CPI  ' '                        ;IGNORE BLANKS
    ret     nz                  ;         RNZ                             ;IN TEXT (WHERE DE->)
    inc     de                  ;         INX  D                          ;AND RETURN THE FIRST
    jp      SS1                 ;         JMP  SS1                        ;NON-BLANK CHAR. IN A
                                ; ;
RST6:
    pop     af                  ;         POP  PSW                        ;*** FINISH/RST 6 ***
    call    FIN                 ;         CALL FIN                        ;CHECK END OF COMMAND
    jp      QWHAT               ;         JMP  QWHAT                      ;PRINT "WHAT?" IF WRONG
    .db     'G'                 ;         DB   'G'
                                ; ;
RST7:
    call    RST5                ;         RST  5                          ;*** TSTV OR RST 7 ***
    sub     #'@'                ;         SUI  '@'                        ;TEST VARIABLES
    ret     c                   ;         RC                              ;C:NOT A VARIABLE
    jp      nz, TV1             ;         JNZ  TV1                        ;NOT "@" ARRAY
    inc     de                  ;         INX  D                          ;IT IS THE "@" ARRAY
    call    PARN                ;         CALL PARN                       ;@ SHOULD BE FOLLOWED
    add     hl, hl              ;         DAD  H                          ;BY (EXPR) AS ITS INDEX
    jp      c, QHOW             ;         JC   QHOW                       ;IS INDEX TOO BIG?
    push    de                  ;         PUSH D                          ;WILL IT OVERWRITE
    ex      de, hl              ;         XCHG                            ;TEXT?
    call    SIZE                ;         CALL SIZE                       ;FIND SIZE OF FREE
    call    RST4                ;         RST  4                          ;AND CHECK THAT
    jp      c, ASORRY           ;         JC   ASORRY                     ;IF SO, SAY "SORRY"
    ld      hl, #VARBGN         ;         LXI  H,VARBGN                   ;IF NOT GET ADDRESS
    call    SUBDE               ;         CALL SUBDE                      ;OF @(EXPR) AND PUT IT
    pop     de                  ;         POP  D                          ;IN HL
    ret                         ;         RET                             ;C FLAG IS CLEARED
TV1:
    cp      #27                 ; TV1:    CPI  27                         ;NOT @, IS IT A TO Z?
    ccf                         ;         CMC                             ;IF NOT RETURN C FLAG
    ret     c                   ;         RC
    inc     de                  ;         INX  D                          ;IF A THROUGH Z
    ld      hl, #VARBGN         ;         LXI  H,VARBGN                   ;COMPUTE ADDRESS OF
    rlca                        ;         RLC                             ;THAT VARIABLE
    add     a, l                ;         ADD  L                          ;AND RETURN IT IN HL
    ld      l, a                ;         MOV  L,A                        ;WITH C FLAG CLEARED
    ld      a, #0               ;         MVI  A,0
    adc     a, h                ;         ADC  H
    ld      h, a                ;         MOV  H,A
    ret                         ;         RET
                                ; ;
                                ; ;TSTC:  XTHL                            ;*** TSTC OR RST 1 ***
                                ; ;       RST  5                          ;THIS IS AT LOC. 8
                                ; ;       CMP  M                          ;AND THEN JUMP HERE
TC1:
    inc     hl                  ; TC1:    INX  H                          ;COMPARE THE BYTE THAT
    jp      z, TC2              ;         JZ   TC2                        ;FOLLOWS THE RST INST.
    push    bc                  ;         PUSH B                          ;WITH THE TEXT (DE->)
    ld      c, (hl)             ;         MOV  C,M                        ;IF NOT =, ADD THE 2ND
    ld      b, #0               ;         MVI  B,0                        ;BYTE THAT FOLLOWS THE
    add     hl, bc              ;         DAD  B                          ;RST TO THE OLD PC
    pop     bc                  ;         POP  B                          ;I.E., DO A RELATIVE
    dec     de                  ;         DCX  D                          ;JUMP IF NOT =
TC2:
    inc     de                  ; TC2:    INX  D                          ;IF =, SKIP THOSE BYTES
    inc     hl                  ;         INX  H                          ;AND CONTINUE
    ex      (sp), hl            ;         XTHL
    ret                         ;         RET
                                ; ;
TSTNUM:
    ld      hl, #0              ; TSTNUM: LXI  H,0                        ;*** TSTNUM ***
    ld      b, h                ;         MOV  B,H                        ;TEST IF THE TEXT IS
    call    RST5                ;         RST  5                          ;A NUMBER
TN1:
    cp      #'0'                ; TN1:    CPI  '0'                        ;IF NOT, RETURN 0 IN
    ret     c                   ;         RC                              ;B AND HL
    cp      #0x3a               ;         CPI  3AH                        ;IF NUMBERS, CONVERT
    ret     nc                  ;         RNC                             ;TO BINARY IN HL AND
    ld      a, #0xf0            ;         MVI  A,0F0H                     ;SET B TO # OF DIGITS
    and     h                   ;         ANA  H                          ;IF H>255, THERE IS NO
    jp      nz, QHOW            ;         JNZ  QHOW                       ;ROOM FOR NEXT DIGIT
    inc     b                   ;         INR  B                          ;B COUNTS # OF DIGITS
    push    bc                  ;         PUSH B
    ld      b, h                ;         MOV  B,H                        ;HL=10*HL+(NEW DIGIT)
    ld      c, l                ;         MOV  C,L
    add     hl, hl              ;         DAD  H                          ;WHERE 10* IS DONE BY
    add     hl, hl              ;         DAD  H                          ;SHIFT AND ADD
    add     hl, bc              ;         DAD  B
    add     hl, hl              ;         DAD  H
    ld      a, (de)             ;         LDAX D                          ;AND (DIGIT) IS FROM
    inc     de                  ;         INX  D                          ;STRIPPING THE ASCII
    and     #0x0f               ;         ANI  0FH                        ;CODE
    add     a, l                ;         ADD  L
    ld      l, a                ;         MOV  L,A
    ld      a, #0               ;         MVI  A,0
    adc     a, h                ;         ADC  H
    ld      h, a                ;         MOV  H,A
    pop     bc                  ;         POP  B
    ld      a, (de)             ;         LDAX D                          ;DO THIS DIGIT AFTER
    jp      p, TN1              ;         JP   TN1                        ;DIGIT. S SAYS OVERFLOW
QHOW:
    push    de                  ; QHOW:   PUSH D                          ;*** ERROR "HOW?" ***
AHOW:
    ld      de, #HOW            ; AHOW:   LXI  D,HOW
    jp      ERROR               ;         JMP  ERROR
HOW:
    .ascii  "HOW?"              ; HOW:    DB   'HOW?',CR
    .db     CR
OK:
    .ascii  "OK"                ; OK:     DB   'OK',CR
    .db     CR
WHAT:
    .ascii  "WHAT?"             ; WHAT:   DB   'WHAT?',CR
    .db     CR
SORRY:
    .ascii  "SORRY"             ; SORRY:  DB   'SORRY',CR
    .db     CR
                                ; ;
                                ; ;*************************************************************
                                ; ;*
                                ; ;* *** MAIN ***
                                ; ;*
                                ; ;* THIS IS THE MAIN LOOP THAT COLLECTS THE TINY BASIC PROGRAM
                                ; ;* AND STORES IT IN THE MEMORY.
                                ; ;*
                                ; ;* AT START, IT PRINTS OUT "(CR)OK(CR)", AND INITIALIZES THE
                                ; ;* STACK AND SOME OTHER INTERNAL VARIABLES.  THEN IT PROMPTS
                                ; ;* ">" AND READS A LINE.  IF THE LINE STARTS WITH A NON-ZERO
                                ; ;* NUMBER, THIS NUMBER IS THE LINE NUMBER.  THE LINE NUMBER
                                ; ;* (IN 16 BIT BINARY) AND THE REST OF THE LINE (INCLUDING CR)
                                ; ;* IS STORED IN THE MEMORY.  IF A LINE WITH THE SAME LINE
                                ; ;* NUMBER IS ALREADY THERE, IT IS REPLACED BY THE NEW ONE.  IF
                                ; ;* THE REST OF THE LINE CONSISTS OF A CR ONLY, IT IS NOT STORED
                                ; ;* AND ANY EXISTING LINE WITH THE SAME LINE NUMBER IS DELETED.
                                ; ;*
                                ; ;* AFTER A LINE IS INSERTED, REPLACED, OR DELETED, THE PROGRAM
                                ; ;* LOOPS BACK AND ASK FOR ANOTHER LINE.  THIS LOOP WILL BE
                                ; ;* TERMINATED WHEN IT READS A LINE WITH ZERO OR NO LINE
                                ; ;* NUMBER; AND CONTROL IS TRANSFERED TO "DIRECT".
                                ; ;*
                                ; ;* TINY BASIC PROGRAM SAVE AREA STARTS AT THE MEMORY LOCATION
                                ; ;* LABELED "TXTBGN" AND ENDED AT "TXTEND".  WE ALWAYS FILL THIS
                                ; ;* AREA STARTING AT "TXTBGN", THE UNFILLED PORTION IS POINTED
                                ; ;* BY THE CONTENT OF A MEMORY LOCATION LABELED "TXTUNF".
                                ; ;*
                                ; ;* THE MEMORY LOCATION "CURRNT" POINTS TO THE LINE NUMBER
                                ; ;* THAT IS CURRENTLY BEING INTERPRETED.  WHILE WE ARE IN
                                ; ;* THIS LOOP OR WHILE WE ARE INTERPRETING A DIRECT COMMAND
                                ; ;* (SEE NEXT SECTION). "CURRNT" SHOULD POINT TO A 0.
                                ; ;*
                                ; ;START: LXI  SP,STACK                   ;THIS IS AT LOC. 0
ST1:
    call    CRLF                ; ST1:    CALL CRLF                       ;AND JUMP TO HERE
    ld      de, #OK             ;         LXI  D,OK                       ;DE->STRING
    sub     a                   ;         SUB  A                          ;A=0
    call    PRTSTG              ;         CALL PRTSTG                     ;PRINT STRING UNTIL CR
    ld      hl, #(ST2 + 1)      ;         LXI  H,ST2+1                    ;LITERAL 0
    ld      (CURRNT), hl        ;         SHLD CURRNT                     ;CURRENT->LINE # = 0
ST2:
    ld      hl, #0              ; ST2:    LXI  H,0
    ld      (LOPVAR), hl        ;         SHLD LOPVAR
    ld      (STKGOS), hl        ;         SHLD STKGOS
ST3:
    ld      a, #'>'             ; ST3:    MVI  A,'>'                      ;PROMPT '>' AND
    call    GETLN               ;         CALL GETLN                      ;READ A LINE
    push    de                  ;         PUSH D                          ;DE->END OF LINE
    ld      de, #BUFFER         ;         LXI  D,BUFFER                   ;DE->BEGINNING OF LINE
    call    TSTNUM              ;         CALL TSTNUM                     ;TEST IF IT IS A NUMBER
    call    RST5                ;         RST  5
    ld      a, h                ;         MOV  A,H                        ;HL=VALUE OF THE # OR
    or      l                   ;         ORA  L                          ;0 IF NO # WAS FOUND
    pop     bc                  ;         POP  B                          ;BC->END OF LINE
    jp      z, DIRECT           ;         JZ   DIRECT
    dec     de                  ;         DCX  D                          ;BACKUP DE AND SAVE
    ld      a, h                ;         MOV  A,H                        ;VALUE OF LINE # THERE
    ld      (de), a             ;         STAX D
    dec     de                  ;         DCX  D
    ld      a, l                ;         MOV  A,L
    ld      (de), a             ;         STAX D
    push    bc                  ;         PUSH B                          ;BC,DE->BEGIN, END
    push    de                  ;         PUSH D
    ld      a, c                ;         MOV  A,C
    sub     e                   ;         SUB  E
    push    af                  ;         PUSH PSW                        ;A=# OF BYTES IN LINE
    call    FNDLN               ;         CALL FNDLN                      ;FIND THIS LINE IN SAVE
    push    de                  ;         PUSH D                          ;AREA, DE->SAVE AREA
    jp      nz, ST4             ;         JNZ  ST4                        ;NZ:NOT FOUND, INSERT
    push    de                  ;         PUSH D                          ;Z:FOUND, DELETE IT
    call    FNDNXT              ;         CALL FNDNXT                     ;FIND NEXT LINE
                                ;                                         ;DE->NEXT LINE
    pop     bc                  ;         POP  B                          ;BC->LINE TO BE DELETED
    ld      hl, (TXTUNF)        ;         LHLD TXTUNF                     ;HL->UNFILLED SAVE AREA
    call    MVUP                ;         CALL MVUP                       ;MOVE UP TO DELETE
    ld      h, b                ;         MOV  H,B                        ;TXTUNF->UNFILLED AREA
    ld      l, c                ;         MOV  L,C
    ld      (TXTUNF), hl        ;         SHLD TXTUNF                     ;UPDATE
ST4:
    pop     bc                  ; ST4:    POP  B                          ;GET READY TO INSERT
    ld      hl, (TXTUNF)        ;         LHLD TXTUNF                     ;BUT FIRST CHECK IF
    pop     af                  ;         POP  PSW                        ;THE LENGTH OF NEW LINE
    push    hl                  ;         PUSH H                          ;IS 3 (LINE # AND CR)
    cp      #3                  ;         CPI  3                          ;THEN DO NOT INSERT
    jp      z, START            ;         JZ   START                      ;MUST CLEAR THE STACK
    add     a, l                ;         ADD  L                          ;COMPUTE NEW TXTUNF
    ld      l, a                ;         MOV  L,A
    ld      a, #0               ;         MVI  A,0
    adc     a, h                ;         ADC  H
    ld      h, a                ;         MOV  H,A                        ;HL->NEW UNFILLED AREA
    ld      de, #TXTEND         ;         LXI  D,TXTEND                   ;CHECK TO SEE IF THERE
    call    RST4                ;         RST  4                          ;IS ENOUGH SPACE
    jp      nc, QSORRY          ;         JNC  QSORRY                     ;SORRY, NO ROOM FOR IT
    ld      (TXTUNF), hl        ;         SHLD TXTUNF                     ;OK, UPDATE TXTUNF
    pop     de                  ;         POP  D                          ;DE->OLD UNFILLED AREA
    call    MVDOWN              ;         CALL MVDOWN
    pop     de                  ;         POP  D                          ;DE->BEGIN, HL->END
    pop     hl                  ;         POP  H
    call    MVUP                ;         CALL MVUP                       ;MOVE NEW LINE TO SAVE
    jp      ST3                 ;         JMP  ST3                        ;AREA
                                ; ;
                                ; ;*************************************************************
                                ; ;*
                                ; ;* *** TABLES *** DIRECT *** & EXEC ***
                                ; ;*
                                ; ;* THIS SECTION OF THE CODE TESTS A STRING AGAINST A TABLE.
                                ; ;* WHEN A MATCH IS FOUND, CONTROL IS TRANSFERED TO THE SECTION
                                ; ;* OF CODE ACCORDING TO THE TABLE.
                                ; ;*
                                ; ;* AT 'EXEC', DE SHOULD POINT TO THE STRING AND HL SHOULD POINT
                                ; ;* TO THE TABLE-1.  AT 'DIRECT', DE SHOULD POINT TO THE STRING.
                                ; ;* HL WILL BE SET UP TO POINT TO TAB1-1, WHICH IS THE TABLE OF
                                ; ;* ALL DIRECT AND STATEMENT COMMANDS.
                                ; ;*
                                ; ;* A '.' IN THE STRING WILL TERMINATE THE TEST AND THE PARTIAL
                                ; ;* MATCH WILL BE CONSIDERED AS A MATCH.  E.G., 'P.', 'PR.',
                                ; ;* 'PRI.', 'PRIN.', OR 'PRINT' WILL ALL MATCH 'PRINT'.
                                ; ;*
                                ; ;* THE TABLE CONSISTS OF ANY NUMBER OF ITEMS.  EACH ITEM
                                ; ;* IS A STRING OF CHARACTERS WITH BIT 7 SET TO 0 AND
                                ; ;* A JUMP ADDRESS STORED HI-LOW WITH BIT 7 OF THE HIGH
                                ; ;* BYTE SET TO 1.
                                ; ;*
                                ; ;* END OF TABLE IS AN ITEM WITH A JUMP ADDRESS ONLY.  IF THE
                                ; ;* STRING DOES NOT MATCH ANY OF THE OTHER ITEMS, IT WILL
                                ; ;* MATCH THIS NULL ITEM AS DEFAULT.
                                ; ;*
TAB1:                           ; TAB1    EQU  $                          ;DIRECT COMMANDS
    .ascii  "LIST"              ;         DB   'LIST'
    .db     >(LIST + 0x8000), <LIST
                                ;         ITEM LIST
    .ascii  "RUN"               ;         DB   'RUN'
    .db     >(RUN + 0x8000), <RUN
                                ;         ITEM RUN
    .ascii  "NEW"               ;         DB   'NEW'
    .db     >(NEW + 0x8000), <NEW
                                ;         ITEM NEW
TAB2:                           ; TAB2    EQU  $                          ;DIRECT/STATEMENT
    .ascii  "NEXT"              ;         DB   'NEXT'
    .db     >(NEXT + 0x8000), <NEXT
                                ;         ITEM NEXT
    .ascii  "LET"               ;         DB   'LET'
    .db     >(LET + 0x8000), <LET
                                ;         ITEM LET
    .ascii  "IF"                ;         DB   'IF'
    .db     >(IFF + 0x8000), <IFF
                                ;         ITEM IFF
    .ascii  "GOTO"              ;         DB   'GOTO'
    .db     >(GOTO + 0x8000), <GOTO
                                ;         ITEM GOTO
    .ascii  "GOSUB"             ;         DB   'GOSUB'
    .db     >(GOSUB + 0x8000), <GOSUB
                                ;         ITEM GOSUB
    .ascii  "RETURN"            ;         DB   'RETURN'
    .db     >(RETURN + 0x8000), <RETURN
                                ;         ITEM RETURN
    .ascii  "REM"               ;         DB   'REM'
    .db     >(REM + 0x8000), <REM
                                ;         ITEM REM
    .ascii  "FOR"               ;         DB   'FOR'
    .db     >(FOR + 0x8000), <FOR
                                ;         ITEM FOR
    .ascii  "INPUT"             ;         DB   'INPUT'
    .db     >(INPUT + 0x8000), <INPUT
                                ;         ITEM INPUT
    .ascii  "PRINT"             ;         DB   'PRINT'
    .db     >(PRINT + 0x8000), <PRINT
                                ;         ITEM PRINT
    .ascii  "STOP"              ;         DB   'STOP'
    .db     >(STOP + 0x8000), <STOP
                                ;         ITEM STOP
    .db     >(DEFLT + 0x8000), <DEFLT
                                ;         ITEM DEFLT
    .ascii  "YOU MAY INSERT  MORE COMMANDS."
                                ;         DB   'YOU MAY INSERT  MORE COMMANDS.'
TAB4:                           ; TAB4    EQU  $                          ;FUNCTIONS
    .ascii  "RND"               ;         DB   'RND'
    .db     >(RND + 0x8000), <RND
                                ;         ITEM RND
    .ascii  "ABS"               ;         DB   'ABS'
    .db     >(ABS + 0x8000), <ABS
                                ;         ITEM ABS
    .ascii  "SIZE"              ;         DB   'SIZE'
    .db     >(SIZE + 0x8000), <SIZE
                                ;         ITEM SIZE
    .db     >(XP40 + 0x8000), <XP40
                                ;         ITEM XP40
    .ascii  "YOU MAY INSERT  MORE FUNCTIONS"
                                ;         DB   'YOU MAY INSERT  MORE FUNCTIONS'
TAB5:                           ; TAB5    EQU  $                          ;"TO" IN "FOR"
    .ascii  "TO"                ;         DB   'TO'
    .db     >(FR1 + 0x8000), <FR1
                                ;         ITEM FR1
    .db     >(QWHAT + 0x8000), <QWHAT
                                ;         ITEM QWHAT
TAB6:                           ; TAB6    EQU  $                          ;"STEP" IN "FOR"
    .ascii  "STEP"              ;         DB   'STEP'
    .db     >(FR2 + 0x8000), <FR2
                                ;         ITEM FR2
    .db     >(FR3 + 0x8000), <FR3
                                ;         ITEM FR3
TAB8:                           ; TAB8    EQU  $                          ;RELATION OPERATORS
    .ascii  ">="                ;         DB   '>='
    .db     >(XP11 + 0x8000), <XP11
                                ;         ITEM XP11
    .db     '#'                 ;         DB   '#'
    .db     >(XP12 + 0x8000), <XP12
                                ;         ITEM XP12
    .db     '>'                 ;         DB   '>'
    .db     >(XP13 + 0x8000), <XP13
                                ;         ITEM XP13
    .db     '='                 ;         DB   '='
    .db     >(XP15 + 0x8000), <XP15
                                ;         ITEM XP15
    .ascii  "<="                ;         DB   '<='
    .db     >(XP14 + 0x8000), <XP14
                                ;         ITEM XP14
    .db     '<'                 ;         DB   '<'
    .db     >(XP16 + 0x8000), <XP16
                                ;         ITEM XP16
    .db     >(XP17 + 0x8000), <XP17
                                ;         ITEM XP17
                                ; ;
DIRECT:
    ld      hl, #(TAB1-1)       ; DIRECT: LXI  H,TAB1-1                   ;*** DIRECT ***
                                ; ;
EXEC:                           ; EXEC    EQU  $                          ;*** EXEC ***
EX0:
    call    RST5                ; EX0:    RST  5                          ;IGNORE LEADING BLANKS
    push    de                  ;         PUSH D                          ;SAVE POINTER
EX1:
    ld      a, (de)             ; EX1:    LDAX D                          ;IF FOUND '.' IN STRING
    inc     de                  ;         INX  D                          ;BEFORE ANY MISMATCH
    cp      #'.'                ;         CPI  '.'                        ;WE DECLARE A MATCH
    jp      z, EX3              ;         JZ   EX3
    inc     hl                  ;         INX  H                          ;HL->TABLE
    cp      (hl)                ;         CMP  M                          ;IF MATCH, TEST NEXT
    jp      z, EX1              ;         JZ   EX1
    ld      a, #0x7f            ;         MVI  A,7FH                      ;ELSE SEE IF BIT 7
    dec     de                  ;         DCX  D                          ;OF TABLE IS SET, WHICH
    cp      (hl)                ;         CMP  M                          ;IS THE JUMP ADDR. (HI)
    jp      c, EX5              ;         JC   EX5                        ;C:YES, MATCHED
EX2:
    inc     hl                  ; EX2:    INX  H                          ;NC:NO, FIND JUMP ADDR.
    cp      (hl)                ;         CMP  M
    jp      nc, EX2             ;         JNC  EX2
    inc     hl                  ;         INX  H                          ;BUMP TO NEXT TAB. ITEM
    pop     de                  ;         POP  D                          ;RESTORE STRING POINTER
    jp      EX0                 ;         JMP  EX0                        ;TEST AGAINST NEXT ITEM
EX3:
    ld      a, #0x7f            ; EX3:    MVI  A,7FH                      ;PARTIAL MATCH, FIND
EX4:
    inc     hl                  ; EX4:    INX  H                          ;JUMP ADDR., WHICH IS
    cp      (hl)                ;         CMP  M                          ;FLAGGED BY BIT 7
    jp      nc, EX4             ;         JNC  EX4
EX5:
    ld      a, (hl)             ; EX5:    MOV  A,M                        ;LOAD HL WITH THE JUMP
    inc     hl                  ;         INX  H                          ;ADDRESS FROM THE TABLE
    ld      l, (hl)             ;         MOV  L,M
    and     #0x7f               ;         ANI  07FH                       ;MASK OFF BIT 7
    ld      h, a                ;         MOV  H,A
    pop     af                  ;         POP  PSW                        ;CLEAN UP THE GABAGE
    jp      (hl)                ;         PCHL                            ;AND WE GO DO IT
                                ; ;
                                ; ;*************************************************************
                                ; ;*
                                ; ;* WHAT FOLLOWS IS THE CODE TO EXECUTE DIRECT AND STATEMENT
                                ; ;* COMMANDS.  CONTROL IS TRANSFERED TO THESE POINTS VIA THE
                                ; ;* COMMAND TABLE LOOKUP CODE OF 'DIRECT' AND 'EXEC' IN LAST
                                ; ;* SECTION.  AFTER THE COMMAND IS EXECUTED, CONTROL IS
                                ; ;* TRANSFERED TO OTHERS SECTIONS AS FOLLOWS:
                                ; ;*
                                ; ;* FOR 'LIST', 'NEW', AND 'STOP': GO BACK TO 'START'
                                ; ;* FOR 'RUN': GO EXECUTE THE FIRST STORED LINE IF ANY, ELSE
                                ; ;* GO BACK TO 'START'.
                                ; ;* FOR 'GOTO' AND 'GOSUB': GO EXECUTE THE TARGET LINE.
                                ; ;* FOR 'RETURN' AND 'NEXT': GO BACK TO SAVED RETURN LINE.
                                ; ;* FOR ALL OTHERS: IF 'CURRENT' -> 0, GO TO 'START', ELSE
                                ; ;* GO EXECUTE NEXT COMMAND.  (THIS IS DONE IN 'FINISH'.)
                                ; ;*************************************************************
                                ; ;*
                                ; ;* *** NEW *** STOP *** RUN (& FRIENDS) *** & GOTO ***
                                ; ;*
                                ; ;* 'NEW(CR)' SETS 'TXTUNF' TO POINT TO 'TXTBGN'
                                ; ;*
                                ; ;* 'STOP(CR)' GOES BACK TO 'START'
                                ; ;*
                                ; ;* 'RUN(CR)' FINDS THE FIRST STORED LINE, STORE ITS ADDRESS (IN
                                ; ;* 'CURRENT'), AND START EXECUTE IT.  NOTE THAT ONLY THOSE
                                ; ;* COMMANDS IN TAB2 ARE LEGAL FOR STORED PROGRAM.
                                ; ;*
                                ; ;* THERE ARE 3 MORE ENTRIES IN 'RUN':
                                ; ;* 'RUNNXL' FINDS NEXT LINE, STORES ITS ADDR. AND EXECUTES IT.
                                ; ;* 'RUNTSL' STORES THE ADDRESS OF THIS LINE AND EXECUTES IT.
                                ; ;* 'RUNSML' CONTINUES THE EXECUTION ON SAME LINE.
                                ; ;*
                                ; ;* 'GOTO EXPR(CR)' EVALUATES THE EXPRESSION, FIND THE TARGET
                                ; ;* LINE, AND JUMP TO 'RUNTSL' TO DO IT.
                                ; ;*
NEW:
    call    ENDCHK              ; NEW:    CALL ENDCHK                     ;*** NEW(CR) ***
    ld      hl, #TXTBGN         ;         LXI  H,TXTBGN
    ld      (TXTUNF), hl        ;         SHLD TXTUNF
                                ; ;
STOP:
    call    ENDCHK              ; STOP:   CALL ENDCHK                     ;*** STOP(CR) ***
    call    RST0                ;         RST  0
                                ; ;
RUN:
    call    ENDCHK              ; RUN:    CALL ENDCHK                     ;*** RUN(CR) ***
    ld      de, #TXTBGN         ;         LXI  D,TXTBGN                   ;FIRST SAVED LINE
                                ; ;
RUNNXL:
    ld      hl, #0              ; RUNNXL: LXI  H,0                        ;*** RUNNXL ***
    call    FDLNP               ;         CALL FDLNP                      ;FIND WHATEVER LINE #
    jp      c, START            ;         JC   START                      ;C:PASSED TXTUNF, QUIT
                                ; ;
RUNTSL:
    ex      de, hl              ; RUNTSL: XCHG                            ;*** RUNTSL ***
    ld      (CURRNT), hl        ;         SHLD CURRNT                     ;SET 'CURRENT'->LINE #
    ex      de, hl              ;         XCHG
    inc     de                  ;         INX  D                          ;BUMP PASS LINE #
    inc     de                  ;         INX  D
                                ; ;
RUNSML:
    call    CHKIO               ; RUNSML: CALL CHKIO                      ;*** RUNSML ***
    ld      hl, #(TAB2 - 1)     ;         LXI  H,TAB2-1                   ;FIND COMMAND IN TAB2
    jp      EXEC                ;         JMP  EXEC                       ;AND EXECUTE IT
                                ; ;
GOTO:
    call    RST3                ; GOTO:   RST  3                          ;*** GOTO EXPR ***
    push    de                  ;         PUSH D                          ;SAVE FOR ERROR ROUTINE
    call    ENDCHK              ;         CALL ENDCHK                     ;MUST FIND A CR
    call    FNDLN               ;         CALL FNDLN                      ;FIND THE TARGET LINE
    jp      nz, AHOW            ;         JNZ  AHOW                       ;NO SUCH LINE #
    pop     af                  ;         POP  PSW                        ;CLEAR THE PUSH DE
    jp      RUNTSL              ;         JMP  RUNTSL                     ;GO DO IT
                                ; ;
                                ; ;*************************************************************
                                ; ;*
                                ; ;* *** LIST *** & PRINT ***
                                ; ;*
                                ; ;* LIST HAS TWO FORMS:
                                ; ;* 'LIST(CR)' LISTS ALL SAVED LINES
                                ; ;* 'LIST #(CR)' START LIST AT THIS LINE #
                                ; ;* YOU CAN STOP THE LISTING BY CONTROL C KEY
                                ; ;*
                                ; ;* PRINT COMMAND IS 'PRINT ....;' OR 'PRINT ....(CR)'
                                ; ;* WHERE '....' IS A LIST OF EXPRESIONS, FORMATS, BACK-
                                ; ;* ARROWS, AND STRINGS.  THESE ITEMS ARE SEPERATED BY COMMAS.
                                ; ;*
                                ; ;* A FORMAT IS A POUND SIGN FOLLOWED BY A NUMBER.  IT CONTROLS
                                ; ;* THE NUMBER OF SPACES THE VALUE OF A EXPRESION IS GOING TO
                                ; ;* BE PRINTED.  IT STAYS EFFECTIVE FOR THE REST OF THE PRINT
                                ; ;* COMMAND UNLESS CHANGED BY ANOTHER FORMAT.  IF NO FORMAT IS
                                ; ;* SPECIFIED, 6 POSITIONS WILL BE USED.
                                ; ;*
                                ; ;* A STRING IS QUOTED IN A PAIR OF SINGLE QUOTES OR A PAIR OF
                                ; ;* DOUBLE QUOTES.
                                ; ;*
                                ; ;* A BACK-ARROW MEANS GENERATE A (CR) WITHOUT (LF)
                                ; ;*
                                ; ;* A (CRLF) IS GENERATED AFTER THE ENTIRE LIST HAS BEEN
                                ; ;* PRINTED OR IF THE LIST IS A NULL LIST.  HOWEVER IF THE LIST
                                ; ;* ENDED WITH A COMMA, NO (CRLF) IS GENERATED.
                                ; ;*
LIST:
    call    TSTNUM              ; LIST:   CALL TSTNUM                     ;TEST IF THERE IS A #
    call    ENDCHK              ;         CALL ENDCHK                     ;IF NO # WE GET A 0
    call    FNDLN               ;         CALL FNDLN                      ;FIND THIS OR NEXT LINE
LS1:
    jp      c, START            ; LS1:    JC   START                      ;C:PASSED TXTUNF
    call    PRTLN               ;         CALL PRTLN                      ;PRINT THE LINE
    call    CHKIO               ;         CALL CHKIO                      ;STOP IF HIT CONTROL-C
    call    FDLNP               ;         CALL FDLNP                      ;FIND NEXT LINE
    jp      LS1                 ;         JMP  LS1                        ;AND LOOP BACK
                                ; ;
PRINT:
    ld      c, #6               ; PRINT:  MVI  C,6                        ;C = # OF SPACES
    call    RST1                ;         RST  1                          ;IF NULL LIST & ";"
    .db     ';'                 ;         DB   ';'
    .db     PR2 - . - 1         ;         DB   PR2-$-1
    call    CRLF                ;         CALL CRLF                       ;GIVE CR-LF AND
    jp      RUNSML              ;         JMP  RUNSML                     ;CONTINUE SAME LINE
PR2:
    call    RST1                ; PR2:    RST  1                          ;IF NULL LIST (CR)
    .db     CR                  ;         DB   CR
    .db     PR0 - . - 1         ;         DB   PR0-$-1
    call    CRLF                ;         CALL CRLF                       ;ALSO GIVE CR-LF AND
    jp      RUNNXL              ;         JMP  RUNNXL                     ;GO TO NEXT LINE
PR0:
    call    RST1                ; PR0:    RST  1                          ;ELSE IS IT FORMAT?
    .db     '#'                 ;         DB   '#'
    .db     PR1 - . - 1         ;         DB   PR1-$-1
    call    RST3                ;         RST  3                          ;YES, EVALUATE EXPR.
    ld      c, l                ;         MOV  C,L                        ;AND SAVE IT IN C
    jp      PR3                 ;         JMP  PR3                        ;LOOK FOR MORE TO PRINT
PR1:
    call    QTSTG               ; PR1:    CALL QTSTG                      ;OR IS IT A STRING?
    jp      PR8                 ;         JMP  PR8                        ;IF NOT, MUST BE EXPR.
PR3:
    call    RST1                ; PR3:    RST  1                          ;IF ",", GO FIND NEXT
    .db     ','                 ;         DB   ','
    .db     PR6 - . - 1         ;         DB   PR6-$-1
    call    FIN                 ;         CALL FIN                        ;IN THE LIST.
    jp      PR0                 ;         JMP  PR0                        ;LIST CONTINUES
PR6:
    call    CRLF                ; PR6:    CALL CRLF                       ;LIST ENDS
    call    RST6                ;         RST  6
PR8:
    call    RST3                ; PR8:    RST  3                          ;EVALUATE THE EXPR
    push    bc                  ;         PUSH B
    call    PRTNUM              ;         CALL PRTNUM                     ;PRINT THE VALUE
    pop     bc                  ;         POP  B
    jp      PR3                 ;         JMP  PR3                        ;MORE TO PRINT?
                                ; ;
                                ; ;*************************************************************
                                ; ;*
                                ; ;* *** GOSUB *** & RETURN ***
                                ; ;*
                                ; ;* 'GOSUB EXPR;' OR 'GOSUB EXPR (CR)' IS LIKE THE 'GOTO'
                                ; ;* COMMAND, EXCEPT THAT THE CURRENT TEXT POINTER, STACK POINTER
                                ; ;* ETC. ARE SAVE SO THAT EXECUTION CAN BE CONTINUED AFTER THE
                                ; ;* SUBROUTINE 'RETURN'.  IN ORDER THAT 'GOSUB' CAN BE NESTED
                                ; ;* (AND EVEN RECURSIVE), THE SAVE AREA MUST BE STACKED.
                                ; ;* THE STACK POINTER IS SAVED IN 'STKGOS', THE OLD 'STKGOS' IS
                                ; ;* SAVED IN THE STACK.  IF WE ARE IN THE MAIN ROUTINE, 'STKGOS'
                                ; ;* IS ZERO (THIS WAS DONE BY THE "MAIN" SECTION OF THE CODE),
                                ; ;* BUT WE STILL SAVE IT AS A FLAG FOR NO FURTHER 'RETURN'S.
                                ; ;*
                                ; ;* 'RETURN(CR)' UNDOS EVERYTHING THAT 'GOSUB' DID, AND THUS
                                ; ;* RETURN THE EXECUTION TO THE COMMAND AFTER THE MOST RECENT
                                ; ;* 'GOSUB'.  IF 'STKGOS' IS ZERO, IT INDICATES THAT WE
                                ; ;* NEVER HAD A 'GOSUB' AND IS THUS AN ERROR.
                                ; ;*
GOSUB:
    call    PUSHA               ; GOSUB:  CALL PUSHA                      ;SAVE THE CURRENT "FOR"
    call    RST3                ;         RST  3                          ;PARAMETERS
    push    de                  ;         PUSH D                          ;AND TEXT POINTER
    call    FNDLN               ;         CALL FNDLN                      ;FIND THE TARGET LINE
    jp      nz, AHOW            ;         JNZ  AHOW                       ;NOT THERE. SAY "HOW?"
    ld      hl, (CURRNT)        ;         LHLD CURRNT                     ;FOUND IT, SAVE OLD
    push    hl                  ;         PUSH H                          ;'CURRNT' OLD 'STKGOS'
    ld      hl, (STKGOS)        ;         LHLD STKGOS
    push    hl                  ;         PUSH H
    ld      hl, #0              ;         LXI  H,0                        ;AND LOAD NEW ONES
    ld      (LOPVAR), hl        ;         SHLD LOPVAR
    add     hl, sp              ;         DAD  SP
    ld      (STKGOS), hl        ;         SHLD STKGOS
    jp      RUNTSL              ;         JMP  RUNTSL                     ;THEN RUN THAT LINE
RETURN:
    call    ENDCHK              ; RETURN: CALL ENDCHK                     ;THERE MUST BE A CR
    ld      hl, (STKGOS)        ;         LHLD STKGOS                     ;OLD STACK POINTER
    ld      a, h                ;         MOV  A,H                        ;0 MEANS NOT EXIST
    or      l                   ;         ORA  L
    jp      z, QWHAT            ;         JZ   QWHAT                      ;SO, WE SAY: "WHAT?"
    ld      sp, hl              ;         SPHL                            ;ELSE, RESTORE IT
    pop     hl                  ;         POP  H
    ld      (STKGOS), hl        ;         SHLD STKGOS                     ;AND THE OLD 'STKGOS'
    pop     hl                  ;         POP  H
    ld      (CURRNT), hl        ;         SHLD CURRNT                     ;AND THE OLD 'CURRNT'
    pop     de                  ;         POP  D                          ;OLD TEXT POINTER
    call    POPA                ;         CALL POPA                       ;OLD "FOR" PARAMETERS
    call    RST6                ;         RST  6                          ;AND WE ARE BACK HOME
                                ; ;
                                ; ;*************************************************************
                                ; ;*
                                ; ;* *** FOR *** & NEXT ***
                                ; ;*
                                ; ;* 'FOR' HAS TWO FORMS:
                                ; ;* 'FOR VAR=EXP1 TO EXP2 STEP EXP1' AND 'FOR VAR=EXP1 TO EXP2'
                                ; ;* THE SECOND FORM MEANS THE SAME THING AS THE FIRST FORM WITH
                                ; ;* EXP1=1.  (I.E., WITH A STEP OF +1.)
                                ; ;* TBI WILL FIND THE VARIABLE VAR, AND SET ITS VALUE TO THE
                                ; ;* CURRENT VALUE OF EXP1.  IT ALSO EVALUATES EXPR2 AND EXP1
                                ; ;* AND SAVE ALL THESE TOGETHER WITH THE TEXT POINTER ETC. IN
                                ; ;* THE 'FOR' SAVE AREA, WHICH CONSISTS OF 'LOPVAR', 'LOPINC',
                                ; ;* 'LOPLMT', 'LOPLN', AND 'LOPPT'.  IF THERE IS ALREADY SOME-
                                ; ;* THING IN THE SAVE AREA (THIS IS INDICATED BY A NON-ZERO
                                ; ;* 'LOPVAR'), THEN THE OLD SAVE AREA IS SAVED IN THE STACK
                                ; ;* BEFORE THE NEW ONE OVERWRITES IT.
                                ; ;* TBI WILL THEN DIG IN THE STACK AND FIND OUT IF THIS SAME
                                ; ;* VARIABLE WAS USED IN ANOTHER CURRENTLY ACTIVE 'FOR' LOOP.
                                ; ;* IF THAT IS THE CASE, THEN THE OLD 'FOR' LOOP IS DEACTIVATED.
                                ; ;* (PURGED FROM THE STACK..)
                                ; ;*
                                ; ;* 'NEXT VAR' SERVES AS THE LOGICAL (NOT NECESSARILLY PHYSICAL)
                                ; ;* END OF THE 'FOR' LOOP.  THE CONTROL VARIABLE VAR. IS CHECKED
                                ; ;* WITH THE 'LOPVAR'.  IF THEY ARE NOT THE SAME, TBI DIGS IN
                                ; ;* THE STACK TO FIND THE RIGHT ONE AND PURGES ALL THOSE THAT
                                ; ;* DID NOT MATCH.  EITHER WAY, TBI THEN ADDS THE 'STEP' TO
                                ; ;* THAT VARIABLE AND CHECK THE RESULT WITH THE LIMIT.  IF IT
                                ; ;* IS WITHIN THE LIMIT, CONTROL LOOPS BACK TO THE COMMAND
                                ; ;* FOLLOWING THE 'FOR'.  IF OUTSIDE THE LIMIT, THE SAVE AREA
                                ; ;* IS PURGED AND EXECUTION CONTINUES.
                                ; ;*
FOR:
    call    PUSHA               ; FOR:    CALL PUSHA                      ;SAVE THE OLD SAVE AREA
    call    SETVAL              ;         CALL SETVAL                     ;SET THE CONTROL VAR.
    dec     hl                  ;         DCX  H                          ;HL IS ITS ADDRESS
    ld      (LOPVAR), hl        ;         SHLD LOPVAR                     ;SAVE THAT
    ld      hl, #(TAB5 - 1)     ;         LXI  H,TAB5-1                   ;USE 'EXEC' TO LOOK
    jp      EXEC                ;         JMP  EXEC                       ;FOR THE WORD 'TO'
FR1:
    call    RST3                ; FR1:    RST  3                          ;EVALUATE THE LIMIT
    ld      (LOPLMT), hl        ;         SHLD LOPLMT                     ;SAVE THAT
    ld      hl, #(TAB6 - 1)     ;         LXI  H,TAB6-1                   ;USE 'EXEC' TO LOOK
    jp      EXEC                ;         JMP EXEC                        ;FOR THE WORD 'STEP'
FR2:
    call    RST3                ; FR2:    RST  3                          ;FOUND IT, GET STEP
    jp      FR4                 ;         JMP  FR4
FR3:
    ld      hl, #1              ; FR3:    LXI  H,1                        ;NOT FOUND, SET TO 1
FR4:
    ld      (LOPINC), hl        ; FR4:    SHLD LOPINC                     ;SAVE THAT TOO
FR5:
    ld      hl, (CURRNT)        ; FR5:    LHLD CURRNT                     ;SAVE CURRENT LINE #
    ld      (LOPLN), hl         ;         SHLD LOPLN
    ex      de, hl              ;         XCHG                            ;AND TEXT POINTER
    ld      (LOPPT), hl         ;         SHLD LOPPT
    ld      bc, #10             ;         LXI  B,10                       ;DIG INTO STACK TO
    ld     hl, (LOPVAR)         ;         LHLD LOPVAR                     ;FIND 'LOPVAR'
    ex      de, hl              ;         XCHG
    ld      h, b                ;         MOV  H,B
    ld      l, b                ;         MOV  L,B                        ;HL=0 NOW
    add     hl, sp              ;         DAD  SP                         ;HERE IS THE STACK
    .db     0x3e                ;         DB   3EH
FR7:
    add     hl, bc              ; FR7:    DAD  B                          ;EACH LEVEL IS 10 DEEP
    ld      a, (hl)             ;         MOV  A,M                        ;GET THAT OLD 'LOPVAR'
    inc     hl                  ;         INX  H
    or      (hl)                ;         ORA  M
    jp      z, FR8              ;         JZ   FR8                        ;0 SAYS NO MORE IN IT
    ld      a, (hl)             ;         MOV  A,M
    dec     hl                  ;         DCX  H
    cp      d                   ;         CMP  D                          ;SAME AS THIS ONE?
    jp      nz, FR7             ;         JNZ  FR7
    ld      a, (hl)             ;         MOV  A,M                        ;THE OTHER HALF?
    cp      e                   ;         CMP  E
    jp      nz, FR7             ;         JNZ  FR7
    ex      de, hl              ;         XCHG                            ;YES, FOUND ONE
    ld      hl, #0              ;         LXI  H,0
    add     hl, sp              ;         DAD  SP                         ;TRY TO MOVE SP
    ld      b, h                ;         MOV  B,H
    ld      c, l                ;         MOV  C,L
    ld      hl, #10             ;         LXI  H,10
    add     hl, de              ;         DAD  D
    call    MVDOWN              ;         CALL MVDOWN                     ;AND PURGE 10 WORDS
    ld      sp, hl              ;         SPHL                            ;IN THE STACK
FR8:
    ld      hl, (LOPPT)         ; FR8:    LHLD LOPPT                      ;JOB DONE, RESTORE DE
    ex      de, hl              ;         XCHG
    call    RST6                ;         RST  6                          ;AND CONTINUE
                                ; ;
NEXT:
    call    RST7                ; NEXT:   RST  7                          ;GET ADDRESS OF VAR.
    jp      c, QWHAT            ;         JC   QWHAT                      ;NO VARIABLE, "WHAT?"
    ld      (VARNXT), hl        ;         SHLD VARNXT                     ;YES, SAVE IT
NX0:
    push    de                  ; NX0:    PUSH D                          ;SAVE TEXT POINTER
    ex      de, hl              ;         XCHG
    ld      hl, (LOPVAR)        ;         LHLD LOPVAR                     ;GET VAR. IN 'FOR'
    ld      a, h                ;         MOV  A,H
    or      l                   ;         ORA  L                          ;0 SAYS NEVER HAD ONE
    jp      z, AWHAT            ;         JZ   AWHAT                      ;SO WE ASK: "WHAT?"
    call    RST4                ;         RST  4                          ;ELSE WE CHECK THEM
    jp      z, NX3              ;         JZ   NX3                        ;OK, THEY AGREE
    pop     de                  ;         POP  D                          ;NO, LET'S SEE
    call    POPA                ;         CALL POPA                       ;PURGE CURRENT LOOP
    ld      hl, (VARNXT)        ;         LHLD VARNXT                     ;AND POP ONE LEVEL
    jp      NX0                 ;         JMP  NX0                        ;GO CHECK AGAIN
NX3:
    ld      e, (hl)             ; NX3:    MOV  E,M                        ;COME HERE WHEN AGREED
    inc     hl                  ;         INX  H
    ld      d, (hl)             ;         MOV  D,M                        ;DE=VALUE OF VAR.
    ld      hl, (LOPINC)        ;         LHLD LOPINC
    push    hl                  ;         PUSH H
    add     hl, de              ;         DAD  D                          ;ADD ONE STEP
    ex      de, hl              ;         XCHG
    ld      hl, (LOPVAR)        ;         LHLD LOPVAR                     ;PUT IT BACK
    ld      (hl), e             ;         MOV  M,E
    inc     hl                  ;         INX  H
    ld      (hl), d             ;         MOV  M,D
    ld      hl, (LOPLMT)        ;         LHLD LOPLMT                     ;HL->LIMIT
    pop     af                  ;         POP  PSW                        ;OLD HL
    or      a                   ;         ORA  A
    jp      p, NX1              ;         JP   NX1                        ;STEP > 0
    ex      de, hl              ;         XCHG                            ;STEP < 0
NX1:
    call    CKHLDE              ; NX1:    CALL CKHLDE                     ;COMPARE WITH LIMIT
    pop     de                  ;         POP  D                          ;RESTORE TEXT POINTER
    jp      c, NX2              ;         JC   NX2                        ;OUTSIDE LIMIT
    ld      hl, (LOPLN)         ;         LHLD LOPLN                      ;WITHIN LIMIT, GO
    ld      (CURRNT), hl        ;         SHLD CURRNT                     ;BACK TO THE SAVED
    ld      hl, (LOPPT)         ;         LHLD LOPPT                      ;'CURRNT' AND TEXT
    ex      de, hl              ;         XCHG                            ;POINTER
    call    RST6                ;         RST  6
NX2:
    call    POPA                ; NX2:    CALL POPA                       ;PURGE THIS LOOP
    call    RST6                ;         RST  6
                                ; ;
                                ; ;*************************************************************
                                ; ;*
                                ; ;* *** REM *** IF *** INPUT *** & LET (& DEFLT) ***
                                ; ;*
                                ; ;* 'REM' CAN BE FOLLOWED BY ANYTHING AND IS IGNORED BY TBI.
                                ; ;* TBI TREATS IT LIKE AN 'IF' WITH A FALSE CONDITION.
                                ; ;*
                                ; ;* 'IF' IS FOLLOWED BY AN EXPR. AS A CONDITION AND ONE OR MORE
                                ; ;* COMMANDS (INCLUDING OTHER 'IF'S) SEPERATED BY SEMI-COLONS.
                                ; ;* NOTE THAT THE WORD 'THEN' IS NOT USED.  TBI EVALUATES THE
                                ; ;* EXPR. IF IT IS NON-ZERO, EXECUTION CONTINUES.  IF THE
                                ; ;* EXPR. IS ZERO, THE COMMANDS THAT FOLLOWS ARE IGNORED AND
                                ; ;* EXECUTION CONTINUES AT THE NEXT LINE.
                                ; ;*
                                ; ;* 'INPUT' COMMAND IS LIKE THE 'PRINT' COMMAND, AND IS FOLLOWED
                                ; ;* BY A LIST OF ITEMS.  IF THE ITEM IS A STRING IN SINGLE OR
                                ; ;* DOUBLE QUOTES, OR IS A BACK-ARROW, IT HAS THE SAME EFFECT AS
                                ; ;* IN 'PRINT'.  IF AN ITEM IS A VARIABLE, THIS VARIABLE NAME IS
                                ; ;* PRINTED OUT FOLLOWED BY A COLON.  THEN TBI WAITS FOR AN
                                ; ;* EXPR. TO BE TYPED IN.  THE VARIABLE IS THEN SET TO THE
                                ; ;* VALUE OF THIS EXPR.  IF THE VARIABLE IS PROCEDED BY A STRING
                                ; ;* (AGAIN IN SINGLE OR DOUBLE QUOTES), THE STRING WILL BE
                                ; ;* PRINTED FOLLOWED BY A COLON.  TBI THEN WAITS FOR INPUT EXPR.
                                ; ;* AND SET THE VARIABLE TO THE VALUE OF THE EXPR.
                                ; ;*
                                ; ;* IF THE INPUT EXPR. IS INVALID, TBI WILL PRINT "WHAT?",
                                ; ;* "HOW?" OR "SORRY" AND REPRINT THE PROMPT AND REDO THE INPUT.
                                ; ;* THE EXECUTION WILL NOT TERMINATE UNLESS YOU TYPE CONTROL-C.
                                ; ;* THIS IS HANDLED IN 'INPERR'.
                                ; ;*
                                ; ;* 'LET' IS FOLLOWED BY A LIST OF ITEMS SEPERATED BY COMMAS.
                                ; ;* EACH ITEM CONSISTS OF A VARIABLE, AN EQUAL SIGN, AND AN EXPR.
                                ; ;* TBI EVALUATES THE EXPR. AND SET THE VARIABLE TO THAT VALUE.
                                ; ;* TBI WILL ALSO HANDLE 'LET' COMMAND WITHOUT THE WORD 'LET'.
                                ; ;* THIS IS DONE BY 'DEFLT'.
                                ; ;*
REM:
    ld      hl, #0              ; REM:    LXI  H,0                        ;*** REM ***
    .db     0x3e                ;         DB   3EH                        ;THIS IS LIKE 'IF 0'
                                ; ;
IFF:
    call    RST3                ; IFF:    RST  3                          ;*** IF ***
    ld      a, h                ;         MOV  A,H                        ;IS THE EXPR.=0?
    or      l                   ;         ORA  L
    jp      nz, RUNSML          ;         JNZ  RUNSML                     ;NO, CONTINUE
    call    FNDSKP              ;         CALL FNDSKP                     ;YES, SKIP REST OF LINE
    jp      nc, RUNTSL          ;         JNC  RUNTSL                     ;AND RUN THE NEXT LINE
    call    RST0                ;         RST  0                          ;IF NO NEXT, RE-START
                                ; ;
INPERR:
    ld      hl, (STKINP)        ; INPERR: LHLD STKINP                     ;*** INPERR ***
    ld      sp, hl              ;         SPHL                            ;RESTORE OLD SP
    pop     hl                  ;         POP  H                          ;AND OLD 'CURRNT'
    ld      (CURRNT), hl        ;         SHLD CURRNT
    pop     de                  ;         POP  D                          ;AND OLD TEXT POINTER
    pop     de                  ;         POP  D
                                ; ;
INPUT:                          ; INPUT   EQU  $                          ;*** INPUT ***
IP1:
    push    de                  ; IP1:    PUSH D                          ;SAVE IN CASE OF ERROR
    call    QTSTG               ;         CALL QTSTG                      ;IS NEXT ITEM A STRING?
    jp      IP2                 ;         JMP  IP2                        ;NO
    call    RST7                ;         RST  7                          ;YES, BUT FOLLOWED BY A
    jp      c, IP4              ;         JC   IP4                        ;VARIABLE?   NO.
    jp      IP3                 ;         JMP  IP3                        ;YES.  INPUT VARIABLE
IP2:
    push    de                  ; IP2:    PUSH D                          ;SAVE FOR 'PRTSTG'
    call    RST7                ;         RST  7                          ;MUST BE VARIABLE NOW
    jp      c, QWHAT            ;         JC   QWHAT                      ;"WHAT?" IT IS NOT?
    ld      a, (de)             ;         LDAX D                          ;GET READY FOR 'PRTSTR'
    ld      c, a                ;         MOV  C,A
    sub     a                   ;         SUB  A
    ld      (de), a             ;         STAX D
    pop     de                  ;         POP  D
    call    PRTSTG              ;         CALL PRTSTG                     ;PRINT STRING AS PROMPT
    ld      a, c                ;         MOV  A,C                        ;RESTORE TEXT
    dec     de                  ;         DCX  D
    ld      (de), a             ;         STAX D
IP3:
    push    de                  ; IP3:    PUSH D                          ;SAVE IN CASE OF ERROR
    ex      de, hl              ;         XCHG
    ld      hl, (CURRNT)        ;         LHLD CURRNT                     ;ALSO SAVE 'CURRNT'
    push    hl                  ;         PUSH H
    ld      hl, #IP1            ;         LXI  H,IP1                      ;A NEGATIVE NUMBER
    ld      (CURRNT), hl        ;         SHLD CURRNT                     ;AS A FLAG
    ld      hl, #0              ;         LXI  H,0                        ;SAVE SP TOO
    add     hl, sp              ;         DAD  SP
    ld      (STKINP), hl        ;         SHLD STKINP
    push    de                  ;         PUSH D                          ;OLD HL
    ld      a, #':'             ;         MVI  A,':'                      ;PRINT THIS TOO
    call    GETLN               ;         CALL GETLN                      ;AND GET A LINE
    ld      de, #BUFFER         ;         LXI  D,BUFFER                   ;POINTS TO BUFFER
    call    RST3                ;         RST  3                          ;EVALUATE INPUT
    nop                         ;         NOP                             ;CAN BE 'CALL ENDCHK'
    nop                         ;         NOP
    nop                         ;         NOP
    pop     de                  ;         POP  D                          ;OK, GET OLD HL
    ex      de, hl              ;         XCHG
    ld      (hl), e             ;         MOV  M,E                        ;SAVE VALUE IN VAR.
    inc     hl                  ;         INX  H
    ld      (hl), d             ;         MOV  M,D
    pop     hl                  ;         POP  H                          ;GET OLD 'CURRNT'
    ld      (CURRNT), hl        ;         SHLD CURRNT
    pop     de                  ;         POP  D                          ;AND OLD TEXT POINTER
IP4:
    pop     af                  ; IP4:    POP  PSW                        ;PURGE JUNK IN STACK
    call    RST1                ;         RST  1                          ;IS NEXT CH. ','?
    .db     ','                 ;         DB   ','
    .db     IP5 - . - 1         ;         DB   IP5-$-1
    jp      IP1                 ;         JMP  IP1                        ;YES, MORE ITEMS.
IP5:
    call    RST6                ; IP5:    RST  6
                                ; ;
DEFLT:
    ld      a, (de)             ; DEFLT:  LDAX D                          ;***  DEFLT ***
    cp      #CR                 ;         CPI  CR                         ;EMPTY LINE IS OK
    jp      z, LT1              ;         JZ   LT1                        ;ELSE IT IS 'LET'
                                ; ;
LET:
    call    SETVAL              ; LET:    CALL SETVAL                     ;*** LET ***
    call    RST1                ;         RST  1                          ;SET VALUE TO VAR.
    .db     ','                 ;         DB   ','
    .db     LT1 - . - 1         ;         DB   LT1-$-1
    jp      LET                 ;         JMP  LET                        ;ITEM BY ITEM
LT1:
    call    RST6                ; LT1:    RST  6                          ;UNTIL FINISH
                                ; ;
                                ; ;*************************************************************
                                ; ;*
                                ; ;* *** EXPR ***
                                ; ;*
                                ; ;* 'EXPR' EVALUATES ARITHMETICAL OR LOGICAL EXPRESSIONS.
                                ; ;* <EXPR>::<EXPR2>
                                ; ;*         <EXPR2><REL.OP.><EXPR2>
                                ; ;* WHERE <REL.OP.> IS ONE OF THE OPERATORS IN TAB8 AND THE
                                ; ;* RESULT OF THESE OPERATIONS IS 1 IF TRUE AND 0 IF FALSE.
                                ; ;* <EXPR2>::=(+ OR -)<EXPR3>(+ OR -<EXPR3>)(....)
                                ; ;* WHERE () ARE OPTIONAL AND (....) ARE OPTIONAL REPEATS.
                                ; ;* <EXPR3>::=<EXPR4>(* OR /><EXPR4>)(....)
                                ; ;* <EXPR4>::=<VARIABLE>
                                ; ;*           <FUNCTION>
                                ; ;*           (<EXPR>)
                                ; ;* <EXPR> IS RECURSIVE SO THAT VARIABLE '@' CAN HAVE AN <EXPR>
                                ; ;* AS INDEX, FUNCTIONS CAN HAVE AN <EXPR> AS ARGUMENTS, AND
                                ; ;* <EXPR4> CAN BE AN <EXPR> IN PARANTHESE.
                                ; ;*
                                ; ;EXPR:  CALL EXPR2                      ;THIS IS AT LOC. 18
                                ; ;       PUSH H                          ;SAVE <EXPR2> VALUE
EXPR1:
    ld      hl, #(TAB8 - 1)     ; EXPR1:  LXI  H,TAB8-1                   ;LOOKUP REL.OP.
    jp      EXEC                ;         JMP  EXEC                       ;GO DO IT
XP11:
    call    XP18                ; XP11:   CALL XP18                       ;REL.OP.">="
    ret     c                   ;         RC                              ;NO, RETURN HL=0
    ld      l, a                ;         MOV  L,A                        ;YES, RETURN HL=1
    ret                         ;         RET
XP12:
    call    XP18                ; XP12:   CALL XP18                       ;REL.OP."#"
    ret     z                   ;         RZ                              ;FALSE, RETURN HL=0
    ld      l, a                ;         MOV  L,A                        ;TRUE, RETURN HL=1
    ret                         ;         RET
XP13:
    call    XP18                ; XP13:   CALL XP18                       ;REL.OP.">"
    ret     z                   ;         RZ                              ;FALSE
    ret     c                   ;         RC                              ;ALSO FALSE, HL=0
    ld      l, a                ;         MOV  L,A                        ;TRUE, HL=1
    ret                         ;         RET
XP14:
    call    XP18                ; XP14:   CALL XP18                       ;REL.OP."<="
    ld      l, a                ;         MOV  L,A                        ;SET HL=1
    ret     z                   ;         RZ                              ;REL. TRUE, RETURN
    ret     c                   ;         RC
    ld      l, h                ;         MOV  L,H                        ;ELSE SET HL=0
    ret                         ;         RET
XP15:
    call    XP18                ; XP15:   CALL XP18                       ;REL.OP."="
    ret     nz                  ;         RNZ                             ;FALSE, RETURN HL=0
    ld      l, a                ;         MOV  L,A                        ;ELSE SET HL=1
    ret                         ;         RET
XP16:
    call    XP18                ; XP16:   CALL XP18                       ;REL.OP."<"
    ret     nc                  ;         RNC                             ;FALSE, RETURN HL=0
    ld      l, a                ;         MOV  L,A                        ;ELSE SET HL=1
    ret                         ;         RET
XP17:
    pop     hl                  ; XP17:   POP  H                          ;NOT .REL.OP
    ret                         ;         RET                             ;RETURN HL=<EXPR2>
XP18:
    ld      a, c                ; XP18:   MOV  A,C                        ;SUBROUTINE FOR ALL
    pop     hl                  ;         POP  H                          ;REL.OP.'S
    pop     bc                  ;         POP  B
    push    hl                  ;         PUSH H                          ;REVERSE TOP OF STACK
    push    bc                  ;         PUSH B
    ld      c, a                ;         MOV  C,A
    call    EXPR2               ;         CALL EXPR2                      ;GET 2ND <EXPR2>
    ex      de, hl              ;         XCHG                            ;VALUE IN DE NOW
    ex      (sp), hl            ;         XTHL                            ;1ST <EXPR2> IN HL
    call    CKHLDE              ;         CALL CKHLDE                     ;COMPARE 1ST WITH 2ND
    pop     de                  ;         POP  D                          ;RESTORE TEXT POINTER
    ld      hl, #0              ;         LXI  H,0                        ;SET HL=0, A=1
    ld      a, #1               ;         MVI  A,1
    ret                         ;         RET
                                ; ;
EXPR2:
    call    RST1                ; EXPR2:  RST  1                          ;NEGATIVE SIGN?
    .db     '-'                 ;         DB   '-'
    .db     XP21 - . - 1        ;         DB   XP21-$-1
    ld      hl, #0              ;         LXI  H,0                        ;YES, FAKE '0-'
    jp      XP26                ;         JMP  XP26                       ;TREAT LIKE SUBTRACT
XP21:
    call    RST1                ; XP21:   RST  1                          ;POSITIVE SIGN? IGNORE
    .db     '+'                 ;         DB   '+'
    .db     XP22 - . - 1        ;         DB   XP22-$-1
XP22:
    call    EXPR3               ; XP22:   CALL EXPR3                      ;1ST <EXPR3>
XP23:
    call    RST1                ; XP23:   RST  1                          ;ADD?
    .db     '+'                 ;         DB   '+'
    .db     XP25 - . - 1        ;         DB   XP25-$-1
    push    hl                  ;         PUSH H                          ;YES, SAVE VALUE
    call    EXPR3               ;         CALL EXPR3                      ;GET 2ND <EXPR3>
XP24:
    ex      de, hl              ; XP24:   XCHG                            ;2ND IN DE
    ex      (sp), hl            ;         XTHL                            ;1ST IN HL
    ld      a, h                ;         MOV  A,H                        ;COMPARE SIGN
    xor     d                   ;         XRA  D
    ld      a, d                ;         MOV  A,D
    add     hl, de              ;         DAD  D
    pop     de                  ;         POP  D                          ;RESTORE TEXT POINTER
    jp      m, XP23             ;         JM   XP23                       ;1ST AND 2ND SIGN DIFFER
    xor     h                   ;         XRA  H                          ;1ST AND 2ND SIGN EQUAL
    jp      p, XP23             ;         JP   XP23                       ;SO IS RESULT
    jp      QHOW                ;         JMP  QHOW                       ;ELSE WE HAVE OVERFLOW
XP25:
    call    RST1                ; XP25:   RST  1                          ;SUBTRACT?
    .db     '-'                 ;         DB   '-'
    .db     XP42 - . - 1        ;         DB   XP42-$-1
XP26:
    push    hl                  ; XP26:   PUSH H                          ;YES, SAVE 1ST <EXPR3>
    call    EXPR3               ;         CALL EXPR3                      ;GET 2ND <EXPR3>
    call    CHGSGN              ;         CALL CHGSGN                     ;NEGATE
    jp      XP24                ;         JMP  XP24                       ;AND ADD THEM
                                ; ;
EXPR3:
    call    EXPR4               ; EXPR3:  CALL EXPR4                      ;GET 1ST <EXPR4>
XP31:
    call    RST1                ; XP31:   RST  1                          ;MULTIPLY?
    .db     '*'                 ;         DB   '*'
    .db     XP34 - . - 1        ;         DB   XP34-$-1
    push    hl                  ;         PUSH H                          ;YES, SAVE 1ST
    call    EXPR4               ;         CALL EXPR4                      ;AND GET 2ND <EXPR4>
    ld      b, #0               ;         MVI  B,0                        ;CLEAR B FOR SIGN
    call    CHKSGN              ;         CALL CHKSGN                     ;CHECK SIGN
    ex      de, hl              ;         XCHG                            ;2ND IN DE NOW
    ex      (sp), hl            ;         XTHL                            ;1ST IN HL
    call    CHKSGN              ;         CALL CHKSGN                     ;CHECK SIGN OF 1ST
    ld      a, h                ;         MOV  A,H                        ;IS HL > 255 ?
    or      a                   ;         ORA  A
    jp      z, XP32             ;         JZ   XP32                       ;NO
    ld      a, d                ;         MOV  A,D                        ;YES, HOW ABOUT DE
    or      d                   ;         ORA  D
    ex      de, hl              ;         XCHG                            ;PUT SMALLER IN HL
    jp      nz, AHOW            ;         JNZ  AHOW                       ;ALSO >, WILL OVERFLOW
XP32:
    ld      a, l                ; XP32:   MOV  A,L                        ;THIS IS DUMB
    ld      hl, #0              ;         LXI  H,0                        ;CLEAR RESULT
    or      a                   ;         ORA  A                          ;ADD AND COUNT
    jp      z, XP35             ;         JZ   XP35
XP33:
    add     hl, de              ; XP33:   DAD  D
    jp      c, AHOW             ;         JC   AHOW                       ;OVERFLOW
    dec     a                   ;         DCR  A
    jp      nz, XP33            ;         JNZ  XP33
    jp      XP35                ;         JMP  XP35                       ;FINISHED
XP34:
    call    RST1                ; XP34:   RST  1                          ;DIVIDE?
    .db     '/'                 ;         DB   '/'
    .db     XP42 - . - 1        ;         DB   XP42-$-1
    push    hl                  ;         PUSH H                          ;YES, SAVE 1ST <EXPR4>
    call    EXPR4               ;         CALL EXPR4                      ;AND GET THE SECOND ONE
    ld      b, #0               ;         MVI  B,0                        ;CLEAR B FOR SIGN
    call    CHKSGN              ;         CALL CHKSGN                     ;CHECK SIGN OF 2ND
    ex      de, hl              ;         XCHG                            ;PUT 2ND IN DE
    ex      (sp), hl            ;         XTHL                            ;GET 1ST IN HL
    call    CHKSGN              ;         CALL CHKSGN                     ;CHECK SIGN OF 1ST
    ld      a, d                ;         MOV  A,D                        ;DIVIDE BY 0?
    or      e                   ;         ORA  E
    jp      z, AHOW             ;         JZ   AHOW                       ;SAY "HOW?"
    push    bc                  ;         PUSH B                          ;ELSE SAVE SIGN
    call    DIVIDE              ;         CALL DIVIDE                     ;USE SUBROUTINE
    ld      h, b                ;         MOV  H,B                        ;RESULT IN HL NOW
    ld      l, c                ;         MOV  L,C
    pop     bc                  ;         POP  B                          ;GET SIGN BACK
XP35:
    pop     de                  ; XP35:   POP  D                          ;AND TEXT POINTER
    ld      a, h                ;         MOV  A,H                        ;HL MUST BE +
    or      a                   ;         ORA  A
    jp      m, QHOW             ;         JM   QHOW                       ;ELSE IT IS OVERFLOW
    ld      a, b                ;         MOV  A,B
    or      a                   ;         ORA  A
    call    m, CHGSGN           ;         CM   CHGSGN                     ;CHANGE SIGN IF NEEDED
    jp      XP31                ;         JMP  XP31                       ;LOOK FOR MORE TERMS
                                ; ;
EXPR4:
    ld      hl, #(TAB4 - 1)     ; EXPR4:  LXI  H,TAB4-1                   ;FIND FUNCTION IN TAB4
    jp      EXEC                ;         JMP  EXEC                       ;AND GO DO IT
XP40:
    call    RST7                ; XP40:   RST  7                          ;NO, NOT A FUNCTION
    jp      c, XP41             ;         JC   XP41                       ;NOR A VARIABLE
    ld      a, (hl)             ;         MOV  A,M                        ;VARIABLE
    inc     hl                  ;         INX  H
    ld      h, (hl)             ;         MOV  H,M                        ;VALUE IN HL
    ld      l, a                ;         MOV  L,A
    ret                         ;         RET
XP41:
    call    TSTNUM              ; XP41:   CALL TSTNUM                     ;OR IS IT A NUMBER
    ld      a, b                ;         MOV  A,B                        ;# OF DIGIT
    or      a                   ;         ORA  A
    ret     nz                  ;         RNZ                             ;OK
PARN:
    call    RST1                ; PARN:   RST  1
    .db     '('                 ;         DB   '('
    .db     XP43 - . - 1        ;         DB   XP43-$-1
    call    RST3                ;         RST  3                          ;"(EXPR)"
    call    RST1                ;         RST  1
    .db     ')'                 ;         DB   ')'
    .db     XP43 - . - 1        ;         DB   XP43-$-1
XP42:
    ret                         ; XP42:   RET
XP43:
    jp      QWHAT               ; XP43:   JMP  QWHAT                      ;ELSE SAY: "WHAT?"
                                ; ;
RND:
    call    PARN                ; RND:    CALL PARN                       ;*** RND(EXPR) ***
    ld      a, h                ;         MOV  A,H                        ;EXPR MUST BE +
    or      a                   ;         ORA  A
    jp      m, QHOW             ;         JM   QHOW
    or      l                   ;         ORA  L                          ;AND NON-ZERO
    jp      z, QHOW             ;         JZ   QHOW
    push    de                  ;         PUSH D                          ;SAVE BOTH
    push    hl                  ;         PUSH H
    ld      hl, (RANPNT)        ;         LHLD RANPNT                     ;GET MEMORY AS RANDOM
    ld      de, #LSTROM         ;         LXI  D,LSTROM                   ;NUMBER
    call    RST4                ;         RST  4
    jp      c, RA1              ;         JC   RA1                        ;WRAP AROUND IF LAST
    ld      hl, #START          ;         LXI  H,START
RA1:
    ld      e, (hl)             ; RA1:    MOV  E,M
    inc     hl                  ;         INX  H
    ld      d, (hl)             ;         MOV  D,M
    ld      (RANPNT), hl        ;         SHLD RANPNT
    pop     hl                  ;         POP  H
    ex      de, hl              ;         XCHG
    push    bc                  ;         PUSH B
    call    DIVIDE              ;         CALL DIVIDE                     ;RND(N)=MOD(M,N)+1
    pop     bc                  ;         POP  B
    pop     de                  ;         POP  D
    inc     hl                  ;         INX  H
    ret                         ;         RET
                                ; ;
ABS:
    call    PARN                ; ABS:    CALL PARN                       ;*** ABS(EXPR) ***
    call    CHKSGN              ;         CALL CHKSGN                     ;CHECK SIGN
    ld      a, h                ;         MOV  A,H                        ;NOTE THAT -32768
    or      h                   ;         ORA  H                          ;CANNOT CHANGE SIGN
    jp      m, QHOW             ;         JM   QHOW                       ;SO SAY: "HOW?"
    ret                         ;         RET
                                ; ;
SIZE:
    ld      hl, (TXTUNF)        ; SIZE:   LHLD TXTUNF                     ;*** SIZE ***
    push    de                  ;         PUSH D                          ;GET THE NUMBER OF FREE
    ex      de, hl              ;         XCHG                            ;BYTES BETWEEN 'TXTUNF'
    ld      hl, #VARBGN         ;         LXI  H,VARBGN                   ;AND 'VARBGN'
    call    SUBDE               ;         CALL SUBDE
    pop     de                  ;         POP  D
    ret                         ;         RET
                                ; ;
                                ; ;*************************************************************
                                ; ;*
                                ; ;* *** DIVIDE *** SUBDE *** CHKSGN *** CHGSGN *** & CKHLDE ***
                                ; ;*
                                ; ;* 'DIVIDE' DIVIDES HL BY DE, RESULT IN BC, REMAINDER IN HL
                                ; ;*
                                ; ;* 'SUBDE' SUBSTRACTS DE FROM HL
                                ; ;*
                                ; ;* 'CHKSGN' CHECKS SIGN OF HL.  IF +, NO CHANGE.  IF -, CHANGE
                                ; ;* SIGN AND FLIP SIGN OF B.
                                ; ;*
                                ; ;* 'CHGSGN' CHANGES SIGN OF HL AND B UNCONDITIONALLY.
                                ; ;*
                                ; ;* 'CKHLDE' CHECKS SIGN OF HL AND DE.  IF DIFFERENT, HL AND DE
                                ; ;* ARE INTERCHANGED.  IF SAME SIGN, NOT INTERCHANGED.  EITHER
                                ; ;* CASE, HL DE ARE THEN COMPARED TO SET THE FLAGS.
                                ; ;*
DIVIDE:
    push    hl                  ; DIVIDE: PUSH H                          ;*** DIVIDE ***
    ld      l, h                ;         MOV  L,H                        ;DIVIDE H BY DE
    ld      h, #0               ;         MVI  H,0
    call    DV1                 ;         CALL DV1
    ld      b, c                ;         MOV  B,C                        ;SAVE RESULT IN B
    ld      a, l                ;         MOV  A,L                        ;(REMINDER+L)/DE
    pop     hl                  ;         POP  H
    ld      h, a                ;         MOV  H,A
DV1:
    ld      c, #-1              ; DV1:    MVI  C,-1                       ;RESULT IN C
DV2:
    inc     c                   ; DV2:    INR  C                          ;DUMB ROUTINE
    call    SUBDE               ;         CALL SUBDE                      ;DIVIDE BY SUBTRACT
    jp      nc, DV2             ;         JNC  DV2                        ;AND COUNT
    add     hl, de              ;         DAD  D
    ret                         ;         RET
                                ; ;
SUBDE:
    ld      a, l                ; SUBDE:  MOV  A,L                        ;*** SUBDE ***
    sub     e                   ;         SUB  E                          ;SUBSTRACT DE FROM
    ld      l, a                ;         MOV  L,A                        ;HL
    ld      a, h                ;         MOV  A,H
    sbc     d                   ;         SBB  D
    ld      h, a                ;         MOV  H,A
    ret                         ;         RET
                                ; ;
CHKSGN:
    ld      a, h                ; CHKSGN: MOV  A,H                        ;*** CHKSGN ***
    or      a                   ;         ORA  A                          ;CHECK SIGN OF HL
    ret     p                   ;         RP                              ;IF -, CHANGE SIGN
                                ; ;
CHGSGN:
    ld      a, h                ; CHGSGN: MOV  A,H                        ;*** CHGSGN ***
    cpl                         ;         CMA                             ;CHANGE SIGN OF HL
    ld      h, a                ;         MOV  H,A
    ld      a, l                ;         MOV  A,L
    cpl                         ;         CMA
    ld      l, a                ;         MOV  L,A
    inc     hl                  ;         INX  H
    ld      a, b                ;         MOV  A,B                        ;AND ALSO FLIP B
    xor     #0x80               ;         XRI  80H
    ld      b, a                ;         MOV  B,A
    ret                         ;         RET
                                ; ;
CKHLDE:
    ld      a, h                ; CKHLDE: MOV  A,H
    xor     d                   ;         XRA  D                          ;SAME SIGN?
    jp      p, CK1              ;         JP   CK1                        ;YES, COMPARE
    ex      de, hl              ;         XCHG                            ;NO, XCH AND COMP
CK1:
    call    RST4                ; CK1:    RST  4
    ret                         ;         RET
                                ; ;
                                ; ;*************************************************************
                                ; ;*
                                ; ;* *** SETVAL *** FIN *** ENDCHK *** & ERROR (& FRIENDS) ***
                                ; ;*
                                ; ;* "SETVAL" EXPECTS A VARIABLE, FOLLOWED BY AN EQUAL SIGN AND
                                ; ;* THEN AN EXPR.  IT EVALUATES THE EXPR. AND SET THE VARIABLE
                                ; ;* TO THAT VALUE.
                                ; ;*
                                ; ;* "FIN" CHECKS THE END OF A COMMAND.  IF IT ENDED WITH ";",
                                ; ;* EXECUTION CONTINUES.  IF IT ENDED WITH A CR, IT FINDS THE
                                ; ;* NEXT LINE AND CONTINUE FROM THERE.
                                ; ;*
                                ; ;* "ENDCHK" CHECKS IF A COMMAND IS ENDED WITH CR.  THIS IS
                                ; ;* REQUIRED IN CERTAIN COMMANDS.  (GOTO, RETURN, AND STOP ETC.)
                                ; ;*
                                ; ;* "ERROR" PRINTS THE STRING POINTED BY DE (AND ENDS WITH CR).
                                ; ;* IT THEN PRINTS THE LINE POINTED BY 'CURRNT' WITH A "?"
                                ; ;* INSERTED AT WHERE THE OLD TEXT POINTER (SHOULD BE ON TOP
                                ; ;* OF THE STACK) POINTS TO.  EXECUTION OF TB IS STOPPED
                                ; ;* AND TBI IS RESTARTED.  HOWEVER, IF 'CURRNT' -> ZERO
                                ; ;* (INDICATING A DIRECT COMMAND), THE DIRECT COMMAND IS NOT
                                ; ;* PRINTED.  AND IF 'CURRNT' -> NEGATIVE # (INDICATING 'INPUT'
                                ; ;* COMMAND), THE INPUT LINE IS NOT PRINTED AND EXECUTION IS
                                ; ;* NOT TERMINATED BUT CONTINUED AT 'INPERR'.
                                ; ;*
                                ; ;* RELATED TO 'ERROR' ARE THE FOLLOWING:
                                ; ;* 'QWHAT' SAVES TEXT POINTER IN STACK AND GET MESSAGE "WHAT?"
                                ; ;* 'AWHAT' JUST GET MESSAGE "WHAT?" AND JUMP TO 'ERROR'.
                                ; ;* 'QSORRY' AND 'ASORRY' DO SAME KIND OF THING.
                                ; ;* 'QHOW' AND 'AHOW' IN THE ZERO PAGE SECTION ALSO DO THIS.
                                ; ;*
SETVAL:
    call    RST7                ; SETVAL: RST  7                          ;*** SETVAL ***
    jp      c, QWHAT            ;         JC   QWHAT                      ;"WHAT?" NO VARIABLE
    push    hl                  ;         PUSH H                          ;SAVE ADDRESS OF VAR.
    call    RST1                ;         RST  1                          ;PASS "=" SIGN
    .db     '='                 ;         DB   '='
    .db     SV1 - . - 1         ;         DB   SV1-$-1
    call    RST3                ;         RST  3                          ;EVALUATE EXPR.
    ld      b, h                ;         MOV  B,H                        ;VALUE IS IN BC NOW
    ld      c, l                ;         MOV  C,L
    pop     hl                  ;         POP  H                          ;GET ADDRESS
    ld      (hl), c             ;         MOV  M,C                        ;SAVE VALUE
    inc     hl                  ;         INX  H
    ld      (hl), b             ;         MOV  M,B
    ret                         ;         RET
SV1:
    jp      QWHAT               ; SV1:    JMP  QWHAT                      ;NO "=" SIGN
                                ; ;
FIN:
    call    RST1                ; FIN:    RST  1                          ;*** FIN ***
    .db     ';'                 ;         DB   ';'
    .db     FI1 - . - 1         ;         DB   FI1-$-1
    pop     af                  ;         POP  PSW                        ;";", PURGE RET. ADDR.
    jp      RUNSML              ;         JMP  RUNSML                     ;CONTINUE SAME LINE
FI1:
    call    RST1                ; FI1:    RST  1                          ;NOT ";", IS IT CR?
    .db     CR                  ;         DB   CR
    .db     FI2 - . - 1         ;         DB   FI2-$-1
    pop     af                  ;         POP  PSW                        ;YES, PURGE RET. ADDR.
    jp      RUNNXL              ;         JMP  RUNNXL                     ;RUN NEXT LINE
FI2:
    ret                         ; FI2:    RET                             ;ELSE RETURN TO CALLER
                                ; ;
ENDCHK:
    call    RST5                ; ENDCHK: RST  5                          ;*** ENDCHK ***
    cp      #CR                 ;         CPI  CR                         ;END WITH CR?
    ret     z                   ;         RZ                              ;OK, ELSE SAY: "WHAT?"
                                ; ;
QWHAT:
    push    de                  ; QWHAT:  PUSH D                          ;*** QWHAT ***
AWHAT:
    ld      de, #WHAT           ; AWHAT:  LXI  D,WHAT                     ;*** AWHAT ***
ERROR:
    sub     a                   ; ERROR:  SUB  A                          ;*** ERROR ***
    call    PRTSTG              ;         CALL PRTSTG                     ;PRINT 'WHAT?', 'HOW?'
    pop     de                  ;         POP  D                          ;OR 'SORRY'
    ld      a, (de)             ;         LDAX D                          ;SAVE THE CHARACTER
    push    af                  ;         PUSH PSW                        ;AT WHERE OLD DE ->
    sub     a                   ;         SUB  A                          ;AND PUT A 0 THERE
    ld      (de), a             ;         STAX D
    ld      hl, (CURRNT)        ;         LHLD CURRNT                     ;GET CURRENT LINE #
    push    hl                  ;         PUSH H
    ld      a, (hl)             ;         MOV  A,M                        ;CHECK THE VALUE
    inc     hl                  ;         INX  H
    or      (hl)                ;         ORA  M
    pop     de                  ;         POP  D
    jp      z, START            ;         JZ   START                      ;IF ZERO, JUST RESTART
    ld      a, (hl)             ;         MOV  A,M                        ;IF NEGATIVE,
    or      a                   ;         ORA  A
    jp      m, INPERR           ;         JM   INPERR                     ;REDO INPUT
    call    PRTLN               ;         CALL PRTLN                      ;ELSE PRINT THE LINE
    dec     de                  ;         DCX  D                          ;UPTO WHERE THE 0 IS
    pop     af                  ;         POP  PSW                        ;RESTORE THE CHARACTER
    ld      (de), a             ;         STAX D
    ld      a, #'?'             ;         MVI  A,'?'                      ;PRINT A "?"
    call    RST2                ;         RST  2
    sub     a                   ;         SUB  A                          ;AND THE REST OF THE
    call    PRTSTG              ;         CALL PRTSTG                     ;LINE
    call    RST0                ;         RST  0                          ;THEN RESTART
                                ; ;
QSORRY:
    push    de                  ; QSORRY: PUSH D                          ;*** QSORRY ***
ASORRY:
    ld      de, #SORRY          ; ASORRY: LXI  D,SORRY                    ;*** ASORRY ***
    jp      ERROR               ;         JMP  ERROR
                                ; ;
                                ; ;*************************************************************
                                ; ;*
                                ; ;* *** GETLN *** FNDLN (& FRIENDS) ***
                                ; ;*
                                ; ;* 'GETLN' READS A INPUT LINE INTO 'BUFFER'.  IT FIRST PROMPT
                                ; ;* THE CHARACTER IN A (GIVEN BY THE CALLER), THEN IT FILLS
                                ; ;* THE BUFFER AND ECHOS.  IT IGNORES LF'S AND NULLS, BUT STILL
                                ; ;* ECHOS THEM BACK.  RUB-OUT IS USED TO CAUSE IT TO DELETE
                                ; ;* THE LAST CHARACTER (IF THERE IS ONE), AND ALT-MOD IS USED TO
                                ; ;* CAUSE IT TO DELETE THE WHOLE LINE AND START IT ALL OVER.
                                ; ;* CR SIGNALS THE END OF A LINE, AND CAUSE 'GETLN' TO RETURN.
                                ; ;*
                                ; ;* 'FNDLN' FINDS A LINE WITH A GIVEN LINE # (IN HL) IN THE
                                ; ;* TEXT SAVE AREA.  DE IS USED AS THE TEXT POINTER.  IF THE
                                ; ;* LINE IS FOUND, DE WILL POINT TO THE BEGINNING OF THAT LINE
                                ; ;* (I.E., THE LOW BYTE OF THE LINE #), AND FLAGS ARE NC & Z.
                                ; ;* IF THAT LINE IS NOT THERE AND A LINE WITH A HIGHER LINE #
                                ; ;* IS FOUND, DE POINTS TO THERE AND FLAGS ARE NC & NZ.  IF
                                ; ;* WE REACHED THE END OF TEXT SAVE AREA AND CANNOT FIND THE
                                ; ;* LINE, FLAGS ARE C & NZ.
                                ; ;* 'FNDLN' WILL INITIALIZE DE TO THE BEGINNING OF THE TEXT SAVE
                                ; ;* AREA TO START THE SEARCH.  SOME OTHER ENTRIES OF THIS
                                ; ;* ROUTINE WILL NOT INITIALIZE DE AND DO THE SEARCH.
                                ; ;* 'FDLNP' WILL START WITH DE AND SEARCH FOR THE LINE #.
                                ; ;* 'FNDNXT' WILL BUMP DE BY 2, FIND A CR AND THEN START SEARCH.
                                ; ;* 'FNDSKP' USE DE TO FIND A CR, AND THEN START SEARCH.
                                ; ;*
GETLN:
    call    RST2                ; GETLN:  RST  2                          ;*** GETLN ***
    ld      de, #BUFFER         ;         LXI  D,BUFFER                   ;PROMPT AND INIT.
GL1:
    call    CHKIO               ; GL1:    CALL CHKIO                      ;CHECK KEYBOARD
    jp      z, GL1              ;         JZ   GL1                        ;NO INPUT, WAIT
    call    RST2                ;         RST  2                          ;INPUT, ECHO BACK
    cp      #LF                 ;         CPI  LF                         ;IGNORE LF
    jp      z, GL1              ;         JZ   GL1
    or      a                   ;         ORA  A                          ;IGNORE NULL
    jp      z, GL1              ;         JZ   GL1
    cp      #DEL                ;         CPI  DEL                        ;DELETE LAST CHARACTER?
    jp      z, GL3              ;         JZ   GL3                        ;YES
                                ; ;       CPI  DLLN                       ;DELETE THE WHOLE LINE?
    cp      #CNTLU              ;         CPI  CNTLU
    jp      z, GL4              ;         JZ   GL4                        ;YES
    ld      (de), a             ;         STAX D                          ;ELSE SAVE INPUT
    inc     de                  ;         INX  D                          ;AND BUMP POINTER
    cp      #CR                 ;         CPI  CR                         ;WAS IT CR?
    ret     z                   ;         RZ                              ;YES, END OF LINE
    ld      a, e                ;         MOV  A,E                        ;ELSE MORE FREE ROOM?
    cp      #<BUFEND            ;         CPI  BUFEND AND 0FFH
    jp      nz, GL1             ;         JNZ  GL1                        ;YES, GET NEXT INPUT
GL3:
    ld      a, e                ; GL3:    MOV  A,E                        ;DELETE LAST CHARACTER
    cp      #<BUFFER            ;         CPI  BUFFER AND 0FFH            ;BUT DO WE HAVE ANY?
    jp      z, GL4              ;         JZ   GL4                        ;NO, REDO WHOLE LINE
    dec     de                  ;         DCX  D                          ;YES, BACKUP POINTER
    ld      a, #BKS             ;         MVI  A,BKS                      ;AND ECHO A BACK-SLASH
    call    RST2                ;         RST  2
    jp      GL1                 ;         JMP  GL1                        ;GO GET NEXT INPUT
GL4:
    call    CRLF                ; GL4:    CALL CRLF                       ;REDO ENTIRE LINE
    ld      a, #UPA             ;         MVI  A,UPA                      ;CR, LF AND UP-ARROW
    jp      GETLN               ;         JMP  GETLN
                                ; ;
FNDLN:
    ld      a, h                ; FNDLN:  MOV  A,H                        ;*** FNDLN ***
    or      a                   ;         ORA  A                          ;CHECK SIGN OF HL
    jp      m, QHOW             ;         JM   QHOW                       ;IT CANNOT BE -
    ld      de, #TXTBGN         ;         LXI  D,TXTBGN                   ;INIT TEXT POINTER
                                ; ;
FDLNP:                          ; FDLNP   EQU  $                          ;*** FDLNP ***
FL1:
    push    hl                  ; FL1:    PUSH H                          ;SAVE LINE #
    ld      hl, (TXTUNF)        ;         LHLD TXTUNF                     ;CHECK IF WE PASSED END
    dec     hl                  ;         DCX  H
    call    RST4                ;         RST  4
    pop     hl                  ;         POP  H                          ;GET LINE # BACK
    ret     c                   ;         RC                              ;C,NZ PASSED END
    ld      a, (de)             ;         LDAX D                          ;WE DID NOT, GET BYTE 1
    sub     l                   ;         SUB  L                          ;IS THIS THE LINE?
    ld      b, a                ;         MOV  B,A                        ;COMPARE LOW ORDER
    inc     de                  ;         INX  D
    ld      a, (de)             ;         LDAX D                          ;GET BYTE 2
    sbc     h                   ;         SBB  H                          ;COMPARE HIGH ORDER
    jp      c, FL2              ;         JC   FL2                        ;NO, NOT THERE YET
    dec     de                  ;         DCX  D                          ;ELSE WE EITHER FOUND
    or      b                   ;         ORA  B                          ;IT, OR IT IS NOT THERE
    ret                         ;         RET                             ;NC,Z:FOUND, NC,NZ:NO
                                ; ;
FNDNXT:                         ; FNDNXT  EQU  $                          ;*** FNDNXT ***
    inc     de                  ;         INX  D                          ;FIND NEXT LINE
FL2:
    inc     de                  ; FL2:    INX  D                          ;JUST PASSED BYTE 1 & 2
                                ; ;
FNDSKP:
    ld      a, (de)             ; FNDSKP: LDAX D                          ;*** FNDSKP ***
    cp      #CR                 ;         CPI  CR                         ;TRY TO FIND CR
    jp      nz, FL2             ;         JNZ  FL2                        ;KEEP LOOKING
    inc     de                  ;         INX  D                          ;FOUND CR, SKIP OVER
    jp      FL1                 ;         JMP  FL1                        ;CHECK IF END OF TEXT
                                ; ;
                                ; ;*************************************************************
                                ; ;*
                                ; ;* *** PRTSTG *** QTSTG *** PRTNUM *** & PRTLN ***
                                ; ;*
                                ; ;* 'PRTSTG' PRINTS A STRING POINTED BY DE.  IT STOPS PRINTING
                                ; ;* AND RETURNS TO CALLER WHEN EITHER A CR IS PRINTED OR WHEN
                                ; ;* THE NEXT BYTE IS THE SAME AS WHAT WAS IN A (GIVEN BY THE
                                ; ;* CALLER).  OLD A IS STORED IN B, OLD B IS LOST.
                                ; ;*
                                ; ;* 'QTSTG' LOOKS FOR A BACK-ARROW, SINGLE QUOTE, OR DOUBLE
                                ; ;* QUOTE.  IF NONE OF THESE, RETURN TO CALLER.  IF BACK-ARROW,
                                ; ;* OUTPUT A CR WITHOUT A LF.  IF SINGLE OR DOUBLE QUOTE, PRINT
                                ; ;* THE STRING IN THE QUOTE AND DEMANDS A MATCHING UNQUOTE.
                                ; ;* AFTER THE PRINTING THE NEXT 3 BYTES OF THE CALLER IS SKIPPED
                                ; ;* OVER (USUALLY A JUMP INSTRUCTION.
                                ; ;*
                                ; ;* 'PRTNUM' PRINTS THE NUMBER IN HL.  LEADING BLANKS ARE ADDED
                                ; ;* IF NEEDED TO PAD THE NUMBER OF SPACES TO THE NUMBER IN C.
                                ; ;* HOWEVER, IF THE NUMBER OF DIGITS IS LARGER THAN THE # IN
                                ; ;* C, ALL DIGITS ARE PRINTED ANYWAY.  NEGATIVE SIGN IS ALSO
                                ; ;* PRINTED AND COUNTED IN, POSITIVE SIGN IS NOT.
                                ; ;*
                                ; ;* 'PRTLN' PRINTS A SAVED TEXT LINE WITH LINE # AND ALL.
                                ; ;*
PRTSTG:
    ld      b, a                ; PRTSTG: MOV  B,A                        ;*** PRTSTG ***
PS1:
    ld      a, (de)             ; PS1:    LDAX D                          ;GET A CHARACTER
    inc     de                  ;         INX  D                          ;BUMP POINTER
    cp      b                   ;         CMP  B                          ;SAME AS OLD A?
    ret     z                   ;         RZ                              ;YES, RETURN
    call    RST2                ;         RST  2                          ;ELSE PRINT IT
    cp      #CR                 ;         CPI  CR                         ;WAS IT A CR?
    jp      nz, PS1             ;         JNZ  PS1                        ;NO, NEXT
    ret                         ;         RET                             ;YES, RETURN
                                ; ;
QTSTG:
    call    RST1                ; QTSTG:  RST  1                          ;*** QTSTG ***
    .db     '"'                 ;         DB   '"'
    .db     QT3 - . - 1         ;         DB   QT3-$-1
    ld      a, #'"'             ;         MVI  A,'"'                      ;IT IS A "
QT1:
    call    PRTSTG              ; QT1:    CALL PRTSTG                     ;PRINT UNTIL ANOTHER
    cp      #CR                 ;         CPI  CR                         ;WAS LAST ONE A CR?
    pop     hl                  ;         POP  H                          ;RETURN ADDRESS
    jp      z, RUNNXL           ;         JZ   RUNNXL                     ;WAS CR, RUN NEXT LINE
QT2:
    inc     hl                  ; QT2:    INX  H                          ;SKIP 3 BYTES ON RETURN
    inc     hl                  ;         INX  H
    inc     hl                  ;         INX  H
    jp      (hl)                ;         PCHL                            ;RETURN
QT3:
    call    RST1                ; QT3:    RST  1                          ;IS IT A '?
    .db     QT                  ;         DB   QT
    .db     QT4 - . - 1         ;         DB   QT4-$-1
    ld      a, #QT              ;         MVI  A,QT                       ;YES, DO THE SAME
    jp      QT1                 ;         JMP  QT1                        ;AS IN "
QT4:
    call    RST1                ; QT4:    RST  1                          ;IS IT BACK-ARROW?
    .db     BKA                 ;         DB   BKA
    .db     QT5 - . - 1         ;         DB   QT5-$-1
    ld      a, #0x8d            ;         MVI  A,8DH                      ;YES, CR WITHOUT LF
    call    RST2                ;         RST  2                          ;DO IT TWICE TO GIVE
    call    RST2                ;         RST  2                          ;TTY ENOUGH TIME
    pop     hl                  ;         POP  H                          ;RETURN ADDRESS
    jp      QT                  ;         JMP  QT2
QT5:
    ret                         ; QT5:    RET                             ;NONE OF ABOVE
                                ; ;
PRTNUM:
    push    de                  ; PRTNUM: PUSH D                          ;*** PRTNUM ***
    ld      de, #10             ;         LXI  D,10                       ;DECIMAL
    push    de                  ;         PUSH D                          ;SAVE AS A FLAG
    ld      b, d                ;         MOV  B,D                        ;B=SIGN
    dec     c                   ;         DCR  C                          ;C=SPACES
    call    CHKSGN              ;         CALL CHKSGN                     ;CHECK SIGN
    jp      p, PN1              ;         JP   PN1                        ;NO SIGN
    ld      b, #'-'             ;         MVI  B,'-'                      ;B=SIGN
    dec     c                   ;         DCR  C                          ;'-' TAKES SPACE
PN1:
    push    bc                  ; PN1:    PUSH B                          ;SAVE SIGN & SPACE
PN2:
    call    DIVIDE              ; PN2:    CALL DIVIDE                     ;DIVIDE HL BY 10
    ld      a, b                ;         MOV  A,B                        ;RESULT 0?
    or      c                   ;         ORA  C
    jp      z, PN3              ;         JZ   PN3                        ;YES, WE GOT ALL
    ex      (sp), hl            ;         XTHL                            ;NO, SAVE REMAINDER
    dec     l                   ;         DCR  L                          ;AND COUNT SPACE
    push    hl                  ;         PUSH H                          ;HL IS OLD BC
    ld      h, b                ;         MOV  H,B                        ;MOVE RESULT TO BC
    ld      l, c                ;         MOV  L,C
    jp      PN2                 ;         JMP  PN2                        ;AND DIVIDE BY 10
PN3:
    pop     bc                  ; PN3:    POP  B                          ;WE GOT ALL DIGITS IN
PN4:
    dec     c                   ; PN4:    DCR  C                          ;THE STACK
    ld      a, c                ;         MOV  A,C                        ;LOOK AT SPACE COUNT
    or      a                   ;         ORA  A
    jp      m, PN5              ;         JM   PN5                        ;NO LEADING BLANKS
    ld      a, #' '             ;         MVI  A,' '                      ;LEADING BLANKS
    call    RST2                ;         RST  2
    jp      PN4                 ;         JMP  PN4                        ;MORE?
PN5:
    ld      a, b                ; PN5:    MOV  A,B                        ;PRINT SIGN
    call    RST2                ;         RST  2                          ;MAYBE - OR NULL
    ld      e, l                ;         MOV  E,L                        ;LAST REMAINDER IN E
PN6:
    ld      a, e                ; PN6:    MOV  A,E                        ;CHECK DIGIT IN E
    cp      #10                 ;         CPI  10                         ;10 IS FLAG FOR NO MORE
    pop     de                  ;         POP  D
    ret     z                   ;         RZ                              ;IF SO, RETURN
    add     a, #'0'             ;         ADI  '0'                        ;ELSE CONVERT TO ASCII
    call    RST2                ;         RST  2                          ;AND PRINT THE DIGIT
    jp      PN6                 ;         JMP  PN6                        ;GO BACK FOR MORE
                                ; ;
PRTLN:
    ld      a, (de)             ; PRTLN:  LDAX D                          ;*** PRTLN ***
    ld      l, a                ;         MOV  L,A                        ;LOW ORDER LINE #
    inc     de                  ;         INX  D
    ld      a, (de)             ;         LDAX D                          ;HIGH ORDER
    ld      h, a                ;         MOV  H,A
    inc     de                  ;         INX  D
    ld      c, #4               ;         MVI  C,4                        ;PRINT 4 DIGIT LINE #
    call    PRTNUM              ;         CALL PRTNUM
    ld      a, #' '             ;         MVI  A,' '                      ;FOLLOWED BY A BLANK
    call    RST2                ;         RST  2
    sub     a                   ;         SUB  A                          ;AND THEN THE NEXT
    call    PRTSTG              ;         CALL PRTSTG
    ret                         ;         RET
                                ; ;
                                ; ;*************************************************************
                                ; ;*
                                ; ;* *** MVUP *** MVDOWN *** POPA *** & PUSHA ***
                                ; ;*
                                ; ;* 'MVUP' MOVES A BLOCK UP FROM WHERE DE-> TO WHERE BC-> UNTIL
                                ; ;* DE = HL
                                ; ;*
                                ; ;* 'MVDOWN' MOVES A BLOCK DOWN FROM WHERE DE-> TO WHERE HL->
                                ; ;* UNTIL DE = BC
                                ; ;*
                                ; ;* 'POPA' RESTORES THE 'FOR' LOOP VARIABLE SAVE AREA FROM THE
                                ; ;* STACK
                                ; ;*
                                ; ;* 'PUSHA' STACKS THE 'FOR' LOOP VARIABLE SAVE AREA INTO THE
                                ; ;* STACK
                                ; ;*
MVUP:
    call    RST4                ; MVUP:   RST  4                          ;*** MVUP ***
    ret     z                   ;         RZ                              ;DE = HL, RETURN
    ld      a, (de)             ;         LDAX D                          ;GET ONE BYTE
    ld      (bc), a             ;         STAX B                          ;MOVE IT
    inc     de                  ;         INX  D                          ;INCREASE BOTH POINTERS
    inc     bc                  ;         INX  B
    jp      MVUP                ;         JMP  MVUP                       ;UNTIL DONE
                                ; ;
MVDOWN:
    ld      a, b                ; MVDOWN: MOV  A,B                        ;*** MVDOWN ***
    sub     d                   ;         SUB  D                          ;TEST IF DE = BC
    jp      nz, MD1             ;         JNZ  MD1                        ;NO, GO MOVE
    ld      a, c                ;         MOV  A,C                        ;MAYBE, OTHER BYTE?
    sub     e                   ;         SUB  E
    ret     z                   ;         RZ                              ;YES, RETURN
MD1:
    dec     de                  ; MD1:    DCX  D                          ;ELSE MOVE A BYTE
    dec     hl                  ;         DCX  H                          ;BUT FIRST DECREASE
    ld      a, (de)             ;         LDAX D                          ;BOTH POINTERS AND
    ld      (hl), a             ;         MOV  M,A                        ;THEN DO IT
    jp      MVDOWN              ;         JMP  MVDOWN                     ;LOOP BACK
                                ; ;
POPA:
    pop     bc                  ; POPA:   POP  B                          ;BC = RETURN ADDR.
    pop     hl                  ;         POP  H                          ;RESTORE LOPVAR, BUT
    ld      (LOPVAR), hl        ;         SHLD LOPVAR                     ;=0 MEANS NO MORE
    ld      a, h                ;         MOV  A,H
    or      l                   ;         ORA  L
    jp      z, PP1              ;         JZ   PP1                        ;YEP, GO RETURN
    pop     hl                  ;         POP  H                          ;NOP, RESTORE OTHERS
    ld      (LOPINC), hl        ;         SHLD LOPINC
    pop     hl                  ;         POP  H
    ld      (LOPLMT), hl        ;         SHLD LOPLMT
    pop     hl                  ;         POP  H
    ld      (LOPLN), hl         ;         SHLD LOPLN
    pop     hl                  ;         POP  H
    ld      (LOPPT), hl         ;         SHLD LOPPT
PP1:
    push    bc                  ; PP1:    PUSH B                          ;BC = RETURN ADDR.
    ret                         ;         RET
                                ; ;
PUSHA:
    ld      hl, #_stack         ; PUSHA:  LXI  H,STKLMT                   ;*** PUSHA ***
    call    CHGSGN              ;         CALL CHGSGN
    pop     bc                  ;         POP  B                          ;BC=RETURN ADDRESS
    add     hl, sp              ;         DAD  SP                         ;IS STACK NEAR THE TOP?
    jp      nc, QSORRY          ;         JNC  QSORRY                     ;YES, SORRY FOR THAT
    ld      hl, (LOPVAR)        ;         LHLD LOPVAR                     ;ELSE SAVE LOOP VAR'S
    ld      a, h                ;         MOV  A,H                        ;BUT IF LOPVAR IS 0
    or      l                   ;         ORA  L                          ;THAT WILL BE ALL
    jp      z, PU1              ;         JZ   PU1
    ld      hl, (LOPPT)         ;         LHLD LOPPT                      ;ELSE, MORE TO SAVE
    push    hl                  ;         PUSH H
    ld      hl, (LOPLN)         ;         LHLD LOPLN
    push    hl                  ;         PUSH H
    ld      hl, (LOPLMT)        ;         LHLD LOPLMT
    push    hl                  ;         PUSH H
    ld      hl, (LOPINC)        ;         LHLD LOPINC
    push    hl                  ;         PUSH H
    ld      hl, (LOPVAR)        ;         LHLD LOPVAR
PU1:
    push    hl                  ; PU1:    PUSH H
    push    bc                  ;         PUSH B                          ;BC = RETURN ADDR.
    ret                         ;         RET
                                ; ;
                                ; ;*************************************************************
                                ; ;*
                                ; ;* *** OUTC *** & CHKIO ***
                                ; ;*
                                ; ;* THESE ARE THE ONLY I/O ROUTINES IN TBI.
                                ; ;* 'OUTC' IS CONTROLLED BY A SOFTWARE SWITCH 'OCSW'.  IF OCSW=0
                                ; ;* 'OUTC' WILL JUST RETURN TO THE CALLER.  IF OCSW IS NOT 0,
                                ; ;* IT WILL OUTPUT THE BYTE IN A.  IF THAT IS A CR, A LF IS ALSO
                                ; ;* SEND OUT.  ONLY THE FLAGS MAY BE CHANGED AT RETURN. ALL REG.
                                ; ;* ARE RESTORED.
                                ; ;*
                                ; ;* 'CHKIO' CHECKS THE INPUT.  IF NO INPUT, IT WILL RETURN TO
                                ; ;* THE CALLER WITH THE Z FLAG SET.  IF THERE IS INPUT, Z FLAG
                                ; ;* IS CLEARED AND THE INPUT BYTE IS IN A.  HOWEVER, IF THE
                                ; ;* INPUT IS A CONTROL-O, THE 'OCSW' SWITCH IS COMPLIMENTED, AND
                                ; ;* Z FLAG IS RETURNED.  IF A CONTROL-C IS READ, 'CHKIO' WILL
                                ; ;* RESTART TBI AND DO NOT RETURN TO THE CALLER.
                                ; ;*
                                ; ;OUTC:  PUSH PSW                        ;THIS IS AT LOC. 10
                                ; ;       LDA  OCSW                       ;CHECK SOFTWARE SWITCH
                                ; ;       ORA  A
OC2:
    jp      nz, OC3             ; OC2:    JNZ  OC3                        ;IT IS ON
    pop     af                  ;         POP  PSW                        ;IT IS OFF
    ret                         ;         RET                             ;RESTORE AF AND RETURN
OC3:

;; ↓ MSX ROUTINE

    ; 文字コードの判定
    pop     af
    push    hl
    push    bc
    push    de

    ; 改行コード
    cp      #CR
    jr      z, OC30

    ; 無効な文字
    cp      #' '
    jr      c, OC39
    cp      #DEL
    jr      z, OC39

    ; 文字出力
    ld      hl, (CURSOR)
    ld      (hl), a
    inc     hl
    ld      de, #(_patternName + 40 * 24)
    or      a
    sbc     hl, de
    jr      nc, OC30
    add     hl, de
    jr      OC38

    ; 改行
OC30:
    ld      hl, #(_patternName + 40)
    ld      de, #(_patternName +  0)
    ld      bc, #(40 * 24 - 40)
    ldir
    ld      hl, #(_patternName + 40 * 24 - 40 + 0)
    ld      de, #(_patternName + 40 * 24 - 40 + 1)
    ld      bc, #(40 - 1)
    ld      (hl), #' '
    ldir
    ld      hl, #(_patternName + 40 * 24 - 40)
;   jr      OC38

    ; カーソル位置の更新
OC38:
    ld      (CURSOR), hl
OC39:
    pop     de
    pop     bc
    pop     hl
    ret

;; ↑ MSX ROUTINE

;   in      a, (0)              ; OC3:    IN   0                          ;COME HERE TO DO OUTPUT
;   and     #0x02               ;         ANI  02H                        ;STATUS BIT
;   jp      z, OC3              ;         JZ   OC3                        ;NOT READY, WAIT
;   pop     af                  ;         POP  PSW                        ;READY, GET OLD A BACK
;   out     (1), a              ;         OUT  1                          ;AND SEND IT OUT
;   cp      #CR                 ;         CPI  CR                         ;WAS IT CR?
;   ret     nz                  ;         RNZ                             ;NO, FINISHED
;   ld      a, #LF              ;         MVI  A,LF                       ;YES, WE SEND LF TOO
;   call    RST2                ;         RST  2                          ;THIS IS RECURSIVE
;   ld      a, #CR              ;         MVI  A,CR                       ;GET CR BACK IN A
;   ret                         ;         RET
                                ; ;
CHKIO:

;; ↓ MSX ROUTINE

    ; キー入力
    push    hl
    push    de
    call    CHSNS
    jr      z, CI09
    call    CHGET
    ld      e, a

    ; 文字コード変換
    ld      d, #0x00
    ld      hl, #CICODE
    add     hl, de
    ld      a, (hl)
    cp      #CNTLC
    call    z, RST0
    or      a
CI09:
    pop     de
    pop     hl
    ret

; キーコードテーブル
CICODE:
    .db     0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x7f, 0x00, 0x0d, 0x00, 0x00, 0x0d, 0x00, 0x00
    .db     0x00, 0x00, 0x00, 0x00, 0x00, 0x15, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    .db     0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f
    .db     0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f
    .db     0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f
    .db     0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f
    .db     0x60, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f
    .db     0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f
    .db     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    .db     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    .db     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    .db     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    .db     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    .db     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    .db     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    .db     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

;; ↑ MSX ROUTINE

;   in      a, (0)              ; CHKIO:  IN   0                          ;*** CHKIO ***
;   nop                         ;         NOP                             ;STATUS BIT FLIPPED?
;   and     #0x20               ;         ANI  20H                        ;MASK STATUS BIT
;   ret     z                   ;         RZ                              ;NOT READY, RETURN "Z"
;   in      a, (1)              ;         IN   1                          ;READY, READ DATA
;   and     #0x7f               ;         ANI  7FH                        ;MASK BIT 7 OFF
;   cp      #CNTLO              ;         CPI  CNTLO                      ;IS IT CONTROL-O?
;   jp      nz, CI1             ;         JNZ  CI1                        ;NO, MORE CHECKING
;   ld      a, (OCSW)           ;         LDA  OCSW                       ;CONTROL-O FLIPS OCSW
;   cpl                         ;         CMA                             ;ON TO OFF, OFF TO ON
;   ld      (OCSW), a           ;         STA  OCSW
;   jp      CHKIO               ;         JMP  CHKIO                      ;GET ANOTHER INPUT
;CI1:
;   cp      #CNTLC              ; CI1:    CPI  CNTLC                      ;IS IT CONTROL-C?
;   ret     nz                  ;         RNZ                             ;NO, RETURN "NZ"
;   call    RST0                ;         RST  0                          ;YES, RESTART TBI
                                ; ;
    .ascii  "YOU MAY NEED THIS SPACE TO"
                                ;         DB   'YOU MAY NEED THIS SPACE TO'
    .ascii  "PATCH UP THE I/O ROUTINES,"
                                ;         DB   'PATCH UP THE I/O ROUTINES,'
    .ascii  "TO FIX UP BUGS, OR TO ADD"
                                ;         DB   'TO FIX UP BUGS, OR TO ADD'
    .ascii  "MORE COMMANDS AND FUNCTIONS."
                                ;         DB   'MORE COMMANDS AND FUNCTIONS.'
    .ascii  "SKY (SPACE) IS THE LIMIT."
                                ;         DB   'SKY (SPACE) IS THE LIMIT.'
    .ascii  "GOOD LUCK AND GOOD BYE."
                                ;         DB   'GOOD LUCK AND GOOD BYE.'
    .ascii  "LICHEN WANG, 10 JUNE 76"
                                ;         DB   'LICHEN WANG, 10 JUNE 76'
                                ; ;
LSTROM:                         ; LSTROM  EQU  $                          ;ALL ABOVE CAN BE ROM


; DATA 領域
;
    .area   _DATA

                                ;         ORG  0800H                      ;HERE DOWN MUST BE RAM
OCSW:
    .ds     1                   ; OCSW:   DB   0FFH                       ;SWITCH FOR OUTPUT
CURRNT:
    .ds     2                   ; CURRNT: DW   0                          ;POINTS TO CURRENT LINE
STKGOS:
    .ds     2                   ; STKGOS: DW   0                          ;SAVES SP IN 'GOSUB'
VARNXT:                         ; VARNXT  EQU  $                          ;TEMP STORAGE
STKINP:
    .ds     2                   ; STKINP: DW   0                          ;SAVES SP IN 'INPUT'
LOPVAR:
    .ds     2                   ; LOPVAR: DW   0                          ;'FOR' LOOP SAVE AREA
LOPINC:
    .ds     2                   ; LOPINC: DW   0                          ;INCREMENT
LOPLMT:
    .ds     2                   ; LOPLMT: DW   0                          ;LIMIT
LOPLN:
    .ds     2                   ; LOPLN:  DW   0                          ;LINE NUMBER
LOPPT:
    .ds     2                   ; LOPPT:  DW   0                          ;TEXT POINTER
RANPNT:
    .ds     2                   ; RANPNT: DW   START                      ;RANDOM NUMBER POINTER
TXTUNF:
    .ds     2                   ; TXTUNF: DW   TXTBGN                     ;->UNFILLED TEXT AREA
TXTBGN:
    .ds     1                   ; TXTBGN: DS   1                          ;TEXT SAVE AREA BEGINS
                                ;         ORG  1F00H
    .ds     0x5000
TXTEND:                         ; TXTEND  EQU  $                          ;TEXT SAVE AREA ENDS
VARBGN:
    .ds     2 * 27              ; VARBGN: DS   2*27                       ;VARIABLE @(0)
    .ds     1                   ;         DS   1                          ;EXTRA BYTE FOR BUFFER
BUFFER:
    .ds     72                  ; BUFFER: DS   72                         ;INPUT BUFFER
BUFEND:                         ; BUFEND  EQU  $                          ;BUFFER ENDS
    .ds     40                  ;         DS   40                         ;EXTRA BYTES FOR STACK
STKLMT:                         ; STKLMT  EQU  $                          ;TOP LIMIT FOR STACK
                                ;         ORG  2000H
STACK:                          ; STACK   EQU  $                          ;STACK STARTS HERE
                                ; 
                                ;         END

;; ↓ MSX ROUTINE

; スタックポインタ
STACKPOINTER:
    .ds     2

; カーソル位置
CURSOR:
    .ds     2

;; ↑ MSX ROUTINE
