#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    element_count = tokens[0]
    query_count = tokens[1]
    difference_limit = tokens[2]
    values = tokens[3:3 + element_count]
    cursor = 3 + element_count
    lines = []
    for _ in range(query_count):
        left = tokens[cursor] - 1
        right = tokens[cursor + 1] - 1
        cursor += 2
        segment = sorted(values[left:right + 1])
        close_pairs = 0
        following = 0
        for index, value in enumerate(segment):
            if following < index + 1:
                following = index + 1
            while following < len(segment) and segment[following] - value < difference_limit:
                following += 1
            close_pairs += following - index - 1
        total_pairs = len(segment) * (len(segment) - 1) // 2
        lines.append(str(total_pairs - close_pairs))
    return "\n".join(lines) + "\n"


SAMPLE = "3 1 21\n2 31 3\n2 3\n"
SAMPLE_OUT = "1\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2 1 1 5 5 1 2\n") == "0\n"
assert oracle("3 1 100 4 8 15 1 3\n") == "0\n"
assert oracle("4 1 3 1 1 4 5 1 4\n") == "4\n"
assert oracle("2 1 0 7 7 1 2\n") == "1\n"


def write(name, values, queries, difference_limit):
    chunks = [f"{len(values)} {len(queries)} {difference_limit}",
              " ".join(str(value) for value in values)]
    for left, right in queries:
        chunks.append(f"{left} {right}")
    text = "\n".join(chunks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 1, 2, 2, 3], [(1, 1), (1, 5), (2, 4), (3, 3), (1, 2)], 2)
    rng = random.Random(20261126)
    wide = [rng.randint(1, 30) for _ in range(120)]
    wide_queries = [(lng, rng.randint(lng, 120)) for lng in (rng.randint(1, 120) for _ in range(120))]
    write("3_wide", wide, wide_queries, 15)
    medium = [rng.randint(1, 50) for _ in range(200)]
    medium_queries = []
    for _ in range(200):
        left = rng.randint(1, 200)
        medium_queries.append((left, rng.randint(left, 200)))
    write("4_random", medium, medium_queries, 25)
    large = [rng.randint(1, 100) for _ in range(300)]
    many_queries = []
    for _ in range(600):
        left = rng.randint(1, 300)
        many_queries.append((left, rng.randint(left, 300)))
    write("5_io", large, many_queries, 40)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
