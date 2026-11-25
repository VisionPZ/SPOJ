#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 10**9 + 7


def simulate(sequence, window, repetitions):
    size = len(sequence)
    current = [value % MOD for value in sequence]
    for _ in range(repetitions):
        temporary = [0] * size
        for index in range(size):
            total = 0
            for offset in range(window):
                source = (index + offset) % size
                if offset % 2 == 0:
                    total += current[source]
                else:
                    total -= current[source]
            temporary[index] = total % MOD
        for index in range(0, size, 2):
            temporary[index], temporary[index + 1] = temporary[index + 1], temporary[index]
        current = temporary
    return current


def matrix_power_check(sequence, window, repetitions):
    size = len(sequence)
    transform = [[0] * size for _ in range(size)]
    for row in range(size):
        source = row ^ 1
        for column in range(size):
            offset = (column - source) % size
            if offset < window:
                transform[row][column] = 1 if offset % 2 == 0 else MOD - 1
    vector = [value % MOD for value in sequence]
    power = repetitions
    while power:
        if power % 2:
            vector = [sum(transform[row][column] * vector[column] for column in range(size)) % MOD
                      for row in range(size)]
        transform = [[sum(transform[row][middle] * transform[middle][column]
                          for middle in range(size)) % MOD
                      for column in range(size)] for row in range(size)]
        power //= 2
    return vector


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    lines = []
    for _ in range(case_count):
        size = tokens[cursor]
        window = tokens[cursor + 1]
        repetitions = tokens[cursor + 2]
        cursor += 3
        sequence = tokens[cursor:cursor + size]
        cursor += size
        lines.append(" ".join(str(value) for value in simulate(sequence, window, repetitions)))
    return "\n".join(lines) + "\n"


SAMPLE = """1
4 3 1
2 4 -3 5
"""
SAMPLE_OUT = """12 1000000002 7 1000000001
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 1 1\n1 2\n") == "2 1\n"
assert oracle("1\n2 2 3\n-1 -2\n") == "1000000003 4\n"
assert simulate([2, 4, -3, 5], 3, 1) == matrix_power_check([2, 4, -3, 5], 3, 1)
assert simulate([5, -7, 3, 1], 2, 1) == matrix_power_check([5, -7, 3, 1], 2, 1)
assert matrix_power_check([2, 4, -3, 5], 3, 0) == [2, 4, MOD - 3, 5]
assert matrix_power_check([2, 4, -3, 5], 3, 500) == simulate([2, 4, -3, 5], 3, 500)
rng = random.Random(20261126)
for _ in range(60):
    size = 2 * rng.randint(1, 4)
    sequence = [rng.randint(-1000, 1000) for _ in range(size)]
    window = rng.randint(1, size)
    repetitions = rng.randint(0, 8)
    assert simulate(sequence, window, repetitions) == matrix_power_check(sequence, window, repetitions)


def write(name, cases):
    chunks = [str(len(cases))]
    for size, window, repetitions, sequence in cases:
        chunks.append(f"{size} {window} {repetitions}")
        chunks.append(" ".join(str(value) for value in sequence))
    text = "\n".join(chunks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(2, 1, 1, [1, 2]), (2, 2, 5, [-1, -2]), (4, 1, 2, [0, 0, 0, 0]),
                      (4, 4, 7, [1000000000, -1000000000, 3, 5])])
    write("3_wide", [(50, 50, 20, [rng.randint(-10**9, 10**9) for _ in range(50)]) for _ in range(10)])
    random_cases = []
    for _ in range(40):
        size = 2 * rng.randint(1, 8)
        random_cases.append((size, rng.randint(1, size), rng.randint(0, 30),
                             [rng.randint(-10**9, 10**9) for _ in range(size)]))
    write("4_random", random_cases)
    wide_cases = []
    for _ in range(100):
        size = 50
        wide_cases.append((size, rng.randint(1, size), rng.randint(0, 30),
                           [rng.randint(-10**9, 10**9) for _ in range(size)]))
    write("5_io", wide_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(4, 3, 1, [2, 4, -3, 5])])
build()
