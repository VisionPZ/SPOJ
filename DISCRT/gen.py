#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(modulus, exponent, target):
    solutions = [
        value for value in range(modulus)
        if math.gcd(value, modulus) == 1 and pow(value, exponent, modulus) == target
    ]
    lines = [str(len(solutions))]
    lines.extend(str(value) for value in solutions)
    return "\n".join(lines) + "\n"


def solve_text(text):
    modulus, exponent, target = (int(token) for token in text.split()[:3])
    return oracle(modulus, exponent, target)


SAMPLE = """5 1 3
"""
SAMPLE_OUT = """1
3
"""
assert oracle(5, 1, 3) == SAMPLE_OUT
assert oracle(9, 2, 4) == "2\n2\n7\n"
assert oracle(7, 3, 6) == "3\n3\n5\n6\n"
assert oracle(27, 3, 8) == "3\n2\n11\n20\n"
assert oracle(5, 0, 1) == "4\n1\n2\n3\n4\n"
assert oracle(25, 1, 7) == "1\n7\n"
assert solve_text(SAMPLE) == SAMPLE_OUT


def write(name, modulus, exponent, target):
    text = f"{modulus} {exponent} {target}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(modulus, exponent, target))


def build():
    write("2_edges", 9, 2, 4)
    write("3_wide", 27, 3, 8)
    rng = random.Random(20261126)
    primes = [7, 11, 13, 17, 19, 23, 29, 31]
    prime = rng.choice(primes)
    exponent_count = rng.randint(1, 2)
    modulus = prime ** exponent_count
    write("4_random", modulus, rng.randint(1, 4), rng.randint(1, modulus - 1))
    write("5_io", 5003, 0, 1)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
