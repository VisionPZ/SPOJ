#!/usr/bin/env python3
import math
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SUCCESS = "The shortest path is {} steps long."
FAILURE = "Mission impossible!"


def direct_visibility(terrain, source_row, source_col, target_row, target_col):
    rows = len(terrain)
    cols = len(terrain[0])
    if source_row == target_row and source_col == target_col:
        return True
    source_z = 2 * terrain[source_row][source_col] + 1
    target_z = 2 * terrain[target_row][target_col] + 1
    col_gap = target_col - source_col
    row_gap = target_row - source_row
    steps = math.gcd(abs(col_gap), abs(row_gap))
    dir_col = col_gap // steps
    dir_row = row_gap // steps
    step_x = 2 * abs(dir_col) if dir_col != 0 else 1
    step_y = 2 * abs(dir_row) if dir_row != 0 else 1
    scale = step_x * step_y
    final_cross = steps * scale
    infinite = 1 << 60
    cross_x = step_y if dir_col != 0 else infinite
    cross_y = step_x if dir_row != 0 else infinite
    advance_x = 2 * step_y
    advance_y = 2 * step_x
    sign_x = 1 if dir_col > 0 else -1
    sign_y = 1 if dir_row > 0 else -1
    current_row = source_row
    current_col = source_col
    previous_cross = 0
    slope = target_z - source_z
    while True:
        next_cross = min(cross_x, cross_y, final_cross)
        cell_top = 2 * terrain[current_row][current_col]
        lowest_cross = previous_cross if slope >= 0 else next_cross
        if (source_z - cell_top) * final_cross + slope * lowest_cross < 0:
            return False
        if next_cross == final_cross:
            break
        if cross_x == next_cross:
            current_col += sign_x
            cross_x += advance_x
        if cross_y == next_cross:
            current_row += sign_y
            cross_y += advance_y
        previous_cross = next_cross
    return True


def shortest_path(terrain, first_row, first_col, second_row, second_col):
    rows = len(terrain)
    cols = len(terrain[0])
    good = [[False] * cols for _ in range(rows)]
    for row in range(rows):
        for col in range(cols):
            if direct_visibility(terrain, first_row, first_col, row, col) or \
               direct_visibility(terrain, second_row, second_col, row, col):
                good[row][col] = True
    start = (first_row, first_col)
    goal = (second_row, second_col)
    if start == goal:
        return 0
    queue = deque([start])
    distance = {start: 0}
    while queue:
        row, col = queue.popleft()
        current_distance = distance[(row, col)]
        for neighbor_row, neighbor_col in ((row - 1, col), (row + 1, col),
                                            (row, col - 1), (row, col + 1)):
            if not (0 <= neighbor_row < rows and 0 <= neighbor_col < cols):
                continue
            if (neighbor_row, neighbor_col) in distance:
                continue
            if not good[neighbor_row][neighbor_col]:
                continue
            gap = terrain[neighbor_row][neighbor_col] - terrain[row][col]
            if gap > 1 or gap < -3:
                continue
            distance[(neighbor_row, neighbor_col)] = current_distance + 1
            if (neighbor_row, neighbor_col) == goal:
                return current_distance + 1
            queue.append((neighbor_row, neighbor_col))
    return None


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        rows = int(tokens[cursor])
        cols = int(tokens[cursor + 1])
        cursor += 2
        terrain = []
        for _ in range(rows):
            terrain.append([int(tokens[cursor + index]) for index in range(cols)])
            cursor += cols
        first_row = int(tokens[cursor]) - 1
        first_col = int(tokens[cursor + 1]) - 1
        second_row = int(tokens[cursor + 2]) - 1
        second_col = int(tokens[cursor + 3]) - 1
        cursor += 4
        result = shortest_path(terrain, first_row, first_col, second_row, second_col)
        answers.append(FAILURE if result is None else SUCCESS.format(result))
    return "\n".join(answers) + "\n" if answers else ""


def format_case(terrain, first, second):
    rows = len(terrain)
    cols = len(terrain[0])
    lines = [f"{rows} {cols}"]
    lines.extend(" ".join(str(value) for value in row) for row in terrain)
    lines.append(f"{first[0]} {first[1]} {second[0]} {second[1]}")
    return "\n".join(lines) + "\n"


SAMPLE_IN = """4
5 5
8 7 6 5 4
2 2 2 2 2
2 2 2 2 2
2 2 2 2 2
2 2 2 2 2
1 1 5 1
5 8
2 2 2 2 2 2 2 2
2 2 2 2 2 2 2 2
2 2 2 2 2 2 2 2
9 9 9 9 9 9 9 2
2 2 2 2 2 2 2 2
1 2 5 1
5 8
2 2 2 2 2 2 2 2
2 2 2 2 2 2 2 2
2 2 2 2 2 2 2 2
9 9 9 9 9 9 9 2
2 2 2 2 2 2 2 2
1 5 5 1
6 12
5 5 5 5 1 5 5 5 5 5 5 5
5 5 5 5 1 5 5 5 5 5 5 5
5 5 5 5 9 5 5 5 5 5 5 5
5 9 1 5 5 5 5 5 5 5 5 5
5 5 9 5 5 5 5 5 5 5 5 5
5 5 9 5 5 5 5 5 5 5 5 5
6 1 3 12
"""

SAMPLE_OUT = """The shortest path is 10 steps long.
Mission impossible!
The shortest path is 14 steps long.
The shortest path is 18 steps long.
"""


def write_case(name, input_text, expected=None):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(
        oracle(input_text) if expected is None else expected)


assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert shortest_path([[0]], 0, 0, 0, 0) == 0
assert shortest_path([[0, 0]], 0, 0, 0, 1) == 1
assert shortest_path([[0, 4]], 0, 0, 0, 1) is None
assert shortest_path([[0, 1, 2]], 0, 0, 0, 2) == 2

write_case("1_sample", SAMPLE_IN, SAMPLE_OUT)

edge_parts = []
edge_text = ""
edge_cases = [
    ([[7]], (1, 1), (1, 1)),
    ([[0, 0]], (1, 1), (1, 2)),
    ([[0, 4]], (1, 1), (1, 2)),
    ([[5, 2]], (1, 1), (1, 2)),
    ([[0, 0], [0, 0]], (1, 1), (2, 2)),
    ([[9, 9, 9], [9, 9, 9], [9, 9, 9]], (1, 1), (3, 3)),
    ([[0, 3, 0]], (1, 1), (1, 3)),
    ([[0, 1, 2, 3, 4]], (1, 1), (1, 5)),
    ([[4, 3, 2, 1, 0]], (1, 1), (1, 5)),
    ([[0, 0, 5, 0, 0]], (1, 1), (1, 5)),
]
edge_text = str(len(edge_cases)) + "\n" + "".join(
    format_case(terrain, first, second) for terrain, first, second in edge_cases)
write_case("2_edges", edge_text)

wide_cases = []
flat = [[0] * 200 for _ in range(200)]
wide_cases.append((flat, (1, 1), (200, 200)))
high = [[5000] * 200 for _ in range(200)]
wide_cases.append((high, (1, 200), (200, 1)))
wide_text = str(len(wide_cases)) + "\n" + "".join(
    format_case(terrain, first, second) for terrain, first, second in wide_cases)
write_case("3_wide", wide_text)

random_gen = random.Random(20201123)
random_cases = []
for _ in range(12):
    rows = random_gen.randint(2, 18)
    cols = random_gen.randint(2, 18)
    terrain = [[random_gen.randint(0, 12) for _ in range(cols)] for _ in range(rows)]
    first = (random_gen.randint(1, rows), random_gen.randint(1, cols))
    second = (random_gen.randint(1, rows), random_gen.randint(1, cols))
    random_cases.append((terrain, first, second))
random_text = str(len(random_cases)) + "\n" + "".join(
    format_case(terrain, first, second) for terrain, first, second in random_cases)
write_case("4_random", random_text)

io_cases = []
for index in range(500):
    if index % 3 == 0:
        terrain = [[index % 127]]
    elif index % 3 == 1:
        terrain = [[index % 13, (index + 1) % 13]]
    else:
        terrain = [[5000]]
    first = (1, 1)
    second = (1, len(terrain[0]))
    io_cases.append((terrain, first, second))
io_text = str(len(io_cases)) + "\n" + "".join(
    format_case(terrain, first, second) for terrain, first, second in io_cases)
write_case("5_io", io_text)

print("generated all DIRVS test pairs")
