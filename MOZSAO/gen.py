#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    counts = tokens[1:1 + case_count]
    lines = []
    for count in counts:
        words = []
        for _ in range(count):
            words.append("one")
        marks = []
        for _ in range(count):
            marks.append("!")
        lines.append(" ".join(words) + "".join(marks))
    return "\n".join(lines) + "\n"


SAMPLE = """2
1
2
"""
SAMPLE_OUT = """one!
one one!!
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n") == "one!\n"
assert oracle("1\n3\n") == "one one one!!!\n"
assert oracle("1\n4\n") == "one one one one!!!!\n"


def write(name, counts):
    text = "\n".join([str(len(counts))] + [str(count) for count in counts]) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 1, 2])
    write("3_wide", [50000])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 50000) for _ in range(10)])
    write("5_io", [50000] * 50)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
