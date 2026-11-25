#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    element_count = int(tokens[cursor]); cursor += 1
    values = [int(value) for value in tokens[cursor:cursor + element_count]]
    cursor += element_count
    operation_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(operation_count):
        operation_type = int(tokens[cursor]); cursor += 1
        left = int(tokens[cursor]); cursor += 1
        right = int(tokens[cursor]); cursor += 1
        if operation_type == 0:
            values[left - 1] = right
        else:
            best = values[left - 1]
            running = 0
            for index in range(left - 1, right):
                running = max(values[index], running + values[index])
                best = max(best, running)
            answers.append(str(best))
    return "\n".join(answers) + "\n"


SAMPLE = """4
1 2 3 4
4
1 1 3
0 3 -3
1 2 4
1 3 3
"""
SAMPLE_OUT = """6
4
-3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n5\n1\n1 1 1\n") == "5\n"
assert oracle("2\n-4 -7\n2\n1 1 2\n1 2 2\n") == "-4\n-7\n"
assert oracle("3\n-1 2 -1\n2\n0 2 9\n1 1 3\n") == "9\n"
assert oracle("4\n0 0 0 0\n1\n1 2 3\n") == "0\n"


def write(name, values, operations):
    lines = [str(len(values)), " ".join(str(value) for value in values), str(len(operations))]
    lines += [" ".join(str(part) for part in operation) for operation in operations]
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [7], [(1, 1, 1), (0, 1, -9), (1, 1, 1), (1, 1, 1)])
    write("3_wide", [-10000, 10000] * 25,
          [(1, 1, 50)] + [(1, index, index + 3) for index in range(1, 48)])
    rng = random.Random(20261126)
    random_values = [rng.randint(-10000, 10000) for _ in range(120)]
    random_operations = []
    for _ in range(400):
        if rng.random() < 0.3:
            random_operations.append((0, rng.randint(1, 120), rng.randint(-10000, 10000)))
        else:
            left = rng.randint(1, 120)
            right = rng.randint(left, 120)
            random_operations.append((1, left, right))
    write("4_random", random_values, random_operations)
    io_values = [rng.randint(-10000, 10000) for _ in range(100)]
    io_operations = []
    for _ in range(50000):
        if rng.random() < 0.2:
            io_operations.append((0, rng.randint(1, 100), rng.randint(-10000, 10000)))
        else:
            left = rng.randint(1, 100)
            right = rng.randint(left, 100)
            io_operations.append((1, left, right))
    write("5_io", io_values, io_operations)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 2, 3, 4],
      [(1, 1, 3), (0, 3, -3), (1, 2, 4), (1, 3, 3)])
build()
