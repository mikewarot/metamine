%define parse.error verbose
%define api.pure true
%locations
%token-table
%glr-parser
%define api.value.type {struct node*}
%lex-param {void* scanner}

%parse-param {void** root}
%parse-param {char* waarom}
%parse-param {void* scanner}

%{
  #include <math.h>
	#include <stdbool.h>
  #include <stdio.h>
	#include <string.h>

	typedef struct node* YYSTYPE;

	#define YYLTYPE_IS_DECLARED
	typedef struct YYLTYPE  
	{  
		int first_line;  
		int first_column;  
		int last_line;  
		int last_column;  
	} YYLTYPE;

	#include "node.h"

	#include "lex.yy.h"

	int yyerror(YYLTYPE* loc, void** root, char* waarom, void* scanner, const char* yymsg);

	#define A(a) aloc(a,yylloc)
	#define APPEND(a,b) appendloc(a,b,yylloc)
	#define PREPEND(a,b) prependloc(a,b,yylloc)
	#define FN1(a) metloc(a,yylloc)
	#define FN2(a,b) fn2loc(a,b,yylloc)
	#define FN3(a,b,c) fn3loc(a,b,c,yylloc)
	

%}

%token '\n' RE "regeleinde"
%token NAAM "naam"
%token TEKST "tekst"
%token ALS "als"
%token DAN "dan"
%token ANDERS "anders"
%token NIN "!:"
%token SOM "som"
%token IMPLICEERT "=>"
%token TO "->"
%token MAPLET "-->"
%token ASS ":="
%token ISN "!="
%token INC "+="
%token CAT "||"
%token ICAT "::"
%token TIL ".."
%token CART "xx"
%token END 0 "invoereinde"
%token NEG '-'
%token GDGA ">="
%token ISB "~="
%token KDGA "<="
%token OUD '\''
%token TAB '\t' "tab"
%token EN "/\\"
%token OF "\\/"
%token NIET "niet"
%token JOKER "_"
%token EXOF "exof"
%token NOCH "noch"

/* %precedence NAAM TEKST */
%left ALS DAN ANDERS
%left "=>"
%left SOM
%left EN OF EXOF NOCH NIET
%left '=' "!=" "~="
%left ":=" "+=" "-=" "|=" "&="
%left '@'
%left ':' "!:"
%left "->" "-->"
%left ','
%left '<' '>' "<=" ">="
%left '&' '|'
%left "||" "::"
%left ".."
%left "xx"
%left '+' '-'
%nonassoc CALL
%left '*' '/'
%left NEG '#'
%right '^' '_'
%left OUD
%left '.'
%nonassoc '%' '\'' INV M0 M1 M2 M3 M4 MN I0 I1 I2 I3 I4
%left NAAM TEKST

%%

/* ALTERNATIEF */
input:
	%empty						{ *root = $$ = A("en"); }
|	input exp '\n' 		{ $$ = APPEND($1, $2);  } /* lees regeltje */
|	input exp '=' block '\n' 		{ $$ = APPEND($1, FN3(A("="), $2, $4));  } /* lees regeltje */
|	input error '\n' 	{ $$ = APPEND($1, metfout(A("?"), waarom)); yyerrok; } /* lees regeltje */
|	input '\n' 				/* negeer witregels */
|	error  						{ $$ = metfout(A("?"), waarom); yyerrok; }
;

/*op:
	'^' | '_' | '*' | '/' | '+' | '-'
| '[' ']' | '{' '}'
| "->" | "||" | ".." | "xx" | "=>"
| '=' | "!=" | "~=" | '>' | '<' | ">=" | "<="
| '|' | '&' | '#'
| ":=" | "+=" | "-=" | "|=" | "&="
| "en" | "of" | "exof" | "noch" | "niet"
| '.' | '@' | ':' | '!:' | ">>" | "<<"
;*/

single:
	NAAM 								{ $$ = metloc($1, @1); }
| TEKST								{ $$ = metloc($1, @1); }
| single '%'					{ $$ = FN2(A("%"), $1); }
| single '!'					{ $$ = FN2(A("faculteit"), $1); }
| single '\''					{ $$ = FN2(A("'"), $1); }
| single I0						{ $$ = FN2($1, A("0")); }
| single I1						{ $$ = FN2($1, A("1")); }
| single I2						{ $$ = FN2($1, A("2")); }
| single I3						{ $$ = FN2($1, A("3")); }
| single INV					{ $$ = FN2(A("inverteer"), $1); }
| single M0						{ $$ = FN3(A("^"), $1, A("0")); }
| single M1						{ $$ = FN3(A("^"), $1, A("1")); }
| single M2						{ $$ = FN3(A("^"), $1, A("2")); }
| single M3						{ $$ = FN3(A("^"), $1, A("3")); }
| single M4						{ $$ = FN3(A("^"), $1, A("4")); }
| single MN						{ $$ = FN3(A("^"), $1, A("n")); }
|	'(' exp ')'					{ $$ = metloc($2, @$); }
| '(' exp ',' exp ')'	{ $$ = fn3loc(A(","), $2, $4, @$); }
| '(' exp ',' exp ',' exp ')'	{ $$ = fn4loc(A(","), $2, $4, $6, @$); }
| '(' exp ',' exp ',' exp ',' exp ')'	{ $$ = fn5loc(A(","), $2, $4, $6, $8, @$); }
| '[' list ']'				{ $$ = metloc($2, @$); }
| '{' set '}'					{ $$ = metloc($2, @$); }
| '[' error 					{ $$ = metfout(A("?"), waarom); yyerrok; }
| '(' error 					{ $$ = metfout(A("?"), waarom); yyerrok; }
| '{' error 					{ $$ = metfout(A("?"), waarom); yyerrok; }

/*| '(' op ')'					{ $$ = $2; }*/

| '(' '^' ')'       	{ $$ = A("^"); }
| '(' '_' ')'       	{ $$ = A("_"); }
| '(' '*' ')'       	{ $$ = A("*"); }
| '(' '/' ')'       	{ $$ = A("/"); }
| '(' '+' ')'       	{ $$ = A("+"); }
| '(' '-' ')'       	{ $$ = A("-"); }

| '(' '[' ')'     { $$ = A("[]"); }
| '(' '{' '}' ')'     { $$ = A("{}"); }

| '(' "->" ')'				{ $$ = A("->"); }
| '(' "-->" ')'				{ $$ = A("-->"); }
| '(' "||" ')'				{ $$ = A("||"); }
| '(' "::" ')'				{ $$ = A("::"); }
| '(' ".." ')'				{ $$ = A(".."); }
| '(' "xx" ')'				{ $$ = A("xx"); }
| '(' "=>" ')'				{ $$ = A("=>"); }

| '(' '='	')'					{ $$ = A("="); }
| '(' "!=" ')'				{ $$ = A("!="); }
| '(' "~=" ')'				{ $$ = A("~="); }
| '(' '>' ')'					{ $$ = A(">"); }
| '(' '<' ')'					{ $$ = A("<"); }
| '(' ">=" ')'				{ $$ = A(">="); }
| '(' "<=" ')'				{ $$ = A("<="); }

| '(' '&' ')'				{ $$ = A("|"); }
| '(' '|' ')'				{ $$ = A("&"); }
| '(' '#' ')'       	{ $$ = A("#"); }

| '(' ":=" ')'				{ $$ = A(":="); }
| '(' "+=" ')'				{ $$ = A("+="); }
| '(' "-=" ')'				{ $$ = A("-="); }
| '(' "|=" ')'				{ $$ = A("|="); }
| '(' "&=" ')'				{ $$ = A("&="); }

| '(' "/\\" ')'				{ $$ = A("/\\"); }

| '(' "en" ')'				{ $$ = A("en"); }
| '(' "of" ')'				{ $$ = A("of"); }
| '(' "exof" ')'			{ $$ = A("exof"); }
| '(' "noch" ')'			{ $$ = A("noch"); }
| '(' "niet" ')'			{ $$ = A("niet"); }

| '(' '.' ')'       	{ $$ = A("."); }
| '(' '@' ')'       	{ $$ = A("@"); }
| '(' ':' ')'       	{ $$ = A(":"); }
| '(' "!:" ')'       	{ $$ = A("!:"); }
| '(' ">>" ')'       	{ $$ = A(">>"); }
| '(' "<<" ')'       	{ $$ = A("<<"); }

|	'(' error ')'				{ $$ = metfout(A("?"), waarom); yyerrok; }
|	'[' error ']'				{ $$ = metfout(A("?"), waarom); yyerrok; }
|	'{' error '}'				{ $$ = metfout(FN2(A("{}"), A("?")), waarom); yyerrok; }
;

blockline: '\n' TAB exp { $$ = $3; }
block:
	blockline						{ $$ = FN2(A("co"), $1); }
| block blockline			{ $$ = APPEND($1, $2); }
;

exp:

 single

/* als ... dan ... */
| ALS exp DAN exp %prec ALS													{ $$ = FN3(A("=>"), $2, $4); }
| ALS exp DAN '\n' TAB exp %prec ALS								{ $$ = FN3(A("=>"), $2, $6); }
| ALS exp '\n' TAB exp %prec ALS										{ $$ = FN3(A("=>"), $2, $5); }
| ALS '\n' TAB exp '\n' DAN '\n' TAB exp %prec ALS	{ $$ = FN3(A("=>"), $4, $9); }
/*
| ALS exp '\n' exp			{ $$ = FN3(A("=>"), $2, $4); }
*/

/* als ... dan ... anders */
/*
als exp
	b = 2
anders
	b = 3
*/
| ALS exp DAN '\n' exp '\n' ANDERS '\n' exp %prec ALS { $$ = FN3(A("/\\"), FN3(A("=>"), $2, $5), FN3(A("=>"), FN2(A("!"), $2), $9)); }

| exp '^' exp       	{ $$ = FN3(A("^"), $1, $3); }
| exp '_' exp       	{ $$ = FN3(A("_"), $1, $3); }
| exp '*' exp       	{ $$ = FN3(A("*"), $1, $3); }
| exp '/' exp       	{ $$ = FN3(A("/"), $1, $3); }
| exp '+' exp       	{ $$ = fn3loc(aloc("+", @2), $1, $3, @$); }
| exp '-' exp       	{ $$ = FN3(A("-"), $1, $3); }

| SOM exp			       	{ $$ = FN2(A("som"), $2); }
| exp "->" exp				{ $$ = FN3(A("->"), $1, $3); }
| exp "-->" exp				{ $$ = FN3(A("-->"), $1, $3); }
| exp "||" exp				{ $$ = FN3(A("||"), $1, $3); }
| exp "::" exp				{ $$ = FN3(A("::"), $1, $3); }
| exp ".." exp				{ $$ = FN3(A(".."), $1, $3); }
| exp "xx" exp				{ $$ = FN3(A("xx"), $1, $3); }
| exp "=>" exp				{ $$ = FN3(A("=>"), $1, $3); }

| exp '='	exp					{ $$ = fn3loc(aloc("=", @2), $1, $3, @$); }
| exp "!=" exp				{ $$ = FN3(A("!="), $1, $3); }
| exp "~=" exp				{ $$ = FN3(A("~="), $1, $3); }
| exp '>' exp					{ $$ = FN3(A(">"), $1, $3); }
| exp '<' exp					{ $$ = FN3(A("<"), $1, $3); }
| exp ">=" exp				{ $$ = FN3(A(">="), $1, $3); }
| exp "<=" exp				{ $$ = FN3(A("<="), $1, $3); }

| '#' exp							{ $$ = FN2(A("#"), $2); }
| exp '|' exp				{ $$ = FN3(A("|"), $1, $3); }
| exp '&' exp				{ $$ = FN3(A("&"), $1, $3); }

| exp ":=" exp				{ $$ = FN3(A(":="), $1, $3); }
| exp "+=" exp				{ $$ = FN3(A("+="), $1, $3); }
| exp "-=" exp				{ $$ = FN3(A("-="), $1, $3); }
| exp "|=" exp				{ $$ = FN3(A("|="), $1, $3); }
| exp "&=" exp				{ $$ = FN3(A("&="), $1, $3); }

| exp "/\\" exp				{ $$ = FN3(A("/\\"), $1, $3); }
| exp "\\/" exp				{ $$ = FN3(A("\\/"), $1, $3); }
| exp "exof" exp			{ $$ = FN3(A("xof"), $1, $3); }
| exp "noch" exp			{ $$ = FN3(A("noch"), $1, $3); }
| "niet" exp					{ $$ = FN2(A("!"), $2); }

| exp '.' exp       	{ $$ = FN3(A("."), $1, $3); }
| exp '@' exp       	{ $$ = FN3(A("@"), $1, $3); }
| exp ':' exp       	{ $$ = FN3(A(":"), $1, $3); }
| exp "!:" exp       	{ $$ = FN2(A("!"), FN3(A(":"), $1, $3)); } // !(:(a b))

| '-' exp  %prec NEG	{ $$ = FN2(A("-"), $2); }

| single single %prec CALL { $$ = FN2($1, $2); }
| single single single %prec CALL { $$ = FN3($2, $1, $3); }
| single single single single %prec CALL { $$ = A("fout"); yyerrok; }
|	'[' error ']'				
;

list:
	%empty							{ $$ = exp1(A("[]")); }
|	items
;

set:
	%empty							{ $$ = exp1(A("{}")); }
|	setitems
;

setitems:
	exp									{ $$ = FN2(A("{}"), $1); }
| setitems ',' exp			{ $$ = APPEND($1, $3); }
;

items:
	exp									{ $$ = FN2(A("[]"), $1); }
| items ',' exp				{ $$ = APPEND($1, $3); }
;
