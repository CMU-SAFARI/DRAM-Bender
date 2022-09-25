import os
import argparse
import subprocess
import time

parser = argparse.ArgumentParser(description = "Run this script to evaluate bitstreams")

parser.add_argument('dimm', help="DIMM label under test")
parser.add_argument('temperature', help="DIMM temperature in centigrades")

args = parser.parse_args()

# ---------------- SETUP DIRECTORIES ------------------- 

if not os.path.isdir("data"):
  os.mkdir("data")

if not os.path.isdir("data/" + args.dimm):
  os.mkdir("data/" + args.dimm)

if not os.path.isdir("data/" + args.dimm + "/vnc"):
  os.mkdir("data/" + args.dimm + "/vnc")

if not os.path.isdir("data/" + args.dimm + "/vnc/" + args.temperature + "C"):
  os.mkdir("data/" + args.dimm + "/vnc/" + args.temperature + "C")

if not os.path.isdir("data/" + args.dimm + "/vnc/" +
    args.temperature + "C/nist_results"):
  os.mkdir("data/" + args.dimm + "/vnc/" + args.temperature + "C/nist_results")

if not os.path.isdir("data/" + args.dimm + "/vnc/" +
    args.temperature + "C/binaries"):
  os.mkdir("data/" + args.dimm + "/vnc/" + args.temperature + "C/binaries")

outdir = os.path.normpath("data/" + args.dimm + "/vnc/" + args.temperature + "C/nist_results")
indir = os.path.normpath("data/" + args.dimm + "/vnc/" + args.temperature + "C/binaries")

if not os.path.isfile(indir + "/lastrow.txt"):
  input("I am going to overwrite 'lastrow.txt', proceed with caution")
  init_file = open(indir + "/lastrow.txt", "w")
  init_file.write(str(0) + "\n")

# Hard-reset SoftMC before other experiments
reset_path = os.path.normpath("bin/SoftMC_reset")
reset = subprocess.Popen("exec sudo " + reset_path, shell=True, preexec_fn=os.setpgrp)
time.sleep(5)
os.system("sudo pkill -9 -P" + str(os.getpgid(reset.pid)))
reset.wait()

# First run OBSERVE to collect von Neumann corrected bitstreams
observe_path = os.path.normpath("bin/OBSERVE " + indir)
observe_args = " > " + os.path.normpath(outdir + "/output.log")
observe = subprocess.Popen("exec sudo " + observe_path + observe_args, shell=True, preexec_fn=os.setpgrp)

# Watch the bitstream directory for new files
before = ["lastrow.txt"]

while True:
  time.sleep(1)
  after = os.listdir(indir) 
  s = set(before)
  diff = [x for x in after if x not in s]
  before = after
  if len(diff) == 0:
    continue

  bitstream = [[] for i in range(8)] # at most 8 STS runs
 
  # Partition 
  i = 0 
  for fname in diff:
    bitstream[i].append(fname)
    i = (i+1) % 8

  found = False
  for i in range(len(bitstream[0])):
    print("Finished " + str(i) + " out of " + str(len(bitstream[7])))
    processes = []
    for thr in range(0,8):
      if len(bitstream[thr]) <= i:
        break
      command_output = os.path.normpath(outdir + "/thr" + str(thr))
      command_input = os.path.normpath(indir + '/' + bitstream[thr][i])
      command = 'tools/sts -O -i 1 -I 1 -S '+ str(1024*1024) +' -w ' + command_output +' -F r ' + command_input + " 2>/dev/null"
      process = subprocess.Popen(command, shell=True)
      processes.append(process)

    # Collect statuses
    output = [p.wait() for p in processes]

    for thr in range(0,8):
      if len(bitstream[thr]) <= i:
        break
      res_txt = open(os.path.normpath(outdir + '/thr' + str(thr) + '/finalAnalysisReport.txt'), "r")
      lines = res_txt.readlines()
      n_success = 0
      for j in range(7, len(lines)):
        line = lines[j].strip()
        if not ("1" in line or "0" in line):
          break
        split = line.split()
        if "/" in split[11]:
          n_success += int(split[11].split("/")[0])
      res_txt.close()
      print(bitstream[thr][i] + " succeeded in " + str(n_success) + "tests + bits: " + str(1024*1024))
      if n_success < 187:
        os.system("rm -f " + indir + "/" + bitstream[thr][i])
      if n_success > 186:
        os.system("mkdir " + outdir + "/" + bitstream[thr][i])
        os.system("cp " + outdir + '/thr' + str(thr) + "/finalAnalysisReport.txt " + outdir + "/" + bitstream[thr][i])
      if n_success == 188:
        os.system("sudo pkill -9 -P" + str(os.getpgid(observe.pid)))
        observe.wait() # wait until the process actually terminates
        found = True
  if found:
    break

print("Finally found one cell that passes all NIST tests!")

# Reset SoftMC because last process was killed prematurely
reset_path = os.path.normpath("bin/SoftMC_reset")
reset = subprocess.Popen("exec sudo " + observe_path, shell=True, preexec_fn=os.setpgrp)
time.sleep(5)
os.system("sudo pkill -9 -P" + str(os.getpgid(reset.pid)))
reset.wait()
