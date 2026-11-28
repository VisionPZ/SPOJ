#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MAX_WEIGHT = 60000


def oracle_case(weights, queries):
    states = {(0, 0)}
    for weight in weights:
        states |= {(count + 1, total + weight)
                   for count, total in states if total + weight <= MAX_WEIGHT}
    by_total = {}
    for count, total in states:
        if count > 0:
            by_total.setdefault(total, set()).add(count)
    lines = []
    for query in queries:
        counts = sorted(by_total.get(query, set()))
        if counts:
            lines.append(" ".join(str(count) for count in counts))
        else:
            lines.append("That's impossible!")
    return lines


def parse_cases(text):
    tokens = text.split()
    cursor = 0
    cases = []
    while True:
        part_count = int(tokens[cursor]); cursor += 1
        query_count = int(tokens[cursor]); cursor += 1
        if part_count == 0 and query_count == 0:
            break
        weights = [int(tokens[cursor + index]) for index in range(part_count)]
        cursor += part_count
        queries = [int(tokens[cursor + index]) for index in range(query_count)]
        cursor += query_count
        cases.append((weights, queries))
    return cases


def oracle(text):
    lines = []
    for weights, queries in parse_cases(text):
        lines.extend(oracle_case(weights, queries))
    return "\n".join(lines) + "\n"


SAMPLE = "5 4\n1 2 3 1 1\n3\n5\n1\n9\n0 0\n"
SAMPLE_OUT = "1 2 3\n2 3 4\n1\nThat's impossible!\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_case([1], [0, 1, 2, -3]) == ["That's impossible!", "1", "That's impossible!", "That's impossible!"]
assert oracle_case([2, 2], [2, 4, 6]) == ["1", "2", "That's impossible!"]
assert oracle_case([1000] * 60, [60000, 60001]) == ["60", "That's impossible!"]
assert oracle_case([3, 5, 7], [8, 10, 12, 15]) == ["2", "2", "2", "3"]


def write(name, cases):
    parts = []
    for weights, queries in cases:
        parts.append(f"{len(weights)} {len(queries)}")
        parts.append(" ".join(str(weight) for weight in weights))
        parts.extend(str(query) for query in queries)
    parts.append("0 0")
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [([1000], [0, 1000, 1001, -5, MAX_WEIGHT]),
                      ([1000, 1000], [1000, 2000, 0, -1])])
    write("3_wide", [([1000] * 60, list(range(1000, 60001, 1000)))])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(4):
        weights = [rng.randint(1, 1000) for _ in range(40)]
        queries = [rng.randint(-20, MAX_WEIGHT + 20) for _ in range(200)]
        random_cases.append((weights, queries))
    write("4_random", random_cases)
    heavy_weights = [rng.randint(1, 1000) for _ in range(60)]
    heavy_queries = [rng.randint(-10, MAX_WEIGHT + 10) for _ in range(10000)]
    write("5_io", [(heavy_weights, heavy_queries)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
