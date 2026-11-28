#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    numbers = list(map(int, text.split()))
    pos = 0
    answers = []
    while pos < len(numbers):
        tree_length = numbers[pos]
        question_count = numbers[pos + 1]
        pos += 2
        heights = numbers[pos:pos + tree_length]
        pos += tree_length
        for _ in range(question_count):
            left = numbers[pos]
            right = numbers[pos + 1]
            limit = numbers[pos + 2]
            pos += 3
            best = 0
            for height in heights[left:right + 1]:
                if height <= limit and height > best:
                    best = height
            answers.append(str(best))
    return "\n".join(answers) + "\n"


SAMPLE = """9 8
1 5 9 11 9 7 6 2 1
1 6 4
1 6 10
0 8 97
0 8 4
1 4 5
2 6 8
2 8 5
3 3 12
"""
SAMPLE_OUT = """0
9
11
2
5
7
2
11
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n0\n0 0 0\n") == "0\n"
assert oracle("3 2\n1000000 1 2\n0 2 999999\n0 2 1000000\n") == "2\n1000000\n"
assert oracle("4 3\n5 5 5 5\n0 3 4\n1 2 5\n2 3 0\n") == "0\n5\n0\n"


def write(name, tree_length, heights, questions):
    lines = [f"{tree_length} {len(questions)}"]
    lines.append(" ".join(str(value) for value in heights))
    for left, right, limit in questions:
        lines.append(f"{left} {right} {limit}")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 5, [0, 0, 3, 1000000, 2],
          [(0, 4, 2), (2, 3, 999999), (4, 4, 0), (0, 0, 1000000)])
    rng = random.Random(20261126)
    wide_questions = []
    for _ in range(200):
        first = rng.randrange(300)
        second = rng.randrange(300)
        wide_questions.append((min(first, second), max(first, second), rng.randint(0, 1000000)))
    write("3_wide", 300, [rng.randint(0, 1000000) for _ in range(300)], wide_questions)
    questions = []
    for index in range(60):
        left = rng.randrange(100)
        right = min(99, left + rng.randrange(100))
        questions.append((left, right, rng.randint(0, 1000000)))
    write("4_random", 100, [rng.randint(0, 1000000) for _ in range(100)], questions)
    rng_io = random.Random(77)
    io_questions = []
    for _ in range(30000):
        first = rng_io.randrange(100)
        second = rng_io.randrange(100)
        io_questions.append((min(first, second), max(first, second), rng_io.randint(0, 1000000)))
    write("5_io", 100, [rng_io.randint(0, 1000000) for _ in range(100)], io_questions)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
sample_heights = [1, 5, 9, 11, 9, 7, 6, 2, 1]
sample_questions = [(1, 6, 4), (1, 6, 10), (0, 8, 97), (0, 8, 4),
                    (1, 4, 5), (2, 6, 8), (2, 8, 5), (3, 3, 12)]
write("1_sample", 9, sample_heights, sample_questions)
build()
