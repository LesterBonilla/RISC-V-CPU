# RISC-V-CPU

## Description

This project implements an in-order 5-stage RV32I processor in SystemVerilog. The goal of this project is to implement the RV32G ISA along with common peripherals (UART, SPI, I2C). The ISA will be tested for correctness via the [RISC-V Architectural Compliance Tests (ACTs)](https://github.com/riscv/riscv-arch-test). The target FPGA for this project is the DE10-Lite development board using the MAX 10 chip.

## Features

- 5-stage in-order pipeline
- RV32I ISA
- Zicsr
- M-mode (CSRs, interrupts, and exceptions)
- Passed the RISC-V Architectural Compliance Tests (ACTs) for implemented extensions

## Architecture

This project implements a classic 5-stage in-order pipeline: Fetch, Decode, Execute, Memory access, and Writeback. Hazard control includes load-use stalls, forwarding to EX from MEM and WB, and flushing the pipeline for jumps and branches. The following diagram is inspired by and extended from material in "Digital Design and Computer Architecture: RISC-V Edition" by Harris and Harris.

![Diagram of the core's pipeline organization](/docs/Pipeline%20Architecture.svg)

CSRs and trap mechanism not shown to maintain clarity of the base RV32I structure.
<!-- TODO: Add CSR and Trap documentation to /docs, link to it here -->

## Getting Started

### Quick Start
---

1. Clone this repo recursively to clone the ACT submodule:

```
git clone --recursive https://github.com/LesterBonilla/RISC-V-CPU.git
```

If you cloned without the `--recursive` flag, you can get the submodule with this command:
```
git submodule update --init --recursive
```

2. Install dependencies as shown below.

3. Source the setup.sh script to add simulate.py to PATH and to export the PROJECT_ROOT environment variable: 

```
source setup.sh
```

4. Build the tests, compile the RTL source, and run the simulation with: 
```
simulate.py
````

### Dependencies
---

See the [RISC-V ACT README](external/riscv-arch-test/README.md) for instructions on how to install the required dependencies. Additionally, the user must have QuestaSim or ModelSim installed with `vsim` and `vlog` on their system PATH.

This project relies on:
- `riscv64-unknown-elf-gcc` with multilib support for RV32 cross-compilation. This builds the RV32 test programs.
- The `RISCV Architectural Certification Tests` (ACTs)
- The `Sail RISCV` reference model. The ACTs use this to build a signature for each test and embeds it into the self-checking `.elf` files for this project's configuration.
- `QuestaSim` or `ModelSim`. Used for simulation.
- `Python`. Used for automation in this project and for test generation by the ACT.
- `UV`. Used for Python environment management. Required by ACT.

For a full list of dependencies, see the [RISC-V ACT README](external/riscv-arch-test/README.md).

### `simulate.py` CLI
---
[simulate.py](scripts/simulate.py) is this project's build tool. It automates building the ACT `.elf` files, converting them to `.hex`, compiling the RTL, launching the simulation, and running the tests. See [Build and Simulation](docs/build_and_simulation.md) for more information.

To build and run the full test suite, run:
```
simulate.py
```

To use the gui use the `--gui` flag:
```
simulate.py --gui
```

To isolate one or more tests, run:
```
simulate.py --gui --tests TEST1,TEST2,...
```
Where `TEST` is the stem of the `.hex` or `.elf` file (e.g. `Zicsr-csrrci-00`).

To isolate one or more extensions, run:

```
simulate.py --gui --extensions EXT1,EXT2,...
```
Where `EXT` is the extension prefix (e.g. `Zicsr` or `I`)

For a full list of flags, run:

```
simulate.py --help
```

### Developing
---

1. Run the full test suite to verify a working state before starting a branch.

2. Write new RTL or make changes as needed for the new feature.

3. Write specific testbenches to verify new modules or run test cases for the specific extension or feature being added (`simulate.py --tests`/`--extensions`). Debug with the GUI if needed.

4. Once the feature is complete, run the full test suite to make sure there were no breaking changes.

5. Document the new changes and how they interact with other modules. Update any affected documentation in `/docs` and this file.

6. Open a pull request to merge the new feature.

## Future Work

- UART module
- AHB-Lite bus
- Zifence extension
- C extension
- M extension

## Helpful Links and References

[RISC-V Ratified Specifications Library](https://docs.riscv.org/reference/home/index.html)