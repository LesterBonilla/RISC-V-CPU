#!/usr/bin/env -S uv run --script
"""
Generates a System Verilog header file with names, paths, and size of hex files for testing.
"""
from pathlib import Path
import argparse
import os


def generate_header(hex_paths: list[Path], output: Path) -> None:
    """
    Create a system verilog header with two arrays and an array size. 
    The arrays carry matching file path and file names.

    Input is a list of file paths to .hex files, and the tests.svh is placed in the output path.
    """
    names = [f.stem for f in hex_paths]
    hex_paths = [f.resolve().as_posix() for f in hex_paths]

    with output.open("w") as f:
        f.write("// Auto-generated. Do not edit.\n\n")

        f.write(f"localparam int NUM_TESTS = {len(names)};\n\n")

        entries = ",\n".join(f'    "{name}"' for name in names)
        f.write(f"string test_names [NUM_TESTS] = {{\n{entries}\n}};\n\n")
        
        entries = ",\n".join(f'    "{hex_path}"' for hex_path in hex_paths)
        f.write(f"string test_hexfiles [NUM_TESTS] = {{\n{entries}\n}};\n\n")
        

def main():
    parser = argparse.ArgumentParser(
        prog="generate_sv_header.py",
        description="Generates a SystemVerilog .svh file with absolute file paths and names of "
        "hexfiles found in the input hex_dir to the output location."
    )
    parser.add_argument("--hex_dir", type=Path, help="A directory to glob for .hex files")
    parser.add_argument("--header_output", type=Path, help="The location where the system verilog header will be written to. "
                        "Should end with .svh")
    mutually_exclusive_group = parser.add_mutually_exclusive_group()
    mutually_exclusive_group.add_argument(
        "--extensions", "-e", 
        type=lambda s: [ext.strip() for ext in s.split(",")],
        metavar="EXT[,EXT...]",
        help="Only add hex files to the header that are prefixed with the passed in extensions (e.g. I, ExceptionsSm)"
        )
    mutually_exclusive_group.add_argument(
        "--tests", "-t",
        type=lambda s: [ext.strip() for ext in s.split(",")],
        metavar="TEST[,TEST...]",
        help="Only add hex files to the header that match the passed in names (e.g. I-add-00)"
    )

    args = parser.parse_args()

    if (args.hex_dir):
        hex_paths = sorted(args.hex_dir.glob("*.hex"))
    else:
        hex_paths = sorted((Path(os.environ["PROJECT_ROOT"]) / "tests" / "work" / "hex").glob("*.hex"))

    if (args.header_output):
        header_output = args.header_output
    else:
        header_output = Path(os.environ["PROJECT_ROOT"]) / "testbench" / "test.svh"

    if (args.extensions):
        hex_paths = [hex for hex in hex_paths if hex.stem.split("-")[0] in args.extensions]
    elif (args.tests):
        hex_paths = [hex for hex in hex_paths if hex.stem in args.tests]

    if not hex_paths:
        print(f"Warning: No hex files matched the given filters:\n {args.extensions if args.extensions else args.tests}")
    
    generate_header(hex_paths, header_output)


if __name__ == "__main__":
    main()