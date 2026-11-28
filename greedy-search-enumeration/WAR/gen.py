#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while cursor < len(tokens):
        state_count = tokens[cursor]
        segment_count = tokens[cursor + 1]
        cursor += 2
        if state_count == 0 and segment_count == 0:
            break
        capitals = []
        for _ in range(state_count):
            capitals.append((tokens[cursor], tokens[cursor + 1]))
            cursor += 2
        segments = []
        for _ in range(segment_count):
            segments.append(tuple(tokens[cursor:cursor + 4]))
            cursor += 4
        all_x = [value for segment in segments for value in (segment[0], segment[2])]
        all_y = [value for segment in segments for value in (segment[1], segment[3])]
        low_x, high_x = min(all_x), max(all_x)
        low_y, high_y = min(all_y), max(all_y)
        blocked_vertical = set()
        blocked_horizontal = set()
        for first_x, first_y, second_x, second_y in segments:
            if first_x == second_x:
                lower, upper = sorted((first_y, second_y))
                for coordinate in range(lower, upper):
                    blocked_vertical.add((first_x, coordinate))
            else:
                lower, upper = sorted((first_x, second_x))
                for coordinate in range(lower, upper):
                    blocked_horizontal.add((coordinate, first_y))
        labels = {}
        for capital_index, (capital_x, capital_y) in enumerate(capitals, 1):
            start = (capital_x, capital_y)
            if start in labels:
                continue
            labels[start] = capital_index
            queue = deque([start])
            while queue:
                cell_x, cell_y = queue.popleft()
                neighbours = (
                    (cell_x + 1, cell_y, (cell_x + 1, cell_y) in blocked_vertical),
                    (cell_x - 1, cell_y, (cell_x, cell_y) in blocked_vertical),
                    (cell_x, cell_y + 1, (cell_x, cell_y + 1) in blocked_horizontal),
                    (cell_x, cell_y - 1, (cell_x, cell_y) in blocked_horizontal),
                )
                for next_x, next_y, blocked in neighbours:
                    if blocked or not (low_x <= next_x < high_x and low_y <= next_y < high_y):
                        continue
                    if (next_x, next_y) not in labels:
                        labels[(next_x, next_y)] = capital_index
                        queue.append((next_x, next_y))
        enemies = [set() for _ in range(state_count + 1)]
        for first_x, first_y, second_x, second_y in segments:
            if first_x == second_x:
                middle = (first_y + second_y) // 2
                sample_a = (first_x - 1 + 0.25, middle + 0.5)
                sample_b = (first_x + 0.25, middle + 0.5)
            else:
                middle = (first_x + second_x) // 2
                sample_a = (middle + 0.5, first_y - 1 + 0.25)
                sample_b = (middle + 0.5, first_y + 0.25)
            first_owner = labels.get((int(sample_a[0]), int(sample_a[1])), 0)
            second_owner = labels.get((int(sample_b[0]), int(sample_b[1])), 0)
            if first_owner > 0 and second_owner > 0 and first_owner != second_owner:
                enemies[first_owner].add(second_owner)
                enemies[second_owner].add(first_owner)
        answers.append('\n'.join(
            str(len(enemies[index])) + ' ' + ' '.join(str(value) for value in sorted(enemies[index]))
            if enemies[index] else '0'
            for index in range(1, state_count + 1)))
    return '\n'.join(answers) + '\n'


SAMPLE = """4 12
3 2
11 8
12 17
1 19
0 0 10 0
10 0 20 0
20 0 20 10
20 10 20 20
20 20 10 20
10 20 0 20
0 20 0 10
0 10 0 0
10 0 10 10
0 10 10 10
20 10 10 10
10 20 10 10
4 16
170 13
24 88
152 49
110 130
60 60 140 60
140 60 140 140
140 140 60 140
60 140 60 60
0 0 200 0
200 0 200 200
200 200 0 200
0 200 0 0
40 40 160 40
160 40 160 160
160 160 40 160
40 160 40 40
20 20 180 20
180 20 180 180
180 180 20 180
20 180 20 20
0 0
"""
SAMPLE_OUT = """2 2 4
2 1 3
2 2 4
2 1 3
1 2
2 1 3
2 2 4
1 3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 4\n1 1\n0 0 4 0\n4 0 4 4\n4 4 0 4\n0 4 0 0\n0 0\n") == "0\n"
assert oracle("2 5\n1 1\n3 1\n0 0 4 0\n4 0 4 2\n4 2 0 2\n0 2 0 0\n2 0 2 2\n0 0\n") == "1 2\n1 1\n"


def grid_case(rows, columns, rng, fraction=1.0):
    vertical_lines = [column for column in range(1, columns)
                      if rng.random() < fraction]
    horizontal_lines = [row for row in range(1, rows)
                        if rng.random() < fraction]
    segments = []
    for column in [0, columns] + vertical_lines:
        for row in range(rows):
            segments.append((2 * column, 2 * row, 2 * column, 2 * row + 2))
    for row in [0, rows] + horizontal_lines:
        for column in range(columns):
            segments.append((2 * column, 2 * row, 2 * column + 2, 2 * row))
    seen = set()
    capitals = []
    for row in range(rows):
        for column in range(columns):
            if (row, column) in seen:
                continue
            queue = deque([(row, column)])
            seen.add((row, column))
            components = [(row, column)]
            while queue:
                current_row, current_column = queue.popleft()
                neighbours = []
                if current_column > 0 and current_column - 1 not in vertical_lines:
                    neighbours.append((current_row, current_column - 1))
                if current_column + 1 < columns and current_column + 1 not in vertical_lines:
                    neighbours.append((current_row, current_column + 1))
                if current_row > 0 and current_row - 1 not in horizontal_lines:
                    neighbours.append((current_row - 1, current_column))
                if current_row + 1 < rows and current_row + 1 not in horizontal_lines:
                    neighbours.append((current_row + 1, current_column))
                for neighbour in neighbours:
                    if neighbour not in seen:
                        seen.add(neighbour)
                        queue.append(neighbour)
                        components.append(neighbour)
            representative = min(components)
            capitals.append((2 * representative[1] + 1, 2 * representative[0] + 1))
    rng.shuffle(capitals)
    return capitals, segments


def nested_case(depth):
    segments = []
    capitals = []
    for level in range(depth):
        low = 2 * level
        high = 2 * (2 * depth - level)
        segments.extend([(low, low, high, low), (high, low, high, high),
                         (high, high, low, high), (low, high, low, low)])
        capitals.append((2 * level + 1, 2 * level + 1))
    return capitals, segments


def guillotine_case(rng):
    return grid_case(12, 16, rng, 0.45)


def write(name, blocks):
    lines = []
    for capitals, segments in blocks:
        lines.append(str(len(capitals)) + ' ' + str(len(segments)))
        for capital_x, capital_y in capitals:
            lines.append(str(capital_x) + ' ' + str(capital_y))
        for first_x, first_y, second_x, second_y in segments:
            lines.append(f'{first_x} {first_y} {second_x} {second_y}')
    lines.append('0 0')
    text = '\n'.join(lines) + '\n'
    (ROOT / 'in' / (name + '.txt')).write_text(text)
    (ROOT / 'out' / (name + '.out')).write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write('2_edges', [([(1, 1)], [(0, 0, 4, 0), (4, 0, 4, 4), (4, 4, 0, 4), (0, 4, 0, 0)]),
                      grid_case(1, 2, rng)])
    write('3_wide', [nested_case(8), grid_case(10, 20, rng)])
    write('4_random', [guillotine_case(rng) for _ in range(6)])
    write('5_io', [grid_case(20, 30, rng), nested_case(12)])
    stress = [grid_case(20, 30, rng) for _ in range(10)]
    write('/tmp/WAR_big', stress)


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
(ROOT / 'in' / '1_sample.txt').write_text(SAMPLE)
(ROOT / 'out' / '1_sample.out').write_text(oracle(SAMPLE))
build()
