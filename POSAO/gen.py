#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    grid_size, computer_count = (int(value) for value in text.split())
    complete_row = (1 << grid_size) - 1
    start_state = (0,) * grid_size
    goal_state = (complete_row,) * grid_size
    frontier = deque([(start_state, 0)])
    visited = {start_state}
    while frontier:
        state, seconds = frontier.popleft()
        if state == goal_state:
            return str(seconds) + "\n"
        available = []
        for row_index in range(grid_size):
            for column_index in range(grid_size):
                if state[row_index] >> column_index & 1:
                    continue
                if column_index and not state[row_index] >> (column_index - 1) & 1:
                    continue
                if row_index and not state[row_index - 1] >> column_index & 1:
                    continue
                available.append((row_index, column_index))
        for choice in range(1, 1 << len(available)):
            if choice.bit_count() > computer_count:
                continue
            next_rows = list(state)
            for job_index, (row_index, column_index) in enumerate(available):
                if choice >> job_index & 1:
                    next_rows[row_index] |= 1 << column_index
            next_state = tuple(next_rows)
            if next_state not in visited:
                visited.add(next_state)
                frontier.append((next_state, seconds + 1))
    return "-1\n"


SAMPLE = "3 2\n"
SAMPLE_OUT = "6\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("5 1\n") == "25\n"
assert oracle("4 4\n") == "7\n"
assert oracle("1 1\n") == "1\n"
assert oracle("2 3\n") == "3\n"
assert oracle("6 2\n") == "19\n"


def write(name, grid_size, computer_count):
    text = f"{grid_size} {computer_count}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, 1)
    write("3_wide", 5, 6)
    rng = random.Random(20261126)
    write("4_random", rng.randint(1, 5), rng.randint(1, 6))
    write("5_io", 5, 2)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 3, 2)
build()
