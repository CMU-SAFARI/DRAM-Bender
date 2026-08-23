"""Program authoring: DSL for building DRAM Bender test programs.

Typical imports:

    from drambender.api.program import DDR4Target, ProgramBuilder, program_template
    from drambender.api.program.instructions import *

The `instructions` submodule holds the DRAM command factories (ACT, NOP,
PRE, RD, WR, REF, SEL_CH, ALIGN). The `raw_instructions` submodule holds
low-level SMC instruction factories for direct `Program.add_inst(...)`
construction.
"""

from drambender._core import FinalProgram, Program
from drambender._jit import program_template

from .builder import ProgramBuilder
from .targets import DDR4Target, HBM2Target, HBM2U50Target, HBM2U55CTarget

__all__ = [
    "DDR4Target",
    "FinalProgram",
    "HBM2Target",
    "HBM2U50Target",
    "HBM2U55CTarget",
    "Program",
    "ProgramBuilder",
    "program_template",
]
