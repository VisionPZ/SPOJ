#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def solve_case(rows, blocked):
    row_count = len(rows)
    column_count = len(rows[0])

    @lru_cache(maxsize=None)
    def recurse(state, turn):
        best = None
        for row_index in range(row_count):
            left, right = state[row_index]
            remaining = column_count - left - right
            if remaining <= 0:
                continue
            candidates = []
            if blocked[row_index]:
                candidates.append(("R", rows[row_index][column_count - 1 - right]))
            else:
                candidates.append(("L", rows[row_index][left]))
                if remaining > 1:
                    candidates.append(("R", rows[row_index][column_count - 1 - right]))
            for side, value in candidates:
                changed = list(state)
                changed[row_index] = (left + 1, right) if side == "L" else (left, right + 1)
                result = value - recurse(tuple(changed), 1 - turn)
                if best is None or result > best:
                    best = result
        return 0 if best is None else best

    advantage = recurse(tuple((0, 0) for _ in range(row_count)), 0)
    total = sum(sum(row) for row in rows)
    winner_score = (total + abs(advantage)) // 2
    return ("first" if advantage > 0 else "second") + " " + str(winner_score)


def oracle(text):
    tokens = text.split()
    position = 0
    answers = []
    while True:
        row_count = int(tokens[position])
        column_count = int(tokens[position + 1])
        blocked_count = int(tokens[position + 2])
        position += 3
        if row_count == 0 and column_count == 0 and blocked_count == 0:
            break
        blocked = [False] * row_count
        for _ in range(blocked_count):
            blocked[int(tokens[position]) - 1] = True
            position += 1
        rows = []
        for _ in range(row_count):
            rows.append(tuple(int(value) for value in tokens[position:position + column_count]))
            position += column_count
        answers.append(solve_case(tuple(rows), tuple(blocked)))
    return "\n".join(answers) + "\n"


SAMPLE = """2 2 2
1 2
500 10
3 10
3 3 2
1 3
0 1 2
3 7 4
0 0 9
0 0 0
"""
SAMPLE_OUT = """second 503
first 17
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1 0\n7\n0 0 0\n") == "first 7\n"
assert oracle("1 2 0\n5 3\n0 0 0\n") == "first 5\n"
assert oracle("1 2 1\n1\n5 3\n0 0 0\n") == "second 5\n"
assert oracle("1 3 0\n-5 9 -2\n0 0 0\n") == "second 9\n"


def write(name, cases):
    lines = []
    for rows, blocked in cases:
        lines.append(f"{len(rows)} {len(rows[0])} {len(blocked)}")
        if blocked:
            lines.append(" ".join(str(index) for index in blocked))
        for row in rows:
            lines.append(" ".join(str(value) for value in row))
    lines.append("0 0 0")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        ([[7]], []),
        ([[5, 3]], []),
        ([[5, 3]], [1]),
        ([[-5, 9, -2]], []),
        ([[1, 2], [3, 4]], [1, 2]),
        ([[2, 8, 1], [9, 4, 6]], [2]),
    ])
    write("3_wide", [
        ([[500, 10], [3, 10]], [1, 2]),
        ([[0, 1, 2], [3, 7, 4], [0, 0, 9]], [1, 3]),
        ([[10, -20, 30, -40], [15, 25, -35, 45]], [1]),
    ])
    rng = random.Random(20261126)
    cases = []
    for _ in range(12):
        rows_count = rng.randint(1, 3)
        columns_count = rng.randint(1, 4)
        rows = [[rng.randint(-20, 20) for _ in range(columns_count)] for _ in range(rows_count)]
        blocked = [index + 1 for index in range(rows_count) if rng.random() < 0.5]
        cases.append((rows, blocked))
    write("4_random", cases)
    io_cases = []
    for _ in range(30):
        rows = [[rng.randint(-99, 99) for _ in range(4)] for _ in range(3)]
        blocked = [index + 1 for index in range(3) if rng.random() < 0.5]
        io_cases.append((rows, blocked))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    ([[500, 10], [3, 10]], [1, 2]),
    ([[0, 1, 2], [3, 7, 4], [0, 0, 9]], [1, 3]),
])
build()
