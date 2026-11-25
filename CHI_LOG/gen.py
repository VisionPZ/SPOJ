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
    answers = []
    for index in range(count):
        answers.append(significant(Decimal(tokens[index + 1]).ln()))
    return "\n".join(answers) + "\n"

SAMPLE_INPUTS = ["1", "3.1415926535897932384626433832"]
SAMPLE_OUT = """0
1144729885849400174143427351327752157627210731401746036785205942589070827177558730931032351538638113
"""
assert oracle("2\n" + "\n".join(SAMPLE_INPUTS) + "\n") == SAMPLE_OUT
assert significant(Decimal(10).ln()) == "23025850929940456840179914546843642076011014886287729760333279009675726096773524802359972050895982983"
assert significant(Decimal(100).ln()).startswith("46051701859880913680359829093")
assert significant(Decimal(2).ln()).startswith("69314718055994530941723212145")

def decimal_text(integer_part, fraction_digits):
    return str(integer_part) + "." + fraction_digits


def build():
    tiny = "1." + "0" * 100 + "1"
    write("2_edges", ["1", "100", tiny, "3.1415926535897932384626433832",
                      "99.99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999",
                      "1.00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001"])
    long_fraction = "9876543210" * 10 + "98765432101"
    write("3_wide", [decimal_text(100, long_fraction[:101]),
                     decimal_text(2, "3" * 101), decimal_text(1, "0" * 100 + "1"),
                     decimal_text(99, "9" * 101)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(40):
        integer_part = rng.randint(1, 100)
        fraction = "".join(str(rng.randint(0, 9)) for _ in range(rng.randint(1, 101)))
        random_cases.append(decimal_text(integer_part, fraction))
    write("4_random", random_cases)
    io_cases = [decimal_text(rng.randint(1, 100), "".join(str(rng.randint(0, 9)) for _ in range(101)))
                for _ in range(110)]
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
