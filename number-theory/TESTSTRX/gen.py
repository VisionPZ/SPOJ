#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    lines = text.splitlines()
    test_count = int(lines[0].split()[0])
    answers = []
    for line in lines[1:test_count + 1]:
        numbers = [int(token) for token in line.split()]
        answers.append(sum(numbers))
    return "".join(str(answer) + "\n" for answer in answers)


SAMPLE = """3 
1 2 
3 4 
10 10
"""
SAMPLE_OUT = """3
7
20
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0 0\n") == "0\n"
assert oracle("2\n10000 10000\n9999 1\n") == "20000\n10000\n"
assert oracle("3\n5 5\n5 5\n5 5\n") == "10\n10\n10\n"


def write(name, text, expected=None):
    if expected is None:
        expected = oracle(text)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(expected)


def cases_text(pairs):
    return f"{len(pairs)}\n" + "".join(f"{left} {right}\n" for left, right in pairs)


def build():
    write("2_edges", cases_text([(0, 0)]))
    write("3_wide", cases_text([(10000, 10000)] * 100))
    rng = random.Random(20261126)
    write("4_random", cases_text([(rng.randint(0, 10000), rng.randint(0, 10000)) for _ in range(100)]))
    write("5_io", cases_text([(9999, 9999)] * 100))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE, SAMPLE_OUT)
build()
