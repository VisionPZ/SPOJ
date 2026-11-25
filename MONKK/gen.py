#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_grid(grid):
    row_count = len(grid)
    column_count = len(grid[0]) if grid else 0
    if row_count == 0 or column_count == 0:
        return 0
    values = [[1 if cell == 'B' else -1 if cell == 'T' else 0 for cell in row]
              for row in grid]
    prefix = [[0] * (column_count + 1) for _ in range(row_count + 1)]
    for column_index in range(column_count):
        for row_index in range(row_count):
            prefix[row_index + 1][column_index + 1] = (
                prefix[row_index][column_index + 1] + prefix[row_index + 1][column_index]
                - prefix[row_index][column_index] + values[row_index][column_index])
    best = 0
    for top in range(row_count):
        for left in range(column_count):
            limit = min(row_count - top, column_count - left)
            for side in range(1, limit + 1):
                total = (prefix[top + side][left + side] - prefix[top][left + side]
                         - prefix[top + side][left] + prefix[top][left])
                if total > best:
                    best = total
    return best


def brute_grid(grid):
    row_count = len(grid)
    column_count = len(grid[0]) if grid else 0
    values = [[1 if cell == 'B' else -1 if cell == 'T' else 0 for cell in row]
              for row in grid]
    best = 0
    for top in range(row_count):
        for left in range(column_count):
            for side in range(1, min(row_count - top, column_count - left) + 1):
                total = 0
                for row_index in range(top, top + side):
                    total += sum(values[row_index][left:left + side])
                if total > best:
                    best = total
    return best


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for case_number in range(1, case_count + 1):
        rows = int(tokens[cursor]); cursor += 1
        columns = int(tokens[cursor]); cursor += 1
        grid = [tokens[cursor + index] for index in range(rows)]
        cursor += rows
        answers.append(f"Case {case_number}: {oracle_grid(grid)}")
    return "\n".join(answers) + "\n"


SAMPLE = "2\n\n3 3\nBBB\nBBB\nBBB\n\n5 5\nT.BBB\nTBBBB\n.BBBB\nTBBBB\n.BBBB\n"
SAMPLE_OUT = "Case 1: 9\nCase 2: 16\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_grid(["T"]) == 0
assert oracle_grid(["BBB", "BBB", "BBB"]) == 9
assert oracle_grid(["T.BBB", "TBBBB", ".BBBB", "TBBBB", ".BBBB"]) == 16

rng = random.Random(20261126)
for _ in range(80):
    rows = rng.randint(1, 6)
    columns = rng.randint(1, 6)
    grid = ["".join(rng.choice("BT.") for _ in range(columns)) for _ in range(rows)]
    assert oracle_grid(grid) == brute_grid(grid)


def write(name, grids, raw_input=None, raw_output=None):
    parts = [str(len(grids))]
    for grid in grids:
        rows = len(grid)
        columns = len(grid[0]) if grid else 0
        parts.append(f"{rows} {columns}")
        parts.extend(grid)
    text = raw_input if raw_input is not None else "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(
        raw_output if raw_output is not None else oracle(text))


def build():
    write("2_edges", [[], ["T"], ["."], ["B"], ["TT", "TT"], ["BB", "BB"]])
    write("3_wide", [["B" * 100 for _ in range(100)],
                     ["T" * 100 for _ in range(100)]])
    wide = []
    for _ in range(60):
        rows = rng.randint(50, 100)
        columns = rng.randint(50, 100)
        wide.append(["".join(rng.choice("BB.BT") for _ in range(columns))
                     for _ in range(rows)])
    write("4_random", wide[:10])
    write("5_io", wide[10:])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [["BBB", "BBB", "BBB"],
                   ["T.BBB", "TBBBB", ".BBBB", "TBBBB", ".BBBB"]],
      raw_input=SAMPLE, raw_output=SAMPLE_OUT)
build()
