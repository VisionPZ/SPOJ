#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 10 ** 9


@lru_cache(maxsize=None)
def count_height(size, height):
    if size == 0:
        return 1 if height == -1 else 0
    if height < 0 or size < 0:
        return 0
    if size == 1 and height == 0:
        return 1
    total = 0
    for left_height in range(-1, height):
        for right_height in range(-1, height):
            if abs(left_height - right_height) > 1:
                continue
            if 1 + max(left_height, right_height) != height:
                continue
            for left_size in range(0, size):
                left_count = count_height(left_size, left_height)
                if left_count == 0:
                    continue
                right_count = count_height(size - 1 - left_size, right_height)
                total += left_count * right_count
    return total % MOD


@lru_cache(maxsize=None)
def answer(size):
    return sum(count_height(size, height) for height in range(0, 10)) % MOD


def oracle(text):
    values = [value for value in text.split() if value]
    return "".join(f"{answer(int(value)):09d}\n" for value in values)


SAMPLE = "1\n3\n6\n21\n"
SAMPLE_OUT = "000000001\n000000001\n000000004\n000036900\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert answer(1) == 1
assert answer(2) == 2
assert answer(3) == 1
assert answer(6) == 4
assert answer(21) == 36900
assert answer(0) == 0


def write(name, sizes):
    text = "".join(f"{size}\n" for size in sizes)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 4, 7, 12, 32, 60])
    write("3_wide", [1, 3, 6, 21] * 12)
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 60) for _ in range(120)])
    write("5_io", [rng.randint(1, 40) for _ in range(4000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 3, 6, 21])
build()
