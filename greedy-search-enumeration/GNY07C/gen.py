#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def spiral_cells(rows, cols):
    seen = [[False] * cols for _ in range(rows)]
    row = col = 0
    drow, dcol = 0, 1
    cells = []
    for _ in range(rows * cols):
        cells.append((row, col))
        seen[row][col] = True
        if len(cells) == rows * cols:
            break
        while True:
            next_row, next_col = row + drow, col + dcol
            if 0 <= next_row < rows and 0 <= next_col < cols and not seen[next_row][next_col]:
                break
            drow, dcol = dcol, -drow
        row, col = next_row, next_col
    return cells


def oracle(text):
    lines = text.splitlines()
    count = int(lines[0])
    answers = []
    for case in range(1, count + 1):
        parts = lines[case].split(' ', 2)
        rows = int(parts[0])
        cols = int(parts[1])
        message = parts[2] if len(parts) > 2 else ""
        bits = ""
        for letter in message:
            value = 0 if letter == ' ' else ord(letter) - 64
            bits += format(value, '05b')
        bits += '0' * (rows * cols - len(bits))
        grid = [['0'] * cols for _ in range(rows)]
        for index, (row, col) in enumerate(spiral_cells(rows, cols)):
            grid[row][col] = bits[index]
        encoded = ''.join(''.join(row) for row in grid)
        answers.append(f"{case} {encoded}")
    return "\n".join(answers) + "\n"


SAMPLE = """4
4 4 ACM
5 2 HI
2 6 HI
5 5 HI HO
"""
SAMPLE_OUT = """1 0000110100101100
2 0110000010
3 010000001001
4 0100001000011010110000010
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 5 A\n") == "1 00001\n"
assert oracle("1\n5 1 A\n") == "1 00001\n"
assert oracle("1\n2 5 A\n") == "1 0000100000\n"
assert spiral_cells(4, 4)[4] == (1, 3)


def write(name, datasets):
    lines = [str(len(datasets))]
    for rows, cols, message in datasets:
        lines.append(f"{rows} {cols} {message}")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_message(rng, rows, cols):
    length = rng.randint(0, (rows * cols) // 5)
    letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ "
    message = ''.join(rng.choice(letters) for _ in range(length))
    return message if not message.startswith(' ') else 'A' + message[1:]


def build():
    write("2_edges", [(1, 5, "A"), (5, 1, "Z"), (1, 5, ""), (20, 20, "A" * 80)])
    rng = random.Random(20261126)
    edges = []
    for _ in range(200):
        rows = rng.randint(1, 20)
        cols = rng.randint(1, 20)
        edges.append((rows, cols, random_message(rng, rows, cols)))
    write("3_wide", edges)
    edges = []
    for _ in range(200):
        rows = rng.randint(1, 20)
        cols = rng.randint(1, 20)
        edges.append((rows, cols, random_message(rng, rows, cols)))
    write("4_random", edges)
    write("5_io", [(20, 20, "Q" * 80) for _ in range(1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
