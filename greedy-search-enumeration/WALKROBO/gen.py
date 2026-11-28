#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while cursor + 4 <= len(tokens):
        row_count, column_count, move_count, known_count = tokens[cursor:cursor + 4]
        cursor += 4
        if row_count == column_count == move_count == known_count == 0:
            break
        moves = []
        for _ in range(move_count):
            moves.append((tokens[cursor], tokens[cursor + 1]))
            cursor += 2
        initial_mask = 0
        for _ in range(known_count):
            initial_mask |= 1 << (tokens[cursor] - 1)
            cursor += 1
        grid = []
        for _ in range(row_count):
            grid.append(tokens[cursor:cursor + column_count])
            cursor += column_count

        best_seen = {}
        goal_row = row_count - 1
        goal_column = column_count - 1

        def search(column, row, mask, depth, limit):
            if column == goal_column and row == goal_row:
                return True
            if depth == limit:
                return False
            state = (column, row, mask)
            if best_seen.get(state, 1 << 30) <= depth:
                return False
            best_seen[state] = depth
            for offset, (delta_x, delta_y) in enumerate(moves):
                if not mask & (1 << offset):
                    continue
                next_column = column + delta_x
                next_row = row + delta_y
                if 0 <= next_column < column_count and 0 <= next_row < row_count:
                    if search(next_column, next_row, mask, depth + 1, limit):
                        return True
            spot = grid[row_count - 1 - row][column]
            if spot > 0:
                bit = 1 << (spot - 1)
                if not mask & bit:
                    if search(column, row, mask | bit, depth + 1, limit):
                        return True
            return False

        answer = -1
        for limit in range(0, 40):
            best_seen = {}
            if search(0, 0, initial_mask, 0, limit):
                answer = limit
                break
        answers.append(f"Case #{len(answers) + 1}: {answer}")
    return "\n".join(answers) + ("\n" if answers else "")


SAMPLE = """4 3 2 1
1 0
0 1
1
0 0 0
0 0 0
0 0 0
0 0 2
5 5 4 1
2 1
-1 1
-1 0
-1 -2
1
0 4 3 0 0
0 0 0 0 0
0 0 0 0 2
0 0 0 0 0
0 0 0 0 0
5 5 4 1
2 1
-1 1
-1 0
-1 -2
1
4 0 3 0 0
0 0 0 0 0
0 0 0 0 2
0 0 0 0 0
0 0 0 0 0
7 7 3 0
1 1
2 2
4 4
0 0 0 0 0 0 0
0 0 0 0 0 0 0
0 0 0 0 0 0 0
0 0 0 0 0 0 0
0 0 3 0 0 0 0
0 2 0 0 0 0 0
1 0 0 0 0 0 0
"""
SAMPLE_OUT = """Case #1: 6
Case #2: 11
Case #3: -1
Case #4: 5
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2 2 1 1\n1 0\n1\n0 0\n0 0\n0 0 0 0\n") == "Case #1: -1\n"
assert oracle("2 2 2 2\n1 0\n0 1\n1 2\n0 0\n0 0\n0 0 0 0\n") == "Case #1: 2\n"
assert oracle("2 2 1 0\n0 1\n0 0\n0 0\n0 0 0 0\n") == "Case #1: -1\n"
assert oracle("3 3 2 0\n1 0\n0 1\n0 0 2\n0 0 0\n0 0 0\n") == "Case #1: -1\n"


def render(cases):
    parts = []
    for row_count, column_count, moves, known, grid in cases:
        parts.append(f"{row_count} {column_count} {len(moves)} {len(known)}")
        for delta_x, delta_y in moves:
            parts.append(f"{delta_x} {delta_y}")
        if known:
            parts.append(" ".join(str(value) for value in known))
        for row in grid:
            parts.append(" ".join(str(value) for value in row))
    parts.append("0 0 0 0")
    return "\n".join(parts) + "\n"


def write(name, cases):
    text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (2, 2, [(1, 0)], [1], [[0, 0], [0, 0]]),
        (2, 2, [(0, 1)], [], [[0, 0], [0, 0]]),
        (3, 3, [(0, -1), (1, 0)], [2], [[0, 1], [0, 0], [0, 0]]),
    ])
    wide_grid = [[0] * 8 for _ in range(8)]
    wide_grid[7][0] = 1
    wide_grid[6][1] = 2
    wide_grid[4][4] = 3
    wide_grid[1][7] = 4
    write("3_wide", [(8, 8, [(1, 0), (0, 1), (2, 1), (-1, 2), (3, 0), (0, -2)], [1], wide_grid)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(12):
        rows = rng.randint(2, 6)
        columns = rng.randint(2, 6)
        count = rng.randint(1, 4)
        moves = [(rng.randint(-2, 2), rng.randint(-2, 2)) for _ in range(count)]
        known = [index + 1 for index in range(count) if rng.random() < 0.5]
        grid = [[rng.randint(0, count) if rng.random() < 0.4 else 0 for _ in range(columns)] for _ in range(rows)]
        random_cases.append((rows, columns, moves, known, grid))
    write("4_random", random_cases)
    io_cases = []
    for index in range(60):
        rows = 2 + index % 3
        columns = 2 + (index + 1) % 3
        io_cases.append((rows, columns, [(1, 0), (0, 1)], [1], [[0] * columns for _ in range(rows)]))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
