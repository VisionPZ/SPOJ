#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOVE = {"U": (0, -1), "D": (0, 1), "L": (-1, 0), "R": (1, 0)}


def brute_case(row_limit, column_limit, start, end, directions):
    start_row, start_column = start
    end_row, end_column = end
    queue = deque()
    seen = set()
    best = [None, None]
    for ant_type in (0, 1):
        queue.append((start_row, start_column, ant_type, 0))
        seen.add((start_row, start_column, ant_type))
    while queue:
        row, column, ant_type, distance = queue.popleft()
        if (row, column) == (end_row, end_column) and best[ant_type] is None:
            best[ant_type] = distance
        for group_index in (0, 1):
            group = directions[0:2] if group_index == 0 else directions[2:4]
            for direction in group:
                delta_row, delta_column = MOVE[direction]
                next_row = row + delta_row
                next_column = column + delta_column
                if not (0 <= next_row < row_limit and 0 <= next_column < column_limit):
                    continue
                state = (next_row, next_column, group_index)
                if state not in seen:
                    seen.add(state)
                    queue.append((next_row, next_column, group_index, distance + 1))
    if best[0] is None or best[1] is None:
        return -1
    return best[0] + best[1]


def reachable_by_time(start_row, start_column, row, column, time):
    return abs(row - start_row) + abs(column - start_column) <= time


def type_time(row_limit, column_limit, start, end, directions):
    start_row, start_column = start
    end_row, end_column = end
    best_time = None
    for direction in directions:
        delta_row, delta_column = MOVE[direction]
        row = end_row - delta_row
        column = end_column - delta_column
        if not (0 <= row < row_limit and 0 <= column < column_limit):
            continue
        low = 0
        high = row_limit + column_limit
        while low < high:
            middle = (low + high) // 2
            if reachable_by_time(start_row, start_column, row, column, middle):
                high = middle
            else:
                low = middle + 1
        candidate = low + 1
        if best_time is None or candidate < best_time:
            best_time = candidate
    return best_time


def oracle(text):
    tokens = text.split()
    scan = 0
    test_count = int(tokens[scan]); scan += 1
    lines = []
    for _ in range(test_count):
        row_limit = int(tokens[scan]); scan += 1
        column_limit = int(tokens[scan]); scan += 1
        start_row = int(tokens[scan]); scan += 1
        start_column = int(tokens[scan]); scan += 1
        end_row = int(tokens[scan]); scan += 1
        end_column = int(tokens[scan]); scan += 1
        directions = tokens[scan]; scan += 1
        if (start_row, start_column) == (end_row, end_column):
            lines.append("0")
            continue
        first_time = type_time(row_limit, column_limit, (start_row, start_column),
                               (end_row, end_column), directions[0:2])
        second_time = type_time(row_limit, column_limit, (start_row, start_column),
                                (end_row, end_column), directions[2:4])
        if first_time is None or second_time is None:
            lines.append("-1")
        else:
            lines.append(str(first_time + second_time))
    return "\n".join(lines) + "\n"


SAMPLE = """3
5 5
1 1
3 4
LRUD
2 4
0 2
0 3
RULD
2 4
0 2
1 1
URDL
"""
SAMPLE_OUT = "10\n-1\n6\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute_case(5, 5, (1, 1), (3, 4), "LRUD") == 10
assert brute_case(2, 4, (0, 2), (0, 3), "RULD") == -1
assert brute_case(2, 4, (0, 2), (1, 1), "URDL") == 6
assert oracle("1\n3 3\n1 1\n1 1\nLRUD\n") == "0\n"
assert oracle("1\n5 5\n0 0\n4 4\nLRUD\n") == "16\n"
assert oracle("1\n1 5\n0 0\n0 4\nLRUD\n") == "-1\n"
assert sum(MOVE["U"]) == -1


def write(name, cases):
    text = str(len(cases)) + "\n"
    for row_limit, column_limit, start, end, directions in cases:
        text += (f"{row_limit} {column_limit}\n{start[0]} {start[1]}\n"
                 f"{end[0]} {end[1]}\n{directions}\n")
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("1_sample", [(5, 5, (1, 1), (3, 4), "LRUD"),
                       (2, 4, (0, 2), (0, 3), "RULD"),
                       (2, 4, (0, 2), (1, 1), "URDL")])
    write("2_edges", [(3, 3, (1, 1), (1, 1), "LRUD"),
                      (4, 4, (0, 0), (3, 3), "UDLR")])
    rng = random.Random(20261126)
    directions = ["LRUD", "RULD", "URDL", "DLUR", "UDRL", "LDRU"]
    wide = []
    for _ in range(20):
        row_limit = rng.randint(2, 12)
        column_limit = rng.randint(2, 12)
        start = (rng.randrange(row_limit), rng.randrange(column_limit))
        end = (rng.randrange(row_limit), rng.randrange(column_limit))
        wide.append((row_limit, column_limit, start, end, rng.choice(directions)))
    write("3_wide", wide)
    random_cases = []
    for _ in range(20):
        row_limit = rng.randint(3, 40)
        column_limit = rng.randint(3, 40)
        start = (rng.randrange(row_limit), rng.randrange(column_limit))
        end = (rng.randrange(row_limit), rng.randrange(column_limit))
        permuted = rng.sample("LRUD", 4)
        random_cases.append((row_limit, column_limit, start, end, "".join(permuted)))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(100):
        row_limit = rng.randint(100, 5000)
        column_limit = rng.randint(100, 5000)
        start = (rng.randrange(row_limit), rng.randrange(column_limit))
        end = (rng.randrange(row_limit), rng.randrange(column_limit))
        io_cases.append((row_limit, column_limit, start, end, rng.choice(directions)))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
build()
