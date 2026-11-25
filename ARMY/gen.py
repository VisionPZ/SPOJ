#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        godzilla_count = tokens[cursor]
        mecha_count = tokens[cursor + 1]
        cursor += 2
        godzilla = sorted(tokens[cursor:cursor + godzilla_count], reverse=True)
        cursor += godzilla_count
        mecha = sorted(tokens[cursor:cursor + mecha_count], reverse=True)
        cursor += mecha_count
        first = 0
        second = 0
        while first < len(godzilla) and second < len(mecha):
            if godzilla[first] >= mecha[second]:
                second += 1
            else:
                first += 1
        answers.append("Godzilla" if first < len(godzilla) else "MechaGodzilla")
    return "\n".join(answers) + "\n"


SAMPLE = """2

1 1
1
1

3 2
1 3 2
5 5
"""
SAMPLE_OUT = """Godzilla
MechaGodzilla
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 1\n4 7\n9\n") == "MechaGodzilla\n"
assert oracle("1\n1 3\n5\n1 2 3\n") == "Godzilla\n"
assert oracle("1\n2 2\n8 8\n8 1\n") == "Godzilla\n"


def write(name, cases):
    parts = [str(len(cases))]
    for godzilla, mecha in cases:
        parts.append(f"{len(godzilla)} {len(mecha)}")
        parts.append(" ".join(str(value) for value in godzilla))
        parts.append(" ".join(str(value) for value in mecha))
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [([1], [1]), ([1, 2, 3], [5, 5]), ([9], [1]), ([1], [9])])
    write("3_wide", [([10**9] * 10, [10**9] * 10), ([10**9], [10**9 - 1]), ([7] * 20, [6] * 20)])
    rng = random.Random(20261126)
    write("4_random", [([rng.randint(1, 10**9) for _ in range(rng.randint(1, 30))],
                        [rng.randint(1, 10**9) for _ in range(rng.randint(1, 30))])
                       for _ in range(100)])
    write("5_io", [([rng.randint(1, 10**9), 5], [rng.randint(1, 10**9), 5])
                   for _ in range(20000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
