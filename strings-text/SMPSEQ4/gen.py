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
    kept = []
    for candidate in source:
        found = False
        for queried in query:
            if candidate == queried:
                found = True
                break
        if found:
            kept.append(candidate)
    return "".join(str(value) + " " for value in kept) + "\n"


def input_text(source, query):
    lines = [str(len(source)), " ".join(str(v) for v in source),
             str(len(query)), " ".join(str(v) for v in query)]
    return "\n".join(lines) + "\n"


def write(name, source, query):
    text = input_text(source, query)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


SAMPLE = "5\n-2 -1 0 1 4\n6\n-3 -2 -1 1 2 3\n"
SAMPLE_OUT = "-2 -1 1 \n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2\n1 2\n2\n1 2\n") == "1 2 \n"
assert oracle("2\n5 5\n2\n1 2\n") == "\n"
assert oracle(input_text([-100, -100, 100], [-100, 0, 50])) == "-100 -100 \n"

write("1_sample", [-2, -1, 0, 1, 4], [-3, -2, -1, 1, 2, 3])
write("2_edges", [1, 2, 3, 4, 5], [6, 7, 8, 9, 10])
write("3_wide", list(range(-100, 101)), [-100, -99, -98, 0, 99, 100])
random.seed(2026)
source = sorted(random.randint(-100, 100) for _ in range(100))
query = sorted(random.randint(-100, 100) for _ in range(100))
write("4_random", source, query)
write("5_io", [-100, -100, -100, 0, 0, 100, 100, 100], [-100, 0, 99, 100])
