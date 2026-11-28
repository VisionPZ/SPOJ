#!/usr/bin/env python3
import random
from math import gcd
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def period_answer(a, b, n):
    period = a // gcd(a, b) * b
    first_period = sorted(set(range(a, period + 1, a)) | set(range(b, period + 1, b)))
    blocks, offset = divmod(n - 1, len(first_period))
    return blocks * period + first_period[offset]


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    answers = []
    for _ in range(case_count):
        divisor_a, divisor_b, target = tokens[cursor:cursor + 3]
        cursor += 3
        answers.append(str(period_answer(divisor_a, divisor_b, target)))
    return "\n".join(answers) + "\n"


def brute(a, b, n):
    found = 0
    value = 0
    while found < n:
        value += 1
        if value % a == 0 or value % b == 0:
            found += 1
    return value


SAMPLE = "1\n2 3 10\n"
SAMPLE_OUT = "15\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 2 5\n") == "10\n"
assert oracle("1\n1 1 1\n") == "1\n"
assert oracle("1\n4 6 8\n") == "24\n"
assert period_answer(2, 3, 10) == brute(2, 3, 10)
assert period_answer(4, 6, 8) == brute(4, 6, 8)


def write(name, triples):
    text = str(len(triples)) + "\n" + "".join(
        f"{a} {b} {n}\n" for a, b, n in triples)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1, 1), (2, 2, 1000000000), (1, 10000, 999999999),
                      (10000, 9999, 7), (9999, 10000, 8)])
    write("3_wide", [(10000, 9999, 1000000000), (9999, 9998, 999999999),
                     (10000, 10000, 1000000000), (1, 10000, 1000000000)])
    rng = random.Random(20261126)
    triples = []
    for _ in range(40):
        divisor_a = rng.randint(1, 10000)
        divisor_b = rng.randint(1, 10000)
        target = rng.randint(1, 1000000000)
        triples.append((divisor_a, divisor_b, target))
    write("4_random", triples)
    io_triples = [(rng.randint(1, 12), rng.randint(1, 12), rng.randint(1, 1000000000))
                  for _ in range(100000)]
    write("5_io", io_triples)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(2, 3, 10)])
build()
