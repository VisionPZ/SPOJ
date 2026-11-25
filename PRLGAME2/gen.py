#!/usr/bin/env python3
import math
import random
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_case(ball_count, drawn_count, red_count):
    weight_total = Fraction(0)
    red_total = Fraction(0)
    for actual_red in range(red_count, ball_count - drawn_count + red_count + 1):
        weight = Fraction(math.comb(actual_red, red_count) *
                          math.comb(ball_count - actual_red,
                                    drawn_count - red_count))
        weight_total += weight
        red_total += weight * Fraction(actual_red - red_count,
                                       ball_count - drawn_count)
    return red_total / weight_total


def format_probability(value):
    scaled = (2 * value.numerator * 10000 + value.denominator) // (2 * value.denominator)
    whole, fraction = divmod(scaled, 10000)
    return f"{whole}.{fraction:04d}"


def oracle(cases):
    return "\n".join(
        f"Case {index + 1}: {format_probability(oracle_case(*case))}"
        for index, case in enumerate(cases)) + "\n"


SAMPLE_CASES = [(3, 0, 0), (4, 2, 1)]
SAMPLE = "3 0 0\n4 2 1\n"
SAMPLE_OUT = "Case 1: 0.5000\nCase 2: 0.5000\n"
assert oracle(SAMPLE_CASES) == SAMPLE_OUT
assert format_probability(oracle_case(10, 3, 1)) == "0.4000"
assert format_probability(oracle_case(5, 1, 0)) == "0.3333"
assert format_probability(oracle_case(6, 5, 5)) == "0.8571"
for balls in range(2, 9):
    for drawn in range(0, balls):
        for red in range(0, drawn + 1):
            assert oracle_case(balls, drawn, red) == Fraction(red + 1, drawn + 2)


def write(name, cases):
    text = "".join(f"{balls} {drawn} {red}\n" for balls, drawn, red in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(cases))


def build():
    write("2_edges", [(2, 0, 0), (2, 1, 0), (2, 1, 1), (30, 29, 28),
                      (30, 29, 0), (100, 1, 1)])
    rng = random.Random(20261126)

    def random_case(maximum):
        balls = rng.randint(2, maximum)
        drawn = rng.randint(0, balls - 1)
        return balls, drawn, rng.randint(0, drawn)

    write("3_wide", [random_case(300) for _ in range(200)])
    write("4_random", [random_case(200) for _ in range(400)])
    write("5_io", [random_case(12) for _ in range(20000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_CASES)
build()
