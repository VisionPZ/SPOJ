#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    array_length = tokens[0]
    query_count = tokens[1]
    values = tokens[2:2 + array_length]
    lines = []
    offset = 2 + array_length
    for _ in range(query_count):
        span = tokens[offset]
        begin = tokens[offset + 1]
        offset += 2
        total = 0
        for step in range(span):
            total += values[(begin - 1 + step) % array_length]
        lines.append(str(total))
    return "\n".join(lines) + ("\n" if lines else "")


SAMPLE = """5 2
4 2 6 1 7
3 2
3 9
"""
SAMPLE_OUT = """9
12
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 3\n7\n1 1\n2 3\n3 5\n") == "7\n14\n21\n"
assert oracle("3 2\n1 2 3\n4 2\n5 3\n") == "8\n10\n"
assert oracle("4 1\n10 20 30 40\n2 4\n") == "50\n"
assert (9 - 1) % 5 == 3


def write(name, array_length, values, queries):
    text = f"{array_length} {len(queries)}\n" + " ".join(str(v) for v in values) + "\n"
    text += "".join(f"{span} {begin}\n" for span, begin in queries)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, [7], [(1, 1), (2, 3), (3, 5)])
    write("3_wide", 1000, [1000000000 - index for index in range(1000)],
          [(1000, 1000), (999, 500), (1, 1000)])
    rng = random.Random(20261126)
    values = [rng.randint(1, 1000000000) for _ in range(50)]
    queries = [(rng.randint(1, 200), rng.randint(1, 200)) for _ in range(200)]
    write("4_random", 50, values, queries)
    values = [rng.randint(1, 1000) for _ in range(100)]
    queries = [(rng.randint(1, 60), rng.randint(1, 200)) for _ in range(20000)]
    write("5_io", 100, values, queries)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 5, [4, 2, 6, 1, 7], [(3, 2), (3, 9)])
build()
