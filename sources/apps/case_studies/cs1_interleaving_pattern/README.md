## Case Study #1: RowHammer: Interleaving Pattern of Activations

### Instructions

1. run `make` to compile the DRAM Bender program
2. execute `./TEST <hc_per_aggr> <cascade_amount> <data_pattern_select> <out_filename>` to run the experiment
    - hc_per_aggr: Total number of activation per aggressor row.
    - cascade_amount: The number of consecutive activations for a aggressor row. Value 1 results with double-sided RH attack.  
    - data_pattern_select: selects the data pattern for victim and aggressor rows.
    - out_filename: output filename for the results. The output file has the number of bitflips for each victim row.
