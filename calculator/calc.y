%{
#include <assert.h>
#include <stdio.h>

static int Pop();
static void Push(int val);
static int Top();
%}

%token T_Int

%%

S   :   S E '\n'    { printf(" = %d\n", Top()); }
    |  
    ;

E   :   E '+' E     { Push(Pop() + Pop());  }
    |   E '-' E     { int op2 = Pop(); Push(Pop() - op2); }
    |   E '*' E     { Push(Pop() * Pop());  }
    |   E '/' E     { int op2 = Pop(); Push(Pop() / op2); }
    |   T_Int       { Push(yylval); }
    ;

%%

static int Stack[1000];
static int Count = 0;

static int Pop()
{
    assert(Count > 0);
    return Stack[--Count];
}

static void Push(int val)
{
    assert(Count < 1000);
    Stack[Count++] = val;
}

static int Top()
{
    assert(Count > 0 && Count < 1000);
    return Stack[Count - 1];
}

int main()
{
    return yyparse();
}