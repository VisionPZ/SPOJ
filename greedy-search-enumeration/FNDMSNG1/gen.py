#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    size = tokens[0]
    present = tokens[1:1 + size - 1]
    seen = set(present)
    for value in range(1, size + 1):
        if value not in seen:
            return str(value) + "\n"
    return "0\n"


SAMPLE = """10
10 2 3 1 9 7 8 6 4
"""
SAMPLE_OUT = """5
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2\n2\n") == "1\n"
assert oracle("2\n1\n") == "2\n"
assert oracle("5\n1 2 4 5\n") == "3\n"
assert oracle("4\n4 1 3\n") == "2\n"


def write(name, size, missing):
    values = [value for value in range(1, size + 1) if value != missing]
    random.Random(2000 + size).shuffle(values)
    text = f"{size}\n" + " ".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 2, 1)
    write("3_wide", 100, 100)
    rng = random.Random(20261127)
    randomSize = rng.randint(2, 100)
    write("4_random", randomSize, rng.randint(1, randomSize))
    write("5_io", 100, 50)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()

if __name__ == "__main__":
    big_n = 100000
    order = list(range(1, big_n + 1))
    order.pop(big_n // 2)
    Path("/tmp/FNDMSNG1_big.txt").write_text(
        "%d\n%s\n" % (big_n, " ".join(map(str, order))))
