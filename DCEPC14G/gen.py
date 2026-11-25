#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


@lru_cache(maxsize=None)
def grundy(coins, limit):
    reachable = set()
    for taken in range(1, min(limit, coins) + 1):
        reachable.add(grundy(coins - taken, limit))
    value = 0
    while value in reachable:
        value += 1
    return value


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    case_count = tokens[position]
    position += 1
    answers = []
    for _ in range(case_count):
        pile_count = tokens[position]
        position += 1
        piles = tokens[position:position + pile_count]
        position += pile_count
        limits = tokens[position:position + pile_count]
        position += pile_count
        nim_sum = 0
        for coins, limit in zip(piles, limits):
            nim_sum ^= grundy(coins, limit)
        answers.append("Amit" if nim_sum else "Mishra")
    return "\n".join(answers) + "\n"


SAMPLE = """2
1
5
2
2
4 7
1 3
"""
SAMPLE_OUT = """Amit
Amit
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n0\n3\n") == "Mishra\n"
assert oracle("1\n1\n5\n4\n") == "Mishra\n"
assert oracle("1\n2\n6 4\n2 3\n") == "Mishra\n"
assert oracle("1\n2\n6 4\n2 2\n") == "Amit\n"
for coins in range(20):
    for limit in range(1, 12):
        assert grundy(coins, limit) == coins % (limit + 1)


def write(name, cases):
    lines = [str(len(cases))]
    for piles, limits in cases:
        lines.append(str(len(piles)))
        lines.append(" ".join(str(value) for value in piles))
        lines.append(" ".join(str(value) for value in limits))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [([0], [1]), ([0, 0], [5, 7]), ([7], [7]), ([3, 3], [1, 1])])
    rng = random.Random(20261126)
    write("3_wide", [([rng.randrange(0, 80) for _ in range(10000)],
                      [rng.randrange(1, 80) for _ in range(10000)])])
    random_cases = []
    for _ in range(20):
        pile_count = rng.randrange(1, 30)
        random_cases.append(([rng.randrange(0, 80) for _ in range(pile_count)],
                             [rng.randrange(1, 80) for _ in range(pile_count)]))
    write("4_random", random_cases)
    write("5_io", [([rng.randrange(0, 20)], [rng.randrange(1, 20)]) for _ in range(4000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
