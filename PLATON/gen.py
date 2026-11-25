#!/usr/bin/env python3
from collections import defaultdict
from itertools import combinations
from math import isqrt
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parent


def factor_pairs(product, low, high):
    pairs = []
    for divisor in range(low, isqrt(product) + 1):
        if product % divisor == 0:
            partner = product // divisor
            if divisor < partner <= high:
                pairs.append((divisor, partner))
    return pairs


def divisor_oracle(low, high):
    splits = defaultdict(list)
    for left, right in combinations(range(low, high + 1), 2):
        splits[left + right].append((left, right))
    representation_cache = {}

    def representations(product):
        if product not in representation_cache:
            representation_cache[product] = factor_pairs(product, low, high)
        return representation_cache[product]

    good_sums = {
        total for total, choices in splits.items()
        if len(choices) > 1
        and all(len(representations(left * right)) > 1 for left, right in choices)
    }
    winners = []
    for total in sorted(good_sums):
        choices = [
            (left, right) for left, right in splits[total]
            if sum(1 for factor_left, factor_right in representations(left * right)
                   if factor_left + factor_right in good_sums) == 1
        ]
        if len(choices) == 1:
            winners.append(choices[0])
    return winners


def oracle_case(low, high):
    triples = []
    for left in range(low, high + 1):
        for right in range(left + 1, high + 1):
            triples.append((left * right, left + right, left, right))
    triples.sort(key=lambda triple: triple[0])
    product_counts = {}
    start = 0
    while start < len(triples):
        product = triples[start][0]
        stop = start + 1
        while stop < len(triples) and triples[stop][0] == product:
            stop += 1
        product_counts[product] = stop - start
        start = stop

    splits_by_sum = defaultdict(list)
    for product, total, left, right in triples:
        splits_by_sum[total].append((product, left, right))
    good_sums = {
        total for total, choices in splits_by_sum.items()
        if len(choices) > 1 and all(product_counts[product] > 1 for product, _, _ in choices)
    }
    good_triples = [triple for triple in triples if triple[1] in good_sums]
    good_triples.sort(key=lambda triple: triple[0])
    good_product_counts = {}
    start = 0
    while start < len(good_triples):
        product = good_triples[start][0]
        stop = start + 1
        while stop < len(good_triples) and good_triples[stop][0] == product:
            stop += 1
        good_product_counts[product] = stop - start
        start = stop

    winner_count = defaultdict(int)
    winner_pair = {}
    for product, total, left, right in good_triples:
        if good_product_counts[product] == 1:
            winner_count[total] += 1
            winner_pair[total] = (left, right)
    return [winner_pair[total] for total in sorted(winner_count) if winner_count[total] == 1]


def render(cases):
    blocks = []
    for case_index, (low, high) in enumerate(cases, 1):
        pairs = oracle_case(low, high)
        blocks.append(f"case {case_index}\n{len(pairs)}\n")
        for left, right in pairs:
            blocks.append(f"{left} {right}\n")
    return "".join(blocks)


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(f"{low} {high}\n" for low, high in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(render(cases))


assert oracle_case(1, 10) == []
assert oracle_case(2, 8) == []
assert oracle_case(2, 100) == [(4, 13)]
assert oracle_case(1, 30) == [(1, 6)]
for check_low in range(1, 8):
    for check_high in range(check_low + 1, 21):
        assert oracle_case(check_low, check_high) == divisor_oracle(check_low, check_high)

SAMPLE = [(1, 10), (2, 8)]
EDGES = [
    (1, 2), (2, 3), (1, 10), (2, 8), (1, 14), (2, 15), (1, 26),
    (1, 30), (2, 77), (1, 101), (4999, 5000), (4800, 4999),
]
WIDE = [(1, 200), (2, 201), (3, 202), (4, 203), (4800, 4999), (4801, 5000)]

random.seed(20261125)
RANDOM = []
for _ in range(200):
    low = random.randint(1, 4999)
    high = min(5000, low + random.randint(1, 199))
    RANDOM.append((low, high))

IO = []
for _ in range(2000):
    low = random.randint(1, 4801)
    IO.append((low, low + 199))

(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
write("2_edges", EDGES)
write("3_wide", WIDE)
write("4_random", RANDOM)
write("5_io", IO)
