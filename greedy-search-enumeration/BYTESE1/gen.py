#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10 ** 9


def parse(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    cases = []
    for _ in range(case_count):
        rows = tokens[cursor]
        cols = tokens[cursor + 1]
        cursor += 2
        guard_times = tokens[cursor:cursor + rows * cols]
        cursor += rows * cols
        target_row = tokens[cursor]
        target_col = tokens[cursor + 1]
        bomb_time = tokens[cursor + 2]
        cursor += 3
        cases.append((rows, cols, guard_times, target_row, target_col, bomb_time))
    return cases


def shortest_path(rows, cols, guard_times, target_row, target_col):
    node_count = rows * cols
    distances = [INF] * node_count
    distances[0] = guard_times[0]
    queued = [False] * node_count
    queue = deque([0])
    queued[0] = True
    while queue:
        node = queue.popleft()
        queued[node] = False
        row = node // cols
        col = node % cols
        for next_row, next_col in ((row - 1, col), (row + 1, col), (row, col - 1), (row, col + 1)):
            if next_row < 0 or next_row >= rows or next_col < 0 or next_col >= cols:
                continue
            neighbor = next_row * cols + next_col
            candidate = distances[node] + guard_times[neighbor]
            if candidate < distances[neighbor]:
                distances[neighbor] = candidate
                if not queued[neighbor]:
                    queue.append(neighbor)
                    queued[neighbor] = True
    return distances[(target_row - 1) * cols + (target_col - 1)]


def oracle(text):
    answers = []
    for rows, cols, guard_times, target_row, target_col, bomb_time in parse(text):
        needed = shortest_path(rows, cols, guard_times, target_row, target_col)
        if needed <= bomb_time:
            answers.append("YES")
            answers.append(str(bomb_time - needed))
        else:
            answers.append("NO")
    return "\n".join(answers) + "\n"


SAMPLE = """2
4 3 
2 3 2
2 5 1
5 3 1
3 1 1
4 2 15
2 2
1 2
1 1
2 2 2
"""
SAMPLE_OUT = """YES
4
NO
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1\n7\n1 1 7\n") == "YES\n0\n"
assert oracle("1\n1 2\n2 3\n1 2 5\n") == "YES\n0\n"
assert oracle("1\n2 2\n9 9 9 9\n2 2 10\n") == "NO\n"
assert shortest_path(4, 3, [2, 3, 2, 2, 5, 1, 5, 3, 1, 3, 1, 1], 4, 2) == 11


def render(cases):
    lines = [str(len(cases))]
    for rows, cols, guard_times, target_row, target_col, bomb_time in cases:
        lines.append(f"{rows} {cols}")
        for row in range(rows):
            lines.append(" ".join(str(value) for value in guard_times[row * cols:(row + 1) * cols]))
        lines.append(f"{target_row} {target_col} {bomb_time}")
    return "\n".join(lines) + "\n"


def write(name, cases):
    text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    edge_cases = [
        (1, 1, [7], 1, 1, 7),
        (1, 5, [1, 2, 3, 4, 5], 1, 5, 15),
        (5, 1, [1, 2, 3, 4, 5], 5, 1, 5),
        (2, 2, [4, 4, 4, 4], 1, 1, 0),
        (2, 2, [9, 9, 9, 9], 2, 2, 3),
    ]
    write("2_edges", edge_cases)
    write("3_wide", [(100, 100, [1] * 10000, 100, 100, 500)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(8):
        rows = rng.randint(2, 30)
        cols = rng.randint(2, 30)
        guard_times = [rng.randint(0, 9) for _ in range(rows * cols)]
        target_row = rng.randint(1, rows)
        target_col = rng.randint(1, cols)
        bomb_time = rng.randint(0, 400)
        random_cases.append((rows, cols, guard_times, target_row, target_col, bomb_time))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(20):
        rows = 60
        cols = 60
        guard_times = [rng.randint(0, 9) for _ in range(rows * cols)]
        target_row = rng.randint(1, rows)
        target_col = rng.randint(1, cols)
        bomb_time = rng.randint(200, 500)
        io_cases.append((rows, cols, guard_times, target_row, target_col, bomb_time))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
