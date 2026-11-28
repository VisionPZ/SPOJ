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


def decode(rows, cols, bits):
    order = spiral_cells(rows, cols)
    stream = ''.join(bits[row * cols + col] for row, col in order)
    text = ""
    for index in range(0, len(stream) - 4, 5):
        value = int(stream[index:index + 5], 2)
        text += ' ' if value == 0 else chr(64 + value)
    return text.rstrip(' ')


def oracle(text):
    lines = text.splitlines()
    count = int(lines[0])
    answers = []
    for case in range(1, count + 1):
        parts = lines[case].split(' ', 2)
        rows = int(parts[0])
        cols = int(parts[1])
        bits = parts[2] if len(parts) > 2 else ""
        answers.append(f"{case} {decode(rows, cols, bits)}")
    return "\n".join(answers) + "\n"


SAMPLE = """4
4 4 0000110100101100
5 2 0110000010
2 6 010000001001
5 5 0100001000011010110000010
"""
SAMPLE_OUT = """1 ACM
2 HI
3 HI
4 HI HO
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 5 0000100000\n") == "1 A\n"
assert oracle("1\n5 1 0000100000\n") == "1 A\n"
assert oracle("1\n5 5 0100001000011010110000000\n") == "1 HH HO\n"
assert decode(2, 5, "0000100000") == "A"


def write(name, datasets):
    lines = [str(len(datasets))]
    for rows, cols, bits in datasets:
        lines.append(f"{rows} {cols} {bits}")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def encode_message(rows, cols, message, rng=None):
    cells = rows * cols
    bits = ""
    for char in message:
        value = 0 if char == ' ' else ord(char) - 64
        bits += format(value, '05b')
    bits += '0' * (cells - len(bits))
    order = spiral_cells(rows, cols)
    grid = ['0'] * cells
    for index, (row, col) in enumerate(order):
        grid[row * cols + col] = bits[index]
    return ''.join(grid)


def build():
    write("2_edges", [(1, 5, "00001"), (5, 1, "11010"), (2, 5, "0000100000"),
                      (5, 5, "0100001000011010110000000")])
    rng = random.Random(20261126)
    for name, count in (("3_wide", 200), ("4_random", 200)):
        datasets = []
        for _ in range(count):
            rows = rng.randint(1, 20)
            cols = rng.randint(1, 20)
            length = rng.randint(0, (rows * cols) // 5)
            message = ''.join(rng.choice("ABCDEFGHIJKLMNOPQRSTUVWXYZ ")
                              for _ in range(length))
            datasets.append((rows, cols, encode_message(rows, cols, message)))
        write(name, datasets)
    datasets = []
    for _ in range(1000):
        message = ''.join(rng.choice("ABCDEFGHIJKLMNOPQRSTUVWXYZ") for _ in range(80))
        datasets.append((20, 20, encode_message(20, 20, message)))
    write("5_io", datasets)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
