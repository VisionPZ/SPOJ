#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute_oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        element_count = int(tokens[cursor]); cursor += 1
        query_count = int(tokens[cursor]); cursor += 1
        values = [int(tokens[cursor + index]) for index in range(element_count)]
        cursor += element_count
        for _ in range(query_count):
            range_end = int(tokens[cursor]); cursor += 1
            answers.append(str(min(values[:range_end])))
    return "\n".join(answers) + "\n"


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        element_count = int(tokens[cursor]); cursor += 1
        query_count = int(tokens[cursor]); cursor += 1
        values = [int(tokens[cursor + index]) for index in range(element_count)]
        cursor += element_count
        prefix_min = list(itertools.accumulate(values, min))
        for _ in range(query_count):
            range_end = int(tokens[cursor]); cursor += 1
            answers.append(str(prefix_min[range_end - 1]))
    return "\n".join(answers) + "\n"


SAMPLE = """1
4 2
2 2 3 1
3 4
"""
SAMPLE_OUT = """2
1
"""
assert brute_oracle(SAMPLE) == SAMPLE_OUT
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute_oracle("1\n1 1\n5\n1\n") == oracle("1\n1 1\n5\n1\n") == "5\n"
assert brute_oracle("1\n3 3\n3 2 1\n1 2 3\n") == oracle("1\n3 3\n3 2 1\n1 2 3\n") == "3\n2\n1\n"
assert brute_oracle("2\n2 1\n5 4\n\n2\n3 1\n1 1 2\n\n3\n") == oracle("2\n2 1\n5 4\n\n2\n3 1\n1 1 2\n\n3\n") == "4\n1\n"


def write(name, cases):
    rows = []
    for values, queries in cases:
        rows.append(f"{len(values)} {len(queries)}")
        rows.append(" ".join(str(value) for value in values))
        rows.append(" ".join(str(value) for value in queries))
    text = "\n".join([str(len(cases))] + rows) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        ([7], [1]),
        ([5, 4], [1, 2]),
        ([3, 2, 1], [1, 2, 3]),
        ([9, 9, 9], [3, 1, 2]),
        ([1, 100000, 2, 99999], [4, 3, 2, 1]),
    ])
    write("3_wide", [
        (list(range(100000, 0, -1)), [1, 2, 50000, 99999, 100000]),
        ([100000] * 100000, [100000, 1, 77777]),
    ])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(12):
        element_count = rng.randint(1, 1200)
        query_count = rng.randint(1, 1200)
        values = [rng.randint(1, 100000) for _ in range(element_count)]
        queries = [rng.randint(1, element_count) for _ in range(query_count)]
        random_cases.append((values, queries))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(3):
        values = [rng.randint(1, 100000) for _ in range(100000)]
        queries = [rng.randint(1, 100000) for _ in range(100000)]
        io_cases.append((values, queries))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [([2, 2, 3, 1], [3, 4])])
build()
