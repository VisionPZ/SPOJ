#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    cursor = 1
    for _ in range(case_count):
        count = tokens[cursor]
        target = tokens[cursor + 1]
        cursor += 2
        values = tokens[cursor:cursor + count]
        cursor += count
        answers.append("YES" if target in values else "NO")
    return "\n".join(answers) + "\n"


SAMPLE = "2\n5 10\n1 4 7 10 20\n6 13\n1 4 6 7 8 23\n"
SAMPLE_OUT = "YES\nNO\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 5\n5\n") == "YES\n"
assert oracle("1\n3 2\n1 3 5\n") == "NO\n"
assert oracle("1\n3 1\n1 2 3\n") == "YES\n"


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(
        f"{len(values)} {target}\n" + " ".join(str(value) for value in values) + "\n"
        for values, target in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [([1], 1), ([1, 2, 3], 2), ([1, 2, 3], 9), ([0, 0, 0], 0)])
    write("3_wide", [(list(range(100000)), 99999)] * 15)
    rng = random.Random(20261126)
    cases = []
    for _ in range(15):
        values = sorted(rng.randint(0, 100000) for _ in range(rng.randint(1, 1000)))
        target = rng.randint(0, 100000)
        cases.append((values, target))
    write("4_random", cases)
    write("5_io", cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [([1, 4, 7, 10, 20], 10), ([1, 4, 6, 7, 8, 23], 13)])
build()
