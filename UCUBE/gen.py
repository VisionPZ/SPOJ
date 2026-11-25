#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def view_to_cell(side, row, col, depth, size):
    if side == 0:
        return (col, size - 1 - row, depth)
    if side == 1:
        return (depth, size - 1 - row, size - 1 - col)
    if side == 2:
        return (size - 1 - col, size - 1 - row, size - 1 - depth)
    if side == 3:
        return (size - 1 - depth, size - 1 - row, col)
    if side == 4:
        return (col, size - 1 - depth, size - 1 - row)
    return (col, depth, row)


def cell_index(x, y, z, size):
    return (x * size + y) * size + z


def render_views(cells, size):
    views = []
    for side in range(6):
        plane = []
        for row in range(size):
            line = []
            for col in range(size):
                seen = '.'
                for depth in range(size):
                    x, y, z = view_to_cell(side, row, col, depth, size)
                    color = cells[cell_index(x, y, z, size)]
                    if color is not None:
                        seen = color
                        break
                line.append(seen)
            plane.append(line)
        views.append(plane)
    return views


def format_case(size, views):
    rows = []
    for row in range(size):
        rows.append(' '.join(''.join(views[side][row])
                            for side in range(6)))
    return str(size) + '\n' + '\n'.join(rows) + '\n'


def oracle(size, views):
    surviving = [True] * (size * size * size)
    for side in range(6):
        for row in range(size):
            for col in range(size):
                if views[side][row][col] != '.':
                    continue
                for depth in range(size):
                    x, y, z = view_to_cell(side, row, col, depth, size)
                    surviving[cell_index(x, y, z, size)] = False
    while True:
        demands = [set() for _ in surviving]
        for side in range(6):
            for row in range(size):
                for col in range(size):
                    wanted = views[side][row][col]
                    if wanted == '.':
                        continue
                    for depth in range(size):
                        x, y, z = view_to_cell(side, row, col, depth, size)
                        position = cell_index(x, y, z, size)
                        if surviving[position]:
                            demands[position].add(wanted)
                            break
        changed = False
        for position in range(size * size * size):
            if surviving[position] and len(demands[position]) > 1:
                surviving[position] = False
                changed = True
        if not changed:
            return sum(surviving)


def brute_force(size, views):
    best = 0
    total = size * size * size
    for mask in range(1 << total):
        present = [(mask >> position) & 1 for position in range(total)]
        demands = [set() for _ in range(total)]
        valid = True
        for side in range(6):
            for row in range(size):
                for col in range(size):
                    wanted = views[side][row][col]
                    front = -1
                    for depth in range(size):
                        x, y, z = view_to_cell(side, row, col, depth, size)
                        position = cell_index(x, y, z, size)
                        if present[position]:
                            front = position
                            break
                    if wanted == '.':
                        if front != -1:
                            valid = False
                    elif front == -1:
                        valid = False
                    else:
                        demands[front].add(wanted)
        if valid and all(len(group) <= 1 for group in demands):
            count = sum(present)
            if count > best:
                best = count
    return best


def constant_cells(size, color):
    return [color] * (size * size * size)


def checker_case(size):
    cells = [None] * (size * size * size)
    cells[cell_index(0, 0, 1, size)] = 'A'
    cells[cell_index(1, 0, 0, size)] = 'B'
    cells[cell_index(0, 1, 0, size)] = 'C'
    return cells


def write(name, cases):
    input_text = str(len(cases)) + '\n' + ''.join(
        format_case(size, views) for size, views in cases)
    answers = [str(oracle(size, views)) for size, views in cases]
    (ROOT / 'in' / (name + '.txt')).write_text(input_text)
    (ROOT / 'out' / (name + '.out')).write_text('\n'.join(answers) + '\n')
    return answers


SAMPLE_INPUT = (
    '2\n'
    '3\n'
    '.R. YYR .Y. RYY .Y. .R.\n'
    'GRB YGR BYG RBY GYB GRB\n'
    '.R. YRR .Y. RRY .R. .Y.\n'
    '2\n'
    'ZZ ZZ ZZ ZZ ZZ ZZ\n'
    'ZZ ZZ ZZ ZZ ZZ ZZ\n')

SAMPLE_OUTPUT = '11\n8\n'

sample_views = [
    [['.R.', 'GRB', '.R.'], ['YYR', 'YGR', 'YRR'], ['.Y.', 'BYG', '.Y.'],
     ['RYY', 'RBY', 'RRY'], ['.Y.', 'GYB', '.R.'], ['.R.', 'GRB', '.Y.']],
    [['ZZ', 'ZZ'], ['ZZ', 'ZZ'], ['ZZ', 'ZZ'], ['ZZ', 'ZZ'],
     ['ZZ', 'ZZ'], ['ZZ', 'ZZ']]]

assert oracle(3, sample_views[0]) == 11
assert oracle(2, sample_views[1]) == 8
assert oracle(3, render_views(constant_cells(3, 'Z'), 3)) == 27
assert oracle(4, render_views([None] * 64, 4)) == 0

checker_views = render_views(checker_case(2), 2)
assert oracle(2, checker_views) == 3
assert brute_force(2, checker_views) == 3

verification_rng = random.Random(31415)
for trial in range(40):
    trial_size = verification_rng.choice([1, 2])
    trial_cells = [None if verification_rng.random() < 0.5
                   else verification_rng.choice('ABCD')
                   for _ in range(trial_size ** 3)]
    trial_views = render_views(trial_cells, trial_size)
    assert oracle(trial_size, trial_views) == brute_force(trial_size, trial_views)

(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
(ROOT / 'in' / '1_sample.txt').write_text(SAMPLE_INPUT)
(ROOT / 'out' / '1_sample.out').write_text(SAMPLE_OUTPUT)

edge_configs = [
    (1, constant_cells(1, 'A')),
    (1, [None]),
    (2, constant_cells(2, 'Z')),
    (2, [None] * 8),
    (2, checker_case(2)),
    (3, constant_cells(3, 'Q')),
    (3, [None] * 27),
    (10, constant_cells(10, 'M')),
    (10, [None] * 1000),
]
for position in [(0, 0, 0), (1, 1, 1), (2, 0, 2), (0, 2, 1)]:
    single = [None] * 27
    single[cell_index(*position, 3)] = 'D'
    edge_configs.append((3, single))
write('2_edges', [(size, render_views(cells, size)) for size, cells in edge_configs])

wide_cases = []
for case_number, density in enumerate((1.0, 0.85, 0.5, 0.15, 0.0)):
    case_rng = random.Random(700 + case_number)
    cells = [None if case_rng.random() > density else case_rng.choice('ABCDEFGH')
             for _ in range(1000)]
    wide_cases.append((10, render_views(cells, 10)))
write('3_wide', wide_cases)

rng = random.Random(20261125)
random_cases = []
for _ in range(24):
    size = rng.randint(1, 10)
    density = rng.uniform(0.05, 1.0)
    cells = [None if rng.random() > density else rng.choice('ABCDEFGH')
             for _ in range(size ** 3)]
    random_cases.append((size, render_views(cells, size)))
write('4_random', random_cases)

io_cases = []
for position in range(100000):
    size = 1
    color = 'A' if position % 3 else None
    io_cases.append((size, render_views([color], size)))
write('5_io', io_cases)

print('generated five test pairs')
