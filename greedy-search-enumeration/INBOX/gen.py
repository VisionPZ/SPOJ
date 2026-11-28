#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    answers = []
    while position < len(tokens):
        box_count = tokens[position]
        position += 1
        if box_count == 0:
            break
        group_size = tokens[position]
        position += 1
        boxes = []
        for _ in range(box_count):
            boxes.append((tokens[position], tokens[position + 1]))
            position += 2
        total_weight = sum(weight for weight, _ in boxes)
        total_cost = sum(cost for _, cost in boxes)
        best = None
        for chosen in itertools.combinations(range(box_count), group_size):
            weight = sum(boxes[index][0] for index in chosen)
            cost = sum(boxes[index][1] for index in chosen)
            value = weight / cost + (total_weight - weight) / (total_cost - cost)
            if best is None or value < best:
                best = value
        answers.append(f"{best:.5f}")
    return "\n".join(answers) + "\n"


SAMPLE = """8 4
2 1
3 2
4 3
5 4
6 5
7 6
8 7
10 8
0
"""
SAMPLE_OUT = """2.49845
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2 1\n1 1\n2 1\n0\n") == "3.00000\n"
assert oracle("3 1\n1 2\n2 3\n3 4\n0\n") == "1.21429\n"
assert oracle("4 2\n1 1\n2 1\n3 1\n4 1\n0\n") == "5.00000\n"
assert oracle("3 2\n5 1\n1 5\n3 3\n0\n") == "2.00000\n"


def write(name, cases):
    lines = []
    for group_size, boxes in cases:
        lines.append(f"{len(boxes)} {group_size}")
        for weight, cost in boxes:
            lines.append(f"{weight} {cost}")
    lines.append("0")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (1, [(1, 1), (2, 1)]),
        (1, [(1, 2), (2, 3), (3, 4)]),
        (2, [(1, 1), (2, 1), (3, 1), (4, 1)]),
        (2, [(5, 1), (1, 5), (3, 3)]),
    ])
    write("3_wide", [
        (9, [(weight, 1) for weight in range(1, 19)]),
        (9, [(1, cost) for cost in range(1, 19)]),
    ])
    rng = random.Random(20261126)
    cases = []
    for _ in range(12):
        count = rng.randint(2, 18)
        group_size = rng.randint(1, count - 1)
        cases.append((group_size, [(rng.randint(1, 50), rng.randint(1, 50)) for _ in range(count)]))
    write("4_random", cases)
    io_cases = []
    for case_index in range(100):
        io_cases.append((8, [(50, 1) for _ in range(16)]))
        io_cases.append((8, [(1, 50) for _ in range(16)]))
        io_cases.append((8, [(i % 50 + 1, (i * 7) % 50 + 1) for i in range(16)]))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(4, [(2, 1), (3, 2), (4, 3), (5, 4), (6, 5), (7, 6), (8, 7), (10, 8)])])
build()
