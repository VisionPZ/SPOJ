#!/usr/bin/env python3
import random
from itertools import combinations
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """5
-3 2 -2 1 -3
"""
SAMPLE_OUT = """18
"""


def oracle(input_text):
    tokens = input_text.split()
    count = int(tokens[0])
    values = [int(token) for token in tokens[1:1 + count]]
    best = 1
    for size in range(count + 1):
        for subset in combinations(values, size):
            product = 1
            for value in subset:
                product *= value
            if product > best:
                best = product
    return str(best) + "\n"


def write(name, values):
    input_text = str(len(values)) + "\n"
    if values:
        input_text += " ".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    print("numbers -3 2 -2 1 -3")
    print("best subset -3 -3 2 gives 18")


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("0\n") == "1\n"
assert oracle("1\n-5\n") == "1\n"
assert oracle("2\n-5 -2\n") == "10\n"
assert oracle("9\n0 0 0 0 0 0 0 0 0\n") == "1\n"


def build():
    write("2_edges", [])
    write("3_wide", [10] * 9)
    rng = random.Random(4519)
    write("4_random", [rng.randint(-10, 10) for _ in range(rng.randint(0, 9))])
    write("5_io", [-10] * 9)


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", [-3, 2, -2, 1, -3])
        build()
