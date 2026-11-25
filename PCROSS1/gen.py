#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
STATEMENT = (ROOT.parent / "stmts" / "PCROSS1.txt").read_text()

SAMPLE_INPUT = "3\n1 1 1 1\n5 5 3 3\n8 13 3 5\n"
SAMPLE_OUTPUT = (
    "*\n\n"
    "..*..\n..*..\n*****\n..*..\n..*..\n\n"
    "....*........\n....*........\n"
    "*************\n"
    "....*........\n....*........\n....*........\n....*........\n....*........\n\n"
)
SAMPLES = [(SAMPLE_INPUT, SAMPLE_OUTPUT)]


def oracle(cases):
    blocks = []
    for row_count, column_count, center_row, center_column in cases:
        full_row = "*" * column_count
        thin_row = "." * (center_column - 1) + "*" + "." * (column_count - center_column)
        grid = [thin_row for _ in range(row_count)]
        grid[center_row - 1] = full_row
        blocks.append("\n".join(grid) + "\n\n")
    return "".join(blocks)


for sample_input, sample_output in SAMPLES:
    assert sample_input in STATEMENT
    assert sample_output in STATEMENT
    assert oracle([(1, 1, 1, 1), (5, 5, 3, 3), (8, 13, 3, 5)]) == sample_output

assert oracle([(1, 1, 1, 1)]) == "*\n\n"
assert oracle([(2, 3, 1, 1)]) == "***\n*..\n\n"
assert oracle([(3, 3, 2, 2)]) == ".*.\n***\n.*.\n\n"
assert oracle([(1, 100, 1, 100)]) == "*" * 100 + "\n\n"


def write(name, cases):
    lines = [str(len(cases))]
    lines.extend(" ".join(map(str, case)) for case in cases)
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(cases))


def trace(row_count, column_count, center_row, center_column):
    full_row = "*" * column_count
    thin_row = "." * (center_column - 1) + "*" + "." * (column_count - center_column)
    lines = [f"case {row_count} by {column_count}, center row {center_row}, column {center_column}"]
    lines.append(f"row {center_row} is the full row {full_row}")
    lines.append(f"every other row is {thin_row}")
    lines.append("then one blank line")
    return "\n".join(lines)


write("1_sample", [(1, 1, 1, 1), (5, 5, 3, 3), (8, 13, 3, 5)])
write("2_edges", [(1, 1, 1, 1), (1, 100, 1, 1), (100, 1, 100, 1),
                  (100, 100, 1, 100), (2, 3, 1, 1), (3, 3, 2, 2)])
random.seed(2026)


def random_case(row_limit=100, column_limit=100):
    row_count = random.randint(1, row_limit)
    column_count = random.randint(1, column_limit)
    return (row_count, column_count, random.randint(1, row_count),
            random.randint(1, column_count))


write("3_wide", [random_case() for _ in range(100)])
write("4_random", [random_case(100, 100) for _ in range(100)])
write("5_io", [(100, 100, 50, 50) for _ in range(100)])

if __name__ == "__main__":
    print(trace(5, 5, 3, 3))
