#!/usr/bin/env -S uv run --script 
"""
Main script for compiling riscv-arch-tests, converting them to hex files, and running the test bench.
"""
from pathlib import Path
import os
import subprocess
import argparse
import sys
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


def is_stale(input: Path, output: Path) -> bool:
    """
    Returns bool representing if the output file is older than its dependency.
    
    Args:
        input: Path to file that is depended on by output
        output: Path to file that might be stale
    """
    return (not output.exists() or (input.stat().st_mtime > output.stat().st_mtime))


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

    print(f"Config:\t\t{str(config_file.relative_to(PROJECT_ROOT))}")
    print(f"Workdir:\t{str(workdir.relative_to(PROJECT_ROOT))}")
    print(f"Debug:\t\t{"Yes" if debug else "No"}")
    print(f"Extensions:\t{"All" if extensions is None else ",".join(extensions)}")
    print(f"Jobs:\t\t{jobs}\n")

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

    elfs: list[Path] = sorted(elf_dir.rglob("*.elf"))

    if extensions is not None:
        # Get elfs that have extention-test-00.elf where extension is in the extension list
        # split returns a list, so we take only the first element and match to extensions
        elfs = [elf for elf in elfs if elf.stem.split("-")[0] in extensions]
    elif tests is not None:
        elfs = [elf for elf in elfs if elf.stem in tests]

    if not elfs:
        print(f"Warning: No elf files matched the given filters:\n {extensions if extensions else tests}")
    else:
        print(f"Found:\t\t{len(elfs)}")

    return elfs


def convert_elfs_to_hex(elfs: list[Path], hex_dir: Path) -> list[Path]:
    """
    Converts passed in elfs to hex files if the equivalent hex file doesn't exist or is stale.
    Prints report of files converted or skipped (if they were up to date).

    Args:
        elfs: List of paths to elfs. Expects .elf stem to be present
        hex_dir: Path to folder to place .hex files
    """
    hex_dir.mkdir(parents=True, exist_ok=True)
    num_converted = 0
    hex_paths: list[Path] = []

    for elf in elfs:
        hex_path = (hex_dir / elf.stem).with_suffix(".hex")
        if is_stale(input=elf, output=hex_path):
            subprocess.run(["elf2hex.py", str(elf), str(hex_path)])
            num_converted += 1

        hex_paths.append(hex_path)

    num_skipped = len(elfs) - num_converted

    print(f"Converted:\t{num_converted}")
    print(f"Up to date:\t{num_skipped}")

    return hex_paths


def build_sv_filelist(src_dir: Path, tb_file: Path) -> list[Path]:
    """
    Return a list of SystemVerilog source files in compilation order.
    decode_pkg first, then all other packages, then all other *.sv, then the testbench.
    """
    all_files = sorted(src_dir.rglob("*.sv"))
    packages = [file for file in all_files if file != DECODE_PKG and file.stem.endswith("_pkg")]
    others = [file for file in all_files if file != DECODE_PKG and not file.stem.endswith("_pkg")]

    return [DECODE_PKG, *packages, *others, tb_file]


def write_filelist(files: list[Path], output: Path) -> None:
    """
    Write a list of file paths. Meant for use with list of SystemVerilog source files
    ordered by dependency for compilation.

    Args:
        files: List of .sv suffixed paths for compilation
        output: Destination path of .f suffixed filelist
    """
    output.parent.mkdir(parents=True, exist_ok=True)
    text = "\n".join(path.resolve().as_posix() for path in files) + "\n"

    if not output.exists() or output.read_text() != text:
        output.write_text(text)
        print(f"{output.relative_to(PROJECT_ROOT)} updated")
    else:
        print(f"{output.relative_to(PROJECT_ROOT)} is up to date")


def run_sim(sim_workdir: Path, filelist: Path, tb_top: Path, gui: bool = False) -> int:
    """
    Run .do scripts to compile the rtl source files and testbench, and run the simulation.
    Optionally run with QuestaSim GUI.

    The run.do files use environment variables to locate their files.
    See SIM_DIR for .do file specifics.
    """
    env = os.environ.copy()
    env["SIM_WORKDIR"] = str(sim_workdir)
    env["FILELIST"] = str(filelist)
    env["TB_TOP"] = str(tb_top.stem)
    env["BUILD_DIR"] = str(BUILD_DIR)
    env["SCRIPT_DIR"] = str(SIM_DIR)

    do_file = RUN_GUI_FILE if gui else RUN_CONSOLE_FILE
    cmd = ["vsim"] if gui else ["vsim", "-c"] 
    cmd += ["-do", do_file]

    result = subprocess.run(cmd, env=env, cwd=BUILD_DIR)
    return result.returncode


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
    print("=== Building RISC-V Arch Tests ===")
    error = build_arch_tests(config_file=CONFIG_FILE, workdir=WORKDIR, debug=args.debug, extensions=extensions)
    if (error):
        sys.exit(1)

    # Find the requested elfs, convert them to hex. 
    print("\n=== Converting ELF -> HEX ===")
    elfs = select_elfs(elf_dir=ELF_DIR, extensions=args.extensions, tests=args.tests)
    hex_paths = convert_elfs_to_hex(elfs=elfs, hex_dir=HEX_DIR)

    # Generate .svh header
    print("\n=== Updating testbench header ===")
    generate_header(hex_paths=hex_paths, output=SV_HEADER)

    # Generate RTL source file list
    print("\n=== Updating RTL source filelist ===")
    filelist = build_sv_filelist(src_dir=CORE_SRC, tb_file=TB_FILE)
    write_filelist(files=filelist, output=FILELIST)

    # Compile rtl source and run vsim
    print("\n=== Compiling RTL and running simulation ===")
    print(f"Mode: {"GUI" if args.gui else "Console"}\n")
    run_sim(sim_workdir=SIM_WORKDIR, filelist=FILELIST, tb_top=TB_FILE, gui=args.gui)


if __name__ == "__main__":
    main()