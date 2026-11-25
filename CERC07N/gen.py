#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def polynomial_value(digits, base):
    return sum(digit * base ** position for position, digit in enumerate(digits))


def oracle_to(decimal_value, radius):
    if decimal_value == 0:
        return "0"
    base = -radius
    for length in range(1, 26):
        low_length = length // 2
        high_length = length - low_length
        low_values = {}
        for low_digits in itertools.product(range(radius), repeat=low_length):
            low_value = polynomial_value(low_digits, base)
            if low_value not in low_values:
                low_values[low_value] = low_digits
        scale = base ** low_length
        for high_digits in itertools.product(range(radius), repeat=high_length):
            if high_digits[-1] == 0:
                continue
            high_value = polynomial_value(high_digits, base)
            needed = decimal_value - high_value * scale
            if needed in low_values:
                most_significant = tuple(reversed(high_digits))
                least_significant = tuple(reversed(low_values[needed]))
                return "".join(str(digit) for digit in most_significant + least_significant)
    raise ValueError("no representation")


def oracle_from(digit_text, radius):
    base = -radius
    reversed_digits = [int(char) for char in reversed(digit_text)]
    return polynomial_value(reversed_digits, base)


def oracle(text):
    answers = []
    for line in text.splitlines():
        line = line.strip()
        if not line or line == "end":
            continue
        prefix, number_text = line.split()
        radius = int(prefix[3:] if prefix.startswith("to-") else prefix[5:])
        if prefix.startswith("to-"):
            answers.append(oracle_to(int(number_text), radius))
        else:
            answers.append(str(oracle_from(number_text, radius)))
    return "\n".join(answers) + "\n"


SAMPLE = """to-2 10
from-2 1010
to-10 10
to-10 -10
from-10 10
end
"""
SAMPLE_OUT = """11110
-10
190
10
-10
"""

assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_to(10, 2) == "11110"
assert oracle_to(-10, 2) == "1010"
assert oracle_to(10, 10) == "190"
assert oracle_to(0, 7) == "0"
assert oracle_from("1010", 2) == -10
assert oracle_from("10", 10) == -10


def write(name, lines):
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def conversions(pairs):
    return [f"to-{radius} {decimal}" if decimal is not None else f"from-{radius} {text}"
            for radius, decimal, text in pairs]


def build():
    edges = [
        (2, 0, None), (2, 1, None), (2, -1, None), (10, 0, None),
        (10, 999, None), (3, -999, None), (2, None, "0"),
        (2, None, "1"), (10, None, "190"), (10, None, "10"),
    ]
    write("2_edges", conversions(edges))
    wide = []
    for radius in range(2, 11):
        wide.append((radius, 99999, None))
        wide.append((radius, -99999, None))
    write("3_wide", conversions(wide))
    rng = random.Random(20261125)
    random_lines = []
    for _ in range(300):
        radius = rng.randint(2, 10)
        decimal = rng.randint(-9999, 9999)
        digits = oracle_to(decimal, radius)
        random_lines.append(f"to-{radius} {decimal}")
        random_lines.append(f"from-{radius} {digits}")
    write("4_random", random_lines)
    io_lines = []
    for index in range(20000):
        radius = 2 + index % 9
        decimal = (index * 37) % 401 - 200
        io_lines.append(f"to-{radius} {decimal}")
    write("5_io", io_lines)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
