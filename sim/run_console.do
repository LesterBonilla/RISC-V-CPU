# run_console.do
# Compiles the project and runs simulation in console mode
#
# Environment variables:
#   SIM_WORKDIR : Path to the simulation working directory
#   TB_TOP      : Name of design file to be loaded (testbench)
#
# Flags:
#   -quiet  : Disable 'loading' messages
#   -lib    : Specify library directory
#

onerror {quit -f}

do compile.do
vsim -quiet -lib $env(SIM_WORKDIR) $env(TB_TOP)
run -all
quit -f