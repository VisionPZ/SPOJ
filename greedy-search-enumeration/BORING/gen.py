#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PRIME_POOL = [3, 5101, 5003, 15013, 995009, 1005007, 99995011, 100005001, 9999995023,
              10000005139, 999999995009, 1000000005041, 99999999995023, 100000000005001,
              9999999999995023, 10000000000005007, 999999999999995083, 1000000000000005029,
              3999999999999995051, 4000000000000005037]


def brute(limit, prime):
    result = 1
    for number in range(1, limit + 1):
        result = result * number % prime
    return result


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    results = []
    for case in range(count):
        limit = tokens[1 + 2 * case]
        prime = tokens[2 + 2 * case]
        if limit >= prime:
            results.append("0")
            continue
        quotient = 1
        for number in range(limit + 1, prime):
            quotient = quotient * number % prime
        results.append(str((-pow(quotient, prime - 2, prime)) % prime))
    return "\n".join(results) + "\n"


SAMPLE = """3
2 5
5 11
21 71
"""
SAMPLE_OUT = """2
10
6
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute(2, 5) == 2
assert brute(5, 11) == 10
assert brute(21, 71) == 6
assert oracle("1\n4 5\n") == "4\n"
assert oracle("1\n5 5\n") == "0\n"
for prime in (5, 7, 11, 13, 101):
    for limit in range(1, prime):
        assert oracle(f"1\n{limit} {prime}\n") == str(brute(limit, prime)) + "\n"


def write(name, cases):
    text = str(len(cases)) + "\n"
    for limit, prime in cases:
        text += f"{limit} {prime}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 2), (2, 3), (4, 5), (5, 5), (6, 5), (5100, 5101),
                      (999999999999999083, 999999999999999083)])
    write("3_wide", [(prime - 1 - distance, prime) for prime in PRIME_POOL[-6:] for distance in (0, 1, 9999)])
    rng = random.Random(20261126)
    cases = []
    for _ in range(999):
        prime = rng.choice(PRIME_POOL)
        distance = rng.randint(0, min(9999, prime - 2))
        if rng.random() < 0.2:
            limit = prime + rng.randint(0, min(9999, max(0, 4 * 10**18 - prime - 1)))
        else:
            limit = prime - 1 - distance
        cases.append((limit, prime))
    write("4_random", cases)
    write("5_io", [(995009 - 1 - rng.randint(0, 30), 995009) for _ in range(2000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
