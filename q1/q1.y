%{
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

void yyerror(const char *s);
int yylex(void);
%}

%union {
    int ival;
    struct {
        int min_val;
        int max_val;
        int is_ordered;
    } btree_attrs;
}

%token <ival> NUMBER
%token LPAREN RPAREN NIL
%token NEWLINE // <-- Declare the new token

%type <btree_attrs> btree

%start program

%%

/* A program is a sequence of trees, each ending with a newline */
program:
    /* A program can be empty */
    | program btree NEWLINE {
        // NOTE: The btree is now the second symbol ($2), not the first ($1)
        if ($2.is_ordered) {
            printf(" -> Result: The binary tree IS ordered.\n");
        } else {
            printf(" -> Result: The binary tree IS NOT ordered.\n");
        }
    }
    ;

btree:
    NIL {
        $$.is_ordered = 1;
        $$.min_val = INT_MAX;
        $$.max_val = INT_MIN;
    }
    | LPAREN NUMBER btree btree RPAREN {
        int root_val = $2;
        int left_ok = ($3.max_val <= root_val);
        int right_ok = ($4.min_val >= root_val);

        if ($3.is_ordered && $4.is_ordered && left_ok && right_ok) {
            $$.is_ordered = 1;
        } else {
            $$.is_ordered = 0;
        }

        $$.min_val = ($3.min_val < root_val) ? $3.min_val : root_val;
        $$.max_val = ($4.max_val > root_val) ? $4.max_val : root_val;
    }
    ;

%%

void yyerror(const char *s) {
    // Make error reporting a bit more helpful
    fprintf(stderr, "Parse Error: %s. Waiting for next line.\n", s);
}

int main(void) {
    printf("Enter linearized binary trees, one per line.\n");
    printf("Press EOF (Ctrl+D on Linux, Ctrl+Z on Windows) to exit.\n");
    yyparse();
    printf("Exiting.\n");
    return 0;
}