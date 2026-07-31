# compile.do
# Compiles rtl source files in the order presented in filelist.f.
# The filelist path is provided by the FILELIST environment variable.
#
# Usage: Called by other scripts (run_gui.do, run_console.do)
#
# Environment Variables:
#   SIM_WORKDIR : Path to the simulation working directory
#   FILELIST    : Path to filelist.f which contains an ordered list of paths to the RTL source files
#   BUILD_DIR   : Path of project build directory, contains generated .svh to be included in the testbench
#
# Warning suppressions:
#   13314: Defaulting input port kind to 'var' due to -svinputport=relaxed
#
# Compiler Flags:
#   -sv             : Enable SystemVerilog language support
#   -lint           : Enable static error checking
#   -incr           : Enable incremental compilation
#   -pedanticerrors : Enforce strict language checks
#   -suppress       : Supress warning messages for warnings listed above
#   -work           : Specifies the work library for the compiled design
#   -f              : Specify a file containing commands (the .sv source files to compile, in this case)
#   +incdir+        : Search this directory with 
#   -nolog          : Disable startup banner
#   -timescale      : Specifies default timescale for modules that don't have an explicit timescale
#   -svinputport    : Selects the default kind for an input port that is declared with a type but without the var keyword
#

onerror {quit -f}

if {![file isdirectory $env(SIM_WORKDIR)]} {
    vlib $env(SIM_WORKDIR)
}

vlog -sv -lint -incr -pedanticerrors -work $env(SIM_WORKDIR) -f $env(FILELIST) +incdir+$env(BUILD_DIR) -nologo -timescale 1ns/1ps -svinputport=net