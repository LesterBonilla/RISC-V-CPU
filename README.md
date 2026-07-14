# RISC-V-CPU

## Description

This project implements an in-order 5-stage RV32I processor in System Verilog. The goal of this project is build toward supporting the RV32G while passing the riscv-arch-tests compliance tests and to implement an SoC with common peripherals (UART, SPI, I2C) with a simple ecosystem to flash programs. The target FPGA for this project is the DE10-lite development board using the MAX10 chip.

## Architecture

This project implements pipelining through the basic 5 stages: Fetch, Decode, Execute, Memory access, and Writeback. Hazard control is implemented for load-use stalls, forwarding to EX from MEM and WB, and flushing the pipeline for jumps and branches. Currently all instructions are passing the RV32I riscv-arch-test tests.

## Roadmap

- Configure test generation from riscv-arch-test to output tests for RV32I configuration
- Convert .elf files to .hex for loading with System Verilog $readmemh
- Automate running the self checking RV32I tests with .do files for regression testing
- Automate generating a System Verilog header file containing file paths to the test hex files
- Fully automate running the tests with a single command
- Add method for generating .elf files from riscv-arch-test by adding it as a submodule
- Automate compilation of assembly/C and loading the program to sim
- Add information for installing the riscv32 compiler and other dependencies
- Add bash script for sourcing environment variables
- Add cache support to data and instruction memory to transition to a unified memory
- Support for Zicsr extension
- Support for Zifence extension
- Support for M extension

### Dependencies
riscv-arch-tests
riscv32 compiler
modelsim (will update to questa soon)
