#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    day_count = tokens[position]
    position += 1
    answers = []
    for _ in range(day_count):
        channel_count = tokens[position]
        jump_limit = tokens[position + 1]
        wait_seconds = tokens[position + 2]
        position += 3
        values = tokens[position:position + channel_count]
        position += channel_count
        unique = sorted(set(values))
        index_of = {value: index for index, value in enumerate(unique)}
        neighbors = [[] for _ in unique]
        for left_index, left_value in enumerate(unique):
            for right_index, right_value in enumerate(unique):
                if left_index != right_index and right_value <= left_value + jump_limit:
                    neighbors[left_index].append(right_index)
        start_index = index_of[values[0]]
        distance = [-1] * len(unique)
        distance[start_index] = 0
        queue = deque([start_index])
        while queue:
            current = queue.popleft()
            for following in neighbors[current]:
                if distance[following] < 0:
                    distance[following] = distance[current] + 1
                    queue.append(following)
        best_value = max(value for value in unique if distance[index_of[value]] >= 0)
        steps = distance[index_of[best_value]]
        answers.append(f"{best_value} {steps * wait_seconds}")
    return "\n".join(answers) + "\n"


SAMPLE = """2
6 3 5
3 4 0 8 12 6
4 1 2
5 7 7 5
"""
SAMPLE_OUT = """8 10
5 0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1 7\n9\n") == "9 0\n"
assert oracle("1\n3 1 10\n5 5 5\n") == "5 0\n"
assert oracle("1\n3 1 10\n1 2 3\n") == "3 20\n"
assert oracle("1\n3 2 10\n1 2 9\n") == "2 10\n"


def write_days(name, days):
    lines = [str(len(days))]
    for channel_count, jump_limit, wait_seconds, values in days:
        lines.append(f"{channel_count} {jump_limit} {wait_seconds}")
        lines.append(" ".join(str(value) for value in values))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_days("2_edges", [
        (1, 1, 7, [9]),
        (2, 1, 7, [5, 5]),
        (3, 1, 7, [9, 5, 1]),
        (4, 1000000000, 1000, [0, 1, 2, 3]),
        (5, 1, 1000, [1, 2, 3, 4, 5]),
    ])
    rng = random.Random(20261126)
    wide = [(1000, 1000000000, 1000,
             [rng.randint(0, 1000000000) for _ in range(1000)])]
    write_days("3_wide", wide)
    random_days = []
    for _ in range(20):
        channel_count = rng.randint(1, 60)
        random_days.append((channel_count, rng.randint(1, 100), rng.randint(1, 1000),
                            [rng.randint(0, 500) for _ in range(channel_count)]))
    write_days("4_random", random_days)
    io_days = []
    for _ in range(100):
        io_days.append((100, 1000000000, 1000,
                        [rng.randint(0, 1000000000) for _ in range(100)]))
    write_days("5_io", io_days)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_days("1_sample", [(6, 3, 5, [3, 4, 0, 8, 12, 6]),
                        (4, 1, 2, [5, 7, 7, 5])])
build()
