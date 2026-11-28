#!/usr/bin/env python3
import random
from decimal import Decimal, getcontext, localcontext
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PRECISION = 380
getcontext().prec = PRECISION


PI_CACHE = None


def pi_value():
    global PI_CACHE
    if PI_CACHE is None:
        with localcontext() as ctx:
            ctx.prec = PRECISION + 40
            first = Decimal(1)
            second = Decimal(1) / Decimal(2).sqrt()
            term = Decimal(1) / 4
            factor = Decimal(1)
            for _ in range(12):
                average = (first + second) / 2
                second = (first * second).sqrt()
                term = term - factor * (first - average) ** 2
                first = average
                factor = factor * 2
            PI_CACHE = +((first + second) ** 2 / (4 * term))
    return PI_CACHE


def significant(value):
    if value == 0:
        return "0"
    positive = abs(value)
    exponent = positive.adjusted()
    scaled = int(positive.scaleb(100 - exponent))
    return str(scaled).rstrip("0")

def arctan_series(value):
    squared = value * value
    power = value
    total = value
    for index in range(1, 500):
        power = power * squared
        term = power / (2 * index + 1)
        if term == 0:
            break
        total = total + term if index % 2 == 0 else total - term
    return total


def arctan_value(value):
    if value > 1:
        return pi_value() / 2 - arctan_value(1 / value)
    halvings = 0
    reduced = value
    while reduced > Decimal("0.04"):
        reduced = reduced / (1 + (1 + reduced * reduced).sqrt())
        halvings = halvings + 1
    total = arctan_series(reduced)
    for _ in range(halvings):
        total = total * 2
    return total


def oracle(text):
    tokens = text.split()
    count = int(tokens[0])
    answers = []
    for index in range(count):
        answers.append(significant(arctan_value(Decimal(tokens[index + 1]))))
    return "\n".join(answers) + "\n"

SAMPLE_INPUTS = ["0", "1", "2.718281828459045235360287"]
SAMPLE_OUT = """0
78539816339744830961566084581987572104929234984377645524373614807695410157155224965700870633552926699
12182829050172776217604617127291832691014807688333489455796019635447595534415986839011077205055833227
"""
assert oracle("3\n" + "\n".join(SAMPLE_INPUTS) + "\n") == SAMPLE_OUT
assert significant(arctan_value(Decimal(1))) == "78539816339744830961566084581987572104929234984377645524373614807695410157155224965700870633552926699"
assert significant(arctan_value(Decimal(10))) == "14711276743037345918528755717617308518553063771832382624719635193438804556955538448934047882367721624"
assert significant(arctan_value(Decimal(0))) == "0"

def decimal_text(integer_part, fraction_digits):
    return str(integer_part) + "." + fraction_digits


def build():
    write("2_edges", ["0", "0." + "0" * 100 + "1", "1", "10", "2.718281828459045235360287",
                      "3.1415926535897932384626433832", "0.5", "9.99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999"])
    write("3_wide", [decimal_text(10, "0" * 101), decimal_text(9, "9" * 101),
                     decimal_text(0, "1" * 101), decimal_text(5, "1234567890" * 10 + "12345678901")[:103]])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(40):
        integer_part = rng.randint(0, 10)
        fraction = "".join(str(rng.randint(0, 9)) for _ in range(rng.randint(1, 101)))
        random_cases.append(decimal_text(integer_part, fraction))
    write("4_random", random_cases)
    io_cases = [decimal_text(rng.randint(0, 10), "".join(str(rng.randint(0, 9)) for _ in range(101)))
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
