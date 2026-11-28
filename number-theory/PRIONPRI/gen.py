#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "6\n16\n127\n256\n513\n2048\n5097\n"
SAMPLE_OUT = "NO\nYES\nNO\nNO\nNO\nNO\n"


def sieve(limit):
    flags = [True] * (limit + 1)
    flags[0] = False
    if limit >= 1:
        flags[1] = False
    for i in range(2, math.isqrt(limit) + 1):
        if flags[i]:
            for j in range(i * i, limit + 1, i):
                flags[j] = False
    return [i for i in range(2, limit + 1) if flags[i]]


PRIMES = sieve(31623)


def oracle(input_text):
    tokens = input_text.split()
    case_count = int(tokens[0])
    numbers = [int(t) for t in tokens[1:1 + case_count]]
    lines = []
    for number in numbers:
        prime = number >= 2
        for p in PRIMES:
            if p * p > number:
                break
            if number % p == 0:
                prime = False
                break
        lines.append("YES" if prime else "NO")
    return "\n".join(lines) + "\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("3\n2\n3\n4\n") == "YES\nYES\nNO\n"
assert oracle("1\n999999937\n") == "YES\n"
assert oracle("1\n999999938\n") == "NO\n"
assert oracle("1\n999999999\n") == "NO\n"


def write(name, numbers):
    input_text = "%d\n%s\n" % (len(numbers), "\n".join(str(n) for n in numbers))
    (ROOT / "in" / ("%s.txt" % name)).write_text(input_text)
    (ROOT / "out" / ("%s.out" % name)).write_text(oracle(input_text))


def build():
    write("2_edges", [2, 3, 4, 9, 25, 37, 41, 31623, 31627, 31622, 999999937, 999999938])
    write("3_wide", [999999937, 999999929, 1000000000, 999999999, 999999938,
                     999999893, 999999936, 500000003, 999999935])
    rng = random.Random(20190108)
    write("4_random", [rng.randint(2, 10**9) for _ in range(2000)])
    write("5_io", [rng.randint(2, 10**6) for _ in range(100000)])


if __name__ == "__main__":
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [16, 127, 256, 513, 2048, 5097])
    build()
