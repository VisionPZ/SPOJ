#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    for case_index in range(case_count):
        cells = tokens[1 + case_index]
        answers.append(winner(cells))
    return "\n".join(answers) + "\n"


def winner(cells):
    @lru_cache(maxsize=None)
    def solve(mask):
        for position in range(cells):
            if (mask >> position) & 1:
                continue
            opened = mask | (1 << position)
            for start in (position - 2, position - 1, position):
                if start >= 0 and start + 2 < cells:
                    window = (opened >> start) & 7
                    if window == 7:
                        return True
            if not solve(opened):
                return True
        return False

    return "Joker" if solve(0) else "Bane"


SAMPLE = """3
3
5
6
"""
SAMPLE_OUT = """Joker
Joker
Bane
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2\n") == "Bane\n"
assert oracle("1\n1\n") == "Joker\n"
assert oracle("1\n4\n") == "Joker\n"
assert oracle("2\n12 20\n") == "Bane\nJoker\n"


def write(name, values):
    text = str(len(values)) + "\n" + "\n".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 7, 8, 12, 14, 20, 22])
    write("3_wide", [3, 5, 6, 9, 10, 11, 12, 13, 16, 19, 20, 21])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 19) for _ in range(40)])
    write("5_io", [rng.randint(3, 20) for _ in range(333)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [3, 5, 6])
build()
