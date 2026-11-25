#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007


def is_prime(value):
    if value < 2:
        return False
    divisor = 2
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        divisor += 1
    return True


def brute_count(length):
    total = 0
    for mask in range(1 << length):
        word = [1 if (mask >> pos) & 1 else 0 for pos in range(length)]
        valid = True
        for prime in [value for value in range(2, length + 1) if is_prime(value)]:
            for start in range(length - prime + 1):
                ones = sum(word[start:start + prime])
                if ones < prime - ones:
                    valid = False
                    break
            if not valid:
                break
        if valid:
            total += 1
    return total % MOD


def recurrence_count(length):
    first, second, third = 1, 2, 3
    for _ in range(3, length + 1):
        first, second, third = second, third, (third + first) % MOD
    if length == 0:
        return 1
    if length == 1:
        return 2
    return third


def multiply(left, right):
    return [[sum(left[i][k] * right[k][j] for k in range(3)) % MOD for j in range(3)] for i in range(3)]


def fast_count(length):
    if length <= 2:
        return [1, 2, 3][length]
    base = [[1, 0, 1], [1, 0, 0], [0, 1, 0]]
    powered = [[1 if i == j else 0 for j in range(3)] for i in range(3)]
    exponent = length - 2
    while exponent > 0:
        if exponent & 1:
            powered = multiply(powered, base)
        exponent >>= 1
        if exponent:
            base = multiply(base, base)
    return (powered[0][0] * 3 + powered[0][1] * 2 + powered[0][2]) % MOD


def oracle(text):
    length = int(text.split()[0])
    if length <= 18:
        return str(brute_count(length)) + "\n"
    if length <= 200000:
        return str(recurrence_count(length)) + "\n"
    return str(fast_count(length)) + "\n"


SAMPLE = "2\n"
SAMPLE_OUT = "3\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3\n") == "4\n"
assert oracle("1\n") == "2\n"
assert oracle("5\n") == "9\n"
assert [recurrence_count(value) for value in range(2, 21)] == [
    3, 4, 6, 9, 13, 19, 28, 41, 60, 88, 129, 189, 277, 406, 595, 872, 1278, 1873, 2745]
for small_length in range(1, 17):
    assert brute_count(small_length) == recurrence_count(small_length)
assert fast_count(1000) == recurrence_count(1000)
assert fast_count(5000) == recurrence_count(5000)


def write(name, length):
    text = str(length) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1)
    write("3_wide", 100000)
    rng = random.Random(20261126)
    write("4_random", rng.randint(1, 100000))
    write("5_io", 1000000000000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
