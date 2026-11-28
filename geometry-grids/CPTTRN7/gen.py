#!/usr/bin/env python3
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parent


def diamond_tile(size):
    side = 2 * size
    rows = [["." for _ in range(side)] for _ in range(side)]
    for step in range(size):
        rows[step][size - 1 - step] = "/"
        rows[step][size + step] = "\\"
        rows[size + step][step] = "\\"
        rows[size + step][side - 1 - step] = "/"
    return ["".join(row) for row in rows]


def oracle(cases):
    blocks = []
    for row_count, column_count, size in cases:
        tile = diamond_tile(size)
        lines = []
        for _ in range(row_count):
            lines.extend(row * column_count for row in tile)
        blocks.append("\n".join(lines) + "\n\n")
    return "".join(blocks)


SAMPLE = [(3, 1, 2), (4, 4, 1), (2, 5, 2)]
SAMPLE_OUTPUT = r"""./\.
/..\
\../
.\/.
./\.
/..\
\../
.\/.
./\.
/..\
\../
.\/.

/\/\/\/\
\/\/\/\/
/\/\/\/\
\/\/\/\/
/\/\/\/\
\/\/\/\/
/\/\/\/\
\/\/\/\/

./\../\../\../\../\.
/..\/..\/..\/..\/..\
\../\../\../\../\../
.\/..\/..\/..\/..\/.
./\../\../\../\../\.
/..\/..\/..\/..\/..\
\../\../\../\../\../
.\/..\/..\/..\/..\/.

"""
assert diamond_tile(1) == ["/\\", "\\/"]
assert diamond_tile(2) == ["./\\.", "/..\\", "\\../", ".\\/."]
assert oracle(SAMPLE) == SAMPLE_OUTPUT
assert len(SAMPLE_OUTPUT.splitlines()) == 31


def write(name, cases):
    lines = [str(len(cases))]
    lines.extend(" ".join(str(value) for value in case) for case in cases)
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(cases))


def trace():
    size = 3
    side = 2 * size
    print(f"size {size}, tile side {side}, slash sum {size - 1}")
    for row in range(side):
        marks = []
        for column in range(side):
            total = row + column
            gap = abs(row - column)
            if total % side == size - 1:
                marks.append("/")
            elif gap == size:
                marks.append("\\")
            else:
                marks.append(".")
        print(f"row {row}: {''.join(marks)}")
    print("repeat the tile every 6 rows and columns")


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace()
    else:
        write("1_sample", SAMPLE)
        write("2_edges", [(1, 1, 1), (1, 1, 9), (1, 99, 1), (99, 1, 1), (2, 2, 2), (99, 99, 1)])
        random.seed(2026)
        write("3_wide", [(random.randint(1, 99), random.randint(1, 99), 1) for _ in range(20)])
        write("4_random", [(random.randint(1, 20), random.randint(1, 20), random.randint(1, 5)) for _ in range(50)])
        write("5_io", [(30, 30, 5) for _ in range(30)])
