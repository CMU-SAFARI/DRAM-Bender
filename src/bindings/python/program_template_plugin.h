#ifndef DRAMINSPECTOR_PYTHON_BINDINGS_PROGRAM_TEMPLATE_PLUGIN_H
#define DRAMINSPECTOR_PYTHON_BINDINGS_PROGRAM_TEMPLATE_PLUGIN_H

#include <cstddef>
#include <cstdint>

namespace DRAMBender {
class FinalProgram;
}

extern "C" {

struct DRAMInspectorIntArrayArg {
  const int32_t* data;
  size_t length;
};

using DRAMInspectorInstantiateFn = int (*)(
    const int32_t* scalars,
    size_t scalar_count,
    const DRAMInspectorIntArrayArg* arrays,
    size_t array_count,
    DRAMBender::FinalProgram** out_program);

using DRAMInspectorPluginAbiVersionFn = uint32_t (*)();

}  // extern "C"

#endif  // DRAMINSPECTOR_PYTHON_BINDINGS_PROGRAM_TEMPLATE_PLUGIN_H
