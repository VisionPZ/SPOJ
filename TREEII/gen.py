#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007


def enumerate_sequences(size):
    found = set()

    def walk(remaining, levels):
        if remaining == 1:
            found.add(tuple(levels))
            return
        remainder = remaining - 1
        divisor = 1
        while divisor * divisor <= remainder:
            if remainder % divisor == 0:
                walk(divisor, levels + [remainder // divisor])
                paired = remainder // divisor
                if paired != divisor:
                    walk(paired, levels + [divisor])
            divisor += 1
    walk(size, [])
    return len(found)


def divisor_dp(limit):
    counts = [0] * (limit + 2)
    counts[1] = 1
    for size in range(2, limit + 1):
        total = 0
        remainder = size - 1
        divisor = 1
        while divisor * divisor <= remainder:
            if remainder % divisor == 0:
                total += counts[divisor]
                paired = remainder // divisor
                if paired != divisor:
                    total += counts[paired]
            divisor += 1
        counts[size] = total % MOD
    return counts


def oracle(text):
    sizes = [int(value) for value in text.split()]
    counts = divisor_dp(max(sizes))
    return "".join(f"Case {index}: {counts[size]}\n" for index, size in enumerate(sizes, 1))


SAMPLE_IN = "1\n2\n3\n40\n50\n600\n700\n"
SAMPLE_OUT = (
    "Case 1: 1\nCase 2: 1\nCase 3: 2\nCase 4: 924\n"
    "Case 5: 1998\nCase 6: 315478277\nCase 7: 825219749\n"
)
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert enumerate_sequences(1) == 1
assert enumerate_sequences(2) == 1
assert enumerate_sequences(3) == 2
assert enumerate_sequences(40) == 924
assert enumerate_sequences(50) == 1998
for size in range(1, 61):
    assert enumerate_sequences(size) == divisor_dp(60)[size]


def write(name, sizes):
    text = "".join(f"{size}\n" for size in sizes)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 1, 2, 2, 3, 3, 4])
    write("3_wide", [1000] * 20)
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 1000) for _ in range(50)])
    write("5_io", [rng.randint(900, 1000) for _ in range(200)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
