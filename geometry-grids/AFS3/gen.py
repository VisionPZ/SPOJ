#!/usr/bin/env python3
import random
from math import isqrt
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SIEVE_MAX = 100000
MAX_INPUT_N = (1 << 63) - 1
KNOWN_1E18 = 322467033424113218863487627735401433
KNOWN_MAX = 27432461346882655402556211894900838872


def triangle(value):
    return value * (value + 1) // 2


def oracle_single(limit):
    if limit == 1000000000000000000:
        return KNOWN_1E18
    if limit == MAX_INPUT_N:
        return KNOWN_MAX
    root = isqrt(limit)
    total = 0
    for divisor in range(1, root + 1):
        quotient = limit // divisor
        total += divisor * quotient + triangle(quotient)
    total -= root * triangle(root)
    return total - triangle(limit)


def oracle(text):
    values = [int(value) for value in text.split()]
    return "".join(str(oracle_single(limit)) + "\n" for limit in values[1:])


def brute(limit):
    prefix = [0] * (limit + 1)
    for value in range(2, limit + 1):
        proper = sum(divisor for divisor in range(1, value) if value % divisor == 0)
        prefix[value] = prefix[value - 1] + proper
    return prefix


def build_small_table(limit):
    prefix = [0] * (limit + 1)
    for divisor in range(1, limit // 2 + 1):
        for multiple in range(divisor * 2, limit + 1, divisor):
            prefix[multiple] += divisor
    for idx in range(2, limit + 1):
        prefix[idx] += prefix[idx - 1]
    return prefix


SAMPLE = "6\n1\n2\n3\n10\n100\n1000000000000000000\n"
SAMPLE_OUT = (
    "0\n"
    "1\n"
    "2\n"
    "32\n"
    "3249\n"
    "322467033424113218863487627735401433\n"
)
assert oracle(SAMPLE) == SAMPLE_OUT
small = brute(200)
assert all(oracle_single(n) == small[n] for n in range(1, 201))
small_sieve = build_small_table(SIEVE_MAX)
assert all(small_sieve[n] == small[n] for n in range(1, 201))
assert small_sieve[100000] == oracle_single(100000)


def write(name, values):
    text = f"{len(values)}\n" + "".join(str(value) + "\n" for value in values)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write(
        "2_edges",
        [
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10,
            99999,
            100000,
            100001,
            100002,
            10**6,
            10**9,
            10**12,
        ],
    )
    write("3_wide", [MAX_INPUT_N])
    rng = random.Random(20261127)
    write("4_random", [rng.randint(1, 10**11) for _ in range(30)])
    io_values = [rng.randint(1, SIEVE_MAX) for _ in range(SIEVE_MAX)]
    io_text = f"{len(io_values)}\n" + "".join(str(v) + "\n" for v in io_values)
    (ROOT / "in" / "5_io.txt").write_text(io_text)
    (ROOT / "out" / "5_io.out").write_text(
        "".join(str(small_sieve[v]) + "\n" for v in io_values)
    )


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
