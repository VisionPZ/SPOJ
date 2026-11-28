#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    values = [int(value) for value in text.split()]
    pos = 0
    lines = []
    case_number = 0
    while pos + 1 < len(values):
        rows = values[pos]
        cols = values[pos + 1]
        pos += 2
        if rows == 0 and cols == 0:
            break
        case_number += 1
        live_count = values[pos]
        pos += 1
        target = 0
        for _ in range(live_count):
            live_row = values[pos]
            live_col = values[pos + 1]
            pos += 2
            target |= 1 << (live_row * cols + live_col)
        neighbors = []
        for cell_row in range(rows):
            for cell_col in range(cols):
                cell_list = []
                for offset_row in (-1, 0, 1):
                    for offset_col in (-1, 0, 1):
                        if offset_row == 0 and offset_col == 0:
                            continue
                        wrap_row = (cell_row + offset_row) % rows
                        wrap_col = (cell_col + offset_col) % cols
                        cell_list.append(wrap_row * cols + wrap_col)
                neighbors.append(cell_list)
        cell_count = rows * cols
        counts = [0] * cell_count
        parent = 0
        matches = 0
        for step in range(1 << cell_count):
            if step:
                gray = step ^ (step >> 1)
                changed = (step & -step).bit_length() - 1
                delta = 1 if (gray >> changed) & 1 else -1
                for neighbor_index in neighbors[changed]:
                    counts[neighbor_index] += delta
                parent = gray
            else:
                parent = 0
            agrees = True
            for cell_index in range(cell_count):
                occupied = (parent >> cell_index) & 1
                neighbor_total = counts[cell_index]
                alive = (occupied and neighbor_total in (2, 3)) or (
                    (not occupied) and neighbor_total == 3
                )
                if alive != ((target >> cell_index) & 1):
                    agrees = False
                    break
            if agrees:
                matches += 1
        if matches == 0:
            lines.append(f"Case {case_number}: Garden of Eden.")
        else:
            lines.append(f"Case {case_number}: {matches} possible ancestors.")
    return "\n".join(lines) + ("\n" if lines else "")


SAMPLE = """2 3
2
0 0
0 1
3 3
4
0 0
0 1
0 2
1 1
3 3
5
0 0
1 0
1 2
2 1
2 2
0 0
"""
SAMPLE_OUT = """Case 1: 3 possible ancestors.
Case 2: 1 possible ancestors.
Case 3: Garden of Eden.
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n0\n0 0\n") == "Case 1: 2 possible ancestors.\n"
assert oracle("1 1\n1\n0 0\n0 0\n") == "Case 1: Garden of Eden.\n"
assert oracle("2 3\n2\n0 0\n0 1\n0 0\n") == "Case 1: 3 possible ancestors.\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "1 1\n0\n1 1\n1\n0 0\n2 2\n0\n0 0\n")
    write("3_wide", "4 4\n5\n0 0\n0 1\n1 2\n2 3\n3 0\n0 0\n")
    rng = random.Random(20261125)
    cases = []
    for _ in range(12):
        rows = rng.randint(1, 4)
        cols = rng.randint(1, 16 // rows)
        live_count = rng.randint(0, rows * cols)
        cells = rng.sample(range(rows * cols), live_count)
        cases.append(f"{rows} {cols}\n{live_count}\n")
        for cell_index in cells:
            cases.append(f"{cell_index // cols} {cell_index % cols}\n")
    cases.append("0 0\n")
    write("4_random", "".join(cases))
    io_cases = []
    for case_index in range(120):
        rows = 1 + (case_index % 2)
        cols = 1 + (case_index % 2)
        live_count = case_index % (rows * cols + 1)
        cells = list(range(rows * cols))[:live_count]
        io_cases.append(f"{rows} {cols}\n{live_count}\n")
        for cell_index in cells:
            io_cases.append(f"{cell_index // cols} {cell_index % cols}\n")
    io_cases.append("0 0\n")
    write("5_io", "".join(io_cases))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
