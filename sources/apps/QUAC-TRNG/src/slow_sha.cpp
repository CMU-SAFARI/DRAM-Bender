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
#include <algorithm>
#include <iterator>
#include <iomanip>
#include <openssl/sha.h>
#include "util.h"

using namespace std;

// each iter generates 320 bytes of RN
// #define ITERS_SHA 450000
#define READ_CL 128

// Stride register ids are fixed and should not be changed
// CASR should always be reg 0
#define CASR 0
// BASR should always be reg 1
#define BASR 1
// RASR should always be reg 2
#define RASR 2

#define PATTERN_REG 12
#define INV_PATTERN_REG 13
#define TEMP_PATTERN_REG 14

#define BAR 3
#define CAR 4
#define RARBASE 5
#define RAR1 6
#define RAR2 9

#define COPY_REG1 10
#define COPY_REG2 11

#define ITER_REG 7
#define CTR_REG  8

#define INIT_LOOP 15

Program gen_test_prog(int bank, int r1, int r2, int iters, int placement)
{
  Program program;

  program.add_inst(SMC_LI(8, CASR)); // Load 8 into CASR since each READ reads 8 columns
  program.add_inst(SMC_LI(1, BASR)); // Load 1 into BASR
  program.add_inst(SMC_LI(1, RASR)); // Load 1 into RASR

  program.add_inst(SMC_LI(bank, BAR));
  program.add_inst(SMC_LI(r1-(r1%4), RARBASE));

  program.add_inst(SMC_LI(iters, ITER_REG));
  program.add_inst(SMC_LI(0, CTR_REG));

  program.add_label("WRITE_BEGIN");
  program.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_SLEEP(3));
  switch(placement)
  {
    // Invert 0-1 start pattern before here when we set the
    // WIDEREG
    case 1000:
      program.add_below(genWriteRange1000(RARBASE, 4, BAR));
      break;
    case 1001:
      program.add_below(genWriteRange1001(RARBASE, 4, BAR));
      break;
    case 1010:
      program.add_below(genWriteRange1010(RARBASE, 4, BAR));
      break;
    case 1011:
      program.add_below(genWriteRange1011(RARBASE, 4, BAR));
      break;
    case 1100:
      program.add_below(genWriteRange1100(RARBASE, 4, BAR));
      break;
    case 1101:
      program.add_below(genWriteRange1101(RARBASE, 4, BAR));
      break;
    case 1110:
      program.add_below(genWriteRange1110(RARBASE, 4, BAR));
      break;
    case 1111:
      program.add_below(genWriteRange1111(RARBASE, 4, BAR));
      break;
    default:
      printf("Unexpected placement encoding\n");
      exit(0);
  }

  //program.add_below(genCopyRange(RARBASE, 4, BAR, true));
  program.add_inst(SMC_LI(r1, RAR1));
  program.add_inst(SMC_LI(r2, RAR2));
  
  program.add_below(genActPreActSequence(1, 1, RAR1, RAR2, BAR));

  program.add_inst(SMC_SLEEP(6));
  program.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());

  program.add_below(genReadRange(RARBASE, 1, BAR, 128));
  program.add_inst(SMC_ADDI(CTR_REG, 1, CTR_REG));
  
  program.add_branch(program.BR_TYPE::BL, CTR_REG, ITER_REG, "WRITE_BEGIN");
  program.add_inst(SMC_END());

  return program;
}

int main(int argc, char *argv[])
{
  SoftMCPlatform platform;
  int err;
  
  // buffer allocated for reading data from the board
  unsigned char buf[4*READ_CL*64];

  // Initialize the platform, opens file descriptors for the board PCI-E interface.
  if((err = platform.init()) != SOFTMC_SUCCESS){
      cerr << "Could not initialize SoftMC Platform: " << err << endl;
  }
  // reset the board to hopefully restore the board's state
  platform.reset_fpga();
  platform.set_aref(true);
  // Read selected segments from file
  // first line: <number of segments>
  // each line: <bank> <segment_start> <placement>
  ifstream sf;
  string sf_name = string(argv[2]);
  sf.open(sf_name);

  int n_segments; sf >> n_segments;
  std::vector<std::string> placements;
  std::vector<int> banks, segments;
  std::vector<float> ents;
  for(int i = 0 ; i < n_segments ; i++)
  {
    int read;
    sf >> read; banks.push_back(read);
    sf >> read; segments.push_back(read);
    float ent;
    sf >> ent; ents.push_back(ent);
    std::string rd;
    sf >> rd; placements.push_back(rd);
  }

  for(int i = 0 ; i < n_segments ; i++)
  {
    int bank  = banks[i];
    int r1    = segments[i];
    float ent = ents[i];

    if (ent < 1)
      continue;

    std::string placement = placements[i];

    bool invert = false;
    // placement_magic
    char new_placement[10];
    if (placement[0] == '0')
    {
      for (std::string::size_type i = 0 ; i < placement.size() ; i++)
        if(placement[i] == '0')
          new_placement[i] = '1';
        else if(placement[i] == '1')
          new_placement[i] = '0';
        else
          new_placement[i] = placement[i];
      placement = string(new_placement);
      invert = true;
    }

    Program program;
    program.add_inst(SMC_LI(invert ? 0x0 : 0xffffffff, PATTERN_REG));
    program.add_inst(SMC_LI(invert ? 0xffffffff : 0x0, INV_PATTERN_REG));
    for(int i = 0 ; i < 16 ; i++)
      program.add_inst(SMC_LDWD(PATTERN_REG,i));
    program.add_inst(SMC_END());
    platform.execute(program);

    unsigned char *bitstream;

    unsigned int sha_input_ent    = 256;
    unsigned int sha_input_blocks = ent/sha_input_ent + 1;
    unsigned int row_partition_size = 8192/sha_input_blocks;
    // UNTODO //TODO: from now on this is going to be 16Mbits
    unsigned int test_iters       = (1024*1024*1024)/(8*sha_input_blocks*32);
    

    bitstream = new unsigned char[test_iters*32*sha_input_blocks];  
  
    cout << "Running for " << test_iters << " iterations." << endl;
    cout << "Total bits of entropy: " << ent << " -> " << sha_input_blocks << " sha input blocks for the row" << endl; 

    Program prog = gen_test_prog(bank, r1, r1+3, test_iters, std::stoi(placement));
    platform.execute(prog);

    for(int i = 0 ; i < test_iters ; i++)
    {  
      platform.receiveData((char*)buf, 8192); // read one segment each iteration
      // https://stackoverflow.com/q/13784434
      for(int j = 0 ; j < sha_input_blocks ; j++)
      {
        unsigned char hash[SHA256_DIGEST_LENGTH];
        SHA256_CTX sha256;
        SHA256_Init(&sha256);
        SHA256_Update(&sha256, (char*)(buf+row_partition_size*j), row_partition_size);
        SHA256_Final(hash, &sha256);
        for(int k = 0 ; k < SHA256_DIGEST_LENGTH ; k++)
        {
          bitstream[i*sha_input_blocks*SHA256_DIGEST_LENGTH + j*SHA256_DIGEST_LENGTH + k] = hash[k];
        }
      }
    }
    ofstream dump_file;
    string fn = string(argv[1]) + "/" + placements[i] + "_" + to_string(r1) + ".bin";
    dump_file.open(fn, ofstream::binary);
    dump_file.write((char*)(bitstream), test_iters*32*sha_input_blocks);
    dump_file.close();
    printf("\rrow %d", r1);
    fflush(stdout);
    delete bitstream;
  }
  
}
