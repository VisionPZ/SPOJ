#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007
MAX_NUMBERS = 100
MAX_SWAPS = 10000


def build_table():
    coefficients = [1]
    table = [[0] * (MAX_SWAPS + 1) for _ in range(MAX_NUMBERS + 1)]
    table[0][0] = 1
    for count in range(1, MAX_NUMBERS + 1):
        updated = [0] * min(len(coefficients) + count - 1, MAX_SWAPS + 1)
        updated[0] = 1
        for degree in range(1, len(updated)):
            total = 0
            low = max(0, degree - count + 1)
            high = min(degree, len(coefficients) - 1)
            for source in range(low, high + 1):
                total += coefficients[source]
                if total >= MOD:
                    total -= MOD
            updated[degree] = total % MOD
        coefficients = updated
        for degree in range(min(len(coefficients), MAX_SWAPS + 1)):
            table[count][degree] = coefficients[degree]
    return table


TABLE = build_table()


def brute_count(numbers, swaps):
    found = 0
    for order in itertools.permutations(range(numbers)):
        inversions = sum(1 for left in range(numbers)
                         for right in range(left + 1, numbers)
                         if order[left] > order[right])
        if inversions == swaps:
            found += 1
    return found


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    lines = []
    for case_index in range(1, case_count + 1):
        numbers = tokens[cursor]
        swaps = tokens[cursor + 1]
        cursor += 2
        answer = TABLE[numbers][swaps] if swaps <= MAX_SWAPS else 0
        lines.append(f"Case {case_index}: {answer}")
    return "\n".join(lines) + "\n"


SAMPLE = """3
3 1
10 45
100 56
"""
SAMPLE_OUT = """Case 1: 2
Case 2: 1
Case 3: 904490303
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert TABLE[0][0] == 1
assert TABLE[1][1] == 0
assert TABLE[3][1] == 2
assert TABLE[10][45] == 1
assert TABLE[100][56] == 904490303
assert TABLE[100][5000] == 0
for numbers in range(1, 7):
    for swaps in range(numbers * (numbers - 1) // 2 + 1):
        assert TABLE[numbers][swaps] == brute_count(numbers, swaps)


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(
        f"{numbers} {swaps}\n" for numbers, swaps in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 0), (1, 1), (2, 0), (2, 1), (100, 0),
                      (100, 4950), (100, 4951), (100, 10000)])
    rng = random.Random(20261126)
    write("3_wide", [(100, rng.randint(0, 4950)) for _ in range(2000)])
    write("4_random", [(rng.randint(1, 100), rng.randint(0, 10000))
                       for _ in range(10000)])
    write("5_io", [(rng.randint(1, 100), rng.randint(0, 10000))
                   for _ in range(199999)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
