#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    resident_count = tokens[0]
    names = tokens[1:1 + resident_count]
    if resident_count == 1:
        return str(names[0]) + "\n"
    total = 0
    for first_index in range(resident_count):
        for second_index in range(first_index + 1, resident_count):
            total += names[first_index] ^ names[second_index]
    return str(total) + "\n"


SAMPLE = "2\n19\n10\n"
SAMPLE_OUT = "25\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3\n7\n3\n5\n") == "12\n"
assert oracle("1\n7\n") == "7\n"
assert oracle("4\n9\n9\n9\n9\n") == "0\n"
assert oracle("3\n1\n2\n4\n") == "14\n"


def write(name, names):
    text = str(len(names)) + "\n" + "\n".join(str(value) for value in names) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [7, 3, 5])
    rng = random.Random(20261126)
    write("3_wide", [rng.randint(900000, 999999) for _ in range(200)])
    write("4_random", [rng.randint(1, 999999) for _ in range(150)])
    write("5_io", [rng.randint(1, 999999) for _ in range(300)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [19, 10])
build()
