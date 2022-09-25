#!/bin/bash

params_list="board slot dimm_type rank DQ"

allowed_board="XCU200 XUSP3S XUPP3R XUPVVH"
allowed_slot="C1 C2 C3 C4"
allowed_dimm_type="UDIMM RDIMM SODIMM"
allowed_rank="1R 2R"
allowed_DQ="x4 x8 x16"

board=${1}
slot=${2}
dimm_type=${3}
rank=${4}
DQ=${5}

# x16 and x8 bitstreams are interchangeable
if [[ ${DQ} == "x16" ]];
then
  DQ="x8"
fi

function contains() 
{
  token=${1}
  list=${2}
  for _token in ${list};
  do
    if [ "${_token}" == "${token}" ]; 
    then
      return 1
    fi
  done
  return 0
}

input_OK=true
for param in ${params_list};
do
  list_name=allowed_${param}
  
  if contains ${!param} "${!list_name}";
  then
    echo "Unrecognized ${param} \"${!param}\", supported values: ${!list_name}"
    input_OK=false
  fi
done
if ! ${input_OK};
then
  exit -1
fi

board_id=0

bitfile_name=${board}/${board}_${slot}_${dimm_type}_${rank}_${DQ}.bit
probesfile_name=${board}/${board}_${slot}_${dimm_type}_${rank}_${DQ}.ltx

if [ -z "$VIVADO_EXEC" ]
then
  echo "Please assign vivado executable's path to VIVADO_EXEC variable first!"
else
  echo "Trying to program the board with the prebuilt files ${bitfile_name}..."
  $VIVADO_EXEC -mode tcl -source $( dirname "${BASH_SOURCE[0]}")/programFPGA.tcl -nolog -nojournal -tclargs ${bitfile_name} ${probesfile_name}
  echo "Done programming the board!"
fi
