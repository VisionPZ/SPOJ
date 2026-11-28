#!/usr/bin/env python3
import random
import sys
from pathlib import Path

if hasattr(sys, "set_int_max_str_digits"):
    sys.set_int_max_str_digits(0)

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "5 08\n"
SAMPLE_OUTPUT = "13\n"


def oracle(text):
    parts = text.split()
    if len(parts) < 2:
        return ""
    return str(int(parts[0]) + int(parts[1])) + "\n"


def write(name, first, second):
    input_text = first + " " + second + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1 9\n") == "10\n"
assert oracle("999999 1\n") == "1000000\n"
assert oracle("00001 00002\n") == "3\n"


def trace_example():
    for first, second in [(5, 8), (999, 1), (458, 937)]:
        print(first, second, first + second)


if "--trace" in sys.argv:
    trace_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", "5", "08")
    write("2_edges", "1", "9")
    write("3_wide", "9" * 100000, "1")
    random.seed(161803)
    write("4_random", "".join(random.choice("0123456789") for _ in range(997)),
          "".join(random.choice("0123456789") for _ in range(503)))
    write("5_io", "9" * 100000, "9" * 100000)
