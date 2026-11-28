#!/usr/bin/env python3
import heapq
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def wishes_from(params):
    count, multiplier, increment, offset, modulus = params
    state = 0
    wishes = []
    for _ in range(count):
        wishes.append(state + offset)
        state = (multiplier * state + increment) % modulus
    return wishes


def graphical(wishes):
    count = len(wishes)
    if any(wish >= count for wish in wishes):
        return False
    if sum(wishes) % 2:
        return False
    remaining = [-wish for wish in wishes if wish > 0]
    heapq.heapify(remaining)
    while remaining:
        largest = -heapq.heappop(remaining)
        if largest > len(remaining):
            return False
        reduced = []
        for _ in range(largest):
            following = -heapq.heappop(remaining)
            if following <= 0:
                return False
            reduced.append(following)
        for value in reduced:
            if value > 1:
                heapq.heappush(remaining, -(value - 1))
    return True


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    position = 1
    answers = []
    for _ in range(case_count):
        params = tuple(tokens[position:position + 5])
        position += 5
        answers.append("HAPPY" if graphical(wishes_from(params)) else "SAD")
    return "\n".join(answers) + "\n"


SAMPLE = """3
3 2 1 0 2
5 1 1 0 5
6 1 1 1 3
"""
SAMPLE_OUT = """HAPPY
SAD
HAPPY
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0 0 0 0 1\n") == "HAPPY\n"
assert oracle("1\n4 0 0 3 1\n") == "HAPPY\n"
assert oracle("1\n4 1 1 0 4\n") == "SAD\n"
assert oracle("1\n4 0 0 4 1\n") == "SAD\n"


def write_params(name, cases):
    lines = [str(len(cases))]
    for params in cases:
        lines.append(" ".join(str(value) for value in params))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_params("2_edges", [
        (0, 0, 0, 0, 1),
        (1, 0, 0, 0, 1),
        (2, 0, 0, 1, 1),
        (4, 0, 0, 3, 1),
        (4, 1, 1, 0, 4),
        (6, 1, 1, 1, 3),
    ])
    write_params("3_wide", [
        (2000, 0, 0, 1999, 1),
        (2000, 0, 0, 2000, 1),
        (2000, 1, 1, 0, 2000),
    ])
    rng = random.Random(20261126)
    cases = []
    for _ in range(30):
        count = rng.randint(1, 200)
        cases.append((count, rng.randint(0, 100), rng.randint(0, 100),
                      rng.randint(0, count + 2), rng.randint(1, max(2, count))))
    write_params("4_random", cases)
    io_cases = []
    for _ in range(20000):
        count = rng.randint(0, 12)
        io_cases.append((count, rng.randint(0, 20), rng.randint(0, 20),
                         rng.randint(0, count + 1), rng.randint(1, max(2, count + 1))))
    write_params("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_params("1_sample", [(3, 2, 1, 0, 2), (5, 1, 1, 0, 5), (6, 1, 1, 1, 3)])
build()
