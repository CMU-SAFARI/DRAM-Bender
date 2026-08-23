// Host-only test for CMS telemetry decoding and derived power math.
// Uses a fake register map, so it needs no FPGA.

#include <cstdint>
#include <cstdio>
#include <map>
#include <stdexcept>

#include "api/board/cms_monitor.h"
#include "api/board/cms_registers.h"

using namespace DRAMBender;

static int failures = 0;

#define CHECK(cond, msg)                              \
  do {                                                \
    if (!(cond)) {                                    \
      std::fprintf(stderr, "FAIL: %s\n", (msg));      \
      ++failures;                                     \
    }                                                 \
  } while (0)

int main() {
  std::map<uint32_t, uint32_t> regs;

  const auto set_rail = [&](const cms::RailRegs& r, uint32_t vi, uint32_t vm,
                            uint32_t va, uint32_t ii, uint32_t im, uint32_t ia) {
    regs[r.voltage_instant] = vi;
    regs[r.voltage_max] = vm;
    regs[r.voltage_average] = va;
    regs[r.current_instant] = ii;
    regs[r.current_max] = im;
    regs[r.current_average] = ia;
  };
  const auto set_temp = [&](const cms::TempRegs& t, uint32_t i, uint32_t m, uint32_t a) {
    regs[t.instant] = i;
    regs[t.max] = m;
    regs[t.average] = a;
  };

  set_rail(cms::k_pex_12v, 12000, 12100, 11900, 2000, 2500, 1800);
  set_rail(cms::k_pex_3v3, 3300, 3350, 3250, 1000, 1200, 900);
  set_rail(cms::k_vccint, 850, 860, 845, 30000, 32000, 28000);
  set_rail(cms::k_vccint_io, 900, 910, 895, 5000, 5200, 4800);
  set_rail(cms::k_hbm_1v2, 1200, 1210, 1195, 8000, 9000, 7000);
  set_temp(cms::k_hbm_temp0, 45, 60, 48);
  set_temp(cms::k_hbm_temp1, 46, 61, 49);

  const auto read32 = [&](uint32_t off) -> uint32_t {
    const auto it = regs.find(off);
    if (it == regs.end()) {
      throw std::runtime_error("unexpected register offset");
    }
    return it->second;
  };

  const PowerTelemetry t = cms::decode_telemetry(read32);

  // Raw decode.
  CHECK(t.pex_12v.voltage_mv.instant == 12000, "pex_12v voltage instant");
  CHECK(t.pex_12v.current_ma.max == 2500, "pex_12v current max");
  CHECK(t.hbm_temp0_celsius.max == 60, "hbm temp0 max");
  CHECK(t.hbm_temp1_celsius.average == 49, "hbm temp1 average");

  // Derived per-rail power (mV * mA / 1000 = mW).
  CHECK(t.pex_12v.power_mw().instant == uint64_t{12000} * 2000 / 1000, "pex_12v power instant");
  CHECK(t.hbm.power_mw().average == uint64_t{1195} * 7000 / 1000, "hbm power average");

  // 64-bit math: 860 mV * 32000 mA / 1000 = 27520 mW (would be fine in 32-bit
  // here, but confirms the widened type is used).
  CHECK(t.vccint.power_mw().max == uint64_t{860} * 32000 / 1000, "vccint power max");

  // Total input power = 12V PEX + 3V3 PEX.
  const uint64_t expected_total =
      uint64_t{12000} * 2000 / 1000 + uint64_t{3300} * 1000 / 1000;
  CHECK(t.total_input_power_mw().instant == expected_total, "total input power instant");

  if (failures == 0) {
    std::printf("PASS: cms_telemetry_test\n");
  }
  return failures == 0 ? 0 : 1;
}
