#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def integer_cbrt(n):
    if n == 0:
        return 0
    guess = 1 << ((n.bit_length() + 2) // 3)
    while True:
        nxt = (2 * guess + n // (guess * guess)) // 3
        if nxt >= guess:
            break
        guess = nxt
    while (guess + 1) ** 3 <= n:
        guess += 1
    while guess ** 3 > n:
        guess -= 1
    return guess


def answer(text):
    value = int(text)
    scaled = value * 10**30
    root = integer_cbrt(scaled)
    digits = str(root)
    whole = digits[:-10] if len(digits) > 10 else "0"
    fraction = digits[-10:].rjust(10, "0")
    checksum = sum(int(ch) for ch in digits) % 10
    return f"{checksum} {whole}.{fraction}"


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    lines = []
    for _ in range(count):
        lines.append(answer(tokens[cursor])); cursor += 1
    return "\n".join(lines) + "\n"


def write_file(name, input_text):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def from_numbers(numbers):
    return str(len(numbers)) + "\n" + "".join(str(x) + "\n" for x in numbers)


SAMPLE_INPUT = "5\n1\n        8\n   1000\n\n2\n33076161\n"
SAMPLE_OUTPUT = (
    "1 1.0000000000\n"
    "2 2.0000000000\n"
    "1 10.0000000000\n"
    "0 1.2599210498\n"
    "6 321.0000000000\n"
)

for small in range(0, 2000):
    brute = 0
    while (brute + 1) ** 3 <= small:
        brute += 1
    assert integer_cbrt(small) == brute
assert integer_cbrt(10**150) == 10**50
assert integer_cbrt(33076161 * 10**30) == 321 * 10**10
assert answer("1") == "1 1.0000000000"
assert answer("8") == "2 2.0000000000"
assert answer("1000") == "1 10.0000000000"
assert answer("2") == "0 1.2599210498"
assert answer("33076161") == "6 321.0000000000"
assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT


def build():
    edges = [
        1, "00001", 2, 8, 9, 26, 27, 28, 63, 64,
        65, 999, 1000, 10**6, "0" * 149 + "1", 10**149,
        10**149 - 1, 10**150 - 1, 10**150, 1,
    ]
    write_file("2_edges", from_numbers(edges))

    wide = [
        10**150 - 1, 10**150, 9 * 10**149, 5 * 10**149,
        10**149, 10**149 - 1, 10**75, 10**75 - 1,
        2 * 10**149, 3 * 10**149, 7 * 10**149, 8 * 10**149,
        4 * 10**149, 6 * 10**149, 10**100, 10**99,
        10**50, 10**49, 10**120, 10**119,
    ]
    write_file("3_wide", from_numbers(wide))

    random.seed(2026)
    random_case = []
    for _ in range(20):
        length = random.randint(1, 150)
        digits = str(random.randint(1, 9)) + "".join(
            str(random.randint(0, 9)) for _ in range(length - 1))
        random_case.append(digits)
    write_file("4_random", from_numbers(random_case))

    io_case = []
    for index in range(20):
        digits = str(9 - index % 9) + "".join(
            str(random.randint(0, 9)) for _ in range(149))
        io_case.append(digits)
    write_file("5_io", from_numbers(io_case))


def worked_example():
    scaled = 2 * 10**30
    root = integer_cbrt(scaled)
    digits = str(root)
    checksum = sum(int(ch) for ch in digits) % 10
    print(f"scaled   = {scaled}")
    print(f"root     = {root}")
    print(f"digits   = {digits!r}")
    print(f"whole    = {digits[:-10]!r}")
    print(f"fraction = {digits[-10:]!r}")
    print(f"checksum = {checksum}")
    print(f"output   = {answer('2')}")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUTPUT)
build()
worked_example()
