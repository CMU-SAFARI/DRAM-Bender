#ifndef DRAMBENDER_API_BOARD_CMS_REGISTERS_H
#define DRAMBENDER_API_BOARD_CMS_REGISTERS_H

#include <cstdint>

// Register map for the Alveo Card Management Subsystem (CMS), as exposed on the
// XDMA user BAR of the U55C design.
//
// The offsets below are ported verbatim from the internal bscdrambender
// reference (sources/api/platform.cpp on the vivado-upgrade branch). They match
// the standard AMD CMS register space. They are only correct if the U55C
// bitstream maps the CMS register interface onto the user BAR at the same base;
// hardware consistency across the two projects is assumed (tracked separately).

namespace DRAMBender::cms {

// Control / status.
inline constexpr uint32_t k_mb_resetn_reg = 0x020000;    // CMS microcontroller reset.
inline constexpr uint32_t k_control_reg = 0x028018;      // Bit 27 enables HBM monitoring.
inline constexpr uint32_t k_host_status2_reg = 0x02830C;  // Bit 0: ready.

inline constexpr uint32_t k_control_hbm_monitor_enable_bit = (1u << 27);
inline constexpr uint32_t k_host_status2_ready_bit = (1u << 0);

// Each sensor exposes instantaneous / maximum / average registers.
struct RailRegs {
  uint32_t voltage_instant, voltage_max, voltage_average;  // millivolts
  uint32_t current_instant, current_max, current_average;  // milliamps
};

struct TempRegs {
  uint32_t instant, max, average;  // degrees Celsius
};

// 12V PCIe input rail.
inline constexpr RailRegs k_pex_12v{
    0x028028, 0x028020, 0x028024, 0x0280d0, 0x0280c8, 0x0280cc};
// 3.3V PCIe input rail.
inline constexpr RailRegs k_pex_3v3{
    0x028034, 0x02802c, 0x028030, 0x028280, 0x028278, 0x02827c};
// FPGA core (VCCINT).
inline constexpr RailRegs k_vccint{
    0x0280e8, 0x0280e0, 0x0280e4, 0x0280f4, 0x0280ec, 0x0280f0};
// FPGA I/O (VCCINT_IO).
inline constexpr RailRegs k_vccint_io{
    0x0282b0, 0x0282a8, 0x0282ac, 0x02828c, 0x028284, 0x028288};
// HBM 1.2V rail.
inline constexpr RailRegs k_hbm_1v2{
    0x028298, 0x028290, 0x028294, 0x028418, 0x028410, 0x028414};

// HBM stack temperatures.
inline constexpr TempRegs k_hbm_temp0{0x028268, 0x028260, 0x028264};
inline constexpr TempRegs k_hbm_temp1{0x0282BC, 0x0282B4, 0x0282B8};

// Highest register offset accessed, used to size the mmap window.
inline constexpr uint32_t k_highest_offset = 0x028418;

}  // namespace DRAMBender::cms

#endif  // DRAMBENDER_API_BOARD_CMS_REGISTERS_H
