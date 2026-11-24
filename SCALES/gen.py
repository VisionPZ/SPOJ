#!/usr/bin/env python3
import random
import sys
from itertools import product
from pathlib import Path

ROOT = Path(__file__).resolve().parent

ZERO_TRANSITION = ((1, 0), (1, 1))
ONE_TRANSITION = ((1, 1), (0, 1))


def enumerate_transition(bit):
    matrix = [[0, 0], [0, 0]]
    for state in (0, 1):
        carry = -state
        for digit in (-1, 0, 1):
            numerator = carry + digit - bit
            if numerator % 2 != 0:
                continue
            next_carry = numerator // 2
            if next_carry not in (0, -1):
                continue
            matrix[state][-next_carry] += 1
    return tuple(tuple(row) for row in matrix)


assert enumerate_transition(0) == ZERO_TRANSITION
assert enumerate_transition(1) == ONE_TRANSITION


def multiply(left, right, modulus):
    return tuple(
        tuple(sum(left[i][k] * right[k][j] for k in range(2)) % modulus
              for j in range(2))
        for i in range(2))


def power(base, exponent, modulus):
    result = ((1, 0), (0, 1))
    while exponent > 0:
        if exponent & 1:
            result = multiply(result, base, modulus)
        base = multiply(base, base, modulus)
        exponent >>= 1
    return result


def vector_times(vector, matrix, modulus):
    return tuple(sum(vector[i] * matrix[i][j] for i in range(2)) % modulus
                 for j in range(2))


def oracle_single(weight_count, bits, modulus):
    state = (1 % modulus, 0)
    for i in range(len(bits) - 1, -1, -1):
        transition = ONE_TRANSITION if bits[i] == '1' else ZERO_TRANSITION
        state = vector_times(state, transition, modulus)
    trailing = power(ZERO_TRANSITION, weight_count - len(bits), modulus)
    state = vector_times(state, trailing, modulus)
    return state[0]


def brute_single(weight_count, value):
    total = 0
    for digits in product((-1, 0, 1), repeat=weight_count):
        signed_sum = sum(digit << i for i, digit in enumerate(digits))
        if signed_sum == value:
            total += 1
    return total


def parse(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    cases = []
    for _ in range(case_count):
        weight_count = int(tokens[cursor]); cursor += 1
        bit_length = int(tokens[cursor]); cursor += 1
        modulus = int(tokens[cursor]); cursor += 1
        bits = tokens[cursor]; cursor += 1
        cases.append((weight_count, bit_length, modulus, bits))
    return cases


def render(cases):
    parts = [str(len(cases))]
    for weight_count, bit_length, modulus, bits in cases:
        parts.append(f"{weight_count} {bit_length} {modulus}")
        parts.append(bits)
    return "\n".join(parts) + "\n"


def oracle(text):
    cases = parse(text)
    answers = []
    for weight_count, bit_length, modulus, bits in cases:
        assert len(bits) == bit_length
        assert bits[0] == '1' or bits == '0'
        answers.append(str(oracle_single(weight_count, bits, modulus)))
    return "\n".join(answers) + "\n"


SAMPLE_IN = "2\n6 4 6\n1000\n6 6 100\n100110\n"
SAMPLE_OUT = "3\n5\n"

assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle_single(1, "1", 100) == 1
assert oracle_single(2, "1", 100) == 2
assert oracle_single(6, "100000", 100) == 1
assert oracle_single(1000000, "1", 2) == 0

for weight_count in range(1, 9):
    for value in range(1 << weight_count):
        bits = bin(value)[2:] if value > 0 else "0"
        assert oracle_single(weight_count, bits, 1000) == brute_single(
            weight_count, value), (weight_count, value)


def worked_example():
    lines = []
    bits = "1000"
    count_zero, count_one = 1, 0
    lines.append("start (countZero, countOne) = (1, 0)")
    for i in range(len(bits) - 1, -1, -1):
        if bits[i] == '1':
            count_one = count_zero + count_one
        else:
            count_zero = count_zero + count_one
        lines.append(f"bit {i} = {bits[i]}: ({count_zero}, {count_one})")
    lines.append(f"two trailing zero bits: ({count_zero + 2 * count_one}, {count_one})")
    return "\n".join(lines)


assert worked_example() == (
    "start (countZero, countOne) = (1, 0)\n"
    "bit 3 = 0: (1, 0)\n"
    "bit 2 = 0: (1, 0)\n"
    "bit 1 = 0: (1, 0)\n"
    "bit 0 = 1: (1, 1)\n"
    "two trailing zero bits: (3, 1)")


def random_bits(rng, length):
    if length == 1:
        return rng.choice('01')
    return '1' + ''.join(rng.choice('01') for _ in range(length - 1))


def write(name, cases):
    input_text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    edge_cases = [
        (1, 1, 100, "1"),
        (1, 1, 100, "0"),
        (5, 1, 7, "1"),
        (10, 10, 99, "1111111111"),
        (6, 4, 6, "1000"),
        (6, 6, 100, "100110"),
        (100000, 1, 97, "0"),
        (1000000, 1, 2, "1"),
        (1000000, 1, 100, "1"),
    ]
    write("2_edges", edge_cases)

    wide_rng = random.Random(2026)
    wide_cases = [
        (1000000, 1000000, 97, "1" + "0" * 999999),
        (1000000, 1000000, 100, "1" * 1000000),
        (1000000, 1000000, 89, random_bits(wide_rng, 1000000)),
    ]
    write("3_wide", wide_cases)

    random_rng = random.Random(77)
    random_cases = []
    for case_index in range(200):
        if case_index % 2 == 0:
            weight_count = random_rng.randint(1, 30)
            bit_length = random_rng.randint(1, weight_count)
        else:
            weight_count = random_rng.randint(1, 1000000)
            bit_length = random_rng.randint(1, 40)
        modulus = random_rng.randint(2, 100)
        random_cases.append((weight_count, bit_length, modulus,
                             random_bits(random_rng, bit_length)))
    write("4_random", random_cases)

    io_rng = random.Random(999)
    io_cases = []
    for _ in range(200000):
        weight_count = io_rng.randint(8, 20)
        io_cases.append((weight_count, weight_count, 100,
                         random_bits(io_rng, weight_count)))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
if "--worked" in sys.argv:
    print(worked_example())
else:
    (ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
    (ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
    build()
