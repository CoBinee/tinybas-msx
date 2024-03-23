; Sound.s : サウンド
;


; モジュール宣言
;
    .module Sound

; 参照ファイル
;
    .include    "bios.inc"
    .include    "System.inc"
    .include	"Sound.inc"

; 外部変数宣言
;

; マクロの定義
;


; CODE 領域
;
    .area   _CODE

; BGM を再生する
;
_SoundPlayBgm::

    ; レジスタの保存
    push    hl
    push    bc
    push    de

    ; a < BGM

    ; 現在再生している BGM の取得
    ld      bc, (_soundChannel + SOUND_CHANNEL_A + SOUND_CHANNEL_HEAD)

    ; サウンドの再生
    add     a, a
    ld      e, a
    add     a, a
    add     a, e
    ld      e, a
    ld      d, #0x00
    ld      hl, #soundBgm
    add     hl, de
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    inc     hl
    ld      a, e
    cp      c
    jr      nz, 10$
    ld      a, d
    cp      b
    jr      z, 19$
10$:
    ld      (_soundChannel + SOUND_CHANNEL_A + SOUND_CHANNEL_REQUEST), de
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    inc     hl
    ld      (_soundChannel + SOUND_CHANNEL_B + SOUND_CHANNEL_REQUEST), de
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
;   inc     hl
    ld      (_soundChannel + SOUND_CHANNEL_C + SOUND_CHANNEL_REQUEST), de
19$:

    ; レジスタの復帰
    pop     de
    pop     bc
    pop     hl

    ; 終了
    ret

; SE を再生する
;
_SoundPlaySe::

    ; レジスタの保存
    push    hl
    push    de

    ; a < SE

    ; サウンドの再生
    add     a, a
    ld      e, a
    ld      d, #0x00
    ld      hl, #soundSe
    add     hl, de
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
;   inc     hl
    ld      (_soundChannel + SOUND_CHANNEL_D + SOUND_CHANNEL_REQUEST), de

    ; レジスタの復帰
    pop     de
    pop     hl

    ; 終了
    ret

; サウンドを停止する
;
_SoundStop::

    ; レジスタの保存

    ; サウンドの停止
    call    _SystemStopSound

    ; レジスタの復帰

    ; 終了
    ret

; BGM が再生中かどうかを判定する
;
_SoundIsPlayBgm::

    ; レジスタの保存
    push    hl

    ; cf > 0/1 = 停止/再生中

    ; サウンドの監視
    ld      hl, (_soundChannel + SOUND_CHANNEL_A + SOUND_CHANNEL_REQUEST)
    ld      a, h
    or      l
    jr      nz, 10$
    ld      hl, (_soundChannel + SOUND_CHANNEL_A + SOUND_CHANNEL_PLAY)
    ld      a, h
    or      l
    jr      nz, 10$
    or      a
    jr      19$
10$:
    scf
19$:

    ; レジスタの復帰
    pop     hl

    ; 終了
    ret

; SE が再生中かどうかを判定する
;
_SoundIsPlaySe::

    ; レジスタの保存
    push    hl

    ; cf > 0/1 = 停止/再生中

    ; サウンドの監視
    ld      hl, (_soundChannel + SOUND_CHANNEL_D + SOUND_CHANNEL_REQUEST)
    ld      a, h
    or      l
    jr      nz, 10$
    ld      hl, (_soundChannel + SOUND_CHANNEL_D + SOUND_CHANNEL_PLAY)
    ld      a, h
    or      l
    jr      nz, 10$
    or      a
    jr      19$
10$:
    scf
19$:

    ; レジスタの復帰
    pop     hl

    ; 終了
    ret

; 定数の定義
;

; 共通
;
soundNull:

    .ascii  "T1@0"
    .db     0x00

; BGM
;
soundBgm:

    .dw     soundNull, soundNull, soundNull

; SE
;
soundSe:

    .dw     soundNull
    .dw     soundSeBoot
    .dw     soundSeClick

; ブート
soundSeBoot:

    .ascii  "T2@0V15L3O6BO5BR9"
    .db     0x00

; クリック
soundSeClick:

    .ascii  "T2@0V15O4B0"
    .db     0x00


; DATA 領域
;
    .area   _DATA

; 変数の定義
;
