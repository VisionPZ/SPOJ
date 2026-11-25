#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    case_count = tokens[position]
    position += 1
    answers = []
    for _ in range(case_count):
        count = tokens[position]
        position += 1
        values = tokens[position:position + count]
        position += count
        inversions = 0
        for left in range(count):
            for right in range(left + 1, count):
                if values[left] > values[right]:
                    inversions += 1
        local_inversions = 0
        for index in range(count - 1):
            if values[index] > values[index + 1]:
                local_inversions += 1
        answers.append("YES" if inversions == local_inversions else "NO")
    return "\n".join(answers) + "\n"


SAMPLE = """4
1
1
2
2 1
3
3 2 1
4
1 3 2 4
"""
SAMPLE_OUT = """YES
YES
NO
YES
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n3\n1 2 3\n") == "YES\n"
assert oracle("1\n3\n3 2 1\n") == "NO\n"
assert oracle("1\n4\n2 1 3 2\n") == "YES\n"
assert oracle("1\n5\n2 3 1 4 5\n") == "NO\n"


def write(name, cases):
    lines = [str(len(cases))]
    for values in cases:
        lines.append(str(len(values)))
        lines.append(" ".join(str(value) for value in values))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[1], [2, 1], [5, 5, 5, 5, 5], [2, 1, 3, 2], [3, 2, 1]])
    rng = random.Random(20261126)
    write("3_wide", [[rng.randint(1, 100) for _ in range(100)] for _ in range(10)])
    write("4_random", [[rng.randint(1, 100) for _ in range(rng.randint(1, 100))]
                       for _ in range(10)])
    write("5_io", [[rng.randint(1, 100) for _ in range(100)] for _ in range(10)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
