#!/usr/bin/env python3
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = "4 101 309 499 333\n3 499 66 101\n"
SAMPLE_OUT = "101 499\n"


def oracle(text):
    lines = [line for line in text.split("\n") if line.strip()]
    knowledge = [int(piece) for piece in lines[0].split()]
    english = [int(piece) for piece in lines[1].split()]
    shared = sorted(set(knowledge[1:]) & set(english[1:]))
    return " ".join(str(code) for code in shared) + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3 6 999 12\n3 12 123 9\n") == "12\n"
assert oracle("1 5\n1 7\n") == "\n"
assert oracle("2 1 10000\n2 10000 1\n") == "1 10000\n"
assert oracle("2 7 8\n2 8 7\n") == "7 8\n"


def write(name, knowledge, english):
    first_line = " ".join(str(value) for value in [len(knowledge)] + knowledge)
    second_line = " ".join(str(value) for value in [len(english)] + english)
    input_text = first_line + "\n" + second_line + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [1], [10000])
    write("3_wide", list(range(1, 10001)), list(range(5000, 15001)))
    rng = random.Random(20261125)
    write("4_random", rng.sample(range(1, 10001), 6000),
          rng.sample(range(1, 10001), 6000))
    write("5_io", list(range(10000, 0, -1)), list(range(1, 10001)))


def worked_example():
    knowledge = {101, 309, 499, 333}
    english = {499, 66, 101}
    print(f"knowledge exam: {sorted(knowledge)}")
    print(f"english exam: {sorted(english)}")
    print(f"shared codes: {sorted(knowledge & english)}")


if "--trace" in sys.argv:
    worked_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [101, 309, 499, 333], [499, 66, 101])
    build()
