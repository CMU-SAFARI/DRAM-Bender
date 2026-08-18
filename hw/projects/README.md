# Vivado Project Skeletons

Each board directory keeps only the source-like files needed to reconstruct or
open the DRAM Bender Vivado project:

- the top-level `.xpr`
- board constraints
- `verilog/project.vh`
- PHY patch scripts and patch files, when the original project had them

Generated IP output, `ip_user_files`, run directories, caches, logs, and
simulation products are intentionally excluded from this clean repository.

Use `../scripts/generate.tcl` from a board project directory when running the
legacy batch generation flow.
