#!/usr/bin/env python3
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "5\n"
SAMPLE_OUT = "yes\n"


def oracle(input_text):
    friend_count = int(input_text.split()[0])
    remaining_people = friend_count + 1
    while remaining_people >= 2:
        remaining_people -= 2
    return "yes\n" if remaining_people == 0 else "no\n"


def write(name, value):
    input_text = str(value) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1\n") == "yes\n"
assert oracle("2\n") == "no\n"
assert oracle("100000\n") == "no\n"


def trace_example():
    print("friends", 5)
    print("people", 6)
    print("answer", oracle("5\n").strip())


def build():
    write("2_edges", 1)
    write("3_wide", 100000)
    rng = random.Random(81429)
    write("4_random", rng.randint(1, 100000))
    write("5_io", 99999)


if __name__ == "__main__":
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", 5)
        build()
