#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    element_count = tokens[0]
    values = tokens[1:1 + element_count]
    query_count = tokens[1 + element_count]
    cursor = 2 + element_count
    lines = []
    for _ in range(query_count):
        query_type = tokens[cursor]
        if query_type == 0:
            left, right, threshold = tokens[cursor + 1:cursor + 4]
            cursor += 4
            lines.append(str(sum(1 for value in values[left - 1:right] if value >= threshold)))
        else:
            index, new_value = tokens[cursor + 1:cursor + 3]
            cursor += 3
            values[index - 1] = new_value
    return "\n".join(lines) + "\n" if lines else ""


SAMPLE = """5
1 2 3 4 5
3
0 1 5 10
1 2 20
0 1 3 10
"""
SAMPLE_OUT = """0
1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n7\n2\n0 1 1 7\n0 1 1 8\n") == "1\n0\n"
assert oracle("3\n1 1 1\n2\n0 1 3 1\n0 2 2 2\n") == "3\n0\n"
assert oracle("4\n5 1 9 3\n3\n1 2 7\n0 1 4 5\n0 1 4 10\n") == "3\n0\n"


def write(name, values, queries):
    lines = [str(len(values)), " ".join(str(value) for value in values), str(len(queries))]
    lines.extend(" ".join(str(token) for token in query) for query in queries)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1], [(0, 1, 1, 1), (0, 1, 1, 2), (1, 1, 1000000000),
                           (0, 1, 1, 1000000000), (0, 1, 1, 1)])
    rng = random.Random(20261126)
    wide_values = [rng.randint(1, 1000000000) for _ in range(2000)]
    wide_queries = []
    for _ in range(1000):
        left = rng.randint(1, 2000)
        right = rng.randint(left, 2000)
        if rng.random() < 0.3:
            wide_queries.append((1, rng.randint(1, 2000), rng.randint(1, 1000000000)))
        else:
            wide_queries.append((0, left, right, rng.randint(1, 1000000000)))
    write("3_wide", wide_values, wide_queries)

    random_values = [rng.randint(1, 20) for _ in range(500)]
    random_queries = []
    for _ in range(1500):
        left = rng.randint(1, 500)
        right = rng.randint(left, 500)
        if rng.random() < 0.2:
            random_queries.append((1, rng.randint(1, 500), rng.randint(1, 20)))
        else:
            random_queries.append((0, left, right, rng.randint(1, 20)))
    write("4_random", random_values, random_queries)

    io_values = [rng.randint(1, 100) for _ in range(100)]
    io_queries = []
    for _ in range(100000):
        left = rng.randint(1, 100)
        right = rng.randint(left, 100)
        if rng.random() < 0.05:
            io_queries.append((1, rng.randint(1, 100), rng.randint(1, 100)))
        else:
            io_queries.append((0, left, right, rng.randint(1, 100)))
    write("5_io", io_values, io_queries)

    big_lines = ["500000", " ".join(str(rng.randint(1, 1000000000)) for _ in range(500000)),
                 "100000"]
    for _ in range(100000):
        big_lines.append("0 1 500000 500000000")
    Path("/tmp/GIVEAWAY_big.txt").write_text("\n".join(big_lines) + "\n")

    io_big_lines = ["500000", " ".join(str(rng.randint(1, 1000000000)) for _ in range(500000)),
                    "100000"]
    for index in range(100000):
        io_big_lines.append(f"1 {index + 1} {rng.randint(1, 1000000000)}")
    Path("/tmp/GIVEAWAY_io_big.txt").write_text("\n".join(io_big_lines) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 2, 3, 4, 5], [(0, 1, 5, 10), (1, 2, 20), (0, 1, 3, 10)])
build()
