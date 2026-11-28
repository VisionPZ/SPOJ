#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        size = int(tokens[cursor])
        budget = int(tokens[cursor + 1])
        cursor += 2
        heights = []
        for _ in range(size):
            heights.append([int(value) for value in tokens[cursor:cursor + size]])
            cursor += size
        best_paths = []
        stack = [(0, 0, 0, 0)]
        while stack:
            row, col, biggest_rise, spent = stack.pop()
            if row == size - 1 and col == size - 1:
                best_paths.append((biggest_rise, spent))
                continue
            if row + 1 < size:
                rise = max(0, heights[row + 1][col] - heights[row][col])
                step = abs(heights[row + 1][col] - heights[row][col])
                stack.append((row + 1, col, max(biggest_rise, rise), spent + step))
            if col + 1 < size:
                rise = max(0, heights[row][col + 1] - heights[row][col])
                step = abs(heights[row][col + 1] - heights[row][col])
                stack.append((row, col + 1, max(biggest_rise, rise), spent + step))
        smallest_rise = min(path[0] for path in best_paths)
        usable = [path[1] for path in best_paths
                  if path[0] == smallest_rise and path[1] < budget]
        if not usable:
            answers.append("NO")
        else:
            answers.append(f"YES : {smallest_rise} {budget - max(usable)}")
    return "\n".join(answers) + "\n"


SAMPLE = """1
3 40
2 4 3
4 5 3
2 4 6
"""
SAMPLE_OUT = """YES : 2 32
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1\n4\n") == "YES : 0 1\n"
assert oracle("1\n2 4\n5 5\n1 1\n") == "NO\n"
assert oracle("1\n2 10\n5 5\n5 5\n") == "YES : 0 10\n"
assert oracle("1\n2 5\n1 4\n1 4\n") == "YES : 3 2\n"


def write(name, cases):
    parts = [str(len(cases))]
    for size, budget, heights in cases:
        parts.append(f"{size} {budget}")
        for row in heights:
            parts.append(" ".join(str(value) for value in row))
    input_text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [
        (1, 1, [[7]]),
        (2, 10, [[5, 5], [5, 5]]),
        (2, 4, [[5], [1]]),
        (3, 12, [[1, 2, 3], [4, 5, 6], [7, 8, 9]]),
    ])
    rng = random.Random(20261129)
    write("3_wide", [(6, 100, [[rng.randint(1, 12) for _ in range(6)]
                               for _ in range(6)])])
    random_cases = []
    for _ in range(12):
        size = rng.randint(2, 5)
        random_cases.append((size, rng.randint(1, 100),
                             [[rng.randint(1, 15) for _ in range(size)]
                              for _ in range(size)]))
    write("4_random", random_cases)
    write("5_io", [(5, rng.randint(30, 100),
                    [[rng.randint(1, 20) for _ in range(5)]
                     for _ in range(5)]) for _ in range(60)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
