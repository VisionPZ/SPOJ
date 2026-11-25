#!/usr/bin/env python3
import itertools
import math
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = """4
2 3 0 0 10
2 3 1 0 16
2 1
3 3 1 0 7
2 2
2 2 2 1 11
1 2
2 1
"""
SAMPLE_OUT = """1
0
1
0
"""


def enumerate_paths(rows, columns):
    paths = []

    def walk(row, column, cells):
        if row == rows and column == columns:
            paths.append(frozenset(cells))
            return
        if row < rows:
            walk(row + 1, column, cells + [(row + 1, column)])
        if column < columns:
            walk(row, column + 1, cells + [(row, column + 1)])

    walk(1, 1, [(1, 1)])
    return paths


def brute_count(rows, columns, bananas, limit, modulus):
    banana_set = frozenset(bananas)
    paths = enumerate_paths(rows, columns)
    eaten = [len(path & banana_set) for path in paths]
    answer = 0
    for first, second in itertools.combinations(range(len(paths)), 2):
        shared = paths[first] & paths[second]
        if shared != frozenset([(1, 1), (rows, columns)]):
            continue
        if eaten[first] + eaten[second] <= limit:
            answer = (answer + 1) % modulus
    return answer


def closed_count(rows, columns, bananas, limit, modulus):
    if bananas:
        raise ValueError("closed form needs zero bananas")

    def ways(start_x, start_y, end_x, end_y):
        if end_x < start_x or end_y < start_y:
            return 0
        return math.comb((end_x - start_x) + (end_y - start_y), end_x - start_x)

    first_first = ways(1, 2, rows - 1, columns)
    first_second = ways(1, 2, rows, columns - 1)
    second_first = ways(2, 1, rows - 1, columns)
    second_second = ways(2, 1, rows, columns - 1)
    return (first_first * second_second - first_second * second_first) % modulus


def transfer_count(rows, columns, bananas, limit, modulus):
    banana_set = set(bananas)
    total_steps = (rows - 1) + (columns - 1)
    state = {(1, 1): [1] + [0] * limit}
    for step in range(total_steps):
        next_state = {}
        for (row_one, row_two), counts in state.items():
            for move_one in (0, 1):
                new_one = row_one + move_one
                col_one = step + 3 - new_one
                if not (1 <= new_one <= rows and 1 <= col_one <= columns):
                    continue
                for move_two in (0, 1):
                    new_two = row_two + move_two
                    col_two = step + 3 - new_two
                    if not (1 <= new_two <= rows and 1 <= col_two <= columns):
                        continue
                    if step + 1 < total_steps:
                        if new_one >= new_two:
                            continue
                    elif new_one != rows or new_two != rows:
                        continue
                    extra = ((new_one, col_one) in banana_set) + ((new_two, col_two) in banana_set)
                    key = (new_one, new_two)
                    target = next_state.setdefault(key, [0] * (limit + 1))
                    for eaten, ways in enumerate(counts):
                        if ways and eaten + extra <= limit:
                            target[eaten + extra] = (target[eaten + extra] + ways) % modulus
        state = next_state
    return sum(state.get((rows, rows), [0])) % modulus


def oracle(text):
    tokens = text.split()
    cursor = 0
    answers = []
    case_count = int(tokens[cursor]); cursor += 1
    for _ in range(case_count):
        rows = int(tokens[cursor]); cursor += 1
        columns = int(tokens[cursor]); cursor += 1
        banana_count = int(tokens[cursor]); cursor += 1
        limit = int(tokens[cursor]); cursor += 1
        modulus = int(tokens[cursor]); cursor += 1
        bananas = []
        for _ in range(banana_count):
            x = int(tokens[cursor]); cursor += 1
            y = int(tokens[cursor]); cursor += 1
            bananas.append((x, y))
        if modulus == 1:
            answers.append("0")
            continue
        if bananas:
            if rows * columns <= 144:
                answers.append(str(transfer_count(rows, columns, bananas, limit, modulus)))
            else:
                answers.append(str(brute_count(rows, columns, bananas, limit, modulus)))
        else:
            answers.append(str(closed_count(rows, columns, bananas, limit, modulus)))
    return "\n".join(answers) + "\n" if answers else ""


assert oracle(SAMPLE) == SAMPLE_OUT
assert brute_count(2, 3, [], 0, 10) == 1
assert brute_count(3, 3, [(2, 2)], 0, 7) == 1
assert brute_count(2, 2, [(1, 2), (2, 1)], 1, 11) == 0
assert closed_count(2, 3, [], 0, 10) == 1


def write(name, cases):
    lines = [str(len(cases))]
    for rows, columns, bananas, limit, modulus in cases:
        lines.append("%d %d %d %d %d" % (rows, columns, len(bananas), limit, modulus))
        for x, y in bananas:
            lines.append("%d %d" % (x, y))
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def random_case(rng, rows, columns, modulus=None):
    cells = [(x, y) for x in range(1, rows + 1)
             for y in range(1, columns + 1)
             if (x, y) not in [(1, 1), (rows, columns)]]
    count = rng.randint(0, min(6, len(cells)))
    bananas = rng.sample(cells, count)
    limit = rng.randint(0, len(bananas))
    if modulus is None:
        modulus = rng.choice([1, 2, 7, 10, 16, 97, 1000000007, 100])
    return rows, columns, bananas, limit, modulus


def build():
    rng = random.Random(20261126)
    edges = [(2, 2, [], 0, 1), (2, 2, [], 0, 10),
             (2, 2, [(1, 2), (2, 1)], 1, 11),
             (2, 2, [(1, 2), (2, 1)], 2, 11),
             (2, 3, [(2, 1)], 0, 16), (2, 3, [(2, 2)], 1, 10),
             (3, 2, [(1, 2)], 2, 10), (3, 3, [(2, 2)], 1, 7)]
    write("2_edges", edges)
    wide = [(rng.randint(2, 100000), rng.randint(2, 100000), [], 0,
             rng.choice([1, 10, 1000000007, 65536, 100]))
            for _ in range(40)]
    write("3_wide", wide)
    random_cases = [random_case(rng, rng.randint(2, 5), rng.randint(2, 5))
                    for _ in range(25)]
    write("4_random", random_cases)
    many = [random_case(rng, rng.randint(2, 4), rng.randint(2, 4))
            for _ in range(120)]
    write("5_io", many)


if "--trace" in sys.argv:
    print("2x3", brute_count(2, 3, [], 0, 10))
    print("3x3 center", brute_count(3, 3, [(2, 2)], 0, 7))
    print("2x2 two bananas", brute_count(2, 2, [(1, 2), (2, 1)], 1, 11))
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [(2, 3, [], 0, 10), (2, 3, [(2, 1)], 0, 16),
                       (3, 3, [(2, 2)], 0, 7),
                       (2, 2, [(1, 2), (2, 1)], 1, 11)])
    build()
