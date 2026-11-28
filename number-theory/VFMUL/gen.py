#!/usr/bin/env python3
import random
import sys
from pathlib import Path

if hasattr(sys, "set_int_max_str_digits"):
    sys.set_int_max_str_digits(0)

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(count):
        first = int(tokens[cursor]); cursor += 1
        second = int(tokens[cursor]); cursor += 1
        answers.append(str(first * second))
    return "\n".join(answers) + "\n"


def schoolbook(first, second):
    digits = [0] * (len(first) + len(second))
    for i in range(len(first) - 1, -1, -1):
        for j in range(len(second) - 1, -1, -1):
            digits[i + j + 1] += int(first[i]) * int(second[j])
    for k in range(len(digits) - 1, 0, -1):
        digits[k - 1] += digits[k] // 10
        digits[k] %= 10
    return str(int("".join(str(d) for d in digits)))


def write(name, pairs):
    input_text = str(len(pairs)) + "\n" + "".join(
        f"{first} {second}\n" for first, second in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE = [("4", "2"), ("123", "43"), ("324", "342"),
          ("0", "12"), ("9999", "12345")]

assert oracle("1\n4 2\n") == "8\n"
assert oracle("1\n123 43\n") == "5289\n"
assert oracle("1\n9999 12345\n") == "123437655\n"
assert oracle("1\n" + "9" * 100 + " " + "9" * 100 + "\n") == \
    str((10 ** 100 - 1) ** 2) + "\n"
assert oracle("1\n12345 6789\n") == "83810205\n"
random.seed(7)
for _ in range(200):
    first = str(random.randrange(10 ** 8))
    second = str(random.randrange(10 ** 8))
    assert schoolbook(first, second) == str(int(first) * int(second))


def build():
    write("2_edges", [
        ("0", "0"), ("0", "123456789"), ("123456789", "0"),
        ("1", "9" * 300), ("9" * 300, "1"),
        ("0000123", "0456"), ("9" * 1000, "9" * 1000),
        ("1" + "0" * 300, "1" + "0" * 300),
        ("1", "1"), ("9", "9"),
    ])
    write("3_wide", [
        ("9" * 20000, "9" * 20000),
        ("12" * 10000, "34" * 10000),
        ("7" * 100000, "8" * 100000),
        ("1" + "0" * 99999, "9" * 100000),
    ])

    random.seed(2026)
    def random_pair(max_length):
        def number():
            length = random.randint(1, max_length)
            return str(random.randint(1, 9)) + "".join(
                str(random.randint(0, 9)) for _ in range(length - 1))
        return number(), number()

    write("4_random", [random_pair(4000) for _ in range(80)])
    io_pairs = [random_pair(20000) for _ in range(98)]
    io_pairs.append(("9" * 300000, "9" * 300000))
    io_pairs.append(("1" + "0" * 149999 + "7", "8" * 300000))
    write("5_io", io_pairs)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
