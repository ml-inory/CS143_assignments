/* File:  scanner.l
 * ----------------
 * Lex input file to generate the scanner for the compiler.
 */

%{

/* The text within this first region delimited by %{ and %} is assumed to
 * be C/C++ code and will be copied verbatim to the lex.yy.c file ahead
 * of the definitions of the yylex() function. Add other header file inclusions
 * or C++ variable declarations/prototypes that are needed by your code here.
 */

#include <string.h>
#include "scanner.h"
#include "utility.h" // for PrintDebug()
#include "errors.h"

/* Global variable: yylval
 * -----------------------
 * This global variable is how we get attribute information about the token
 * just scanned to the client. The scanner sets the global variable
 * appropriately and since it's global the client can just read it.  In the
 * future, this variable will be declared for us in the y.tab.c file
 * produced by Yacc, but for now, we declare it manually.
 */
YYSTYPE yylval;  // manually declared for pp1, later Yacc provides

/* Global variable: yylloc
 * -----------------------
 * This global variable is how we get position information about the token
 * just scanned to the client. (Operates similarly to yylval above)
 */
struct yyltype yylloc; // manually dclared for pp1, later Yacc provides

/* Macro: YY_USER_ACTION 
 * ---------------------
 * This flex built-in macro can be defined to provide an action which is
 * always executed prior to any matched rule's action. Basically, it is
 * a way of having a piece of code common to all actions factored out to
 * this routine.  We already defined it for you and left the empty
 * function DoBeforeEachAction ready for your use as needed. It will
 * be called once for each pattern scanned from the file, before
 * executing its action.
 */
static void DoBeforeEachAction(); 
#define YY_USER_ACTION DoBeforeEachAction();

static void NewLine()
{
    yylloc.first_column = yylloc.last_column = 0; 
    yylloc.first_line++;
}

static void DealWithStringError()
{
    int have_newline = 0;
    char* err_str = strdup(yytext); 
    if (yytext[yyleng-1] == '\n')
    {
        have_newline = 1;
        err_str[yyleng-1] = '\0'; 
        yylloc.first_line--;
    }
    ReportError::UntermString(&yylloc, err_str); 
    free(err_str);
    if (have_newline)
        NewLine();
}

static void DealWithSpace()
{
    yylloc.first_column += yyleng;
    yylloc.last_column = yylloc.first_column;
}

static void DealWithTab()
{
    yylloc.first_column += yyleng * 4;
    yylloc.last_column = yylloc.first_column;
}

static void DealWithLinuxNewLine()
{
    for (int i = 0; i < yyleng; i++)
        NewLine();
}

static void DealWithWinNewLine()
{
    for (int i = 0; i < yyleng / 2; i++)
        NewLine();
}

%}

 /* The section before the first %% is the Definitions section of the lex
  * input file. Here is where you set options for the scanner, define lex
  * states, and can set up definitions to give names to regular expressions
  * as a simple substitution mechanism that allows for more readable
  * entries in the Rules section later. 
  */
INT_CONSTANT_10     [0-9]+
INT_CONSTANT_16     0(x|X)[0-9A-Fa-f]+
INT_CONSTANT_8      0[0-9]+
DOUBLE_CONSTANT     [0-9]+"\."[0-9]*("E\+"[0-9]+)?
STRING_CONSTANT     \"[^(\"|\n)]*\"
COMMENT             "//".*|"/*"([^*]|(\*+[^*/]))*\*+\/
IDENTIFIER          [A-Za-z]+([A-Za-z]*"_"*[0-9]*)*
ONE_CHAR            "+"|"-"|"*"|"/"|"%"|"<"|">"|"="|"!"|";"|","|"\."|"["|"]"|"("|")"|"{"|"}"
SPACES              " "*"\t"*
NEWLINE             "\n"*"\r\n"*

%%             /* BEGIN RULES SECTION */
 /* All patterns and actions should be placed between the start and stop
  * %% markers which delimit the Rules section. 
  */ 
{COMMENT}           { continue; }
{SPACES}            { continue; }
{NEWLINE}           { continue; }
"void"              { return T_Void; }
"int"               { return T_Int; }
"double"            { return T_Double; }
"bool"              { return T_Bool; }
"string"            { return T_String; }
"class"             { return T_Class; }
"interface"         { return T_Interface; }
"null"              { return T_Null; }
"this"              { return T_This; }
"extends"           { return T_Extends; }
"implements"        { return T_Implements; }
"for"               { return T_For; }
"while"             { return T_While; }
"if"                { return T_If; }
"else"              { return T_Else; }
"return"            { return T_Return; }
"break"             { return T_Break; }
"new"               { return T_New; }
"NewArray"          { return T_NewArray; }
"Print"             { return T_Print; }
"ReadInteger"       { return T_ReadInteger; }
"ReadLine"          { return T_ReadLine; }
"true"              { yylval.boolConstant = true; return T_BoolConstant; }
"false"             { yylval.boolConstant = false; return T_BoolConstant; }
{INT_CONSTANT_10}   { yylval.integerConstant = (int)strtol(yytext, NULL, 10); return T_IntConstant; }
{INT_CONSTANT_16}   { yylval.integerConstant = (int)strtol(yytext, NULL, 16); return T_IntConstant; }
{INT_CONSTANT_8}    { yylval.integerConstant = (int)strtol(yytext, NULL, 8); return T_IntConstant; }
{DOUBLE_CONSTANT}   { yylval.doubleConstant = strtod(yytext, NULL); return T_DoubleConstant; }
{STRING_CONSTANT}   { yylval.stringConstant = strdup(yytext); return T_StringConstant; }
{ONE_CHAR}          { return yytext[0]; }
"<="                { return T_LessEqual; }
">="                { return T_GreaterEqual; }
"=="                { return T_Equal; }
"!="                { return T_NotEqual; }
"&&"                { return T_And; }
"||"                { return T_Or; }
"[]"                { return T_Dims; }
{IDENTIFIER}        { if (yyleng > MaxIdentLen) ReportError::LongIdentifier(&yylloc, yytext); strncpy(yylval.identifier, yytext, MaxIdentLen); return T_Identifier; }
"/\*"               { ReportError::UntermComment(); }
\"[^(\"|\n)]*($|\n) { DealWithStringError(); }
[^({ONE_CHAR})]     { ReportError::UnrecogChar(&yylloc, yytext[0]); }

%%
/* The closing %% above marks the end of the Rules section and the beginning
 * of the User Subroutines section. All text from here to the end of the
 * file is copied verbatim to the end of the generated lex.yy.c file.
 * This section is where you put definitions of helper functions.
 */


/* Function: InitScanner
 * ---------------------
 * This function will be called before any calls to yylex().  It is designed
 * to give you an opportunity to do anything that must be done to initialize
 * the scanner (set global variables, configure starting state, etc.). One
 * thing it already does for you is assign the value of the global variable
 * yy_flex_debug that controls whether flex prints debugging information
 * about each token and what rule was matched. If set to false, no information
 * is printed. Setting it to true will give you a running trail that might
 * be helpful when debugging your scanner. Please be sure the variable is
 * set to false when submitting your final version.
 */
void InitScanner()
{
    PrintDebug("lex", "Initializing scanner");
    yy_flex_debug = false;
}


/* Function: DoBeforeEachAction()
 * ------------------------------
 * This function is installed as the YY_USER_ACTION. This is a place
 * to group code common to all actions.
 */
static void DoBeforeEachAction()
{
    // PrintDebug("lex", "%d:%d:%d:    ", yylloc.first_line, yylloc.first_column, yylloc.last_column);
    if (yylloc.first_line == 0)
    {
        yylloc.first_line = 1;
        yylloc.last_line = 1;
    }
        
    yylloc.first_column = yylloc.last_column;

    if (yytext[0] == ' ')
        DealWithSpace();
    else if (yytext[0] == '\t')
        DealWithTab();
    else if (yytext[0] == '\n')
        DealWithLinuxNewLine();
    else if (yytext[0] == '\r')
        DealWithWinNewLine();
    else
    {
        // if (yylloc.first_column == 0)
        //     yylloc.first_column = 1;
        yylloc.first_column++;
        // if (yyleng == 1)
        // {
        //     yylloc.last_column++;
        //     yylloc.first_column = yylloc.last_column;
        // }
        // else
            yylloc.last_column = yylloc.first_column + yyleng - 1;
        for (int i = 0; i < yyleng; i++)
        {
            if (yytext[i] == '\n')
                NewLine();
        }
    }
}
