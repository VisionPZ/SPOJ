#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute(width, height, values):
    best = 0
    for mask in range(1 << (width * height)):
        occupied = [mask >> (row * width + column) & 1
                    for row in range(height) for column in range(width)]
        valid = True
        for row in range(height):
            for column in range(width):
                index = row * width + column
                if not occupied[index]:
                    continue
                if column + 1 < width and occupied[index + 1]:
                    valid = False
                if row + 1 < height and occupied[index + width]:
                    valid = False
        if not valid:
            continue
        total = sum(values[index] for index in range(width * height)
                    if occupied[index])
        best = max(best, total)
    return best


def row_masks(width):
    result = []
    for mask in range(1 << width):
        if mask & (mask << 1) == 0:
            result.append(mask)
    return result


def profile_dp(width, height, values):
    masks = row_masks(width)
    row_values = {}
    for row in range(height):
        for mask in masks:
            row_values[(row, mask)] = sum(
                values[row * width + column]
                for column in range(width) if mask >> column & 1)
    previous = {0: 0}
    for row in range(height):
        current = {}
        for mask in masks:
            row_total = row_values[(row, mask)]
            current[mask] = max(
                (score for prior, score in previous.items()
                 if prior & mask == 0), default=0) + row_total
        previous = current
    return max(previous.values())


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]; cursor += 1
    answers = []
    for case_number in range(case_count):
        width = tokens[cursor]; cursor += 1
        height = tokens[cursor]; cursor += 1
        values = tokens[cursor:cursor + width * height]
        cursor += width * height
        answers.append('Case {}: {}'.format(
            case_number + 1, profile_dp(width, height, values)))
    return ''.join(answer + '\n' for answer in answers)


SAMPLE_IN = '''2
2 2
2 3
3 5
3 2
4 1 1
2 1 4
'''
SAMPLE_OUT = '''Case 1: 7
Case 2: 8
'''
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert brute(2, 2, [2, 3, 3, 5]) == 7
assert brute(3, 2, [4, 1, 1, 2, 1, 4]) == 8
assert brute(1, 4, [7, 9, 4, 2]) == 11
assert brute(2, 3, [0, 0, 0, 0, 0, 0]) == 0
assert row_masks(3) == [0, 1, 2, 4, 5]


def write(name, cases):
    lines = [str(len(cases))]
    for width, height, values in cases:
        lines.append('{} {}'.format(width, height))
        for row in range(height):
            lines.append(' '.join(str(value) for value in
                                  values[row * width:(row + 1) * width]))
    text = '\n'.join(lines) + '\n'
    (ROOT / 'in' / '{}.txt'.format(name)).write_text(text)
    (ROOT / 'out' / '{}.out'.format(name)).write_text(oracle(text))


def build():
    write('2_edges', [
        (1, 1, [12345]),
        (1, 2, [9, 8]),
        (2, 1, [9, 8]),
        (2, 2, [0, 0, 0, 0]),
        (2, 2, [10000 - 1, 0, 0, 9999]),
    ])
    write('3_wide', [
        (10, 10, [9999 if (row + column) % 2 == 0 else 0
                  for row in range(10) for column in range(10)]),
        (10, 10, [(row * 17 + column * 31) % 10000
                  for row in range(10) for column in range(10)]),
    ])
    rng = random.Random(20261126)
    cases = []
    for _ in range(50):
        width = rng.randint(1, 10)
        height = rng.randint(1, 10)
        cases.append((width, height, [rng.randrange(10000)
                                      for _ in range(width * height)]))
    write('4_random', cases)
    cases = []
    for _ in range(400):
        width = rng.randint(8, 10)
        height = rng.randint(8, 10)
        cases.append((width, height, [rng.randrange(10000)
                                      for _ in range(width * height)]))
    write('5_io', cases)


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
(ROOT / 'in' / '1_sample.txt').write_text(SAMPLE_IN)
(ROOT / 'out' / '1_sample.out').write_text(SAMPLE_OUT)
build()
