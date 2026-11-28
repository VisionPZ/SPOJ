#!/usr/bin/env python3
import random
import sys
from pathlib import Path

sys.setrecursionlimit(10000)

ROOT = Path(__file__).resolve().parent

SAMPLE = """2
2 0 2 0 0 0 0 0
20 20 20 20 20 20 20 20
"""
SAMPLE_OUT = """5
160
"""


def feasible(counts, length):
    instances = []
    for digit in range(2, 10):
        instances.extend([digit] * counts[digit - 2])
    assigned = [-1] * (length + 1)

    def place(index, seen):
        digit = instances[index]
        for position in range(1, length + 1):
            if position % digit == 0 or seen[position]:
                continue
            seen[position] = True
            if assigned[position] == -1 or place(assigned[position], seen):
                assigned[position] = index
                return True
        return False

    for index in range(len(instances)):
        seen = [False] * (length + 1)
        if not place(index, seen):
            return False
    return True


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        counts = [int(value) for value in tokens[cursor:cursor + 8]]
        cursor += 8
        total = sum(counts)
        if total == 0:
            answers.append("1")
            continue
        low = 1
        high = 4 * total + 100
        while low < high:
            middle = (low + high) // 2
            if feasible(counts, middle):
                high = middle
            else:
                low = middle + 1
        answers.append(str(low))
    return "\n".join(answers) + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0 0 0 0 0 0 0 0\n") == "1\n"
assert oracle("1\n1 0 0 0 0 0 0 0\n") == "1\n"
assert oracle("1\n2 0 0 0 0 0 0 0\n") == "3\n"
assert oracle("1\n0 2 0 0 0 0 0 0\n") == "2\n"


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(
        " ".join(str(value) for value in case) + "\n" for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        [0, 0, 0, 0, 0, 0, 0, 0],
        [1, 0, 0, 0, 0, 0, 0, 0],
        [2, 0, 0, 0, 0, 0, 0, 0],
        [0, 1, 0, 0, 0, 0, 0, 0],
        [2, 2, 0, 0, 0, 0, 0, 0],
    ])
    write("3_wide", [
        [20, 20, 20, 20, 20, 20, 20, 20],
        [20, 0, 0, 0, 0, 0, 0, 0],
        [0, 20, 0, 0, 0, 0, 0, 0],
    ])
    rng = random.Random(20261129)
    write("4_random", [[rng.randint(0, 8) for _ in range(8)] for _ in range(20)])
    write("5_io", [[rng.randint(0, 20) for _ in range(8)] for _ in range(50)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
