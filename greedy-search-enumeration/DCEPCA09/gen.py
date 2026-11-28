#!/usr/bin/env python3
import random
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    values = tokens[1:1 + count]
    query_count = tokens[1 + count]
    answers = []
    for query_index in range(query_count):
        left = tokens[2 + count + 2 * query_index]
        right = tokens[3 + count + 2 * query_index]
        segment = values[left:right + 1]
        length = len(segment)
        mean = sum(segment) // length
        ordered = sorted(segment)
        if length % 2:
            median = ordered[length // 2]
        else:
            median = (ordered[length // 2 - 1] + ordered[length // 2]) // 2
        frequencies = Counter(segment)
        peak = max(frequencies.values())
        mode = max(value for value, amount in frequencies.items() if amount == peak)
        answers.append(f"{mean} {median} {mode}")
    return "\n".join(answers) + "\n"


SAMPLE = "5\n6 5 3 7 7\n2\n1 2\n0 4\n"
SAMPLE_OUT = "4 4 5\n5 6 7\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2\n4 4\n1\n0 1\n") == "4 4 4\n"
assert oracle("2\n1 2\n1\n0 1\n") == "1 1 2\n"
assert oracle("3\n1 2 3\n2\n0 0\n2 2\n") == "1 1 1\n3 3 3\n"
assert max(value for value, amount in Counter([1, 3, 3, 2, 2]).items()
           if amount == 2) == 3


def write(name, values, queries):
    text = (str(len(values)) + "\n" + " ".join(str(value) for value in values) + "\n"
            + str(len(queries)) + "\n" + "".join(
                f"{left} {right}\n" for left, right in queries))
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [0, 0, 0, 1], [(0, 0), (0, 3), (2, 2), (1, 3)])
    write("3_wide", [100000000, 1, 99999999, 50000000] * 25,
          [(0, 99), (1, 98), (13, 87), (40, 59)])
    rng = random.Random(20261126)
    random_values = [rng.randint(0, 100000000) for _ in range(200)]
    random_queries = []
    for _ in range(200):
        left = rng.randint(0, 199)
        right = rng.randint(left, 199)
        random_queries.append((left, right))
    write("4_random", random_values, random_queries)
    io_values = [rng.randint(0, 100) for _ in range(100)]
    io_queries = []
    for _ in range(2000):
        left = rng.randint(0, 99)
        right = rng.randint(left, 99)
        io_queries.append((left, right))
    write("5_io", io_values, io_queries)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [6, 5, 3, 7, 7], [(1, 2), (0, 4)])
build()
