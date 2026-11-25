#!/usr/bin/env python3
import calendar
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "0\n"
SAMPLE_OUT = "Friday\n"


def oracle(input_text):
    answers = []
    for token in input_text.split():
        day_offset = int(token)
        answers.append(calendar.day_name[(day_offset + 4) % 7])
    return "\n".join(answers) + "\n"


def write(name, offsets):
    input_text = "".join("%d\n" % day_offset for day_offset in offsets)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    for day_offset in [0, 1, 1000000000]:
        print("X %d -> %s" % (day_offset, calendar.day_name[(day_offset + 4) % 7]))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1\n") == "Saturday\n"
assert oracle("7\n") == "Friday\n"
assert oracle("1000000000\n") == "Thursday\n"


def build():
    write("2_edges", [0, 1, 6, 7, 8, 13, 14, 1000000000])
    write("3_wide", list(range(0, 1001)))
    rng = random.Random(1177)
    write("4_random", [rng.randint(0, 10**9) for _ in range(1000)])
    write("5_io", [rng.randint(0, 10**9) for _ in range(100000)])


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", [0])
        build()
