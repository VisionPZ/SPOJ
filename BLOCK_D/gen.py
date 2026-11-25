#!/usr/bin/env python3
from collections import deque
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(rows):
    start = tuple(rows)
    if all(cell == "." for row in rows for cell in row):
        return 0
    height = len(rows)
    queue = deque([(start, 0)])
    seen = {start}
    while queue:
        state, depth = queue.popleft()
        board = [list(row) for row in state]
        visited = set()
        components = []
        for row in range(height):
            for column in range(len(board[row])):
                if board[row][column] == "." or (row, column) in visited:
                    continue
                color = board[row][column]
                members = set()
                pending = [(row, column)]
                visited.add((row, column))
                while pending:
                    current_row, current_column = pending.pop()
                    members.add((current_row, current_column))
                    for delta_row, delta_column in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        neighbor = (current_row + delta_row,
                                    current_column + delta_column)
                        if (0 <= neighbor[0] < height and
                                0 <= neighbor[1] < len(board[neighbor[0]]) and
                                board[neighbor[0]][neighbor[1]] == color and
                                neighbor not in visited):
                            visited.add(neighbor)
                            pending.append(neighbor)
                if len(members) > 1:
                    components.append(members)
        for members in components:
            next_board = [list(row) for row in state]
            for row, column in members:
                next_board[row][column] = "."
            width = len(next_board[0])
            for column in range(width):
                colors = [next_board[row][column] for row in range(height)
                          if next_board[row][column] != "."]
                padded = ["."] * (height - len(colors)) + colors
                for row in range(height):
                    next_board[row][column] = padded[row]
            kept = [column for column in range(width)
                    if any(next_board[row][column] != "." for row in range(height))]
            next_board = [[row[column] for column in kept] for row in next_board]
            next_state = tuple("".join(row) for row in next_board)
            if all(cell == "." for row in next_board for cell in row):
                return depth + 1
            if next_state not in seen:
                seen.add(next_state)
                queue.append((next_state, depth + 1))
    return -1


def oracle_text(cases):
    return "".join(str(oracle(rows)) + "\n" for rows in cases)


SAMPLE_CASES = [["aaaba"] * 5,
                ["bbbbb", "baabb", "bbbab", "bbbaa", "aabab"]]
SAMPLE_OUT = "2\n3\n"
assert oracle_text(SAMPLE_CASES) == SAMPLE_OUT
assert oracle(["a"]) == -1
assert oracle(["aa"]) == 1
assert oracle(["ab", "ba"]) == -1
assert oracle(["aa", "bb"]) == 2
assert oracle(["abab"]) == -1


def write(name, cases):
    chunks = [str(len(cases))]
    for rows in cases:
        chunks.append(f"{len(rows)} {len(rows[0])}")
        chunks.extend(rows)
    text = "\n".join(chunks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle_text(cases))


def build():
    write("2_edges", [["a"], ["aa"], ["ab", "ba"], ["aa", "bb"],
                      ["aaaaa"], ["abcde"]])
    write("3_wide", [["aaaba"] * 5,
                     ["abababab", "babababa", "abababab"],
                     ["aaaaa", "bbbbb", "aaaaa", "bbbbb", "aaaaa"]])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(25):
        height = rng.randint(1, 5)
        width = rng.randint(1, 5)
        rows = ["".join(rng.choice("abc") for _ in range(width))
                for _ in range(height)]
        random_cases.append(rows)
    write("4_random", random_cases)
    io_cases = []
    for _ in range(200):
        height = rng.randint(1, 2)
        width = rng.randint(1, 3)
        rows = ["".join(rng.choice("ab") for _ in range(width))
                for _ in range(height)]
        io_cases.append(rows)
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
SAMPLE = """2
5 5
aaaba
aaaba
aaaba
aaaba
aaaba
5 5
bbbbb
baabb
bbbab
bbbaa
aabab
"""
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
