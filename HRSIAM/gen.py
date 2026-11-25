#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    count = int(tokens[0])
    values = [int(value) for value in tokens[1:1 + count]]
    anger = [int(value) for value in tokens[1 + count:1 + 2 * count]]
    operation_count = int(tokens[1 + 2 * count])
    cursor = 2 + 2 * count
    answers = []
    for _ in range(operation_count):
        kind = int(tokens[cursor])
        first = int(tokens[cursor + 1])
        second = int(tokens[cursor + 2])
        cursor += 3
        if kind == 1:
            seen = {}
            total = 0
            for position in range(first - 1, second):
                difficulty = values[position]
                seen[difficulty] = seen.get(difficulty, 0) + 1
                total += difficulty * anger[seen[difficulty] - 1]
            answers.append(str(total))
        else:
            values[first - 1] = second
    return "\n".join(answers) + "\n"


SAMPLE = """8
1 2 3 3 1 1 2 3
1 2 3 4 5 6 7 8
2
1 3 6
1 1 5
"""
SAMPLE_OUT = """12
14
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n5\n2\n3\n1 1 1\n2 1 7\n1 1 1\n") == "10\n14\n"
assert oracle("3\n2 2 2\n1 1 1\n2\n1 1 3\n2 2 1\n") == "6\n"
assert oracle("2\n1 2\n3 4\n1\n1 1 2\n") == "9\n"


def write(name, values, anger, operations):
    text = str(len(values)) + "\n"
    text += " ".join(str(value) for value in values) + "\n"
    text += " ".join(str(value) for value in anger) + "\n"
    text += str(len(operations)) + "\n"
    text += "\n".join(" ".join(str(value) for value in operation) for operation in operations) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    values = [rng.randint(1, 30) for _ in range(25)]
    anger = list(range(1, 26))
    operations = []
    for _ in range(40):
        if rng.random() < 0.7:
            left = rng.randint(1, 25)
            right = rng.randint(left, 25)
            operations.append((1, left, right))
        else:
            operations.append((2, rng.randint(1, 25), rng.randint(1, 30)))
    write("2_edges", [5, 5, 5], [2, 3, 7], [(1, 1, 3), (2, 2, 1), (1, 1, 3), (1, 3, 3)])
    write("3_wide", values, anger, operations)
    values = [rng.randint(1, 60) for _ in range(120)]
    anger = [rng.randint(1, 60) for _ in range(120)]
    operations = []
    for _ in range(100):
        if rng.random() < 0.6:
            left = rng.randint(1, 120)
            right = rng.randint(left, 120)
            operations.append((1, left, right))
        else:
            operations.append((2, rng.randint(1, 120), rng.randint(1, 60)))
    write("4_random", values, anger, operations)
    values = [100] * 100
    anger = list(range(1, 101))
    operations = [(1, 1, 100) for _ in range(150)]
    write("5_io", values, anger, operations)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 2, 3, 3, 1, 1, 2, 3], list(range(1, 9)), [(1, 3, 6), (1, 1, 5)])
build()
