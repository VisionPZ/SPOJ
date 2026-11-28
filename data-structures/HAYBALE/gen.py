#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    values = [int(value) for value in text.split()]
    stack_count = values[0]
    instruction_count = values[1]
    heights = [0] * stack_count
    cursor = 2
    for _ in range(instruction_count):
        first_stack = values[cursor]
        last_stack = values[cursor + 1]
        cursor += 2
        for stack_index in range(first_stack - 1, last_stack):
            heights[stack_index] += 1
    heights.sort()
    return str(heights[stack_count // 2]) + "\n"


SAMPLE = """7 4
5 5
2 4
4 6
3 5
"""
SAMPLE_OUT = """1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n1 1\n") == "1\n"
assert oracle("3 1\n1 3\n") == "1\n"
assert oracle("5 5\n1 5\n1 5\n1 5\n1 5\n1 5\n") == "5\n"
assert sorted([0, 0, 1, 1, 2, 3, 3])[3] == 1


def write(name, stack_count, ranges):
    lines = [f"{stack_count} {len(ranges)}"]
    lines.extend(f"{first} {last}" for first, last in ranges)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, [(1, 1)])
    write("3_wide", 2001, [(index % 2000 + 1, index % 2000 + 3) for index in range(30)])
    rng = random.Random(20261126)
    ranges = []
    for _ in range(40):
        first = rng.randint(1, 295)
        ranges.append((first, min(301, first + rng.randint(0, 6))))
    write("4_random", 301, ranges)
    ranges = []
    for _ in range(100):
        first = rng.randint(1, 990)
        ranges.append((first, min(999, first + rng.randint(0, 9))))
    write("5_io", 999, ranges)
    stress = []
    for _ in range(25000):
        first = rng.randint(1, 999995)
        stress.append((first, first + rng.randint(0, 4)))
    lines = ["999999 25000"]
    lines.extend(f"{first} {last}" for first, last in stress)
    Path("/tmp/HAYBALE_big.txt").write_text("\n".join(lines) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 7, [(5, 5), (2, 4), (4, 6), (3, 5)])
build()
