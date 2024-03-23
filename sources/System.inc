; System.inc : システムライブラリ
;


; マクロの定義
;

; フラグ
;
FLAG_H_TIMI_REQUEST_BIT     =   0x00
FLAG_H_TIMI_REQUEST         =   (1 << FLAG_H_TIMI_REQUEST_BIT)
FLAG_SOUND_UPDATE_BIT       =   0x01
FLAG_SOUND_UPDATE           =   (1 << FLAG_SOUND_UPDATE_BIT)
FLAG_SOUND_SLEEP_BIT        =   0x02
FLAG_SOUND_SLEEP            =   (1 << FLAG_SOUND_SLEEP_BIT)

; スロット
;
SLOT_PAGE1_IY               =   0x00
SLOT_PAGE1                  =   0x01
SLOT_SIZE                   =   0x02

; キー入力
;
INPUT_KEY_UP                =   0x00
INPUT_KEY_DOWN              =   0x01
INPUT_KEY_LEFT              =   0x02
INPUT_KEY_RIGHT             =   0x03
INPUT_BUTTON_SPACE          =   0x04
INPUT_BUTTON_SHIFT          =   0x05
INPUT_BUTTON_ESC            =   0x06
INPUT_BUTTON_STOP           =   0x07
INPUT_SIZE                  =   0x08

; ビデオ
;
VIDEO_TEXT1                                 =   0x00
VIDEO_TEXT1_PATTERN_NAME_TABLE              =   0x0000
VIDEO_TEXT1_PATTERN_GENERATOR_TABLE         =   0x0800
VIDEO_TEXT1_COLOR_TABLE                     =   0x0000
VIDEO_TEXT1_SPRITE_ATTRIBUTE_TABLE          =   0x1b00
VIDEO_TEXT1_SPRITE_GENERATOR_TABLE          =   0x3800
VIDEO_GRAPHIC1                              =   0x01
VIDEO_GRAPHIC1_PATTERN_NAME_TABLE           =   0x1800
VIDEO_GRAPHIC1_PATTERN_GENERATOR_TABLE      =   0x0000
VIDEO_GRAPHIC1_COLOR_TABLE                  =   0x2000
VIDEO_GRAPHIC1_SPRITE_ATTRIBUTE_TABLE       =   0x1b00
VIDEO_GRAPHIC1_SPRITE_GENERATOR_TABLE       =   0x3800
VIDEO_GRAPHIC2                              =   0x02
VIDEO_GRAPHIC2_PATTERN_NAME_TABLE           =   0x1800
VIDEO_GRAPHIC2_PATTERN_GENERATOR_TABLE      =   0x0000
VIDEO_GRAPHIC2_COLOR_TABLE                  =   0x2000
VIDEO_GRAPHIC2_SPRITE_ATTRIBUTE_TABLE       =   0x1b00
VIDEO_GRAPHIC2_SPRITE_GENERATOR_TABLE       =   0x3800
VIDEO_MULTICOLOR                            =   0x03
VIDEO_MULTICOLOR_PATTERN_NAME_TABLE         =   0x0800
VIDEO_MULTICOLOR_PATTERN_GENERATOR_TABLE    =   0x0000
VIDEO_MULTICOLOR_COLOR_TABLE                =   0x2000
VIDEO_MULTICOLOR_SPRITE_ATTRIBUTE_TABLE     =   0x1b00
VIDEO_MULTICOLOR_SPRITE_GENERATOR_TABLE     =   0x3800

; スプライト
;

; パターンネーム
;

; サウンド
;
SOUND_PSG_NOISE_FREQUENCY       =   0x00
SOUND_PSG_MIXER                 =   0x01
SOUND_PSG_ENVELOPE_FREQUENCY    =   0x02
SOUND_PSG_ENVELOPE_FREQUENCY_L  =   0x02
SOUND_PSG_ENVELOPE_FREQUENCY_H  =   0x03
SOUND_PSG_ENVELOPE_PATTERN      =   0x04
SOUND_FLAG                      =   0x05
SOUND_SIZE                      =   0x06
SOUND_CHANNEL_REQUEST           =   0x00
SOUND_CHANNEL_REQUEST_L         =   0x00
SOUND_CHANNEL_REQUEST_H         =   0x01
SOUND_CHANNEL_HEAD              =   0x02
SOUND_CHANNEL_HEAD_L            =   0x02
SOUND_CHANNEL_HEAD_H            =   0x03
SOUND_CHANNEL_PLAY              =   0x04
SOUND_CHANNEL_PLAY_L            =   0x04
SOUND_CHANNEL_PLAY_H            =   0x05
SOUND_CHANNEL_TEMPO             =   0x06
SOUND_CHANNEL_VOICE             =   0x07
SOUND_CHANNEL_VOICE_MASK        =   0x08
SOUND_CHANNEL_VOICE_TABLE       =   0x09
SOUND_CHANNEL_VOICE_TABLE_L     =   0x09
SOUND_CHANNEL_VOICE_TABLE_H     =   0x0a
SOUND_CHANNEL_VOLUME            =   0x0b
SOUND_CHANNEL_VOLUME_PLAY       =   0x0c
SOUND_CHANNEL_VOLUME_MINUS      =   0x0d
SOUND_CHANNEL_VOLUME_FRAME      =   0x0e
SOUND_CHANNEL_OCTAVE            =   0x0f
SOUND_CHANNEL_LENGTH            =   0x10
SOUND_CHANNEL_TONE_FREQUENCY    =   0x11
SOUND_CHANNEL_TONE_FREQUENCY_L  =   0x11
SOUND_CHANNEL_TONE_FREQUENCY_H  =   0x12
SOUND_CHANNEL_REST              =   0x13
SOUND_CHANNEL_MIXER_PSG         =   0x14
SOUND_CHANNEL_FLAG              =   0x15
SOUND_CHANNEL_SIZE              =   0x16
SOUND_CHANNEL_A                 =   (0x00 * SOUND_CHANNEL_SIZE)
SOUND_CHANNEL_B                 =   (0x01 * SOUND_CHANNEL_SIZE)
SOUND_CHANNEL_C                 =   (0x02 * SOUND_CHANNEL_SIZE)
SOUND_CHANNEL_D                 =   (0x03 * SOUND_CHANNEL_SIZE)
SOUND_CHANNEL_ENTRY             =   0x04
SOUND_CHANNEL_FLAG_NULL         =   0x00
SOUND_CHANNEL_FLAG_VOICE_BIT    =   0x04
SOUND_CHANNEL_FLAG_VOICE        =   (1 << SOUND_CHANNEL_FLAG_VOICE_BIT)
SOUND_CHANNEL_FLAG_ENVELOPE_BIT =   0x05
SOUND_CHANNEL_FLAG_ENVELOPE     =   (1 << SOUND_CHANNEL_FLAG_ENVELOPE_BIT)
SOUND_CHANNEL_FLAG_VOLUME_BIT   =   0x06
SOUND_CHANNEL_FLAG_VOLUME       =   (1 << SOUND_CHANNEL_FLAG_VOLUME_BIT)
SOUND_CHANNEL_FLAG_UPDATE_BIT   =   0x07
SOUND_CHANNEL_FLAG_UPDATE       =   (1 << SOUND_CHANNEL_FLAG_UPDATE_BIT)

; デバッグ
DEBUG_0                         =   0x00
DEBUG_1                         =   0x01
DEBUG_2                         =   0x02
DEBUG_3                         =   0x03
DEBUG_4                         =   0x04
DEBUG_5                         =   0x05
DEBUG_6                         =   0x06
DEBUG_7                         =   0x07
DEBUG_SIZE                      =   0x08

; 外部関数宣言
;

    ; システム
    .globl  _SystemBoot
    .globl  _SystemInitialize
    
    ; キー入力
    .globl  _SystemUpdateInput
    
    ; ビデオ
    .globl  _SystemUpdateVideo
    .globl  _SystemGetVideoPort
    
    ; スプライト
    .globl  _SystemUpdateSprite
    .globl  _SystemClearSprite
    
    ; パターンネーム
    .globl  _SystemUpdatePatternName
    .globl  _SystemClearPatternName
    
    ; サウンド
    .globl  _SystemUpdateSound
    .globl  _SystemStopSound
    .globl  _SystemSuspendSound
    .globl  _SystemResumeSound

    ; 乱数
    .globl  _SystemGetRandom

    ; CRC
    .globl  _SystemCalcCrc
    
; 外部変数宣言
;

    ; フラグ
    .globl  _flag
    
    ; スロット
    .globl  _slot
    
    ; キー入力
    .globl  _input
    
    ; ビデオ
    .globl  _videoPort
    .globl  _videoRegister

    ; スプライト
    .globl  _sprite

    ; パターンネーム
    .globl  _patternName
    
    ; サウンド
    .globl  _sound
    .globl  _soundChannel

    ; 転送
    .globl  _transfer

    ; デバッグ
    .globl  _debug
