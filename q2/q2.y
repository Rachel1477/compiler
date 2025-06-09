%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// --- C Declarations and Data Structures ---
extern int yylex();
void yyerror(const char *s);

// A node in a linked list to represent a set of variable names.
struct VarNode {
    char *name;
    struct VarNode *next;
};

// --- Helper Functions for our Linked List "Set" ---

// Function to check if a variable is in the list.
int find_var(struct VarNode *head, const char *name) {
    struct VarNode *current = head;
    while (current != NULL) {
        if (strcmp(current->name, name) == 0) {
            return 1;
        }
        current = current->next;
    }
    return 0;
}

// Function to add a variable to a list (if not already there).
struct VarNode* add_var(struct VarNode *head, char *name) {
    if (find_var(head, name)) {
        free(name);
        return head;
    }
    struct VarNode *newNode = (struct VarNode*) malloc(sizeof(struct VarNode));
    newNode->name = name;
    newNode->next = head;
    return newNode;
}

// Function to create a new list that is the union of two lists.
struct VarNode* union_sets(struct VarNode *set1, struct VarNode *set2) {
    struct VarNode *result = NULL;
    struct VarNode *current;
    current = set1;
    while (current != NULL) {
        result = add_var(result, strdup(current->name));
        current = current->next;
    }
    current = set2;
    while (current != NULL) {
        result = add_var(result, strdup(current->name));
        current = current->next;
    }
    return result;
}

// Function to free all memory used by a list.
void free_set(struct VarNode *head) {
    struct VarNode *current = head;
    while (current != NULL) {
        struct VarNode *temp = current;
        current = current->next;
        free(temp->name);
        free(temp);
    }
}


// --- Global State Variables ---
struct VarNode *defined_set = NULL;
struct VarNode *then_branch_start_set = NULL;

%}

/* --- Bison Declarations --- */
%union {
    char *sval;
    struct VarNode *var_list;
}

%token <sval> VAR
%token INT_CONST
%token IF THEN ELSE FI EQ SEMI PLUS LT

%type <var_list> expr

/*
 * --- PRECEDENCE RULES TO RESOLVE CONFLICTS ---
 * Operators on the same line have the same precedence.
 * Lines lower in the list have higher precedence.
 * %left means left-associative (e.g., a-b-c is (a-b)-c).
 * This resolves all shift/reduce conflicts.
 */
%left SEMI      /* Lowest precedence, for statement sequences */
%left ELSE      /* Handles the if-then-else ambiguity */
%left LT        /* '<' has lower precedence than '+' */
%left PLUS      /* '+' has highest precedence */


%%
/* --- Grammar Rules with Semantic Actions --- */

program:
    stmt
    ;

stmt:
    /* Assignment: var = expr */
    VAR EQ expr
    {
        struct VarNode *current_var = $3;
        while (current_var != NULL) {
            if (!find_var(defined_set, current_var->name)) {
                printf("Error: variable '%s' may be undefined.\n", current_var->name);
            }
            current_var = current_var->next;
        }
        free_set($3);
        defined_set = add_var(defined_set, $1);
    }

    /* Sequence: stmt ; stmt */
    | stmt SEMI stmt
    {
        /* No action needed. Associativity is set by %left SEMI. */
        /* State flows naturally from left ($1) to right ($3).   */
    }

    /* Conditional statement */
    | IF expr
    {
        // Mid-rule action 1: After parsing the condition `expr`
        struct VarNode *current_var = $2;
        while (current_var != NULL) {
            if (!find_var(defined_set, current_var->name)) {
                printf("Error: variable '%s' in 'if' condition may be undefined.\n", current_var->name);
            }
            current_var = current_var->next;
        }
        free_set($2);

        // Save the state *before* the 'then' branch.
        if (then_branch_start_set) free_set(then_branch_start_set);
        then_branch_start_set = union_sets(NULL, defined_set);
    }
    THEN stmt
    {
        // Mid-rule action 2: After parsing the `then` branch
        struct VarNode *then_result = defined_set;
        defined_set = then_branch_start_set;
        then_branch_start_set = then_result;
    }
    ELSE stmt
    {
        // Mid-rule action 3: After parsing the `else` branch
        struct VarNode *final_set = union_sets(defined_set, then_branch_start_set);
        free_set(defined_set);
        free_set(then_branch_start_set);
        defined_set = final_set;
        then_branch_start_set = NULL;
    }
    FI
    ;

expr:
    expr PLUS expr
    {
        $$ = union_sets($1, $3);
        free_set($1);
        free_set($3);
    }
    | expr LT expr
    {
        $$ = union_sets($1, $3);
        free_set($1);
        free_set($3);
    }
    | VAR
    {
        $$ = NULL;
        $$ = add_var($$, $1);
    }
    | INT_CONST
    {
        $$ = NULL;
    }
    ;

%%
/* --- C Code Section --- */

int main(void) {
    if (yyparse() == 0) {
        printf("\nParsing completed successfully.\n");
        printf("Variables defined at the end: { ");
        struct VarNode* current = defined_set;
        while(current) {
            printf("%s ", current->name);
            current = current->next;
        }
        printf("}\n");
    } else {
        printf("\nParsing failed.\n");
    }
    free_set(defined_set);
    return 0;
}

void yyerror(const char *s) {
    fprintf(stderr, "%s\n", s);
}