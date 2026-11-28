#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """3
3
4 6 8
2
15 13
1
5
"""
SAMPLE_OUT = """3
1
6
"""


def divisor_sum(value):
    total = 0
    divisor = 1
    while divisor * divisor <= value:
        if value % divisor == 0:
            total += divisor
            paired = value // divisor
            if paired != divisor:
                total += paired
        divisor += 1
    return total


def oracle(input_text):
    tokens = input_text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(count):
        number_count = int(tokens[cursor])
        cursor += 1
        common = 0
        for _ in range(number_count):
            common = math.gcd(common, int(tokens[cursor]))
            cursor += 1
        answers.append(str(divisor_sum(common)))
    return "\n".join(answers) + "\n"


def write(name, cases):
    input_text = str(len(cases)) + "\n"
    input_text += "".join("%d\n%s\n" % (len(numbers), " ".join(map(str, numbers)))
                          for numbers in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    numbers = [4, 6, 8]
    common = 0
    for value in numbers:
        common = math.gcd(common, value)
    divisors = [value for value in range(1, common + 1) if common % value == 0]
    print("numbers 4 6 8")
    print("gcd 2")
    print("divisors %s" % " ".join(map(str, divisors)))
    print("sum 3")


SAMPLE_CASES = [[4, 6, 8], [15, 13], [5]]

assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1\n1\n1\n") == "1\n"
assert oracle("1\n2\n4 6\n") == "3\n"
assert oracle("1\n1\n12\n") == "28\n"


def build():
    write("2_edges", [
        [1], [1, 1], [999999937, 999999929], [1000000000, 1000000000],
        [2, 4, 8, 16], [6, 10, 14], [73513440], [13, 17, 19],
    ])
    write("3_wide", [
        [999999937], [1000000000], [73513440], [963460800],
        [999999937, 999999937], [999999937, 1],
    ])
    rng = random.Random(3319)
    random_cases = []
    for _ in range(10):
        size = rng.randint(1, 1000)
        random_cases.append([rng.randint(1, 10**9) for _ in range(size)])
    write("4_random", random_cases)
    io_cases = []
    for _ in range(10):
        io_cases.append([rng.randint(1, 10**9) for _ in range(100000)])
    write("5_io", io_cases)


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", SAMPLE_CASES)
        build()
