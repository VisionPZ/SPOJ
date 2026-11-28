#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def layout(size):
    widths = [size + min(row, 2 * size - 2 - row) for row in range(2 * size - 1)]
    index = []
    counter = 0
    for width in widths:
        row_index = []
        for _ in range(width):
            row_index.append(counter)
            counter += 1
        index.append(row_index)
    return widths, index, counter


def sources(size, row, column, widths, index):
    result = []
    if column > 0:
        result.append(index[row][column - 1])
    if column + 1 < widths[row]:
        result.append(index[row][column + 1])
    if row > 0:
        above = widths[row - 1]
        if above == widths[row] + 1:
            result.append(index[row - 1][column])
            if column + 1 < above:
                result.append(index[row - 1][column + 1])
        else:
            if column > 0:
                result.append(index[row - 1][column - 1])
            if column < above:
                result.append(index[row - 1][column])
    if row < len(widths) - 1:
        below = widths[row + 1]
        if below == widths[row] + 1:
            result.append(index[row + 1][column])
            if column + 1 < below:
                result.append(index[row + 1][column + 1])
        else:
            if column > 0:
                result.append(index[row + 1][column - 1])
            if column < below:
                result.append(index[row + 1][column])
    return result


def matrix_for(size, modulus):
    widths, index, count = layout(size)
    matrix = [[0] * count for _ in range(count)]
    for row, width in enumerate(widths):
        for column in range(width):
            target = index[row][column]
            matrix[target][target] = 1 % modulus
            for source in sources(size, row, column, widths, index):
                matrix[target][source] = (matrix[target][source] + 1) % modulus
    return matrix, count


def simulate(size, modulus, periods, values):
    widths, index, count = layout(size)
    neighbor_lists = []
    for row, width in enumerate(widths):
        for column in range(width):
            neighbor_lists.append(sources(size, row, column, widths, index))
    state = list(values)
    for _ in range(periods):
        updated = []
        for cell in range(count):
            total = state[cell] + sum(state[source] for source in neighbor_lists[cell])
            updated.append(total % modulus)
        state = updated
    return sum(state)


def matrix_power(size, modulus, periods, values):
    base, count = matrix_for(size, modulus)

    def multiply(left, right):
        result = [[0] * count for _ in range(count)]
        for row in range(count):
            for mid in range(count):
                if left[row][mid] == 0:
                    continue
                factor = left[row][mid]
                for col in range(count):
                    if right[mid][col]:
                        result[row][col] = (result[row][col] + factor * right[mid][col]) % modulus
        return result

    state = list(values)
    exponent = periods
    while exponent:
        if exponent & 1:
            updated = [0] * count
            for mid in range(count):
                if state[mid]:
                    for col in range(count):
                        if base[mid][col]:
                            updated[col] = (updated[col] + state[mid] * base[mid][col]) % modulus
            state = updated
        exponent >>= 1
        if exponent:
            base = multiply(base, base)
    return sum(state)


def oracle(case):
    size, modulus, periods, values = case
    if periods <= 300:
        return simulate(size, modulus, periods, values)
    return matrix_power(size, modulus, periods, values)


def oracle_text(cases):
    return "".join(f"Case {number}: {oracle(case)}\n" for number, case in enumerate(cases, 1))


def input_text(cases):
    parts = []
    for size, modulus, periods, values in cases:
        parts.append(f"{size} {modulus} {periods}\n")
        widths, index, count = layout(size)
        cursor = 0
        for width in widths:
            parts.append(" ".join(str(value) for value in values[cursor:cursor + width]) + "\n")
            cursor += width
    return "".join(parts) + "0 0 0\n"


def flat(size, seed, modulus):
    rng = random.Random(seed)
    return [rng.randrange(modulus) for _ in range(3 * size * (size - 1) + 1)]


SAMPLE_VALUES = [0] * 19
SAMPLE_VALUES[0] = 1
SAMPLE_VALUES[-1] = 1
SAMPLE_CASES = [(3, 3, 1, SAMPLE_VALUES), (3, 3, 2, SAMPLE_VALUES)]
SAMPLE_IN = input_text(SAMPLE_CASES)
SAMPLE_OUT = "Case 1: 8\nCase 2: 18\n"
assert oracle(SAMPLE_CASES[0]) == 8
assert oracle(SAMPLE_CASES[1]) == 18
assert oracle((1, 2, 1, [1])) == 1
assert oracle((2, 1000000007, 3, flat(2, 7, 1000000007))) >= 0
assert oracle_text(SAMPLE_CASES) == SAMPLE_OUT


def write(name, cases):
    (ROOT / "in" / f"{name}.txt").write_text(input_text(cases))
    (ROOT / "out" / f"{name}.out").write_text(oracle_text(cases))


def build():
    write("2_edges", [(size, 2, 1, flat(size, 100 + size, 2)) for size in range(1, 7)])
    write("3_wide", [(3, 1000000007, 10 ** 9, flat(3, 11, 1000000007)),
                     (6, 1000000007, 200, flat(6, 12, 1000000007))])
    rng = random.Random(20261126)
    random_cases = []
    for number in range(12):
        size = rng.randint(1, 4)
        modulus = rng.choice([2, 3, 7, 1000000007])
        random_cases.append((size, modulus, rng.randint(1, 40), flat(size, 500 + number, modulus)))
    write("4_random", random_cases)
    io_cases = []
    for number in range(120):
        size = rng.randint(1, 3)
        modulus = rng.choice([2, 5, 1000000007])
        periods = rng.randint(1, 10)
        values = [value % modulus for value in flat(size, 900 + number, 1000000007)]
        io_cases.append((size, modulus, periods, values))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
