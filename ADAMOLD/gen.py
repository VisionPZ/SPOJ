#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    bloom_count = tokens[0]
    separator_count = tokens[1]
    values = tokens[2:2 + bloom_count]

    @lru_cache(maxsize=None)
    def cost(left, right):
        total = 0
        for first in range(left, right):
            for second in range(first + 1, right):
                total += values[first] ^ values[second]
        return total

    @lru_cache(maxsize=None)
    def solve(segments_left, upto):
        if segments_left == 1:
            return cost(0, upto)
        best = None
        for split in range(segments_left - 1, upto):
            candidate = solve(segments_left - 1, split) + cost(split, upto)
            if best is None or candidate < best:
                best = candidate
        return best

    return str(solve(separator_count + 1, bloom_count)) + "\n"


SAMPLE = """6 1
1 2 3 4 5 6
"""
SAMPLE_OUT = """12
"""
SECOND = """4 3
5 3 5 3
"""
SECOND_OUT = """0
"""
THIRD = """7 2
5 3 5 3 5 3 4
"""
THIRD_OUT = """24
"""
FOURTH = """9 4
1 2 3 4 5 6 7 666 1024
"""
FOURTH_OUT = """8
"""
FIFTH_IN = "30 8\n" + " ".join("629470789 417274987 617986533 841737683 297969800 432044389 708142005 156958893 499363651 434034331 176735187 525172817 747109631 949700868 259681519 357968078 818249370 456939952 450487335 529013233 327250536 90354657 643708145 141755216 656041628 661580907 204072850 469709611 834069223 681347499".split()) + "\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle(SECOND) == SECOND_OUT
assert oracle(THIRD) == THIRD_OUT
assert oracle(FOURTH) == FOURTH_OUT
assert oracle(FIFTH_IN) == "16154467281\n"


def write(name, separator_count, values):
    text = f"{len(values)} {separator_count}\n" + " ".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, [0, 0, 0, 0, 0])
    write("3_wide", 3, [10**9, 0, 10**9, 0, 10**9, 0, 10**9])
    rng = random.Random(20261126)
    write("4_random", 3, [rng.randint(0, 10**9) for _ in range(14)])
    write("5_io", 4, [rng.randint(0, 1000) for _ in range(18)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 1, [1, 2, 3, 4, 5, 6])
build()
