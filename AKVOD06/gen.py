#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


@lru_cache(maxsize=None)
def grundy(money, cap):
    if money <= 0:
        return 0
    reached = set()
    for taken in range(1, min(cap, money) + 1):
        reached.add(grundy(money - taken, taken))
    result = 0
    while result in reached:
        result += 1
    return result


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    position = 1
    lines = []
    for _ in range(case_count):
        box_count = tokens[position]
        cap = tokens[position + 1]
        position += 2
        total = 0
        for _ in range(box_count):
            total ^= grundy(tokens[position], cap)
            position += 1
        lines.append("Cartman" if total else "Butters")
    return "".join(line + "\n" for line in lines)


SAMPLE = """4
1 1
2
2 2
3 3
4 8
3 8 5 10
5 10
8 5 10 20 15
"""
SAMPLE_OUT = """Butters
Butters
Cartman
Cartman
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1\n2\n") == "Butters\n"
assert oracle("1\n2 2\n3 3\n") == "Butters\n"
assert oracle("1\n1 10000\n1000\n") == "Cartman\n"
assert oracle("1\n3 5\n1 1 1\n") == "Cartman\n"


def write(name, cases):
    lines = [str(len(cases))]
    for cap, boxes in cases:
        lines.append(f"{len(boxes)} {cap}")
        lines.append(" ".join(str(value) for value in boxes))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (1, [1]),
        (1, [2]),
        (2, [3, 3]),
        (10000, [1, 1, 1]),
    ])
    rng = random.Random(20261126)
    write("3_wide", [(10000, [rng.randint(1, 1000) for _ in range(50)])])
    random_cases = []
    for _ in range(6):
        cap = rng.randint(1, 25)
        boxes = [rng.randint(1, 40) for _ in range(rng.randint(1, 12))]
        random_cases.append((cap, boxes))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(20):
        cap = rng.randint(1, 30)
        boxes = [rng.randint(1, 50) for _ in range(rng.randint(1, 6))]
        io_cases.append((cap, boxes))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    (1, [2]),
    (2, [3, 3]),
    (8, [3, 8, 5, 10]),
    (10, [8, 5, 10, 20, 15]),
])
build()
