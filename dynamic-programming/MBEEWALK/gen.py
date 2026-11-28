#!/usr/bin/env python3
import math
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DIRECTIONS = [(1, 0), (0, 1), (-1, 1), (-1, 0), (0, -1), (1, -1)]


@lru_cache(maxsize=None)
def closed_walks(steps):
    total = 0
    counts = [0] * 6

    def visit(direction, remaining):
        nonlocal total
        if direction == 5:
            counts[5] = remaining
            if counts[0] - counts[2] - counts[3] + counts[5] != 0:
                return
            if counts[1] + counts[2] - counts[4] - counts[5] != 0:
                return
            ways = math.factorial(steps)
            for count in counts:
                ways //= math.factorial(count)
            total += ways
            return
        for count in range(remaining + 1):
            counts[direction] = count
            visit(direction + 1, remaining - count)
        counts[direction] = 0

    visit(0, steps)
    return total


TABLE = [closed_walks(steps) for steps in range(15)]


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    for case_index in range(case_count):
        steps = tokens[1 + case_index]
        answers.append(str(TABLE[steps]))
    return "\n".join(answers) + ("\n" if answers else "")


SAMPLE = "2\n2\n4\n"
SAMPLE_OUT = "6\n90\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert TABLE[0] == 1
assert TABLE[1] == 0
assert TABLE[2] == 6
assert TABLE[4] == 90
assert TABLE[14] < 2 ** 31


def brute_walk(steps):
    position = (0, 0)
    frontier = {position: 1}
    for _ in range(steps):
        following = {}
        for (grid_x, grid_y), ways in frontier.items():
            for delta_x, delta_y in DIRECTIONS:
                cell = (grid_x + delta_x, grid_y + delta_y)
                following[cell] = following.get(cell, 0) + ways
        frontier = following
    return frontier.get((0, 0), 0)


for small_steps in range(6):
    assert brute_walk(small_steps) == TABLE[small_steps]


def write(name, steps_list):
    text = str(len(steps_list)) + "\n" + "".join(str(value) + "\n" for value in steps_list)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 3, 5, 7, 14])
    write("3_wide", list(range(1, 15)))
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 14) for _ in range(200)])
    write("5_io", [rng.randint(1, 14) for _ in range(20000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [2, 4])
build()
