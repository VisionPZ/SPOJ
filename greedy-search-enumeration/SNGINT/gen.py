#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PRIMES = (2, 3, 5, 7)
DIGIT_VECTORS = (
    (9, (0, 2, 0, 0)),
    (8, (3, 0, 0, 0)),
    (7, (0, 0, 0, 1)),
    (6, (1, 1, 0, 0)),
    (5, (0, 0, 1, 0)),
    (4, (2, 0, 0, 0)),
    (3, (0, 1, 0, 0)),
    (2, (1, 0, 0, 0)),
)


def encode_one(target):
    if target == 0:
        return "10"
    if target == 1:
        return "1"
    rest = target
    exponents = []
    for prime in PRIMES:
        count = 0
        while rest % prime == 0:
            rest //= prime
            count += 1
        exponents.append(count)
    if rest != 1:
        return "-1"
    best = [None]

    def search(index, remaining, counts):
        if index == len(DIGIT_VECTORS):
            if any(remaining):
                return
            chosen = []
            for (digit, _), count in zip(DIGIT_VECTORS, counts):
                chosen.extend([str(digit)] * count)
            candidate = "".join(sorted(chosen))
            if best[0] is None or (len(candidate), candidate) < (len(best[0]), best[0]):
                best[0] = candidate
            return
        _, vector = DIGIT_VECTORS[index]
        limit = min(remaining[p] // vector[p] for p in range(4) if vector[p])
        for count in range(limit, -1, -1):
            nxt = list(remaining)
            for prime_index in range(4):
                nxt[prime_index] -= count * vector[prime_index]
            counts.append(count)
            search(index + 1, nxt, counts)
            counts.pop()

    search(0, exponents, [])
    return best[0] if best[0] is not None else "-1"


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    return "".join(encode_one(value) + "\n" for value in tokens[1:1 + count])


def brute_small(target, limit=300000):
    if target == 0:
        return "10"
    for candidate in range(1, limit + 1):
        product = 1
        for char in str(candidate):
            product *= int(char)
            if product > target:
                break
        if product == target:
            return str(candidate)
    return None


SAMPLE = """3
24
5
11
"""
SAMPLE_OUT = """38
5
-1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert encode_one(0) == "10"
assert encode_one(1) == "1"
assert encode_one(24) == "38"
assert encode_one(11) == "-1"
assert encode_one(4194304) == "28888888"
assert encode_one(3906250) == "2555555555"
assert encode_one(999983) == "-1"
for target in range(0, 160):
    prediction = encode_one(target)
    found = brute_small(target)
    if prediction == "-1":
        assert found is None, (target, prediction, found)
    else:
        assert found == prediction, (target, prediction, found)


def write(name, values):
    text = str(len(values)) + "\n" + "".join(str(value) + "\n" for value in values)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [0, 1, 2, 3, 5, 8, 9, 10, 11, 24, 25, 49, 64, 100, 10000000 - 1])
    write("3_wide", [4194304, 4782969, 1953125, 5764801, 746496, 999983, 9999991])
    rng = random.Random(20261126)
    write("4_random", [rng.randrange(0, 10000000) for _ in range(500)])
    write("5_io", [3906250] * 10000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [24, 5, 11])
build()
