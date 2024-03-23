; App.s : アプリケーション
;


; モジュール宣言
;
    .module App

; 参照ファイル
;
    .include    "bios.inc"
    .include    "vdp.inc"
    .include    "System.inc"
    .include	"App.inc"
    .include    "Basic.inc"

; 外部変数宣言
;
;   .globl  _spriteTable
;   .globl  _patternTable
    

; CODE 領域
;
    .area   _CODE

; アプリケーションを初期化する
;
_AppInitialize::
    
    ; レジスタの保存
    
    ; 画面表示の停止
    call    DISSCR
    
    ; 画面モードの設定
    call    INITXT

    ; ビデオの設定
    ld      hl, #RG0SAV ; #videoScreen1
    ld      de, #_videoRegister
    ld      bc, #0x08
    ldir
    
    ; 割り込みの禁止
    di
    
    ; VDP ポートの取得
    ld      a, (_videoPort + 1)
    ld      c, a
    
;   ; スプライトジェネレータの転送
;   ld      hl, #(_spriteTable + 0x0000)
;   ld      de, #(APP_SPRITE_GENERATOR_TABLE + 0x0000)
;   ld      bc, #0x0800
;   call    LDIRVM
    
;   ; パターンジェネレータの転送
;   ld      hl, #(_patternTable + 0x0000)
;   ld      de, #(APP_PATTERN_GENERATOR_TABLE + 0x0000)
;   ld      bc, #0x0800
;   call    LDIRVM

    ; カラーテーブルの転送
    ld      hl, #(APP_COLOR_TABLE + 0x0000)
    ld      a, #((VDP_COLOR_WHITE << 4) | VDP_COLOR_BLACK)
    ld      bc, #0x0020
    call    FILVRM

    ; パターンネームの初期化
    ld      hl, #APP_PATTERN_NAME_TABLE
    xor     a
    ld      bc, #0x0300
    call    FILVRM
    
    ; 割り込み禁止の解除
    ei

;   ; アプリケーションの初期化
;   ld      hl, #appDefault
;   ld      de, #_app
;   ld      bc, #APP_LENGTH
;   ldir
    
    ; 描画の開始
    ld      hl, #(_videoRegister + VDP_R1)
    set     #VDP_R1_BL, (hl)
    
    ; レジスタの復帰
    
    ; 終了
    ret

; アプリケーションを更新する
;
_AppUpdate::
    
    ; レジスタの保存

    ; BASIC インタプリタの実行
    jp      _Basic

    ; レジスタの復帰
    
;   ; 終了
;   ret

; 処理なし
;
_AppNull::

    ; レジスタの保存
    
    ; レジスタの復帰
    
    ; 終了
    ret

; 定数の定義
;

; VDP レジスタ値（スクリーン１）
;
; videoScreen1:
;
;   .db     0b00000000
;   .db     0b10100010
;   .db     APP_PATTERN_NAME_TABLE >> 10
;   .db     APP_COLOR_TABLE >> 6
;   .db     APP_PATTERN_GENERATOR_TABLE >> 11
;   .db     APP_SPRITE_ATTRIBUTE_TABLE >> 7
;   .db     APP_SPRITE_GENERATOR_TABLE >> 11
;   .db     0b00000111

; アプリケーションの初期値
;
; appDefault:
;
;   .db     APP_STATE_NULL
;   .db     APP_FRAME_NULL


; DATA 領域
;
    .area   _DATA

; 変数の定義
;

; アプリケーション
;
_app::

    .ds     APP_LENGTH

