%{
#include "q1.tab.h"
%}

%%
"("         { return LPAREN; }
")"         { return RPAREN; }
"nil"       { return NIL; }
[0-9]+      { yylval.ival = atoi(yytext); return NUMBER; }
\n          { return NEWLINE; }
[ \t]+      { /* ignore whitespace (but not newlines) */ }
.           { printf("Lexical Error: Unexpected character %s\n", yytext); }
%%

int yywrap() {
    return 1;
}