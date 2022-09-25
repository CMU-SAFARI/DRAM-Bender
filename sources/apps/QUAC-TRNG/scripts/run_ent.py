import os
import argparse
import subprocess
import time

parser = argparse.ArgumentParser(description = "Collects entropy for different data patterns")

parser.add_argument('dimm', help="DIMM label under test")
parser.add_argument('temperature', help="DIMM temperature in centigrades")
parser.add_argument('iters', help="How many times do we QUAC to find entropy")
parser.add_argument('stride', help="Stride (in rows) used to skim through segments, default: 4")

args = parser.parse_args()

# ---------------- SETUP DIRECTORIES ------------------- 

if not os.path.isdir("data"):
  os.mkdir("data")

if not os.path.isdir("data/" + args.dimm):
  os.mkdir("data/" + args.dimm)

if not os.path.isdir("data/" + args.dimm + "/ent"):
  os.mkdir("data/" + args.dimm + "/ent")

if not os.path.isdir("data/" + args.dimm + "/ent/" + args.temperature + "C"):
  os.mkdir("data/" + args.dimm + "/ent/" + args.temperature + "C")

outdir = os.path.normpath("data/" + args.dimm + "/ent/" + args.temperature + "C")

# -------------------- RUN TESTS -----------------------

placements = ["1000", "1001", "1010", "1011", "1100" , "1101", "1110", "1111", \
              "0111", "0110", "0101", "0100", "0011" , "0010", "0001", "0000"]

ent_path = os.path.normpath("bin/ENT")
results_path = outdir
stride = args.stride
iters = args.iters

for placement in placements:
  print("sudo " + ent_path + " " + results_path + " " + placement + " " + stride + " " + iters)
  os.system("sudo " + ent_path + " " + results_path + " " + placement + " " + stride + " " + iters)
