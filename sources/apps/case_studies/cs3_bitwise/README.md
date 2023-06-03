## Case Study #3: In-DRAM Bitwise Operations

### Instructions

1. run `make` to compile the DRAM Bender program
2. execute `run_tests.sh` to generate data under `results` directory

### Data format

`run_tests.sh` creates one result file for each iteration of an AND and an OR experiment. For example, `AND-log1.csv` contains the results for the first iteration of an AND experiment.

A line in this file corresponds to a tested DRAM segment and contains the following comma separated information (taken from test.cpp, line 299):

```
row: The address of the first row in the tested segment
op_type: "AND" or "OR"
dp1: Value stored in the first operand
dp2: Value stored in the second operand
t1: Distance between the first ACT and the first PRE command
t2: Distance between the first PRE and the second ACT command
platext: Placement of the operands (see lines 244-264 in test.cpp)
errors: Number of bit errors in the output
```