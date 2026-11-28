#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 10 ** 9 + 7
SMALL = 10


def exact_counts(max_height):
    exact = [0] * (max_height + 1)
    exact[0] = 1

    def pair_sum(limit):
        total = 0
        for left_height in range(limit):
            left_value = exact[left_height]
            for right_height in range(left_height + 1):
                total += left_value * exact[right_height]
        return total

    for height in range(1, max_height + 1):
        exact[height] = pair_sum(height) - pair_sum(height - 1)
    return exact


EXACT = exact_counts(SMALL)


def mod_counts(max_height):
    values = [0] * (max_height + 1)
    if max_height >= 1:
        values[1] = 1
    prefix_total = 1
    for height in range(1, max_height + 1):
        if height >= 2:
            values[height] = values[height - 1] * prefix_total % MOD
        prefix_total = (prefix_total + values[height]) % MOD
    return values


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    queries = tokens[1:1 + case_count]
    table = mod_counts(max(queries))
    answers = []
    for height in queries:
        if height <= SMALL:
            answers.append(str(EXACT[height] % MOD))
        else:
            answers.append(str(table[height]))
    return "\n".join(answers) + "\n"


SAMPLE = """2
1
2
"""
SAMPLE_OUT = """1
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert EXACT[1:8] == [1, 2, 8, 96, 10368, 108615168, 11798392572168192]
assert oracle("7\n1 2 3 4 5 6 7\n") == "1\n2\n8\n96\n10368\n108615168\n489579448\n"
TABLE = mod_counts(SMALL)
for height in range(1, SMALL + 1):
    assert EXACT[height] % MOD == TABLE[height]
assert TABLE[7] == 489579448


def write(name, heights):
    text = str(len(heights)) + "\n" + "".join(str(value) + "\n" for value in heights)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 5, 6, 7, 8, 20, 40])
    write("3_wide", [10000000, 9999999, 5000000, 1000000, 1048576, 1048577])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 1000000) for _ in range(200)])
    write("5_io", [rng.randint(1, 10000000) for _ in range(100000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 2])
build()
