"""DRAMInspector — Commodity DRAM Reverse Engineering and Characterization Toolkit.

The user-facing API lives under `draminspector.api`:

    from draminspector.api import open_board, ProgramBuilder, program_template
    from draminspector.api.program.instructions import *
    from draminspector.api.jit import get_last_template_run_stats

User-extensible content lives at the top level in parallel with the api
package:

    draminspector.builtin_programs   shipped test-program templates
    draminspector.patterns           bitline / DQ data-pattern mappings
    draminspector.rows               physical-to-logical row mappings
"""

from . import api, builtin_programs, patterns, rows
