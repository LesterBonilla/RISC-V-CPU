#!/usr/bin/env -S uv run --script 
"""
Converts a RISC-V ELF file to a HEX file for use with SystemVerilog readmemh() for simulation.
"""

import subprocess
import argparse
from pathlib import Path
import sys
import shutil
import tempfile

OBJCOPY: str = "riscv64-unknown-elf-objcopy"

def check_objcopy() -> None:
    """
    Verify the objcopy executable is available on the system PATH.

    Terminates the program with an error if it cannot be found.
    """
    if not shutil.which(OBJCOPY):
        print(f"Error: {OBJCOPY} not found on PATH", file=sys.stderr)
        sys.exit(1)


def elf_to_bin(elf_path: Path, bin_path: Path) -> None:
    """
    Use objcopy to convert an ELF into a raw binary.

    Args:
        elf_path: Input ELF file
        bin_path: Output binary file
    """
    subprocess.run([OBJCOPY, elf_path, "-O", "binary", bin_path], check=True)


def bin_to_hex(bin_path: Path, output_path: Path, word_bytes: int = 4) -> None:
    """
    Convert a raw binary file into a text-based hexadecimal file.

    The binary data is processed in word_bytes-byte chunks. Each word
    is padded with zeros if necessary to maintain word boundaries. The byte
    order is reversed (little-endian binary to big-endian hex text) to produce 
    correctly ordered text-based hexadecimal (i.e. 0x33442211, with 33 being MSB).

    Args:
        bin_path: Input binary file
        output_path: Output hex file
        word_bytes: Size of word in bytes
    """
    with open(bin_path, "rb") as f:
        data = f.read()

    with open(output_path, "w") as out:
        for i in range(0, len(data), word_bytes):
            word = data[i:i + word_bytes]
            word = word.ljust(word_bytes, b"\x00")
            out.write(word[::-1].hex() + "\n")


def main():
    check_objcopy()

    parser = argparse.ArgumentParser(
        prog="elf2hex.py", 
        description="Converts a RISC-V ELF file to a HEX file for use with SystemVerilog readmemh() for simulation.", 
        epilog=("Example:\n" "    elf2hex.py input.elf output.hex"),
        formatter_class=argparse.RawDescriptionHelpFormatter)
    
    parser.add_argument("elf", help="Input ELF file")
    parser.add_argument("hex", help ="Output hex file. The path to this file is created if it doesn't exist.")
    args = parser.parse_args()

    elf_path = Path(args.elf)

    if not elf_path.is_file():
        parser.error(f"{elf_path} does not exist")

    hex_path = Path(args.hex)
    hex_path.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory() as tmpdir:
        bin_path = Path(tmpdir) / "output.bin"
        elf_to_bin(elf_path, bin_path)
        bin_to_hex(bin_path, hex_path)


if __name__ == "__main__":
    main()

    
    