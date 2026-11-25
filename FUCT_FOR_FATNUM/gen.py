#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
LIMIT = 10000000

SAMPLE_INPUT = """2
8 15
2000 1
"""
SAMPLE_OUT = """8 9
1 2 3 4 5 6 7 8 9 22 123 132 213 231 312 321 1124 1142 1214 1241 1412 1421
"""


def digit_sum_product(n):
    digit_sum = 0
    digit_product = 1
    while n:
        digit = n % 10
        digit_sum += digit
        digit_product *= digit
        n //= 10
    return digit_sum, digit_product


def brute_fat_list():
    answers = []
    for n in range(1, 100000):
        digit_sum, digit_product = digit_sum_product(n)
        if digit_sum == digit_product:
            answers.append(n)
    half_sum = [0] * 100000
    half_product = [0] * 100000
    for lo in range(100000):
        digit_sum = 0
        digit_product = 1
        rest = lo
        for _ in range(5):
            digit = rest % 10
            digit_sum += digit
            digit_product *= digit
            rest //= 10
        half_sum[lo] = digit_sum
        half_product[lo] = digit_product
    good_lo = [lo for lo in range(100000) if half_product[lo] != 0]
    for hi in range(1, 101):
        digit_sum, digit_product = digit_sum_product(hi)
        if digit_product == 0:
            continue
        for lo in good_lo:
            value = hi * 100000 + lo
            if value > LIMIT:
                break
            if digit_sum + half_sum[lo] == digit_product * half_product[lo]:
                answers.append(value)
    answers.sort()
    return answers


FAT = brute_fat_list()

assert 1 in FAT and 9 in FAT and 22 in FAT
assert 23 not in FAT and 10 not in FAT and 0 not in FAT
assert 123 in FAT and 321 in FAT and 1421 in FAT
assert 1111127 in FAT and 1111134 in FAT
assert 1111112 not in FAT
assert len(FAT) == 182
assert FAT[-1] == 7211111


def oracle(input_text):
    tokens = input_text.split()
    count = int(tokens[0])
    answers = []
    cursor = 1
    for _ in range(count):
        first = int(tokens[cursor])
        second = int(tokens[cursor + 1])
        cursor += 2
        low = min(first, second)
        high = max(first, second)
        found = [str(x) for x in FAT if low <= x <= high]
        answers.append(" ".join(found))
    return "\n".join(answers) + "\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1\n10 20\n") == "\n"
assert oracle("1\n22 22\n") == "22\n"


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(
        "%d %d\n" % case for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    edge_cases = [
        (0, 0), (1, 1), (10, 20), (22, 22), (23, 23),
        (9999999, 9999999), (1111127, 1111127), (10000000, 10000000),
        (0, 10000000), (10000000, 0), (21, 23), (1111134, 1111127),
        (123, 321), (1124, 1421), (5, 5), (999999, 1000001),
    ]
    write("2_edges", edge_cases)
    rng = random.Random(12345)
    wide_cases = []
    for _ in range(1000):
        first = rng.randint(0, 10000000)
        second = rng.randint(0, 10000000)
        wide_cases.append((first, second))
    write("3_wide", wide_cases)
    random_cases = []
    for _ in range(1000):
        first = rng.randint(0, 100000)
        second = rng.randint(0, 100000)
        random_cases.append((first, second))
    write("4_random", random_cases)
    io_cases = [(0, 10000000)] * 1000
    write("5_io", io_cases)


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        print("range 2000 1 becomes 1..2000")
        print("fat in range:", " ".join(str(x) for x in FAT if 1 <= x <= 2000))
        raise SystemExit
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [(8, 15), (2000, 1)])
    (ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
    (ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
    build()
