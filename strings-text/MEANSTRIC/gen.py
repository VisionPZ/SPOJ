#!/usr/bin/env python3
import random
from decimal import Decimal, getcontext, ROUND_HALF_EVEN
from pathlib import Path

ROOT = Path(__file__).resolve().parent
getcontext().prec = 40

SAMPLE_INPUT = """3
5
4 36 45 50 75
6
1.0 2.0 4.0 7.0 14.0 28.0
8
1.0 2.0 3.0 4.0 9.0 12.0 18.0 36.0
"""
SAMPLE_OUT = """42.000000000 30.000000000 15.000000000
9.333333333 5.291502622 3.000000000
10.625000000 6.000000000 3.388235294
"""

NINE_PLACES = Decimal("0.000000001")


def fixed(value):
    return str(value.quantize(NINE_PLACES, rounding=ROUND_HALF_EVEN))


def oracle(input_text):
    tokens = input_text.split()
    case_count = int(tokens[0])
    scan_pos = 1
    lines = []
    for _ in range(case_count):
        number_count = int(tokens[scan_pos])
        scan_pos += 1
        values = [Decimal(tokens[scan_pos + i]) for i in range(number_count)]
        scan_pos += number_count
        total = Decimal(0)
        log_sum = Decimal(0)
        reciprocal_sum = Decimal(0)
        for value in values:
            total += value
            log_sum += value.ln()
            reciprocal_sum += Decimal(1) / value
        count = Decimal(number_count)
        arithmetic = total / count
        geometric = (log_sum / count).exp()
        harmonic = count / reciprocal_sum
        lines.append("%s %s %s" % (fixed(arithmetic), fixed(geometric), fixed(harmonic)))
    return "\n".join(lines) + "\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1\n1\n7\n") == "7.000000000 7.000000000 7.000000000\n"
assert oracle("1\n2\n1 4\n") == "2.500000000 2.000000000 1.600000000\n"


def write(name, cases):
    parts = [str(len(cases))]
    for values in cases:
        parts.append(str(len(values)))
        parts.append(" ".join(values))
    input_text = "\n".join(parts) + "\n"
    (ROOT / "in" / ("%s.txt" % name)).write_text(input_text)
    (ROOT / "out" / ("%s.out" % name)).write_text(oracle(input_text))


SAMPLE_CASES = [
    ["4", "36", "45", "50", "75"],
    ["1.0", "2.0", "4.0", "7.0", "14.0", "28.0"],
    ["1.0", "2.0", "3.0", "4.0", "9.0", "12.0", "18.0", "36.0"],
]


def build():
    write("2_edges", [
        ["7"], ["1", "4"], ["0.001"], ["1000000000"],
        ["1", "1"], ["0.5", "2"], ["1e-6"], ["999999999", "999999999"],
    ])
    wide_case = ["%.10f" % (10 ** (rng_exp / 10.0)) for rng_exp in range(-60, 61)]
    write("3_wide", [wide_case, ["2"] * 100, ["0.25"] * 50])
    rng = random.Random(20190108)
    random_cases = []
    for _ in range(200):
        size = rng.randint(1, 100)
        values = ["%.6f" % rng.uniform(0.0001, 1000000) for _ in range(size)]
        random_cases.append(values)
    write("4_random", random_cases)
    io_cases = []
    for _ in range(2000):
        values = ["%.6f" % rng.uniform(0.0001, 1000000) for _ in range(100)]
        io_cases.append(values)
    write("5_io", io_cases)


if __name__ == "__main__":
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", SAMPLE_CASES)
    build()
