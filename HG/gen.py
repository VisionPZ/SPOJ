#!/usr/bin/env python3
import math
import random
import sys
from pathlib import Path

sys.set_int_max_str_digits(100000)
ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    first_count = tokens[0]
    first_values = tokens[1:1 + first_count]
    second_count = tokens[1 + first_count]
    second_values = tokens[2 + first_count:2 + first_count + second_count]
    product_first = math.prod(first_values)
    product_second = math.prod(second_values)
    divisor = math.gcd(product_first, product_second)
    if len(str(divisor)) > 9:
        return f"{divisor % 1000000000:09d}\n"
    return f"{divisor}\n"


SAMPLE = """3
2 3 5
2
4 5
"""
SAMPLE_OUT = """10
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3\n358572 83391967 82\n3\n50229961 1091444 8863\n") == "000012028\n"
assert oracle("1\n1\n1\n1\n") == "1\n"
assert oracle("1\n2\n1\n3\n") == "1\n"
assert 10**9 % 10**9 == 0
assert len("000012028") == 9


def write(name, first_values, second_values):
    text = (f"{len(first_values)}\n" + " ".join(str(value) for value in first_values) + "\n"
            + f"{len(second_values)}\n" + " ".join(str(value) for value in second_values) + "\n")
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1], [999999999])
    write("3_wide", [999983] * 1000, [999983] * 1000)
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 999999999) for _ in range(1000)],
          [rng.randint(1, 999999999) for _ in range(1000)])
    common = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]
    write("5_io", [common[index % len(common)] * rng.randint(1, 1000000) for index in range(1000)],
          [common[index % len(common)] * rng.randint(1, 1000000) for index in range(1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [2, 3, 5], [4, 5])
build()
