%{ 
  #include <stdlib.h> 
  #include "instruction.h"
  #include "y.tab.h"
%} 

%%

"//"[^\n]*  ;  /* Skip comments   */
[%\t ]+     ;  /* Skip whitespace */

0x[0-9a-f]+ {
              yylval.lit = yytext+2;
              return HEX_NUMBER;
            }

[0-9]+      {
              yylval.num = atoi(yytext);
              return DEC_NUMBER;
            }

r[0-9][0-9]? {
              yylval.num = atoi(++yytext); /* Skip the first character? */
              return REG_ID;
             }

"wait"|"WAIT" return WAIT;

"add"|"ADD"   return ADD;
"addi"|"ADDI" return ADDI;
"sub"|"SUB"   return SUB;
"subi"|"SUBI" return SUBI;
"mov"|"MOV"   return MOV;
"src"|"SRC"   return SRC;
"li"|"LI"     return LI;
"ldwd"|"LDWD" return LDWD;

"bl"|"BL"     return BRL;
"beq"|"beq"   return BREQ;
"jmp"|"JMP"   return JMP;

"wr"|"WR"     return WR;
"rd"|"RD"     return RD;
"act"|"ACT"   return ACT;
"pre"|"PRE"   return PRE;
"ref"|"REF"   return REF;
"zq"|"ZQ"     return ZQ;
"end"|"END"   return END;


"++"          return INCREMENT;
"AP"|"ap"     return AUTO_PRECHARGE;
"BC"|"bc"     return BURST_CHOP;
"PA"|"pa"     return PRECHARGE_ALL;

"times"       return GENFOR;
"ENDPROGRAM"  return ENDPROGRAM;

 [a-z_]+     {
               char* var_name = (char*) malloc((yyleng+1)*sizeof(char));
               strcpy(var_name, yytext);
               yylval.lit = var_name;
               return VARIABLE;
             } 

 [A-Z_]+     {
               char* lbl_name = (char*) malloc((yyleng+1)*sizeof(char));
               strcpy(lbl_name, yytext);
               yylval.lit = lbl_name;
               return LABEL;
             }

 .           return *yytext;

%%

int yywrap(void) { return 1; }
