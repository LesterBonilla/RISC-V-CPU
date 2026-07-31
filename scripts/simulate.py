#!/usr/bin/env -S uv run --script 
"""
Main script for compiling riscv-arch-tests, converting them to hex files, and running the test bench.
"""
from pathlib import Path
import os
import subprocess
import argparse
from generate_sv_header import generate_header


PROJECT_ROOT: Path = Path(os.environ["PROJECT_ROOT"])
CONFIG_FILE: Path = PROJECT_ROOT / "riscv-arch-test-config" / "test_config.yaml"
ARCH_TESTS_DIR: Path = PROJECT_ROOT / "external" / "riscv-arch-test"
BUILD_DIR: Path = PROJECT_ROOT / "build"
WORKDIR: Path = BUILD_DIR / "riscv-arch-tests-work"
ELF_DIR: Path = WORKDIR / "rv32i" / "elfs"
HEX_DIR: Path = WORKDIR / "hex"
SV_HEADER: Path = BUILD_DIR / "tests.svh"
CORE_SRC: Path = PROJECT_ROOT / "src"
DECODE_PKG: Path = CORE_SRC / "pipeline" / "decode_pkg.sv"
TB_FILE: Path = PROJECT_ROOT / "testbench" / "archtest_tb.sv"
SIM_DIR: Path = PROJECT_ROOT / "sim"
SIM_WORKDIR: Path = BUILD_DIR / "sim-work"
FILELIST: Path = BUILD_DIR / "filelist.f"
RUN_GUI_FILE: Path = SIM_DIR / "run_gui.do"
RUN_CONSOLE_FILE: Path = SIM_DIR / "run_console.do"


def build_arch_tests(
        config_file: Path,
        workdir: Path,
        debug: bool = False,
        extensions: list[str] | None = None,
        exclude_extensions: list[str] | None = None,
) -> int:
    """
    Run the riscv-arch-test make file to compile the tests for the given configuration file.
    See: https://github.com/riscv/riscv-arch-test for more information.
    """
    env = os.environ.copy()
    env["CONFIG_FILES"] = str(config_file)
    env["WORKDIR"] = str(workdir)

    if debug:
        env["VERBOSE"] = "TRUE"
        env["DEBUG"] = "TRUE"
    else:
        env["FAST"] = "TRUE"
        env["CLEAN_INTERMEDIATES"] = "TRUE"

    if extensions is not None:
        env["EXTENSIONS"] = ",".join(extensions)
    
    jobs = os.cpu_count() or 1
    cmd = ["make", f"--jobs={jobs}"]

    print("Running riscv-arch-tests make with environment variables:\n",
          f"CONFIG_FILES: {str(config_file)}\n",
          f"WORKDIR: {str(workdir)}\n",
          f"DEBUG: {"TRUE" if debug else "FALSE"}\n",
          f"EXTENSIONS: {"NONE" if extensions is None else ",".join(extensions)}\n",
          f"jobs: {jobs}\n"
        )

    result = subprocess.run(cmd, env=env, cwd=ARCH_TESTS_DIR)
    return result.returncode


def select_elfs(elf_dir: Path, extensions: list[str] | None = None, tests: list[str] | None = None) -> list[Path]:
    """
    Selects elf files from the given directory, optionally selecting based on extension prefix or entire file name.
    
    Returns a list of paths to selected elf files.
    Warns if no files are found with the selected filter.
    """
    if elf_dir.is_file():
        return [elf_dir]

    elfs: list[Path] = find_elf_files(elf_dir)

    if extensions is not None:
        # Get elfs that have extention-test-00.elf where extension is in the extension list
        # split returns a list, so we take only the first element and match to extensions
        elfs = [elf for elf in elfs if elf.stem.split("-")[0] in extensions]
    elif tests is not None:
        elfs = [elf for elf in elfs if elf.stem in tests]

    if not elfs:
        print(f"Warning: No elf files matched the given filters:\n {extensions if extensions else tests}")

    return elfs


def find_elf_files(elf_dir: Path) -> list[Path]:
    """
    Return a list of paths to all .elf files found in elf_dir and its children directories.
    """
    sorted_elfs = sorted(elf_dir.rglob("*.elf"))
    print(f"Found {len(sorted_elfs)} ELF files")
    return sorted_elfs


def convert_elfs_to_hex(elfs: list[Path], hex_dir: Path) -> list[Path]:
    """
    Converts passed in elfs to hex files. Outputs to hex_dir
    """
    hex_dir.mkdir(parents=True, exist_ok=True)
    count = 0
    hex_paths: list[Path] = []

    for elf in elfs:
        hex_path = hex_dir / elf.stem
        subprocess.run(["elf2hex.py", str(elf), str(hex_path.with_suffix(".hex"))])
        count += 1
        hex_paths.append(hex_path)

    print(f"Generated {count} hex files")
    return hex_paths


def build_parser() -> argparse.ArgumentParser:
    """
    Add command line flags and descriptions.
    """
    parser = argparse.ArgumentParser(
        prog="simulate.py",
        description="Main build tool for this project. Builds RISC-V ATC, converts them to hex files, compiles the SystemVerilog project, and runs the testbench.",
    )

    mutually_exclusive_group = parser.add_mutually_exclusive_group()
    mutually_exclusive_group.add_argument(
        "--extensions", "-e", 
        type=lambda s: [ext.strip() for ext in s.split(",")],
        metavar="EXT[,EXT...]",
        help="Only run tests for the passed in extensions (e.g. I, ExceptionsSm)"
        )
    mutually_exclusive_group.add_argument(
        "--tests", "-t",
        type=lambda s: [ext.strip() for ext in s.split(",")],
        metavar="TEST[,TEST...]",
        help="Only run the passed in tests (e.g. I-add-00, Zicsr-csrrc-00)"
    )
    mutually_exclusive_group.add_argument(
        "--elf",
        type=Path,
        metavar="path/to/file.elf",
        help="Convert to hex and run a single arbitrary .elf file"
    )

    parser.add_argument("--gui", "-g", action="store_true", help="Launch ModelSim GUI")
    parser.add_argument("--debug", "-d", action="store_true", help="Enable DEBUG mode for riscv-arch-tests build. Outputs signature objdump, trace files, and trap report.")

    return parser


def main():
    args = build_parser().parse_args()

    # Get necessary extensions to build
    if args.tests:
        extensions = list({test.split("-", 1)[0] for test in args.tests})
    else:
        extensions = args.extensions

    # Build the elfs from riscv-arch-tests repo. They are placed in WORKDIR
    build_arch_tests(config_file=CONFIG_FILE, workdir=WORKDIR, debug=args.debug, extensions=extensions)

    # Find the requested elfs, convert them to hex. 
    elfs = select_elfs(elf_dir=ELF_DIR, extensions=args.extensions, tests=args.tests)
    hex_paths = convert_elfs_to_hex(elfs=elfs, hex_dir=HEX_DIR)

    # Generate .svh header
    generate_header(hex_paths=hex_paths, output=SV_HEADER)

if __name__ == "__main__":
    main()