#include "instruction.h"
#include "prog.h"
#include "platform.h"
#include "tools.h"

#include <string>
#include <fstream>
#include <iostream>
#include <list>
#include <cassert>
#include <bitset>
#include <chrono>
#include <math.h>

#include <array>
#include <algorithm>
#include <numeric>
#include <ctime>

// #define PRINT_SOFTMC_PROGS

using namespace std;

#define CASR 0
#define BASR 1
#define RASR 2

#define NUM_SOFTMC_REGS 16
#define FPGA_PERIOD 1.5015f // ns

#define RED_TXT "\033[31m"
#define GREEN_TXT "\033[32m"
#define YELLOW_TXT "\033[33m"
#define BLUE_TXT "\033[34m"
#define MAGENTA_TXT "\033[35m"
#define NORMAL_TXT "\033[0m"

int NUM_BANKS = 16; // this is the total number of banks in the chip
int NUM_BANK_GROUPS = 4;
int NUM_ROWS  = 32768;
int ROW_SIZE = 8192;
int NUM_COLS_PER_ROW = 128;
int CHIP_NUM = 4;
int CACHE_LINE_BITS = 512;

float DEFAULT_TRCD = 13.5f; // ns
float DEFAULT_TRAS = 35.0f; // ns
float DEFAULT_TRP = 13.5f; // ns
float DEFAULT_TWR = 15.0f; // ns
float DEFAULT_TRFC = 260.0f; // ns
float DEFAULT_TRRDS = 5.3f; // ns (ACT-ACT to different bank groups)
float DEFAULT_TRRDL = 6.4f; // ns (ACT-ACT to same bank group)
float DEFAULT_TREFI = 7800.0f;

int trcd_cycles = (int) ceil(DEFAULT_TRCD/FPGA_PERIOD);
int tras_cycles = (int) ceil(DEFAULT_TRAS/FPGA_PERIOD);
int trp_cycles = (int) ceil(DEFAULT_TRP/FPGA_PERIOD);
int twr_cycles = (int) ceil(DEFAULT_TWR/FPGA_PERIOD);
int trfc_cycles = (int) ceil(DEFAULT_TRFC/FPGA_PERIOD);
int trrds_cycles = (int) ceil(DEFAULT_TRRDS/FPGA_PERIOD);
int trrdl_cycles = (int) ceil(DEFAULT_TRRDL/FPGA_PERIOD);
int trefi_cycles = (int) ceil(DEFAULT_TREFI/FPGA_PERIOD);

bitset<512> vic_data_pattern, aggr_data_pattern;
vector<uint32_t> reserved_regs{CASR, BASR, RASR};

typedef struct RowSet {
    vector<uint> victim_ids;
    vector<uint> aggr_ids;
    uint bank_id;
} RowSet;

void init_program(Program& prog){
    add_op_with_delay(prog, SMC_PRE(0, 0, 1), 0, trp_cycles); // precharge all banks
}

void end_program(Program& prog){   
    prog.add_inst(all_nops());
    prog.add_inst(SMC_END());
}

void init_row(Program* prog, SoftMCRegAllocator* reg_alloc, const uint target_bank, const uint target_row, const bool is_victim){

    SMC_REG reg_row_addr = reg_alloc->allocate_SMC_REG();
    SMC_REG reg_col_addr = reg_alloc->allocate_SMC_REG();
    SMC_REG reg_bank_addr = reg_alloc->allocate_SMC_REG();
    SMC_REG reg_num_cols = reg_alloc->allocate_SMC_REG();
    SMC_REG reg_wrdata = reg_alloc->allocate_SMC_REG();

    bitset<512> bitset_int_mask(0xFFFFFFFF);
    bitset<512> data_pattern;

    if(is_victim)
        data_pattern = vic_data_pattern;
    else
        data_pattern = aggr_data_pattern;
    
    prog->add_inst(SMC_LI(NUM_COLS_PER_ROW*8, reg_num_cols));
    prog->add_inst(SMC_LI(target_bank, reg_bank_addr));
    prog->add_inst(SMC_LI(target_row, reg_row_addr));
    prog->add_inst(SMC_LI(8, CASR));

    // set up the input data in the wide register
    for(int pos = 0; pos < 16; pos++){
        prog->add_inst(SMC_LI((((data_pattern >> 32*pos) & bitset_int_mask).to_ulong() & 0xFFFFFFFF), reg_wrdata));
        prog->add_inst(SMC_LDWD(reg_wrdata, pos));
    }

    // activate the target row
    uint remaining = add_op_with_delay(*prog, SMC_ACT(reg_bank_addr, 0, reg_row_addr, 0), 0, trcd_cycles - 5);

    // write data to the row and precharge
    prog->add_inst(SMC_LI(0, reg_col_addr));

    string new_lbl = createSMCLabel("INIT_ROW");
    prog->add_label(new_lbl);
    add_op_with_delay(*prog, SMC_WRITE(reg_bank_addr, 0, reg_col_addr, 1, 0, 0), 0, 0);
    prog->add_branch(Program::BR_TYPE::BL, reg_col_addr, reg_num_cols, new_lbl);
    
    // precharge the open bank
    add_op_with_delay(*prog, SMC_PRE(reg_bank_addr, 0, 0), 0, trp_cycles);

    reg_alloc->free_SMC_REG(reg_row_addr);
    reg_alloc->free_SMC_REG(reg_col_addr);
    reg_alloc->free_SMC_REG(reg_wrdata);
    reg_alloc->free_SMC_REG(reg_bank_addr);
    reg_alloc->free_SMC_REG(reg_num_cols);

}

void init_rs(Program* prog, SoftMCRegAllocator* reg_alloc, const RowSet rs) {
    //init aggrs
    for(auto aggr_id: rs.aggr_ids)
        init_row(prog, reg_alloc, rs.bank_id, aggr_id, false);
    //init victims
    for(auto victim_id: rs.victim_ids)
        init_row(prog, reg_alloc, rs.bank_id, victim_id, true);
}

void hammer_rs(Program* prog, SoftMCRegAllocator* reg_alloc, const RowSet rs, 
               const uint hc_per_run, const uint num_runs){

    SMC_REG reg_bank_addr = reg_alloc->allocate_SMC_REG();
    SMC_REG reg_row_addr = reg_alloc->allocate_SMC_REG();
    SMC_REG reg_num_hammers = reg_alloc->allocate_SMC_REG();
    SMC_REG reg_cur_hammers = reg_alloc->allocate_SMC_REG();
    SMC_REG reg_num_runs = reg_alloc->allocate_SMC_REG();
    SMC_REG reg_cur_runs = reg_alloc->allocate_SMC_REG();

    prog->add_inst(SMC_LI(rs.bank_id, reg_bank_addr));
    prog->add_inst(SMC_LI(hc_per_run, reg_num_hammers));
    prog->add_inst(SMC_LI(num_runs, reg_num_runs));

    prog->add_inst(SMC_LI(0, reg_cur_runs));
    string lbl_hammer_run = createSMCLabel("HAMMER_RUN");
    prog->add_label(lbl_hammer_run);

    for(auto aggr_id: rs.aggr_ids){
        prog->add_inst(SMC_LI(aggr_id, reg_row_addr));
        prog->add_inst(SMC_LI(0, reg_cur_hammers));

        string lbl_rh = createSMCLabel("ROWHAMMERING");
        prog->add_label(lbl_rh);

        uint remaining_cycs = add_op_with_delay(*prog, SMC_ACT(reg_bank_addr, 0, reg_row_addr, 0), 0, tras_cycles - 1);
        remaining_cycs = add_op_with_delay(*prog, SMC_PRE(reg_bank_addr, 0, 0), remaining_cycs, 0);
    
        prog->add_inst(SMC_ADDI(reg_cur_hammers, 1, reg_cur_hammers));
        prog->add_branch(Program::BR_TYPE::BL, reg_cur_hammers, reg_num_hammers, lbl_rh);
    
    }

    prog->add_inst(SMC_ADDI(reg_cur_runs, 1, reg_cur_runs));
    prog->add_branch(Program::BR_TYPE::BL, reg_cur_runs, reg_num_runs, lbl_hammer_run);

    reg_alloc->free_SMC_REG(reg_bank_addr);
    reg_alloc->free_SMC_REG(reg_row_addr);
    reg_alloc->free_SMC_REG(reg_num_hammers);
    reg_alloc->free_SMC_REG(reg_cur_hammers);
    reg_alloc->free_SMC_REG(reg_num_runs);
    reg_alloc->free_SMC_REG(reg_cur_runs);
}

void read_row(Program* prog, SoftMCRegAllocator* reg_alloc, const uint bank_id, const uint row_id){

    SMC_REG reg_bank_addr = reg_alloc->allocate_SMC_REG();
    SMC_REG reg_num_cols = reg_alloc->allocate_SMC_REG();
    SMC_REG reg_row_addr = reg_alloc->allocate_SMC_REG();
    SMC_REG reg_col_addr = reg_alloc->allocate_SMC_REG();

    prog->add_inst(SMC_LI(8, CASR));
    prog->add_inst(SMC_LI(NUM_COLS_PER_ROW*8, reg_num_cols));
    prog->add_inst(SMC_LI(bank_id, reg_bank_addr));
    prog->add_inst(SMC_LI(row_id, reg_row_addr));

    // activate the victim row
    add_op_with_delay(*prog, SMC_ACT(reg_bank_addr, 0, reg_row_addr, 0), 0, trcd_cycles - 5);
    prog->add_inst(SMC_LI(0, reg_col_addr));
    
    // read data from the row and precharge
    string new_lbl = createSMCLabel("READ_ROW");
    prog->add_label(new_lbl);
    add_op_with_delay(*prog, SMC_READ(reg_bank_addr, 0, reg_col_addr, 1, 0, 0), 0, 0);
    prog->add_branch(Program::BR_TYPE::BL, reg_col_addr, reg_num_cols, new_lbl);

    // precharge the open bank
    add_op_with_delay(*prog, SMC_PRE(reg_bank_addr, 0, 0), 0, trp_cycles);

    reg_alloc->free_SMC_REG(reg_bank_addr);
    reg_alloc->free_SMC_REG(reg_num_cols);
    reg_alloc->free_SMC_REG(reg_row_addr);
    reg_alloc->free_SMC_REG(reg_col_addr);
    
}

void read_rs(Program* prog, SoftMCRegAllocator* reg_alloc, const RowSet rs){
    for(auto victim_id: rs.victim_ids)
        read_row(prog, reg_alloc, rs.bank_id, victim_id);
}

vector<uint> collect_bitflips(const char* read_data){

    bitset<512> read_data_bitset;
    vector<uint> bitflips;
    uint32_t* iread_data = (uint32_t*) read_data;
    uint bit_loc;

    // check for bitflips in each cache line
    for(int cl = 0; cl < ROW_SIZE/64; cl++) {
        read_data_bitset.reset();
        for(int i = 0; i < 512/32; i++) {
            bitset<512> tmp_bitset = iread_data[cl*(512/32) + i];

            read_data_bitset |= (tmp_bitset << i*32);
        }
        // compare and print errors
        bitset<512> error_mask = read_data_bitset ^ vic_data_pattern;
        if(error_mask.any()) {
            // there is at least one bitflip in this cache line
            for(uint i = 0; i < error_mask.size(); i++){
                if(error_mask.test(i)){
                    bit_loc = cl*CACHE_LINE_BITS + i;
                    bitflips.push_back(bit_loc);
                }
            }
        }
    }
    
    return bitflips;
}

vector<uint> get_bitflips(SoftMCPlatform& platform, const RowSet& rs){
    
    vector<uint> num_bitflips;
    uint read_data_size = ROW_SIZE*rs.victim_ids.size();

    char buf[read_data_size*2];

    platform.receiveData(buf, read_data_size);
    for(uint vic_ind = 0; vic_ind < rs.victim_ids.size(); vic_ind++){
        auto bitflips = collect_bitflips(buf + vic_ind*ROW_SIZE);
        num_bitflips.push_back(bitflips.size());
    }
    return num_bitflips;
}

vector<uint> run_single_test(SoftMCPlatform& platform, const RowSet rs, 
                             const uint hc_per_run, const uint num_runs,
                             const uint remaining_hc){

    Program prog;
    SoftMCRegAllocator reg_alloc = SoftMCRegAllocator(NUM_SOFTMC_REGS, reserved_regs);
    
    init_program(prog);
    // INIT DATA
    init_rs(&prog, &reg_alloc, rs);

    // HAMMER 
    if(hc_per_run > 0)
        hammer_rs(&prog, &reg_alloc, rs, hc_per_run, num_runs);
    if(remaining_hc > 0)
        hammer_rs(&prog, &reg_alloc, rs, remaining_hc, 1);

    // READ DATA
    read_rs(&prog, &reg_alloc, rs);

    // END PROGRAM
    end_program(prog);

    #ifdef PRINT_SOFTMC_PROGS
    std::cout << "--- SoftMCProg ---" << std::endl;
    prog.pretty_print(); // DEBUG
    #endif

    // EXECUTE PROGRAM
    platform.execute(prog);

    return get_bitflips(platform, rs);
}

RowSet get_rowset(string rh_pattern, uint bank, uint row){
    RowSet rs;

    rs.bank_id = bank;
    for(int i = 0; i < rh_pattern.length(); i++){
        if(rh_pattern.at(i) == 'A')
            rs.aggr_ids.push_back(to_physical_row_id(row + i));
        else if(rh_pattern.at(i) == 'V')
            rs.victim_ids.push_back(to_physical_row_id(row + i));
    }

    return rs;
}

int main(int argc, char** argv){

    //========================Program Options========================
    string rh_pattern = "VAVAV";
    uint target_bank = 1;
    uint arg_log_phys_conv_scheme = 0;
    uint data_pattern_select = 2;
    uint cascade_amount = 1;
    uint hc = 1000;
    string out_filename = "";

    if (argc != 5) {
        cerr << RED_TXT << "Usage: " << argv[0] << " <hc_per_aggr> <cascade_amount> <data_pattern_select> <out_filename>" << NORMAL_TXT << endl;
        return -1;
    }

    hc = atoi(argv[1]);
    cascade_amount = atoi(argv[2]);
    data_pattern_select = atoi(argv[3]);
    out_filename = argv[4];

    //========================Input Checking========================
    if(!(data_pattern_select >= 0 && data_pattern_select < 8)){
        cerr << RED_TXT << "--data_pattern should be between 0 and 8." << NORMAL_TXT << endl;
        return -1;
    }
    //========================Platform Config========================
    SoftMCPlatform platform;
    int err;
    if((err = platform.init()) != SOFTMC_SUCCESS){
        cerr << "Could not initialize SoftMC Platform: " << err << endl;
        return err;
    }
    platform.reset_fpga();  
    platform.set_aref(false); // disable refresh
    //========================Out_file Config========================
    std::ofstream out_file;
    if(out_filename != ""){
        out_file.open(out_filename);
    }else{
        out_file.open("/dev/null");
    }
    //========================Parse Inputs========================
    // Logical to physical conversion
    logical_physical_conversion_scheme = (LogPhysRowIDScheme) arg_log_phys_conv_scheme;
    // Input Row Data
    const uint vic_patterns[]  = {0x00000000, 0xFFFFFFFF, 0x55555555, 0xAAAAAAAA, 0x55555555, 0xAAAAAAAA, 0x00000000, 0xFFFFFFFF};
    const uint aggr_patterns[] = {0xFFFFFFFF, 0x00000000, 0x55555555, 0xAAAAAAAA, 0xAAAAAAAA, 0x55555555, 0x00000000, 0xFFFFFFFF};
    for(int i = 0; i < 16; i++){
        vic_data_pattern <<=32;
        vic_data_pattern |= vic_patterns[data_pattern_select];
        aggr_data_pattern <<=32;
        aggr_data_pattern |= aggr_patterns[data_pattern_select];
    }
    //========================Parameter Calculations========================
    uint total_victims = count(rh_pattern.begin(), rh_pattern.end(), 'V');
    uint total_aggrs = count(rh_pattern.begin(), rh_pattern.end(), 'A');

    uint hc_per_run = (cascade_amount != -1)? cascade_amount: hc;
    uint num_runs = (uint) floor(hc/hc_per_run);
    uint remaining_hc = hc - hc_per_run*num_runs;
    //========================Information========================
    out_file << "RH_pattern: " << rh_pattern << endl
             << "HC_per_run: " << hc_per_run << endl
             << "Num_runs: " << num_runs << endl
             << "Remaining hc: " << remaining_hc << endl
             << "Total_hc: " << hc << endl
             << "Results" << endl
             << "====================" << endl;
    //========================Run Analyzer========================


    vector<uint> total_bitflips(total_victims, 0);


    for(uint r = 0; r < NUM_ROWS; r++){

        RowSet rs = get_rowset(rh_pattern, target_bank, r);

        auto num_bitflips = run_single_test(platform, rs, hc_per_run, num_runs, remaining_hc);

        if(accumulate(num_bitflips.begin(), num_bitflips.end(), 0) > 0){
            out_file << "Row " << r << ": ";

            uint bitflips_ind = 0;

            for(int i = 0; i < rh_pattern.length(); i++){
                if(rh_pattern.at(i) == 'V'){
                    out_file << num_bitflips[bitflips_ind] << "-";
                    total_bitflips[bitflips_ind] += num_bitflips[bitflips_ind];
                    bitflips_ind++;
                }else if(rh_pattern.at(i) == 'A'){
                    out_file << "A-";
                }else{
                    out_file << "_-";
                }
            }
            out_file << endl;
        }

    }
    
    out_file << "Total bitflips: ";
    uint bitflips_ind = 0;
    for(int i = 0; i < rh_pattern.length(); i++){
        if(rh_pattern.at(i) == 'V'){
            out_file << total_bitflips[bitflips_ind++] << "-";
        }else if(rh_pattern.at(i) == 'A'){
            out_file << "A-";
        }else{
            out_file << "_-";
        }
    }
    out_file << endl;

    cout << "The test has finished!" << endl;

    out_file.close();

    return 0;
}