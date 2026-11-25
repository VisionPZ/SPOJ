#!/usr/bin/env python3
import random
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    element_count = tokens[0]
    query_count = tokens[1]
    values = tokens[2:2 + element_count]
    cursor = 2 + element_count
    answers = []
    for _ in range(query_count):
        left = tokens[cursor]
        right = tokens[cursor + 1]
        factor = tokens[cursor + 2]
        cursor += 3
        span = right - left + 1
        required = (span + factor - 1) // factor
        if required <= 1:
            answers.append("YES")
            continue
        frequencies = Counter(values[left - 1:right])
        answers.append("YES" if max(frequencies.values()) >= required else "NO")
    return "\n".join(answers) + "\n"


SAMPLE = """8 3
1 4 2 3 2 2 5 3
2 6 2
1 8 2
1 8 3
"""
SAMPLE_OUT = """YES
NO
YES
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n1\n1 1 1\n") == "YES\n"
assert oracle("2 1\n1 2\n1 2 1\n") == "NO\n"
assert oracle("3 1\n1 1 1\n1 3 1\n") == "YES\n"
assert oracle("4 1\n1 2 3 4\n1 4 2\n") == "NO\n"


def write(name, values, queries):
    lines = [f"{len(values)} {len(queries)}", " ".join(str(value) for value in values)]
    lines.extend(f"{left} {right} {factor}" for left, right, factor in queries)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1], [(1, 1, 1), (1, 1, 2), (1, 1, 3)])
    rng = random.Random(20261126)
    wide = [rng.randint(1, 2147483647) for _ in range(200)]
    wide_queries = []
    for _ in range(2000):
        left = rng.randint(1, 200)
        right = rng.randint(left, 200)
        wide_queries.append((left, right, rng.randint(1, 5)))
    write("3_wide", wide, wide_queries)
    mixed = [rng.randint(1, 50) for _ in range(500)]
    mixed_queries = []
    for _ in range(2000):
        left = rng.randint(1, 500)
        right = rng.randint(left, 500)
        mixed_queries.append((left, right, rng.randint(1, 8)))
    write("4_random", mixed, mixed_queries)
    io_values = [rng.randint(1, 10) for _ in range(20)]
    io_queries = []
    for _ in range(100000):
        left = rng.randint(1, 20)
        right = rng.randint(left, 20)
        io_queries.append((left, right, 1))
    write("5_io", io_values, io_queries)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 4, 2, 3, 2, 2, 5, 3], [(2, 6, 2), (1, 8, 2), (1, 8, 3)])
build()
