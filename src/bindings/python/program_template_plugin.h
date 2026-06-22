#ifndef DRAMBENDER_PYTHON_BINDINGS_PROGRAM_TEMPLATE_PLUGIN_H
#define DRAMBENDER_PYTHON_BINDINGS_PROGRAM_TEMPLATE_PLUGIN_H

#include <cstddef>
#include <cstdint>

namespace DRAMBender {
class FinalProgram;
}

extern "C" {

struct DRAMBenderIntArrayArg {
  const int32_t* data;
  size_t length;
};

using DRAMBenderInstantiateFn = int (*)(
    const int32_t* scalars,
    size_t scalar_count,
    const DRAMBenderIntArrayArg* arrays,
    size_t array_count,
    DRAMBender::FinalProgram** out_program);

using DRAMBenderPluginAbiVersionFn = uint32_t (*)();

}  // extern "C"

#endif  // DRAMBENDER_PYTHON_BINDINGS_PROGRAM_TEMPLATE_PLUGIN_H
