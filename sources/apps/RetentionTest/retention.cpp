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
#include <cassert>
#include <sys/time.h>

using namespace std;

#define RETENTION_IN_MS 1000
#define NUM_BANKS 1
#define NUM_ROWS 32*1024

#define GET_TIME_INIT(num) struct timeval _timers[num]
#define GET_TIME_VAL(num) gettimeofday(&_timers[num], NULL)
#define TIME_VAL_TO_MS(num) (((double)_timers[num].tv_sec*1000.0) + ((double)_timers[num].tv_usec/1000.0))

// Need to hand-calculate below value?
// indicates how many rows we can write to
// before testing for retention
// TODO SET THIS TO A REASONABLE VALUE
#define MAX_ROW_PER_ITER 512

Inst all_nops()
{
  return  __pack_mininsts(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
}

int main(int argc, char*argv[])
{
  Program program;
  SoftMCPlatform platform;
  int err;

  if(argc != 3)
  {
    printf("Usage: \n ./SoftMC_RETENTION <retention time in ms> <output file name>\n");
    exit(0);
  }

  if((err = platform.init()) != SOFTMC_SUCCESS){
      cerr << "Could not initialize SoftMC Platform: " << err << endl;
  }

  char* buf = (char*) malloc(sizeof(char)*32*1024);
  platform.reset_fpga();
  // sleep(1);

  uint64_t sleep_counter = (uint64_t) ((double) RETENTION_IN_MS * 1000 * 1000 // retention in ns
                            / 6) ; // 6ns clock period

  assert(sleep_counter < (uint64_t)4*1024*1024*1024 && "Retention time too large to fit into a 32 bit register");

  printf("Retention time given as %d ms\n", RETENTION_IN_MS);
  printf("Will sleep for %ld cycles\n", sleep_counter*6);

  program.add_inst(SMC_LI(8, 0)); // CASR
  program.add_inst(SMC_LI(1, 1)); // BASR
  program.add_inst(SMC_LI(1, 2)); // RASR

  program.add_inst(SMC_LI(NUM_ROWS, 8)); // NUM_ROWS
  program.add_inst(SMC_LI(NUM_BANKS, 11));
  
  // To fill wide-reg with data
  program.add_inst(SMC_LI(0xffffffff, 7));
  for(int i = 0 ; i < 16 ; i++)
    program.add_inst(SMC_LDWD(7,i));


  program.add_inst(SMC_LI(0, 5)); // BAR
  program.add_label("BANK_BEGIN");
  program.add_inst(SMC_LI(MAX_ROW_PER_ITER,7));
  program.add_inst(SMC_LI(0, 4)); // CAR
  program.add_inst(SMC_LI(0, 6)); // RAR

  program.add_label("WRITE");

  // PRE & wait for tRP
  program.add_inst(__pack_mininsts(
    SMC_PRE(5, 0, 0),
    SMC_NOP(), SMC_NOP(), SMC_NOP()
  ));
  program.add_inst(all_nops());
  program.add_inst(all_nops());
  program.add_inst(all_nops());

  // ACT & wait for tRCD
  program.add_inst(__pack_mininsts(
    SMC_ACT(5, 0, 6, 1),
    SMC_NOP(), SMC_NOP(), SMC_NOP()
  ));
  program.add_inst(all_nops());
  program.add_inst(all_nops());
  program.add_inst(all_nops());

  // Write to a whole row
  for(int i = 0 ; i < 128 ; i++){
    program.add_inst(__pack_mininsts(
      SMC_WRITE(5, 0, 4, 1, 0, 0),
      SMC_NOP(), SMC_NOP(), SMC_NOP()
    ));
    program.add_inst(all_nops());
  }

  // Wait for t(write-precharge)
  // & precharge the open bank
  program.add_inst(all_nops());
  program.add_inst(all_nops());
  program.add_inst(__pack_mininsts(
    SMC_PRE(5, 0, 0),
    SMC_NOP(), SMC_NOP(), SMC_NOP()
  ));

  program.add_branch(program.BR_TYPE::BL, 6, 7, "WRITE");

  // implement "sleep" as a counter
  //program.add_label("SLEEP");
  //program.add_inst(SMC_LI(0, 9));
  //program.add_inst(SMC_LI(sleep_counter/7, 10));
  //program.add_label("SLEEP_INNER");
  //program.add_inst(SMC_ADDI(9,1,9));
  //program.add_branch(program.BR_TYPE::BL, 9, 10, "SLEEP_INNER");
  program.add_inst(SMC_SLEEP(sleep_counter));

  // decrement RAR to read from newly written rows
  program.add_inst(SMC_SUBI(6, MAX_ROW_PER_ITER, 6));

  program.add_label("READ");
  // PRE & wait for tRP
  program.add_inst(__pack_mininsts(
    SMC_PRE(5, 0, 0),
    SMC_NOP(), SMC_NOP(), SMC_NOP()
  ));
  program.add_inst(all_nops());
  program.add_inst(all_nops());
  program.add_inst(all_nops());

  // ACT & wait for tRCD
  program.add_inst(__pack_mininsts(
    SMC_ACT(5, 0, 6, 1),
    SMC_NOP(), SMC_NOP(), SMC_NOP()
  ));
  program.add_inst(all_nops());
  program.add_inst(all_nops());
  program.add_inst(all_nops());
  
  // Read from a whole row
  for(int i = 0 ; i < 128 ; i++){
    program.add_inst(__pack_mininsts(
      SMC_READ(5, 0, 4, 1, 0, 0),
      SMC_NOP(), SMC_NOP(), SMC_NOP()
    ));
    program.add_inst(all_nops());
  }

  // Wait for t(read-precharge)
  // & precharge the open bank
  program.add_inst(all_nops());
  program.add_inst(all_nops());
  program.add_inst(__pack_mininsts(
    SMC_PRE(5, 0, 0),
    SMC_NOP(), SMC_NOP(), SMC_NOP()
  ));

  program.add_branch(program.BR_TYPE::BEQ, 6, 8, "INC_BANK");
  program.add_branch(program.BR_TYPE::BL, 6, 7, "READ");
  program.add_inst(SMC_ADDI(7, MAX_ROW_PER_ITER, 7));
  program.add_branch(program.BR_TYPE::JUMP, 0, 0, "WRITE");

  program.add_label("INC_BANK");
  program.add_inst(SMC_ADDI(5,1,5));
  program.add_branch(program.BR_TYPE::BEQ, 5, 11, "END");
  program.add_branch(program.BR_TYPE::JUMP,0,0,"BANK_BEGIN");

  program.add_label("END");
  program.add_inst(SMC_END());

  platform.execute(program);

  uint8_t pattern = 0xff;
  uint64_t r_count = 0;

  ofstream failures_file;
  failures_file.open(std::string(argv[2]), ofstream::binary);
  while(1)
  {
    platform.receiveData(buf,8*1024);
    for(int j = 0 ; j < 8*1024 ; j++)
      failures_file << (buf[j] ^ pattern);
    r_count++;
    if(r_count % (NUM_ROWS) == 0)
      printf("Bank %ld complete\n", r_count/(NUM_ROWS));
    if(r_count == NUM_BANKS*NUM_ROWS)
      break;
    printf("\rRead: %ld",r_count);
    fflush(stdout);
  }
  printf("Test complete!\n");
}
