#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
COLUMNS = 10


@lru_cache(maxsize=None)
def winning(state):
    if all(height == 0 for height in state):
        return True
    if len(set(state)) == 1 and state[0] > 1:
        return True
    for column, height in enumerate(state):
        for row in range(height):
            successor = tuple(value if index < column else min(value, row)
                              for index, value in enumerate(state))
            if not winning(successor):
                return True
    return False


def oracle(text):
    lines = text.splitlines()
    count = int(lines[0])
    answers = []
    for index in range(count):
        state = tuple(int(value) for value in lines[index + 1].split())
        answers.append('W' if winning(state) else 'L')
    return "\n".join(answers) + "\n"


SAMPLE = """3
2 2 0 0 0 0 0 0 0 0
2 1 0 0 0 0 0 0 0 0
10 10 10 10 10 10 10 10 10 10
"""
SAMPLE_OUT = """W
L
W
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert winning(tuple([1] + [0] * 9)) is False
assert winning(tuple([2, 2] + [0] * 8)) is True
assert winning(tuple([2, 1] + [0] * 8)) is False
assert winning(tuple([0] * 10)) is True


def write(name, states):
    text = str(len(states)) + "\n"
    text += "".join(" ".join(str(height) for height in state) + "\n" for state in states)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_state(rng, ceiling):
    heights = []
    current = ceiling
    for _ in range(COLUMNS):
        current = rng.randint(0, current)
        heights.append(current)
    return tuple(heights)


def build():
    write("2_edges", [
        tuple([0] * 10), tuple([1] + [0] * 9), tuple([2, 2] + [0] * 8),
        tuple([2, 1] + [0] * 8), tuple([3, 3, 3] + [0] * 7),
        tuple([1] * 10)])
    rng = random.Random(20261126)
    write("3_wide", [random_state(rng, 5) for _ in range(80)])
    write("4_random", [random_state(rng, 3) for _ in range(120)])
    write("5_io", [random_state(rng, 2) for _ in range(1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    (2, 2, 0, 0, 0, 0, 0, 0, 0, 0),
    (2, 1, 0, 0, 0, 0, 0, 0, 0, 0),
    (10, 10, 10, 10, 10, 10, 10, 10, 10, 10)])
build()
