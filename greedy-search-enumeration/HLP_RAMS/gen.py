#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute_one(row_number):
    row = [math.comb(row_number, index) for index in range(row_number + 1)]
    even = sum(1 for value in row if value % 2 == 0)
    odd = len(row) - even
    return f"{even} {odd}"


def oracle_one(row_number):
    set_bits = bin(row_number).count("1")
    odd = 1 << set_bits
    even = row_number + 1 - odd
    return f"{even} {odd}"


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    return "".join(oracle_one(value) + "\n"
                   for value in tokens[1:1 + case_count])


SAMPLE = """2
3
4
"""
SAMPLE_OUT = """0 4
3 2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute_one(0) == oracle_one(0)
for check_value in range(1, 41):
    assert brute_one(check_value) == oracle_one(check_value)
assert oracle_one(3) == "0 4"
assert oracle_one(4) == "3 2"
assert oracle_one(0) == "0 1"
assert oracle_one((1 << 40) - 1) == f"0 {1 << 40}"


def write(name, values):
    input_text = str(len(values)) + "\n" + "".join(
        f"{value}\n" for value in values)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [0, 1, 2, 3, (1 << 40) - 1, 1 << 40, 10**12])
    rng = random.Random(20261126)
    write("3_wide", [rng.randint(0, 10**12) for _ in range(200)])
    write("4_random", [rng.randint(0, 10**12) for _ in range(1000)])
    write("5_io", [rng.randint(0, 10**12) for _ in range(100000)])
    big = [rng.randint(0, 10**12) for _ in range(100000)]
    Path("/tmp/HLP_RAMS_big.txt").write_text(
        str(len(big)) + "\n" + "".join(f"{value}\n" for value in big))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [3, 4])
build()
