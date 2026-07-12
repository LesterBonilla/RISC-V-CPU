# general-compile.do
# Compile general_tb and all files in /src 
# Usage: vsim -c -do ./general-compile.do

# Warning suppressions:
# 13314: Defaulting input port kind to 'var' due to -svinputport=relaxed

onerror {quit -f}

set ROOT    ..
set SRC     ${ROOT}/src
set TB      ${ROOT}/testbench
set WKDIR   ${ROOT}/sim/wkdir/work_general

file mkdir ${WKDIR}
vlib ${WKDIR}

vlog -sv -lint -suppress 13314 -work ${WKDIR} ${SRC}/*_pkg.sv
vlog -sv -lint -suppress 13314 -work ${WKDIR} ${SRC}/*.sv ${TB}/general_tb.sv

quit