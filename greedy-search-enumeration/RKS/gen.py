#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    message_length = tokens[0]
    values = tokens[2:2 + message_length]
    counts = {}
    first_seen = {}
    for position, value in enumerate(values):
        if value in counts:
            counts[value] += 1
        else:
            counts[value] = 1
            first_seen[value] = position
    remaining = list(counts)
    result = []
    while remaining:
        winner = remaining[0]
        for candidate in remaining[1:]:
            if counts[candidate] > counts[winner] or (
                counts[candidate] == counts[winner] and first_seen[candidate] < first_seen[winner]
            ):
                winner = candidate
        result.extend([winner] * counts[winner])
        remaining.remove(winner)
    return " ".join(str(value) for value in result) + "\n"


SAMPLE = """9 3
1 3 3 3 2 2 2 1 1
"""
SAMPLE_OUT = """1 1 1 3 3 3 2 2 2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("5 2\n2 1 2 1 2\n") == "2 2 2 1 1\n"
assert oracle("1 1000000000\n7\n") == "7\n"
assert oracle("4 9\n3 3 1 1\n") == "3 3 1 1\n"
assert oracle("6 9\n4 2 2 4 9 2\n") == "2 2 2 4 4 9\n"


def write(name, values, upper_bound=1000000000):
    text = f"{len(values)} {upper_bound}\n" + " ".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1])
    write("3_wide", list(range(1, 1001)))
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 40) for _ in range(1000)])
    write("5_io", [rng.randint(1, 1000000000) for _ in range(1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 3, 3, 3, 2, 2, 2, 1, 1], 3)
build()
