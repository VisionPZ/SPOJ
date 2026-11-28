#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def term(term_number):
    diagonal = (math.isqrt(8 * term_number + 1) - 1) // 2
    if diagonal * (diagonal + 1) // 2 < term_number:
        diagonal += 1
    previous_terms = diagonal * (diagonal + 1) // 2 - diagonal
    position = term_number - previous_terms
    if diagonal % 2 == 0:
        numerator = position
        denominator = diagonal + 1 - position
    else:
        numerator = diagonal + 1 - position
        denominator = position
    return f"{numerator}/{denominator}"


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    lines = []
    for case_index in range(case_count):
        number = tokens[1 + case_index]
        lines.append(f"TERMINO {number} ES {term(number)}")
    return "\n".join(lines) + "\n"


SAMPLE = """3
3
14
7
"""
SAMPLE_OUT = """TERMINO 3 ES 2/1
TERMINO 14 ES 2/4
TERMINO 7 ES 1/4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n") == "TERMINO 1 ES 1/1\n"
assert oracle("1\n2\n") == "TERMINO 2 ES 1/2\n"
assert oracle("1\n6\n") == "TERMINO 6 ES 1/3\n"
assert oracle("1\n15\n") == "TERMINO 15 ES 1/5\n"


def brute_terms(limit):
    result = []
    diagonal = 1
    while len(result) < limit:
        if diagonal % 2 == 0:
            for position in range(1, diagonal + 1):
                result.append(f"{position}/{diagonal + 1 - position}")
        else:
            for position in range(diagonal, 0, -1):
                result.append(f"{position}/{diagonal + 1 - position}")
        diagonal += 1
    return result


BRUTE = brute_terms(200)
assert all(term(index + 1) == BRUTE[index] for index in range(200))


def write(name, numbers):
    text = str(len(numbers)) + "\n" + "\n".join(str(number) for number in numbers) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 6, 15, 10000000])
    write("3_wide", [499500, 499501, 500500, 10000000, 9999999])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 10000000) for _ in range(20)])
    write("5_io", [10000000 - index for index in range(20)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [3, 14, 7])
build()
