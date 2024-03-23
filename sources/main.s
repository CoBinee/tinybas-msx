; main.s : メインプログラム
;


; モジュール宣言
;
    .module main

; 参照ファイル
;
    .include    "main.inc"
    .include    "bios.inc"
    .include    "System.inc"
    .include    "App.inc"

; マクロの定義
;


; CODE 領域
;
    .area   _CODE

; メインプログラム
;
_main::
    
    ; 初期化
    
    ; システムの起動
    call    _SystemBoot
    
    ; システムの初期化
    call    _SystemInitialize
    
    ; アプリケーションの初期化
    call    _AppInitialize
    
    ; 割り込みの禁止
    di
    
    ; タイマ割り込み処理の保存
    ld      hl, #H.TIMI
    ld      de, #h.timiRoutine
    ld      bc, #0x05
    ldir
    
    ; タイマ割り込み処理の書き換え
    ld      a, #0xc3
    ld      (H.TIMI + 0), a
    ld      hl, #H.timiEntry
    ld      (H.TIMI + 1), hl
    
    ; タイマ割り込みカウンタの初期化
    xor     a
    ld      (h.timiCount), a

    ; タイマ割り込み処理の要求
    ld      hl, #_flag
    set     #FLAG_H_TIMI_REQUEST_BIT, (hl)
    
    ; 割り込み禁止の解除
    ei
    
    ; メインループ
;10$:
;   nop
;   ld      a, (h.timiCount)
;   cp      #H_TIMI_COUNT
;   jr      c, 10$
;   ld      hl, #_flag
;   bit     #FLAG_H_TIMI_REQUEST_BIT, (hl)
;   jr      nz, 10$
;   call    _AppUpdate
;   xor     a
;   ld      (h.timiCount), a
;   ld      hl, #_flag
;   set     #FLAG_H_TIMI_REQUEST_BIT, (hl)
;   jr      10$
    jp      _AppUpdate
    
;   ; 終了
;  
;   ; アプリケーションの終了
;  
;   ; システムの終了
;   ; キーボードバッファのクリア
;   call    KILBUF
;  
;   ; 割り込みの禁止
;   di
;  
;   ; タイマ割り込み処理の復帰
;   ld      hl, #h.timiRoutine
;   ld      de, #H.TIMI
;   ld      bc, #0x05
;   ldir
;
;   ; 割り込み禁止の解除
;   ei
;
;   ; 終了
;   ret

; タイマ割り込みのエントリ
;
H.timiEntry:

    ; 割り込み禁止の解除
    ei
    
    ; レジスタの保存
    push    af
    push    hl
    push    bc
    push    de
    push    ix
    push    iy
    
;   ; 割り込み処理の開始
;   ld      hl, #_flag
;   bit     #FLAG_H_TIMI_REQUEST_BIT, (hl)
;   jr      z, 19$
;   res     #FLAG_H_TIMI_REQUEST_BIT, (hl)
    ld      a, (h.timiCount)
    cp      #H_TIMI_COUNT
    jr      c, 19$

    ; 割り込みの禁止
    di

    ; ビデオポートの取得
    call    _SystemGetVideoPort
    
    ; ビデオの更新
    call    _SystemUpdateVideo

    ; スプライトの更新
    call    _SystemUpdateSprite

;   ; パターンネームの更新
;   call    _SystemUpdatePatternName

    ; 転送処理
    ld      hl, #10$
    push    hl
    ld      hl, (_transfer)
    jp      (hl)
10$:

    ; キー入力の更新
    call    _SystemUpdateInput

    ; 割り込みカウンタのクリア
    xor     a
    ld      (h.timiCount), a

    ; 割り込み禁止の解除
    ei
    
    ; 割り込み処理の完了
19$:
    
    ; サウンド処理の開始
    ld      hl, #_flag
    bit     #FLAG_SOUND_UPDATE_BIT, (hl)
    jr      nz, 29$
    set     #FLAG_SOUND_UPDATE_BIT, (hl)

    ; 割り込みの禁止
    di

    ; サウンドの更新
    call    _SystemUpdateSound

;   ; 負荷の確認
;   call    _SystemGetVideoPort
;   ld      a, (_videoPort + 1)
;   inc     a
;   ld      c, a
;   ld      a, #0x00
;   out     (c), a
;   ld      a, #0x87
;   out     (c), a

    ; 割り込み禁止の解除
    ei

    ; サウンド処理の完了
    ld      hl, #_flag
    res     #FLAG_SOUND_UPDATE_BIT, (hl)
29$:

    ; タイマ割り込みカウンタの更新
    ld      hl, #h.timiCount
    inc     (hl)
    
    ; 割り込み禁止の解除
    ei
    
    ; レジスタの復帰
    pop     iy
    pop     ix
    pop     de
    pop     bc
    pop     hl
    pop     af

    ; 保存されたタイマ割り込みルーチンの実行
    jp      h.timiRoutine
;   ret

; 定数定義
;


; DATA 領域
;
    .area   _DATA

; 変数定義
;

; タイマ割り込みルーチン
;
h.timiRoutine:
    
    .ds     0x05

; タイマ割り込みカウンタ
;
h.timiCount:

    .ds     0x01
    
