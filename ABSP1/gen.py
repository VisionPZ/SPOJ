#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    answers = []
    for _ in range(case_count):
        count = tokens[cursor]
        cursor += 1
        values = tokens[cursor:cursor + count]
        cursor += count
        total = 0
        for first_index in range(count):
            for second_index in range(first_index + 1, count):
                total += abs(values[first_index] - values[second_index])
        answers.append(str(total))
    return "\n".join(answers) + "\n"


SAMPLE = """3
3
1 2 3
3
1 4 5
3
2 4 6
"""
SAMPLE_OUT = """4
8
8
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n5\n") == "0\n"
assert oracle("1\n2\n1 1\n") == "0\n"
assert oracle("1\n3\n1 1 3\n") == "4\n"
assert oracle("1\n4\n1 2 4 8\n") == "23\n"


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(
        str(len(values)) + "\n" + " ".join(str(value) for value in values) + "\n"
        for values in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [[1], [1, 1], [1, 1, 3], [1000000000, 1000000000]])
    write("3_wide", [[1000000000] * 300, list(range(1, 301))])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(120):
        count = rng.randint(1, 200)
        values = sorted(rng.randint(1, 1000000000) for _ in range(count))
        random_cases.append(values)
    write("4_random", random_cases)
    io_cases = []
    for _ in range(400):
        count = rng.randint(1, 150)
        values = sorted(rng.randint(1, 1000000000) for _ in range(count))
        io_cases.append(values)
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [[1, 2, 3], [1, 4, 5], [2, 4, 6]])
build()
