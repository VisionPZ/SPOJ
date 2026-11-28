#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(piece) for piece in text.split()]
    source_count = tokens[0]
    source = tokens[1:1 + source_count]
    query_count = tokens[1 + source_count]
    query = tokens[2 + source_count:2 + source_count + query_count]
    matched = []
    for position, (left, right) in enumerate(zip(source, query), 1):
        if left == right:
            matched.append(position)
    return " ".join(str(value) for value in matched) + "\n"


def input_text(source, query):
    lines = [str(len(source)), " ".join(str(v) for v in source),
             str(len(query)), " ".join(str(v) for v in query)]
    return "\n".join(lines) + "\n"


def write(name, source, query):
    text = input_text(source, query)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


SAMPLE = "5\n-2 -2 -1 1 4 \n6\n-3 -2 -1 1 2 3\n"
SAMPLE_OUT = "2 3 4\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("5\n-2 -1 -3 1 4 \n5\n-3 -2 -1 1 2\n") == "4\n"
assert oracle("2\n7 8\n2\n-9 -9\n") == "\n"
assert oracle(input_text([5, 5, 5], [5, 5, 5])) == "1 2 3\n"

write("1_sample", [-2, -2, -1, 1, 4], [-3, -2, -1, 1, 2, 3])
write("2_edges", [-2, -1, -3, 1, 4], [-3, -2, -1, 1, 2])
write("3_wide", list(range(-50, 50)), list(range(-50, 50)))
random.seed(2026)
source = [random.randint(-100, 100) for _ in range(100)]
query = list(source)
for position in random.sample(range(100), 25):
    query[position] = random.randint(-100, 100)
write("4_random", source, query)
write("5_io", [0] * 100, [0] * 100)
