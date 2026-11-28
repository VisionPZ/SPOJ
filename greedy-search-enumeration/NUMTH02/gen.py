#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    base, exponent, rooms = tokens[0], tokens[1], tokens[2]
    partitions = tokens[3]
    amounts = tokens[4:4 + partitions]
    extra_buckets = (base ** exponent) % rooms
    if extra_buckets == 0:
        return "0 0\n"
    extra_mangoes = sum(amounts) % extra_buckets
    return f"{extra_buckets} {extra_mangoes}\n"


SAMPLE = """2 3 5
3
2
4
4
"""
SAMPLE_OUT = """3 1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2 4 7\n1\n5\n") == "2 1\n"
assert oracle("3 2 4\n2\n10\n20\n") == "1 0\n"
assert oracle("1 999999 13\n1\n1000000000000000000\n") == "1 0\n"
assert 2 ** 3 == 8 and 8 % 5 == 3 and (2 + 4 + 4) % 3 == 1


def write(name, base, exponent, rooms, amounts):
    parts = [f"{base} {exponent} {rooms}", str(len(amounts))]
    parts.extend(str(value) for value in amounts)
    input_text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", 1, 1, 2, [1])
    write("3_wide", 1000000, 1000000, 5000, [10 ** 18] * 50)
    rng = random.Random(20261126)
    amounts = [rng.randint(1, 10 ** 18) for _ in range(50)]
    write("4_random", rng.randint(1, 1000000), rng.randint(1, 1000000), rng.randint(1, 5000), amounts)
    write("5_io", 999999, 999999, 4999, [10 ** 18] * 50)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 2, 3, 5, [2, 4, 4])
build()
