#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    pos = 0
    answers = []
    while pos + 1 < len(tokens):
        width = int(tokens[pos])
        height = int(tokens[pos + 1])
        pos += 2
        if width == 0 and height == 0:
            break
        rows = tokens[pos:pos + height]
        pos += height
        blocked = set()
        dirty = []
        start = None
        for row_index, row in enumerate(rows):
            for col_index, cell in enumerate(row):
                if cell == "x":
                    blocked.add((row_index, col_index))
                elif cell == "*":
                    dirty.append((row_index, col_index))
                elif cell == "o":
                    start = (row_index, col_index)

        def distances(origin):
            seen = {origin: 0}
            queue = deque([origin])
            while queue:
                row, col = queue.popleft()
                for delta_row, delta_col in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nxt = (row + delta_row, col + delta_col)
                    if not (0 <= nxt[0] < height and 0 <= nxt[1] < width):
                        continue
                    if nxt in blocked or nxt in seen:
                        continue
                    seen[nxt] = seen[(row, col)] + 1
                    queue.append(nxt)
            return seen

        dirty_count = len(dirty)
        if dirty_count == 0:
            answers.append("0")
            continue
        points = [start] + dirty
        reachable = [distances(point) for point in points]
        infinite = 10 ** 9
        full_mask = (1 << dirty_count) - 1
        table = [[infinite] * dirty_count for _ in range(full_mask + 1)]
        for dirty_index in range(dirty_count):
            step_count = reachable[0].get(dirty[dirty_index], infinite)
            table[1 << dirty_index][dirty_index] = step_count
        for mask in range(1, full_mask + 1):
            for last_index in range(dirty_count):
                if not (mask >> last_index) & 1:
                    continue
                base = table[mask][last_index]
                if base >= infinite:
                    continue
                for next_index in range(dirty_count):
                    if (mask >> next_index) & 1:
                        continue
                    step_count = reachable[last_index + 1].get(dirty[next_index], infinite)
                    candidate = base + step_count
                    next_mask = mask | (1 << next_index)
                    if candidate < table[next_mask][next_index]:
                        table[next_mask][next_index] = candidate
        best = min(table[full_mask])
        answers.append(str(best) if best < infinite else "-1")
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
assert oracle("1 1\no\n0 0\n") == "0\n"
assert oracle("1 2\n*\no\n0 0\n") == "1\n"
assert oracle("1 3\no\nx\n*\n0 0\n") == "-1\n"
assert oracle("2 2\n.o\n.*\n0 0\n") == "1\n"


def render(width, height, grid):
    return f"{width} {height}\n" + "\n".join("".join(row) for row in grid) + "\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "1 1\no\n1 2\n*\no\n1 3\no\nx\n*\n2 2\n.o\n.*\n0 0\n")
    wide = [["." for _ in range(20)] for _ in range(20)]
    wide[0][0] = "o"
    for cell_index in range(10):
        wide[19][cell_index * 2] = "*"
    write("3_wide", render(20, 20, wide) + "0 0\n")
    rng = random.Random(20261124)
    cases = []
    for _ in range(8):
        width = rng.randint(3, 10)
        height = rng.randint(3, 10)
        grid = [["." for _ in range(width)] for _ in range(height)]
        free = [(row, col) for row in range(height) for col in range(width)]
        rng.shuffle(free)
        start = free.pop()
        grid[start[0]][start[1]] = "o"
        for _ in range(rng.randint(0, 3)):
            grid[free[-1][0]][free[-1][1]] = "x"
            free.pop()
        for _ in range(rng.randint(1, 5)):
            if not free:
                break
            cell = free.pop()
            grid[cell[0]][cell[1]] = "*"
        cases.append(render(width, height, grid))
    cases.append("0 0\n")
    write("4_random", "".join(cases))
    io_cases = []
    for case_index in range(60):
        width = 4
        height = 2
        grid = [["." for _ in range(width)] for _ in range(height)]
        grid[0][0] = "o"
        grid[0][1 + case_index % 3] = "*"
        io_cases.append(render(width, height, grid))
    io_cases.append("0 0\n")
    write("5_io", "".join(io_cases))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
