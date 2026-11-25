#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    numbers = tokens[1:1 + count]
    answer = 0
    for bit in range(61):
        has_zero = False
        has_one = False
        for value in numbers:
            if (value >> bit) & 1:
                has_one = True
            else:
                has_zero = True
        if has_zero and has_one:
            answer |= 1 << bit
    return str(answer) + "\n"


def brute_force(numbers):
    answer = 0
    for left in range(len(numbers)):
        for right in range(left + 1, len(numbers)):
            answer |= numbers[left] ^ numbers[right]
    return str(answer) + "\n"


SAMPLE = """3
10
15
17
"""
SAMPLE_OUT = """31
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute_force([10, 15, 17]) == SAMPLE_OUT
assert oracle("2\n0\n0\n") == "0\n"
assert oracle("3\n5\n5\n7\n") == brute_force([5, 5, 7]) == "2\n"
assert brute_force([1, 2, 4, 8]) == "15\n"


def write(name, numbers):
    text = str(len(numbers)) + "\n" + "".join(str(value) + "\n" for value in numbers)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [0, 0])
    write("3_wide", [10 ** 18 if index % 2 else 0 for index in range(1000)])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(0, 10 ** 18) for _ in range(5000)])
    write("5_io", [rng.randint(0, 10 ** 18) for _ in range(100000)])


def trace_example():
    numbers = [10, 15, 17]
    union_value = 0
    intersection_value = (1 << 61) - 1
    for value in numbers:
        union_value |= value
        intersection_value &= value
    print("numbers      " + " ".join(format(value, "05b") for value in numbers))
    print("unionBits    " + format(union_value, "05b") + " = " + str(union_value))
    print("intersectionBits " + format(intersection_value, "05b") + " = " + str(intersection_value))
    print("answer       " + format(union_value ^ intersection_value, "05b") + " = " + str(union_value ^ intersection_value))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [10, 15, 17])
build()
trace_example()
