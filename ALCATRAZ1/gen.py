#!/usr/bin/env python3
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "3\n123123123\n3434\n1234567890\n"
SAMPLE_OUTPUT = "18\n14\n45\n"


def divmod_digit_sum(number):
    total = 0
    while number > 0:
        number, remainder = divmod(number, 10)
        total += remainder
    return total


def oracle(text):
    parts = text.split()
    count = int(parts[0])
    return "\n".join(str(divmod_digit_sum(int(parts[index + 1])))
                     for index in range(count)) + "\n"


def write(name, numbers):
    input_text = str(len(numbers)) + "\n" + "\n".join(str(number) for number in numbers) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1\n1\n") == "1\n"
assert oracle("1\n9\n") == "9\n"
assert oracle("2\n" + "1" + "0" * 50 + "\n1\n") == "1\n1\n"
assert oracle("1\n" + "9" * 50 + "\n") == "450\n"


def build():
    write("2_edges", [1, 9, 10, 99, 100, 10**50, int("9" * 50),
                      123456789012345678901234567890, 10**49])

    random.seed(27182)
    wide = []
    for _ in range(9):
        length = random.randint(40, 50)
        digits = str(random.randint(1, 9)) + "".join(
            random.choice("0123456789") for _ in range(length - 1))
        wide.append(int(digits))
    write("3_wide", wide)

    random.seed(61616)
    mixed = []
    for _ in range(9):
        length = random.randint(1, 50)
        digits = str(random.randint(1, 9)) + "".join(
            random.choice("0123456789") for _ in range(length - 1))
        mixed.append(int(digits))
    write("4_random", mixed)

    random.seed(12345)
    largest = []
    for _ in range(9):
        digits = "9" * 49 + str(random.randint(1, 9))
        largest.append(int(digits))
    write("5_io", largest)


def trace_example():
    for number in [123123123, 3434, 1234567890]:
        digits = [int(char) for char in str(number)]
        print("number", number, "digits", " ".join(str(digit) for digit in digits),
              "sum", sum(digits))


if "--trace" in sys.argv:
    trace_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [123123123, 3434, 1234567890])
    build()
