#ifndef DRAMINSPECTOR_UTILS_DEBUG_H
#define DRAMINSPECTOR_UTILS_DEBUG_H

#include <array>
#include <cstddef>
#include <cstdint>
#include <string>

#include "draminspector/api/board/board.h"
#include "draminspector/api/program/program.h"

namespace DRAMBender::debug {

struct RegisterDump {
  std::array<std::byte, 64> wdata;
  std::array<uint32_t, 16> registers;
};

std::string format_program(const Program& program);
std::string format_program(const FinalProgram& program);
std::string format_program_binary(const Program& program);
std::string format_program_binary(const FinalProgram& program);
Program& append_register_dump(Program& program);
RegisterDump read_register_dump(IBoard& board);
std::string format_register_dump(const RegisterDump& dump);

}  // namespace DRAMBender::debug

#endif  // DRAMINSPECTOR_UTILS_DEBUG_H
