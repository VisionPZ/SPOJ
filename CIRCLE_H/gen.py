#!/usr/bin/env python3
import random
from decimal import Decimal, getcontext
from pathlib import Path

ROOT = Path(__file__).resolve().parent
getcontext().prec = 220
SCALE = Decimal(10) ** 50


def oracle_case(radius_one, radius_two, radius_three):
    first = Decimal(radius_one)
    second = Decimal(radius_two)
    third = Decimal(radius_three)
    product = first * second * third
    pairwise = first * second + second * third + third * first
    total = first + second + third
    denominator = pairwise + 2 * (product * total).sqrt()
    value = product / denominator
    digits = str(int(value * SCALE)).rjust(51, '0')
    return digits[:-50] + '.' + digits[-50:]


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    answers = []
    position = 1
    for _ in range(case_count):
        answers.append(oracle_case(tokens[position], tokens[position + 1], tokens[position + 2]))
        position += 3
    return "\n".join(answers) + "\n"


SAMPLE = """3
1 1 1
10 10 10
23 46 69
"""
SAMPLE_OUT = """0.15470053837925152901829756100391491129520350254025
1.54700538379251529018297561003914911295203502540253
6.00000000000000000000000000000000000000000000000000
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 2 2\n") == "0.30940107675850305803659512200782982259040700508050\n"
assert oracle("1\n10 10 10\n") == "1.54700538379251529018297561003914911295203502540253\n"
assert oracle("1\n23 46 69\n") == "6.00000000000000000000000000000000000000000000000000\n"
assert oracle("1\n1000000000000000000000000000000 1000000000000000000000000000000 1000000000000000000000000000000\n") == "154700538379251529018297561003.91491129520350254025375203720465296795534460586669\n"


def write(name, cases):
    lines = [str(len(cases))]
    for radii in cases:
        lines.append(" ".join(str(value) for value in radii))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    huge = 10 ** 30 - 1
    write("2_edges", [(1, 1, 1), (1, 2, 3), (huge, huge, huge), (1, huge, huge), (2, 3, 5)])
    write("3_wide", [(huge, huge - 1, huge - 2), (10 ** 29, 10 ** 20, 10 ** 10),
                     (1, 10 ** 30 - 1, 10 ** 30 - 2), (999999999999999999999999999999, 1, 1)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(20):
        digits = rng.randint(1, 30)
        random_cases.append(tuple(rng.randint(1, 10 ** digits - 1) for _ in range(3)))
    write("4_random", random_cases)
    output_cases = []
    for case_index in range(50):
        base = 10 ** 30 - 1 - case_index * 10 ** 20
        output_cases.append((base, base - 1, base - 2))
    write("5_io", output_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(1, 1, 1), (10, 10, 10), (23, 46, 69)])
build()
