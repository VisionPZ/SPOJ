#!/usr/bin/env python3
import random
from math import comb
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DIRECTIONS = ((-1, 0), (1, 0), (0, -1), (0, 1))
ALL_SQUARES = [(row, col) for row in range(1, 9) for col in range(1, 9)]

SAMPLE_START = (4, 4, 4, 5, 5, 4, 6, 5)
SAMPLE_TARGET = (2, 4, 3, 3, 3, 6, 4, 6)
ONE_MOVE = (3, 4, 4, 5, 5, 4, 6, 5)
LEVEL8_TARGET = (1, 2, 2, 5, 4, 5, 5, 4)
COMMENT_START = (1, 1, 1, 2, 1, 3, 7, 8)
COMMENT_TARGET = (2, 1, 2, 2, 2, 3, 8, 8)
CORNERS = (1, 1, 1, 8, 8, 1, 8, 8)
CENTER = (4, 4, 4, 5, 5, 4, 5, 5)


def as_set(config):
    return frozenset(zip(config[0::2], config[1::2]))


def as_config(state):
    return tuple(value for square in sorted(state) for value in square)


def neighbors(state):
    result = []
    for row, col in state:
        for row_step, col_step in DIRECTIONS:
            adj_row, adj_col = row + row_step, col + col_step
            if (adj_row, adj_col) not in ALL_SQUARES:
                continue
            moved = set(state)
            moved.remove((row, col))
            if (adj_row, adj_col) not in state:
                moved.add((adj_row, adj_col))
                result.append(frozenset(moved))
                continue
            land_row = row + 2 * row_step
            land_col = col + 2 * col_step
            if (land_row, land_col) in ALL_SQUARES and (land_row, land_col) not in state:
                moved.add((land_row, land_col))
                result.append(frozenset(moved))
    return result


def bfs_levels(start, limit=8):
    levels = {start: 0}
    frontier = [start]
    for depth in range(1, limit + 1):
        next_frontier = []
        for state in frontier:
            for neighbor in neighbors(state):
                if neighbor not in levels:
                    levels[neighbor] = depth
                    next_frontier.append(neighbor)
        frontier = next_frontier
        if not frontier:
            break
    return levels


def brute_neighbors(state):
    result = set()
    for row, col in state:
        for row_step, col_step in DIRECTIONS:
            adj = (row + row_step, col + col_step)
            land = (row + 2 * row_step, col + 2 * col_step)
            if adj in state and land in ALL_SQUARES and land not in state:
                moved = (set(state) - {(row, col)}) | {land}
            elif adj in ALL_SQUARES and adj not in state:
                moved = (set(state) - {(row, col)}) | {adj}
            else:
                continue
            result.add(tuple(sorted(moved)))
    return result


def brute_within(start, target, max_depth):
    visited = set()
    goal = tuple(sorted(target))

    def search(state, depth):
        if state == goal:
            return True
        if depth == max_depth:
            return False
        key = (state, depth)
        if key in visited:
            return False
        visited.add(key)
        for neighbor in brute_neighbors(state):
            if search(neighbor, depth + 1):
                return True
        return False

    return search(tuple(sorted(start)), 0)


def oracle(text):
    tokens = [int(piece) for piece in text.split()]
    cursor = 0
    case_total = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_total):
        start = as_set(tuple(tokens[cursor:cursor + 8]))
        cursor += 8
        target = as_set(tuple(tokens[cursor:cursor + 8]))
        cursor += 8
        if start == target:
            answers.append("YES")
            continue
        levels = bfs_levels(start)
        answers.append("YES" if target in levels else "NO")
    return "\n".join(answers) + "\n"


def case_text(pairs):
    lines = [str(len(pairs))]
    for start, target in pairs:
        lines.append(" ".join(str(value) for value in start))
        lines.append(" ".join(str(value) for value in target))
    return "\n".join(lines) + "\n"


def write(name, pairs):
    text = case_text(pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_walk(start, steps, rng):
    current = start
    for _ in range(steps):
        options = neighbors(current)
        current = options[rng.randrange(len(options))]
    return current


assert comb(64, 4) == 635376
assert len(neighbors(as_set(SAMPLE_START))) == 16
assert bfs_levels(as_set(SAMPLE_START))[as_set(SAMPLE_TARGET)] == 7
assert oracle(case_text([(SAMPLE_START, SAMPLE_TARGET)])) == "YES\n"
assert oracle(case_text([(COMMENT_START, COMMENT_TARGET)])) == "YES\n"
assert oracle(case_text([(CORNERS, CENTER)])) == "NO\n"
assert oracle(case_text([(SAMPLE_START, ONE_MOVE)])) == "YES\n"
assert oracle(case_text([(SAMPLE_START, LEVEL8_TARGET)])) == "YES\n"

check_rng = random.Random(1234)
for _ in range(24):
    check_start = frozenset(check_rng.sample(ALL_SQUARES, 4))
    check_target = frozenset(check_rng.sample(ALL_SQUARES, 4))
    assert (check_target in bfs_levels(check_start, 3)) == brute_within(check_start, check_target, 3)

build_rng = random.Random(20261124)
sample_levels = bfs_levels(as_set(SAMPLE_START))
level_counts = [sum(1 for value in sample_levels.values() if value == depth) for depth in range(9)]
print("WORKED levels " + " ".join(str(count) for count in level_counts))
print("WORKED sample_distance " + str(sample_levels[as_set(SAMPLE_TARGET)]))

write("1_sample", [(SAMPLE_START, SAMPLE_TARGET)])
write("2_edges", [
    (SAMPLE_START, SAMPLE_START),
    (SAMPLE_START, ONE_MOVE),
    (COMMENT_START, COMMENT_TARGET),
    (SAMPLE_START, LEVEL8_TARGET),
    (CORNERS, CENTER),
    (SAMPLE_START, CORNERS),
    (CENTER, CENTER),
])
write("3_wide", [
    (CORNERS, CENTER),
    (SAMPLE_START, CORNERS),
    (as_config(as_set(SAMPLE_START)), LEVEL8_TARGET),
    (CENTER, CORNERS),
    (CORNERS, as_config(random_walk(as_set(CORNERS), 8, build_rng))),
    (SAMPLE_START, SAMPLE_TARGET),
])

random_pairs = []
for pair_index in range(25):
    start_state = frozenset(build_rng.sample(ALL_SQUARES, 4))
    if pair_index % 2 == 0:
        target_state = random_walk(start_state, build_rng.randint(0, 8), build_rng)
    else:
        target_state = frozenset(build_rng.sample(ALL_SQUARES, 4))
    random_pairs.append((as_config(start_state), as_config(target_state)))
write("4_random", random_pairs)

io_pairs = []
for pair_index in range(29):
    start_state = frozenset(build_rng.sample(ALL_SQUARES, 4))
    if pair_index % 3 == 0:
        target_state = start_state
    elif pair_index % 3 == 1:
        target_state = random_walk(start_state, build_rng.randint(1, 8), build_rng)
    else:
        target_state = frozenset(build_rng.sample(ALL_SQUARES, 4))
    io_pairs.append((as_config(start_state), as_config(target_state)))
write("5_io", io_pairs)
