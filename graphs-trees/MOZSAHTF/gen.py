#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """5
"""
SAMPLE_OUT = """Samira
"""


def parity_by_subtraction(value):
    remainder = value
    while remainder >= 2:
        remainder -= 2
    return remainder


def oracle(input_text):
    difference = int(input_text.split()[0])
    if parity_by_subtraction(difference) == 1:
        return "Samira\n"
    return "Rabeya\n"


def write(name, difference):
    input_text = str(difference) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    print("5 minus pairs of 2 leaves remainder 1")
    print("mixed parity pair means Samira")
    print("0 minus pairs of 2 leaves remainder 0")
    print("same parity pair means Rabeya")


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("0\n") == "Rabeya\n"
assert oracle("4\n") == "Rabeya\n"
assert oracle("99999\n") == "Samira\n"


def build():
    write("2_edges", 0)
    write("3_wide", 100000)
    rng = random.Random(7133)
    write("4_random", rng.randint(0, 100000))
    write("5_io", 99999)


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", 5)
        build()
