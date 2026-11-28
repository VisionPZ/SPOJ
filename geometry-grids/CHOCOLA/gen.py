#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_case(columns, rows, vertical, horizontal):
    descending_vertical = sorted(vertical, reverse=True)
    descending_horizontal = sorted(horizontal, reverse=True)
    left = 0
    right = 0
    vertical_pieces = 1
    horizontal_pieces = 1
    total = 0
    while left < len(descending_vertical) or right < len(descending_horizontal):
        take_vertical = left < len(descending_vertical) and (
            right == len(descending_horizontal) or
            descending_vertical[left] >= descending_horizontal[right])
        if take_vertical:
            total += descending_vertical[left] * horizontal_pieces
            vertical_pieces += 1
            left += 1
        else:
            total += descending_horizontal[right] * vertical_pieces
            horizontal_pieces += 1
            right += 1
    return total


def dp_case(columns, rows, vertical, horizontal):
    descending_vertical = sorted(vertical, reverse=True)
    descending_horizontal = sorted(horizontal, reverse=True)
    vertical_left = len(descending_vertical)
    horizontal_left = len(descending_horizontal)
    table = [[0] * (horizontal_left + 1) for _ in range(vertical_left + 1)]
    for i in range(vertical_left, -1, -1):
        for j in range(horizontal_left, -1, -1):
            if i == vertical_left and j == horizontal_left:
                table[i][j] = 0
            elif i == vertical_left:
                table[i][j] = descending_horizontal[j] * (i + 1) + table[i][j + 1]
            elif j == horizontal_left:
                table[i][j] = descending_vertical[i] * (j + 1) + table[i + 1][j]
            else:
                take_v = descending_vertical[i] * (j + 1) + table[i + 1][j]
                take_h = descending_horizontal[j] * (i + 1) + table[i][j + 1]
                table[i][j] = min(take_v, take_h)
    return table[0][0]


def brute_case(vertical, horizontal):
    moves = [('v', cost) for cost in vertical] + [('h', cost) for cost in horizontal]
    best = None
    for order in itertools.permutations(moves):
        vertical_pieces = 1
        horizontal_pieces = 1
        total = 0
        for direction, cost in order:
            if direction == 'v':
                total += cost * horizontal_pieces
                vertical_pieces += 1
            else:
                total += cost * vertical_pieces
                horizontal_pieces += 1
        if best is None or total < best:
            best = total
    return best


def build_input(cases):
    parts = [str(len(cases)), '']
    for columns, rows, vertical, horizontal in cases:
        parts.append('%d %d' % (columns, rows))
        parts.extend(str(cost) for cost in vertical)
        parts.extend(str(cost) for cost in horizontal)
        parts.append('')
    return '\n'.join(parts) + '\n'


def write(name, cases):
    input_text = build_input(cases)
    answers = [oracle_case(*case) for case in cases]
    (ROOT / 'in' / (name + '.txt')).write_text(input_text)
    (ROOT / 'out' / (name + '.out')).write_text(''.join('%d\n' % a for a in answers))


SAMPLE = (6, 4, [2, 1, 3, 1, 4], [4, 1, 2])
assert oracle_case(*SAMPLE) == 42
assert dp_case(*SAMPLE) == 42
assert oracle_case(2, 2, [5], [7]) == 17
assert oracle_case(1000, 1000, [1000] * 999, [1000] * 999) == 999999000
assert oracle_case(1000, 1000, [1] * 999, [1] * 999) == 999999

check_rng = random.Random(1234)
for trial in range(120):
    vertical = [check_rng.randint(1, 9) for _ in range(check_rng.randint(0, 3))]
    horizontal = [check_rng.randint(1, 9) for _ in range(check_rng.randint(0, 3))]
    columns = len(vertical) + 1
    rows = len(horizontal) + 1
    brute = brute_case(vertical, horizontal)
    assert dp_case(columns, rows, vertical, horizontal) == brute
    assert oracle_case(columns, rows, vertical, horizontal) == brute


def build():
    edges = [
        (2, 2, [5], [7]),
        (2, 2, [7], [5]),
        (2, 2, [1], [1]),
        (2, 1000, [999], [1] * 999),
        (1000, 2, [1] * 999, [999]),
        (1000, 1000, [1] * 999, [1] * 999),
        (1000, 1000, [1000] * 999, [1000] * 999),
    ]
    for case in edges[:5]:
        assert oracle_case(*case) == dp_case(*case)
    write('2_edges', edges)

    wide = [
        (1000, 1000, [1000] * 999, [1000] * 999),
        (1000, 1000, [1] * 999, [1] * 999),
        (1000, 1000, [1000] * 999, [1] * 999),
        (1000, 1000, [1] * 999, [1000] * 999),
        (1000, 2, [1000] * 999, [1000]),
        (2, 1000, [1000], [1000] * 999),
    ]
    write('3_wide', wide)

    random_rng = random.Random(20261124)
    randomized = []
    for _ in range(20):
        columns = random_rng.randint(2, 1000)
        rows = random_rng.randint(2, 1000)
        vertical = [random_rng.randint(1, 1000) for _ in range(columns - 1)]
        horizontal = [random_rng.randint(1, 1000) for _ in range(rows - 1)]
        randomized.append((columns, rows, vertical, horizontal))
    write('4_random', randomized)

    io_case = (1000, 1000, [1000] * 999, [1000] * 999)
    io_cases = [io_case] * 20
    write('5_io', io_cases)
    io_answers = [oracle_case(*case) for case in io_cases]
    assert all(answer == 999999000 for answer in io_answers)


def worked_example():
    descending_vertical = sorted(SAMPLE[2], reverse=True)
    descending_horizontal = sorted(SAMPLE[3], reverse=True)
    left = 0
    right = 0
    vertical_pieces = 1
    horizontal_pieces = 1
    total = 0
    print('vertical %s' % ' '.join(str(v) for v in descending_vertical))
    print('horizontal %s' % ' '.join(str(v) for v in descending_horizontal))
    while left < len(descending_vertical) or right < len(descending_horizontal):
        take_vertical = left < len(descending_vertical) and (
            right == len(descending_horizontal) or
            descending_vertical[left] >= descending_horizontal[right])
        if take_vertical:
            cost = descending_vertical[left]
            added = cost * horizontal_pieces
            total += added
            vertical_pieces += 1
            left += 1
            print('V %d x %d +%d = %d  pieces %d/%d' % (
                cost, horizontal_pieces, added, total,
                vertical_pieces, horizontal_pieces))
        else:
            cost = descending_horizontal[right]
            added = cost * vertical_pieces
            total += added
            horizontal_pieces += 1
            right += 1
            print('H %d x %d +%d = %d  pieces %d/%d' % (
                cost, vertical_pieces, added, total,
                vertical_pieces, horizontal_pieces))
    print('total %d' % total)


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
write('1_sample', [SAMPLE])
build()
worked_example()
