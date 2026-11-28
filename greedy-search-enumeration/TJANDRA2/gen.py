#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute_answer(match_count):
    best = 0
    height = 1
    while 2 * height * height + 2 * height <= match_count + 4:
        for full_rows in range(1, height + 1):
            span = 2 * height + 1 - height + 2 * full_rows
            available = match_count - span
            if available < 0:
                continue
            width = available // (2 * height + 1) + 1
            while width >= 2 or (width == 1 and full_rows == height):
                used = 2 * width * height + width - height + 2 * full_rows
                if used <= match_count:
                    break
                width -= 1
            if width < 1 or (full_rows < height and width < 2):
                continue
            triangle = lambda value: value * (value + 1) // 2
            rectangles = triangle(width) * triangle(full_rows) + triangle(width - 1) * (
                triangle(height) - triangle(full_rows)
            )
            if rectangles > best:
                best = rectangles
        height += 1
    return best


def divisor_answer(match_count):
    from sympy import factorint
    product = 2 * match_count + 1
    factors = factorint(product)
    divisors = [1]
    for prime, exponent in factors.items():
        divisors = [value * prime ** power for value in divisors for power in range(exponent + 1)]
    best = 0
    for divisor in divisors:
        if divisor > product // divisor:
            continue
        height = (divisor - 1) // 2
        width = (product // divisor - 1) // 2
        rectangles = (width * (width + 1) // 2) * (height * (height + 1) // 2)
        if rectangles > best:
            best = rectangles
    return best


SAMPLE_INPUT = """6
3
4
8
12
15
987654321123456789
"""
SAMPLE_OUTPUT = """0
1
3
9
12
60966316127114768913148159571503206
"""

assert brute_answer(3) == 0
assert brute_answer(4) == 1
assert brute_answer(8) == 3
assert brute_answer(12) == 9
assert brute_answer(15) == 12
assert brute_answer(20) == 22
assert brute_answer(90) == 481
assert divisor_answer(987654321123456789) == 60966316127114768913148159571503206


def oracle(match_counts):
    lines = []
    for value in match_counts:
        if value <= 1000000:
            lines.append(str(brute_answer(value)))
        else:
            lines.append(str(divisor_answer(value)))
    return "\n".join(lines) + "\n"


def write(name, values):
    (ROOT / "in" / f"{name}.txt").write_text(str(len(values)) + "\n" + "\n".join(str(v) for v in values) + "\n")
    (ROOT / "out" / f"{name}.out").write_text(oracle(values))


def build():
    write("2_edges", [3, 4, 5, 7, 8, 12, 15, 20, 21, 29, 36, 56, 90, 100, 120])
    rng = random.Random(20261126)
    write("3_wide", [rng.randint(4, 1000000) for _ in range(40)])
    write("4_random", [rng.randint(4, 1000000) for _ in range(60)])
    write("5_io", [rng.randint(4, 1000000) for _ in range(200)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUTPUT)
build()
