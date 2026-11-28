#!/usr/bin/env python3
import math
import random
import sys
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.setrecursionlimit(200000)
if hasattr(sys, "set_int_max_str_digits"):
    sys.set_int_max_str_digits(100000)
PI = math.pi


@lru_cache(maxsize=None)
def recursive_oracle(value):
    if value < 4:
        return 1
    return recursive_oracle(round(value - 1, 10)) + recursive_oracle(round(value - PI, 10))


def formula_oracle(value):
    if value < 4:
        return 1
    threshold = value - 4
    total = 0
    current_n = threshold
    current_k = threshold
    binomial = 1
    first_term = True
    step = 0
    while True:
        base = threshold - step * PI
        highest = math.floor(base + 1e-9)
        if highest < 0:
            break
        lowest_first = math.floor(base - PI + 1e-9) + 1
        lowest_second = math.floor(base - 1.0 + 1e-9) + 1
        kept = highest
        while kept >= max(0, lowest_first):
            wanted_n = kept + step
            wanted_k = kept
            if first_term:
                current_n = wanted_n
                current_k = wanted_k
                first_term = False
            else:
                while current_k > wanted_k:
                    binomial = binomial * current_k // (current_n - current_k + 1)
                    current_k -= 1
                while current_n > wanted_n:
                    binomial = binomial * (current_n - current_k) // current_n
                    current_n -= 1
            total += binomial
            if kept >= lowest_second:
                total += binomial
            kept -= 1
        step += 1
    return total


def format_answer(value):
    text = str(value)
    return "".join(text[offset:offset + 50] + "\n" for offset in range(0, len(text), 50))


def oracle(text):
    tokens = [int(token) for token in text.split()]
    output = []
    for query in tokens:
        if query < 0:
            break
        value = recursive_oracle(query) if query <= 200 else formula_oracle(query)
        output.append(format_answer(value))
    return "".join(output)


SAMPLE = """0
4
11
-1
"""
SAMPLE_OUT = """1
2
20
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert recursive_oracle(0) == 1
assert recursive_oracle(4) == 2
assert recursive_oracle(11) == 20
assert recursive_oracle(30) == 27193
assert formula_oracle(100) == recursive_oracle(100)
for query in range(0, 150):
    assert formula_oracle(query) == recursive_oracle(query)
assert format_answer(10**60) == "1" + "0" * 49 + "\n" + "0" * 11 + "\n"


def write_case(name, queries):
    text = "\n".join(str(query) for query in queries) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_case("2_edges", [0, 1, 3, 4, 5, 6, 7, 8, -1])
    write_case("3_wide", [500, 1000, 2000, -1])
    rng = random.Random(20261126)
    write_case("4_random", [rng.randint(0, 400) for _ in range(20)] + [-1])
    write_case("5_io", [5000, 6000, 7000, 8000, 9000, -1])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
