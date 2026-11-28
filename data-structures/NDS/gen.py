#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10 ** 30


def oracle_case(values, length):
    best = [-1] + [INF] * length
    for value in values:
        for current in range(length - 1, -1, -1):
            if best[current] < value < best[current + 1]:
                best[current + 1] = value
    return str(best[length]) if best[length] < INF else "-1"


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        count = int(tokens[cursor]); cursor += 1
        values = [int(tokens[cursor + index]) for index in range(count)]
        cursor += count
        length = int(tokens[cursor]); cursor += 1
        if length > count:
            answers.append("-1")
        else:
            answers.append(oracle_case(values, length))
    return "\n".join(answers) + "\n"


SAMPLE = """1
7
9 7 2 5 4 11 12 
3
"""
SAMPLE_OUT = """11
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_case([1, 2, 3], 1) == "1"
assert oracle_case([3, 2, 1], 2) == "-1"
assert oracle_case([5, 5, 5], 2) == "-1"
assert oracle_case([2, 5, 4, 11], 3) == "11"


def write(name, cases):
    chunks = [str(len(cases))]
    for values, length in cases:
        chunks.append(str(len(values)))
        chunks.append(" ".join(str(value) for value in values))
        chunks.append(str(length))
    text = "\n".join(chunks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [([7], 1), ([7], 2), ([5, 5, 5], 1), ([5, 5, 5], 2),
                      ([1, 2, 3, 4], 4), ([4, 3, 2, 1], 3), ([0, 0, 1], 2)])
    rng = random.Random(20261126)
    wide = []
    for _ in range(8):
        values = [rng.randint(0, 1000000) for _ in range(200)]
        wide.append((values, rng.randint(1, 205)))
    write("3_wide", wide)
    random_cases = []
    for _ in range(30):
        values = [rng.randint(0, 100) for _ in range(rng.randint(1, 100))]
        random_cases.append((values, rng.randint(1, len(values) + 2)))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(100):
        values = [rng.randint(0, 1000) for _ in range(20)]
        io_cases.append((values, rng.randint(1, 22)))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
