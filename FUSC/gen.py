#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def fusc_values(limit):
    values = [0] * (limit + 1)
    if limit >= 1:
        values[1] = 1
    for index in range(2, limit + 1):
        if index % 2 == 0:
            values[index] = values[index // 2]
        else:
            half = index // 2
            values[index] = values[half] + values[half + 1]
    return values


def brute(limit):
    return max(fusc_values(limit))


def submax(left, right, remaining):
    pairs = [(left, right)]
    for _ in range(remaining):
        candidates = set()
        for first, second in pairs:
            candidates.add((first, first + second))
            candidates.add((first + second, second))
        frontier = []
        best_second = -1
        for first, second in sorted(candidates, reverse=True):
            if second > best_second:
                frontier.append((first, second))
                best_second = second
        pairs = frontier
    return max(first for first, _ in pairs)


def oracle(limit):
    if limit == 0:
        return 0
    digits = bin(limit)[3:]
    remaining = len(digits)
    answer = submax(0, 1, remaining)
    left, right = 1, 1
    for digit in digits:
        remaining -= 1
        if digit == '1':
            answer = max(answer, submax(left, left + right, remaining))
            left, right = left + right, right
        else:
            left, right = left, left + right
    return max(answer, left)


def write(name, limit):
    input_text = f"{limit}\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(f"{oracle(limit)}\n")


fib = [0, 1]
for _ in range(60):
    fib.append(fib[-1] + fib[-2])

assert oracle(10) == 4
assert oracle(15) == 5
assert oracle(0) == 0
for exponent in range(1, 12):
    assert oracle(2 ** exponent - 1) == fib[exponent + 1]
for value in range(0, 5000):
    assert oracle(value) == brute(value), value

write("1_sample", 10)
write("2_edges", 0)
write("3_wide", 10 ** 15)
write("4_random", random.Random(2026).randrange(1, 10 ** 15))
write("5_io", 10 ** 15 - 1)
