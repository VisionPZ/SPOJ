#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_OUT = "Print \\C Programming\n"
OUTPUT_CODE_POINTS = [
    80, 114, 105, 110, 116, 32, 92, 67, 32,
    80, 114, 111, 103, 114, 97, 109, 109, 105, 110, 103, 10,
]


def oracle(input_text):
    return "".join(chr(code_point) for code_point in OUTPUT_CODE_POINTS)


def write(name, input_text):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    print("input (empty)")
    print("output %r" % oracle(""))


assert oracle("") == SAMPLE_OUT
assert SAMPLE_OUT == "Print " + chr(92) + "C Programming\n"
assert len(SAMPLE_OUT) == 21
assert len(OUTPUT_CODE_POINTS) == 21


def build():
    write("2_edges", "\n")
    write("3_wide", "\n\n\n  \t \n")
    rng = random.Random(991)
    junk = "".join(rng.choice("abcXYZ019 \t\n") for _ in range(5000))
    write("4_random", junk)
    big_junk = "".join(rng.choice("abcXYZ019 \t\n") for _ in range(1000000))
    write("5_io", big_junk)


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", "")
        build()
