#ifndef DRAMINSPECTOR_SRC_UTILS_FORMATTING_INTERNAL_H
#define DRAMINSPECTOR_SRC_UTILS_FORMATTING_INTERNAL_H

#include <algorithm>
#include <array>
#include <cstddef>
#include <string>
#include <string_view>

namespace DRAMBender::formatting {

inline constexpr std::array<std::string_view, 16> k_register_aliases = {
    "CASR",
    "BASR",
    "RASR",
    "CAR",
    "BAR",
    "RAR",
    "PATTERN_REG",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
};

inline std::string_view register_alias(size_t register_id) {
  if (register_id >= k_register_aliases.size()) {
    return {};
  }
  return k_register_aliases[register_id];
}

inline std::string format_register_operand(size_t register_id) {
  const std::string_view alias = register_alias(register_id);
  if (!alias.empty()) {
    return std::string(alias);
  }
  return std::string("r") + std::to_string(register_id);
}

inline std::string format_register_listing(size_t register_id) {
  const std::string_view alias = register_alias(register_id);
  std::string label = std::string("R") + std::to_string(register_id);
  if (!alias.empty()) {
    label += " (" + std::string(alias) + ")";
  }
  return label;
}

inline size_t pc_width(size_t instruction_count) {
  const size_t last_pc = instruction_count == 0 ? 0 : instruction_count - 1;
  return std::max<size_t>(4, std::to_string(last_pc).size());
}

}  // namespace DRAMBender::formatting

#endif  // DRAMINSPECTOR_SRC_UTILS_FORMATTING_INTERNAL_H
