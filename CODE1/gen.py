#!/usr/bin/env python3
import os
import random

HERE = os.path.dirname(os.path.abspath(__file__))


def largest_digit(base_norm):
    digit = 0
    while (digit + 1) * (digit + 1) < base_norm:
        digit += 1
    return digit


def nearest(numerator, denominator):
    return (2 * numerator + denominator) // (2 * denominator)


def reconstruct(digits, base_real, base_imag):
    real = 0
    imag = 0
    for digit in reversed(digits):
        real, imag = real * base_real - imag * base_imag + digit, real * base_imag + imag * base_real
    return real, imag


def verify(digits, case):
    xr, xi, br, bi = case
    assert digits is not None, case
    assert 1 <= len(digits) <= 101, (case, len(digits))
    assert reconstruct(digits, br, bi) == (xr, xi), (case, digits)
    assert len(digits) == 1 or digits[-1] != 0, (case, digits)
    limit = largest_digit(br * br + bi * bi)
    assert all(0 <= digit <= limit for digit in digits), (case, digits)


def solve_oracle(xr, xi, br, bi):
    norm = br * br + bi * bi
    limit = largest_digit(norm)
    digits = []
    steps = 0
    while True:
        if xr == 0 and xi == 0:
            break
        guess_real = nearest(xr * br + xi * bi, norm)
        guess_imag = nearest(xi * br - xr * bi, norm)
        found = None
        for quotient_real in range(guess_real - 3, guess_real + 4):
            if br == 0:
                if xi - quotient_real * bi != 0:
                    continue
                for quotient_imag in range(guess_imag - 3, guess_imag + 4):
                    remainder_real = xr + quotient_imag * bi
                    if 0 <= remainder_real <= limit:
                        found = (quotient_real, quotient_imag, remainder_real)
                        break
                if found is not None:
                    break
                continue
            residual = xi - quotient_real * bi
            if residual % br != 0:
                continue
            quotient_imag = residual // br
            if xi - quotient_real * bi - quotient_imag * br != 0:
                continue
            remainder_real = xr - quotient_real * br + quotient_imag * bi
            if 0 <= remainder_real <= limit:
                found = (quotient_real, quotient_imag, remainder_real)
                break
        if found is None:
            return None
        quotient_real, quotient_imag, digit = found
        digits.append(digit)
        if quotient_real == 0 and quotient_imag == 0:
            break
        xr, xi = quotient_real, quotient_imag
        steps += 1
        if steps > 110:
            return None
    return digits if digits else [0]


def format_result(digits):
    if digits is None:
        return "The code cannot be decrypted."
    return ",".join(str(digit) for digit in reversed(digits))


def solve_all(cases):
    results = []
    for case in cases:
        digits = solve_oracle(*case)
        if digits is not None:
            verify(digits, case)
        results.append(digits)
    return results


def write_pair(name, cases, results):
    with open(os.path.join(HERE, "in", name + ".txt"), "w") as input_file:
        input_file.write("%d\n" % len(cases))
        for case in cases:
            input_file.write("%d %d %d %d\n" % case)
    with open(os.path.join(HERE, "out", name + ".out"), "w") as output_file:
        for digits in results:
            output_file.write(format_result(digits) + "\n")


def make_from_cases(name, cases):
    write_pair(name, cases, solve_all(cases))


SAMPLE_CASES = [
    (-935, 2475, -11, -15),
    (1, 0, -3, -2),
    (93, 16, 3, 2),
    (191, -192, 11, -12),
]
SAMPLE_EXPECTED = [
    [18, 11, 8],
    [1],
    None,
    [15, 16],
]
for sample_case, sample_expected in zip(SAMPLE_CASES, SAMPLE_EXPECTED):
    sample_solution = solve_oracle(*sample_case)
    if sample_expected is None:
        assert sample_solution is None, (sample_case, sample_solution)
    else:
        assert sample_solution == sample_expected, (sample_case, sample_solution, sample_expected)
        verify(sample_solution, sample_case)

with open(os.path.join(HERE, "in", "1_sample.txt"), "w") as input_file:
    input_file.write("4\n")
    for case in SAMPLE_CASES:
        input_file.write("%d %d %d %d\n" % case)
with open(os.path.join(HERE, "out", "1_sample.out"), "w") as output_file:
    for digits in SAMPLE_EXPECTED:
        output_file.write(format_result(digits) + "\n")


EDGE_BASES = [
    (1, 1), (1, -1), (-1, 1), (-1, -1),
    (2, 0), (-2, 0), (0, 2), (0, -2),
    (2, 1), (1, 2), (-2, 1), (2, -1), (-2, -1), (-1, -2),
    (3, 2), (-3, -2), (3, -2), (-3, 2), (2, 3), (-2, 3),
    (11, -12), (-11, -15), (16, 16), (-16, -16), (15, 15),
    (16, 0), (0, 16), (-16, 0), (0, -16), (16, 15), (15, 16),
    (1, 16), (16, 1), (-1, 16), (16, -1), (7, 7), (6, 8), (5, 3),
    (4, 2), (8, 4), (12, 9), (10, 10), (9, 12),
]
edge_cases = []
for base in EDGE_BASES:
    limit = largest_digit(base[0] * base[0] + base[1] * base[1])
    edge_cases.extend([
        (0, 0) + base,
        (1, 0) + base,
        (-1, 0) + base,
        (0, 1) + base,
        (0, -1) + base,
        (limit, 0) + base,
        (limit + 1, 0) + base,
        (-limit, -limit) + base,
        (base[0], base[1]) + base,
        (-base[0], -base[1]) + base,
        (1000000, 1000000) + base,
        (-1000000, -1000000) + base,
        (1000000, -1000000) + base,
        (-1000000, 1000000) + base,
        (1000000, 0) + base,
        (0, 1000000) + base,
    ])
make_from_cases("2_edges", edge_cases)


wide_rng = random.Random(88031)
wide_cases = []
for _ in range(6000):
    base_real = wide_rng.randint(-16, 16)
    base_imag = wide_rng.randint(-16, 16)
    if base_real * base_real + base_imag * base_imag <= 1:
        continue
    xr = wide_rng.choice([-1, 1]) * wide_rng.randint(999000, 1000000)
    xi = wide_rng.choice([-1, 1]) * wide_rng.randint(999000, 1000000)
    wide_cases.append((xr, xi, base_real, base_imag))
make_from_cases("3_wide", wide_cases)


random_rng = random.Random(20261123)
random_cases = []
for _ in range(20000):
    base_real = random_rng.randint(-16, 16)
    base_imag = random_rng.randint(-16, 16)
    if base_real * base_real + base_imag * base_imag <= 1:
        continue
    xr = random_rng.randint(-1000000, 1000000)
    xi = random_rng.randint(-1000000, 1000000)
    random_cases.append((xr, xi, base_real, base_imag))
make_from_cases("4_random", random_cases)


io_rng = random.Random(771234)
io_cases = []
io_results = []
digit_length = 36
for _ in range(100000):
    digits = [io_rng.randint(0, 1) for _ in range(digit_length - 1)] + [1]
    real = 0
    imag = 0
    for digit in reversed(digits):
        real, imag = real - imag + digit, real + imag
    assert abs(real) <= 1000000 and abs(imag) <= 1000000, (real, imag)
    verify(digits, (real, imag, 1, 1))
    io_cases.append((real, imag, 1, 1))
    io_results.append(digits)
write_pair("5_io", io_cases, io_results)
