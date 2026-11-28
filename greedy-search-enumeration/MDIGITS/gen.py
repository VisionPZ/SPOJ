#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(first_value, second_value):
    low_limit = min(first_value, second_value)
    high_limit = max(first_value, second_value)
    counts = [0] * 10
    for number in range(low_limit, high_limit + 1):
        for char in str(number):
            counts[ord(char) - 48] += 1
    return " ".join(str(count) for count in counts) + "\n"


SAMPLE = """1 10
44 497
346 542
1199 1748
1496 1403
1004 503
1714 190
1317 854
1976 494
1001 1960
0 0
"""
SAMPLE_OUT = """1 2 1 1 1 1 1 1 1 1
85 185 185 185 190 96 96 96 95 93
40 40 40 93 136 82 40 40 40 40
115 666 215 215 214 205 205 154 105 106
16 113 19 20 114 20 20 19 19 16
107 105 100 101 101 197 200 200 200 200
413 1133 503 503 503 502 502 417 402 412
196 512 186 104 87 93 97 97 142 196
398 1375 398 398 405 499 499 495 488 471
294 1256 296 296 296 296 287 286 286 247
"""
assert oracle(1, 10) == "1 2 1 1 1 1 1 1 1 1\n"
assert oracle(10, 1) == "1 2 1 1 1 1 1 1 1 1\n"
assert oracle(99999999, 99999999) == "0 0 0 0 0 0 0 0 0 8\n"
assert oracle(1, 9) == "0 1 1 1 1 1 1 1 1 1\n"
assert "".join(
    oracle(first, second)
    for first, second in [
        (1, 10), (44, 497), (346, 542), (1199, 1748), (1496, 1403),
        (1004, 503), (1714, 190), (1317, 854), (1976, 494), (1001, 1960),
    ]
) == SAMPLE_OUT


def write(name, pairs):
    text = "".join(f"{first} {second}\n" for first, second in pairs) + "0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(
        "".join(oracle(first, second) for first, second in pairs)
    )


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)

write("2_edges", [(1, 1), (1, 100), (99999999, 99999999), (10000000, 10000050)])
write("3_wide", [(99999000, 99999999), (50000, 50100)])
rng = random.Random(20261129)
random_pairs = []
for _ in range(20):
    start_value = rng.randint(1, 200000)
    span_value = rng.randint(0, 10000)
    end_value = min(99999999, start_value + span_value)
    random_pairs.append((start_value, end_value))
write("4_random", random_pairs)
write("5_io", [(1000 + index, 1000 + index + 10) for index in range(500)])
