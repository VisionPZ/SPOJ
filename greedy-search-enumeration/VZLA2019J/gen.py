#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = """2
5
1 4 7 10 15
5
1 5 6 20 34
"""
SAMPLE_OUT = """Case #1: Survival!
Case #2: Oh no!
"""


def oracle(text):
    tokens = text.split()
    position = 0
    case_count = int(tokens[position])
    position += 1
    result_lines = []
    for case_number in range(1, case_count + 1):
        cactus_count = int(tokens[position])
        position += 1
        cactus_positions = [int(value) for value in tokens[position:position + cactus_count]]
        position += cactus_count
        occupied = set(cactus_positions)
        survives = all((value + 1) not in occupied for value in occupied)
        verdict = "Survival!" if survives else "Oh no!"
        result_lines.append(f"Case #{case_number}: {verdict}")
    return "\n".join(result_lines) + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n5\n") == "Case #1: Survival!\n"
assert oracle("1\n2\n1 2\n") == "Case #1: Oh no!\n"
assert oracle("1\n2\n1 3\n") == "Case #1: Survival!\n"
assert oracle("2\n1\n0\n4\n0 2 4 6\n") == "Case #1: Survival!\nCase #2: Survival!\n"


def write(name, cases):
    lines = [str(len(cases))]
    for cactus_positions in cases:
        lines.append(str(len(cactus_positions)))
        lines.append(" ".join(str(value) for value in cactus_positions))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[0], [0, 1], [0, 2], [1000], [998, 1000]])
    write("3_wide", [list(range(0, 1000, 2))])
    rng = random.Random(20261126)
    cases = []
    for _ in range(40):
        count = rng.randint(1, 60)
        cases.append(sorted(rng.sample(range(1001), count)))
    write("4_random", cases)
    full = list(range(1000))
    write("5_io", [full for _ in range(1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
