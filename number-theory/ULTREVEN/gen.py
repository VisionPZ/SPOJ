#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    numbers = tokens[1:1 + count]
    return "YES\n" if all(value % 2 == 0 for value in numbers) else "NO\n"


SAMPLE = "4\n1 4 5 2\n"
SAMPLE_OUT = "NO\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3\n2 4 6\n") == "YES\n"
assert oracle("1\n1\n") == "NO\n"
assert oracle("1\n1000000000\n") == "YES\n"


def write(name, numbers):
    text = str(len(numbers)) + "\n" + " ".join(str(value) for value in numbers) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [2, 4, 6, 8, 10])
    write("3_wide", [1000000000] * 100000)
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 1000000000) for _ in range(100000)])
    write("5_io", [1000000000] * 100000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 4, 5, 2])
build()
