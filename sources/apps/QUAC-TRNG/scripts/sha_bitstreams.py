import os
import argparse
import subprocess
import time

parser = argparse.ArgumentParser(description = "Collects sha bitstreams for a data pattern")

parser.add_argument('dimm', help="DIMM label under test")
parser.add_argument('pattern', help="data pattern to use")
parser.add_argument('temperature', help="DIMM temperature in centigrades")

args = parser.parse_args()

bitstreams_available = False

if not os.path.isdir("data/" + args.dimm + "/sha"):
  os.mkdir("data/" + args.dimm + "/sha")

if os.path.isdir("data/" + args.dimm + "/sha/" + args.temperature + "C"):
  bitstreams_available = True

if not os.path.isdir("data/" + args.dimm + "/sha/" + args.temperature + "C"):
  os.mkdir("data/" + args.dimm + "/sha/" + args.temperature + "C")

infile = os.path.normpath("data/" + args.dimm + "/ent/" + args.temperature + "C/top.txt")
outdir = os.path.normpath("data/" + args.dimm + "/sha/" + args.temperature + "C")

if not os.path.isdir("data/" + args.dimm + "/sha"):
  os.mkdir("data/" + args.dimm + "/sha_nist_results")

if not os.path.isdir("data/" + args.dimm + "/sha/" + args.temperature + "C"):
  os.mkdir("data/" + args.dimm + "/sha_nist_results/" + args.temperature + "C")

sha_output = os.path.normpath("data/" + args.dimm + "/sha_nist_results/" + args.temperature + "C")

if not bitstreams_available:
  sha_path = "bin/SHA"
  print("sudo " + sha_path + " " + outdir + " " + infile)
  os.system("sudo " + sha_path + " " + outdir + " " + infile)
else:
  print("I think we have the bitstreams available, I won't run softmc code again")

i=0
bitstream = []

for j in range(0,10):
  bitstream.append([])

for fname in os.listdir(outdir):
  bitstream[i].append(fname)
  i+=1
  i = i % 10

print(bitstream)

for i in range(len(bitstream[9])):
  print("Finished " + str(i) + " out of " + str(len(bitstream[9])))
  processes = []
  for thr in range(0,10):
    outpath = os.path.normpath(sha_output+'/thr'+str(thr))
    if not os.path.isdir(outpath):
      os.mkdir(outpath)
    command = 'tools/sts -O -i 1024 -I 1 -P 11=0.001 -S '+ str(1024*1024) +' -w '+ outpath +' -F r ' + outdir+'/'+bitstream[thr][i] + " 2>/dev/null"
    process = subprocess.Popen(command, shell=True)
    processes.append(process)
    print(command)

  # Collect statuses
  output = [p.wait() for p in processes]

  for thr in range(0,10):
    outpath = os.path.normpath(sha_output+'/thr'+str(thr))
    res_txt = open(outpath + '/finalAnalysisReport.txt', "r")
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
    if n_success > 186:
      os.system("mkdir "+sha_output+"/" + bitstream[thr][i])
      os.system("cp "+sha_output+'/thr'+str(thr)+"/finalAnalysisReport.txt "+sha_output+"/" + bitstream[thr][i])
