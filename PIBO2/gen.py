#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1111111111


def build_reduction(degree):
    poly = [1]
    for _ in range(degree + 1):
        expanded = [0] * (len(poly) + 1)
        for index, value in enumerate(poly):
            expanded[index] = (expanded[index] + value) % MODULUS
            expanded[index + 1] = (expanded[index + 1] - value) % MODULUS
        poly = expanded
    recurrence = [0] * (degree + 4)
    for index, value in enumerate(poly):
        recurrence[index] = (recurrence[index] + value) % MODULUS
        recurrence[index + 1] = (recurrence[index + 1] - value) % MODULUS
        recurrence[index + 2] = (recurrence[index + 2] - value) % MODULUS
    return recurrence[:degree + 4]


def initial_values(degree, coefficients):
    order = degree + 3
    values = [0] * order
    values[0] = 1 % MODULUS
    values[1] = 1 % MODULUS
    for index in range(2, order):
        forcing = 0
        power = 1
        for coefficient in coefficients:
            forcing = (forcing + coefficient * power) % MODULUS
            power = power * index % MODULUS
        values[index] = (values[index - 1] + values[index - 2] + forcing) % MODULUS
    return values


def multiply_matrices(first, second, size):
    result = [[0] * size for _ in range(size)]
    for row in range(size):
        result_row = result[row]
        first_row = first[row]
        for middle in range(size):
            factor = first_row[middle]
            if factor == 0:
                continue
            second_row = second[middle]
            for column in range(size):
                result_row[column] = (result_row[column] + factor * second_row[column]) % MODULUS
    return result


def matrix_power(matrix, exponent, size):
    result = [[0] * size for _ in range(size)]
    for index in range(size):
        result[index][index] = 1
    base = matrix
    while exponent > 0:
        if exponent & 1:
            result = multiply_matrices(result, base, size)
        exponent >>= 1
        if exponent > 0:
            base = multiply_matrices(base, base, size)
    return result


def oracle(target_index, degree, coefficients):
    order = degree + 3
    values = initial_values(degree, coefficients)
    if target_index < order:
        return str(values[target_index]) + "\n"
    recurrence = build_reduction(degree)
    first_row = [(-recurrence[index]) % MODULUS for index in range(1, order + 1)]
    companion = [[0] * order for _ in range(order)]
    companion[0] = first_row
    for index in range(1, order):
        companion[index][index - 1] = 1
    powered = matrix_power(companion, target_index - order + 1, order)
    state = list(reversed(values[:order]))
    updated = [sum(powered[row][column] * state[column] for column in range(order)) % MODULUS
               for row in range(order)]
    return str(updated[0]) + "\n"


def brute(target_index, degree, coefficients):
    previous, current = 1 % MODULUS, 1 % MODULUS
    if target_index == 0:
        return str(previous) + "\n"
    if target_index == 1:
        return str(current) + "\n"
    for index in range(2, target_index + 1):
        forcing = 0
        power = 1
        for coefficient in coefficients:
            forcing = (forcing + coefficient * power) % MODULUS
            power = power * index % MODULUS
        previous, current = current, (current + previous + forcing) % MODULUS
    return str(current) + "\n"


def oracle_text(text):
    tokens = [int(value) for value in text.split()]
    return oracle(tokens[0], tokens[1], tokens[2:])


for target, degree, coeffs in [(10, 0, [0]), (10, 0, [1]), (100, 1, [1, 1]),
                               (0, 0, [7]), (20, 2, [2, 3, 4]), (60, 3, [1, 2, 3, 4])]:
    body = f"{target} {degree}\n" + " ".join(str(value) for value in coeffs) + "\n"
    assert oracle_text(body) == brute(target, degree, coeffs)

SAMPLE = "10 0\n0\n"
SAMPLE_OUT = "89\n"
assert oracle_text(SAMPLE) == SAMPLE_OUT
assert oracle_text("10 0\n1\n") == "177\n"
assert oracle_text("100 1\n1 1\n") == "343742333\n"


def write(name, target, degree, coefficients):
    text = f"{target} {degree}\n" + " ".join(str(value) for value in coefficients) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle_text(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", 0, 0, [1111111110])
    write("3_wide", 1000000000, 24, [rng.randint(0, MODULUS - 1) for _ in range(25)])
    random_degree = rng.randint(0, 20)
    write("4_random", rng.randint(0, 1000000000), random_degree,
          [rng.randint(0, MODULUS - 1) for _ in range(random_degree + 1)])
    write("5_io", 1000000000, 40, [MODULUS - 1] * 41)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
