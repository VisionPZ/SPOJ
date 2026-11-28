#!/usr/bin/env python3
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """e2 e4
a1 b2
b2 c3
a1 h8
a1 h7
h8 a1
b1 c3
f6 f6
"""
SAMPLE_OUTPUT = """To get from e2 to e4 takes 2 knight moves.
To get from a1 to b2 takes 4 knight moves.
To get from b2 to c3 takes 2 knight moves.
To get from a1 to h8 takes 6 knight moves.
To get from a1 to h7 takes 5 knight moves.
To get from h8 to a1 takes 6 knight moves.
To get from b1 to c3 takes 1 knight moves.
To get from f6 to f6 takes 0 knight moves.
"""

SQUARES = [chr(97 + column) + str(1 + row)
           for row in range(8) for column in range(8)]
STEPS = [(1, 2), (2, 1), (2, -1), (1, -2),
         (-1, -2), (-2, -1), (-2, 1), (-1, 2)]
INF = 99


def square_index(name):
    return SQUARES.index(name)


def floyd_warshall():
    distance = [[INF] * 64 for _ in range(64)]
    for index in range(64):
        distance[index][index] = 0
    for index, name in enumerate(SQUARES):
        column = ord(name[0]) - 97
        row = int(name[1]) - 1
        for delta_x, delta_y in STEPS:
            new_column, new_row = column + delta_x, row + delta_y
            if 0 <= new_column < 8 and 0 <= new_row < 8:
                neighbor = new_row * 8 + new_column
                distance[index][neighbor] = 1
    for middle in range(64):
        row_middle = distance[middle]
        for start in range(64):
            row_start = distance[start]
            through = row_start[middle]
            for end in range(64):
                candidate = through + row_middle[end]
                if candidate < row_start[end]:
                    row_start[end] = candidate
    return distance


DISTANCE = floyd_warshall()


def oracle(text):
    parts = text.split()
    answers = []
    for index in range(0, len(parts) - 1, 2):
        moves = DISTANCE[square_index(parts[index])][square_index(parts[index + 1])]
        answers.append("To get from %s to %s takes %d knight moves." %
                       (parts[index], parts[index + 1], moves))
    return "\n".join(answers) + "\n" if answers else ""


def write(name, pairs):
    input_text = "".join("%s %s\n" % (pair[0], pair[1]) for pair in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert DISTANCE[square_index("a1")][square_index("h8")] == 6
assert DISTANCE[square_index("f6")][square_index("f6")] == 0
assert DISTANCE[square_index("b1")][square_index("c3")] == 1


def trace_example():
    for start, end in [("e2", "e4"), ("a1", "b2"), ("a1", "h8")]:
        print(start, end, DISTANCE[square_index(start)][square_index(end)])


if "--trace" in sys.argv:
    trace_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [line.split() for line in SAMPLE_INPUT.strip().split("\n")])
    write("2_edges", [("a1", "a1"), ("h8", "h8"), ("a1", "h8"),
                      ("h8", "a1"), ("a1", "b2"), ("f6", "f6"),
                      ("a8", "h1"), ("d4", "d5")])
    write("3_wide", [(start, end) for start in SQUARES for end in SQUARES])
    random.seed(20261125)
    write("4_random", [(random.choice(SQUARES), random.choice(SQUARES))
                       for _ in range(6000)])
    write("5_io", [(random.choice(SQUARES), random.choice(SQUARES))
                   for _ in range(40000)])
