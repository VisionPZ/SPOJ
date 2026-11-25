#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute(values, smart):
    @lru_cache(maxsize=None)
    def solve(left, right):
        if left == right:
            return 0
        next_left = solve(left + 1, right)
        next_right = solve(left, right - 1)
        if (right - left + 1) % 2 == 0:
            return max(values[left] + next_left, values[right] + next_right)
        if smart:
            return min(next_left, next_right)
        return max(next_left, next_right)

    return solve(0, len(values) - 1)


def oracle(text):
    tokens = text.split()
    position = 0
    test_count = int(tokens[position])
    position += 1
    answers = []
    for _ in range(test_count):
        size = int(tokens[position])
        position += 1
        values = tuple(int(token) for token in tokens[position:position + size])
        position += size
        answers.append(f"{brute(values, False)} {brute(values, True)}")
    return "\n".join(answers) + "\n"


SAMPLE = """2
4
5 8 4 2
4
8 5 4 2
"""
SAMPLE_OUT = """13 10
13 12
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2\n5 8\n") == "8 8\n"
assert oracle("1\n4\n1 2 3 4\n") == "7 6\n"
assert oracle("1\n6\n3 1 4 1 5 9\n") == "18 16\n"


def write(name, cases):
    text = str(len(cases)) + "\n"
    for values in cases:
        text += str(len(values)) + "\n" + " ".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[2, 7], [1, 2, 3, 4], [9, 1, 1, 9], [4, 3, 2, 1]])
    rng = random.Random(20261126)
    wide = [rng.randint(1, 10 ** 9) for _ in range(30)]
    write("3_wide", [wide])
    write("4_random", [[rng.randint(1, 100000) for _ in range(rng.choice([2, 4, 6, 30]))]
                       for _ in range(6)])
    write("5_io", [[rng.randint(1, 1000000000) for _ in range(30)] for _ in range(19)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [[5, 8, 4, 2], [8, 5, 4, 2]])
build()
