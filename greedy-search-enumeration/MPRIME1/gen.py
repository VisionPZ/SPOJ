#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
LIMIT = 11000


def oracle(text):
    values = [int(token) for token in text.split()]
    sieve = bytearray(b"\x01") * (LIMIT + 1)
    sieve[0] = sieve[1] = 0
    for prime in range(2, int(LIMIT ** 0.5) + 1):
        if sieve[prime]:
            sieve[prime * prime::prime] = b"\x00" * (((LIMIT - prime * prime) // prime) + 1)
    primes = [value for value in range(2, LIMIT + 1) if sieve[value]]
    prefix = [0]
    for prime in primes:
        prefix.append(prefix[-1] + prime)
    counts = [0] * (LIMIT + 1)
    for start in range(len(primes)):
        for end in range(start + 1, len(primes) + 1):
            total = prefix[end] - prefix[start]
            if total > LIMIT:
                break
            counts[total] += 1
    return "".join(str(counts[value]) + "\n" for value in values if value != 0)


SAMPLE = """2
3
17
41
20
666
12
53
0
"""
SAMPLE_OUT = """1
1
2
3
0
0
1
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("53\n0\n") == "2\n"
assert oracle("41\n0\n") == "3\n"
assert oracle("20\n0\n") == "0\n"
assert oracle("3\n2\n0\n") == "1\n1\n"
assert oracle("5\n0\n") == "2\n"


def write(name, values):
    text = "".join(str(value) + "\n" for value in values) + "0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [2, 3, 4, 5, 6, 7, 10999, 11000])
    write("3_wide", [11000, 10999, 10000, 9999, 5000, 5001, 11000])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(2, 11000) for _ in range(500)])
    write("5_io", [rng.randint(2, 11000) for _ in range(20000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
