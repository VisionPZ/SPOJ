#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    exponent = tokens[0]
    attack_count = tokens[1]
    cursor = 2
    answers = []
    modulus = 10 ** 9 + 7
    for _ in range(attack_count):
        left = tokens[cursor]
        right = tokens[cursor + 1]
        cursor += 2
        total = 0
        for upper in range(left, right + 1):
            inner = 0
            for divisor in range(1, upper + 1):
                inner = (inner + pow(math.gcd(divisor, upper), exponent, modulus)) % modulus
            total = (total + inner) % modulus
        answers.append(str(total))
    return "\n".join(answers) + "\n"


SAMPLE_IN = """1
1
1 5
"""
SAMPLE_OUT = """26
"""
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle("1\n1\n1 1\n") == "1\n"
assert oracle("2\n1\n1 3\n") == "17\n"
assert oracle("1\n1\n3 5\n") == "22\n"
assert oracle("1\n2\n1 1\n1 5\n") == "1\n26\n"


def write(name, exponent, queries):
    lines = [str(exponent), str(len(queries))]
    lines.extend(f"{left} {right}" for left, right in queries)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", 1, [(1, 1), (2, 2), (1, 2), (7, 7)])
    write("3_wide", 100000, [(1, 20), (10, 40), (25, 60)])
    def random_queries(count):
        result = []
        for _ in range(count):
            left = rng.randint(1, 40)
            result.append((left, rng.randint(left, 50)))
        return result

    write("4_random", 12345, random_queries(100))
    write("5_io", 99991, random_queries(2000))
    big_lines = ["100000", "100000"]
    for _ in range(100000):
        left = rng.randint(1, 99000)
        big_lines.append(f"{left} {rng.randint(left, 100000)}")
    Path("/tmp/NTG_big.txt").write_text("\n".join(big_lines) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
