#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    case_count = tokens[position]
    position += 1
    answers = []
    for _ in range(case_count):
        pile_count = tokens[position]
        position += 1
        piles = tuple(tokens[position:position + pile_count])
        position += pile_count

        @lru_cache(maxsize=None)
        def winning(state):
            if not any(state):
                return True
            for pile_index, size in enumerate(state):
                for taken in range(1, size + 1):
                    remaining = list(state)
                    remaining[pile_index] -= taken
                    next_state = tuple(value for value in remaining if value > 0)
                    if not winning(next_state):
                        return True
            return False

        answers.append("John" if winning(piles) else "Brother")
    return "\n".join(answers) + "\n"


SAMPLE = """2
3
3 5 1
1
1
"""
SAMPLE_OUT = """John
Brother
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n1\n") == "Brother\n"
assert oracle("1\n2\n1 1\n") == "John\n"
assert oracle("1\n2\n2 2\n") == "Brother\n"
assert oracle("1\n3\n1 2 3\n") == "Brother\n"
assert oracle("1\n3\n1 1 1\n") == "Brother\n"
assert oracle("1\n4\n1 1 1 1\n") == "John\n"


def write(name, cases):
    lines = [str(len(cases))]
    for piles in cases:
        lines.append(str(len(piles)))
        lines.append(" ".join(map(str, piles)))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[1], [1, 1]])
    write("3_wide", [[8, 7, 6, 5, 4], [8, 8], [1, 2, 3, 4, 5]])
    rng = random.Random(20261126)
    write("4_random", [[rng.randint(1, 8) for _ in range(rng.randint(1, 5))]
                       for _ in range(20)])
    write("5_io", [[rng.randint(1, 8), rng.randint(1, 8)] for _ in range(474)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
