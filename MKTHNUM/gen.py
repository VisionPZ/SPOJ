#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    count = tokens[cursor]
    cursor += 1
    questions = tokens[cursor]
    cursor += 1
    values = tokens[cursor:cursor + count]
    cursor += count
    answers = []
    for _ in range(questions):
        left = tokens[cursor]
        right = tokens[cursor + 1]
        order = tokens[cursor + 2]
        cursor += 3
        segment = sorted(values[left - 1:right])
        answers.append(str(segment[order - 1]))
    return "\n".join(answers) + ("\n" if answers else "")


SAMPLE = """7 3
1 5 2 6 3 7 4
2 5 3
4 4 1
1 7 3
"""
SAMPLE_OUT = """5
6
3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3 2\n-5 0 7\n1 3 1\n1 3 3\n") == "-5\n7\n"
assert oracle("1 1\n1000000000\n1 1 1\n") == "1000000000\n"
assert oracle("4 2\n5 5 5 5\n1 4 2\n2 3 2\n") == "5\n5\n"


def write(name, values, questions):
    lines = [f"{len(values)} {len(questions)}", " ".join(str(value) for value in values)]
    lines.extend(f"{left} {right} {order}" for left, right, order in questions)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [-5, 0, 7, -1000000000, 1000000000],
          [(1, 5, 1), (1, 5, 5), (2, 4, 2), (3, 3, 1)])
    rng = random.Random(20261126)
    wide_values = [rng.randint(-1000000000, 1000000000) for _ in range(1500)]
    wide_questions = []
    for _ in range(2000):
        left = rng.randint(1, 1500)
        right = rng.randint(left, 1500)
        wide_questions.append((left, right, rng.randint(1, right - left + 1)))
    write("3_wide", wide_values, wide_questions)
    random_values = [rng.randint(-100000, 100000) for _ in range(800)]
    random_questions = []
    for _ in range(1000):
        left = rng.randint(1, 800)
        right = rng.randint(left, 800)
        random_questions.append((left, right, rng.randint(1, right - left + 1)))
    write("4_random", random_values, random_questions)
    io_values = [rng.randint(-1000000000, 1000000000) for _ in range(1000)]
    io_questions = []
    for _ in range(5000):
        left = rng.randint(1, 1000)
        right = rng.randint(left, 1000)
        io_questions.append((left, right, rng.randint(1, right - left + 1)))
    write("5_io", io_values, io_questions)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 5, 2, 6, 3, 7, 4], [(2, 5, 3), (4, 4, 1), (1, 7, 3)])
build()
