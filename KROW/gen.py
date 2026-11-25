#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
STEP_ROWS = (0, 1, 1, 1)
STEP_COLUMNS = (1, 0, 1, -1)


def oracle(text):
    tokens = text.split()
    cursor = 0
    game_count = int(tokens[cursor])
    cursor += 1
    hansel_wins = 0
    gretel_wins = 0
    for _ in range(game_count):
        columns = int(tokens[cursor])
        rows = int(tokens[cursor + 1])
        required = int(tokens[cursor + 2])
        cursor += 3
        board = []
        for row_index in range(rows):
            board.append(tokens[cursor])
            cursor += 1
        winner = None
        for row_index in range(rows):
            for column_index in range(columns):
                for direction_index in range(4):
                    end_row = row_index + (required - 1) * STEP_ROWS[direction_index]
                    end_column = column_index + (required - 1) * STEP_COLUMNS[direction_index]
                    if not (0 <= end_row < rows and 0 <= end_column < columns):
                        continue
                    mark = board[row_index][column_index]
                    if mark == ".":
                        continue
                    complete = True
                    for offset in range(1, required):
                        check_row = row_index + offset * STEP_ROWS[direction_index]
                        check_column = column_index + offset * STEP_COLUMNS[direction_index]
                        if board[check_row][check_column] != mark:
                            complete = False
                            break
                    if complete:
                        winner = mark
        if winner == "x":
            hansel_wins += 1
        elif winner == "o":
            gretel_wins += 1
    return f"{hansel_wins}:{gretel_wins}\n"


SAMPLE = """2
3 3 3
.x.
.xo
oox
4 7 4
....
..x.
ooox
oxx.
oox.
o.ox
..xx
"""
SAMPLE_OUT = """0:1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 2 2\nxx\n..\n") == "1:0\n"
assert oracle("1\n3 3 3\nooo\n...\n...\n") == "0:1\n"
assert oracle("1\n3 3 3\n...\n...\n...\n") == "0:0\n"
assert oracle("2\n2 2 2\nxx\n..\n2 2 2\noo\n..\n") == "1:1\n"


def make_board(rows, columns, required, mark, rng):
    grid = [["." for _ in range(columns)] for _ in range(rows)]
    if mark is not None:
        fitting_directions = []
        for direction_index in range(4):
            row_step = STEP_ROWS[direction_index]
            column_step = STEP_COLUMNS[direction_index]
            end_row = (required - 1) * row_step
            end_column = (required - 1) * column_step
            if rows - abs(end_row) > 0 and columns - abs(end_column) > 0:
                fitting_directions.append(direction_index)
        direction_index = rng.choice(fitting_directions)
        row_step = STEP_ROWS[direction_index]
        column_step = STEP_COLUMNS[direction_index]
        possible = []
        for row_index in range(rows):
            for column_index in range(columns):
                end_row = row_index + (required - 1) * row_step
                end_column = column_index + (required - 1) * column_step
                if 0 <= end_row < rows and 0 <= end_column < columns:
                    possible.append((row_index, column_index))
        start_row, start_column = rng.choice(possible)
        for offset in range(required):
            grid[start_row + offset * row_step][start_column + offset * column_step] = mark
    return ["".join(row) for row in grid]


def write(name, games):
    lines = [str(len(games))]
    for rows, columns, required, board in games:
        lines.append(f"{columns} {rows} {required}")
        lines.extend(board)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    edges = []
    for required in (1, 2, 3):
        for mark in ("x", "o", None):
            board = make_board(3, 4, required, mark, rng)
            edges.append((3, 4, required, board))
    write("2_edges", edges)

    wide = []
    for mark in ("x", "o", None, "x", "o"):
        board = make_board(199, 199, 199, mark, rng)
        wide.append((199, 199, 199, board))
    for required in (7, 13, 25):
        board = make_board(120, 160, required, rng.choice(["x", "o"]), rng)
        wide.append((120, 160, required, board))
    write("3_wide", wide)

    random_games = []
    for _ in range(40):
        rows = rng.randint(2, 30)
        columns = rng.randint(2, 30)
        required = rng.randint(2, max(rows, columns))
        mark = rng.choice(["x", "o", None])
        board = make_board(rows, columns, required, mark, rng)
        random_games.append((rows, columns, required, board))
    write("4_random", random_games)

    io_games = []
    for index in range(5000):
        required = 2 + index % 2
        mark = rng.choice(["x", "o", None])
        board = make_board(3, 3, required, mark, rng)
        io_games.append((3, 3, required, board))
    write("5_io", io_games)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    (3, 3, 3, [".x.", ".xo", "oox"]),
    (7, 4, 4, ["....", "..x.", "ooox", "oxx.", "oox.", "o.ox", "..xx"]),
])
build()
