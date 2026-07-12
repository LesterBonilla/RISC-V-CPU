# general-run.do
# Runs general_tb
# Usage: vsim -do ./general-run.do

onerror {quit -f}

set ROOT    ..
set WKDIR   ${ROOT}/sim/wkdir/work_general

vsim -lib   ${WKDIR} general_tb

run -all