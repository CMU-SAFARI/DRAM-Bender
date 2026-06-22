#!/bin/bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <board> <bitstream-name-without-extension>"
  exit 1
fi

board=${1}
bitstream=${2}
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
prebuilt_dir="${script_dir}/../prebuilt"

bitfile_name="${prebuilt_dir}/${board}/${bitstream}.bit"
probesfile_name="${prebuilt_dir}/${board}/${bitstream}.ltx"

if [ -z "${VIVADO_EXEC:-}" ]
then
  echo "Please assign vivado executable's path to VIVADO_EXEC variable first!"
else
  echo "Trying to program the board with the prebuilt files ${bitfile_name}..."
  "$VIVADO_EXEC" -mode tcl -source "${script_dir}/program_fpga.tcl" -nolog -nojournal -tclargs "${bitfile_name}" "${probesfile_name}"
  echo "Done programming the board!"
fi
