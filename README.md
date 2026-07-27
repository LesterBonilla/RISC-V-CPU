# RISC-V-CPU

## Description

This project implements an in-order 5-stage RV32I processor in System Verilog. The goal of this project is build toward supporting the RV32G while passing the riscv-arch-tests compliance tests and to implement an SoC with common peripherals (UART, SPI, I2C) with a simple ecosystem to flash programs. The target FPGA for this project is the DE10-lite development board using the MAX10 chip.

## Features

- 5-stage pipeline with hazard detection
- RV32I base instructions
- Zicsr extension
- M-mode support (CSRs, interrupts, and exceptions)
- RISC-V Architectural Certification Tests passing for currently implemented extensions

## Architecture

This project implements pipelining through the basic 5 stages: Fetch, Decode, Execute, Memory access, and Writeback. Hazard control is implemented for load-use stalls, forwarding to EX from MEM and WB, and flushing the pipeline for jumps and branches. The following diagram is inspired by and extended from material in "Digital Design and Computer Architecture: RISC-V Edition" by Harris and Harris.

![Diagram of the core's pipeline organization](/docs/Pipeline%20Architecture.svg)

CSRs and trap mechanism not shown to maintain clarity of the base RV32I structure.

## Roadmap

- ~~Configure test generation from riscv-arch-test to output tests for RV32I configuration~~
- ~~Convert .elf files to .hex for loading with System Verilog $readmemh~~
- ~~Automate running the self checking RV32I tests with .do files for regression testing~~
- ~~Automate generating a System Verilog header file containing file paths to the test hex files~~
- Fully automate running the tests with a single command
- Add method for generating .elf files from riscv-arch-test by adding it as a submodule
- Add information for installing the riscv32 compiler and other dependencies
- Add bash script for sourcing environment variables
~~- Support for Zicsr extension~~
- Support for Zifence extension
- Support for M extension

### Dependencies

riscv-arch-tests
riscv32 compiler
ModelSim
