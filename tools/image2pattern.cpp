// g++ -o image2pattern `sdl2-config --cflags --libs` -lSDL2_image image2pattern.cpp

// 参照ファイルのインクルード
//
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>


// 内部関数の宣言
static SDL_Surface *LoadImage(const char *filename);
static int ConvertImage(SDL_Surface *image, const char *filename, const char *label);
static int ViewImage(SDL_Surface *image);

// メインプログラムのエントリ
//
int main(int argc, const char *argv[])
{
    // 入力ファイル名の初期化
    const char *inname = NULL;
    
    // 出力ファイル名の初期化
    const char *outname = NULL;

    // ラベルの初期化
    const char *label = NULL;
    
    // 表示の初期化
    bool view = false;

    // 引数の取得
    while (--argc > 0) {
        ++argv;
        if (strcasecmp(*argv, "-o") == 0) {
            outname = *++argv;
            --argc;
        } else if (strcasecmp(*argv, "-n") == 0) {
            label = *++argv;
            --argc;
        } else if (strcasecmp(*argv, "-v") == 0) {
            view = true;
        } else {
            inname = *argv;
        }
    }
    
    // 入力ファイルがない
    if (inname == NULL) {
        return -1;
    }

    // ラベルの作成
    if (label == NULL) {
        int length = strlen(inname);
        int i = length;
        while (i > 0 && inname[i - 1] != '/' && inname[i - 1] != '\\') {
            --i;
        }
        int j = i;
        while (j < length && inname[j] != '.') {
            ++j;
        }
        char *s = new char[j - i + 1];
        strncpy(s, &inname[i], j - i);
        s[j - i] = '\0';
        label = s;
    }

    // 処理の開始
    fprintf(stdout, "image2pattern ...\n");

    // SDL の初期化
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        fprintf(stderr, "error: %s\n", SDL_GetError());
        return -1;
    }

    // イメージの読み込み
    SDL_Surface *image = LoadImage(inname);
    if (image == NULL) {
        return -1;
    }

    // イメージの変換
    if (ConvertImage(image, outname, label) != 0) {
        return -1;
    }

    // イメージの表示
    if (view) {
        if (ViewImage(image) != 0) {
            return -1;
        }
    }

    // イメージの解放
    SDL_FreeSurface(image);

    // SDL の終了
    SDL_Quit();

    // 処理の完了
    fprintf(stdout, "done.\n");

    // 終了
    return 0;
}

// イメージを読み込む
//
static SDL_Surface *LoadImage(const char *filename)
{
    // イメージの読み込み
    SDL_Surface *image = IMG_Load(filename);
    if (image == NULL) {
        fprintf(stderr, "error: %s is not opened.\n", filename);
    } else {
        fprintf(stdout, "image file : %s\n", filename);
        fprintf(stdout, "image size : %d x %d\n", image->w, image->h);
    }
    return image;
}

// イメージを変換する
//
static int ConvertImage(SDL_Surface *image, const char *filename, const char *label)
{
    // キャラクタサイズの取得
    int c_width = (image->w + 7) / 8;
    int c_height = (image->h + 7) / 8;
    int c_size = 0;

    // ファイルへの出力
    {
        // 出力ファイルを開く
        FILE *outfile = filename != NULL ? fopen(filename, "w") : stdout;
        
        // ヘッダの出力
        fprintf(outfile, "; image2pattern\n;\n\n");
        
        // ラベルの出力
        fprintf(outfile, "    .module %s\n", label);
        fprintf(outfile, "    .area   _CODE\n\n");

        // サーフェイスのロック
        SDL_LockSurface(image);

        // キャラクタの出力
        fprintf(outfile, "_%s::\n\n", label);
        for (int c_y = 0; c_y < c_height; c_y++) {
            for (int c_x = 0; c_x < c_width; c_x++) {
                fprintf(outfile, "    .db     ");
                for (int p_y = 0; p_y < 8; p_y++) {
                    unsigned char bits = 0x00;
                    for (int p_x = 0; p_x < 8; p_x++) {
                        int x = c_x * 8 + p_x;
                        int y = c_y * 8 + p_y;
                        SDL_Color color = {0x00, 0x00, 0x00, 0x00, };
                        if (x < image->w && y < image->h) {
                            Uint32 pixel = 0x00000000;
                            Uint8 *p = (Uint8 *)image->pixels + y * image->pitch + x * image->format->BytesPerPixel;
                            if (image->format->BytesPerPixel == 0x01) {
                                pixel = (Uint32)*p;
                            } else if (image->format->BytesPerPixel == 0x02) {
                                pixel = (Uint32)*(Uint16 *)p;
                            } else if (image->format->BytesPerPixel == 0x03) {
                                if (SDL_BYTEORDER == SDL_BIG_ENDIAN) {
                                    pixel = (Uint32)(((Uint32)p[0] << 16) | ((Uint32)p[1] << 8) | (Uint32)p[2]);
                                } else {
                                    pixel = (Uint32)(((Uint32)p[2] << 16) | ((Uint32)p[1] << 8) | (Uint32)p[0]);
                                }
                            } else if (image->format->BytesPerPixel == 0x03) {
                                pixel = *(Uint32 *)p;
                            }
                            SDL_GetRGB(pixel, image->format, &color.r, &color.g, &color.b);
                        }
                        bits = bits << 1;
                        if (color.r != 0x00 || color.g != 0x00 || color.b != 0x00) {
                            bits = bits | 0x01;
                        }
                    }
                    fprintf(outfile, "0x%02x", bits);
                    if (p_y < 8 - 1) {
                        fprintf(outfile, ", ");
                    } else {
                        fprintf(outfile, "\n");
                    }
                }
                ++c_size;
            }
        }

        // サーフェイスの解除
        SDL_UnlockSurface(image);

        // フッタの出力
        fprintf(outfile, "\n\n");
        
        // 出力ファイルを閉じる
        if (outfile != stdout) {
            fclose(outfile);
        }

    }

    // 結果の表示
    {
        fprintf(stdout, "characters : %d\n", c_size);
    }

    // 終了
    return 0;
}

// イメージを表示する
//
static int ViewImage(SDL_Surface *image)
{
    // ウィンドウの作成
    SDL_Window *window = SDL_CreateWindow("image2pattern", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, image->w, image->h, SDL_WINDOW_SHOWN);
    if (window == NULL) {
        fprintf(stderr, "error: %s\n", SDL_GetError());
        return -1;
    }

    // サーフェイスの作成
    SDL_Surface *surface = SDL_GetWindowSurface(window);
    if (surface == NULL) {
        fprintf(stderr, "error: %s\n", SDL_GetError());
        return -1;
    }

    // イメージの描画
    SDL_BlitSurface(image, &image->clip_rect, surface, NULL);
    SDL_UpdateWindowSurface(window);

    // イベントのポーリング
    {
        SDL_Event event;
        bool quit = false;
        while (!quit){
            while (SDL_PollEvent(&event)){
                if (event.type == SDL_QUIT){
                    quit = true;
                }
            }
        }
    }
    
    // ウィンドウを閉じる
    SDL_DestroyWindow(window);

    // 終了
    return 0;
}

