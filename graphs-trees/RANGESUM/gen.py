#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = list(map(int, text.split()))
    cursor = 0
    count = tokens[cursor]
    cursor += 1
    values = tokens[cursor:cursor + count]
    cursor += count
    query_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(query_count):
        kind = tokens[cursor]
        cursor += 1
        if kind == 1:
            left = tokens[cursor]
            right = tokens[cursor + 1]
            cursor += 2
            answers.append(str(sum(values[left - 1:right])))
        else:
            values.insert(0, tokens[cursor])
            cursor += 1
    return "".join(answer + "\n" for answer in answers)


SAMPLE = """10
1 2 3 4 5 6 7 8 9 10
4
1 1 10
1 1 1
1 10 10
1 2 7
"""
SAMPLE_OUT = """55
1
10
27
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n7\n1\n1 1 1\n") == "7\n"
assert oracle("3\n1 2 3\n2\n2 -4\n1 1 4\n") == "2\n"
assert oracle("2\n-5 5\n2\n2 9\n1 1 3\n") == "9\n"
assert sum(range(1, 11)) == 55


def write(name, values, queries):
    lines = [str(len(values)), " ".join(str(value) for value in values), str(len(queries))]
    for query in queries:
        lines.append(" ".join(str(field) for field in query))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1], [(1, 1, 1), (2, -7), (1, 1, 2), (2, 9), (1, 1, 3), (1, 2, 3)])
    rng = random.Random(20261127)
    wide_values = [rng.randint(-10**9, 10**9) for _ in range(500)]
    wide_queries = []
    for _ in range(500):
        if rng.random() < 0.3:
            wide_queries.append((2, rng.randint(-10**9, 10**9)))
        else:
            size = len(wide_values) + sum(1 for query in wide_queries if query[0] == 2)
            left = rng.randint(1, size)
            right = rng.randint(left, size)
            wide_queries.append((1, left, right))
    write("3_wide", wide_values, wide_queries)
    random_values = [rng.randint(-1000, 1000) for _ in range(60)]
    random_queries = []
    for _ in range(400):
        if rng.random() < 0.35:
            random_queries.append((2, rng.randint(-1000, 1000)))
        else:
            size = len(random_values) + sum(1 for query in random_queries if query[0] == 2)
            left = rng.randint(1, size)
            right = rng.randint(left, size)
            random_queries.append((1, left, right))
    write("4_random", random_values, random_queries)
    io_values = [rng.randint(-10**6, 10**6) for _ in range(20)]
    io_queries = []
    for _ in range(100000):
        size = len(io_values) + sum(1 for query in io_queries if query[0] == 2)
        left = rng.randint(1, size)
        right = rng.randint(left, size)
        io_queries.append((1, left, right))
    write("5_io", io_values, io_queries)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
