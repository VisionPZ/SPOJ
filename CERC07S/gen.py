#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(heights):
    sample_count = len(heights)
    ordered = sorted(range(sample_count), key=lambda index: (heights[index], index))
    current = list(range(sample_count))
    answers = []
    for step_index, target in enumerate(ordered):
        position = current.index(target)
        answers.append(str(position + 1))
        current[step_index:position + 1] = reversed(current[step_index:position + 1])
    return " ".join(answers)


SAMPLE = """6
3 4 5 1 6 2
4
3 3 2 1
0
"""
SAMPLE_OUT = """4 6 4 5 6 6
4 2 4 4
"""
assert oracle([3, 4, 5, 1, 6, 2]) == "4 6 4 5 6 6"
assert oracle([3, 3, 2, 1]) == "4 2 4 4"
assert oracle([1]) == "1"
assert oracle([5, 5, 5, 5]) == "1 2 3 4"
assert oracle([2, 1, 2, 1]) == "2 4 4 4"


def write(name, scenarios):
    lines = []
    answers = []
    for heights in scenarios:
        lines.append(str(len(heights)))
        lines.append(" ".join(str(value) for value in heights))
        answers.append(oracle(heights))
    lines.append("0")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text("\n".join(answers) + "\n")


def build():
    write("2_edges", [[1], [1, 1], [2, 1], [5, 5, 5, 5], [9, 8, 7, 6, 5, 4, 3, 2, 1]])
    rng = random.Random(20261126)
    write("3_wide", [[rng.randint(1, 10**9) for _ in range(2000)]])
    random_scenarios = []
    for _ in range(60):
        size = rng.randint(1, 120)
        random_scenarios.append([rng.randint(1, 40) for _ in range(size)])
    write("4_random", random_scenarios)
    io_scenarios = []
    for _ in range(5000):
        io_scenarios.append([rng.randint(1, 10**9) for _ in range(rng.randint(2, 9))])
    write("5_io", io_scenarios)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
