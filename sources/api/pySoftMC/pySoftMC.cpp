#include "platform.h"
#include "instruction.h"
#include "prog.h"

#include "ext/pybind11/include/pybind11/pybind11.h"
namespace py = pybind11;

PYBIND11_MODULE(pySoftMC, m) 
{
  py::enum_<PC_TYPE>(m, "PC_TYPE")
      .value("WRITE", PC_TYPE::WRITE)
      .value("READ",  PC_TYPE::READ)
      .value("PRE",   PC_TYPE::PRE)
      .value("ACT",   PC_TYPE::ACT)
      .value("ZQ",    PC_TYPE::ZQ)
      .value("REF",   PC_TYPE::REF)
      .value("CYC",   PC_TYPE::CYC)
      .export_values();

  m.def("SMC_LD",    &SMC_LD,    py::arg("rb"),   py::arg("offset"), py::arg("rt"));
  m.def("SMC_ST",    &SMC_ST,    py::arg("rb"),   py::arg("offset"), py::arg("rt"));

  m.def("SMC_AND",   &SMC_AND,   py::arg("rs1"),  py::arg("rs2"),    py::arg("rt"));
  m.def("SMC_OR",    &SMC_OR,    py::arg("rs1"),  py::arg("rs2"),    py::arg("rt"));
  m.def("SMC_XOR",   &SMC_XOR,   py::arg("rs1"),  py::arg("rs2"),    py::arg("rt"));
  m.def("SMC_ADD",   &SMC_ADD,   py::arg("rs1"),  py::arg("rs2"),    py::arg("rt"));
  m.def("SMC_ADDI",  &SMC_ADDI,  py::arg("rs1"),  py::arg("imd"),    py::arg("rt"));
  m.def("SMC_SUB",   &SMC_SUB,   py::arg("rs1"),  py::arg("rs2"),    py::arg("rt"));
  m.def("SMC_SUBI",  &SMC_SUBI,  py::arg("rs1"),  py::arg("imd"),    py::arg("rt"));
  m.def("SMC_SRC",   &SMC_SRC,   py::arg("rs1"),  py::arg("rt"));

  m.def("SMC_LI",    &SMC_LI,    py::arg("imd"),  py::arg("rt"));
  m.def("SMC_MV",    &SMC_MV,    py::arg("rs1"),  py::arg("rt"));

  m.def("SMC_LDWD",  &SMC_LDWD,  py::arg("rs1"),  py::arg("offset"));
  m.def("SMC_LDPC",  &SMC_LDPC,  py::arg("type"), py::arg("rt"));

  m.def("SMC_BL",    &SMC_BL,    py::arg("rs1"),  py::arg("rs2"),    py::arg("tgt"));
  m.def("SMC_BEQ",   &SMC_BEQ,   py::arg("rs1"),  py::arg("rs2"),    py::arg("tgt"));
  m.def("SMC_JUMP",  &SMC_JUMP,  py::arg("tgt"));

  m.def("SMC_END",   &SMC_END);
  m.def("SMC_INFO",  &SMC_INFO,  py::arg("rdcnt"));
  m.def("SMC_SLEEP", &SMC_SLEEP, py::arg("samt"));

  m.def("SMC_WRITE", &SMC_WRITE, py::arg("bar"),  py::arg("ibar"),   py::arg("car"), py::arg("icar"), py::arg("BL4"), py::arg("ap"));
  m.def("SMC_READ",  &SMC_READ,  py::arg("bar"),  py::arg("ibar"),   py::arg("car"), py::arg("icar"), py::arg("BL4"), py::arg("ap"));
  m.def("SMC_PRE",   &SMC_PRE,   py::arg("bar"),  py::arg("ibar"),   py::arg("pall"));
  m.def("SMC_ACT",   &SMC_ACT,   py::arg("bar"),  py::arg("ibar"),   py::arg("rar"), py::arg("irar"));

  m.def("SMC_ZQ",    &SMC_ZQ);
  m.def("SMC_REF",   &SMC_REF);
  m.def("SMC_NOP",   &SMC_NOP);
  m.def("SMC_SRE",   &SMC_SRE);
  m.def("SMC_SRX",   &SMC_SRX);

  m.def("__pack_mininsts",  &__pack_mininsts, py::arg("i1"), py::arg("i2"), py::arg("i3"), py::arg("i4"));

  py::class_<SoftMCPlatform>(m, "SoftMCPlatform")
    .def(py::init())
    .def("init",              &SoftMCPlatform::init)
    .def("reset_fpga",        &SoftMCPlatform::reset_fpga)
    .def("execute",           &SoftMCPlatform::execute,     py::arg("program"))
    .def("receiveData",       &SoftMCPlatform::py_receiveData, py::arg("num_words"))
    .def("get_buffer_memoryview", &SoftMCPlatform::get_buffer_memoryview)
    .def("set_aref",          &SoftMCPlatform::set_aref,    py::arg("on"))
    .def("readRegisterDump",  &SoftMCPlatform::readRegisterDump)
    .def("count_bitflips_in_row", &SoftMCPlatform::count_bitflips_in_row, py::arg("char_data"));

  py::class_<Program> program(m, "Program");

  py::enum_<Program::SEQ_TYPE>(program, "SEQ_TYPE")
    .value("WRITE", Program::SEQ_TYPE::WRITE)
    .value("READ",  Program::SEQ_TYPE::READ)
    .export_values();

  py::enum_<Program::BR_TYPE>(program, "BR_TYPE")
    .value("BEQ",   Program::BR_TYPE::BEQ)
    .value("BL",    Program::BR_TYPE::BL)
    .value("JUMP",  Program::BR_TYPE::JUMP)
    .export_values();

  program
    .def(py::init())
    .def("add_mininst",         &Program::add_mininst,  py::arg("mi"), py::arg("wait_after"))
    .def("add_wait",            &Program::add_wait,     py::arg("wait_cycles"))
    .def("pack_minprogram",     &Program::pack_minprogram)
    .def("add_inst",            py::overload_cast<Inst>(&Program::add_inst),     py::arg("inst"))
    .def("add_inst",            py::overload_cast<Mininst, Mininst, Mininst, Mininst>(&Program::add_inst))
    .def("add_label",           &Program::add_label,    py::arg("name"))
    .def("add_branch",          &Program::add_branch,   py::arg("type"), py::arg("rs1"), py::arg("rs2"), py::arg("tgt"))
    .def("add_below",           &Program::add_below)
    .def("pretty_print",        &Program::pretty_print)
    .def("dump_registers",      &Program::dump_registers);
}
