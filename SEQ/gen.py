#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 10**9


def brute(seed_values, coefficients, target):
    terms = list(seed_values)
    order = len(coefficients)
    while len(terms) < target:
        next_term = sum(coefficients[j] * terms[len(terms) - 1 - j]
                        for j in range(order)) % MOD
        terms.append(next_term)
    return terms[target - 1] % MOD


def reduce_poly(poly, coefficients):
    order = len(coefficients)
    reduced = list(poly)
    for degree in range(len(reduced) - 1, order - 1, -1):
        lead = reduced[degree] % MOD
        if lead:
            for j in range(order):
                reduced[degree - 1 - j] = (reduced[degree - 1 - j] +
                                           lead * coefficients[j]) % MOD
        reduced[degree] = 0
    return reduced[:order]


def multiply_poly(left, right, coefficients):
    product = [0] * (len(left) + len(right) - 1)
    for left_index, left_value in enumerate(left):
        if left_value:
            for right_index, right_value in enumerate(right):
                spot = left_index + right_index
                product[spot] = (product[spot] +
                                 left_value * right_value) % MOD
    return reduce_poly(product, coefficients)


def kitamasa(seed_values, coefficients, target):
    order = len(coefficients)
    result_poly = [0] * order
    result_poly[0] = 1
    base_poly = [0] * order
    if order == 1:
        base_poly[0] = coefficients[0] % MOD
    else:
        base_poly[1] = 1
    exponent = target - 1
    while exponent:
        if exponent & 1:
            result_poly = multiply_poly(result_poly, base_poly, coefficients)
        base_poly = multiply_poly(base_poly, base_poly, coefficients)
        exponent >>= 1
    return sum(result_poly[j] * seed_values[j]
               for j in range(order)) % MOD


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        order = int(tokens[cursor])
        cursor += 1
        seed_values = [int(tokens[cursor + j]) for j in range(order)]
        cursor += order
        coefficients = [int(tokens[cursor + j]) for j in range(order)]
        cursor += order
        target = int(tokens[cursor])
        cursor += 1
        answers.append(str(kitamasa(seed_values, coefficients, target)))
    return "\n".join(answers) + "\n"


def encode(cases):
    lines = [str(len(cases))]
    for seed_values, coefficients, target in cases:
        lines.append(str(len(seed_values)))
        lines.append(" ".join(str(value) for value in seed_values))
        lines.append(" ".join(str(value) for value in coefficients))
        lines.append(str(target))
    return "\n".join(lines) + "\n"


def write(name, cases):
    input_text = encode(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE = [
    ([5, 8, 2], [32, 54, 6], 2),
    ([1, 2, 3], [4, 5, 6], 6),
    ([24, 354, 6], [56, 57, 465], 98765432),
]
SAMPLE_INPUT = ("3\n3\n5 8 2\n32 54 6\n2\n"
                "3\n1 2 3\n4 5 6\n6\n"
                "3\n24 354 6\n56 57 465\n98765432\n")
assert oracle(SAMPLE_INPUT) == "8\n714\n257599514\n"
assert kitamasa([5, 8, 2], [32, 54, 6], 2) == 8
assert kitamasa([1, 2, 3], [4, 5, 6], 6) == 714
assert kitamasa([7], [3], 10**9) == 7 * pow(3, 10**9 - 1, MOD) % MOD
assert kitamasa([0] * 10, [0] * 10, 10**9) == 0

check_rng = random.Random(7)
for _ in range(300):
    order = check_rng.randint(1, 5)
    seed_values = [check_rng.randint(0, 30) for _ in range(order)]
    coefficients = [check_rng.randint(0, 8) for _ in range(order)]
    target = check_rng.randint(1, 70)
    assert kitamasa(seed_values, coefficients, target) == \
        brute(seed_values, coefficients, target)

(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)

edges = [
    ([0], [0], 1),
    ([7], [3], 1),
    ([5], [1], 10**9),
    ([10**9, 10**9], [10**9, 10**9], 3),
    ([10**9, 0, 10**9], [0, 10**9, 0], 4),
    ([1] * 10, [0] * 10, 10**9),
    ([0] * 10, [1] * 10, 10**9),
    ([10**9] * 10, [10**9] * 10, 10),
    ([10**9] * 10, [10**9] * 10, 11),
    ([24, 354, 6], [56, 57, 465], 3),
]
write("2_edges", edges)

wide_rng = random.Random(20261125)
wide = []
for _ in range(20):
    wide.append(([wide_rng.randint(0, 10**9) for _ in range(10)],
                 [wide_rng.randint(0, 10**9) for _ in range(10)],
                 10**9))
for _ in range(10):
    wide.append(([wide_rng.randint(0, 10**9) for _ in range(10)],
                 [wide_rng.randint(0, 10**9) for _ in range(10)],
                 10**9 - 1))
write("3_wide", wide)

rng = random.Random(424242)
random_cases = []
for _ in range(1000):
    order = rng.randint(1, 10)
    seed_values = [rng.randint(0, 10**9) for _ in range(order)]
    coefficients = [rng.randint(0, 10**9) for _ in range(order)]
    target = rng.choice([rng.randint(1, 10), rng.randint(1, 10**9)])
    random_cases.append((seed_values, coefficients, target))
write("4_random", random_cases)

io_rng = random.Random(9001)
io_cases = []
for _ in range(1000):
    seed_values = [io_rng.randint(10**9 - 999, 10**9) for _ in range(10)]
    coefficients = [io_rng.randint(10**9 - 999, 10**9) for _ in range(10)]
    io_cases.append((seed_values, coefficients, 10**9))
write("5_io", io_cases)

print(f"generated {len(random_cases)} random cases and {len(io_cases)} io cases")
