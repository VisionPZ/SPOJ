#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


@lru_cache(maxsize=None)
def is_prime(value):
    if value < 2:
        return False
    if value % 2 == 0:
        return value == 2
    divisor = 3
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        divisor += 2
    return True


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_total = tokens[cursor]
    cursor += 1
    answers = []
    for case_index in range(1, case_total + 1):
        element_count = tokens[cursor]
        command_count = tokens[cursor + 1]
        cursor += 2
        values = tokens[cursor:cursor + element_count]
        cursor += element_count
        answers.append(f"Case {case_index}:")
        for _ in range(command_count):
            command_type = tokens[cursor]
            cursor += 1
            if command_type == 0:
                range_left = tokens[cursor]
                range_right = tokens[cursor + 1]
                assigned_value = tokens[cursor + 2]
                cursor += 3
                for position in range(range_left - 1, range_right):
                    values[position] = assigned_value
            else:
                range_left = tokens[cursor]
                range_right = tokens[cursor + 1]
                cursor += 2
                found = 0
                for position in range(range_left - 1, range_right):
                    if is_prime(values[position]):
                        found += 1
                answers.append(str(found))
    return "\n".join(answers) + "\n"


SAMPLE = """1
5 3
78 2 13 12 3
1 1 2
0 4 4 5
1 1 5
"""
SAMPLE_OUT = """Case 1:
1
4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert is_prime(2) and is_prime(999983) and not is_prime(999984)
assert oracle("1\n1 3\n2\n1 1 1\n1 1 1\n1 1 1\n") == "Case 1:\n1\n1\n1\n"
assert oracle("1\n3 2\n4 6 8\n1 1 3\n0 1 3 7\n") == "Case 1:\n0\n"
assert oracle("2\n1 1\n9\n1 1 1\n1 1\n2\n1 1 1\n") == "Case 1:\n0\nCase 2:\n1\n"


def write(name, cases):
    text = str(len(cases)) + "\n"
    for values, commands in cases:
        text += f"{len(values)} {len(commands)}\n"
        text += " ".join(str(value) for value in values) + "\n"
        for command in commands:
            text += " ".join(str(value) for value in command) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [([2], [(1, 1, 1), (0, 1, 1, 4), (1, 1, 1)])])
    write("3_wide", [([999983, 999984, 1000000, 2, 3, 4, 999979, 999980],
                      [(1, 1, 8), (0, 2, 6, 999983), (1, 1, 8)])])
    rng = random.Random(20261126)
    values = [rng.randrange(2, 1000001) for _ in range(80)]
    commands = []
    for _ in range(200):
        if rng.random() < 0.35:
            left = rng.randrange(1, 81)
            right = rng.randrange(left, 81)
            commands.append((0, left, right, rng.randrange(2, 1000001)))
        else:
            left = rng.randrange(1, 81)
            right = rng.randrange(left, 81)
            commands.append((1, left, right))
    write("4_random", [(values, commands)])
    values = [rng.randrange(2, 1000001) for _ in range(200)]
    commands = []
    for _ in range(150000):
        if rng.random() < 0.3:
            left = rng.randrange(1, 201)
            right = rng.randrange(left, 201)
            commands.append((0, left, right, rng.randrange(2, 1000001)))
        else:
            left = rng.randrange(1, 201)
            right = rng.randrange(left, 201)
            commands.append((1, left, right))
    write("5_io", [(values, commands)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [([78, 2, 13, 12, 3], [(1, 1, 2), (0, 4, 4, 5), (1, 1, 5)])])
build()
