#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1000007


def oracle(text):
    values = [int(value) for value in text.split()]
    case_count = values[0]
    answers = []
    for level in values[1:1 + case_count]:
        total = 0
        for row in range(1, level + 1):
            total = (total + 3 * row - 1) % MODULUS
        answers.append(str(total))
    return "\n".join(answers) + "\n"


SAMPLE = """2
3
7
"""
SAMPLE_OUT = """15
77
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n") == "2\n"
assert oracle("1\n2\n") == "7\n"
assert 3 * 7 * 8 // 2 - 7 == 77


def write(name, levels):
    text = str(len(levels)) + "\n" + "\n".join(str(level) for level in levels) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 5])
    write("3_wide", [3000, 2999, 2998, 1, 2500, 1234])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 2000) for _ in range(60)])
    write("5_io", [rng.randint(1, 1000) for _ in range(1000)])
    stress = [rng.randint(1, 1000000) for _ in range(1000)]
    text = str(len(stress)) + "\n" + "\n".join(str(level) for level in stress) + "\n"
    Path("/tmp/CRDS_big.txt").write_text(text)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [3, 7])
build()
