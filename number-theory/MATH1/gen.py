import itertools
import random
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent
INF = 10 ** 9


def costs_at_levels(values, first_level, second_level):
    levels = np.array([first_level, second_level], dtype=np.int64)
    current = np.zeros((1, 2), dtype=np.int64)
    low_backlog = 0
    for step in values:
        new_low = low_backlog + step - 1
        length = current.shape[0] + 1
        best = np.empty((length, 2), dtype=np.int64)
        best[:-1] = current
        best[-1] = INF
        best[1:] = np.minimum(best[1:], current)
        offsets = np.arange(length, dtype=np.int64).reshape(-1, 1)
        current = best + np.abs(new_low + offsets - levels.reshape(1, 2))
        low_backlog = new_low
    return int(current[-low_backlog, 0]), int(current[-low_backlog, 1])


def cost_at_level(values, level):
    return costs_at_levels(values, level, level + 1)[0]


def oracle_case(values):
    prefix = 0
    low_level = 0
    high_level = 0
    for index, value in enumerate(values):
        prefix += value
        low_level = min(low_level, prefix - index - 1)
        high_level = max(high_level, prefix)
    while low_level < high_level:
        middle = (low_level + high_level) // 2
        here, after = costs_at_levels(values, middle, middle + 1)
        if after >= here:
            high_level = middle
        else:
            low_level = middle + 1
    return cost_at_level(values, low_level)


def brute_case(values):
    count = len(values)
    ones_total = sum(values)
    best = INF
    for chosen in itertools.combinations(range(count), ones_total):
        served = [0] * count
        for position in chosen:
            served[position] = 1
        backlog = 0
        heights = []
        for index in range(count):
            backlog += values[index] - served[index]
            heights.append(backlog)
        assert backlog == 0
        heights.sort()
        if count % 2:
            median = heights[count // 2]
        else:
            median = (heights[count // 2 - 1] + heights[count // 2]) // 2
        total = 0
        for height in heights:
            total += abs(height - median)
        if total < best:
            best = total
    return best


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        count = int(tokens[cursor])
        cursor += 1
        values = []
        for _ in range(count):
            values.append(int(tokens[cursor]))
            cursor += 1
        answers.append(str(oracle_case(values)))
    return "\n".join(answers) + "\n"


def write_case(name, cases):
    pieces = [str(len(cases)), "\n"]
    for values in cases:
        pieces.append(str(len(values)))
        pieces.append("\n")
        pieces.append(" ".join(str(value) for value in values))
        pieces.append("\n")
    input_text = "".join(pieces)
    (ROOT / "in" / (name + ".txt")).write_text(input_text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(input_text))


assert brute_case([2, 1, 0, 0]) == 1
assert brute_case([0, 1, 2, 2, 0]) == 3
assert oracle_case([1] * 10) == 0
assert oracle_case([8] + [0] * 7) == 16
assert oracle_case([0, 0, 0, 0, 0]) == 0
check_seed = random.Random(77)
for _ in range(160):
    size = check_seed.randint(1, 8)
    candidate = [check_seed.randint(0, size) for _ in range(size)]
    if sum(candidate) > size:
        continue
    assert oracle_case(candidate) == brute_case(candidate), candidate

SAMPLE = [[2, 1, 0, 0], [0, 1, 2, 2, 0]]

EDGES = [
    [0],
    [1],
    [2, 0],
    [0, 0, 0, 0, 0],
    [1, 1, 1, 1, 1],
    [6, 0, 0, 0, 0, 0],
    [0, 1, 2, 2, 0],
    [3, 0, 0, 2, 0, 1, 0],
]

WIDE = [
    [1000] + [0] * 999,
    [1] * 1000,
    [0] * 1000,
    [0] * 999 + [1],
    [2] * 500 + [0] * 500,
    [0] * 500 + [2] * 500,
]

rng = random.Random(20261125)
RANDOM = []
for _ in range(10):
    size = rng.randint(1, 1000)
    budget = rng.randint(0, size)
    values = [0] * size
    for _ in range(budget):
        position = rng.randrange(size)
        values[position] += 1
    RANDOM.append(values)

IO_CASES = []
for _ in range(20):
    size = 1000
    values = [0] * size
    for _ in range(size):
        position = rng.randrange(size)
        values[position] += 1
    IO_CASES.append(values)

(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_case("1_sample", SAMPLE)
write_case("2_edges", EDGES)
write_case("3_wide", WIDE)
write_case("4_random", RANDOM)
write_case("5_io", IO_CASES)
