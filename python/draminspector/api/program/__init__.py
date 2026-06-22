"""Program authoring: DSL for building DRAM Bender test programs.

Typical imports:

    from draminspector.api.program import ProgramBuilder, program_template
    from draminspector.api.program.instructions import *

The `instructions` submodule holds the DRAM command factories (ACT, NOP,
PRE, RD, WR, REF, SEL_CH, ALIGN). The `raw_instructions` submodule holds
low-level SMC instruction factories for direct `Program.add_inst(...)`
construction.
"""

from draminspector._core import FinalProgram, Program
from draminspector._jit import program_template

from .builder import ProgramBuilder

__all__ = [
    "FinalProgram",
    "Program",
    "ProgramBuilder",
    "program_template",
]
