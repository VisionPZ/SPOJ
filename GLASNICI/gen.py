#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def can_finish(positions, hearing_range, seconds):
    rightmost = positions[0] + seconds
    for index in range(1, len(positions)):
        lowest = max(positions[index] - seconds, rightmost - hearing_range)
        highest = min(positions[index] + seconds, rightmost + hearing_range)
        if lowest > highest:
            return False
        rightmost = highest
    return True


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        hearing_range = float(tokens[cursor])
        messenger_count = int(tokens[cursor + 1])
        cursor += 2
        positions = [float(value) for value in tokens[cursor:cursor + messenger_count]]
        cursor += messenger_count
        low = 0.0
        high = float(positions[-1] - positions[0] + 1.0)
        for _ in range(80):
            middle = (low + high) / 2.0
            if can_finish(positions, hearing_range, middle):
                high = middle
            else:
                low = middle
        answers.append(f"{high + 1e-9:.3f}")
    return "\n".join(answers) + "\n"


SAMPLE = """2
3.000 2
0.000
6.000
2.000 4
0.000
4.000
4.000
8.000
"""
SAMPLE_OUT = """1.500
1.000
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0.000 3\n0.000\n1.000\n2.000\n") == "1.000\n"
assert oracle("1\n5.000 3\n0.000\n1.000\n2.000\n") == "0.000\n"
assert oracle("1\n1.000 1\n7.000\n") == "0.000\n"


def write(name, cases):
    parts = [str(len(cases))]
    for hearing_range, positions in cases:
        parts.append(f"{hearing_range:.3f} {len(positions)}")
        parts.extend(f"{position:.3f}" for position in positions)
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(0.0, [0.0]), (0.0, [0.0, 1.0, 2.0]),
                      (1000000.0, [0.0, 1000000000.0, 1000000000.0])])
    write("3_wide", [(1000000.0, [float(index) * 1000000.0 for index in range(1000)]),
                     (0.0, [float(index) for index in range(1000)])])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(30):
        count = rng.randint(1, 60)
        positions = []
        current = 0.0
        for _ in range(count):
            current += rng.uniform(0.0, 20.0)
            positions.append(round(current, 3))
        random_cases.append((round(rng.uniform(0.0, 15.0), 3), positions))
    write("4_random", random_cases)
    write("5_io", [(float(case_index % 4), [float(index) * 2.0 for index in range(1000)])
                   for case_index in range(25)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
