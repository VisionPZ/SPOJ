#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(cases):
    answers = []
    for distance, target, throw_height in cases:
        found = None
        for landing in range(1, distance + 1):
            incoming = math.atan2(throw_height, landing)
            outgoing = math.atan2(target, distance - landing)
            if abs(outgoing - 2 * incoming) < 1e-9:
                found = landing
                break
        answers.append("Not this time." if found is None else str(found))
    return "\n".join(answers) + "\n"


SAMPLE_CASES = [(5, 4, 1), (6, 5, 2), (7, 3, 1)]
SAMPLE = "3\n5 4 1\n6 5 2\n7 3 1\n"
SAMPLE_OUT = "2\nNot this time.\n3\n"
assert oracle(SAMPLE_CASES) == SAMPLE_OUT
assert oracle([(5, 4, 1)]) == "2\n"
assert oracle([(7, 3, 1)]) == "3\n"
assert oracle([(1, 1, 1)]) == "1\n"
assert oracle([(2, 1, 1)]) == "Not this time.\n"


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(
        f"{distance} {target} {throw_height}\n"
        for distance, target, throw_height in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(cases))


def build():
    write("2_edges", [(1, 1, 1), (2, 1, 1), (3, 1, 1), (1000, 999, 1),
                      (999, 1000, 1), (12, 5, 3)])
    rng = random.Random(20261126)
    write("3_wide", [(rng.randint(1, 3000), rng.randint(1, 3000),
                      rng.randint(1, 3000)) for _ in range(200)])
    write("4_random", [(rng.randint(1, 2000), rng.randint(1, 2000),
                       rng.randint(1, 2000)) for _ in range(400)])
    write("5_io", [(rng.randint(1, 30), rng.randint(1, 30),
                   rng.randint(1, 30)) for _ in range(20000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_CASES)
build()
