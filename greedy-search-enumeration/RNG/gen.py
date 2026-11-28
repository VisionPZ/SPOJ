#!/usr/bin/env python3
import random
from bisect import bisect_right
from fractions import Fraction
from math import comb
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def poly_add(first, second):
    size = max(len(first), len(second))
    return [(first[i] if i < len(first) else Fraction(0)) +
            (second[i] if i < len(second) else Fraction(0)) for i in range(size)]


def poly_scale(poly, factor):
    return [factor * value for value in poly]


def poly_eval(poly, point):
    total = Fraction(0)
    for value in reversed(poly):
        total = total * point + value
    return total


def linear_power(shift, degree):
    return [Fraction(comb(degree, index) * (-shift) ** (degree - index))
            for index in range(degree + 1)]


def to_shifted(poly, base):
    shifted = [Fraction(0)] * len(poly)
    for degree, coefficient in enumerate(poly):
        for index in range(degree + 1):
            shifted[index] += coefficient * comb(degree, index) * Fraction(base ** (degree - index))
    return shifted


def antiderivative(breaks, polys, constants, position, shift):
    if position <= breaks[0]:
        return [Fraction(0)]
    if position >= breaks[-1]:
        return [Fraction(constants[-1] - breaks[-1] - shift), Fraction(1)]
    index = bisect_right(breaks, position) - 1
    current = [constants[index]]
    for degree, coefficient in enumerate(polys[index]):
        current = poly_add(current, poly_scale(linear_power(breaks[index] + shift, degree + 1),
                                               coefficient / (degree + 1)))
    return current


def convolve(breaks, polys, width):
    constants = [Fraction(0)]
    for index, poly in enumerate(polys):
        span = breaks[index + 1] - breaks[index]
        value = sum(coefficient * Fraction(span ** (degree + 1), degree + 1)
                    for degree, coefficient in enumerate(poly))
        constants.append(constants[-1] + value)
    new_breaks = sorted(set(breaks + [point + width for point in breaks]))
    new_polys = []
    for index in range(len(new_breaks) - 1):
        midpoint = Fraction(new_breaks[index] + new_breaks[index + 1], 2)
        direct = antiderivative(breaks, polys, constants, midpoint, 0)
        shifted = antiderivative(breaks, polys, constants, midpoint - width, width)
        difference = poly_add(direct, poly_scale(shifted, Fraction(-1)))
        global_poly = poly_scale(difference, Fraction(1, width))
        new_polys.append(to_shifted(global_poly, new_breaks[index]))
    return new_breaks, new_polys


def distribution_cdf(widths, point):
    breaks = [0]
    polys = []
    for width in widths:
        breaks, polys = convolve(breaks, polys, width)
    if point <= breaks[0]:
        return Fraction(0)
    if point >= breaks[-1]:
        return Fraction(1)
    index = bisect_right(breaks, point) - 1
    return poly_eval(polys[index], Fraction(point - breaks[index]))


def format_probability(fraction):
    scaled = fraction * 10 ** 9
    quotient = scaled.numerator // scaled.denominator
    remainder = scaled.numerator - quotient * scaled.denominator
    if 2 * remainder >= scaled.denominator:
        quotient += 1
    return f"{quotient // 10 ** 9}.{quotient % 10 ** 9:09d}"


def solve(lower, upper, widths):
    half_span = sum(widths) // 2
    result = distribution_cdf(widths, upper + half_span) - distribution_cdf(widths, lower + half_span)
    return format_probability(result)


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _case in range(case_count):
        factor_count = int(tokens[cursor])
        lower = int(tokens[cursor + 1])
        upper = int(tokens[cursor + 2])
        cursor += 3
        widths = [2 * int(tokens[cursor + index]) for index in range(factor_count)]
        cursor += factor_count
        answers.append(solve(lower, upper, widths))
    if not answers:
        return ""
    return "\n".join(answers) + "\n"


SAMPLE_IN = """5
1 -100 100
10
1 10 90
10
1 -20 5
10
2 -20 5
5 5
5 -5 10
1 2 3 4 5
"""
SAMPLE_OUT = """1.000000000
0.000000000
0.750000000
0.875000000
0.864720052
"""
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert solve(-100, 100, [20]) == "1.000000000"
assert solve(10, 90, [20]) == "0.000000000"
assert solve(-20, 5, [20]) == "0.750000000"
assert solve(-20, 5, [10, 10]) == "0.875000000"
assert solve(-5, 10, [2, 4, 6, 8, 10]) == "0.864720052"


def case_text(lower, upper, values):
    return f"{len(values)} {lower} {upper}\n" + " ".join(str(value) for value in values) + "\n"


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(case_text(*case) for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [(-100, 100, [1]), (0, 0, [1]), (-100, -50, [3]),
                      (100, 100, [10]), (-30, 30, [1, 1, 1])])
    write("3_wide", [(-100, 100, [10] * 6), (-100, 100, [1, 2, 3, 4, 5, 6]),
                     (-20, 20, [10, 10, 10, 10, 10, 10])])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(-100, 0), rng.randint(0, 100),
                        [rng.randint(1, 10) for _ in range(rng.randint(1, 6))])
                       for _ in range(120)])
    write("5_io", [(rng.randint(-100, 0), rng.randint(0, 100),
                    [rng.randint(1, 10) for _ in range(rng.randint(1, 3))])
                   for _ in range(20000)])
    big_cases = ["1000\n"]
    for index in range(1000):
        big_cases.append(f"10 {rng.randint(-100, 0)} {rng.randint(0, 100)}\n")
        big_cases.append(" ".join(["10"] * 10) + "\n")
    (Path("/tmp") / "RNG_big.txt").write_text("".join(big_cases))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(-100, 100, [10]), (10, 90, [10]), (-20, 5, [10]),
                   (-20, 5, [5, 5]), (-5, 10, [1, 2, 3, 4, 5])])
build()
