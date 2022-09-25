#include "instruction.h"
#include "prog.h"
#include "platform.h"
#include <fstream>
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <cstring>
#include <list>

using namespace std;

#define PROJECT_DIRECTORY "<YOUR PROJECT DIRECTORY>"

#define ADD_REG 7
#define LD_REG 8
#define STR_REG 9

/**
 * @return an instruction formed by NOPs
 */
Inst all_nops()
{
  return  __pack_mininsts(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
}

int main()
{
  
	Program program;

	program.add_inst(SMC_LI(5, 3));		//R3=5
	program.add_inst(SMC_LI(15, 4));		//R4=15
	program.add_label("LOOP");
	program.add_inst(SMC_ADDI(3, 1, 3));	//R3++
	//If R4>R3, go to LOOP
	program.add_branch(program.BR_TYPE::BL,3,4, "LOOP");
	program.add_inst(all_nops());		//R3=R4=15
	program.add_inst(SMC_LI(121, LD_REG));
	program.add_inst(SMC_LI(62, STR_REG));
	program.add_inst(SMC_LI(100, ADD_REG));
	program.add_inst(SMC_ST(ADD_REG, 0, STR_REG));
	program.add_inst(all_nops());
	program.add_inst(SMC_LD(ADD_REG, 0, LD_REG));
	program.add_inst(all_nops());
	program.add_inst(SMC_END());

	//DRAM timing parameters are updated with timings.txt
	program.debug(PROJECT_DIRECTORY, "timings.txt");

	//Load the program to instruction memory
	program.save_coe(PROJECT_DIRECTORY);
	program.pretty_print();

	//Start the debugger
	program.debug(PROJECT_DIRECTORY, false);
}
