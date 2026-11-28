#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def is_prime(value):
    if value < 2:
        return False
    divisor = 2
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        divisor += 1
    return True


def oracle(text):
    tokens = [int(value) for value in text.split()]
    test_count = tokens[0]
    lines = []
    position = 1
    for _ in range(test_count):
        left = tokens[position]
        right = tokens[position + 1]
        position += 2
        if left > right:
            left, right = right, left
        primes = [str(value) for value in range(left, right + 1) if is_prime(value)]
        lines.append(",".join(primes))
    return "\n".join(lines) + "\n"


SAMPLE = """2
10 50
500 400
"""
SAMPLE_OUT = """11,13,17,19,23,29,31,37,41,43,47
401,409,419,421,431,433,439,443,449,457,461,463,467,479,487,491,499
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1\n") == "\n"
assert oracle("1\n2 2\n") == "2\n"
assert oracle("1\n14 16\n") == "\n"
assert oracle("1\n4 3\n") == "3\n"
assert is_prime(499) and not is_prime(500)


def write(name, pairs):
    text = f"{len(pairs)}\n" + "".join(f"{left} {right}\n" for left, right in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1), (2, 2), (14, 16), (4, 3)])
    write("3_wide", [(1, 500), (500, 1), (250, 251)])
    rng = random.Random(20261126)
    pairs = []
    for _ in range(100):
        left = rng.randint(1, 500)
        right = rng.randint(1, 500)
        pairs.append((left, right))
    write("4_random", pairs)
    write("5_io", [(1, 500) for _ in range(1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
