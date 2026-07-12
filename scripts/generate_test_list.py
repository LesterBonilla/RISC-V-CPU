#!/usr/bin/env -S uv run --script
# Generates a System Verilog header file containing
# information about available test hex files

from pathlib import Path
import argparse


def generate_header(test_dir: Path, output: Path):
    hexfiles = sorted(test_dir.glob("*.hex"))
    names = [f.stem for f in hexfiles]

    with output.open("w") as f:
        f.write("// Auto-generated. Do not edit.\n\n")

        f.write(f"localparam int NUM_TESTS = {len(names)};\n\n")

        f.write("string test_names [NUM_TESTS] = '{\n")
        for i, name in enumerate(names):
            comma = "," if i != len(names) - 1 else ""
            f.write(f'    "{name}"{comma}\n')
        f.write("};\n\n")

        f.write("string test_hexfiles [NUM_TESTS] = '{\n")
        for i, file in enumerate(hexfiles):
            comma = "," if i != len(hexfiles) - 1 else ""
            f.write(f'    "{file.as_posix()}"{comma}\n')
        f.write("};\n")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("test_dir", type=Path)
    parser.add_argument("output", type=Path)

    args = parser.parse_args()

    generate_header(args.test_dir, args.output)


if __name__ == "__main__":
    main()