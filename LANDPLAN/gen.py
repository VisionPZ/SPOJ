#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    sizes = tokens[1:1 + case_count]
    lines = []
    for size in sizes:
        for row in range(1, size + 1):
            cells = []
            for column in range(1, size + 1):
                if row == 1 or row == size or column == 1 or column == size:
                    cells.append("#")
                else:
                    cells.append(".")
            lines.append("".join(cells))
        lines.append("")
    return "\n".join(lines) + "\n"


SAMPLE = """3
1
2
5
"""
SAMPLE_OUT = """#

##
##

#####
#...#
#...#
#...#
#####

"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n") == "#\n\n"
assert oracle("1\n2\n") == "##\n##\n\n"
assert oracle("1\n3\n") == "###\n#.#\n###\n\n"


def write(name, sizes):
    text = "\n".join([str(len(sizes))] + [str(size) for size in sizes]) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 1, 2])
    write("3_wide", [100, 99, 98])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 100) for _ in range(10)])
    write("5_io", [100] * 10)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
