#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DIRECTIONS = ("Down", "Left", "Right", "Up")
STEPS = {"Down": (1, 0), "Left": (0, -1), "Right": (0, 1), "Up": (-1, 0)}


def parse(text):
    lines = [line.strip() for line in text.strip().splitlines()]
    header = [int(part) for part in lines[0].split()]
    rows, columns = header[0], header[1]
    maze = []
    for line in lines[1:1 + rows]:
        maze.append((line + "." * columns)[:columns])
    return rows, columns, maze


def oracle(text):
    rows, columns, maze = parse(text)
    stones = [(r, c) for r in range(rows) for c in range(columns)
              if maze[r][c] == "*"]
    stone_id = {cell: index for index, cell in enumerate(stones)}
    start = next((r, c) for r in range(rows) for c in range(columns)
                 if maze[r][c] == "S")
    full_mask = (1 << len(stones)) - 1

    def slide(cell, direction):
        row, column = cell
        step_row, step_column = STEPS[direction]
        mask = 0
        while True:
            next_row = row + step_row
            next_column = column + step_column
            if not (0 <= next_row < rows and 0 <= next_column < columns):
                break
            if maze[next_row][next_column] == "#":
                break
            row, column = next_row, next_column
            if (row, column) in stone_id:
                mask |= 1 << stone_id[(row, column)]
        return (row, column), mask

    start_mask = 1 << stone_id[start] if start in stone_id else 0
    for depth in range(0, 25):
        solution = []
        failed = set()

        def search(cell, mask, left, path):
            if left == 0:
                if mask == full_mask:
                    solution.append(tuple(path))
                    return True
                return False
            state = (cell, mask, left)
            if state in failed:
                return False
            for direction in sorted(DIRECTIONS):
                destination, extra = slide(cell, direction)
                path.append(direction)
                if search(destination, mask | extra, left - 1, path):
                    return True
                path.pop()
            failed.add(state)
            return False

        if search(start, start_mask, depth, []):
            answer = str(depth) + "\n" + "-".join(solution[0]) + "\n"
            return answer
    return "-1\n"


SAMPLE = """5 6
*S....
....#.
.##...
**....
.#.*#.
"""
SAMPLE_OUT = """7
Down-Right-Down-Left-Up-Left-Up
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2 2\nS*\n..\n") == "1\nRight\n"
assert oracle("3 3\nS#*\n...\n...\n") == "3\nDown-Right-Up\n"
assert oracle("2 2\nS.\n..\n") == "0\n\n"
assert len(DIRECTIONS) == 4


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_maze(rows, columns, wall_chance, stone_count, rng):
    while True:
        maze = [["." for _ in range(columns)] for _ in range(rows)]
        maze[0][0] = "S"
        free = [(r, c) for r in range(rows) for c in range(columns)
                if (r, c) != (0, 0)]
        rng.shuffle(free)
        for cell in free[:stone_count]:
            maze[cell[0]][cell[1]] = "*"
        for cell in free[stone_count:]:
            if rng.random() < wall_chance:
                maze[cell[0]][cell[1]] = "#"
        text = f"{rows} {columns}\n" + "\n".join("".join(row) for row in maze) + "\n"
        if oracle(text).startswith("-1"):
            continue
        return text


def build():
    write("2_edges", "2 2\nS.\n..\n")
    write("3_wide", random_maze(6, 8, 0.18, 4, random.Random(8021)))
    write("4_random", random_maze(5, 6, 0.15, 3, random.Random(20261126)))
    write("5_io", random_maze(20, 20, 0.12, 13, random.Random(777)))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
