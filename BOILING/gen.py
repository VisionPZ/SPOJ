#!/usr/bin/env python3
import random
from fractions import Fraction
from itertools import product
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_value(threshold_hundredths, weights):
    piece_total = len(weights)
    for cuts in range(0, 61):
        wanted = piece_total + cuts
        for counts in product(range(1, cuts + 2), repeat=piece_total):
            if sum(counts) != wanted:
                continue
            pieces = [Fraction(weight, count) for weight, count in zip(weights, counts)]
            if min(pieces) * 100 > threshold_hundredths * max(pieces):
                return cuts
    raise ValueError("no answer under 60 cuts")


def parse_threshold(token):
    whole, _, fraction = token.partition(".")
    fraction = (fraction + "00")[:2]
    return int(whole) * 100 + int(fraction)


def oracle(text):
    tokens = text.split()
    threshold = parse_threshold(tokens[0])
    count = int(tokens[1])
    weights = [int(value) for value in tokens[2:2 + count]]
    return str(oracle_value(threshold, weights)) + "\n"


SAMPLE = """0.99 3
2000 3000 4000
"""
SAMPLE_OUT = """6
"""
SAMPLE_TWO = """0.80 2
1000 1400
"""
SAMPLE_TWO_OUT = """3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle(SAMPLE_TWO) == SAMPLE_TWO_OUT
assert oracle("0.99 1\n1000\n") == "0\n"
assert oracle("0.99 2\n1000 1000\n") == "0\n"
assert oracle("0.51 2\n1000 1000\n") == "0\n"
assert parse_threshold("0.99") == 99
assert parse_threshold("0.8") == 80


def write_case(name, threshold, weights, expected=None):
    text = "%s %d\n" % (threshold, len(weights)) + " ".join(str(value) for value in weights) + "\n"
    (ROOT / "in" / (name + ".txt")).write_text(text)
    answer = expected + "\n" if expected is not None else oracle(text)
    (ROOT / "out" / (name + ".out")).write_text(answer)


def build():
    write_case("2_edges", "0.80", [1000, 1400], "3")
    write_case("3_wide", "0.70", [5, 6, 7, 8])
    rng = random.Random(20261126)
    pool = [[2, 3, 4], [3, 4, 5], [4, 5, 6], [2, 5, 7]]
    write_case("4_random", "0.%02d" % rng.randint(55, 70), rng.choice(pool))
    write_case("5_io", "0.99", [1000000] * 1000, "0")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
