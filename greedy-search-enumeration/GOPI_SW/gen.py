#!/usr/bin/env python3
import math
import random
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007


def build_prefix(limit):
    prefix = [0] * (limit + 1)
    prefix[1] = 2
    running_product = 2
    for index in range(2, limit + 1):
        next_term = running_product + 1
        running_product = (running_product * (next_term % MOD)) % MOD
        prefix[index] = running_product
    return prefix


def max_denominator_by_search(part_count, bound):
    best = [0]

    def search(remaining, slots, smallest, chosen):
        if remaining <= 0:
            return
        if slots == 1:
            if remaining.numerator == 1:
                denominator = remaining.denominator
                if smallest <= denominator <= bound:
                    best[0] = max(best[0], max(chosen + [denominator]))
            return
        low = max(smallest, math.ceil(Fraction(1, 1) / remaining))
        high = min(math.floor(Fraction(slots, 1) / remaining), bound)
        for denominator in range(low, high + 1):
            search(remaining - Fraction(1, denominator), slots - 1,
                   denominator, chosen + [denominator])

    search(Fraction(1, 1), part_count, 2, [])
    return best[0]


SAMPLE = """1
3
"""
SAMPLE_OUT = """6
"""
assert max_denominator_by_search(2, 200) == 2
assert max_denominator_by_search(3, 200) == 6
assert max_denominator_by_search(4, 5000) == 42
assert build_prefix(6)[1] == 2
assert build_prefix(6)[2] == 6
assert build_prefix(6)[3] == 42
assert build_prefix(6)[4] == 1806
assert build_prefix(6)[5] == 3263442
assert SAMPLE_OUT == "6\n"


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    queries = tokens[1:1 + case_count]
    prefix = build_prefix(max(queries))
    return "".join(str(prefix[query - 1]) + "\n" for query in queries)


assert oracle(SAMPLE) == SAMPLE_OUT


def write(name, queries):
    input_text = str(len(queries)) + "\n" + "".join(
        f"{query}\n" for query in queries)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [2, 2, 3, 4, 5, 1000000])
    rng = random.Random(20261126)
    write("3_wide", [rng.randint(2, 1000000) for _ in range(200)])
    write("4_random", [rng.randint(2, 1000000) for _ in range(1000)])
    write("5_io", [rng.randint(2, 1000000) for _ in range(100000)])
    big = [rng.randint(2, 1000000) for _ in range(100000)]
    Path("/tmp/GOPI_SW_big.txt").write_text(
        str(len(big)) + "\n" + "".join(f"{query}\n" for query in big))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [3])
build()
