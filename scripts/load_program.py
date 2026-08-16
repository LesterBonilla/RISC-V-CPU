#!/usr/bin/env -S uv run --script
# /// script
# dependencies = [
#   "pyserial",
# ]
# ///
"""
Loads a .hex file to the core over UART
"""

import serial
from pathlib import Path


def send_hex(hex_path: Path, ser: serial.Serial) -> None:
    """
    Send little-endian hex values over UART.

    Args:
        hex_path: Path to hex file
        ser: Serial device to send hex to
    """
    # Write sync byte
    ser.write(b'\x37')

    # Get lines of hex values from hex_path
    with open(hex_path, "rb") as f:
        lines = [line.strip() for line in f if line.strip()]

    # Send count of hex lines
    print(f"Sending: {len(lines)} lines of hex, {len(lines)*4} bytes")
    print(f"Bytes represented as {(len(lines)*4).to_bytes(length = 4, byteorder='little').hex()}")
    ser.write((len(lines)*4).to_bytes(length = 4, byteorder='little'))

    # Ack that the size was received correctly
    print(ser.readline())
    print(ser.readline())
    ack = ser.read(4)
    expected = (len(lines)*4).to_bytes(length = 4, byteorder='little')

    print(f"ACK:        {ack} ({ack.hex()})")
    print(f"Expected:   {expected} ({expected.hex()})")
    
    if ack != expected:
        print ("Bad value received")
        return

    # Send hex lines
    for line in lines:
        send = int(line, 16).to_bytes(length = 4, byteorder='little')
        ser.write(send)
        ack = ser.read(4)

        print(f"Sent:       {send} ({send.hex()})")
        print(f"Received:   {ack} ({ack.hex()})")
            
        if ack != send:
            print ("Bad value received")
            print(f"Sent:       {send} ({send.hex()})")
            print(f"Received:   {ack} ({ack.hex()})")
            return

    print(ser.readline())
    

with serial.Serial('/dev/ttyACM0', 108295) as ser:
    print(ser.name)
    line = ser.readline()
    print(line)
    send_hex(Path("/home/lester/Projects/RISC-V-CPU/build/riscv-arch-tests-work/hex/ExceptionsSm-00.hex"), ser)
    while True:
        print(ser.readline())