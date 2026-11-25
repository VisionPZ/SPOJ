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

def sine_value(value):
    circle = pi_value()
    reduced = value
    if reduced > circle / 2:
        reduced = circle - reduced
    use_cosine = False
    if reduced > circle / 4:
        reduced = circle / 2 - reduced
        use_cosine = True
    squared = reduced * reduced
    if use_cosine:
        term = Decimal(1)
        total = Decimal(1)
        for index in range(1, 400):
            term = term * squared / ((2 * index - 1) * (2 * index))
            if term == 0:
                break
            total = total + term if index % 2 == 0 else total - term
        return total
    term = reduced
    total = reduced
    for index in range(1, 400):
        term = term * squared / ((2 * index) * (2 * index + 1))
        if term == 0:
            break
        total = total + term if index % 2 == 0 else total - term
    return total


def oracle(text):
    tokens = text.split()
    count = int(tokens[0])
    answers = []
    for index in range(count):
        answers.append(significant(sine_value(Decimal(tokens[index + 1]))))
    return "\n".join(answers) + "\n"

SAMPLE_INPUTS = ["0", "1.5707963267948966"]
SAMPLE_OUT = """0
99999999999999999999999999999999981507813299633318447401631655066443910339246693874482714867916134939
"""
assert oracle("2\n" + "\n".join(SAMPLE_INPUTS) + "\n") == SAMPLE_OUT
assert significant(sine_value(Decimal(1))) == "84147098480789650665250232163029899962256306079837106567275170999191040439123966894863974354305269585"
assert significant(sine_value(pi_value() / 2)) == "1"
assert significant(sine_value(Decimal(0))) == "0"

PI_TEXT = "3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679"


def build():
    write("2_edges", ["0", "0." + "0" * 100 + "1", "1", "0.785398163397448309615660845819875721",
                      "1.5707963267948966", PI_TEXT, "3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679"])
    write("3_wide", [PI_TEXT, "3.141592653589793238462643383279502884197169399375105820974944592307816406286208998628034825342117067",
                     "1." + "2" * 100, "0." + "5" * 101, "3.14159265358979323846264338327950288"])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(40):
        integer_part = rng.randint(0, 3)
        fraction = "".join(str(rng.randint(0, 9)) for _ in range(rng.randint(1, 101)))
        token = str(integer_part) + "." + fraction
        if Decimal(token) >= pi_value():
            token = "3." + "141592653589793238462643383279502884197169399375105820974944592307816406286208998628034825342117067"
        random_cases.append(token)
    write("4_random", random_cases)
    io_cases = []
    for _ in range(110):
        integer_part = rng.randint(0, 3)
        fraction = "".join(str(rng.randint(0, 9)) for _ in range(101))
        token = str(integer_part) + "." + fraction
        if Decimal(token) >= pi_value():
            token = "3.141592653589793238462643383279502884197169399375105820974944592307816406286208998628034825342117067"
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
