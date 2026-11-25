#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent

COORDINATES = [(x, y, z) for x in range(3) for y in range(3) for z in range(3)]
INDEX = {point: number for number, point in enumerate(COORDINATES)}
RAW_LINES = set()
for axis in range(3):
    for first in range(3):
        for second in range(3):
            points = []
            for step in range(3):
                point = [0, 0, 0]
                point[axis] = step
                others = [value for value in range(3) if value != axis]
                point[others[0]] = first
                point[others[1]] = second
                points.append(tuple(point))
            RAW_LINES.add(tuple(sorted(points)))
for fixed_axis in range(3):
    others = [value for value in range(3) if value != fixed_axis]
    for level in range(3):
        forward = []
        backward = []
        for step in range(3):
            forward_point = [0, 0, 0]
            forward_point[fixed_axis] = level
            forward_point[others[0]] = step
            forward_point[others[1]] = step
            forward.append(tuple(forward_point))
            backward_point = [0, 0, 0]
            backward_point[fixed_axis] = level
            backward_point[others[0]] = step
            backward_point[others[1]] = 2 - step
            backward.append(tuple(backward_point))
        RAW_LINES.add(tuple(sorted(forward)))
        RAW_LINES.add(tuple(sorted(backward)))
RAW_LINES.add(tuple(sorted([(0, 0, 0), (1, 1, 1), (2, 2, 2)])))
RAW_LINES.add(tuple(sorted([(0, 0, 2), (1, 1, 1), (2, 2, 0)])))
RAW_LINES.add(tuple(sorted([(0, 2, 0), (1, 1, 1), (2, 0, 2)])))
RAW_LINES.add(tuple(sorted([(2, 0, 0), (1, 1, 1), (0, 2, 2)])))
LINE_INDICES = tuple(sorted(tuple(INDEX[point] for point in line) for line in RAW_LINES))
LINES_THROUGH = [[line for line in LINE_INDICES if index in line] for index in range(27)]


def has_line(state, mark, index=None):
    lines = LINES_THROUGH[index] if index is not None else LINE_INDICES
    return any(all(state[position] == mark for position in line) for line in lines)


@lru_cache(maxsize=None)
def solve_state(state, circle_turn):
    if all(mark != '.' for mark in state):
        return 0
    best = -2
    mark = 'o' if circle_turn else 'x'
    for index in range(27):
        if state[index] != '.':
            continue
        placed = list(state)
        placed[index] = mark
        if has_line(placed, mark, index):
            score = 1
        else:
            score = -solve_state(tuple(placed), not circle_turn)
        if score > best:
            best = score
        if best == 1:
            break
    return best


def winner_of_board(board):
    cross_count = sum(value == 'x' for value in board.values())
    circle_count = sum(value == 'o' for value in board.values())
    cross_to_move = cross_count == circle_count
    start = tuple(board[point] for point in COORDINATES)
    result = solve_state(start, not cross_to_move)
    if result == 0:
        return "Ada"
    if result == 1:
        return "Vinit" if not cross_to_move else "Ada"
    return "Ada" if not cross_to_move else "Vinit"


def oracle(boards):
    return "\n".join(winner_of_board(board) for board in boards) + "\n"


def board_from_rows(rows):
    board = {}
    for layer in range(3):
        for row in range(3):
            for column in range(3):
                board[(layer, row, column)] = rows[layer * 3 + row][column]
    return board


def rows_from_board(board):
    rows = []
    for layer in range(3):
        for row in range(3):
            rows.append("".join(board[(layer, row, column)] for column in range(3)))
    return rows


SAMPLE_ROWS = [
    ["..o", "o.x", "xox", "x.x", "...", "x.o", "...", "o.o", ".x."],
    [".x.", "...", "..o", "o.x", "x..", "..o", "..x", "...", "..."],
    ["o..", "...", "o.x", ".x.", "...", ".x.", "o.o", ".xx", "oox"],
    ["..x", "..x", ".o.", "..x", "..x", "xo.", "o..", "..o", "..."],
    ["...", "..x", "..x", ".o.", "..x", "o..", "...", "...", "x.o"],
    ["...", "..x", "..o", "...", "...", "xo.", "ox.", "...", ".ox"],
    ["o..", "x..", "...", "oxx", "..o", ".ox", "..o", ".x.", ".x."],
]
SAMPLE = str(len(SAMPLE_ROWS)) + "\n\n" + "\n\n".join("\n".join(rows) for rows in SAMPLE_ROWS) + "\n"
SAMPLE_OUT = "Vinit\nVinit\nAda\nVinit\nAda\nVinit\nVinit\n"
assert oracle([board_from_rows(rows) for rows in SAMPLE_ROWS]) == SAMPLE_OUT
assert winner_of_board(board_from_rows(["xox", "x.o", "oox", "o.o", "x.x", "xxo", "x.o", "oxo", "ox."])) == "Ada"
assert len(LINE_INDICES) == 49


def random_board(rng, minimum_marks):
    while True:
        state = ['.'] * 27
        mark = 'x'
        moves = 0
        while moves < minimum_marks:
            empty = [index for index, value in enumerate(state) if value == '.']
            if not empty:
                break
            index = rng.choice(empty)
            state[index] = mark
            if has_line(state, mark, index):
                break
            mark = 'o' if mark == 'x' else 'x'
            moves += 1
        if moves >= minimum_marks:
            return {point: state[index] for point, index in INDEX.items()}


def write(name, boards):
    text = str(len(boards)) + "\n"
    text += "\n".join("\n".join(rows_from_board(board)) for board in boards) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(boards))


def build():
    rng = random.Random(20261126)
    write("2_edges", [random_board(rng, count) for count in (17, 18, 19, 20)])
    write("3_wide", [random_board(rng, 17) for _ in range(6)])
    write("4_random", [random_board(rng, rng.randint(17, 20)) for _ in range(6)])
    write("5_io", [random_board(rng, 20) for _ in range(60)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
