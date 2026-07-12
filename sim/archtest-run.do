# archtest-run.do
# Runs archtest_tb
# Usage: vsim -c -do ./archtest-run.do

onerror {quit -f}

set ROOT    ..
set WKDIR   ${ROOT}/sim/wkdir/work_archtest

vsim -lib   ${WKDIR} archtest_tb

run -all

quit