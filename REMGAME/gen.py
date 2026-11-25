#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def all_moves(stones):
    found = set()
    directions = ((1, 0), (0, 1))
    for delta_row, delta_col in directions:
        for start_row in range(5):
            for start_col in range(5):
                position = start_row * 5 + start_col
                if not stones >> position & 1:
                    continue
                removed = 0
                row, col = start_row, start_col
                while 0 <= row < 5 and 0 <= col < 5:
                    position = row * 5 + col
                    if not stones >> position & 1:
                        break
                    removed |= 1 << position
                    found.add(stones ^ removed)
                    row += delta_row
                    col += delta_col
    return found


def oracle_board(stones):
    if stones == 0:
        return "losing"
    winning = set()
    submask = stones
    subsets = []
    while True:
        subsets.append(submask)
        if submask == 0:
            break
        submask = (submask - 1) & stones
    for mask in sorted(subsets, key=int.bit_count):
        if mask == 0:
            continue
        for next_mask in all_moves(mask):
            if next_mask and next_mask not in winning:
                winning.add(mask)
                break
    return "winning" if stones in winning else "losing"


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        stones = 0
        for cell in range(25):
            if int(tokens[cursor + cell]):
                stones |= 1 << cell
        cursor += 25
        answers.append(oracle_board(stones))
    return "\n".join(answers) + "\n"


def grid_text(rows):
    return "\n".join(" ".join(str(value) for value in row) for row in rows) + "\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


SAMPLE = ("1 \n"
          "1 0 0 0 0 \n"
          "1 1 0 0 0 \n"
          "1 1 1 0 0 \n"
          "1 1 1 1 0 \n"
          "1 1 1 1 1\n")
SAMPLE_OUT = "winning\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_board(0) == "losing"
assert oracle_board(1) == "losing"
assert oracle_board(3) == "winning"
assert oracle_board(1 | (1 << 6)) == "winning"


def build():
    empty = [[0] * 5 for _ in range(5)]
    one = [row[:] for row in empty]; one[2][2] = 1
    pair = [row[:] for row in empty]; pair[2][2] = pair[2][3] = 1
    diagonal = [row[:] for row in empty]; diagonal[2][2] = diagonal[3][3] = 1
    whole_row = [row[:] for row in empty]; whole_row[1] = [1] * 5
    edge_boards = (empty, one, pair, diagonal, whole_row)
    write("2_edges", str(len(edge_boards)) + "\n" +
          "".join(grid_text(board) for board in edge_boards))
    write("3_wide", "1\n" + grid_text([
        [1, 0, 0, 0, 0],
        [1, 1, 0, 0, 0],
        [1, 1, 1, 0, 0],
        [1, 1, 1, 1, 0],
        [1, 1, 1, 1, 1],
    ]))
    rng = random.Random(20261126)
    random_boards = []
    for _ in range(20):
        cells = [0] * 25
        for position in rng.sample(range(25), rng.randint(1, 10)):
            cells[position] = 1
        random_boards.append([cells[row * 5:(row + 1) * 5] for row in range(5)])
    write("4_random", str(len(random_boards)) + "\n" +
          "".join(grid_text(board) for board in random_boards))
    io_boards = []
    for _ in range(100):
        cells = [0] * 25
        for position in rng.sample(range(25), rng.randint(1, 7)):
            cells[position] = 1
        io_boards.append([cells[row * 5:(row + 1) * 5] for row in range(5)])
    write("5_io", str(len(io_boards)) + "\n" +
          "".join(grid_text(board) for board in io_boards))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
