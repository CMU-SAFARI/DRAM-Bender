#include "instruction.h"
#include "prog.h"
#include <string>
#include <vector>
#include <cassert>
#include <iostream>
#include <fstream>
#include <bitset>
#include <algorithm>
#include <sys/wait.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>

Program::Program()
{
  dumpRegsCalled = false;
}

Program::Program(std::string fname)
{
  std::cout << "WARNING: make sure that the executable \"smc_parser\" exists in the working directory" << std::endl;

  std::string correctFileName = "./smc_parser " + fname + " < " + fname + " >/dev/null";
  if (system(correctFileName.c_str()) != 0)
  {
    std::cerr << "Error parsing SMC program, abort." << std::endl;
    exit(-1);
  }

  // Read instruction binary data from fname.inst
  std::ifstream binFile (fname + ".bin", std::ios::in | std::ios::binary);
  int no_insts = 0;
  // Read no of insts
  binFile.read((char*) &no_insts, 4);
  Inst insts[no_insts];
  // Read all insts
  binFile.read((char*) insts, sizeof(Inst)*no_insts);
  for(int i = 0 ; i < no_insts ; i++)
  {
    program.push_back(insts[i]);
    spc++;
  }
  binFile.close();
  // Read branch label positions from fname.meta
  std::ifstream metaFile (fname + ".meta", std::ios::in);
  std::string line;
  bool parseLabels = true;
  while(getline(metaFile,line))
  {
    if(parseLabels)
    {
      if (line == "-")
      {
        parseLabels = false;
        continue;
      }
      std::string label = line.substr(0,line.find(" "));
      std::string target = line.substr(line.find(" ")+1,line.length());
      (labels)[label] = stoi(target);
    }
    else
    {
      std::string target = line.substr(0,line.find(" "));
      std::string label = line.substr(line.find(" ")+1,line.length());
      (branches)[stoi(target)] = label;
    }
  }
  metaFile.close();
}


void Program::add_label(std::string name)
{
  if(labels.count(name))
    std::cerr << "Trying to add label " << name << " multiple times!" << std::endl;
  (labels)[name] = spc;
}
void Program::add_wait(int wait_cycles)
{
  for(; wait_cycles > 0 ; wait_cycles--)
  {
    minprogram.push_back(SMC_NOP());
  }
}

void Program::add_mininst(Mininst mi, int wait_after)
{
  minprogram.push_back(mi);
  for ( ; wait_after>0 ; wait_after--)
    minprogram.push_back(SMC_NOP());
  // if (verbose) {
  //   std::cout << "Added new mininst with wait." << std::endl;
  //   for(auto& mininst : minprogram){
  //     std::cout << std::hex << mininst << " ";
  //   }
  //   std::cout << std::endl;
  // }
}

void Program::pack_minprogram()
{
  // if (verbose) std::cout << "Packing minprogram" << std::endl;
  while(minprogram.size() >= 4)
  {
    this->add_inst(__pack_mininsts(minprogram[0], minprogram[1], minprogram[2], minprogram[3]));
    minprogram.erase(minprogram.begin(), minprogram.begin()+4);
  }

  switch (minprogram.size())
  {
    case 0:
      return;
    case 1:
      this->add_inst(__pack_mininsts(minprogram[0], SMC_NOP(), SMC_NOP(), SMC_NOP()));
      break;
    case 2:
      this->add_inst(__pack_mininsts(minprogram[0], minprogram[1], SMC_NOP(), SMC_NOP()));
      break;
    case 3:
      this->add_inst(__pack_mininsts(minprogram[0], minprogram[1], minprogram[2], SMC_NOP()));
      break;
  }
  // std::cerr << "WARNING: Number of mininsts is not multiple of four. "
            // << "Appending "<< 4-minprogram.size() << " extra NOPs for alignment."
            // << std::endl;
  minprogram.erase(minprogram.begin(), minprogram.end());
}

void Program::add_inst(Inst i)
{
  program.push_back(i);
  if (is_load(i))
    this->add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  spc += 1;
}

void Program::add_inst(Mininst m1, Mininst m2, Mininst m3, Mininst m4)
{
  Inst i =  (uint64_t) m4 << 48 |
            (uint64_t) m3 << 32 |
            (uint64_t) m2 << 16 |
            m1;
  program.push_back(i);
  spc += 1;
}

void Program::add_branch(BR_TYPE bt, int rs1, int rs2, std::string tgt)
{
  Inst place_holder = 2;
  switch(bt)
  {
    case BR_TYPE::BL:
      place_holder = SMC_BL(rs1, rs2, 0);
      break;
    case BR_TYPE::BEQ:
      place_holder = SMC_BEQ(rs1, rs2, 0);
      break;
    case BR_TYPE::JUMP:
      place_holder = SMC_JUMP(0);
      break;
  }
  (branches)[spc] = tgt;
  add_inst(place_holder);
}

void Program::add_below(const Program &p)
{
  // move instructions from p to the end of
  // this program
  program.insert(program.end(), p.program.begin(), p.program.end());

  // update branch targets and branch instruction pcs
  for ( const auto &branch : (p.branches) )
    ((this->branches))[branch.first + this -> spc] = branch.second;

  for ( const auto &label : (p.labels) )
    ((this->labels))[label.first] = label.second + this -> spc;

  // update pc
  this -> spc += p.spc;
}

Inst* Program::get_inst_array()
{
  linear_analysis();
  insert_generated();
//  printf("Inserted auto-generated info instructions\n");
  preprocess_branches();
//  printf("Assigned branch targets to labels\n");
  //pretty_print();
  int bytes = size();
  Inst* arr = (Inst*) malloc(bytes);
  int ind = 0;
  for (auto & element : (program))
    arr[ind++] = element;
  return arr;
}

Inst* Program::get_insts()
{
  int bytes = size();
  Inst* arr = (Inst*) malloc(bytes);
  int ind = 0;
  for (auto & element : (program))
    arr[ind++] = element;
  return arr;
}

int Program::size()
{
  return program.size() * 8;
}

void Program::preprocess_branches()
{
  for ( const auto &branch : (branches) ) {
    Inst br = (program)[branch.first];
    int lbl = (labels)[branch.second];
//    printf("branch addr: %d branch label: %s lbl_adr: %d is_cond: %d\n", branch.first, branch.second.c_str(),
//        lbl,is_conditional(br));
    assert(is_branch(br) &&
        "preprocess_branches(): expected a branch but got something else");
    uint64_t target_b = ((uint64_t)lbl) << 8;
    uint64_t target_j = (uint64_t) lbl;
    br |= is_conditional(br) ? target_b : target_j;
    (program)[branch.first] = br;
  }
}

/**
 * Currently only goes through the whole program
 * to see if any constraint is violated
 */
void Program::linear_analysis()
{
  bool inSequence = false;
  uint  seqPc = 0;
  int  readCtr = 0;
  for (uint pc = 0 ; pc < program.size() ; pc++)
  {
    Inst cur_inst = (program)[pc];
    if(!inSequence)
    {
      if(is_ddr(cur_inst))
      {
        //printf("Program::linear_analysis(): enter segment at pc: %d\n", pc);
        inSequence = true;
        seqPc = pc;
        readCtr = is_ddr_read(cur_inst);
      }
    }else
    {
      // we see a non-ddr inst,
      // can commit whatever info we want
      // related to the previous segment
      if(!is_ddr(cur_inst) && !is_sleep(cur_inst))
      {
        //printf("Program::linear_analysis(): exit segment at pc: %d with %d reads \n", pc, readCtr);
        inSequence = false;
        // TODO either directly insert into the vector
        // or keep these records elsewhere
        if(readCtr > 1024)
        {
          // TODO Add code that will warn user violently here.
          // maybe even an assertion?
          std::cerr << "WARNING: SoftMC won't be able to run your program timing-critically!" << std::endl;
        }else if(readCtr > 0)
        {
          // Insert info-encapsulating packet into program
          Inst warn_pipeline = SMC_INFO(readCtr);
          (warnings)[seqPc] = warn_pipeline;
        }
      }else
      {
        readCtr += is_ddr_read(cur_inst);
      }
    }
  }
}


void Program::insert_generated()
{
  // WARNING this assumes that map keys are iterated
  // in ascending order

  std::vector<uint> warn_keys;
  std::vector<Inst> warn_values;

  for ( const auto &warn : (this->warnings))
  {
    warn_keys.push_back(warn.first);
    warn_values.push_back(warn.second);
  }

  while (warn_keys.size()>0)
  {
    // new branch and label mappings
    uint warn_key = warn_keys.front();
    Inst warn_value = warn_values.front();
    warn_keys.erase(warn_keys.begin());
    warn_values.erase(warn_values.begin());

    std::map<std::string, uint> n_labels;
    std::map<uint, std::string> n_branches;
    program.insert(program.begin() + warn_key, warn_value);
    for ( const auto &branch : (this->branches) )
    {
      // branch target > inserted instruction pc
      if((labels)[branch.second] > warn_key)
      {
        (n_labels)[branch.second] = (labels)[branch.second] + 1;
      }else
      {
        (n_labels)[branch.second] = (labels)[branch.second];
      }
      // branching instruction pc > inserted instruction pc
      if(branch.first >= warn_key)
      {
        (n_branches)[branch.first + 1] = branch.second;
      }else
      {
        (n_branches)[branch.first] = branch.second;
      }
    }
    for (uint i = 0 ; i < warn_keys.size() ; i++)
      warn_keys[i] += 1;

    labels = n_labels;
    branches = n_branches;
  }
}

void Program::pretty_print()
{
  for (uint pc = 0 ; pc < program.size() ; pc++)
  {
    for ( const auto &label : (labels) )
    {
      if(label.second == pc)
        std::cout << label.first << std::endl;
    }
    printf("%04d: ", pc);
    decode_inst((program)[pc]);
    for ( const auto &branch : (branches) )
    {
      if(branch.first == pc)
        std::cout << " (TARGET LABEL: " << branch.second << ")";
    }
    printf("\n");
  }

}

void Program::bin_dump()
{
  for (uint pc = 0 ; pc < program.size() ; pc++)
  {
    for ( const auto &label : (labels) )
    {
      if(label.second == pc)
        std::cout << label.first << std::endl;
    }
    std::cout << "PC: " << pc << " Inst: " << std::hex << (program)[pc] << std::dec << std::endl;

    for ( const auto &branch : (branches) )
    {
      if(branch.first == pc)
        std::cout << branch.second;
    }
    printf("\n");
  }
}

void Program::save_bin(const std::string &fname)
{
  // Write instruction binary data to fname.inst
  std::ofstream binFile (fname + ".bin", std::ios::out | std::ios::binary);
  Inst* insts = this -> get_insts();
  int no_insts = spc;
  binFile.write ((char*)&no_insts, sizeof(no_insts));
  binFile.write ((char*) insts, sizeof(Inst)*no_insts);
  binFile.close();
  // Write branch label positions to fname.meta
  std::ofstream metaFile (fname + ".meta", std::ios::out);
  for ( const auto &label : (labels) )
    metaFile << label.first << " " << label.second << "\n";
  metaFile << "-" << "\n";
  for ( const auto &branch : (branches) )
    metaFile << branch.first << " " << branch.second << "\n";
  metaFile.close();
}

void Program::save_coe_here(const std::string &prj_dir)
{
  std::ofstream coeFile ("program.coe", std::ios::out | std::ios::binary);
  uint64_t* insts = (uint64_t*) this -> get_inst_array();
  coeFile << "memory_initialization_radix=2;\n";
  coeFile << "memory_initialization_vector=\n";
  for(uint i = 0 ; i < program.size() ; i++){
    coeFile << std::bitset<64>(insts[i]);
    if( i == (program.size()) -1){
      coeFile << ";";
    }else{
      coeFile << ",\n";
    }
  }
  coeFile.close();
}


void Program::save_coe(const std::string &prj_dir)
{
  std::ofstream coeFile (prj_dir + "/VU095.sim/sim_1/behav/xsim/simmem.coe", std::ios::out | std::ios::binary);
  std::ofstream coeFile2 (prj_dir + "/coe/simmem.coe", std::ios::out | std::ios::binary);
  std::ofstream mifFile (prj_dir + "/VU095.sim/sim_1/behav/xsim/instr_blk_mem_sim.mif", std::ios::out | std::ios::binary);
  uint64_t* insts = (uint64_t*) this -> get_inst_array();
  coeFile << "memory_initialization_radix=2;\n";
  coeFile2 << "memory_initialization_radix=2;\n";
  coeFile << "memory_initialization_vector=\n";
  coeFile2 << "memory_initialization_vector=\n";
  for(uint i = 0 ; i < program.size() ; i++){
    coeFile << std::bitset<64>(insts[i]);
    coeFile2 << std::bitset<64>(insts[i]);
    mifFile << std::bitset<64>(insts[i])<<"\n";
    if( i == (program.size()) -1){
      coeFile << ";";
      coeFile2 << ";";
    }else{
      coeFile << ",\n";
      coeFile2 << ",\n";
    }
  }
  coeFile.close();
  coeFile2.close();
  mifFile.close();
}


void Program::dump_registers()
{
  if(dumpRegsCalled)
  {
    std::cerr << "You can use your trump card (dump_register) only once per program!" << std::endl;
    exit(1);
  }
  dumpRegsCalled = true;

  this -> add_inst(SMC_LI(15,13));  // BAR
  this -> add_inst(SMC_LI(0,14));   // RAR
  this -> add_inst(SMC_LI(0,15));   // CAR

  this -> add_inst(__pack_mininsts(SMC_PRE(13,0,1),           // PRECHARGE ALL
                  SMC_NOP(),SMC_NOP(),SMC_NOP()));
  this -> add_inst(__pack_mininsts(SMC_NOP(),SMC_NOP(),SMC_NOP(),SMC_NOP()));
  this -> add_inst(__pack_mininsts(SMC_NOP(),SMC_NOP(),SMC_NOP(),SMC_NOP()));
  this -> add_inst(__pack_mininsts(SMC_NOP(),SMC_NOP(),SMC_NOP(),SMC_NOP()));
  this -> add_inst(__pack_mininsts(SMC_ACT(13,0,14,0),        // ACT B15 R0
                  SMC_NOP(),SMC_NOP(),SMC_NOP()));
  this -> add_inst(__pack_mininsts(SMC_NOP(),SMC_NOP(),SMC_NOP(),SMC_NOP()));
  this -> add_inst(__pack_mininsts(SMC_NOP(),SMC_NOP(),SMC_NOP(),SMC_NOP()));
  this -> add_inst(__pack_mininsts(SMC_WRITE(13,0,15,0,0,0),  // WRITE WDATA CONTENT
                  SMC_NOP(),SMC_NOP(),SMC_NOP()));
  this -> add_inst(__pack_mininsts(SMC_NOP(),SMC_NOP(),SMC_NOP(),SMC_NOP()));
  this -> add_inst(__pack_mininsts(SMC_NOP(),SMC_NOP(),SMC_NOP(),SMC_NOP()));
  this -> add_inst(__pack_mininsts(SMC_NOP(),SMC_NOP(),SMC_NOP(),SMC_NOP()));
  this -> add_inst(__pack_mininsts(SMC_READ(13,0,15,0,0,0),   // READ WDATA CONTENT
                  SMC_NOP(),SMC_NOP(),SMC_NOP()));

  for (int i = 0 ; i < 16 ; i++)                              // SWAP WDATA WITH REG VALUES
    this -> add_inst(SMC_LDWD(i,i));

  this -> add_inst(__pack_mininsts(SMC_WRITE(13,0,15,0,0,0),  // WRITE WDATA CONTENT
                  SMC_NOP(),SMC_NOP(),SMC_NOP()));
  this -> add_inst(__pack_mininsts(SMC_NOP(),SMC_NOP(),SMC_NOP(),SMC_NOP()));
  this -> add_inst(__pack_mininsts(SMC_NOP(),SMC_NOP(),SMC_NOP(),SMC_NOP()));
  this -> add_inst(__pack_mininsts(SMC_NOP(),SMC_NOP(),SMC_NOP(),SMC_NOP()));
  this -> add_inst(__pack_mininsts(SMC_READ(13,0,15,0,0,0),   // READ WDATA CONTENT
                  SMC_NOP(),SMC_NOP(),SMC_NOP()));

  this -> add_inst(__pack_mininsts(SMC_NOP(),SMC_NOP(),SMC_NOP(),SMC_NOP()));
  this -> add_inst(__pack_mininsts(SMC_NOP(),SMC_NOP(),SMC_NOP(),SMC_NOP()));
  this -> add_inst(__pack_mininsts(SMC_PRE(13,0,1),           // PRECHARGE ALL
                  SMC_NOP(),SMC_NOP(),SMC_NOP()));
}

bool Program::isDumpRegsCalled()
{
  return dumpRegsCalled;
}

void Program::debug(const std::string &prj_dir, bool first)
{
  int pid = fork();
  if(pid == 0){
    
    std::string source = prj_dir + "/source.tcl";
    std::string project = prj_dir + "/VU095.xpr";
    std::string arg;
    int fd = open("/dev/null", O_WRONLY);
    dup2(fd, 1);
    if(first)
      arg = "first";
    else
      arg = "debug";
    
    execl("/opt/Xilinx/Vivado/2018.2/bin/vivado",
          "vivado","-mode","tcl","-nojournal","-applog","-log","/tmp/asmc.log",
          "-source", source.c_str(), project.c_str(),"-tclargs", arg.c_str(), NULL);
    
  }else if(pid > 0){
    std::cout << "Debugger starting...\n";

    mkfifo("/tmp/fifo_1", 0666);
    int f1 = open("/tmp/fifo_1", O_WRONLY);
    mkfifo("/tmp/fifo_2", 0666);
    int f2 = open("/tmp/fifo_2", O_RDONLY);

    char buf[100];
    [[maybe_unused]] int rv;

    std::vector<std::string> vios;
    std::string line, start, end, vio;

    start = "sim_tb_top.mem_model_x8.memModels_Ri1[0].memModel1[0].ddr4_model.always_diff_ck.if_diff_ck:VIOLATION:";
    end = "sim_tb_top.mem_model_x8.memModels_Ri1[0].memModel1[1].ddr4_model.always_diff_ck.if_diff_ck:VIOLATION:";

    std::string msg, com, param,param2;
    std::vector<std::string> commands {"reg", "mem", "time", "step", "run", 
                                       "until", "exit", "btwn","stat"};

    int state = 0;

    while(state != 5){
      switch (state){
        case 0:
          std::cout << "Enter command: ";
          std::cin >> com;
          if(std::find(commands.begin(), commands.end(), com) != commands.end()){
            if(com == "step" || com == "exit" || com == "time" || com == "stat"){
              msg = com + "_\n";
            }else if(com == "btwn"){
              std::cin >> param;
              std::cin >> param2;
              msg = com + "_" + param + "_" + param2 + "\n";
            }else{
              std::cin >> param;
              msg = com + "_" + param + "\n";
            }
            state = 1;
          }else{
            std::cout << "Please enter a valid command...\n";
          }
          break;

        case 1:
          rv = write( f1, (char*)msg.c_str(), msg.size());
          memset(buf, 0, sizeof(buf));
          while(read(f2, buf, sizeof(buf)) == 0);
          state = 2;
          break;

        case 2:
          if(com == "reg" || com == "mem")
            std::cout << com << " " << param << ": " << buf;
          else if(com == "btwn")
            std::cout << "Time between "<< param << "-" << param2 << ": " << buf;
          else if(com == "time")
            std::cout << "Current time: " << buf;
          else if(com == "stat")
            std::cout << "Stats:\n" << buf;
          else if(com == "exit"){
            state = 5;
            break;
          }
          state = 3;
          break;

        case 3:
          std::ifstream logfile ("/tmp/asmc.log");
          while (std::getline(logfile, line))
          {
            if(line.find(start) != std::string::npos)
            {
              vio = line;
              if(std::find(vios.begin(), vios.end(), vio) != vios.end())
                continue;
              std::cout << line.substr(91) << "\n";
              while (std::getline(logfile, line))
              {
                if (line.find(end) != std::string::npos)
                  break;
                std::cout << line << "\n";
              }
              vios.insert(vios.begin(), vio);
            }
          }
          logfile.close();
          state = 0;
          break;

      }
    }
    close(f1);
    close(f2);
    wait(NULL);
    remove("/tmp/fifo_1");
    remove("/tmp/fifo_2");
    remove("/tmp/asmc.log");
    std::cout << "Exiting debugger.\n";
  }
}

void Program::debug(const std::string &prj_dir, const std::string &filename)
{
  int pid = fork();
  if(pid == 0){

    std::string source = prj_dir + "/source.tcl";
    std::string project = prj_dir + "/VU095.xpr";
    int fd = open("/dev/null", O_WRONLY);
    dup2(fd, 1);
    execl("/opt/Xilinx/Vivado/2018.2/bin/vivado",
          "vivado","-mode","tcl","-nojournal","-applog","-log","/tmp/asmc.log",
          "-source", source.c_str(), project.c_str(),"-tclargs", "update", NULL);
    
  }else if(pid > 0){

    std::string path, line, param, value, time_path, temp_path;
    
    path = prj_dir.substr(0, prj_dir.find("VU095")) + "phy_ddr4_ex/imports/";
    time_path = path + "timing_tasks.sv";
    temp_path = path + "temp.sv";

    std::ifstream timing_tasks (time_path);
    std::ifstream param_file (filename);
    std::ofstream temp_file (temp_path);

    std::map <std::string, std::string> params;

    while (std::getline(param_file, line)){
      param = line.substr(0, line.find("="));
      param = param.substr(param.find_first_not_of(" \n\r\t\f\v"),param.find_last_not_of(" \n\r\t\f\v") + 1);
      param = "    SetTSArray (i" + param;
      value = line.substr(line.find("=") + 1);
      value = value.substr(value.find_first_not_of(" \n\r\t\f\v"),value.find_last_not_of(" \n\r\t\f\v") + 1);
      value = std::string((7- value.size()), ' ') + value;
      params[param] = value;
    }
    param_file.close();

    while (std::getline(timing_tasks, line)){
      if(line.find("    SetTSArray (i") == std::string::npos){
        temp_file << line << "\n";
        continue;
      }
      for(const auto & param : params){
        if(line.find(param.first) != std::string::npos){
          line = line.replace(35, 7, param.second);
          break;
        }
      }
      temp_file << line << "\n";
    }

    timing_tasks.close();
    temp_file.close();
    remove(time_path.c_str());
    rename(temp_path.c_str(), time_path.c_str());
    wait(NULL);
    std::cout << "Timing parameters are updated...\n";
  }
}
