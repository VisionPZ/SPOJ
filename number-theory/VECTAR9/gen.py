#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 10 ** 9 + 7
PRIMES = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41]
PERIOD = math.prod(PRIMES)
PERIOD_COUNT = PERIOD - math.prod([prime - 1 for prime in PRIMES])

SUBSETS = []
for mask in range(1, 1 << len(PRIMES)):
    divisor = 1
    parity = 0
    for index, prime in enumerate(PRIMES):
        if mask >> index & 1:
            divisor *= prime
            parity ^= 1
    SUBSETS.append((divisor, 1 if parity else -1))


def count_mangu(value):
    total = 0
    for divisor, sign in SUBSETS:
        total += sign * (value // divisor)
    return total


SIEVE_LIMIT = 5000
sieve = bytearray([1]) * (SIEVE_LIMIT + 1)
sieve[0] = sieve[1] = 0
for value in range(2, math.isqrt(SIEVE_LIMIT) + 1):
    if sieve[value]:
        sieve[value * value::value] = b"\0" * len(sieve[value * value::value])
SMALL_MANGU = [value for value in range(2, SIEVE_LIMIT + 1)
               if any(value % prime == 0 for prime in PRIMES)]


def kth_by_count(requested):
    period_number = (requested - 1) // PERIOD_COUNT
    local_rank = (requested - 1) % PERIOD_COUNT + 1
    low, high = 1, PERIOD
    while low < high:
        middle = (low + high) // 2
        if count_mangu(middle) >= local_rank:
            high = middle
        else:
            low = middle + 1
    return period_number * PERIOD + low


def kth(requested):
    if requested <= len(SMALL_MANGU):
        return SMALL_MANGU[requested - 1]
    return kth_by_count(requested)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    return "\n".join(str(kth(tokens[index + 1])) for index in range(case_count)) + "\n"


SAMPLE = """2
2
3
"""
SAMPLE_OUT = """3
4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert count_mangu(PERIOD) == PERIOD_COUNT
assert kth(1) == 2 and kth(2) == 3 and kth(3) == 4
assert kth_by_count(100) == SMALL_MANGU[99]
assert kth_by_count(2000) == SMALL_MANGU[1999]
assert kth_by_count(PERIOD_COUNT) == PERIOD
for sample_rank in (1, 2, 3, 7, 50, 500, 1500, 3000, len(SMALL_MANGU)):
    assert kth_by_count(sample_rank) == SMALL_MANGU[sample_rank - 1]


def write(name, ranks):
    text = str(len(ranks)) + "\n" + "".join(str(value) + "\n" for value in ranks)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 5, 10, 100, 500, 1000, PERIOD_COUNT - 1, PERIOD_COUNT])
    write("3_wide", [PERIOD_COUNT, PERIOD_COUNT - 1, PERIOD_COUNT // 2,
                     10 ** 12, 10 ** 13, 50000, 100000, 200000])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 4000) for _ in range(200)])
    write("5_io", [rng.randint(1, 4000) for _ in range(500)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [2, 3])
build()
