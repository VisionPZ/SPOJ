#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1000000007


def value_of(prime, digits):
    result = 0
    for exponent, digit in enumerate(digits):
        result += digit * prime ** exponent
    return result


def sum_non_divisible(size, prime):
    if size <= 0:
        return 0
    block = 1
    height = 0
    while block * prime <= size:
        block *= prime
        height += 1
    leading = size // block
    rest = size % block
    full_block = prime * (prime + 1) // 2
    return leading * (leading + 1) // 2 * full_block ** height + (leading + 1) * sum_non_divisible(rest, prime)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    answers = []
    for _ in range(case_count):
        prime = tokens[cursor]
        digit_count = tokens[cursor + 1]
        cursor += 2
        digits = tokens[cursor:cursor + digit_count]
        cursor += digit_count
        size = value_of(prime, digits)
        total = size * (size + 1) // 2
        answer = (total - sum_non_divisible(size, prime)) % MODULUS
        answers.append(str(answer))
    return "\n".join(answers) + "\n"


def brute(prime, digits):
    size = value_of(prime, digits)
    row = [1]
    divisible = 0
    for _ in range(size):
        divisible += sum(1 for entry in row if entry % prime == 0)
        row = [1] + [(row[index] + row[index + 1]) % prime for index in range(len(row) - 1)] + [1]
    return divisible


SAMPLE = """3
5 2
0 1 
5 2
1 1
7 3
2 0 2
"""
SAMPLE_OUT = """0
4
2689
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 1\n1\n") == "0\n"
assert oracle("1\n2 2\n0 1\n") == "0\n"
assert oracle("1\n2 2\n1 1\n") == "1\n"
assert brute(2, [1, 1]) == 1
assert brute(5, [0, 1]) == 0
assert brute(5, [1, 1]) == 4
assert brute(7, [2, 0, 2]) == 2689

for check_prime in (2, 3, 5, 7):
    for check_digits in ([1], [0, 1], [1, 1], [2, 1], [0, 0, 1], [1, 2, 1]):
        if check_digits[-1] > 0 and all(digit < check_prime for digit in check_digits):
            check_size = value_of(check_prime, check_digits)
            assert sum_non_divisible(check_size, check_prime) == check_size * (check_size + 1) // 2 - brute(check_prime, check_digits)


def write_cases(name, cases):
    lines = []
    for prime, digits in cases:
        lines.append("%d %d" % (prime, len(digits)))
        lines.append(" ".join(str(digit) for digit in digits))
    text = str(len(cases)) + "\n" + "\n".join(lines) + "\n"
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(text))


def build():
    write_cases("2_edges", [(2, [1]), (2, [0, 1]), (2, [1, 1]), (3, [0, 0, 1]), (5, [1]), (7, [2, 0, 2])])
    rng = random.Random(20261126)
    wide = []
    for _ in range(5):
        digits = [rng.randrange(999983) for _ in range(50)]
        digits[-1] = rng.randrange(1, 999983)
        wide.append((999983, digits))
    write_cases("3_wide", wide)
    primes = [2, 3, 5, 7, 11, 101, 1009, 1000003, 999983]
    random_cases = []
    for _ in range(20):
        prime = rng.choice(primes)
        length = rng.randint(1, 20)
        digits = [rng.randrange(prime) for _ in range(length)]
        digits[-1] = rng.randrange(1, prime)
        random_cases.append((prime, digits))
    write_cases("4_random", random_cases)
    io_cases = []
    for _ in range(299):
        prime = rng.choice(primes)
        length = rng.randint(1, 3)
        digits = [rng.randrange(prime) for _ in range(length)]
        digits[-1] = rng.randrange(1, prime)
        io_cases.append((prime, digits))
    write_cases("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
