#!/usr/bin/env -S uv run --script 
"""
Main script for compiling riscv-arch-tests, converting them to hex files, and running the test bench.
"""
from pathlib import Path
import os
import subprocess

PROJECT_ROOT: Path = Path(os.environ["PROJECT_ROOT"])
CONFIG_FILE: Path = PROJECT_ROOT / "riscv-arch-test-config" / "test_config.yaml"
ARCH_TESTS_DIR: Path = PROJECT_ROOT / "external" / "riscv-arch-test"
WORKDIR: Path = PROJECT_ROOT / "tests" / "work"
ELF_DIR: Path = WORKDIR / "rv32i" / "elfs"
HEX_DIR: Path = WORKDIR / "hex"

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


def convert_tests_to_hex(elf_dir: Path, hex_dir: Path) -> None:
    """
    Converts all riscv-arch-test elfs to hex files. Creates hex_dir if it doesn't exist.
    """
    hex_dir.mkdir(parents=True, exist_ok=True)
    elfs = find_elf_files(elf_dir)
    count = 0

    for elf in elfs:
        hexfile = hex_dir / elf.with_suffix("").name
        subprocess.run(["elf2hex.py", str(elf), str(hexfile.with_suffix(".hex"))])
        count += 1

    print(f"Generated {count} hex files")
    

def main():
    build_arch_tests(CONFIG_FILE, WORKDIR)
    convert_tests_to_hex(ELF_DIR, HEX_DIR)


if __name__ == "__main__":
    main()