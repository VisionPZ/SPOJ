#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    values = [int(token) for token in tokens[cursor:cursor + count]]
    cursor += count
    operations = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(operations):
        kind = int(tokens[cursor])
        cursor += 1
        if kind == 0:
            left = int(tokens[cursor]) - 1
            right = int(tokens[cursor + 1]) - 1
            increment = int(tokens[cursor + 2])
            cursor += 3
            for position in range(left, right + 1):
                values[position] += increment
        else:
            left = int(tokens[cursor]) - 1
            right = int(tokens[cursor + 1]) - 1
            cursor += 2
            running = 0
            best = None
            for position in range(right + 1):
                running += values[position]
                if left <= position and (best is None or running > best):
                    best = running
            answers.append(str(best))
    return "\n".join(answers) + "\n"


SAMPLE_IN = """5
238 -9622 5181 202 -6943
5
1 3 4
0 5 5 4846
1 3 5
0 3 5 -7471
1 3 3
"""
SAMPLE_OUT = """-4001
-4001
-11674
"""
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle("1\n-5\n1\n1 1 1\n") == "-5\n"
assert oracle("3\n-2 3 -1\n2\n0 1 3 4\n1 1 3\n") == "12\n"
assert oracle("4\n0 0 0 0\n3\n0 2 4 -2\n1 1 4\n1 3 4\n") == "0\n-4\n"


def write(name, values, operations):
    lines = [str(len(values)), " ".join(str(value) for value in values), str(len(operations))]
    lines.extend(" ".join(str(value) for value in operation) for operation in operations)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_operations(rng, count, length, query_share):
    operations = []
    for _ in range(count):
        left = rng.randint(1, length)
        right = rng.randint(left, length)
        if rng.random() < query_share:
            operations.append((1, left, right))
        else:
            operations.append((0, left, right, rng.randint(-10000, 10000)))
    return operations


def build():
    rng = random.Random(20261126)
    write("2_edges", [0, 0, 0, 0, 0], [
        (1, 1, 5), (0, 1, 5, -2), (1, 1, 5), (0, 3, 3, 7), (1, 3, 3),
        (0, 1, 5, 2), (1, 1, 5), (1, 5, 5),
    ])
    write("3_wide", [rng.randint(-10000, 10000) for _ in range(50000)],
          random_operations(rng, 200, 50000, 0.5))
    write("4_random", [rng.randint(-10000, 10000) for _ in range(3000)],
          random_operations(rng, 800, 3000, 0.5))
    write("5_io", [rng.choice([-10000, -1, 0, 1, 10000]) for _ in range(6000)],
          random_operations(rng, 2000, 6000, 0.6))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
