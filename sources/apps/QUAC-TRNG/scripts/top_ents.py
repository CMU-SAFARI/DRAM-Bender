import os
import argparse
import pandas as pd
import numpy as np

parser = argparse.ArgumentParser(description = "Postprocess entropy files and obtain top-10 segments with the highest entropy")
parser.add_argument('dimm', help="DIMM label")
parser.add_argument('pattern', help="4-bit data pattern [1000, 1001, 0111, etc]")
parser.add_argument('temp', help="temperature in centigrades")
args = parser.parse_args()

dimm = args.dimm
pattern = args.pattern
temp = args.temp

no_segments = 8192
no_bitlines = 512 * 128

fn = "data/" + dimm + "/ent/" + temp  + "C/1_1000_128_32768_" + pattern + "_floats.bin"
dirname = "data/" + dimm + "/ent/" + temp  + "C/"

arr = np.fromfile(fn, dtype=np.float32)
arr = arr.reshape(no_segments, no_bitlines)
arr = arr.sum(axis = 1)
indices = arr.argsort()[-10:][::-1]
print(indices)
print(arr[indices])

log = open(dirname + "top.txt", "w")
log.write("10\n")
for index in indices:
  # bank is always 1
  # multiply segment # by 4 to get starting row addr
  log.write("1 " + str(int(index) * 4) + " " + str(arr[index]) + " " + pattern + "\n")
log.close()
