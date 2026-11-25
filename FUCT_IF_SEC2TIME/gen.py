#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """1986
"""
SAMPLE_OUT = """00:33:06
"""

SECOND_SAMPLE_INPUT = """-5
"""
SECOND_SAMPLE_OUT = """total second must be a positive integer
"""


def oracle(input_text):
    answers = []
    for token in input_text.split():
        value = int(token)
        if value < 0:
            answers.append("total second must be a positive integer")
        else:
            hours, remainder = divmod(value, 3600)
            minutes, seconds = divmod(remainder, 60)
            answers.append("%02d:%02d:%02d" % (hours, minutes, seconds))
    return "\n".join(answers) + "\n"


def write(name, values):
    input_text = "".join("%d\n" % value for value in values)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    hours, remainder = divmod(1986, 3600)
    minutes, seconds = divmod(remainder, 60)
    print(hours, minutes, seconds)
    print("%02d:%02d:%02d" % (hours, minutes, seconds))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle(SECOND_SAMPLE_INPUT) == SECOND_SAMPLE_OUT
assert oracle("0\n1\n59\n60\n") == (
    "00:00:00\n00:00:01\n00:00:59\n00:01:00\n")
assert oracle("360000\n") == "100:00:00\n"


def build():
    write("2_edges", [-5, 0, 1, 59, 60, 61, 3599, 3600, 3601,
                      86399, 86400, 360000])
    write("3_wide", [10 ** 9, 10 ** 9 + 1, 86399, 86400, 10 ** 12, -1])
    rng = random.Random(515017)
    write("4_random", [rng.randint(-1000, 10 ** 9) for _ in range(1000)])
    write("5_io", [rng.randint(1, 10 ** 12) for _ in range(20000)])


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", [1986])
        build()
