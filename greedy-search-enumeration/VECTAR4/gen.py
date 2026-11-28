#!/usr/bin/env python3
import math
import random
from collections import deque
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def max_kills(days):
    if days % 2 == 1:
        peak = (days + 1) // 2
        return peak * peak
    peak = days // 2
    return peak * (peak + 1)


@lru_cache(maxsize=None)
def oracle_value(enemies):
    low = 1
    high = 2 * math.isqrt(enemies) + 5
    while low < high:
        middle = (low + high) // 2
        if max_kills(middle) >= enemies:
            high = middle
        else:
            low = middle + 1
    return low


def brute_value(enemies):
    queue = deque([(1, 1, 1)])
    seen = {(1, 1)}
    while queue:
        total, last, days = queue.popleft()
        if total == enemies and last <= 1:
            return days
        if total >= enemies:
            continue
        for following in (last - 1, last, last + 1):
            if following < 0:
                continue
            state = (total + following, following)
            if state not in seen:
                seen.add(state)
                queue.append((total + following, following, days + 1))
    return -1


def oracle(text):
    tokens = [int(value) for value in text.split()]
    return "\n".join(str(oracle_value(value)) for value in tokens[1:]) + "\n"


SAMPLE = """3
4
1
9
"""
SAMPLE_OUT = """3
1
5
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert all(brute_value(value) == oracle_value(value) for value in range(1, 200))
assert oracle_value(2) == 2
assert oracle_value(3) == 3
assert oracle_value(7) == 5
assert oracle_value(10**18) == 1999999999


def write(name, values):
    text = f"{len(values)}\n" + "\n".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 5, 999999999999999999, 10**18])
    write("3_wide", [10**18, 10**18 - 1, 999999999999999999, 500000000000000000])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 10**18) for _ in range(200)])
    pool = [1, 2, 3, 4, 9, 16, 17, 1000000, 10**18]
    write("5_io", [rng.choice(pool) for _ in range(100000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [4, 1, 9])
build()
