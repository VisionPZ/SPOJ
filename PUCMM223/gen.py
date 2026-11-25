#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DIRECTIONS = [(0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)]


def solve_case(board):
    height = len(board)
    width = len(board[0])
    walls = set()
    start_a = None
    start_b = None
    for row in range(height):
        for column in range(width):
            symbol = board[row][column]
            if symbol == '#':
                walls.add((row, column))
            elif symbol == 'a':
                start_a = (row, column)
            elif symbol == 'b':
                start_b = (row, column)

    def neighbours(position):
        row, column = position
        result = []
        for delta_row, delta_column in DIRECTIONS:
            candidate = (row + delta_row, column + delta_column)
            if 0 <= candidate[0] < height and 0 <= candidate[1] < width and candidate not in walls:
                result.append(candidate)
        return result

    start = (start_a, start_b)
    goal = (start_b, start_a)
    seen = {start}
    frontier = {start}
    moves = 0
    while frontier:
        if goal in frontier:
            return str(moves)
        following = set()
        for piece_a, piece_b in frontier:
            for next_a in neighbours(piece_a):
                for next_b in neighbours(piece_b):
                    if next_a == next_b:
                        continue
                    if next_a == piece_b and next_b == piece_a:
                        continue
                    state = (next_a, next_b)
                    if state not in seen:
                        seen.add(state)
                        following.add(state)
        frontier = following
        moves += 1
    return "IMPOSSIBLE"


def oracle(text):
    lines = text.splitlines()
    cursor = 0
    answers = []
    while cursor < len(lines):
        header = lines[cursor].split()
        cursor += 1
        height = int(header[0])
        width = int(header[1])
        if height == 0 and width == 0:
            break
        board = lines[cursor:cursor + height]
        cursor += height
        answers.append(solve_case(board))
    return "\n".join(answers) + "\n"


SAMPLE = """3 4
#..#
a..b
####
3 7
#######
#a...b#
#######
4 4
a...
###.
##..
b...
0 0
"""
SAMPLE_OUT = "5\nIMPOSSIBLE\n11\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2 2\nab\n..\n0 0\n") == "3\n"
assert oracle("1 2\nab\n0 0\n") == "IMPOSSIBLE\n"
assert oracle("3 3\na..\n...\n..b\n0 0\n") == "4\n"
assert oracle("1 3\na.b\n0 0\n") == "IMPOSSIBLE\n"


def encode(cases):
    parts = []
    for board in cases:
        parts.append(f"{len(board)} {len(board[0])}")
        parts.extend(board)
    parts.append("0 0")
    return "\n".join(parts) + "\n"


def write(name, cases):
    text = encode(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def open_board(height, width):
    board = [["." for _ in range(width)] for _ in range(height)]
    board[0][0] = "a"
    board[height - 1][width - 1] = "b"
    return ["".join(row) for row in board]


def build():
    write("2_edges", [["ab", ".."], ["a.b"], ["a", "b"]])
    write("3_wide", [open_board(20, 20)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(20):
        height = rng.randint(1, 7)
        width = rng.randint(2, 7)
        grid = [["." for _ in range(width)] for _ in range(height)]
        for _ in range(rng.randint(0, height * width // 3)):
            grid[rng.randrange(height)][rng.randrange(width)] = "#"
        positions = [(row, column) for row in range(height) for column in range(width)
                     if grid[row][column] == "."]
        if len(positions) < 2:
            positions = [(row, column) for row in range(height) for column in range(width)]
            for row in range(height):
                for column in range(width):
                    grid[row][column] = "."
        first = rng.choice(positions)
        positions.remove(first)
        second = rng.choice(positions)
        grid[first[0]][first[1]] = "a"
        grid[second[0]][second[1]] = "b"
        random_cases.append(["".join(row) for row in grid])
    write("4_random", random_cases)
    io_cases = []
    for _ in range(150):
        height = rng.randint(2, 4)
        width = rng.randint(2, 5)
        grid = [["." for _ in range(width)] for _ in range(height)]
        first = (0, 0)
        second = (height - 1, width - 1)
        for _ in range(rng.randint(0, 3)):
            row = rng.randrange(height)
            column = rng.randrange(width)
            if (row, column) not in (first, second):
                grid[row][column] = "#"
        grid[first[0]][first[1]] = "a"
        grid[second[0]][second[1]] = "b"
        io_cases.append(["".join(row) for row in grid])
    write("5_io", io_cases)
    Path("/tmp/PUCMM223_big.txt").write_text(encode([open_board(20, 20)]))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [["#..#", "a..b", "####"],
                   ["#######", "#a...b#", "#######"],
                   ["a...", "###.", "##..", "b..."]])
build()
