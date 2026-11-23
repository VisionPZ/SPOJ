#!/usr/bin/env python3
import math
import os
import random
from fractions import Fraction


def lagrange_complete(sequence, count):
    size = len(sequence)
    factorials = [math.factorial(value) for value in range(size + 1)]
    denominators = []
    for index in range(1, size + 1):
        sign = -1 if (size - index) % 2 else 1
        denominators.append(sign * factorials[index - 1] * factorials[size - index])
    answers = []
    for step in range(1, count + 1):
        point = size + step
        factors = [1] + [point - index for index in range(1, size + 1)]
        prefix = [1] * (size + 2)
        for index in range(1, size + 1):
            prefix[index] = prefix[index - 1] * factors[index]
        suffix = [1] * (size + 2)
        for index in range(size, 0, -1):
            suffix[index] = suffix[index + 1] * factors[index]
        total = Fraction(0, 1)
        for index in range(1, size + 1):
            numerator = prefix[index - 1] * suffix[index + 1]
            total += Fraction(sequence[index - 1] * numerator, denominators[index - 1])
        assert total.denominator == 1
        answers.append(int(total))
    return answers


def difference_complete(sequence, count):
    rows = [list(sequence)]
    while len(rows[-1]) > 1:
        row = rows[-1]
        rows.append([row[index + 1] - row[index] for index in range(len(row) - 1)])
    last = [row[-1] for row in rows]
    answers = []
    for _ in range(count):
        carried = last[-1]
        for index in range(len(last) - 2, -1, -1):
            carried = last[index] + carried
            last[index] = carried
        answers.append(carried)
    return answers


def polynomial_values(coefficients, length):
    values = []
    for point in range(1, length + 1):
        value = 0
        power = 1
        for coefficient in coefficients:
            value += coefficient * power
            power *= point
        values.append(value)
    return values


def emit(name, cases):
    input_lines = [str(len(cases))]
    output_lines = []
    for length, count, sequence in cases:
        assert len(sequence) == length
        assert 1 <= length < 100 and 1 <= count < 100 and length + count <= 100
        input_lines.append("%d %d" % (length, count))
        input_lines.append(" ".join(str(value) for value in sequence))
        answers = lagrange_complete(sequence, count)
        assert answers == difference_complete(sequence, count)
        assert all(0 <= answer <= 2147483647 for answer in answers)
        output_lines.append(" ".join(str(answer) for answer in answers))
    with open("in/" + name + ".txt", "w") as handle:
        handle.write("\n".join(input_lines) + "\n")
    with open("out/" + name + ".out", "w") as handle:
        handle.write("\n".join(output_lines) + "\n")


assert lagrange_complete([1, 2, 3, 4, 5, 6], 3) == [7, 8, 9]
assert lagrange_complete([1, 2, 4, 7, 11, 16, 22, 29], 2) == [37, 46]
assert lagrange_complete([1] * 9 + [2], 2) == [11, 56]
assert lagrange_complete([3], 10) == [3] * 10
assert lagrange_complete([1, 4, 9, 16, 25], 2) == [36, 49]

sample = [
    (6, 3, [1, 2, 3, 4, 5, 6]),
    (8, 2, [1, 2, 4, 7, 11, 16, 22, 29]),
    (10, 2, [1] * 9 + [2]),
    (1, 10, [3]),
]
emit("1_sample", sample)

edges = [
    (1, 1, [5]),
    (1, 10, [3]),
    (5, 2, [7, 7, 7, 7, 7]),
    (4, 3, [0, 0, 0, 0]),
    (4, 3, [-3, -1, 1, 3]),
    (10, 2, [1] * 9 + [2]),
    (2, 98, [100, 200]),
    (3, 97, [1, -2, 4]),
    (5, 95, [2147483647] * 5),
    (99, 1, polynomial_values([1, 0, 1], 99)),
]
emit("2_edges", edges)

wide = [
    (99, 1, polynomial_values([2, 1, 2, 1], 99)),
    (1, 99, [2147483647]),
    (50, 50, polynomial_values([1, 2, 0, 3], 50)),
    (99, 1, polynomial_values([0, 0, 0, 0, 1], 99)),
    (2, 98, [1234567, 2345678]),
]
emit("3_wide", wide)

rng = random.Random(20261123)
random_cases = []
for _ in range(1000):
    length = rng.randint(1, 99)
    count = rng.randint(1, 100 - length)
    degree = rng.randint(0, 3)
    while True:
        coefficients = [rng.randint(-2, 3) for _ in range(degree + 1)]
        sequence = polynomial_values(coefficients, length)
        try:
            answers = lagrange_complete(sequence, count)
        except AssertionError:
            answers = None
        if answers is not None and all(0 <= answer <= 2147483647 for answer in answers):
            break
    random_cases.append((length, count, sequence))
emit("4_random", random_cases)

io_cases = [(1, 99, [2147483647]) for _ in range(5000)]
emit("5_io", io_cases)

print("generated", sum(len(value) for value in [sample, edges, wide, random_cases, io_cases]), "cases")
