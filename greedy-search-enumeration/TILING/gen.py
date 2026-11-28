#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        rows = int(tokens[cursor]); cursor += 1
        cols = int(tokens[cursor]); cursor += 1
        board = tokens[cursor:cursor + rows]; cursor += rows
        best = rows * cols
        for height in range(1, rows + 1):
            if rows % height:
                continue
            for width in range(1, cols + 1):
                if cols % width or height * width >= best:
                    continue
                tile = [line[:width] for line in board[:height]]
                rebuilt = "".join(
                    "".join(tile[i % height][j % width] for j in range(cols))
                    for i in range(rows)
                )
                if rebuilt == "".join(board):
                    best = height * width
        answers.append(str(best))
    return "\n".join(answers) + "\n"


def case(rows):
    header = f"{len(rows)} {len(rows[0])}\n"
    return header + "\n".join(rows) + "\n"


def packets(boards):
    return f"{len(boards)}\n" + "".join(case(board) for board in boards)


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


SAMPLE = "3\n4 3\naaa\naaa\naaa\naaa\n4 4\nabab\ncdcd\nabab\ncdcd\n3 4\naaaa\naaaa\naaab\n"
SAMPLE_OUT = "1\n4\n12\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle(packets([["a"]])) == "1\n"
assert oracle(packets([["ab", "ab"]])) == "2\n"
assert oracle(packets([["ab", "ba"]])) == "4\n"
assert oracle(packets([["abc", "abc", "abc"]])) == "3\n"


def build():
    write("2_edges", packets([["a"], ["aa", "aa"], ["ab", "ab"],
                              ["abcd", "abcd"], ["ab", "ba"]]))
    write("3_wide", packets([["a" * 1000] * 1000]))
    rng = random.Random(20261126)
    boards = []
    for _ in range(20):
        rows = rng.randint(1, 12)
        cols = rng.randint(1, 12)
        base = [[rng.choice("abc") for _ in range(cols)] for _ in range(rows)]
        if rng.randrange(2):
            period_rows = rng.randint(1, rows)
            period_cols = rng.randint(1, cols)
            block = [[rng.choice("abc") for _ in range(period_cols)]
                     for _ in range(period_rows)]
            base = [[block[i % period_rows][j % period_cols] for j in range(cols)]
                    for i in range(rows)]
        boards.append(["".join(line) for line in base])
    write("4_random", packets(boards))
    io_boards = []
    for index in range(100):
        size = 1 + index % 5
        letter = chr(ord("a") + index % 3)
        io_boards.append([letter * size for _ in range(size)])
    write("5_io", packets(io_boards))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
