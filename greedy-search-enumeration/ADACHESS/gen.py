#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def neighbours(figure, row, col):
    result = []
    if figure == 0:
        for step_row in (-1, 0, 1):
            for step_col in (-1, 0, 1):
                if step_row or step_col:
                    result.append((row + step_row, col + step_col))
    elif figure == 1:
        for step_row, step_col in ((1, 2), (2, 1), (-1, 2), (-2, 1),
                                   (1, -2), (2, -1), (-1, -2), (-2, -1)):
            result.append((row + step_row, col + step_col))
    else:
        if figure == 3:
            directions = [(0, 1), (0, -1), (1, 0), (-1, 0)]
        elif figure == 4:
            directions = [(1, 1), (1, -1), (-1, 1), (-1, -1)]
        else:
            directions = [(0, 1), (0, -1), (1, 0), (-1, 0),
                          (1, 1), (1, -1), (-1, 1), (-1, -1)]
        for step_row, step_col in directions:
            distance = 1
            while True:
                target_row = row + distance * step_row
                target_col = col + distance * step_col
                if not (0 <= target_row < 8 and 0 <= target_col < 8):
                    break
                result.append((target_row, target_col))
                distance += 1
    return [(target_row, target_col) for target_row, target_col in result
            if 0 <= target_row < 8 and 0 <= target_col < 8]


def distances(figure, row, col):
    known = {(row, col): 0}
    queue = deque([(row, col)])
    while queue:
        current_row, current_col = queue.popleft()
        for square in neighbours(figure, current_row, current_col):
            if square not in known:
                known[square] = known[(current_row, current_col)] + 1
                queue.append(square)
    return known


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    position = 1
    lines = []
    for _ in range(case_count):
        first_figure, first_row, first_col, second_figure, second_row, second_col = tokens[position:position + 6]
        position += 6
        first_distances = distances(first_figure, first_row, first_col)
        second_distances = distances(second_figure, second_row, second_col)
        best = None
        for square in first_distances:
            if square in second_distances:
                total = first_distances[square] + second_distances[square]
                if best is None or total < best:
                    best = total
        lines.append("INF" if best is None else str(best))
    return "\n".join(lines) + ("\n" if lines else "")


SAMPLE = "5\n1 0 0 1 7 7\n2 1 3 3 2 5 \n0 1 0 4 5 5\n3 1 1 4 3 3\n0 1 2 0 3 4\n"
SAMPLE_OUT = "6\n2\n2\n1\n2\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0 0 0 0 0 0\n") == "0\n"
assert oracle("1\n4 0 0 4 1 0\n") == "INF\n"
assert oracle("1\n3 0 0 3 7 7\n") == "2\n"
assert oracle("1\n1 0 0 1 1 1\n") == "4\n"


def write(name, cases):
    lines = [str(len(cases))]
    for case in cases:
        lines.append(" ".join(str(value) for value in case))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    edge_cases = [
        (0, 0, 0, 0, 0, 0),
        (4, 0, 0, 4, 1, 0),
        (4, 0, 0, 4, 7, 7),
        (3, 0, 0, 3, 7, 7),
        (1, 0, 0, 1, 0, 0),
        (2, 0, 0, 1, 7, 7),
        (3, 3, 3, 4, 3, 3),
        (1, 7, 7, 0, 0, 0),
    ]
    write("2_edges", edge_cases)
    wide_cases = []
    for first_figure in range(5):
        for second_figure in range(5):
            wide_cases.append((first_figure, 0, 0, second_figure, 7, 7))
            wide_cases.append((first_figure, 3, 4, second_figure, 4, 3))
    write("3_wide", wide_cases)
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(600):
        random_cases.append(tuple(rng.randrange(5) if index in (0, 3) else rng.randrange(8)
                                  for index in range(6)))
    write("4_random", random_cases)
    io_cases = [(4, first_row, first_col, 4, 1 - first_row, first_col)
                for first_row in range(8) for first_col in range(8)]
    io_cases = io_cases * 60
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
