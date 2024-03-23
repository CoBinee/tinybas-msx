; crt0.s : ブートコード
;


; モジュール宣言
;
    .module crt0

; 参照ファイル
;
    .include    "main.inc"


; HEADER 領域（プログラムのエントリポイント）
;
    .area   _HEADER (ABS)
    .org    0x4010

; ブート
;
boot:

    ; スタックの設定
    ld      hl, #stackfinal
    ld      sp, hl

    ; main() 関数の呼び出し
    jp      _main


; CODE 領域
;
    .area   _CODE


; GSINIT 領域
;
    .area   _GSINIT

; 変数の初期化
;
gsinit:


; GSFINAL 領域
;
    .area   _GSFINAL

; 変数の初期化の完了
;
gsfinal:


; DATA 領域
;
    .area   _DATA

; DATA 領域の開始
;
data:

; スタック領域
;
_stack::

    .ds     0x0400

; スタック領域の末端
;
stackfinal:


; DATA 領域の末端
;
    .area   _DATAFINAL

; DATA 領域の終了
;
datafinal:
