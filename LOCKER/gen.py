#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007
DP_LIMIT = 2200

best = [1] * (DP_LIMIT + 1)
for length in range(1, DP_LIMIT + 1):
    best[length] = max(part * best[length - part] for part in range(1, length + 1))


def formula(length):
    if length <= 3:
        return length
    remainder = length % 3
    if remainder == 0:
        return pow(3, length // 3, MOD)
    if remainder == 1:
        return 4 * pow(3, (length - 4) // 3, MOD) % MOD
    return 2 * pow(3, (length - 2) // 3, MOD) % MOD


def oracle(text):
    values = [int(value) for value in text.split()]
    return "".join(str(best[value] % MOD) + "\n" for value in values[1:])


SAMPLE = "2\n4\n5\n"
SAMPLE_OUT = "4\n6\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert all(best[value] % MOD == formula(value) for value in range(1, DP_LIMIT + 1))
assert best[4] == 4 and best[5] == 6 and best[6] == 9
assert best[10] == 36


def write(name, values):
    text = f"{len(values)}\n" + "".join(str(value) + "\n" for value in values)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", list(range(1, 16)))
    write("3_wide", [DP_LIMIT - index for index in range(100)])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, DP_LIMIT) for _ in range(100)])
    write("5_io", [rng.randint(1, DP_LIMIT) for _ in range(100000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
