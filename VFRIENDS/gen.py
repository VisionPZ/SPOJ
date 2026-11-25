#!/usr/bin/env python3
import heapq
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def graphical(wishes):
    remaining = [-degree for degree in wishes if degree > 0]
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
        dog_count = tokens[position]
        position += 1
        wishes = tokens[position:position + dog_count]
        position += dog_count
        answers.append("HAPPY" if graphical(wishes) else "SAD")
    return "\n".join(answers) + "\n"


SAMPLE = """3
3 0 1 1
5 0 1 2 3 4
6 1 1 2 2 3 3
"""
SAMPLE_OUT = """HAPPY
SAD
HAPPY
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0\n") == "HAPPY\n"
assert oracle("1\n3\n0 0 0\n") == "HAPPY\n"
assert oracle("1\n3\n2 2 2\n") == "HAPPY\n"
assert oracle("1\n2\n1 0\n") == "SAD\n"
assert oracle("1\n5\n0 1 2 3 4\n") == "SAD\n"


def write_cases(name, cases):
    lines = [str(len(cases))]
    for wishes in cases:
        lines.append(" ".join([str(len(wishes))] + [str(wish) for wish in wishes]))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_cases("2_edges", [[], [0], [0, 0], [1, 1], [2, 0], [3, 3, 3, 3]])
    write_cases("3_wide", [[999] * 1000, [1000] * 1000, [500] * 1000])
    rng = random.Random(20261126)
    cases = []
    for _ in range(20):
        count = rng.randint(1, 200)
        degrees = [0] * count
        for left in range(count):
            for right in range(left + 1, count):
                if rng.random() < 0.4:
                    degrees[left] += 1
                    degrees[right] += 1
        cases.append(degrees)
        broken = degrees[:]
        broken[rng.randrange(count)] = count + rng.randint(0, 5)
        cases.append(broken)
    write_cases("4_random", cases)
    io_cases = []
    for case_index in range(20000):
        count = case_index % 7
        io_cases.append([rng.randint(0, count) for _ in range(count)])
    write_cases("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_cases("1_sample", [[0, 1, 1], [0, 1, 2, 3, 4], [1, 1, 2, 2, 3, 3]])
build()
