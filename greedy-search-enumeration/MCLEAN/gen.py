#!/usr/bin/env python3
import itertools
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DIRECTIONS = ((1, 0), (-1, 0), (0, 1), (0, -1))


def distances(grid, start):
    width = len(grid[0])
    height = len(grid)
    result = {}
    queue = deque([start])
    result[start] = 0
    while queue:
        cell_x, cell_y = queue.popleft()
        for delta_x, delta_y in DIRECTIONS:
            next_x = cell_x + delta_x
            next_y = cell_y + delta_y
            if not (0 <= next_x < width and 0 <= next_y < height):
                continue
            if grid[next_y][next_x] == 'x':
                continue
            if (next_x, next_y) in result:
                continue
            result[(next_x, next_y)] = result[(cell_x, cell_y)] + 1
            queue.append((next_x, next_y))
    return result


def solve(grid):
    dirty = []
    robot = None
    for row_index, row in enumerate(grid):
        for column_index, symbol in enumerate(row):
            if symbol == '*':
                dirty.append((column_index, row_index))
            elif symbol == 'o':
                robot = (column_index, row_index)
    from_robot = distances(grid, robot)
    if any(cell not in from_robot for cell in dirty):
        return -1
    best = None
    for order in itertools.permutations(range(len(dirty))):
        current = robot
        total = 0
        for index in order:
            leg = distances(grid, current)
            total += leg[dirty[index]]
            if best is not None and total >= best:
                break
            current = dirty[index]
        if best is None or total < best:
            best = total
    return best if best is not None else 0


def oracle(text):
    lines = [line for line in text.splitlines() if line.strip()]
    cursor = 0
    answers = []
    while cursor < len(lines):
        width, height = (int(value) for value in lines[cursor].split())
        cursor += 1
        if width == 0 and height == 0:
            break
        grid = lines[cursor:cursor + height]
        cursor += height
        answers.append(str(solve(grid)))
    return "\n".join(answers) + ("\n" if answers else "")


SAMPLE = """7 5
.......
.o...*.
.......
.*...*.
.......
15 13
.......x.......
...o...x....*..
.......x.......
.......x.......
.......x.......
...............
xxxxx.....xxxxx
...............
.......x.......
.......x.......
.......x.......
..*....x....*..
.......x.......
10 10
..........
..o.......
..........
..........
..........
.....xxxxx
.....x....
.....x.*..
.....x....
.....x....
0 0
"""
SAMPLE_OUT = """8
49
-1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3 1\nox*\n0 0\n") == "-1\n"
assert oracle("3 1\no.*\n0 0\n") == "2\n"
assert oracle("3 3\n...\n.o.\n...\n0 0\n") == "0\n"
assert oracle("5 1\no...*\n0 0\n") == "4\n"


def write(name, maps):
    lines = []
    for grid in maps:
        lines.append(f"{len(grid[0])} {len(grid)}")
        lines.extend(grid)
    lines.append("0 0")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        ["ox*"],
        ["o.*"],
        ["...", ".o.", "..."],
        ["o...*", "x....", "....."],
    ])
    wide = ["...................."] * 20
    for row_index in range(20):
        row = list(wide[row_index])
        row[7] = 'x'
        wide[row_index] = "".join(row)
    wide[2] = wide[2][:2] + "o" + wide[2][3:]
    for column, row in ((2, 3), (4, 3), (2, 10), (4, 12), (11, 9), (12, 15)):
        row_chars = list(wide[row])
        row_chars[column] = '*'
        wide[row] = "".join(row_chars)
    write("3_wide", [wide])
    rng = random.Random(20261126)
    random_maps = []
    for _ in range(15):
        height = 8
        width = 8
        grid = [["." for _ in range(width)] for _ in range(height)]
        for _ in range(8):
            grid[rng.randrange(height)][rng.randrange(width)] = 'x'
        robot_x, robot_y = rng.randrange(width), rng.randrange(height)
        grid[robot_y][robot_x] = 'o'
        for _ in range(rng.randint(1, 6)):
            cell_x, cell_y = rng.randrange(width), rng.randrange(height)
            if grid[cell_y][cell_x] == '.':
                grid[cell_y][cell_x] = '*'
        random_maps.append(["".join(row) for row in grid])
    write("4_random", random_maps)
    io_maps = []
    for _ in range(2000):
        io_maps.append(["o...*"])
    write("5_io", io_maps)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    [".......", ".o...*.", ".......", ".*...*.", "......."],
    [".......x.......", "...o...x....*..", ".......x.......", ".......x.......",
     ".......x.......", "...............", "xxxxx.....xxxxx", "...............",
     ".......x.......", ".......x.......", ".......x.......", "..*....x....*..",
     ".......x......."],
    ["..........", "..o.......", "..........", "..........", "..........",
     ".....xxxxx", ".....x....", ".....x.*..", ".....x....", ".....x...."],
])
build()
