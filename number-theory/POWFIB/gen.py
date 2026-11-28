#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007


def fib_values():
    values = set()
    first, second = 1, 1
    while first <= MOD + 500:
        values.add(first)
        first, second = second, first + second
    return sorted(values)


FIBS = fib_values()


def fib_mod(n):
    result = [[1, 0], [0, 1]]
    base = [[1, 1], [1, 0]]
    exponent = n
    while exponent:
        if exponent & 1:
            result = [[sum(result[i][k] * base[k][j] for k in range(2)) % MOD
                       for j in range(2)] for i in range(2)]
        base = [[sum(base[i][k] * base[k][j] for k in range(2)) % MOD
                 for j in range(2)] for i in range(2)]
        exponent >>= 1
    return result[0][1]


def nth_non_fib(n):
    import bisect
    guess = n
    while True:
        skipped = bisect.bisect_right(FIBS, guess)
        updated = n + skipped
        if updated == guess:
            return guess
        guess = updated


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    ranks = [int(value) for value in tokens[1:1 + case_count]]
    answers = []
    for rank in ranks:
        base = nth_non_fib(rank)
        exponent = fib_mod(rank)
        answers.append(str(pow(base, exponent, MOD)))
    return "\n".join(answers) + "\n"


SAMPLE = """3
3
2
1
"""
SAMPLE_OUT = """49
6
4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert nth_non_fib(1) == 4
assert nth_non_fib(2) == 6
assert nth_non_fib(3) == 7
assert fib_mod(10) == 55
assert pow(7, 2, MOD) == 49


def write(name, ranks):
    text = str(len(ranks)) + "\n" + "\n".join(str(rank) for rank in ranks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 5, 6, 7, 8])
    rng = random.Random(20261126)
    write("3_wide", [rng.randint(1, 900000000) for _ in range(50)])
    write("4_random", [1, 2, 3, 9, 10, 11, 12, 13, 14, 100, 1000, 99999999])
    write("5_io", [900000000] * 2000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
