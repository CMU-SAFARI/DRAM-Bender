"""DRAMBender — Commodity DRAM Reverse Engineering and Characterization Toolkit.

The user-facing API lives under `drambender.api`:

    from drambender.api import open_board, ProgramBuilder, program_template
    from drambender.api.program.instructions import *
    from drambender.api.jit import get_last_template_run_stats

User-extensible content lives at the top level in parallel with the api
package:

    drambender.builtin_programs   shipped test-program templates
    drambender.patterns           bitline / DQ data-pattern mappings
    drambender.rows               physical-to-logical row mappings
"""

from . import api, builtin_programs, patterns, rows
