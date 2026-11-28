#!/usr/bin/env python3
import random
import sys
from decimal import Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "8.549e2\n"
SAMPLE_OUTPUT = "854.9\n"


def oracle(text):
    token = text.split()[0]
    rendered = format(Decimal(token), "f")
    if "." in rendered:
        rendered = rendered.rstrip("0").rstrip(".")
    return rendered + "\n"


def write(name, notation):
    input_text = notation + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("8.549e3\n") == "8549\n"
assert oracle("0.33e0\n") == "0.33\n"
assert oracle("0.0e0\n") == "0\n"
assert oracle("1.23e5\n") == "123000\n"


def make_notation(seed, length, exponent, force_nonzero=False):
    random.seed(seed)
    lead = random.randint(1, 9) if force_nonzero else random.randint(0, 9)
    digits = "".join(random.choice("0123456789") for _ in range(max(0, length - 1)))
    digits += random.choice("123456789")
    if lead == 0:
        exponent = 0
    return f"{lead}.{digits}e{exponent}"


def build():
    write("2_edges", "0.0e0")
    write("3_wide", "1.23456789e100")
    write("4_random", make_notation(5151, 16, 73))
    write("5_io", make_notation(91919, 100, 100, force_nonzero=True))


def trace_example():
    notation = "8.549e2"
    token = notation.split("e")
    digits = token[0].replace(".", "")
    exponent = int(token[1])
    fraction_length = len(token[0].split(".")[1])
    print("notation:", notation)
    print("digits:", " ".join(digits))
    print("fraction digits:", fraction_length)
    print("exponent:", exponent)
    print("point after", 1 + exponent, "digits")
    print("integer part:", digits[:1 + exponent])
    print("fraction part:", digits[1 + exponent:])
    print("output:", oracle(notation + "\n").strip())


if "--trace" in sys.argv:
    trace_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", "8.549e2")
    build()
