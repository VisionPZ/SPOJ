#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SEARCH_CAP = 2_000_000


def multiplicative_order(base, modulus):
    if math.gcd(base, modulus) != 1:
        return None
    current = base % modulus
    order = 1
    while current != 1 and order <= modulus:
        current = current * base % modulus
        order += 1
    return order if current == 1 else None


def shortest_repdigit_length(divisor):
    best_length = None
    for digit in range(1, 10):
        reduced = divisor // math.gcd(digit, divisor)
        if math.gcd(10, reduced) != 1:
            continue
        modulus = 9 * reduced
        order = multiplicative_order(10, modulus)
        if order is not None and (best_length is None or order < best_length):
            best_length = order
    return best_length


def safe_divisor(divisor):
    if len(set(str(divisor))) > 2:
        return False
    one_digit_length = shortest_repdigit_length(divisor)
    return one_digit_length is None or one_digit_length <= 6


def oracle(divisor):
    best_count = 99
    best_value = None
    for multiple in range(divisor, SEARCH_CAP + 1, divisor):
        digit_count = len(set(str(multiple)))
        if digit_count < best_count:
            best_count = digit_count
            best_value = multiple
        if best_count == 1:
            break
    return str(best_value)


SAMPLE = "7 \n15 \n16 \n101 \n0\n"
SAMPLE_OUT = "7 \n555 \n16 \n1111\n"
assert oracle(7) == "7"
assert oracle(15) == "555"
assert oracle(16) == "16"
assert oracle(101) == "1111"
assert oracle(37) == "111"
assert oracle(11) == "11"
assert oracle(100) == "100"
assert "".join(oracle(value) + " \n" for value in [7, 15, 16]) + "1111\n" == "7 \n555 \n16 \n1111\n"


def format_answers(divisors):
    return "".join(
        oracle(value) + (" \n" if index < len(divisors) - 1 else "\n")
        for index, value in enumerate(divisors)
    )


def write(name, divisors):
    divisors = [value for value in divisors if safe_divisor(value)]
    assert divisors
    text = "".join(f"{value} \n" for value in divisors) + "0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(format_answers(divisors))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)

write("2_edges", [1, 2, 3, 7, 9, 10, 11, 37, 98, 99])
write("3_wide", [101, 111, 222, 333, 444, 555, 666, 777, 888, 999, 1000, 2000, 5000, 10000])
pool = list(range(1, 100)) + [101, 111, 222, 333, 444, 555, 666, 777, 888, 999, 1000, 2000, 5000, 10000]
rng = random.Random(20261130)
write("4_random", [rng.choice(pool) for _ in range(30)])
write("5_io", [rng.choice(pool) for _ in range(50)])
