#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    case_count = tokens[position]
    position += 1
    output = []
    for case_number in range(1, case_count + 1):
        element_count = tokens[position]
        operation_count = tokens[position + 1]
        position += 2
        values = tokens[position:position + element_count]
        position += element_count
        output.append(f"Case {case_number}:")
        for _ in range(operation_count):
            operation_type = tokens[position]
            left = tokens[position + 1]
            right = tokens[position + 2]
            position += 3
            if operation_type == 2:
                answer = sum(value * value for value in values[left - 1:right])
                output.append(str(answer))
            else:
                operand = tokens[position]
                position += 1
                for index in range(left - 1, right):
                    if operation_type == 0:
                        values[index] = operand
                    else:
                        values[index] += operand
    return "\n".join(output) + "\n"


SAMPLE = """2
4 5
1 2 3 4
2 1 4
0 3 4 1
2 1 4
1 3 4 1
2 1 4
1 1
1
2 1 1
"""
SAMPLE_OUT = """Case 1:
30
7
13
Case 2:
1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 5\n3\n2 1 1\n0 1 1 -2\n2 1 1\n1 1 1 1\n2 1 1\n") == "Case 1:\n9\n4\n1\n"
assert oracle("1\n3 2\n-1 2 -3\n1 1 3 1\n2 1 3\n") == "Case 1:\n13\n"
assert oracle("1\n2 1\n0 0\n0 1 2 5\n") == "Case 1:\n"


def write(name, cases):
    lines = [str(len(cases))]
    for values, operations in cases:
        lines.append(f"{len(values)} {len(operations)}")
        lines.append(" ".join(str(value) for value in values))
        for operation in operations:
            lines.append(" ".join(str(value) for value in operation))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        ([5], [(2, 1, 1), (1, 1, 1, -3), (2, 1, 1)]),
        ([0, 0], [(0, 1, 2, 1000), (2, 1, 2), (1, 2, 2, -1000), (2, 1, 2)]),
    ])
    write("3_wide", [
        (list(range(1, 1001)) + [0] * 99000,
         [(2, 1, 100000), (1, 1, 100000, 1), (2, 1, 100000),
          (0, 1, 100000, -1000), (2, 1, 100000)]),
    ])
    rng = random.Random(20261126)
    values = [rng.randint(-1000, 1000) for _ in range(500)]
    operations = []
    for _ in range(500):
        kind = rng.randint(0, 2)
        left = rng.randint(1, 500)
        right = rng.randint(left, 500)
        operation = [kind, left, right]
        if kind != 2:
            operation.append(rng.randint(-1000, 1000))
        operations.append(tuple(operation))
    write("4_random", [(values, operations)])
    io_cases = []
    for _ in range(25):
        values = [rng.randint(-1000, 1000) for _ in range(200)]
        operations = [(2, rng.randint(1, 200), rng.randint(1, 200)) for _ in range(2000)]
        operations = [(kind, min(left, right), max(left, right))
                      for kind, left, right in operations]
        io_cases.append((values, operations))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
