# run_gui.do
# Compiles the project and runs simulation in GUI mode with waves added
#
# Environment variables:
#   SIM_WORKDIR : Path to the simulation working directory
#   TB_TOP      : Name of design file to be loaded (testbench)
#
# Flags:
#   -voptargs="+acc"    : Track all signals for the waveform
#   -lib                : Specify library directory
#
# Alias:
#   recompile : shortcut to run this script from QuestaSim transcript terminal  
#
# Catch:
#   quit -sim : Ignores a warning if there is no sim to quit. Helps kekep this script reusable through the alias.
#

alias recompile "do $env(SCRIPT_DIR)/run_gui.do"

catch {quit -sim}
do compile.do
vsim -quiet -voptargs="+acc" -lib $env(SIM_WORKDIR) $env(TB_TOP)
do wave.do