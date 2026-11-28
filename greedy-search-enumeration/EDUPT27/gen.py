#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    first_end = tokens.index(-1)
    list_values = tokens[:first_end]
    second_end = tokens.index(-1, first_end + 1)
    pattern = tokens[first_end + 1:second_end]
    result = list(list_values)
    if pattern:
        width = len(pattern)
        while True:
            found_at = -1
            for start in range(len(result) - width + 1):
                if result[start:start + width] == pattern:
                    found_at = start
                    break
            if found_at < 0:
                break
            del result[found_at:found_at + width]
    return " ".join(str(value) for value in result) + "\n"


SAMPLE = "3 5 1 8 9 5 7 -1\n5 1 8 -1\n"
SAMPLE_OUT = "3 9 5 7\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3 7 1 5 9 7 1 2 -1\n7 1 -1\n") == "3 5 9 2\n"
assert oracle("10 4 6 8 4 6 8 12 12 9 1 3 -1\n4 6 8 12 -1\n") == "10 9 1 3\n"
assert oracle("3 9 5 7 -1\n9 3 -1\n") == "3 9 5 7\n"
assert oracle("1 2 3 -1\n-1\n") == "1 2 3\n"


def write(name, list_values, pattern):
    text = " ".join(str(value) for value in list_values) + " -1\n"
    text += " ".join(str(value) for value in pattern) + " -1\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3], [])
    write("2_edge_full", [7, 7, 7], [7])
    write("3_wide", list(range(32000, 32000 - 3000, -1)), [32000, 31999])
    rng = random.Random(20261126)
    values = [rng.randint(0, 30) for _ in range(200)]
    pattern = values[20:24]
    write("4_random", values, pattern)
    repeated = [1, 2, 3] * 100
    write("5_io", repeated, [1, 2, 3])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [3, 5, 1, 8, 9, 5, 7], [5, 1, 8])
build()
