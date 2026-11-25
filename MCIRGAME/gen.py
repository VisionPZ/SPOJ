#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(pair_count):
    ways = [0] * (pair_count + 1)
    ways[0] = 1
    for count in range(1, pair_count + 1):
        total = 0
        for left_size in range(count):
            total += ways[left_size] * ways[count - 1 - left_size]
        ways[count] = total
    return ways[pair_count]


SAMPLE = "2\n-1\n"
SAMPLE_OUT = "2\n"
assert oracle(1) == 1
assert oracle(2) == 2
assert oracle(3) == 5
assert oracle(4) == 14
assert oracle(10) == math.comb(20, 10) // 11
assert "\n".join(str(oracle(value)) for value in [2]) + "\n" == SAMPLE_OUT


def write(name, queries):
    text = "".join(f"{value}\n" for value in queries) + "-1\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(
        "".join(f"{oracle(value)}\n" for value in queries)
    )


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)

write("2_edges", [1, 3, 4, 5, 10])
write("3_wide", [150, 149, 148, 100, 75])
rng = random.Random(20261127)
write("4_random", [rng.randint(1, 150) for _ in range(40)])
write("5_io", [150] * 500)
