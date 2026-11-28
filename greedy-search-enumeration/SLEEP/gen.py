#!/usr/bin/env python3
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

ORDER = ((0, 1, 2), (7, 6, 3), (8, 5, 4))
TRANS = ((1, 1, 0), (2, 2, 0), (0, 3, 0))
MOVES = {'E': (1, 0), 'W': (-1, 0), 'N': (0, 1), 'S': (0, -1)}
POW3 = [3 ** i for i in range(61)]
POW9 = [9 ** i for i in range(61)]


def step_index(level_count, x, y):
    result = 0
    for level in range(level_count - 1, -1, -1):
        block = POW3[level]
        col = (x - 1) // block
        row = (y - 1) // block
        result += ORDER[row][col] * POW9[level]
        local_x = x - col * block
        local_y = y - row * block
        transform = TRANS[row][col]
        if transform == 0:
            x, y = local_x, local_y
        elif transform == 1:
            x, y = local_y, local_x
        elif transform == 2:
            x, y = block - local_y + 1, block - local_x + 1
        else:
            x, y = block - local_x + 1, block - local_y + 1
    return result


def renamed(word, table):
    return ''.join(table[ch] for ch in word)


TABLE_A = {'E': 'N', 'N': 'E', 'W': 'S', 'S': 'W'}
TABLE_B = {'E': 'S', 'S': 'E', 'W': 'N', 'N': 'W'}
TABLE_C = {'E': 'W', 'W': 'E', 'N': 'S', 'S': 'N'}


def path_index(level_count):
    word = 'EENNWSWN'
    for _ in range(1, level_count):
        first = renamed(word, TABLE_A)
        second = renamed(word, TABLE_B)
        third = renamed(word, TABLE_C)
        word = (first + 'E' + first + 'E' + word + 'N' + word + 'N' +
                word + 'W' + third + 'S' + second + 'W' + second + 'N' + word)
    assert len(word) == POW9[level_count] - 1
    x, y = 1, 1
    visited = {}
    for step, ch in enumerate(word):
        visited[(x, y)] = step
        dx, dy = MOVES[ch]
        x += dx
        y += dy
    visited[(x, y)] = len(word)
    assert (x, y) == (1, POW3[level_count])
    assert len(visited) == POW9[level_count]
    return visited


def trace_digits(level_count, x, y):
    digits = []
    for level in range(level_count - 1, -1, -1):
        block = POW3[level]
        col = (x - 1) // block
        row = (y - 1) // block
        digits.append(ORDER[row][col])
        local_x = x - col * block
        local_y = y - row * block
        transform = TRANS[row][col]
        if transform == 0:
            x, y = local_x, local_y
        elif transform == 1:
            x, y = local_y, local_x
        elif transform == 2:
            x, y = block - local_y + 1, block - local_x + 1
        else:
            x, y = block - local_x + 1, block - local_y + 1
    return digits


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(count):
        level_count = int(tokens[cursor])
        start_x = int(tokens[cursor + 1])
        start_y = int(tokens[cursor + 2])
        hole_x = int(tokens[cursor + 3])
        hole_y = int(tokens[cursor + 4])
        cursor += 5
        start_step = step_index(level_count, start_x, start_y)
        hole_step = step_index(level_count, hole_x, hole_y)
        answers.append(str(hole_step - start_step))
    return '\n'.join(answers) + '\n'


def write(name, cases, blank=False):
    chunks = [str(len(cases)) + '\n']
    for level_count, start_x, start_y, hole_x, hole_y in cases:
        chunks.append('%d\n%d %d\n%d %d\n' %
                      (level_count, start_x, start_y, hole_x, hole_y))
        if blank:
            chunks.append('\n')
    input_text = ''.join(chunks)
    (ROOT / 'in' / (name + '.txt')).write_text(input_text)
    (ROOT / 'out' / (name + '.out')).write_text(oracle(input_text))


def ordered(level_count, start, hole):
    if step_index(level_count, *start) > step_index(level_count, *hole):
        return (level_count, hole[0], hole[1], start[0], start[1])
    return (level_count, start[0], start[1], hole[0], hole[1])


SAMPLE = '1\n2\n3 2\n7 2\n'
assert oracle(SAMPLE) == '20\n'
assert step_index(1, 1, 1) == 0
assert step_index(1, 1, 3) == 8
assert step_index(2, 3, 2) == 5
assert step_index(2, 7, 2) == 25
assert step_index(60, 1, POW3[60]) == POW9[60] - 1
for level in range(1, 5):
    visited = path_index(level)
    limit = POW3[level]
    for pos_x in range(1, limit + 1):
        for pos_y in range(1, limit + 1):
            assert visited[(pos_x, pos_y)] == step_index(level, pos_x, pos_y)


def build():
    (ROOT / 'in').mkdir(exist_ok=True)
    (ROOT / 'out').mkdir(exist_ok=True)
    (ROOT / 'in' / '1_sample.txt').write_text(SAMPLE)
    (ROOT / 'out' / '1_sample.out').write_text(oracle(SAMPLE))

    big = POW3[60]
    edges = [
        ordered(1, (1, 1), (1, 1)),
        ordered(1, (1, 1), (3, 3)),
        ordered(1, (1, 1), (1, 3)),
        ordered(2, (1, 1), (1, 9)),
        ordered(2, (3, 2), (7, 2)),
        ordered(3, (1, 27), (1, 27)),
        ordered(3, (1, 1), (1, 27)),
        ordered(3, (27, 27), (1, 27)),
        ordered(60, (1, 1), (1, big)),
    ]
    write('2_edges', edges, blank=True)

    wide = []
    for level in (60, 59, 58, 40, 36, 20):
        limit = POW3[level]
        corners = [(1, 1), (limit, 1), (1, limit), (limit, limit)]
        for start in corners:
            for hole in corners:
                wide.append(ordered(level, start, hole))
    write('3_wide', wide)

    rng = random.Random(20261124)
    random_cases = []
    for _ in range(200):
        level = rng.randint(1, 60)
        limit = POW3[level]
        start = (rng.randint(1, limit), rng.randint(1, limit))
        hole = (rng.randint(1, limit), rng.randint(1, limit))
        random_cases.append(ordered(level, start, hole))
    write('4_random', random_cases)

    io_cases = []
    for _ in range(100000):
        limit = POW3[60]
        start = (rng.randint(1, limit), rng.randint(1, limit))
        hole = (rng.randint(1, limit), rng.randint(1, limit))
        if step_index(60, *start) > step_index(60, *hole):
            start, hole = hole, start
        io_cases.append((60, start[0], start[1], hole[0], hole[1]))
    write('5_io', io_cases)


def example():
    start_digits = trace_digits(2, 3, 2)
    hole_digits = trace_digits(2, 7, 2)
    start_step = int(''.join(str(d) for d in start_digits), 9)
    hole_step = int(''.join(str(d) for d in hole_digits), 9)
    print('start (3,2): base-9 digits %s -> %d' % (start_digits, start_step))
    print('hole  (7,2): base-9 digits %s -> %d' % (hole_digits, hole_step))
    print('steps: %d - %d = %d' % (hole_step, start_step, hole_step - start_step))


if '--example' in sys.argv:
    example()
else:
    build()
