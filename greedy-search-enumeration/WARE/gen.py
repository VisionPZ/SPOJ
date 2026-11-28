#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DIRECTIONS = [(1, 0), (-1, 0), (0, 1), (0, -1)]


def parse(text):
    tokens = text.split()
    cursor = 0
    cases = []
    while cursor < len(tokens):
        size = int(tokens[cursor]); cursor += 1
        start_row = int(tokens[cursor]); cursor += 1
        start_column = int(tokens[cursor]); cursor += 1
        if size == 0 and start_row == 0 and start_column == 0:
            break
        rows = tokens[cursor:cursor + size]
        cursor += size
        cases.append((size, start_row - 1, start_column - 1, rows))
    return cases


def oracle_case(size, start_row, start_column, rows):
    grid = []
    for row in rows:
        mapped = []
        for char in row:
            if char == 'E':
                mapped.append(5)
            elif char in '234':
                mapped.append(int(char))
            else:
                mapped.append(0)
        grid.append(mapped)
    start = start_row * size + start_column
    initial = (tuple(value for row in grid for value in row), start)
    if initial[0][start] != 0:
        cells = list(initial[0])
        cells[start] += 6
        initial = (tuple(cells), start)
    queue = [(initial, 0)]
    seen = {initial}
    head = 0
    while head < len(queue):
        (cells, position), depth = queue[head]
        head += 1
        if cells[position] in (5, 11):
            return str(depth)
        row, column = divmod(position, size)
        for delta_row, delta_column in DIRECTIONS:
            next_row = row + delta_row
            next_column = column + delta_column
            if 0 <= next_row < size and 0 <= next_column < size:
                target = next_row * size + next_column
                if cells[target] != 0:
                    updated = list(cells)
                    updated[position] = cells[position] - 6 if cells[position] > 5 else cells[position]
                    updated[target] = (cells[target] - 6 if cells[target] > 5 else cells[target]) + 6
                    candidate = (tuple(updated), target)
                    if candidate not in seen:
                        seen.add(candidate)
                        queue.append((candidate, depth + 1))
        height = cells[position] - 6 if cells[position] > 5 else cells[position]
        if height not in (2, 3, 4):
            continue
        for delta_row, delta_column in DIRECTIONS:
            targets = []
            for step in range(1, height + 1):
                target_row = row + delta_row * step
                target_column = column + delta_column * step
                if not (0 <= target_row < size and 0 <= target_column < size):
                    break
                target = target_row * size + target_column
                if cells[target] != 0:
                    break
                targets.append(target)
            if len(targets) != height:
                continue
            updated = list(cells)
            updated[position] = 0
            for target in targets:
                updated[target] = 1
            updated[targets[0]] = 7
            candidate = (tuple(updated), targets[0])
            if candidate not in seen:
                seen.add(candidate)
                queue.append((candidate, depth + 1))
    return "Impossible."


def oracle(text):
    return "\n".join(oracle_case(*case) for case in parse(text)) + "\n"


SAMPLE = """5 5 3
.2..E
...2.
4....
....4
..2..
0 0 0
"""
SAMPLE_OUT = """18
"""
assert oracle(SAMPLE) == SAMPLE_OUT
COMMENT = """8 6 1
........
2..3...3
........
........
.2......
332.2..2
...2....
..2E2...
0 0 0
"""
assert oracle(COMMENT) == "27\n"
assert oracle("1 1 1\nE\n0 0 0\n") == "0\n"
assert oracle("1 1 1\n2\n0 0 0\n") == "Impossible.\n"


def write(name, cases):
    blocks = []
    for size, start_row, start_column, rows in cases:
        blocks.append(f"{size} {start_row} {start_column}\n" + "\n".join(rows) + "\n")
    text = "".join(blocks) + "0 0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_case(rng, size, box_probability):
    rows = []
    for _ in range(size):
        row = []
        for _ in range(size):
            draw = rng.random()
            if draw < box_probability:
                row.append(rng.choice("234"))
            else:
                row.append(".")
        rows.append(row)
    exit_row = size - 1
    exit_column = rng.randrange(size)
    rows[exit_row][exit_column] = "E"
    start_row = rng.randrange(size)
    start_column = rng.randrange(size)
    if rows[start_row][start_column] == ".":
        rows[start_row][start_column] = "2"
    return size, start_row + 1, start_column + 1, ["".join(row) for row in rows]


def build():
    write("2_edges", [
        (1, 1, 1, ["E"]),
        (1, 1, 1, ["2"]),
        (2, 1, 1, ["2E", ".."]),
        (2, 1, 1, [".E", "2."]),
        (3, 1, 1, ["2..", "...", "..E"]),
    ])
    rng = random.Random(20261125)
    wide = [
        (8, 1, 1, ["2.2.2.2.", "........", "3.3.3.3.", "........",
                    "2.2.2.2.", "........", "4.4.4.4.", "......E2"]),
        (8, 4, 4, ["........", ".2.2.2..", "........", ".4E4....",
                    "........", ".2.2.2..", "........", "3......."]),
    ]
    write("3_wide", wide)
    random_cases = []
    for size, probability in ((3, 0.35), (4, 0.4), (5, 0.3), (6, 0.25)):
        for _ in range(3):
            random_cases.append(random_case(rng, size, probability))
    write("4_random", random_cases)
    io_cases = [random_case(rng, 4, 0.4) for _ in range(40)]
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(size, start_row + 1, start_column + 1, rows)
                   for size, start_row, start_column, rows in parse(SAMPLE)])
build()
