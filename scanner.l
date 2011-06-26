/* File:  scanner.l
 * ----------------
 * Lex inupt file to generate the scanner for the compiler.
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

#define LEXEME_FMT "%-10s"
#define TOKEN_FMT  "%s"

/* Function: PrintTokenType
 * -----------------------------------
 * This function prints out the specified token type's token name from the
 * gTokenNames array, along with the lexeme just scanned
 */
static void PrintTokenType(TokenType token_type)
{
	printf(LEXEME_FMT " " TOKEN_FMT "\n", yytext,
	       gTokenNames[token_type - T_Void]);
}

/* Function: PrintSingleCharToken
 * ------------------------------
 * This function prints out the specified single character token, along with
 * the lexeme just scanned
 */
static void PrintSingleCharToken(int token)
{
	printf(LEXEME_FMT " %c\n", yytext, token);
}

/* Function: PrintTokenTypeConstant
 * --------------------------------
 * This function prints out the specified token type's token name from the
 * gTokenNames array, the lexeme just scanned, and the appropriate field of
 * yylval
 */
static void PrintTokenTypeConstant(TokenType token_type)
{
	printf(LEXEME_FMT " " TOKEN_FMT " ", yytext,
	       gTokenNames[token_type - T_Void]);

	switch (token_type) {
	case T_IntConstant:
		printf("(value = %i)\n", yylval.integerConstant);
		break;
	case T_DoubleConstant:
		printf("(value = %f)\n", yylval.doubleConstant);
		break;
	case T_BoolConstant:
		printf("(value = %s)\n", yylval.boolConstant ? "true" :
		                                               "false");
		break;
	case T_StringConstant:
		printf("(value = %s)\n", yylval.stringConstant);
		break;
	default:
		/* This case should never occur. If it does, Assert because we
		 * have a problem.
		 */
		Assert(0);
		break;
	}
}

%}

 /* The section before the first %% is the Definitions section of the lex
  * input file. Here is where you set options for the scanner, define lex
  * states, and can set up definitions to give names to regular expressions
  * as a simple substitution mechanism that allows for more readable
  * entries in the Rules section later.
  */

DEC_DIGIT [0-9]
HEX_DIGIT [0-9a-fA-F]
LETTER [a-zA-Z]

%%             /* BEGIN RULES SECTION */
 /* All patterns and actions should be placed between the start and stop
  * %% markers which delimit the Rules section.
  */

 /* Recognize all keywords and return the correct token from scanner.h
  * The following are keywords. They are all reserved, which means they cannot
  * be used as identifiers or redefined.
  *         void int double bool string class interface null this extends
  *         implements for while if else return break new NewArray Print
  *         ReadInteger Readline
  */
void        PrintTokenType(T_Void);
int         PrintTokenType(T_Int);
double      PrintTokenType(T_Double);
bool        PrintTokenType(T_Bool);
string      PrintTokenType(T_String);
class       PrintTokenType(T_Class);
interface   PrintTokenType(T_Interface);
null        PrintTokenType(T_Null);
this        PrintTokenType(T_This);
extends     PrintTokenType(T_Extends);
implements  PrintTokenType(T_Implements);
for         PrintTokenType(T_For);
while       PrintTokenType(T_While);
if          PrintTokenType(T_If);
else        PrintTokenType(T_Else);
return      PrintTokenType(T_Return);
break       PrintTokenType(T_Break);
new         PrintTokenType(T_New);
NewArray    PrintTokenType(T_NewArray);
Print       PrintTokenType(T_Print);
ReadInteger PrintTokenType(T_ReadInteger);
ReadLine    PrintTokenType(T_ReadLine);

 /* Recognize punctuation and single-char operators and return the ASCII value
  * as the token.
  * Operator and punctuation characters used by the language includes:
  *        + - * / % \ < <= > >= = == != && || ! ; , . [] [ ] ( ) { }
  */
"+"  PrintSingleCharToken('+');
"-"  PrintSingleCharToken('-');
"*"  PrintSingleCharToken('*');
"/"  PrintSingleCharToken('/');
"%"  PrintSingleCharToken('%');
"\\" PrintSingleCharToken('\\');
"<"  PrintSingleCharToken('<');
">"  PrintSingleCharToken('>');
"="  PrintSingleCharToken('=');
"!"  PrintSingleCharToken('!');
";"  PrintSingleCharToken(';');
","  PrintSingleCharToken(',');
"."  PrintSingleCharToken('.');
"["  PrintSingleCharToken('[');
"]"  PrintSingleCharToken(']');
"("  PrintSingleCharToken('(');
")"  PrintSingleCharToken(')');
"{"  PrintSingleCharToken('{');
"}"  PrintSingleCharToken('}');

 /* Recognize two-character operators and return the correct token.
  * See above for operators and punctuation used by the language.
  */
"<=" PrintTokenType(T_LessEqual);
">=" PrintTokenType(T_GreaterEqual);
"==" PrintTokenType(T_Equal);
"!=" PrintTokenType(T_NotEqual);
"&&" PrintTokenType(T_And);
"||" PrintTokenType(T_Or);
"[]" PrintTokenType(T_Dims);

 /* Recognize int, double, bool, and string constants, return the correct
  * token and set appropriate field of yylval
  */
 /* Recognize int constants
  * An integer constant can either be specified in decimal (base 10) or
  * hexadecimal (base 16). A decimal integer is a sequence of decimal digits. A
  * hexadecimal integer must begin with 0X or 0x (that is a zero, not the
  * letter oh) and is followed by a sequence of hexadecimal digits. Hexadecimal
  * digits include the decimal digits and the letters a through f (either upper
  * or lowercase). For example, the following are valid integers: 8, 012, 0x0,
  * 0X12aE.
  */
0[xX]{HEX_DIGIT}+|{DEC_DIGIT}+ {
	yylval.integerConstant = strtol(yytext, NULL, 0);
	PrintTokenTypeConstant(T_IntConstant);
}

 /* Recognize double constants
  * A double constant is a sequence of decimal digits, a period, followed by
  * any sequence of digist (maybe none). Thus .12 is not valid, but both 0.12
  * and 12. are. A double can also have an optional exponent, e.g., 12.2E+2.
  * For a double in this sort of scientific notation, the decimal point is
  * required, the sign of the exponent is optional (if not specified, a + is
  * assumed), and the E can be either lower or upper case. As above, .12E+2 is
  * invalid, but 12.E+2 is valid. Leading zeros on the mantissa and exponent
  * are allowed.
  */
{DEC_DIGIT}+\.{DEC_DIGIT}*([eE][-+]?{DEC_DIGIT}+)? {
	yylval.doubleConstant = strtod(yytext, NULL);
	PrintTokenTypeConstant(T_DoubleConstant);
}

 /* Recognize bool constants
  * A Boolean constant is either true or false. Like keywords, these words are
  * reserved.
  */
true|false {
	yylval.boolConstant = strcmp(yytext, "true") == 0 ? true : false;
	PrintTokenTypeConstant(T_BoolConstant);
}

 /* Recognize string constants
  * A string constant is a sequence of characters enclosed in couble quotes.
  * Strings can contain any character except a newline or double quote. A
  * string must start and end on a single line; it cannot be split over
  * multiple lines:
  *         "this string is missing its closing quote
  *          this is not part of the string above
  */
\"[^"]*\" {
	yylval.stringConstant = strdup(yytext);
	PrintTokenTypeConstant(T_StringConstant);
}

 /* Recognize identifiers, return the correct token and set appropriate fields
  * of yylval.
  * An identifier is a sequence of letters, digits, and underscores, starting
  * with a letter. Decaf is case-sensitive, e.g., if is a keyword, but IF is an
  * identifier; binky and Binky are two distinct identifiers. Identifiers can
  * be at most 31 characters long.
  */
{LETTER}({LETTER}*|{DEC_DIGIT}*|_*)* {
	strncpy(yylval.identifier, yytext, MaxIdentLen);
	/* Taken from man strncpy:
	 * "Warning: if there is no null byte amont the first n bytes of src,
	 *  the string placed in dest will not be null-terminated."
	 * Thus, we need to explicitly null terminate yylval.identifier just in
	 * case yytext is a string with length greater than MaxIdentLen.
	 */
	yylval.identifier[MaxIdentLen] = '\0';
	PrintTokenType(T_Identifier);
}

[ \t\n] ; /* Skip over white space */

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
}
