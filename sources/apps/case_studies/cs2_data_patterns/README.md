## Case Study #2: RowHammer: Data Patterns

### Instructions

1. run `make` to compile the DRAM Bender program
2. execute `./TEST <hc_per_aggr> <target_row> <aggr_pattern_select> <vic_pattern_select> <out_filename>` to run the experiment
    - hc_per_aggr: Total number of activation per aggressor row.
    - target_row: The target row for RH attack.
    - aggr_pattern_select: SoftMC for 0x00 to 0xFF patterns, DRAM-Bender for 256 random patterns.
    - vic_pattern_select: 0 for all-zeros, 1 for all-ones.
    - out_filename: output filename for the results. The output file has the bitflip locations for each victim row and aggr pattern.
