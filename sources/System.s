; System.s : システムライブラリ
;


; モジュール宣言
;
    .module System

; 参照ファイル
;
    .include    "main.inc"
    .include    "bios.inc"
    .include    "vdp.inc"
    .include    "System.inc"


; CODE 領域
;
    .area   _CODE

; システムを起動する
;
_SystemBoot::

    ; レジスタの保存

    ; スロットの起動
    call    SystemBootSlot

    ; レジスタの復帰

    ; 終了
    ret

; スロットを起動する
;
SystemBootSlot:

    ; レジスタの保存

    ; スロットの初期化
    ld      hl, #(_slot + 0x0000)
    ld      de, #(_slot + 0x0001)
    ld      bc, #(SLOT_SIZE - 0x0001)
    ld      (hl), #0xff
    ldir

    ; ページ 1 のスロットの保存
    call    RSLREG
    rrca
    rrca
    and     #0b00000011
    ld      c, a
    ld      b, #0x00
    ld      hl, #EXPTBL
    add     hl, bc
    ld      a, (hl)
    and     #0b10000000
    or      c
    ld      c, a
    inc     hl
    inc     hl
    inc     hl
    inc     hl
    ld      a, (hl)
    and     #0b00001100
    or      c
    ld      (_slot + SLOT_PAGE1), a

;   ; ページ 2 のスロットの設定
;   ld      h, #0x80
;   call    ENASLT

    ; レジスタの復帰

    ; 終了
    ret

; システムを初期化する
;
_SystemInitialize::
    
    ; レジスタの保存
    
    ; フラグの初期化
    xor     a
    ld      (_flag), a
    
    ; スロットの初期化
    call    SystemInitializeSlot

    ; キー入力の初期化
    call    SystemInitializeInput
    
    ; ビデオの初期化
    call    SystemInitializeVideo

    ; スプライトの初期化
    call    SystemInitializeSprite

    ; パターンネームの初期化
    call    SystemInitializePatternName

    ; サウンドの初期化
    call    SystemInitializeSound

    ; 転送の初期化
    ld      hl, #_SystemUpdatePatternName
    ld      (_transfer), hl

    ; デバッグの初期化
    ld      hl, #(_debug + 0x0000)
    ld      de, #(_debug + 0x0001)
    ld      bc, #(DEBUG_SIZE - 0x0001)
    ld      (hl), #0x00
    ldir

    ; レジスタの復帰
    
    ; 終了
    ret

; スロットを初期化する
;
SystemInitializeSlot:

    ; レジスタの保存

    ; レジスタの復帰

    ; 終了
    ret

; キー入力を初期化する  
;
SystemInitializeInput:
    
    ; レジスタの保存
    
    ; キー入力の初期化
    ld      hl, #(_input + 0x0000)
    ld      de, #(_input + 0x0001)
    ld      bc, #INPUT_SIZE
    ld      (hl), #0x00
    ldir

    ; キークリック音の無効化
    xor     a
    ld      (CLIKSW), a
    
    ; レジスタの復帰
    
    ; 終了
    ret

; キーの入力を更新する
;
_SystemUpdateInput::
    
    ; レジスタの保存
    
    ; キーの取得
    xor     a
    call    GTSTCK
    or      a
    jr      nz, 10$
    inc     a
    call    GTSTCK
10$:
    ld      c, a
    ld      b, #0x00
    ld      hl, #inputKeyTable
    add     hl, bc
    ld      h, (hl)

    ; ボタンの取得
    xor     a
    call    GTTRIG
    or      a
    jr      nz, 20$
    inc     a
    call    GTTRIG
    or      a
    jr      nz, 20$
    ld      a, #0x05
    call    SNSMAT
    and     #0b10000000
    jr      nz, 21$
20$:
    set     #INPUT_BUTTON_SPACE, h
21$:
    ld      a, #0x03
    call    GTTRIG
    or      a
    jr      nz, 22$
    ld      a, #0x06
    call    SNSMAT
    and     #0b00000001
    jr      z, 22$
    ld      a, #0x05
    call    SNSMAT
    and     #0b00100000
    jr      nz, 23$
22$:
    set     #INPUT_BUTTON_SHIFT, h
23$:
    ld      a, #0x07
    call    SNSMAT
    and     #0x04
    jr      nz, 24$
    set     #INPUT_BUTTON_ESC, h
24$:

    ; キー入力の取得
    ld      c, h
    ld      hl, #_input
    ld      b, #INPUT_SIZE
30$:
    ld      a, (hl)
    srl     c
    jr      c, 31$
    xor     a
    jr      32$
31$:
    inc     a
    jr      nz, 32$
    inc     a
32$:
    ld      (hl), a
    inc     hl
    djnz    30$
    
    ; レジスタの復帰
    
    ; 終了
    ret

; ビデオを初期化する
;
SystemInitializeVideo:
    
    ; レジスタの保存
    
    ; ポートの取得
    ld      a, (0x0006)
    ld      (_videoPort + 0), a
    ld      a, (0x0007)
    ld      (_videoPort + 1), a
    
    ; レジスタの取得
    ld      hl, #RG0SAV
    ld      de, #_videoRegister
    ld      bc, #0x08
    ldir

    ; レジスタの復帰
    
    ; 終了
    ret

; ビデオを更新する
;
_SystemUpdateVideo::
    
    ; レジスタの保存
    
    ; d < ポート #0
    ; e < ポート #1

    ; レジスタの取得
    ld      hl, #_videoRegister

    ; レジスタの転送
    ld      c, e
    outi
    ld      a, #0x80
    out     (c), a
    outi
    inc     a
    out     (c), a
    outi
    inc     a
    out     (c), a
    outi
    inc     a
    out     (c), a
    outi
    inc     a
    out     (c), a
    outi
    inc     a
    out     (c), a
    outi
    inc     a
    out     (c), a
    outi
    inc     a
    out     (c), a
    
    ; レジスタの復帰
    
    ; 終了
    ret

; ビデオポートを取得する
;
_SystemGetVideoPort::

    ; レジスタの保存

    ; d > ポート #0
    ; e > ポート #1

    ; ポートの取得
    ld      a, (_videoPort + 1)
    ld      d, a
    inc     a
    ld      e, a

    ; 終了
    ret

; スプライトを初期化する
;
SystemInitializeSprite:

    ; レジスタの保存

    ; スプライトのクリア
    call    _SystemClearSprite

    ; レジスタの復帰
    
    ; 終了
    ret

; スプライトを更新する
;
_SystemUpdateSprite::
    
    ; レジスタの保存
    
    ; d > ポート #0
    ; e > ポート #1

    ; スプライトアトリビュートテーブルの取得
    ld      a, (_videoRegister + VDP_R5)
    ld      l, #0x00
    rra
    rr      l
    
    ; VRAM アドレスの設定
    ld      c, e
    out     (c), l
    or      #0b01000000
    out     (c), a
    
    ; スプライトアトリビュートテーブルの転送
    ld      c, d
    ld      hl, #_sprite
    ld      b, #0x80
;   otir
10$:
    outi
    jp      nz, 10$

    ; レジスタの復帰
    
    ; 終了
    ret

; スプライトをクリアする
;
_SystemClearSprite::
    
    ; レジスタの保存
    push    hl
    push    bc
    push    de
    
    ; スプライトのクリア
    ld      hl, #(_sprite + 0x0000)
    ld      de, #(_sprite + 0x0001)
    ld      bc, #0x007f
    ld      (hl), #0xc0
    ldir
    
    ; レジスタの復帰
    pop     de
    pop     bc
    pop     hl
    
    ; 終了
    ret

; パターンネームを初期化する
;
SystemInitializePatternName:

    ; レジスタの保存

    ; パターンネームのクリア
    xor     a
    call    _SystemClearPatternName

    ; レジスタの復帰
    
    ; 終了
    ret

; パターンネームを更新する
;
_SystemUpdatePatternName::
    
    ; レジスタの保存
    
    ; d < ポート #0
    ; e < ポート #1

    ; パターンネームテーブルの取得    
    ld      a, (_videoRegister + VDP_R2)
    add     a, a
    add     a, a
    ld      l, #0x00

    ; VRAM アドレスの設定
    ld      c, e
    out     (c), l
    or      #0b01000000
    out     (c), a

    ; パターンネームテーブルの転送
    ld      c, d
    ld      hl, #_patternName
    ld      b, #0x00
;   otir
;   nop
10$:
    outi
    jp      nz, 10$
;   otir
;   nop
11$:
    outi
    jp      nz, 11$
;   otir
;   nop
12$:
    outi
    jp      nz, 12$
    ld      b, #(40 * 24 - 0x0300)
;   otir
;   nop
13$:
    outi
    jp      nz, 13$
    
    ; レジスタの復帰
    
    ; 終了
    ret

; パターンネームをクリアする
;
_SystemClearPatternName::

    ; レジスタの保存
    push    hl
    push    bc
    push    de

    ; a < pattern name data

    ; パターンネームのクリア
    ld      hl, #(_patternName + 0x0000)
    ld      de, #(_patternName + 0x0001)
    ld      bc, #(40 * 24 - 1)
    ld      (hl), a
    ldir

    ; レジスタの復帰
    pop     de
    pop     bc
    pop     hl

    ; 終了
    ret

; サウンドを初期化する
;
SystemInitializeSound:
    
    ; レジスタの保存
    
    ; PSG の初期化
    call    GICINI
    ld      e, #0b10111111
    ld      a, #0x07
    call    WRTPSG
    
;   ; サウンドレジスタの初期化
;   ld      0x00(ix), #0b01010101
;   ld      0x01(ix), #0b00000000
;   ld      0x02(ix), #0b00000000
;   ld      0x03(ix), #0b00000000
;   ld      0x04(ix), #0b00000000
;   ld      0x05(ix), #0b00000000
;   ld      0x06(ix), #0b00000000
;   ld      0x07(ix), #0b10111111
;   ld      0x08(ix), #0b00000000
;   ld      0x09(ix), #0b00000000
;   ld      0x0a(ix), #0b00000000
;   ld      0x0b(ix), #0b00001011
;   ld      0x0c(ix), #0b00000000
;   ld      0x0d(ix), #0b00000000
;   ld      0x0e(ix), #0b00000000
;   ld      0x0f(ix), #0b00000000

    ; サウンドの初期化
    ld      hl, #(_sound + 0x0000)
    ld      de, #(_sound + 0x0001)
    ld      bc, #(SOUND_SIZE - 0x0001)
    ld      (hl), #0x00
    ldir
    ld      a, #0b10111111
    ld      (_sound + SOUND_PSG_MIXER), a

    ; チャンネルの初期化
    ld      hl, #(_soundChannel + 0x0000)
    ld      de, #(_soundChannel + 0x0001)
    ld      bc, #(SOUND_CHANNEL_SIZE * SOUND_CHANNEL_ENTRY - 0x0001)
    ld      (hl), #0x00
    ldir

    ; レジスタの復帰
    
    ; 終了
    ret

; サウンドを更新する
;
_SystemUpdateSound::
    
    ; レジスタの保存
    
    ; スリープ
    ld      a, (_flag)
    bit     #FLAG_SOUND_SLEEP_BIT, a
    jp      nz, 90$

    ; フラグのクリア
    xor     a
    ld      (_sound + SOUND_FLAG), a
    
    ; チャンネルの走査
    ld      ix, #_soundChannel
    ld      b, #SOUND_CHANNEL_ENTRY
100$:
    push    bc
    
    ; リクエスト
    ld      a, SOUND_CHANNEL_REQUEST_L(ix)
    or      SOUND_CHANNEL_REQUEST_H(ix)
    jr      z, 101$
    ld      l, SOUND_CHANNEL_REQUEST_L(ix)
    ld      h, SOUND_CHANNEL_REQUEST_H(ix)
    xor     a
    ld      SOUND_CHANNEL_REQUEST_L(ix), a
    ld      SOUND_CHANNEL_REQUEST_H(ix), a
    ld      SOUND_CHANNEL_HEAD_L(ix), l
    ld      SOUND_CHANNEL_HEAD_H(ix), h
    ld      SOUND_CHANNEL_PLAY_L(ix), l
    ld      SOUND_CHANNEL_PLAY_H(ix), h
    call    SystemClearSoundChannel
101$:
    
    ; 再生ポインタの取得
    ld      l, SOUND_CHANNEL_PLAY_L(ix)
    ld      h, SOUND_CHANNEL_PLAY_H(ix)

    ; サウンドデータの存在
    ld      a, h
    or      l
    jp      z, 190$
    
    ; 待機
    dec     SOUND_CHANNEL_REST(ix)
    jr      z, 110$
    
    ; 音量の減衰
    ld      a, SOUND_CHANNEL_VOLUME_PLAY(ix)
    or      a
    jp      z, 190$
    ld      e, a
    ld      a, SOUND_CHANNEL_VOLUME_MINUS(ix)
    or      a
    jp      z, 190$
    dec     SOUND_CHANNEL_VOLUME_FRAME(ix)
    jp      nz, 190$
    dec     e
    ld      SOUND_CHANNEL_VOLUME_PLAY(ix), e
    ld      a, SOUND_CHANNEL_VOLUME_MINUS(ix)
    ld      SOUND_CHANNEL_VOLUME_FRAME(ix), a
    set     #SOUND_CHANNEL_FLAG_VOLUME_BIT, SOUND_CHANNEL_FLAG(ix)
    jp      190$
    
    ; MML の解析
110$:
    ld      a, (hl)
    inc     hl
    
    ; 0x00 : 終端コード
    or      a
    jr      nz, 111$
;   xor     a
    ld      SOUND_CHANNEL_HEAD_L(ix), a
    ld      SOUND_CHANNEL_HEAD_H(ix), a
    ld      SOUND_CHANNEL_PLAY_L(ix), a
    ld      SOUND_CHANNEL_PLAY_H(ix), a
    ld      SOUND_CHANNEL_TONE_FREQUENCY_L(ix), a
    ld      SOUND_CHANNEL_TONE_FREQUENCY_H(ix), a
    ld      SOUND_CHANNEL_MIXER_PSG(ix), #0b00001001
    set     #SOUND_CHANNEL_FLAG_UPDATE_BIT, SOUND_CHANNEL_FLAG(ix)
    jr      190$
111$:
    
    ; 0xff : 繰り返し
    cp      #0xff
    jr      nz, 112$
    ld      l, SOUND_CHANNEL_HEAD_L(ix)
    ld      SOUND_CHANNEL_PLAY_L(ix), l
    ld      h, SOUND_CHANNEL_HEAD_H(ix)
    ld      SOUND_CHANNEL_PLAY_H(ix), h
    jr      110$
112$:
    
    ; '@''A'～'Z' の処理
    ld      de, #113$
    push    de
    sub     #'@
    add     a, a
    ld      e, a
    ld      d, #0x00
    ld      iy, #soundMmlProc
    add     iy, de
    ld      e, 0x00(iy)
    ld      d, 0x01(iy)
    push    de
    pop     iy
    jp      (iy)
;   pop     de
113$:
    jr      c, 110$
    
    ; 音の長さの設定
    ld      a, (hl)
    cp      #('9 + 0x01)
    jr      nc, 120$
    sub     #'0
    jr      c, 120$
    inc     hl
    jr      121$
120$:
    ld      a, SOUND_CHANNEL_LENGTH(ix)
121$:
    push    hl
    ld      e, a
    ld      d, #0x00
    ld      hl, #soundLengthTable
    add     hl, de
    ld      a, SOUND_CHANNEL_TEMPO(ix)
    add     a, a
    add     a, a
    add     a, a
    add     a, a
    ld      e, a
;   ld      d, #0x00
    add     hl, de
    ld      a, (hl)
    ld      SOUND_CHANNEL_REST(ix), a

    ; チャンネルの更新
    bit     #0x04, SOUND_CHANNEL_VOLUME(ix)
    jr      z, 130$
    set     #SOUND_CHANNEL_FLAG_ENVELOPE_BIT, SOUND_CHANNEL_FLAG(ix)
130$:
    set     #SOUND_CHANNEL_FLAG_UPDATE_BIT, SOUND_CHANNEL_FLAG(ix)
    pop     hl
    
    ; 再生ポインタの保存
    ld      SOUND_CHANNEL_PLAY_L(ix), l
    ld      SOUND_CHANNEL_PLAY_H(ix), h
    
    ; 次のチャンネルへ
190$:
    ld      hl, #(_sound + SOUND_FLAG)
    ld      a, (hl)
    or      SOUND_CHANNEL_FLAG(ix)
    ld      (hl), a
    ld      de, #SOUND_CHANNEL_SIZE
    add     ix, de
    pop     bc
    dec     b
    jp      nz, 100$
    
    ; 更新の確認
    ld      a, (_sound + SOUND_FLAG)
    and     #(SOUND_CHANNEL_FLAG_UPDATE | SOUND_CHANNEL_FLAG_VOLUME)
    jp      z, 90$
    
    ; エンベロープ周波数の設定
    ld      de, (_sound + SOUND_PSG_ENVELOPE_FREQUENCY)
    ld      a, #0x0b
    call    WRTPSG
    ld      e, d
    inc     a
    call    WRTPSG
    
    ; ノイズ周波数の設定
    ld      a, (_sound + SOUND_PSG_NOISE_FREQUENCY)
    ld      e, a
    ld      a, #0x06
    call    WRTPSG
    
    ; チャンネルＡの設定
    ld      a, (_soundChannel + SOUND_CHANNEL_A + SOUND_CHANNEL_FLAG)
    bit     #SOUND_CHANNEL_FLAG_VOLUME_BIT, a
    jr      nz, 300$
    bit     #SOUND_CHANNEL_FLAG_UPDATE_BIT, a
    jr      z, 309$
    ld      hl, #(_sound + SOUND_PSG_MIXER)
    ld      a, (hl)
    and     #0b11110110
    ld      e, a
    ld      a, (_soundChannel + SOUND_CHANNEL_A + SOUND_CHANNEL_MIXER_PSG)
    or      e
    ld      (hl), a
    ld      de, (_soundChannel + SOUND_CHANNEL_A + SOUND_CHANNEL_TONE_FREQUENCY)
    ld      a, #0x00
    call    WRTPSG
    ld      e, d
    ld      a, #0x01
    call    WRTPSG
300$:
    ld      a, (_soundChannel + SOUND_CHANNEL_A + SOUND_CHANNEL_VOLUME_PLAY)
    ld      e, a
    ld      a, #0x08
    call    WRTPSG
    ld      a, (_soundChannel + SOUND_CHANNEL_A + SOUND_CHANNEL_FLAG)
    and     #(~(SOUND_CHANNEL_FLAG_UPDATE | SOUND_CHANNEL_FLAG_VOLUME | SOUND_CHANNEL_FLAG_ENVELOPE | SOUND_CHANNEL_FLAG_VOICE))
    ld      (_soundChannel + SOUND_CHANNEL_A + SOUND_CHANNEL_FLAG), a
309$:

    ; チャンネルＢの設定
    ld      a, (_soundChannel + SOUND_CHANNEL_B + SOUND_CHANNEL_FLAG)
    bit     #SOUND_CHANNEL_FLAG_VOLUME_BIT, a
    jr      nz, 310$
    bit     #SOUND_CHANNEL_FLAG_UPDATE_BIT, a
    jr      z, 319$
    ld      hl, #(_sound + SOUND_PSG_MIXER)
    ld      a, (hl)
    and     #0b11101101
    ld      e, a
    ld      a, (_soundChannel + SOUND_CHANNEL_B + SOUND_CHANNEL_MIXER_PSG)
    add     a, a
    or      e
    ld      (hl), a
    ld      de, (_soundChannel + SOUND_CHANNEL_B + SOUND_CHANNEL_TONE_FREQUENCY)
    ld      a, #0x02
    call    WRTPSG
    ld      e, d
    ld      a, #0x03
    call    WRTPSG
310$:
    ld      a, (_soundChannel + SOUND_CHANNEL_B + SOUND_CHANNEL_VOLUME_PLAY)
    ld      e, a
    ld      a, #0x09
    call    WRTPSG
    ld      a, (_soundChannel + SOUND_CHANNEL_B + SOUND_CHANNEL_FLAG)
    and     #(~(SOUND_CHANNEL_FLAG_UPDATE | SOUND_CHANNEL_FLAG_VOLUME | SOUND_CHANNEL_FLAG_ENVELOPE | SOUND_CHANNEL_FLAG_VOICE))
    ld      (_soundChannel + SOUND_CHANNEL_B + SOUND_CHANNEL_FLAG), a
319$:

    ; チャンネルＤの設定
    ld      a, (_soundChannel + SOUND_CHANNEL_D + SOUND_CHANNEL_FLAG)
    bit     #SOUND_CHANNEL_FLAG_VOLUME_BIT, a
    jr      nz, 320$
    bit     #SOUND_CHANNEL_FLAG_UPDATE_BIT, a
    jr      z, 329$
    ld      hl, #(_sound + SOUND_PSG_MIXER)
    ld      a, (hl)
    and     #0b11011011
    ld      e, a
    ld      a, (_soundChannel + SOUND_CHANNEL_D + SOUND_CHANNEL_MIXER_PSG)
    add     a, a
    add     a, a
    or      e
    ld      (hl), a
    ld      de, (_soundChannel + SOUND_CHANNEL_D + SOUND_CHANNEL_TONE_FREQUENCY)
    ld      a, #0x04
    call    WRTPSG
    ld      e, d
    ld      a, #0x05
    call    WRTPSG
320$:
    ld      a, (_soundChannel + SOUND_CHANNEL_D + SOUND_CHANNEL_VOLUME_PLAY)
    ld      e, a
    ld      a, #0x0a
    call    WRTPSG
    ld      a, (_soundChannel + SOUND_CHANNEL_D + SOUND_CHANNEL_FLAG)
    and     #(~(SOUND_CHANNEL_FLAG_UPDATE | SOUND_CHANNEL_FLAG_VOLUME | SOUND_CHANNEL_FLAG_ENVELOPE | SOUND_CHANNEL_FLAG_VOICE))
    ld      (_soundChannel + SOUND_CHANNEL_D + SOUND_CHANNEL_FLAG), a
329$:

    ; チャンネルＣの設定
    ld      hl, (_soundChannel + SOUND_CHANNEL_D + SOUND_CHANNEL_PLAY)
    ld      a, h
    or      l
    jr      nz, 338$
    ld      a, (_soundChannel + SOUND_CHANNEL_C + SOUND_CHANNEL_FLAG)
    bit     #SOUND_CHANNEL_FLAG_VOLUME_BIT, a
    jr      nz, 330$
    bit     #SOUND_CHANNEL_FLAG_UPDATE_BIT, a
    jr      z, 339$
    ld      hl, #(_sound + SOUND_PSG_MIXER)
    ld      a, (hl)
    and     #0b11011011
    ld      e, a
    ld      a, (_soundChannel + SOUND_CHANNEL_C + SOUND_CHANNEL_MIXER_PSG)
    add     a, a
    add     a, a
    or      e
    ld      (hl), a
    ld      de, (_soundChannel + SOUND_CHANNEL_C + SOUND_CHANNEL_TONE_FREQUENCY)
    ld      a, #0x04
    call    WRTPSG
    ld      e, d
    ld      a, #0x05
    call    WRTPSG
330$:
    ld      a, (_soundChannel + SOUND_CHANNEL_C + SOUND_CHANNEL_VOLUME_PLAY)
    ld      e, a
    ld      a, #0x0a
    call    WRTPSG
338$:
    ld      a, (_soundChannel + SOUND_CHANNEL_C + SOUND_CHANNEL_FLAG)
    and     #(~(SOUND_CHANNEL_FLAG_UPDATE | SOUND_CHANNEL_FLAG_VOLUME | SOUND_CHANNEL_FLAG_ENVELOPE | SOUND_CHANNEL_FLAG_VOICE))
    ld      (_soundChannel + SOUND_CHANNEL_C + SOUND_CHANNEL_FLAG), a
339$:

    ; エンベロープ形状の設定
    ld      a, (_sound + SOUND_FLAG)
    and     #SOUND_CHANNEL_FLAG_ENVELOPE
    jr      z, 40$
    ld      a, (_sound + SOUND_PSG_ENVELOPE_PATTERN)
    ld      e, a
    ld      a, #0x0d
    call    WRTPSG
40$:
    
    ; ミキサ（PSG）の設定
    ld      a, (_sound + SOUND_PSG_MIXER)
    ld      e, a
    ld      a, #0x07
    call    WRTPSG

    ; 更新の終了
90$:
    
    ; レジスタの復帰
    
    ; 終了
    ret

; MML : 非対応命令
;
SystemUpdateSoundMmlNull:
    
    scf
    ret

; 'S' : エンベロープ波形（S0 ～ S15）
;
SystemUpdateSoundMmlS:

    ld      a, (hl)
    inc     hl
    sub     #'0
    ld      (_sound + SOUND_PSG_ENVELOPE_PATTERN), a
    ld      a, (hl)
    sub     #'0
    cp      #0x0a
    jr      nc, 09$
    add     a, #0x0a
    ld      (_sound + SOUND_PSG_ENVELOPE_PATTERN), a
    inc     hl
09$:
    scf
    ret
    
; 'M' : エンベロープ周期（M0 ～ M9）
;
SystemUpdateSoundMmlM:

    ld      a, (hl)
    inc     hl
    push    hl
    sub     #'0
    add     a, a
    ld      e, a
    ld      d, #0x00
    ld      hl, #soundEnvelopeTable
    add     hl, de
    ld      a, (hl)
    ld      (_sound + SOUND_PSG_ENVELOPE_FREQUENCY_L), a
    inc     hl
    ld      a, (hl)
    ld      (_sound + SOUND_PSG_ENVELOPE_FREQUENCY_H), a
    pop     hl
    scf
    ret
    
; 'N' : ノイズ周波数（N0 ～ N9）
;
SystemUpdateSoundMmlN:

    ld      a, (hl)
    inc     hl
    push    hl
    sub     #'0
    ld      e, a
    ld      d, b
    ld      hl, #soundNoiseFrequencyTable
    add     hl, de
    ld      a, (hl)
    ld      (_sound + SOUND_PSG_NOISE_FREQUENCY), a
    pop     hl
    scf
    ret
    
; 'T' : テンポ（T1 ～ T8）
;
SystemUpdateSoundMmlT:

    ld      a, (hl)
    inc     hl
    sub     #'1
    ld      SOUND_CHANNEL_TEMPO(ix), a
    scf
    ret

; '@' : 音色（@0 〜 @9）
;
SystemUpdateSoundMmlAt:

    ld      a, (hl)
    inc     hl
    sub     #'0
    ld      SOUND_CHANNEL_VOICE(ix), a
    scf
    ret

; 'V' : 音量（V0 ～ V16）
;
SystemUpdateSoundMmlV:

    ld      a, (hl)
    inc     hl
    sub     #'0
    ld      SOUND_CHANNEL_VOLUME(ix), a
    ld      a, (hl)
    sub     #'0
    cp      #0x0a
    jr      nc, 00$
    add     a, #0x0a
    ld      SOUND_CHANNEL_VOLUME(ix), a
    inc     hl
00$:
    ld      a, (hl)
    cp      #',
    jr      nz, 01$
    inc     hl
    ld      a, (hl)
    sub     #'0
    inc     hl
    jr      02$
01$:
    xor     a
02$:
    ld      SOUND_CHANNEL_VOLUME_MINUS(ix), a
    ld      SOUND_CHANNEL_VOLUME_FRAME(ix), a
    scf
    ret
    
; 'O' : オクターブ（O1 ～ O8）
;
SystemUpdateSoundMmlO:

    ld      a, (hl)
    inc     hl
    sub     #'1
    ld      SOUND_CHANNEL_OCTAVE(ix), a
    scf
    ret
    
; 'L' : 音の長さ（L0 ～ L9）
;
SystemUpdateSoundMmlL:

    ld      a, (hl)
    inc     hl
    sub     #'0
    ld      SOUND_CHANNEL_LENGTH(ix), a
    scf
    ret
    
; 'R' : 休符
;
SystemUpdateSoundMmlR:

    xor     a
;   ld      SOUND_CHANNEL_TONE_FREQUENCY_L(ix), a
;   ld      SOUND_CHANNEL_TONE_FREQUENCY_H(ix), a
    ld      SOUND_CHANNEL_VOLUME_PLAY(ix), a
    ld      SOUND_CHANNEL_MIXER_PSG(ix), #0b00001001
    or      a
    ret
    
; 'X' : ノイズ
;
SystemUpdateSoundMmlX:

;   xor     a
;   ld      SOUND_CHANNEL_TONE_FREQUENCY_L(ix), a
;   ld      SOUND_CHANNEL_TONE_FREQUENCY_H(ix), a
    ld      a, SOUND_CHANNEL_VOLUME(ix)
    ld      SOUND_CHANNEL_VOLUME_PLAY(ix), a
    ld      a, SOUND_CHANNEL_VOLUME_MINUS(ix)
    ld      SOUND_CHANNEL_VOLUME_FRAME(ix), a
    ld      SOUND_CHANNEL_MIXER_PSG(ix), #0b00000001
    or      a
    ret
    
; 'A' : 音符
;
SystemUpdateSoundMmlA:

    sub     #(('C - '@) * 0x02)
    jr      nc, 00$
    add     a, #(0x07 * 0x02)
00$:
;   add     a, a
    add     a, a
    ld      e, a
    ld      d, #0x00
    push    hl
    ld      hl, #(soundToneFrequencyPsgTable + 0x0004)
    add     hl, de
    ld      a, SOUND_CHANNEL_OCTAVE(ix)
    add     a, a
    add     a, a
    add     a, a
    add     a, a
    add     a, a
    ld      e, a
;   ld      d, #0x00
    add     hl, de
    ex      de, hl
    pop     hl
    ld      a, (hl)
    cp      #'+
    jr      nz, 01$
    inc     de
    inc     de
    inc     hl
    jr      02$
01$:
    cp      #'-
    jr      nz, 02$
    dec     de
    dec     de
    inc     hl
02$:
    ld      a, (de)
    ld      SOUND_CHANNEL_TONE_FREQUENCY_L(ix), a
    inc     de
    ld      a, (de)
    ld      SOUND_CHANNEL_TONE_FREQUENCY_H(ix), a
    ld      a, SOUND_CHANNEL_VOLUME(ix)
    ld      SOUND_CHANNEL_VOLUME_PLAY(ix), a
    ld      a, SOUND_CHANNEL_VOLUME_MINUS(ix)
    ld      SOUND_CHANNEL_VOLUME_FRAME(ix), a
    ld      a, SOUND_CHANNEL_VOICE(ix)
    or      a
    jr      nz, 03$
    ld      SOUND_CHANNEL_MIXER_PSG(ix), #0b00001000
    jr      04$
03$:
    ld      SOUND_CHANNEL_MIXER_PSG(ix), #0b00001001
04$:
    or      a
    ret

; サウンドのチャンネルをクリアする
;
SystemClearSoundChannel:
    
    ; レジスタの保存
    push    af

    ; ix < sound channel
    
    ; チャンネルのクリア
    xor     a
    ld      SOUND_CHANNEL_TEMPO(ix), a
    ld      SOUND_CHANNEL_VOICE(ix), a
    ld      SOUND_CHANNEL_VOLUME(ix), #0x0f
    ld      SOUND_CHANNEL_VOLUME_PLAY(ix), #0x0f
    ld      SOUND_CHANNEL_VOLUME_MINUS(ix), a
    ld      SOUND_CHANNEL_OCTAVE(ix), #0x03
    ld      SOUND_CHANNEL_LENGTH(ix), #0x05
    ld      SOUND_CHANNEL_TONE_FREQUENCY_L(ix), a
    ld      SOUND_CHANNEL_TONE_FREQUENCY_H(ix), a
    ld      SOUND_CHANNEL_REST(ix), #0x01
    ld      SOUND_CHANNEL_MIXER_PSG(ix), #0b00001001
    ld      SOUND_CHANNEL_FLAG(ix), a
    
    ; レジスタの復帰
    pop     af
    
    ; 終了
    ret

; サウンドを停止する
;
_SystemStopSound::

    ; レジスタの保存
    push    bc
    push    de
    push    ix

    ; 再生の停止
    ld      ix, #_soundChannel
    ld      de, #SOUND_CHANNEL_SIZE
    ld      bc, #((SOUND_CHANNEL_ENTRY << 8) | 0x0000)
10$:
    ld      SOUND_CHANNEL_HEAD_L(ix), c
    ld      SOUND_CHANNEL_HEAD_H(ix), c
    ld      SOUND_CHANNEL_PLAY_L(ix), c
    ld      SOUND_CHANNEL_PLAY_H(ix), c
    ld      SOUND_CHANNEL_TONE_FREQUENCY_L(ix), c
    ld      SOUND_CHANNEL_TONE_FREQUENCY_H(ix), c
    ld      SOUND_CHANNEL_MIXER_PSG(ix), #0b00001001
    add     ix, de
    djnz    10$

    ; サウンドの停止
    call    SystemMuteSound
    
    ; レジスタの復帰
    pop     ix
    pop     de
    pop     bc
    
    ; 終了
    ret

; サウンドを一時停止する
;
_SystemSuspendSound::
    
    ; レジスタの保存
    push    hl
    
    ; スリープの設定
    ld      hl, #_flag
    set     #FLAG_SOUND_SLEEP_BIT, (hl)
    
    ; サウンドの発声の停止
    call    SystemMuteSound

    ; レジスタの復帰
    pop     hl
    
    ; 終了
    ret

; サウンドを再開する
;
_SystemResumeSound::
    
    ; レジスタの保存
    push    hl
    push    bc
    push    de
    
    ; スリープの解除
    ld      hl, #_flag
    res     #FLAG_SOUND_SLEEP_BIT, (hl)
    
    ; サウンドの更新
    ld      hl, #(_soundChannel + SOUND_CHANNEL_FLAG)
    ld      de, #SOUND_CHANNEL_SIZE
    ld      b, #SOUND_CHANNEL_ENTRY
10$:
    set     #SOUND_CHANNEL_FLAG_UPDATE_BIT, (hl)
    add     hl, de
    djnz    10$
    
    ; レジスタの復帰
    pop     de
    pop     bc
    pop     hl
    
    ; 終了
    ret

; サウンドの発声を停止する
;
SystemMuteSound:

    ; レジスタの保存
    push    de

    ; PSG の停止
    ld      e, #0b10111111
    ld      a, #0x07
    call    WRTPSG
    ld      e, #0b00000000
    inc     a
    call    WRTPSG
    inc     a
    call    WRTPSG
    inc     a
    call    WRTPSG

    ; レジスタの復帰
    pop     de

    ; 終了
    ret

; 乱数を取得する
;
_SystemGetRandom::
    
    ; レジスタの保存
    push    hl
    push    de

    ; a > random number
    
    ; 乱数の生成
    ld      hl, (random)
    ld      e, l
    ld      d, h
    add     hl, hl
    add     hl, hl
    add     hl, de
    ld      de, #0x2018
    add     hl, de
    ld      (random), hl
    ld      a, h
    
    ; レジスタの復帰
    pop     de
    pop     hl
    
    ; 終了
    ret

; CRC を計算する
;
_SystemCalcCrc::

    ; レジスタの保存
    push    hl
    push    bc
    push    de

    ; hl < data address
    ; bc < data length
    ; a  > crc

    ; CRC8: x^8 + x^7 + x^2 + 1 = 0x85
    ld      e, #0x85
    xor     a
10$:
    xor     (hl)
    ld      d, #0x08
11$:
    add     a, a
    jr      nc, 12$
    xor     e
12$:
    dec     d
    jr      nz, 11$
    inc     hl
    dec     bc
    ld      d, a
    ld      a, b
    or      c
    ld      a, d
    jr      nz, 10$

    ; レジスタの復帰
    pop     de
    pop     bc
    pop     hl

    ; 終了
    ret

; 定数の定義
;

; キー入力
;
inputKeyTable:
    
    .db     0x00
    .db     (1 << INPUT_KEY_UP)
    .db     (1 << INPUT_KEY_UP)    | (1 << INPUT_KEY_RIGHT)
    .db     (1 << INPUT_KEY_RIGHT)
    .db     (1 << INPUT_KEY_DOWN)  | (1 << INPUT_KEY_RIGHT)
    .db     (1 << INPUT_KEY_DOWN)
    .db     (1 << INPUT_KEY_DOWN)  | (1 << INPUT_KEY_LEFT)
    .db     (1 << INPUT_KEY_LEFT)
    .db     (1 << INPUT_KEY_UP)    | (1 << INPUT_KEY_LEFT)

; サウンド
;
soundEnvelopeTable:
    
    .dw        0,    128,   256,   512,  1024,  2048,  4096,  8192, 16384, 32768

soundToneFrequencyPsgTable:

    .dw     0x0000, 0x0000, 0x0d5d, 0x0c9c, 0x0be7, 0x0b3c, 0x0a9b, 0x0a02, 0x0a02, 0x0973, 0x08eb, 0x086b, 0x07f2, 0x0780, 0x0714, 0x06af  ; O1
    .dw     0x0000, 0x0714, 0x06af, 0x064e, 0x05f4, 0x059e, 0x054e, 0x0501, 0x0501, 0x04ba, 0x0476, 0x0436, 0x03f9, 0x03c0, 0x038a, 0x0357  ; O2
    .dw     0x0000, 0x038a, 0x0357, 0x0327, 0x02fa, 0x02cf, 0x02a7, 0x0281, 0x0281, 0x025d, 0x023b, 0x021b, 0x01fd, 0x01e0, 0x01c5, 0x01ac  ; O3
    .dw     0x0000, 0x01c5, 0x01ac, 0x0194, 0x017d, 0x0168, 0x0153, 0x0140, 0x0140, 0x012e, 0x011d, 0x010d, 0x00fe, 0x00f0, 0x00e3, 0x00d6  ; O4
    .dw     0x0000, 0x00e3, 0x00d6, 0x00ca, 0x00be, 0x00b4, 0x00aa, 0x00a0, 0x00a0, 0x0097, 0x008f, 0x0087, 0x007f, 0x0078, 0x0071, 0x006b  ; O5
    .dw     0x0000, 0x0071, 0x006b, 0x0065, 0x005f, 0x005a, 0x0055, 0x0050, 0x0050, 0x004c, 0x0047, 0x0043, 0x0040, 0x003c, 0x0039, 0x0035  ; O6
    .dw     0x0000, 0x0039, 0x0035, 0x0032, 0x0030, 0x002d, 0x002a, 0x0028, 0x0028, 0x0026, 0x0024, 0x0022, 0x0020, 0x001e, 0x001c, 0x001b  ; O7
    .dw     0x0000, 0x001c, 0x001b, 0x0019, 0x0018, 0x0016, 0x0015, 0x0014, 0x0014, 0x0013, 0x0012, 0x0011, 0x0010, 0x000d, 0x000e, 0x000d  ; O8

soundNoiseFrequencyTable:
    
    .db      0,  1,  2,  4,  8, 12, 16, 20, 24, 31

soundLengthTable:
    
    .db     1       ; T1 L0 32
    .db     2       ; T1 L1 16
    .db     3       ; T1 L2 16.
    .db     4       ; T1 L3  8
    .db     6       ; T1 L4  8.
    .db     8       ; T1 L5  4
    .db     12      ; T1 L6  4.
    .db     16      ; T1 L7  2
    .db     24      ; T1 L8  2.
    .db     32      ; T1 L9  1
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     2       ; T2 L0 32
    .db     4       ; T2 L1 16
    .db     6       ; T2 L2 16.
    .db     8       ; T2 L3  8
    .db     12      ; T2 L4  8.
    .db     16      ; T2 L5  4
    .db     24      ; T2 L6  4.
    .db     32      ; T2 L7  2
    .db     48      ; T2 L8  2.
    .db     64      ; T2 L9  1
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     3       ; T3 L0 32
    .db     6       ; T3 L1 16
    .db     9       ; T3 L2 16.
    .db     12      ; T3 L3  8
    .db     18      ; T3 L4  8.
    .db     24      ; T3 L5  4
    .db     36      ; T3 L6  4.
    .db     48      ; T3 L7  2
    .db     72      ; T3 L8  2.
    .db     96      ; T3 L9  1
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     4       ; T4 L0 32
    .db     8       ; T4 L1 16
    .db     12      ; T4 L2 16.
    .db     16      ; T4 L3  8
    .db     24      ; T4 L4  8.
    .db     32      ; T4 L5  4
    .db     48      ; T4 L6  4.
    .db     64      ; T4 L7  2
    .db     96      ; T4 L8  2.
    .db     128     ; T4 L9  1
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     5       ; T5 L0 32
    .db     10      ; T5 L1 16
    .db     15      ; T5 L2 16.
    .db     20      ; T5 L3  8
    .db     30      ; T5 L4  8.
    .db     40      ; T5 L5  4
    .db     60      ; T5 L6  4.
    .db     80      ; T5 L7  2
    .db     120     ; T5 L8  2.
    .db     160     ; T5 L9  1
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     6       ; T6 L0 32
    .db     12      ; T6 L1 16
    .db     18      ; T6 L2 16.
    .db     24      ; T6 L3  8
    .db     32      ; T6 L4  8.
    .db     48      ; T6 L5  4
    .db     72      ; T6 L6  4.
    .db     96      ; T6 L7  2
    .db     144     ; T6 L8  2.
    .db     192     ; T6 L9  1
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     7       ; T7 L0 32
    .db     14      ; T7 L1 16
    .db     21      ; T7 L2 16.
    .db     28      ; T7 L3  8
    .db     42      ; T7 L4  8.
    .db     56      ; T7 L5  4
    .db     84      ; T7 L6  4.
    .db     112     ; T7 L7  2
    .db     168     ; T7 L8  2.
    .db     224     ; T7 L9  1
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     8       ; T8 L0 32
    .db     16      ; T8 L1 16
    .db     24      ; T8 L2 16.
    .db     32      ; T8 L3  8
    .db     48      ; T8 L4  8.
    .db     64      ; T8 L5  4
    .db     96      ; T8 L6  4.
    .db     128     ; T8 L7  2
    .db     192     ; T8 L8  2.
    .db     0       ; T8 L9  1
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     1       ;
    .db     1       ;

soundMmlProc:

    .dw     SystemUpdateSoundMmlAt
    .dw     SystemUpdateSoundMmlA
    .dw     SystemUpdateSoundMmlA
    .dw     SystemUpdateSoundMmlA
    .dw     SystemUpdateSoundMmlA
    .dw     SystemUpdateSoundMmlA
    .dw     SystemUpdateSoundMmlA
    .dw     SystemUpdateSoundMmlA
    .dw     SystemUpdateSoundMmlNull
    .dw     SystemUpdateSoundMmlNull
    .dw     SystemUpdateSoundMmlNull
    .dw     SystemUpdateSoundMmlNull
    .dw     SystemUpdateSoundMmlL
    .dw     SystemUpdateSoundMmlM
    .dw     SystemUpdateSoundMmlN
    .dw     SystemUpdateSoundMmlO
    .dw     SystemUpdateSoundMmlNull
    .dw     SystemUpdateSoundMmlNull
    .dw     SystemUpdateSoundMmlR
    .dw     SystemUpdateSoundMmlS
    .dw     SystemUpdateSoundMmlT
    .dw     SystemUpdateSoundMmlNull
    .dw     SystemUpdateSoundMmlV
    .dw     SystemUpdateSoundMmlNull
    .dw     SystemUpdateSoundMmlX
    .dw     SystemUpdateSoundMmlNull
    .dw     SystemUpdateSoundMmlNull


; DATA 領域
;
    .area   _DATA

; 変数の定義
;

; フラグ
;
_flag::
    
    .ds     0x01

; スロット
;
_slot::

    .ds     SLOT_SIZE

; キー入力
;
_input::
    
    .ds     INPUT_SIZE

; ビデオ
;
_videoPort::
    
    .ds     0x02

_videoRegister::
    
    .ds     0x08

; スプライト
;
_sprite::
    
    .ds     0x80

; パターンネーム
;
_patternName::

    .ds     40 * 24

; サウンド
;
_sound::

    .ds     SOUND_SIZE

_soundChannel::

    .ds     SOUND_CHANNEL_SIZE * SOUND_CHANNEL_ENTRY

; 転送
;
_transfer::

    .ds     0x02

; 乱数
;
random:
    
    .ds     0x02

; デバッグ
;
_debug::

    .ds     DEBUG_SIZE
