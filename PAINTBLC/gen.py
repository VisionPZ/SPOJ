#!/usr/bin/env python3
import random
import sys
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007
sys.setrecursionlimit(1000000)


def oracle(counts):
    kind_count = len(counts)
    initial = tuple(counts)

    @lru_cache(maxsize=None)
    def walk(remaining, previous):
        if not any(remaining):
            return 1
        total = 0
        for index in range(kind_count):
            if remaining[index] > 0 and index != previous:
                updated = remaining[:index] + (remaining[index] - 1,) + remaining[index + 1:]
                total += walk(updated, index)
        return total

    return walk(initial, -1) % MOD


def oracle_text(cases):
    return "".join(str(oracle(counts)) + "\n" for counts in cases)


def input_text(cases):
    parts = [str(len(cases)) + "\n"]
    for counts in cases:
        parts.append(str(len(counts)) + "\n" + " ".join(str(value) for value in counts) + "\n")
    return "".join(parts)


SAMPLE_CASES = [[1, 2, 3], [2, 2, 2, 2, 2], [1, 1, 2, 2, 3, 3, 4, 4, 5, 5]]
SAMPLE_IN = input_text(SAMPLE_CASES)
SAMPLE_OUT = "10\n39480\n85937576\n"
assert oracle([1, 2, 3]) == 10
assert oracle([2, 2, 2, 2, 2]) == 39480
assert oracle(SAMPLE_CASES[2]) == 85937576
assert oracle([1]) == 1
assert oracle([2]) == 0
assert oracle([1, 1]) == 2
assert oracle_text(SAMPLE_CASES) == SAMPLE_OUT


def write(name, cases):
    text = input_text(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle_text(cases))


def build():
    write("2_edges", [[1], [2], [3], [5], [6], [1, 1], [1, 2], [6, 6], [1, 1, 1]])
    write("3_wide", [[1] * 15, [2] * 10, [3] * 6, [4] * 5, [6] * 4])
    rng = random.Random(20261126)
    write("4_random", [[rng.randint(1, 4) for _ in range(rng.randint(2, 7))] for _ in range(20)])
    write("5_io", [[rng.randint(1, 2) for _ in range(rng.randint(1, 4))] for _ in range(2000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
