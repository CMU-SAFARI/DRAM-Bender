import os
import argparse
from numpy import array

parser = argparse.ArgumentParser(description = "Run this script to preprocess entropy files")
parser.add_argument('indir', help="Path to entropy files")
args = parser.parse_args()

files = []
for fname in os.listdir(args.indir):
  files.append(fname)

for file in files:
  print("Processing:", file)
  # Add this placement
  fpath = os.path.normpath(args.indir + '/' + file)
  infile = open(fpath,'r')
  wfile = file.split('.')[0] + '_floats.bin'
  wfpath = os.path.normpath(args.indir + '/' + wfile)
  output_file = open(wfpath, 'wb')

  lines  = infile.readlines()

  # First row reserved for metadata
  for lidx in range(1,len(lines)):
    line     = lines[lidx].strip()
    split    = line.split()
    elements = [float(i) for i in split[1:]]    
    a = array(elements,'float32')
    a.tofile(output_file)

  output_file.close()