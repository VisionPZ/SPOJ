#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "6\n16\n127\n256\n513\n2048\n5097\n"
SAMPLE_OUT = ("2 2 2 2\n127\n2 2 2 2 2 2 2 2\n3 3 3 19\n"
              "2 2 2 2 2 2 2 2 2 2 2\n3 1699\n")


def factorize(number):
    factors = []
    while number % 2 == 0:
        factors.append(2)
        number //= 2
    divisor = 3
    while divisor * divisor <= number:
        while number % divisor == 0:
            factors.append(divisor)
            number //= divisor
        divisor += 2
    if number > 1:
        factors.append(number)
    return factors


def oracle(input_text):
    tokens = input_text.split()
    case_count = int(tokens[0])
    lines = []
    for i in range(case_count):
        number = int(tokens[1 + i])
        lines.append(" ".join(str(f) for f in factorize(number)))
    return "\n".join(lines) + "\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1\n1\n") == "\n"
assert oracle("1\n2\n") == "2\n"
assert oracle("1\n720720\n") == "2 2 2 2 3 3 5 7 11 13\n"
assert oracle("1\n999983\n") == "999983\n"


def write(name, numbers):
    input_text = "%d\n%s\n" % (len(numbers), "\n".join(str(n) for n in numbers))
    (ROOT / "in" / ("%s.txt" % name)).write_text(input_text)
    (ROOT / "out" / ("%s.out" % name)).write_text(oracle(input_text))


def build():
    write("2_edges", [1, 2, 999983, 1000000, 999999, 4, 999979, 524288, 720720])
    write("3_wide", [1000000] * 20 + [524288] * 20 + [999983, 999979, 999961])
    rng = random.Random(20190108)
    write("4_random", [rng.randint(1, 10**6) for _ in range(2000)])
    write("5_io", [rng.randint(1, 10**6) for _ in range(100000)])


if __name__ == "__main__":
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [16, 127, 256, 513, 2048, 5097])
    build()
