# archtest-compile.do
# Compile archtest_tb and all files in /src 
# Usage: vsim -c -do ./archtest-compile.do\

# Warning suppressions:
# 13314: Defaulting input port kind to 'var' due to -svinputport=relaxed

onerror {quit -f}

set ROOT    ..
set SRC     ${ROOT}/src
set TB      ${ROOT}/testbench
set WKDIR   ${ROOT}/sim/wkdir/work_archtest

file mkdir ${WKDIR}
vlib ${WKDIR}

vlog -sv -lint -suppress 13314 -work ${WKDIR} ${SRC}/*_pkg.sv
vlog -sv -lint -suppress 13314 -work ${WKDIR} ${SRC}/*.sv ${TB}/archtest_tb.sv

quit