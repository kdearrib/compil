%{
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include "../include/table_symb.h"

	FILE* yyout;
	int yyerror(char*);
	int yylex();
	FILE* yyin; 
	int stack_cur = 0;
	int jump_label=0; 
	
	void alloc(int* cur);
	void inst(const char *);
	void instarg(const char *,int);
	void comment(const char *);
		
	/*les fonctions utilisés*/
	int getsigne(char addsub);
	void add_sub(char op);
	void div_star(char op);
	void comp( char* bop);
	void neg(void);
	void bope (char* bop);

	
/*	typedef enum { ENT, CAR } type_var; */

typedef enum bool{
 	false, true
	}Bool;
 





%}

%union {
   char ident[50];
   char type[50];
   char caractere;
   int entier;
   char comp[3];
   char bool[3];
}

%token NUM CARACTERE
%token IDENT
%token TYPE
%token COMP
%token ADDSUB
%token DIVSTAR
%token BOPE
%token NEGATION
%token EGAL, PV, VRG, LPAR, RPAR, LACC, RACC, LSQB, RSQB

%token CONST
%token VOID
%token IDENT
%token MAIN, PRINT, READ, READCH

%type <ident> IDENT
%type <entier> NUM NombreSigne
%type <type> TYPE
%type <caractere> CARACTERE ADDSUB

%left BOPE
%left COMP
%left ADDSUB
%left DIVSTAR
%left NEGATION
/*%left ADDSUB unaire, avec %prec?*/ 


%%

PROG 		: DeclConst DeclVarPuisFonct Print
			;

DeclConst 	: DeclConst CONST ListConst PV 
			| /* rien */
			;
	
ListConst 	: ListConst VRG 							{alloc(&stack_cur);} IDENT EGAL Litteral { add_symb($4, 1, stack_cur-1); } 
			| 											{alloc(&stack_cur);} IDENT { add_symb($2, 1, stack_cur-1);} EGAL Litteral
			;
	
Litteral 	: NombreSigne								{putOnStack(stack_cur-1, $1);}
			| CARACTERE 								{putOnStack(stack_cur-1, $1);}
			;
	
NombreSigne : NUM 										{ $$ = $1;}
			| ADDSUB NUM 								{ $$ = (getsigne($1) * $2);}
			;
	
DeclVarPuisFonct : TYPE ListVar PV DeclVarPuisFonct
			| /* DeclFonct */
			;
	
ListVar 	: ListVar VRG {alloc(&stack_cur);} Ident 
			| {alloc(&stack_cur);} Ident
			;
	
Ident 		: IDENT 									{ add_symb($1, 0, stack_cur-1);}
			;
	
Tab			: Tab LSQB NUM RSQB
			|
			; 
			
DeclMain	: EnTeteMain Corps
			;
			
EnTeteMain	: MAIN LPAR RPAR
			;
			
DeclFonct	: DeclFonct DeclUneFonct
			| DeclUneFonct
			;
			
DeclUneFonct: EnTeteFonct Corps
			;

EnTeteFonct	: TYPE IDENT LPAR Parametres RPAR
			| VOID IDENT LPAR Parametres RPAR
			;
			
Parametres	: VOID
			| ListTypVar
			;
			
ListTypVar	: ListTypVar VRG TYPE IDENT
			| TYPE IDENT
			;

Corps		: LACC DeclConst DeclVar SuiteInstr RACC
			;

DeclVar		: DeclVar TYPE ListVar PV
			|
			; 

SuiteInstr	: SuiteInstr Instr
			|
			;

InstrComp	: LACC SuiteInstr RACC
			;
			
Instr		: LValue EGAL Exp PV
			| IF LPAR Exp RPAR Instr
			| IF LPAR Exp RPAR Instr ELSE Instr
			| WHILE LPAR Exp RPAR Instr				
			| RETURN Exp PV								{inst("POP"); inst("RETURN");}
			| RETURN PV									{inst("RETURN");}
			| IDENT LPAR Arguments RPAR PV
			| READ LPAR IDENT RPAR PV
			| READCH LPAR IDENT RPAR PV
			| PRINT LPAR Exp RPAR PV					{inst("POP");inst("WRITE");}
			| PV										{}
			| InstrComp									{}
			;



Arguments 	: ListExp
			| 
			;
          
LValue		: IDENT TabExp
			;
				
ListExp 	: ListExp VRG Exp
			| Exp;
        
Exp 		: Exp ADDSUB Exp 							{inst("POP"); inst("SWAP"); inst("POP"); add_sub($2); inst("PUSH");}
			| Exp DIVSTAR Exp							{inst("POP"); inst("SWAP"); inst("POP"); div_star($2); inst("PUSH");}
			| Exp COMP Exp 								{ inst("POP"); inst("SWAP"); inst("POP"); comp($2);}
			| ADDSUB Exp 								{if($1 == '-'){ inst("POP"); inst("NEG"); inst("PUSH");}}
			| Exp BOPE Exp								{inst("POP"); inst("SWAP"); inst("POP"); bope($2); inst("PUSH");}
			| NEGATION Exp								{inst("POP"); neg(); inst("PUSH");}
			| LPAR Exp RPAR 							{$$ = $2;}
			/*| LValue*/
			| NUM 										{instarg("SET", $1); inst("PUSH");}
			/*| IDENT LPAR Arguments RPAR				{}*/
		
	
Print 		: /* rien */ 
			| Print PRINT IDENT PV 						{ inst("PUSH"); instarg("SET", getIdAddrOnStack($3, stack_cur)); inst("LOAD"); inst("WRITE"); inst("POP");} 
			;
	

%%


int yyerror(char* s) {
  fprintf(stderr,"%s\n",s);
  return 0;
}

void endProgram() {
  printf("HALT\n");
}

void alloc(int* cur){
	instarg("ALLOC", 1);
	*cur = *cur + 1;
}	

void inst(const char *s){
  printf("%s\n",s);
}

void instarg(const char *s,int n){
  printf("%s\t%d\n",s,n);
}

void comment(const char *s){
  printf("#%s\n",s);
}

int getsigne(char addsub){
	if(addsub == '+')
		return 1;
	return -1;
}

void add_sub(char op) {
	if(op == '+')
		inst("ADD");
	else
		inst("SUB");
}

void div_star(char op){
	if(op == '/')
		inst("DIV");
	if( op == '*')
		inst("MULT");
	else
		inst("MOD");
}

void comp( char* bop){
	if(strcmp(bop, "==") == 0)
		inst("EQUAL");
	if(strcmp(bop,">") == 0)
		inst("GREATER");
	if(strcmp(bop,"<") == 0)
		inst("LESS");
	if(strcmp(bop,">=") == 0)
		inst("GEQ");
	if(strcmp(bop,"<=") == 0)
		inst("LEQ");
	else
		inst("NOTEQ");
}

void neg(void){
	inst("SWAP"); 	/*reg1 = reg2*/
	inst("PUSH");	/*conservation de la valeur ancienne reg2*/
	instarg("SET",1);
	inst("ADD");	/*la somme de reg1 et reg2*/
	inst("SWAP");	/*reg 2 = la somme*/ 
	instarg("SET",2);
	inst("SWAP");
	inst("MOD");	/*la somme % 2*/
	inst("SWAP");	/*le resultat de negation en reg2 pour pop reg2 precedent*/
	inst("POP");
	inst("SWAP");	/*resultat negation en reg1*/
}

void bope (char* bop){
	if( strcmp(bop,"&&") == 0)
		/*
		inst("EQUAL");
		inst("SWAP");
		instarg("SET",1);
		inst("EQUAL");
		*/
		inst("ADD");
		inst("SWAP);
		instarg("SET",2);
		inst("EQUAL");
	else
		inst("ADD");
		inst("SWAP");
		instarg("SET",0);
		inst("NOTEQ");
		
}


int main(int argc, char** argv) {
  if(argc==3){
	if( strcmp(argv[1], "-o") == 0)
		yyout = fopen("test.vm","w");
		yyin = fopen(argv[2], "r");
  }
  else if(argc==1){
    yyout = stdout;
    yyin = stdin;
  }
  else{
    fprintf(stderr,"usage: %s [src]\n",argv[0]);
    return 1;
  }
  
  yyparse();
  endProgram();
  return 0;
}
