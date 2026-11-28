#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PIECES = ["-", "-", "-", "-", "WH", "WP", "WK", "BH", "BP"]


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for case_number in range(1, case_count + 1):
        board = [tokens[cursor + index] for index in range(64)]
        cursor += 64
        king_position = board.index("BK")
        attacked = set()
        for cell_index, piece in enumerate(board):
            row, col = divmod(cell_index, 8)
            if piece == "WH":
                for row_step, col_step in ((1, 2), (1, -2), (-1, 2), (-1, -2),
                                           (2, 1), (2, -1), (-2, 1), (-2, -1)):
                    target = (row + row_step, col + col_step)
                    if 0 <= target[0] < 8 and 0 <= target[1] < 8:
                        attacked.add(target)
            elif piece == "WP":
                for col_step in (-1, 1):
                    target = (row - 1, col + col_step)
                    if 0 <= target[0] < 8 and 0 <= target[1] < 8:
                        attacked.add(target)
            elif piece == "WK":
                for row_step in (-1, 0, 1):
                    for col_step in (-1, 0, 1):
                        if row_step == 0 and col_step == 0:
                            continue
                        target = (row + row_step, col + col_step)
                        if 0 <= target[0] < 8 and 0 <= target[1] < 8:
                            attacked.add(target)
        verdict = "Check" if divmod(king_position, 8) in attacked else "Not Check"
        answers.append(f"Case #{case_number}: {verdict}")
    return "\n".join(answers) + "\n"


SAMPLE = """3
- - - - - - - -
- - - - - - - -
- - - - - - - -
- BH - - - - - -
- - - BK - - - -
- - WP - - - - -
- - - - - - - -
- - - - - - - -

- - - - - - - -
BH - - BH - - - -
- - - - - - - -
- - - - - - - -
- - - BK - - - -
- - - - - - - -
- WP - - - - WH -
- - - WK - - - -

- - - - - - - -
- - - - - - - -
- - - - - - - -
- - - BK - - - -
- - WK - - - - -
- - - - - - WH -
- - - - - - - -
- - - - - - - -
"""
SAMPLE_OUT = """Case #1: Check
Case #2: Not Check
Case #3: Check
"""
assert oracle(SAMPLE) == SAMPLE_OUT


def board_text(board):
    rows = [" ".join(board[row * 8:(row + 1) * 8]) for row in range(8)]
    return "\n".join(rows)


def write(name, boards):
    input_text = str(len(boards)) + "\n" + "\n\n".join(board_text(b) for b in boards) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def make_board(rng, density):
    board = [rng.choice(PIECES) for _ in range(64)]
    while "WK" in board:
        board[board.index("WK")] = "-"
    king_spot = rng.randrange(64)
    board[king_spot] = "BK"
    return board


def build():
    empty = ["-"] * 64
    edge_a = empty[:]
    edge_a[4 * 8 + 3] = "BK"
    edge_b = empty[:]
    edge_b[4 * 8 + 3] = "BK"
    edge_b[3 * 8 + 2] = "WP"
    edge_c = empty[:]
    edge_c[4 * 8 + 3] = "BK"
    edge_c[2 * 8 + 4] = "WH"
    edge_d = empty[:]
    edge_d[4 * 8 + 3] = "BK"
    edge_d[5 * 8 + 3] = "WK"
    write("2_edges", [edge_a, edge_b, edge_c, edge_d])
    rng = random.Random(20261201)
    write("3_wide", [make_board(rng, 0.4) for _ in range(10)])
    write("4_random", [make_board(rng, 0.15) for _ in range(20)])
    write("5_io", [make_board(rng, 0.2) for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
