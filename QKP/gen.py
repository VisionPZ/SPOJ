#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
KNIGHT_OFFSETS = [(1, 2), (2, 1), (2, -1), (1, -2), (-1, -2), (-2, -1), (-2, 1), (-1, 2)]


def sees(queen, square, occupied):
    queen_row, queen_column = queen
    target_row, target_column = square
    row_step = target_row - queen_row
    column_step = target_column - queen_column
    if row_step == 0 and column_step == 0:
        return False
    if row_step == 0:
        step = (0, 1 if column_step > 0 else -1)
    elif column_step == 0:
        step = (1 if row_step > 0 else -1, 0)
    elif abs(row_step) == abs(column_step):
        step = (1 if row_step > 0 else -1, 1 if column_step > 0 else -1)
    else:
        return False
    current_row, current_column = queen_row + step[0], queen_column + step[1]
    while (current_row, current_column) != square:
        if (current_row, current_column) in occupied:
            return False
        current_row += step[0]
        current_column += step[1]
    return True


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    answers = []
    while True:
        row_count = tokens[position]
        column_count = tokens[position + 1]
        position += 2
        if row_count == 0 and column_count == 0:
            break
        pieces = []
        for _ in range(3):
            count = tokens[position]
            position += 1
            group = []
            for _ in range(count):
                group.append((tokens[position], tokens[position + 1]))
                position += 2
            pieces.append(group)
        queens, knights, pawns = pieces
        occupied = set(queens) | set(knights) | set(pawns)
        knight_set = set(knights)
        safe = 0
        for row in range(1, row_count + 1):
            for column in range(1, column_count + 1):
                square = (row, column)
                if square in occupied:
                    continue
                if any((row + step_row, column + step_column) in knight_set for step_row, step_column in KNIGHT_OFFSETS):
                    continue
                if any(sees(queen, square, occupied) for queen in queens):
                    continue
                safe += 1
        answers.append(f"Board {len(answers) + 1} has {safe} safe squares.")
    return "".join(answer + "\n" for answer in answers)


SAMPLE = """4 4
2 1 4 2 4
1 1 2
1 2 3
2 3
1 1 2
1 1 1
0
1000 1000
1 3 3
0
0
0 0
"""
SAMPLE_OUT = """Board 1 has 6 safe squares.
Board 2 has 0 safe squares.
Board 3 has 996998 safe squares.
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("10 10\n2 2 2 5 5\n0\n0\n0 0\n") == "Board 1 has 48 safe squares.\n"
assert oracle("1 1\n0\n0\n0\n0 0\n") == "Board 1 has 1 safe squares.\n"
assert oracle("3 3\n1 2 2\n0\n0\n0 0\n") == "Board 1 has 0 safe squares.\n"


def write_case(name, boards):
    lines = []
    for rows, columns, queens, knights, pawns in boards:
        lines.append(f"{rows} {columns}\n")
        for group in (queens, knights, pawns):
            lines.append(str(len(group)))
            for row, column in group:
                lines.append(f" {row} {column}")
            lines.append("\n")
    lines.append("0 0\n")
    text = "".join(lines)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_case("2_edges", [
        (1, 1, [], [], []),
        (2, 2, [(1, 1)], [], []),
        (3, 3, [], [(2, 2)], []),
        (6, 6, [(2, 2)], [], [(3, 3), (4, 4)]),
        (8, 8, [(1, 1), (8, 8)], [(4, 4)], [(3, 3)]),
    ])
    rng = random.Random(20261126)
    wide = (
        40, 40,
        [(rng.randint(1, 40), rng.randint(1, 40)) for _ in range(12)],
        [(rng.randint(1, 40), rng.randint(1, 40)) for _ in range(12)],
        [(rng.randint(1, 40), rng.randint(1, 40)) for _ in range(12)],
    )
    write_case("3_wide", [wide])
    boards = []
    for _ in range(8):
        rows = rng.randint(4, 20)
        columns = rng.randint(4, 20)
        boards.append((
            rows, columns,
            [(rng.randint(1, rows), rng.randint(1, columns)) for _ in range(rng.randint(0, 5))],
            [(rng.randint(1, rows), rng.randint(1, columns)) for _ in range(rng.randint(0, 5))],
            [(rng.randint(1, rows), rng.randint(1, columns)) for _ in range(rng.randint(0, 5))],
        ))
    write_case("4_random", boards)
    rng = random.Random(224488)
    boards = []
    for _ in range(400):
        rows = rng.randint(3, 6)
        columns = rng.randint(3, 6)
        boards.append((
            rows, columns,
            [(rng.randint(1, rows), rng.randint(1, columns)) for _ in range(rng.randint(0, 2))],
            [(rng.randint(1, rows), rng.randint(1, columns)) for _ in range(rng.randint(0, 2))],
            [(rng.randint(1, rows), rng.randint(1, columns)) for _ in range(rng.randint(0, 2))],
        ))
    write_case("5_io", boards)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
