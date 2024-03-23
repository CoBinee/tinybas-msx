// 参照ファイルのインクルード
//
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>



// メインプログラムのエントリ
//
int main(int argc, const char *argv[])
{
    // 入力ファイル名の初期化
    const char *inname = NULL;
    
    // 出力ファイル名の初期化
    const char *outname = NULL;
    
    // 名前の初期化
    const char *name = NULL;

    // null 終端の初期化
    bool terminate = false;
    
    // 引数の取得
    while (--argc > 0) {
        ++argv;
        if (strcasecmp(*argv, "-o") == 0) {
            outname = *++argv;
            --argc;
        } else if (strcasecmp(*argv, "-n") == 0) {
            name = *++argv;
            --argc;
        } else if (strcasecmp(*argv, "-t") == 0) {
            terminate = true;
        } else {
            inname = *argv;
        }
    }
    
    // 入力ファイルがない
    if (inname == NULL) {
        return -1;
    }
    
    // 入力ファイルを開く
    FILE *infile = fopen(inname, "r");
    
    // 出力ファイルを開く
    FILE *outfile = outname != NULL ? fopen(outname, "w") : stdout;
    
    // ヘッダの出力
    fprintf(outfile, "; %s\n;\n\n", inname);
    
    // ラベルの出力
    if (name != NULL) {
        fprintf(outfile, "    .module %s\n", name);
        fprintf(outfile, "    .area   _CODE\n\n");
        fprintf(outfile, "_%s::\n\n", name);
    }
    
    // ファイルの読み込み
    char buffer[1024];
    char *s, c;
    while ((s = fgets(buffer, 1024, infile)) != NULL) {
        fprintf(outfile, "    .ascii  \"");
        while ((c = *s++) != '\0') {
            if (c == '\r') {
                if (*s == '\n') {
                    ++s;
                }
                fprintf(outfile, "\\n");
            } else if (c == '\n') {
                fprintf(outfile, "\\n");
            } else if (c == '\t') {
                fprintf(outfile, "\\t");
            } else if (c == '"') {
                fprintf(outfile, "\\042");
            } else if (c >= ' ') {
                fputc(c, outfile);
            }
        }
        fprintf(outfile, "\"\n");
    }

    //　null 終端の出力
    if (terminate == true) {
        fprintf(outfile, "    .db     0x00\n");
    }
    
    // フッタの出力
    fprintf(outfile, "\n\n");
    
    // 出力ファイルを閉じる
    if (outfile != stdout) {
        fclose(outfile);
    }
    
    // 入力ファイルを閉じる
    fclose(infile);

    // 終了
    return 0;
}


