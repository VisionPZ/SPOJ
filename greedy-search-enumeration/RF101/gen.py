#!/usr/bin/env python3
"""Test-data generator and statement-derived oracle for RF101.

Each input line holds one quoted string of DNA letters.
The statement asks for balance when every x has a y beside it in the count.
The oracle uses Counter on each line; the solution counts bytes by index.
"""
import random
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = (
    '"aaxbby"\n'
    '"aaxbb"\n'
    '"bbbaxyb"\n'
    '"jjjxjjjy"\n'
    '"fefsegesxy"\n'
    '"xydawdhafw"\n'
    '"aaaaaxxxxxx"\n'
    '"xaxwdawyx"\n'
)
SAMPLE_OUTPUT = (
    "True\nFalse\nTrue\nTrue\nTrue\nTrue\nFalse\nFalse\n"
)


def oracle(text):
    answers = []
    for raw_line in text.splitlines():
        if not any(character > " " for character in raw_line):
            continue
        counts = Counter(raw_line)
        answers.append("True" if counts["y"] >= counts["x"] else "False")
    return "".join(answer + "\n" for answer in answers)


def write(name, lines):
    input_text = "".join('"%s"\n' % line for line in lines)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert SAMPLE_OUTPUT.count("True\n") == 5
assert oracle('"xy"\n') == "True\n"
assert oracle('"xxy"\n') == "False\n"
assert oracle('"abc"\n') == "True\n"


def trace_example():
    for line in ["aaxbby", "aaxbb", "jjjxjjjy", "aaaaaxxxxxx", "xaxwdawyx"]:
        counts = Counter(line)
        print("%s x=%d y=%d %s" % (
            line, counts["x"], counts["y"],
            "True" if counts["y"] >= counts["x"] else "False"))


if "--trace" in sys.argv:
    trace_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", ["aaxbby", "aaxbb", "bbbaxyb", "jjjxjjjy",
                       "fefsegesxy", "xydawdhafw", "aaaaaxxxxxx",
                       "xaxwdawyx"])
    write("2_edges", ["", "x", "y", "xy", "xxyy", "xxy", "yyy", "abc"])
    write("3_wide", ["x" * 500 + "y" * 500, "x" * 501 + "y" * 500,
                     "a" * 1000, "xy" * 500])
    random.seed(2026)
    write("4_random", ["".join(random.choice("abcxy") for _ in range(40))
                       for _ in range(200)])
    write("5_io", ["".join(random.choice("abcxy") for _ in range(200))
                   for _ in range(5000)])
