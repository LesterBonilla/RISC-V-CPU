# Build and Simulation

The `simulate.py` CLI automates building and simulating the RISC-V Architectural Tests. The `setup.sh` script can be sourced to add the `/scripts` directory to the system `PATH`, allowing `simulate.py` to be run as a command. It also exports the `PROJECT_ROOT` environment variable. Throughout the following steps, generated files are created or updated only if they do not exist or are detected to be stale.

## Building the Tests

1. `make` is run from `/external/riscv-arch-test/Makefile`. It generates .`elf` files based on this project's DUT configuration in `/riscv-arch-test-config`. The .`elf` files are placed in `/build/riscv-arch-test-work`.

2. `elf2hex.py` converts the `.elf` files to `.hex` files.

3. A SystemVerilog header is generated from the `.hex` files. It contains arrays of the hex file paths (e.g. `/buid/riscv-arch-tests-work/hex/I-add-00.hex`) and test names (e.g. `I-add-00`). It also defines a `localparam` with the size of the arrays/number of tests.

## Setting up the Simulation

1. A `filelist.f` is created by scanning the `/src` directory for `.sv` files. The compilation order is arranged so dependencies (`*_pkg.sv` files) are compiled before the modules that import them.

2. GUI and Console `.do` scripts use Questa `vlog` and `vsim` commands to compile the RTL and testbench using the generated `filelist.f`.

## Running the Tests

1. The testbench includes the generated header and loads each `.hex` file into memory using `$readmemh()`. 

2. Functions that halt the test on completion and print test summaries and debug information are defined in `/riscv-arch-test-config/rvmodel_macros.h`. The testbench reads writes to these addresses to determine when to load the next test and to print to the terminal with `$display()`

3. The testbench iterates the tests through a state machine and finishes once the final test completes.

## Debugging Tests

When debugging a specific test, you limit the run to a single extension or test using the `--extensions` or `--tests` flag.

```
simulate.py --debug --gui --tests ExceptionsSm-00
```

The `--debug` flag is passed to the `riscv-arch-test` Makefile and outputs objdump, trace, and trap report files from the reference model. This can be compared against the waveform and simulation output to determine where and how the DUT diverges from the reference.