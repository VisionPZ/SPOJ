#!/usr/bin/env python3
from collections import deque
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10 ** 9


def oracle(text):
    tokens = text.split()
    land_length = int(tokens[0])
    rock_count = int(tokens[1])
    rocks = []
    for index in range(rock_count):
        rocks.append((int(tokens[2 + 2 * index]), int(tokens[3 + 2 * index])))
    treasure_depth = int(tokens[2 + 2 * rock_count])
    treasure_column = int(tokens[3 + 2 * rock_count])
    columns = land_length + 1
    column_rocks = [[] for _ in range(columns)]
    for depth, column in rocks:
        column_rocks[column].append(depth)
    for depths in column_rocks:
        depths.sort()
    max_depth = max([0] + [depth for depth, _ in rocks] + [treasure_depth]) + 1
    total_states = (max_depth + 1) * columns * 2
    distances = [INF] * total_states
    queue = deque()

    def state_index(depth, column, flag):
        return (depth * columns + column) * 2 + flag

    def first_below(depth, column):
        depths = column_rocks[column]
        left, right = 0, len(depths)
        while left < right:
            middle = (left + right) // 2
            if depths[middle] <= depth:
                left = middle + 1
            else:
                right = middle
        return depths[left] if left < len(depths) else None

    def replacement_flag(depth, column, rock_ahead, flag):
        if flag:
            return 1
        if depth == treasure_depth:
            return 1
        if depth > treasure_depth:
            return -1
        if column == treasure_column:
            if rock_ahead is None or rock_ahead > treasure_depth + 1:
                return -1
            return 1 if rock_ahead == treasure_depth + 1 else 0
        if column == treasure_column - 1 or column == treasure_column + 1:
            return 1 if (rock_ahead is None or rock_ahead >= treasure_depth + 1) else 0
        return 0

    for column in range(columns):
        start = state_index(0, column, 0)
        distances[start] = 0
        queue.append(start)
    answer = INF
    while queue:
        current = queue.popleft()
        cost = distances[current]
        without_flag = current % 2
        remainder = current // 2
        column = remainder % columns
        depth = remainder // columns
        if without_flag == 0 and depth == treasure_depth:
            target = state_index(depth, column, 1)
            if cost < distances[target]:
                distances[target] = cost
                queue.append(target)
        if without_flag == 0 and depth > treasure_depth:
            continue
        for next_column in range(columns):
            rock_ahead = first_below(depth, next_column)
            flag = replacement_flag(depth, next_column, rock_ahead, without_flag)
            if flag < 0:
                continue
            if rock_ahead is None:
                if flag == 1 and cost < answer:
                    answer = cost
            else:
                target = state_index(rock_ahead - 1, next_column, flag)
                if cost + 1 < distances[target]:
                    distances[target] = cost + 1
                    queue.append(target)
    if answer == INF:
        return "Use dynamite\n"
    return str(answer) + "\n"


SAMPLE = """10 20
1 5
2 1
2 2
2 4
2 5
2 6
2 8
2 9
3 3
4 7
4 8
4 9
5 3
5 4
5 5
5 6
6 3
10 1
10 2
10 7
8 6
"""
SAMPLE_OUT = """3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 0\n5 0\n") == "0\n"
assert oracle("1 2\n2 0\n2 1\n5 0\n") == "Use dynamite\n"


def write(name, land_length, rocks, treasure_depth, treasure_column):
    lines = [f"{land_length} {len(rocks)}"]
    lines.extend(f"{depth} {column}" for depth, column in rocks)
    lines.append(f"{treasure_depth} {treasure_column}")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 2, [(2, 0), (2, 1)], 5, 0)
    rng = random.Random(20261126)
    wide = set()
    while len(wide) < 60:
        wide.add((rng.randint(1, 12), rng.randint(0, 200)))
    write("3_wide", 200, sorted(wide), 15, 100)
    rock_set = set()
    while len(rock_set) < 14:
        rock_set.add((rng.randint(1, 12), rng.randint(0, 10)))
    treasure = (rng.randint(1, 14), rng.randint(0, 10))
    while treasure in rock_set:
        treasure = (rng.randint(1, 14), rng.randint(0, 10))
    write("4_random", 10, sorted(rock_set), treasure[0], treasure[1])
    big_set = set()
    while len(big_set) < 2000:
        big_set.add((rng.randint(1, 12), rng.randint(0, 200)))
    write("5_io", 200, sorted(big_set), 15, 100)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
def trace_example():
    print("surface -> column 7: rock at depth 4, stop at 3, bits 1")
    print("depth 3 -> column 5: rock at depth 5, stop at 4, bits 2")
    print("depth 4 -> column 7: rock at depth 10, stop at 9, bits 3")
    print("treasure at depth 8 is passed in column 7")
    print("depth 9 -> column 10: no rock below, finish")


build()
trace_example()
