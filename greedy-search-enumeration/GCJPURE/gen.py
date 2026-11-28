#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def is_pure(chosen, value):
    current = value
    visited = set()
    while current != 1:
        if current in visited or current not in chosen:
            return False
        visited.add(current)
        current = chosen.index(current) + 1
    return True


def answer_for(value):
    total = 0
    numbers = list(range(2, value + 1))
    for mask in range(1 << len(numbers)):
        chosen = tuple(num for index, num in enumerate(numbers) if mask >> index & 1)
        if chosen and chosen[-1] == value and is_pure(chosen, value):
            total += 1
    return total % 100003


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    lines = []
    for index in range(case_count):
        value = tokens[1 + index]
        lines.append(f"Case #{index + 1}: {answer_for(value)}")
    return "\n".join(lines) + "\n"


SAMPLE = """2
5
6
"""
SAMPLE_OUT = """Case #1: 5
Case #2: 8
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2\n") == "Case #1: 1\n"
assert oracle("1\n3\n") == "Case #1: 2\n"
assert oracle("1\n7\n") == "Case #1: 14\n"
assert oracle("3\n4\n5\n6\n") == "Case #1: 3\nCase #2: 5\nCase #3: 8\n"


def write(name, values):
    text = str(len(values)) + "\n" + "\n".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [2, 3])
    write("3_wide", [10, 11])
    rng = random.Random(20261128)
    write("4_random", [rng.randint(2, 10) for _ in range(20)])
    write("5_io", [10 for _ in range(200)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [5, 6])
build()
