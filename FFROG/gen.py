#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def moves_for(position, row_count, column_count):
    row_index, column_index = position
    moves = []
    for next_row in range(row_index):
        moves.append((next_row, column_index))
    for next_column in range(column_index):
        moves.append((row_index, next_column))
    return moves


def reachable_states(state, move_limit, row_count, column_count):
    seen = set()
    frontier = {tuple(sorted(state))}
    for _ in range(move_limit):
        next_frontier = set()
        for current in frontier:
            for frog_index, position in enumerate(current):
                for next_position in moves_for(position, row_count, column_count):
                    updated = list(current)
                    updated[frog_index] = next_position
                    updated = tuple(sorted(updated))
                    seen.add(updated)
                    next_frontier.add(updated)
        frontier = next_frontier
    return seen


def oracle(text):
    lines = text.splitlines()
    case_count = int(lines[0])
    cursor = 1
    answers = []
    for _ in range(case_count):
        row_count, column_count, move_limit = map(int, lines[cursor].split())
        cursor += 1
        state = []
        for row_index in range(row_count):
            counts = list(map(int, lines[cursor].split()))
            cursor += 1
            for column_index, frog_count in enumerate(counts):
                state.extend([(row_index, column_index)] * frog_count)
        state = tuple(state)

        @lru_cache(maxsize=None)
        def winning(current):
            if all(position == (0, 0) for position in current):
                return False
            for following in reachable_states(current, move_limit, row_count, column_count):
                if not winning(following):
                    return True
            return False

        answers.append("SensibleFrog Wins!." if winning(state) else "SmartFrog Wins!.")
    return "\n".join(answers) + "\n"


SAMPLE = """3
1 1 1
837465
2 2 1
0 0
0 1
2 2 2
0 0
0 2
"""
SAMPLE_OUT = """SmartFrog Wins!.
SmartFrog Wins!.
SensibleFrog Wins!.
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 2 1\n0 1\n") == "SensibleFrog Wins!.\n"
assert oracle("1\n1 2 2\n0 2\n") == "SensibleFrog Wins!.\n"
assert oracle("1\n2 2 3\n0 0\n0 0\n") == "SmartFrog Wins!.\n"


def encode(cases):
    blocks = [str(len(cases))]
    for row_count, column_count, move_limit, counts in cases:
        lines = [f"{row_count} {column_count} {move_limit}"]
        for row in counts:
            lines.append(" ".join(str(value) for value in row))
        blocks.append("\n".join(lines))
    return "\n".join(blocks) + "\n"


def write(name, cases):
    input_text = encode(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [
        (1, 1, 1, [[0]]),
        (1, 2, 1, [[0, 1]]),
        (1, 2, 2, [[0, 2]]),
        (2, 2, 1, [[0, 0], [0, 1]]),
        (2, 2, 2, [[0, 0], [1, 1]]),
    ])
    rng = random.Random(20261126)
    wide_cases = []
    for _ in range(5):
        row_count = rng.randint(1, 3)
        column_count = rng.randint(1, 3)
        move_limit = rng.randint(1, 3)
        counts = [[0] * column_count for _ in range(row_count)]
        for _ in range(rng.randint(1, 3)):
            counts[rng.randrange(row_count)][rng.randrange(column_count)] += 1
        wide_cases.append((row_count, column_count, move_limit, counts))
    write("3_wide", wide_cases)
    random_cases = []
    for _ in range(8):
        row_count = rng.randint(1, 3)
        column_count = rng.randint(1, 3)
        move_limit = rng.randint(1, 3)
        counts = [[0] * column_count for _ in range(row_count)]
        for _ in range(rng.randint(1, 3)):
            counts[rng.randrange(row_count)][rng.randrange(column_count)] += 1
        random_cases.append((row_count, column_count, move_limit, counts))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(20):
        row_count = rng.randint(1, 3)
        column_count = rng.randint(1, 3)
        move_limit = rng.randint(1, 3)
        counts = [[0] * column_count for _ in range(row_count)]
        for _ in range(rng.randint(1, 2)):
            counts[rng.randrange(row_count)][rng.randrange(column_count)] += 1
        io_cases.append((row_count, column_count, move_limit, counts))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    (1, 1, 1, [[837465]]),
    (2, 2, 1, [[0, 0], [0, 1]]),
    (2, 2, 2, [[0, 0], [0, 2]]),
])
build()
