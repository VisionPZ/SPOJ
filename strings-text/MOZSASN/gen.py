#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """10
"""
SAMPLE_OUT = """-_--_--_--
"""


def oracle(input_text):
    days = int(input_text.split()[0])
    repeated = "-_-" * ((days + 2) // 3)
    return repeated[:days] + "\n"


def write(name, days):
    input_text = str(days) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    print("the block -_- repeated three times is -_--_--_-")
    print("the first 10 characters are -_--_--_--")


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1\n") == "-\n"
assert oracle("2\n") == "-_\n"
assert oracle("3\n") == "-_-\n"
assert oracle("6\n") == "-_--_-\n"


def build():
    write("2_edges", 1)
    write("3_wide", 99999)
    rng = random.Random(5531)
    write("4_random", rng.randint(1, 100000))
    write("5_io", 100000)


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", 10)
        build()
