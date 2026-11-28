#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
ORACLE_ROW_LIMIT = 25000


def edge_cost(lengths):
    return 2 * sum(lengths) + lengths[0] + len(lengths)


def count_rectangles(lengths):
    total = 0
    for top in range(len(lengths)):
        for bottom in range(top, len(lengths)):
            shortest = min(lengths[top:bottom + 1])
            total += shortest * (shortest + 1) // 2
    return total


def brute_small(match_count):
    best = 0

    def descend(lengths):
        nonlocal best
        if lengths and edge_cost(lengths) <= match_count:
            best = max(best, count_rectangles(lengths))
        if lengths:
            largest = lengths[-1]
        else:
            largest = match_count
        start = 1
        while start <= largest:
            trial = lengths + [start]
            if edge_cost(trial) > match_count:
                break
            descend(trial)
            start += 1

    descend([])
    return best


def uniform_cost(rows, length):
    return 2 * rows * length + length + rows


def oracle(match_count):
    if match_count < 4:
        return 0
    best = 0
    for rows in range(1, ORACLE_ROW_LIMIT + 1):
        low, high = 0, match_count // (2 * rows + 1) + 2
        while low < high:
            middle = (low + high + 1) // 2
            if uniform_cost(rows, middle) <= match_count:
                low = middle
            else:
                high = middle - 1
        base = low
        if base == 0:
            break
        leftover = match_count - uniform_cost(rows, base)
        extra = 0
        if leftover > 0:
            extra = min(rows - 1, (leftover - 1) // 2)
        row_sum = rows * (rows + 1) // 2
        length_sum = base * (base + 1) // 2
        extra_sum = extra * (extra + 1) // 2
        candidate = length_sum * row_sum + (base + 1) * extra_sum
        if candidate > best:
            best = candidate
    return best


SAMPLE = """5
3
4
8
12
15
"""
SAMPLE_OUT = """0
1
3
9
12
"""
assert oracle(3) == 0
assert oracle(4) == 1
assert oracle(8) == 3
assert oracle(12) == 9
assert oracle(15) == 12
assert all(oracle(value) == brute_small(value) for value in range(1, 31))


def write(name, values):
    input_text = "\n".join([str(len(values))] + [str(value) for value in values]) + "\n"
    output_text = "\n".join(str(oracle(value)) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(output_text)


def build():
    write("2_edges", [1, 2, 3, 4, 5, 6, 7, 9, 11, 16])
    write("3_wide", [1000000000, 999999999, 500000000, 1000000])
    rng = random.Random(20261130)
    write("4_random", [rng.randint(1, 1000000000) for _ in range(40)])
    write("5_io", [rng.randint(1, 1000000000) for _ in range(40)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
