#!/usr/bin/env python3
import random
from decimal import Decimal, getcontext, localcontext
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PRECISION = 380
getcontext().prec = PRECISION



def significant(value):
    if value == 0:
        return "0"
    positive = abs(value)
    exponent = positive.adjusted()
    scaled = int(positive.scaleb(100 - exponent))
    return str(scaled).rstrip("0")

def oracle(text):
    tokens = text.split()
    count = int(tokens[0])
    cursor = 1
    answers = []
    for _ in range(count):
        degree = int(tokens[cursor]); cursor += 1
        argument = Decimal(tokens[cursor]); cursor += 1
        root = argument ** (Decimal(1) / Decimal(degree)) if argument > 0 else Decimal(0)
        nearest = int(root.to_integral_value())
        if nearest > 0 and Decimal(nearest) ** degree == argument:
            root = Decimal(nearest)
        answers.append(significant(root))
    return "\n".join(answers) + "\n"

SAMPLE_INPUTS = ["3 2", "4 16", "2 5", "2 3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679"]
SAMPLE_OUT = """12599210498948731647672106072782283505702514647015079800819751121552996765139594837293965624362550941
2
22360679774997896964091736687312762354406183596115257242708972454105209256378048994144144083787822749
17724538509055160272981674833411451827975494561223871282138077898529112845910321813749506567385446653
"""
assert oracle("4\n" + "\n".join(SAMPLE_INPUTS) + "\n") == SAMPLE_OUT
assert oracle("2\n4 16\n3 27\n") == "2\n3\n"
assert significant(Decimal(2) ** (Decimal(1) / Decimal(2))).startswith("14142135623730950488016887242")

def decimal_text(integer_part, fraction_digits):
    return str(integer_part) + "." + fraction_digits


def build():
    write("2_edges", ["1 0", "2 1", "3 27", "4 16", "2 0.25", "2000000000 1.00000000000000000000000000000000000001",
                      "100 12345678901234567890", "2 2", "7 823543"])
    write("3_wide", ["2 3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679",
                     "100 12345678901234567890", "2147483647 1.000000000000000000000000000000000000000000000000001",
                     "3 " + decimal_text(100, "1234567890" * 10 + "12345678901")[:103]])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(20):
        degree = rng.choice([1, 2, 3, 4, 5, 10, 100, 1000, rng.randint(1, 100000)])
        integer_part = rng.randint(0, 1000)
        fraction = "".join(str(rng.randint(0, 9)) for _ in range(rng.randint(1, 101)))
        random_cases.append((degree, decimal_text(integer_part, fraction)))
    write("4_random", random_cases)
    io_cases = []
    for index in range(45):
        degree = rng.choice([2, 3, 5, 10, 50, 100, 1000, rng.randint(1, 1000000)])
        integer_part = rng.randint(0, 1000)
        fraction = "".join(str(rng.randint(0, 9)) for _ in range(101))
        io_cases.append((degree, decimal_text(integer_part, fraction)))
    write("5_io", io_cases)


def write(name, arguments):
    body = [str(len(arguments))]
    for item in arguments:
        body.append(item if isinstance(item, str) else " ".join(str(part) for part in item))
    text = "\n".join(body) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_INPUTS)
build()
