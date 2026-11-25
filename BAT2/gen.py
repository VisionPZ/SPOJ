#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        room_count = tokens[cursor]
        cursor += 1
        tags = tokens[cursor:cursor + room_count]
        cursor += room_count
        best = 0
        for choice in itertools.product((0, 1, 2), repeat=room_count):
            forward = [tags[i] for i in range(room_count) if choice[i] == 1]
            backward = [tags[i] for i in range(room_count) if choice[i] == 2]
            if any(left >= right for left, right in zip(forward, forward[1:])):
                continue
            if any(left <= right for left, right in zip(backward, backward[1:])):
                continue
            best = max(best, len(forward) + len(backward))
        answers.append(str(best))
    return "\n".join(answers) + "\n"


SAMPLE = """1
6
5 3 4 6 1 2
"""
SAMPLE_OUT = """5
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n3\n6 3 3\n") == "3\n"
assert oracle("1\n4\n1 2 3 4\n") == "4\n"
assert oracle("1\n4\n4 3 2 1\n") == "4\n"
assert oracle("1\n1\n7\n") == "1\n"


def write(name, cases):
    parts = [str(len(cases))]
    for tags in cases:
        parts.append(str(len(tags)))
        parts.append(" ".join(str(value) for value in tags))
    input_text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [[1], [7, 3], [3, 3, 3], [5, 6, 6], [2, 1, 4, 3]])
    write("3_wide", [list(range(1, 11)), list(range(10, 0, -1))])
    rng = random.Random(20261127)
    write("4_random", [[rng.randint(1, 30) for _ in range(rng.randint(3, 9))]
                       for _ in range(12)])
    write("5_io", [[rng.randint(1, 50) for _ in range(8)] for _ in range(200)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
