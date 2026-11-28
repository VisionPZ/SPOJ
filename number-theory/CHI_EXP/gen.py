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
        answers.append(significant(Decimal(tokens[index + 1]).exp()))
    return "\n".join(answers) + "\n"

SAMPLE_INPUTS = ["0", "1", "-3.14159265358979323846264338327950288"]
SAMPLE_OUT = """1
27182818284590452353602874713526624977572470936999595749669676277240766303535475945713821785251664274
43213918263772249774417737171728011457104245174434972327166908869626900798351779694542372009588635587
"""
assert oracle("3\n" + "\n".join(SAMPLE_INPUTS) + "\n") == SAMPLE_OUT
assert significant(Decimal(1).exp()) == "27182818284590452353602874713526624977572470936999595749669676277240766303535475945713821785251664274"
assert significant(Decimal(10).exp()).startswith("22026465794806716516957900645")
assert significant(Decimal(-100).exp()).startswith("37200759760208359629596958038")

def decimal_text(integer_part, fraction_digits):
    return str(integer_part) + "." + fraction_digits


def build():
    long_fraction = "1234567890" * 10 + "12345678901"
    write("2_edges", ["0", "1", "-1", "100", "-100",
                      "0." + "0" * 100 + "1", "-0." + "0" * 100 + "1",
                      "99.99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999"])
    write("3_wide", [decimal_text(100, long_fraction[:101]),
                     "-" + decimal_text(100, long_fraction[:101]),
                     decimal_text(0, "9" * 101), "-" + decimal_text(0, "9" * 101),
                     decimal_text(50, "5" * 101), "-" + decimal_text(50, "5" * 101)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(40):
        integer_part = rng.randint(0, 100)
        fraction = "".join(str(rng.randint(0, 9)) for _ in range(rng.randint(1, 101)))
        token = decimal_text(integer_part, fraction)
        if rng.random() < 0.5:
            token = "-" + token
        random_cases.append(token)
    write("4_random", random_cases)
    io_cases = []
    for _ in range(110):
        integer_part = rng.randint(0, 100)
        fraction = "".join(str(rng.randint(0, 9)) for _ in range(101))
        token = decimal_text(integer_part, fraction)
        if rng.random() < 0.5:
            token = "-" + token
        io_cases.append(token)
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
