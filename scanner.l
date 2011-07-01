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

/* Global variable: line_num
 * -------------------------
 * This global variable is how we keep track of the current line number being
 * scanned. This should be initialized in the InitScanner function and
 * incremented with each new line scanned.
 */
int line_num;

/* Global variable: first_col
 * --------------------------
 * This global variable is how we keep track of what column the current lexeme
 * starts at. This should be initialized in the InitScanner function and at
 * the start of every new line, along with being appropriately incremented
 * with every token.
 */
int first_col;

/* Global variable: last_col
 * ------------------------
 * This global variable is how we keep track of what column the current lexeme
 * ends at. This should be initialized in the InitScanner function and at the
 * start of every new line, along with being appropriately incremented with
 * every token.
 */
int last_col;

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

%x C_COMMENT

%%             /* BEGIN RULES SECTION */
 /* All patterns and actions should be placed between the start and stop
  * %% markers which delimit the Rules section.
  */

 /* Skip over comments */
 /* A single-line comment is started by // and extends to the end of the line.
  */
"//"[^\n]* ;

 /* C-style comments start with '/ *' (without the space character of course)
  * and end with the first subsequent '* /' (again, without the space
  * character). Any symbol is allowed in a comment except the sequence '* /'
  * (again, ignore the space character) which ends the current comment.
  * C-style comments do not nest.
  */
"/*" {
	BEGIN(C_COMMENT);
}
<C_COMMENT>"*/" {
	BEGIN(INITIAL);
}

 /* Recognize all keywords and return the correct token from scanner.h
  * The following are keywords. They are all reserved, which means they cannot
  * be used as identifiers or redefined.
  *         void int double bool string class interface null this extends
  *         implements for while if else return break new NewArray Print
  *         ReadInteger Readline
  */
void        return T_Void;
int         return T_Int;
double      return T_Double;
bool        return T_Bool;
string      return T_String;
class       return T_Class;
interface   return T_Interface;
null        return T_Null;
this        return T_This;
extends     return T_Extends;
implements  return T_Implements;
for         return T_For;
while       return T_While;
if          return T_If;
else        return T_Else;
return      return T_Return;
break       return T_Break;
new         return T_New;
NewArray    return T_NewArray;
Print       return T_Print;
ReadInteger return T_ReadInteger;
ReadLine    return T_ReadLine;

 /* Recognize punctuation and single-char operators and return the ASCII value
  * as the token.
  * Operator and punctuation characters used by the language includes:
  *        + - * / % < <= > >= = == != && || ! ; , . [] [ ] ( ) { }
  */
"+"  return '+';
"-"  return '-';
"*"  return '*';
"/"  return '/';
"%"  return '%';
"<"  return '<';
">"  return '>';
"="  return '=';
"!"  return '!';
";"  return ';';
","  return ',';
"."  return '.';
"["  return '[';
"]"  return ']';
"("  return '(';
")"  return ')';
"{"  return '{';
"}"  return '}';

 /* Recognize two-character operators and return the correct token.
  * See above for operators and punctuation used by the language.
  */
"<=" return T_LessEqual;
">=" return T_GreaterEqual;
"==" return T_Equal;
"!=" return T_NotEqual;
"&&" return T_And;
"||" return T_Or;
"[]" return T_Dims;

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
	return T_IntConstant;
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
	return T_DoubleConstant;
}

 /* Recognize bool constants
  * A Boolean constant is either true or false. Like keywords, these words are
  * reserved.
  */
true|false {
	yylval.boolConstant = strcmp(yytext, "true") == 0 ? true : false;
	return T_BoolConstant;
}

 /* Recognize string constants
  * A string constant is a sequence of characters enclosed in couble quotes.
  * Strings can contain any character except a newline or double quote. A
  * string must start and end on a single line; it cannot be split over
  * multiple lines:
  *         "this string is missing its closing quote
  *          this is not part of the string above
  */
\"[^"\n]*\"? {
	yylval.stringConstant = strdup(yytext);

	size_t len = strlen(yytext);
	/* If the length of the lexeme is equal to 1, then it is impossible for
	 * it to have matching double quotes. At lease two characters are
	 * needed for this (a length of 2 or more). Also, if the last character
	 * in the string is not a double quote, then the string does not
	 * contain it's terminating double quote. Report these errors if they
	 * are present, otherwise print the token string constant.
	 */
	if (len == 1 || yytext[len - 1] != '"')
		ReportError::UntermString(&yylloc, yytext);
	else
		return T_StringConstant;
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
	if (strlen(yytext) > MaxIdentLen)
		ReportError::LongIdentifier(&yylloc, yytext);
	return T_Identifier;
}

 /* Skip over white space */
<C_COMMENT,INITIAL>[ \t\n] {
	/* If we have encountered a newline character then increment the line
	 * number counter (hopefully this doesn't cause overflow issues). Also,
	 * reset the starting and ending column counters to their initial
	 * values.
	 */
	if (strcmp(yytext, "\n") == 0) {
		++line_num;
		first_col = 1;
		last_col = 1;
	}
}

<C_COMMENT><<EOF>> {
	ReportError::UntermComment();
	yyterminate();
}

 /* C-style comments can contain _any_ character except the terminal sequence.
  * Thus, skip over these characters that are within C-style comments.
  */
<C_COMMENT>. ;

 /* Report lexical errors for invalid characters */
. {
	ReportError::UnrecogChar(&yylloc, yytext[0]);
}

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
    /* Initialize the global line number counter. The first line in the source
     * input is labeled as line 1.
     */
    line_num = 1;
    /* Initialize the global starting and ending column counters. The first
     * column in each source line is labeled as column 1
     */
    first_col = 1;
    last_col = 1;
}


/* Function: DoBeforeEachAction()
 * ------------------------------
 * This function is installed as the YY_USER_ACTION. This is a place
 * to group code common to all actions.
 */
static void DoBeforeEachAction()
{
	first_col = last_col;
	last_col += strlen(yytext);

	yylloc.first_line = yylloc.last_line = line_num;
	yylloc.first_column = first_col;
	yylloc.last_column = last_col - 1;
}
