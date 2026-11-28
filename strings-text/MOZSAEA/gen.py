#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

LOWER = "abcdefghijklmnopqrstuvwxyz"
SAMPLE_INPUT = """y c
"""
SAMPLE_OUT = """y z a b c
"""


def successor(letter):
    index = LOWER.index(letter)
    return LOWER[(index + 1) % len(LOWER)]


def oracle(input_text):
    start, end = input_text.split()
    letters = [start]
    cursor = start
    while cursor != end:
        cursor = successor(cursor)
        letters.append(cursor)
    return " ".join(letters) + "\n"


def write(name, start, end):
    input_text = start + " " + end + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    print("walk from y: y z a b c")
    print("the walk stops when c is reached")


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("a a\n") == "a\n"
assert oracle("z a\n") == "z a\n"
assert oracle("a b\n") == "a b\n"
assert oracle("a z\n") == " ".join(LOWER) + "\n"


def build():
    write("2_edges", "a", "a")
    write("3_wide", "a", "z")
    rng = random.Random(6247)
    write("4_random", rng.choice(LOWER), rng.choice(LOWER))
    write("5_io", "z", "y")


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", "y", "c")
        build()
