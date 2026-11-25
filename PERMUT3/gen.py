#!/usr/bin/env python3
import itertools
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
EULER = [1, 1]
while len(EULER) <= 100:
    index = len(EULER) - 1
    total = 0
    for split in range(index + 1):
        total += math.comb(index, split) * EULER[split] * EULER[index - split]
    EULER.append(total // 2)


def pattern_of(permutation):
    return tuple(1 if permutation[index] < permutation[index + 1] else 0
                 for index in range(len(permutation) - 1))


def brute(permutation):
    target = pattern_of(permutation)
    count = 0
    for candidate in itertools.permutations(range(1, len(permutation) + 1)):
        if pattern_of(candidate) == target:
            count += 1
    return count


def few_descents(permutation):
    size = len(permutation)
    pattern = pattern_of(permutation)
    descents = [index + 1 for index, value in enumerate(pattern) if value == 0]
    if len(descents) > 2:
        raise ValueError("pattern outside formula family")
    if not descents:
        return 1
    if len(descents) == 1:
        return math.comb(size, descents[0]) - 1
    first, second = descents
    return (math.factorial(size) // (math.factorial(first) *
            math.factorial(second - first) * math.factorial(size - second))
            - math.comb(size, first) - math.comb(size, second) + 1)


def euler_number(permutation):
    return EULER[len(permutation)]


def oracle(permutation):
    size = len(permutation)
    if size <= 8:
        return str(brute(permutation)) + "\n"
    pattern = pattern_of(permutation)
    alternating = all(pattern[index] != pattern[index + 1]
                      for index in range(len(pattern) - 1))
    if alternating:
        return str(euler_number(permutation)) + "\n"
    return str(few_descents(permutation)) + "\n"


def oracle_text(text):
    tokens = [int(token) for token in text.split()]
    cursor = 0
    answers = []
    while True:
        size = tokens[cursor]; cursor += 1
        if size == 0:
            break
        permutation = tokens[cursor:cursor + size]; cursor += size
        answers.append(oracle(permutation).rstrip("\n"))
    return "\n".join(answers) + "\n"


SAMPLE = """2
1 2
4
1 3 2 4
0
"""
SAMPLE_OUT = """1
5
"""
assert oracle_text(SAMPLE) == SAMPLE_OUT
assert oracle([1, 2, 3, 4, 5]) == "1\n"
assert EULER[10] == 50521
assert few_descents(list(range(51, 101)) + list(range(1, 51))) == math.comb(100, 50) - 1
assert oracle([2, 1, 3]) == "2\n"


def permutation_from_pattern(pattern):
    size = len(pattern) + 1
    descent_points = [index + 1 for index, value in enumerate(pattern) if value == 0]
    boundaries = [0] + descent_points + [size]
    result = [0] * size
    high = size
    for run_index in range(len(boundaries) - 1):
        start = boundaries[run_index]
        stop = boundaries[run_index + 1]
        count = stop - start
        for offset in range(count):
            result[start + offset] = high - count + 1 + offset
        high -= count
    return result


for size in range(2, 7):
    for mask in range(1 << (size - 1)):
        candidate_pattern = tuple((mask >> index) & 1 for index in range(size - 1))
        candidate = permutation_from_pattern(candidate_pattern)
        if len(pattern_of(candidate)) - sum(candidate_pattern) <= 2:
            assert oracle(candidate) == str(few_descents(candidate)) + "\n"


def write(name, cases):
    text = ""
    for permutation in cases:
        text += str(len(permutation)) + "\n"
        text += " ".join(str(value) for value in permutation) + "\n"
    text += "0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle_text(text))


def build():
    write("2_edges", [
        [1], [1, 2], [2, 1], [1, 2, 3], [3, 2, 1], [2, 1, 3], [3, 1, 2]])
    alternating = tuple(index % 2 for index in range(99))
    wide = [permutation_from_pattern(alternating)]
    for position in (1, 2, 49, 50, 98, 99):
        pattern = [1] * 99
        pattern[position - 1] = 0
        wide.append(permutation_from_pattern(tuple(pattern)))
    for first, second in ((1, 2), (20, 50), (49, 51), (98, 99)):
        pattern = [1] * 99
        pattern[first - 1] = 0
        pattern[second - 1] = 0
        wide.append(permutation_from_pattern(tuple(pattern)))
    write("3_wide", wide)
    rng = random.Random(20261126)
    random_small = []
    for _ in range(60):
        size = rng.randint(2, 9)
        chosen = rng.randint(2, min(size, 8))
        random_small.append(list(rng.sample(range(1, size + 1), chosen)))
    write("4_random", random_small)
    io_cases = []
    for _ in range(300):
        if rng.random() < 0.5:
            io_cases.append(permutation_from_pattern(alternating))
        else:
            pattern = [1] * 99
            pattern[rng.randrange(99)] = 0
            io_cases.append(permutation_from_pattern(tuple(pattern)))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [[1, 2], [1, 3, 2, 4]])
build()
