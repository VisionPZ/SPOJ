#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """100604
"""
SAMPLE_OUT = """3
"""


def oracle(input_text):
    number = int(input_text.split()[0])
    magnitude = abs(number)
    if magnitude == 0:
        return "1\n"
    zero_count = 0
    while magnitude > 0:
        if magnitude - 10 * (magnitude // 10) == 0:
            zero_count += 1
        magnitude //= 10
    return str(zero_count) + "\n"


def write(name, number):
    input_text = str(number) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    print("100604 gives remainders 4 0 6 0 0 1")
    print("three of those remainders are zero")


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("0\n") == "1\n"
assert oracle("-100\n") == "2\n"
assert oracle("5\n") == "0\n"
assert oracle("-100000000\n") == "8\n"


def build():
    write("2_edges", 0)
    write("3_wide", -100000000)
    rng = random.Random(8621)
    write("4_random", rng.randint(-10**8, 10**8))
    write("5_io", 100000000)


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", 100604)
        build()
