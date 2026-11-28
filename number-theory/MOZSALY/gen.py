#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """2012
"""
SAMPLE_OUT = """2
"""


def remainder(value, divisor):
    return value - divisor * (value // divisor)


def oracle(input_text):
    year = int(input_text.split()[0])
    for divisor, step in ((4, 1), (100, 2), (400, 3)):
        if remainder(year, divisor) != 0:
            return str(step) + "\n"
    return "3\n"


def write(name, year):
    input_text = str(year) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    print("2012 passes the divide by 4 check")
    print("2012 fails the divide by 100 check")
    print("the program halts at step 2")


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("2013\n") == "1\n"
assert oracle("2020\n") == "2\n"
assert oracle("1900\n") == "3\n"
assert oracle("2000\n") == "3\n"


def build():
    write("2_edges", 0)
    write("3_wide", 100000000)
    rng = random.Random(9173)
    write("4_random", rng.randint(0, 10**8))
    write("5_io", 99999904)


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", 2012)
        build()
