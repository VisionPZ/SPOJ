#!/usr/bin/env python3
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

if hasattr(sys, "set_int_max_str_digits"):
    sys.set_int_max_str_digits(0)

SAMPLE_INPUT = "1011\n"
SAMPLE_OUT = "3\n"


def oracle(input_text):
    token = input_text.split()[0]
    return str(int(token, 2).bit_count()) + "\n"


def write(name, binary_text):
    input_text = binary_text + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    token = "1011"
    print("binary 1011")
    print("integer %d" % int(token, 2))
    print("set bits %d" % int(token, 2).bit_count())


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("0000\n") == "0\n"
assert oracle("1\n") == "1\n"
assert oracle("1111111111\n") == "10\n"


def build():
    write("2_edges", "0")
    write("3_wide", "1" * 100000)
    rng = random.Random(8801)
    write("4_random", "".join(rng.choice("01") for _ in range(100000)))
    write("5_io", "".join(rng.choice("0011") for _ in range(100000)))


if __name__ == "__main__":
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", "1011")
        build()
