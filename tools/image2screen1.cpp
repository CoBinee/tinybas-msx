// g++ -o image2screen1 `sdl2-config --cflags --libs` -lSDL2_image image2screen1.cpp

// 参照ファイルのインクルード
//
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <vector>
#include <map>
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>


// 内部関数の宣言
static SDL_Surface *LoadImage(const char *filename);
static SDL_Surface *ConvertImage(SDL_Surface *image, const char *filename, const char *label, unsigned char base);
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
    const char *label = "image";
    
    // ベースの初期化
    unsigned char base = 0x40;

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
        } else if (strcasecmp(*argv, "-b") == 0) {
            base = (unsigned char)strtol(*++argv, NULL, 0);
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

    // 処理の開始
    fprintf(stdout, "image2screen1 ...\n");

    // SDL の初期化
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        fprintf(stderr, "error: %s\n", SDL_GetError());
        return -1;
    }

    // イメージの読み込み
    SDL_Surface *inimage = LoadImage(inname);
    if (inimage == NULL) {
        return -1;
    }

    // イメージの変換
    SDL_Surface *outimage = ConvertImage(inimage, outname, label, base);
    if (outimage == NULL) {
        return -1;
    }

    // イメージの表示
    if (view) {
        if (ViewImage(outimage) != 0) {
            return -1;
        }
    }

    // イメージの解放
    SDL_FreeSurface(outimage);
    SDL_FreeSurface(inimage);

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
    } else if (image->format->palette == NULL) {
        fprintf(stderr, "error: no palette.\n");
        image = NULL;
    } else if (image->format->BitsPerPixel != 8) {
        fprintf(stderr, "error: no 8 bits color palette.\n");
        image = NULL;
    } else {
        fprintf(stdout, "image file  : %s\n", filename);
        fprintf(stdout, "image size  : %d x %d\n", image->w, image->h);
        fprintf(stdout, "image color : %d bits, %d colors\n", image->format->BitsPerPixel, image->format->palette->ncolors);
    }
    return image;
}

// イメージを変換する
//
static SDL_Surface *ConvertImage(SDL_Surface *image, const char *filename, const char *label, unsigned char base)
{
    // ピクセルの取得
    unsigned char *pixels = (unsigned char *)image->pixels;

    // キャラクタサイズの取得
    int c_width = (image->w + 7) / 8;
    int c_height = (image->h + 7) / 8;

    // カラーの初期化
    std::vector<unsigned char> colors;

    // パターンの初期化
    std::vector<std::vector<unsigned char *> *> patterns;

    // ベースの初期化
    std::map<unsigned char, unsigned char> bases;

    // ネームの初期化
    int *names = new int[c_width * c_height];

    // キャラクタ単位の走査
    for (int c_y = 0; c_y < c_height; c_y++) {
        for (int c_x = 0; c_x < c_width; c_x++) {

            // 色の初期化
            unsigned char c_0 = pixels[(c_y * 8) * image->w + (c_x * 8)] & 0x0f;
            unsigned char c_1 = 0x00;
            unsigned char color = 0x00;

            // １キャラクタの走査
            unsigned char pattern[8];
            for (int p_y = 0; p_y < 8; p_y++) {
                pattern[p_y] = 0x00;
                for (int p_x = 0; p_x < 8; p_x++) {

                    // ピクセルの取得
                    int x = c_x * 8 + p_x;
                    int y = c_y * 8 + p_y;
                    unsigned char c = 0x00;
                    if (x < image->w && y < image->h) {
                        c = pixels[y * image->w + x] & 0x0f;
                    }
                    if (c == c_0) {
                        pattern[p_y] |= (1 << (7 - p_x));
                    } else {
                        c_1 = c;
                    }
                }
            }

            // 色の順番による反転
            if (c_0 < c_1) {
                unsigned char t = c_0;
                c_0 = c_1;
                c_1 = t;
                for (int i = 0; i < 8; i++) {
                    pattern[i] = ~pattern[i];
                }
            }
            color = (c_0 << 4) | c_1;
            
            // 色の検索
            int c_i = 0;
            while (c_i < colors.size()) {
                if (colors.at(c_i) == color) {
                    break;
                }
                ++c_i;
            }

            // 色が一致
            if (c_i < colors.size()) {

                // パターンの検索
                std::vector<unsigned char *> *v = patterns.at(c_i);
                int p_i = 0;
                while (p_i < v->size()) {
                    if (memcmp(v->at(p_i), pattern, 0x08) == 0) {
                        break;
                    }
                    ++p_i;
                }

                // 新しいパターン
                if (p_i >= v->size()) {
                    unsigned char *p = new unsigned char [8];
                    memcpy(p, pattern, 8);
                    v->push_back(p);
                }

                // ネームの設定
                names[c_y * c_width + c_x] = (color << 8) | p_i;

            // 新しい色
            } else {

                // 色の登録
                colors.push_back(color);

                // パターンの登録
                std::vector<unsigned char *> *v = new std::vector<unsigned char *>;
                unsigned char *p = new unsigned char [8];
                memcpy(p, pattern, 8);
                v->push_back(p);
                patterns.push_back(v);

                // ネームの設定
                names[c_y * c_width + c_x] = (color << 8) | 0x00;
            }
        }
    }

    // ベースの取得
    {
        int b = base;
        for (int i = 0; i < colors.size(); i++) {
            unsigned char c = colors.at(i);
            if (c != 0x00) {
                std::vector<unsigned char *> *v = patterns.at(i);
                bases.insert(std::make_pair(c, b));
                b += (v->size() + 7) & 0xf8;
            } else {
                bases.insert(std::make_pair(c, (unsigned char)0x00));
            }
        }
    }

    // ファイルへの出力
    {
        // 出力ファイルを開く
        FILE *outfile = filename != NULL ? fopen(filename, "w") : stdout;
        
        // ヘッダの出力
        fprintf(outfile, "; image2screen1\n;\n\n");
        
        // ラベルの出力
        fprintf(outfile, "    .module %s\n", label);
        fprintf(outfile, "    .area   _CODE\n\n");

        // カラーテーブルの出力
        {
            fprintf(outfile, "_%sColorTable::\n\n", label);
            for (int i = 0; i < colors.size(); i++) {
                unsigned char c = colors.at(i);
                if (c != 0x00) {
                    if ((c & 0xf0) == 0x00) {
                        c += 0x10;
                    }
                    if ((c & 0x0f) == 0x00) {
                        c += 0x01;
                    }
                    std::vector<unsigned char *> *v = patterns.at(i);
                    int size = (v->size() + 7) / 8;
                    fprintf(outfile, "    .db     ");
                    for (int j = 0; j < size; j++) {
                        fprintf(outfile, "0x%02x", c);
                        if (j < size - 1) {
                            fprintf(outfile, ", ");
                        } else {
                            fprintf(outfile, "\n");
                        }
                    }
                }
            }
            fprintf(outfile, "\n");
        }

        // パターンジェネレータの出力
        {
            fprintf(outfile, "_%sPatternGenerator::\n\n", label);
            for (int i = 0; i < colors.size(); i++) {
                if (colors.at(i) != 0x00) {
                    std::vector<unsigned char *> *v = patterns.at(i);
                    int size = v->size();
                    for (int j = 0; j < size; j++) {
                        unsigned char *p = v->at(j);
                        fprintf(outfile, "    .db     ");
                        for (int k = 0; k < 8; k++) {
                            fprintf(outfile, "0x%02x", p[k]);
                            if (k < 8 - 1) {
                                fprintf(outfile, ", ");
                            } else {
                                fprintf(outfile, "\n");
                            }
                        }
                    }
                    for (int j = size; j < ((size + 7) & 0xf8); j++) {
                        fprintf(outfile, "    .db     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00\n");
                    }
                }
            }
            fprintf(outfile, "\n");
        }

        // パターンネームの出力
        {
            fprintf(outfile, "_%sPatternName::\n\n", label);
            for (int y = 0; y < c_height; y++) {
                fprintf(outfile, "    .db     ");
                for (int x = 0; x < c_width; x++) {
                    int name = names[y * c_width + x];
                    unsigned char c = (unsigned char)((name >> 8) & 0xff);
                    unsigned char n = c != 0x00 ? (unsigned char)(name & 0xff) + bases.at(c) : 0x00;
                    fprintf(outfile, "0x%02x", n);
                    if (x < c_width - 1) {
                        fprintf(outfile, ", ");
                    } else {
                        fprintf(outfile, "\n");
                    }
                }
            }
            fprintf(outfile, "\n");
        }
    
        // フッタの出力
        fprintf(outfile, "\n\n");
        
        // 出力ファイルを閉じる
        if (outfile != stdout) {
            fclose(outfile);
        }
    }

    // 結果の表示
    {
        int total = 0;
        for (int i = 0; i < colors.size(); i++) {
            unsigned char c = colors.at(i);
            int size = patterns.at(i)->size();
            int t = c != 0x00 ? (int)(size + 7) / 8 : base / 8;
            fprintf(stdout, "color = 0x%02x, %3d chars, %2d tables\n", c, size, t);
            total += t;
        }
        fprintf(stdout, "total = ----, --- chars,%3d tables\n", total);
    }

    // イメージの再構築
    SDL_Surface *outimage = SDL_CreateRGBSurfaceWithFormat(0, c_width * 8, c_height * 8, 32, SDL_PIXELFORMAT_RGBA32);
    if (outimage != NULL) {
        if (SDL_LockSurface(outimage) == 0) {
            for (int c_y = 0; c_y < c_height; c_y++) {
                for (int c_x = 0; c_x < c_width; c_x++) {
                    int name = names[c_y * c_width + c_x];
                    unsigned char c = (unsigned char)((name >> 8) & 0xff);
                    if (c != 0x00) {
                        int c_i = 0;
                        while (colors.at(c_i) != c) {
                            ++c_i;
                        }
                        std::vector<unsigned char *> *v = patterns.at(c_i);
                        unsigned char *p = v->at(name & 0xff);
                        for (int p_y = 0; p_y < 8; p_y++) {
                            for (int p_x = 0; p_x < 8; p_x++) {
                                SDL_Color color;
                                if ((p[p_y] & (1 << (7 - p_x))) != 0) {
                                    color = image->format->palette->colors[(c >> 4) & 0x0f];
                                } else {
                                    color = image->format->palette->colors[c & 0x0f];
                                }
                                SDL_Rect rect = {c_x * 8 + p_x, c_y * 8 + p_y, 1, 1};
                                SDL_FillRect(outimage, &rect, SDL_MapRGB(outimage->format, color.r, color.g, color.b));
                            }
                        }
                    } else {
                        SDL_Rect rect;
                        rect.x = c_x * 8;
                        rect.y = c_y * 8;
                        rect.w = 8;
                        rect.h = 8;
                        SDL_FillRect(outimage, &rect, SDL_MapRGB(outimage->format, 0, 0, 0));
                    }
                }
            }
            SDL_UnlockSurface(outimage);
        }
    }

    // ネームの破棄
    delete[] names;

    // ベースの破棄
    ;

    // パターンの破棄
    for (int i = 0; i < patterns.size(); i++) {
        for (int j = 0; j < patterns.at(i)->size(); j++) {
            delete[] patterns.at(i)->at(j);
        }
        delete patterns.at(i);
    }

    // カラーの破棄
    ;

    // 終了
    return outimage;
}

// イメージを表示する
//
static int ViewImage(SDL_Surface *image)
{
    // ウィンドウの作成
    SDL_Window *window = SDL_CreateWindow("image2screen1", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, image->w, image->h, SDL_WINDOW_SHOWN);
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

