#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def parse(text):
    tokens = text.split()
    cursor = 0
    cases = []
    while cursor < len(tokens):
        rows = int(tokens[cursor]); cursor += 1
        columns = int(tokens[cursor]); cursor += 1
        if rows == 0 and columns == 0:
            break
        yeyenum = []
        for _ in range(rows):
            yeyenum.append([int(value) for value in tokens[cursor:cursor + columns]])
            cursor += columns
        bloggium = []
        for _ in range(rows):
            bloggium.append([int(value) for value in tokens[cursor:cursor + columns]])
            cursor += columns
        cases.append((yeyenum, bloggium))
    return cases


def oracle(text, trace=False):
    answers = []
    for yeyenum, bloggium in parse(text):
        rows = len(yeyenum)
        columns = len(yeyenum[0]) if rows else 0
        y_prefix = []
        b_suffix = []
        for row_index in range(rows):
            y_row = [0]
            for value in yeyenum[row_index]:
                y_row.append(y_row[-1] + value)
            y_prefix.append(y_row)
            b_row = [0] * (columns + 1)
            for column_index in range(columns - 1, -1, -1):
                b_row[column_index] = b_row[column_index + 1] + bloggium[row_index][column_index]
            b_suffix.append(b_row)
        best = [-10**18] * (columns + 1)
        best[0] = 0
        for row_index in range(rows):
            updated = [-10**18] * (columns + 1)
            for previous in range(columns + 1):
                if best[previous] == -10**18:
                    continue
                for split in range(columns + 1):
                    boundary = max(previous, split)
                    total = (best[previous] + y_prefix[row_index][split]
                             + b_suffix[row_index][boundary])
                    if total > updated[boundary]:
                        updated[boundary] = total
            if trace:
                print(f"row {row_index + 1} best {updated}")
            best = updated
        answers.append(str(max(best)))
    return "\n".join(answers) + "\n"


SAMPLE = """4 4
0 0 10 9
1 3 10 0
4 2 1 3 
1 1 20 0
10 0 0 0
1 1 1 30
0 0 5 5
5 10 10 10
0 0
"""
SAMPLE_OUT = """98
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n5\n7\n0 0\n") == "7\n"
assert oracle("1 3\n1 2 3\n0 0 0\n0 0\n") == "6\n"
assert oracle("2 1\n9\n1\n0\n8\n0 0\n") == "10\n"
assert max([0, 0, 10, 9]) == 10


def encode_case(yeyenum, bloggium):
    rows = len(yeyenum)
    columns = len(yeyenum[0])
    lines = [f"{rows} {columns}"]
    for row in yeyenum:
        lines.append(" ".join(str(value) for value in row))
    for row in bloggium:
        lines.append(" ".join(str(value) for value in row))
    lines.append("0 0")
    return "\n".join(lines) + "\n"


def write(name, cases):
    text = "".join(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        encode_case([[5]], [[7]]),
        encode_case([[0, 0, 0]], [[0, 0, 0]]),
        encode_case([[1000], [1000]], [[1000], [1000]]),
        encode_case([[1, 2, 3], [4, 5, 6]], [[6, 5, 4], [3, 2, 1]]),
    ])
    rng = random.Random(20261125)
    wide = encode_case([[rng.randint(0, 1000) for _ in range(20)]
                        for _ in range(500)],
                       [[rng.randint(0, 1000) for _ in range(20)]
                        for _ in range(500)])
    write("3_wide", [wide])
    random_cases = []
    for rows, columns in ((3, 4), (20, 12), (50, 30)):
        random_cases.append(encode_case(
            [[rng.randint(0, 1000) for _ in range(columns)] for _ in range(rows)],
            [[rng.randint(0, 1000) for _ in range(columns)] for _ in range(rows)]))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(40):
        columns = 30
        io_cases.append(encode_case(
            [[1000] * columns for _ in range(20)],
            [[1000] * columns for _ in range(20)]))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [SAMPLE])
build()
