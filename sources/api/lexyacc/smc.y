%{
  #include "prog.h"
  #include "instruction.h"
  #include <iostream>
  #include <stdlib.h>
  #include <stdint.h>
  #include <string>
  #include <string.h>
  #include <queue>
  #include <map>
  #include <stack>

  extern char* yytext;
  extern int yyleng;
  extern int yylex(void);
  extern "C" void yyerror(char const*);

  int block_levels = 0;
  
  Program* prog;
  std::stack <Program*> prog_addr_stack;
  void process_ddr_command_queue();
  std::stack <uint32_t> num_generate_stack;
  std::queue <Mininst> ddr_command_queue;
  std::map<std::string, uint32_t> variable_map; 
%}

%start program

%union  { void* prg;
          Mininst mini_i_type;
          Inst i_type;
          uint32_t num;
          char* lit;
        }

%token <lit> HEX_NUMBER
%token <num> DEC_NUMBER
%token <num> REG_ID
%token <lit> LABEL
%token <lit> VARIABLE

/* Instruction OP-Codes */
%token WAIT

%token ADD
%token ADDI
%token SUB
%token SUBI
%token MOV
%token SRC
%token LI
%token LDWD

%token BRL
%token BREQ
%token JMP

%token WR
%token RD
%token ACT
%token PRE
%token REF
%token ZQ
%token END

/* Misc. operators */
%token INCREMENT
%token AUTO_PRECHARGE
%token BURST_CHOP
%token PRECHARGE_ALL

/* Other Expressions */
%token GENFOR
%token ENDPROGRAM

%type <num> gen_begin
%type <num> immediate
%type <i_type> instruction
%type <mini_i_type> ddr_command
%type <num> address_register
%type <num> reg_id
%type <num> rw_args
%type <num> pre_args

%%

program:
  expression_list
  | program ENDPROGRAM
  {
  }
  ;

expression_list:
  expression  {}
  | expression_list expression {}

expression:
  instruction
  {
    // See if DDR command queue is empty
    if (ddr_command_queue.size() > 0)
    {
      printf("WARNING: I just appended some NOPs to your code\n");
      int nops_to_append = 4 - ddr_command_queue.size();
      Mininst ddr_cmd_batch[4];
      for (int i = 0 ; i < ddr_command_queue.size() ; i++)
      {
        ddr_cmd_batch[i] = ddr_command_queue.front();
        ddr_command_queue.pop();
      }
      for (int i = ddr_command_queue.size() ; i < 4 ; i++)
        ddr_cmd_batch[i] = SMC_NOP();
      prog->add_inst(__pack_mininsts(ddr_cmd_batch[0],ddr_cmd_batch[1],
        ddr_cmd_batch[2],ddr_cmd_batch[3]));
    }
    prog->add_inst($1);
  }
  | branch
    {
      
    }
  | pseudo_instruction
    {
      
    }
  | LABEL ':'
    {
      prog->add_label(std::string($1));
    }
  | ddr_command   
    {
      ddr_command_queue.push($1);
      process_ddr_command_queue();
    }
  | definition
    {

    }
  | gen_begin
  {
    num_generate_stack.push($1);
  }
  | '}' // end of a generate block
  {
    if(block_levels == 0) // pop an error: no generate blocks present, cannot end a block definition
      printf("Expected \'}\' somewhere.\n"); // TODO change this with a correct error displaying function
    else
    {
      Program* previous_in_stack = prog_addr_stack.top();
      prog_addr_stack.pop();
      int num_gen = num_generate_stack.top();
      num_generate_stack.pop();
      for (int i = 0 ; i < num_gen ; i++)
        previous_in_stack->add_below(*prog);
      free(prog);
      prog = previous_in_stack;
    }
  }
  ;

instruction:
  ADD reg_id reg_id reg_id        
  {
    $$ = SMC_ADD($3, $4, $2); 
  }
  | ADDI reg_id reg_id immediate  
    {
      $$ = SMC_ADDI($3, $4, $2); 
    }
  | SUB reg_id reg_id reg_id      
    {
      $$ = SMC_SUB($3, $4, $2); 
    }
  | SUBI reg_id reg_id immediate  
    {
      $$ = SMC_SUBI($3, $4, $2); 
    }
  | MOV reg_id reg_id             
    {
      $$ = SMC_MV($3, $2);
    }
  | SRC reg_id reg_id             
    {
      $$ = SMC_SRC($3, $2);  
    }
  | LI reg_id immediate           
    {
      $$ = SMC_LI($3, $2);
    }
  | LDWD immediate reg_id
    {
      $$ = SMC_LDWD($3, $2);
    }
  | END
    {
      $$ = SMC_END();
    }
  ;

branch:
  BRL LABEL reg_id reg_id
    {
      prog->add_branch(prog->BR_TYPE::BL, $3, $4, $2);
    }
  | BREQ LABEL reg_id reg_id
    {
      prog->add_branch(prog->BR_TYPE::BEQ, $3, $4, $2);
    }
  | JMP LABEL
    {
      prog->add_branch(prog->BR_TYPE::JUMP, 0, 0, $2);
    }
  ;

pseudo_instruction:
  WAIT immediate
  {
    // currently functions only by adding NOPs
    // TODO depending on the # of cycles specified
    // we can instead generate a "loop" which enables
    // us to wait for more with less instructions.
    for(int i = 0 ; i < $2 ; i++)
      ddr_command_queue.push(SMC_NOP());
    process_ddr_command_queue();
  }
  ;

immediate:
  HEX_NUMBER 
  {
    $$ = (uint32_t) strtol($1, NULL, 16);  
  }
  | DEC_NUMBER
    {
    $$ = $1;
    }
  ;
ddr_command:
  WR address_register address_register rw_args      
  {
    int reg1_id = $2;
    int reg2_id = $3;
    int do_increment1 = reg1_id >= 100 ? 1 : 0;
    int do_increment2 = reg2_id >= 100 ? 1 : 0;
    if(do_increment1)
      reg1_id -= 100;
    if(do_increment2)
      reg2_id -= 100;
    int do_ap = $4 == 3 ? 1 : $4 == 1 ? 1 : 0;
    int do_bc = $4 == 3 ? 1 : $4 == 2 ? 1 : 0;
    $$ = SMC_WRITE(reg1_id, do_increment1, reg2_id, do_increment2, do_bc, do_ap);
  }
  | RD address_register address_register rw_args 
    {
      int reg1_id = $2;
      int reg2_id = $3;
      int do_increment1 = reg1_id >= 100 ? 1 : 0;
      int do_increment2 = reg2_id >= 100 ? 1 : 0;
      if(do_increment1)
        reg1_id -= 100;
      if(do_increment2)
        reg2_id -= 100;
      int do_ap = $4 == 3 ? 1 : $4 == 1 ? 1 : 0;
      int do_bc = $4 == 3 ? 1 : $4 == 2 ? 1 : 0;
      $$ = SMC_READ(reg1_id, do_increment1, reg2_id, do_increment2, do_bc, do_ap);
    }
  | ACT address_register address_register 
    {
      int reg1_id = $2;
      int reg2_id = $3;
      int do_increment1 = reg1_id >= 100 ? 1 : 0;
      int do_increment2 = reg2_id >= 100 ? 1 : 0;
      if(do_increment1)
        reg1_id -= 100;
      if(do_increment2)
        reg2_id -= 100;
      $$ = SMC_ACT(reg1_id, do_increment1, reg2_id, do_increment2);
    }
  | PRE address_register pre_args  
    {
      int reg_id       = $2;
      int do_increment = reg_id>=100 ? 1 : 0;
      if(do_increment)
        reg_id -= 100;
      $$ = SMC_PRE(reg_id, do_increment, $3);
    }
  | REF   
    {
      $$ = SMC_REF();
    }
  | ZQ
    {
      $$ = SMC_ZQ();
    }
  ;

address_register:
  reg_id
  {
    $$ = $1;
  }
  | reg_id INCREMENT
    {
      $$ = 100 + $1;
    }
  ;

definition:
  VARIABLE '=' immediate
  {
    std::string key = std::string($1);
    variable_map[key] = $3;
  }
  ;

reg_id:
  REG_ID
  {
    $$ = $1;
  }
  | VARIABLE
    {
      std::string key = std::string($1);
      if (variable_map.find(key) == variable_map.end()) 
      {
        // TODO proper error handling
        std::cout << "Variable " << key << " is not defined." << std::endl;
        $$ = 0;
      } else 
        $$ = variable_map[key];
    }
  ;

rw_args:
  %empty
  {
    $$ = 0;
  }
  | AUTO_PRECHARGE 
    {
      $$ = 1;
    }
  | BURST_CHOP 
    {
      $$ = 2;
    }
  | AUTO_PRECHARGE BURST_CHOP 
    {
      $$ = 3;
    }
  | BURST_CHOP AUTO_PRECHARGE
    {
      $$ = 3;
    }
  ;

pre_args:
  %empty
  {
    $$ = 0;
  }
  | PRECHARGE_ALL 
    {
      $$ = 1;
    }
  ;

gen_begin:
  GENFOR immediate '{'
  {
    // See if DDR command queue is empty
    if (ddr_command_queue.size() > 0)
    {
      printf("WARNING: I just appended some NOPs to your code\n");
      int nops_to_append = 4 - ddr_command_queue.size();
      Mininst ddr_cmd_batch[4];
      for (int i = 0 ; i < ddr_command_queue.size() ; i++)
      {
        ddr_cmd_batch[i] = ddr_command_queue.front();
        ddr_command_queue.pop();
      }
      for (int i = ddr_command_queue.size() ; i < 4 ; i++)
        ddr_cmd_batch[i] = SMC_NOP();
      prog->add_inst(__pack_mininsts(ddr_cmd_batch[0],ddr_cmd_batch[1],
        ddr_cmd_batch[2],ddr_cmd_batch[3]));
    }
    prog_addr_stack.push(prog);
    prog = new Program();
    block_levels++;
    $$ = $2; // Number of times this block is generated
  }
  ;

%%

void process_ddr_command_queue()
{
  while (ddr_command_queue.size() >= 4)
  {
    Mininst ddr_cmd_batch[4];
    for (int i = 0 ; i < 4 ; i++)
    {
      ddr_cmd_batch[i] = ddr_command_queue.front();
      ddr_command_queue.pop();
    }
    prog->add_inst(__pack_mininsts(ddr_cmd_batch[0],ddr_cmd_batch[1],
      ddr_cmd_batch[2],ddr_cmd_batch[3]));
  }
}

void yyerror (char const *s) {
  fprintf (stderr, "%s\n", s);
}

int main(int argc, char* argv[])
{
  if(argc != 2){
    printf("I need you to supply me with the filename!\n");
    exit(1);
  }
  prog = new Program();
  yyparse();
  prog->save_bin(std::string(argv[1]));
}

