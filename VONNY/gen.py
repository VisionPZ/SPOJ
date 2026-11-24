#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
ROWS, COLS, CELLS = 7, 8, 56
DOMINOES = [(a, b) for a in range(7) for b in range(a, 7)]


def neighbors():
    result = []
    for cell in range(CELLS):
        row, col = divmod(cell, COLS)
        around = []
        if col + 1 < COLS:
            around.append(cell + 1)
        if row + 1 < ROWS:
            around.append(cell + COLS)
        if col > 0:
            around.append(cell - 1)
        if row > 0:
            around.append(cell - COLS)
        result.append(around)
    return result


NEIGHBORS = neighbors()
FULL = (1 << CELLS) - 1


def oracle_plain(board):
    total = 0

    def rec(covered, used):
        nonlocal total
        if covered == FULL:
            total += 1
            return
        cell = 0
        while covered >> cell & 1:
            cell += 1
        for other in NEIGHBORS[cell]:
            if covered >> other & 1:
                continue
            low, high = board[cell], board[other]
            domino = (low, high) if low <= high else (high, low)
            if domino not in used:
                rec(covered | 1 << cell | 1 << other, used | {domino})

    rec(0, frozenset())
    return total


def oracle_last(board):
    total = 0

    def rec(covered, used):
        nonlocal total
        if covered == FULL:
            total += 1
            return
        cell = CELLS - 1
        while covered >> cell & 1:
            cell -= 1
        for other in NEIGHBORS[cell]:
            if covered >> other & 1:
                continue
            low, high = board[cell], board[other]
            if low > high:
                low, high = high, low
            bit = low * 7 + high - low * (low + 1) // 2
            if not used >> bit & 1:
                rec(covered | 1 << cell | 1 << other, used | 1 << bit)

    rec(0, 0)
    return total


@lru_cache(maxsize=None)
def cached_count(key):
    return oracle_plain(list(key))


def solve_board(board):
    if any(board.count(label) != 8 for label in range(7)):
        return 0
    return cached_count(tuple(board))


def write(name, boards):
    parts = [str(len(boards)) + "\n"]
    for board in boards:
        for row in range(ROWS):
            parts.append(" ".join(str(board[row * COLS + col]) for col in range(COLS)) + "\n")
        parts.append("\n")
    (ROOT / "in" / f"{name}.txt").write_text("".join(parts))
    (ROOT / "out" / f"{name}.out").write_text(
        "".join(str(solve_board(board)) + "\n" for board in boards))


def random_matching(rng):
    paired = {}

    def rec(free):
        if free == 0:
            return True
        cell = 0
        while not (free >> cell & 1):
            cell += 1
        options = [other for other in NEIGHBORS[cell] if free >> other & 1]
        rng.shuffle(options)
        for other in options:
            paired[cell] = other
            paired[other] = cell
            if rec(free & ~(1 << cell) & ~(1 << other)):
                return True
            del paired[cell]
            del paired[other]
        return False

    assert rec(FULL)
    assert len(paired) == CELLS
    return paired


def valid_board(rng):
    paired = random_matching(rng)
    pairs = [(cell, paired[cell]) for cell in range(CELLS) if cell < paired[cell]]
    assert len(pairs) == 28
    pieces = DOMINOES[:]
    rng.shuffle(pieces)
    board = [0] * CELLS
    for (left, right), (low, high) in zip(pairs, pieces):
        if rng.random() < 0.5:
            board[left], board[right] = low, high
        else:
            board[left], board[right] = high, low
    assert all(board.count(label) == 8 for label in range(7))
    assert solve_board(board) >= 1
    return board


def invalid_board(rng):
    return [rng.randrange(7) for _ in range(CELLS)]


def parse_sample():
    part1 = [
        "0 3 0 2 2 0 2 3", "1 5 6 5 5 1 2 2", "3 4 1 4 5 4 4 4",
        "6 6 1 0 5 2 3 0", "4 0 3 2 4 1 6 0", "1 4 1 5 6 6 3 0",
        "1 2 6 5 5 6 3 3",
    ]
    part2 = [
        "5 3 1 0 0 1 6 3", "0 2 0 4 1 2 5 2", "1 5 3 5 6 4 6 4",
        "0 5 0 2 0 4 6 2", "4 5 3 6 0 6 1 1", "2 3 5 3 4 4 5 3",
        "2 1 1 6 6 2 4 3",
    ]
    to_board = lambda rows: [int(value) for row in rows for value in row.split()]
    return [to_board(part1), to_board(part2)]


SAMPLE = parse_sample()
assert oracle_plain(SAMPLE[0]) == 18
assert oracle_plain(SAMPLE[1]) == 1
assert oracle_last(SAMPLE[0]) == 18
assert oracle_last(SAMPLE[1]) == 1
assert solve_board([0] * CELLS) == 0
assert len(DOMINOES) == 28


def build():
    rng = random.Random(1977)
    probe = [valid_board(rng) for _ in range(24)]
    for board in probe[:6]:
        assert oracle_last(board) == oracle_plain(board)

    edges = [[0] * CELLS, [0] * (CELLS - 1) + [1], probe[0], SAMPLE[1]]
    write("2_edges", edges)

    wide_rng = random.Random(8123)
    write("3_wide", [valid_board(wide_rng) for _ in range(60)])

    mix_rng = random.Random(4242)
    mixed = []
    for idx in range(80):
        mixed.append(valid_board(mix_rng) if idx % 2 == 0 else invalid_board(mix_rng))
    write("4_random", mixed)

    scored = sorted(((solve_board(board), board) for board in probe), reverse=True)
    best_score, best_board = scored[0]
    assert best_score >= 1
    write("5_io", [best_board] * 1000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
SAMPLE_INPUT = """2
0 3 0 2 2 0 2 3 
1 5 6 5 5 1 2 2 
3 4 1 4 5 4 4 4 
6 6 1 0 5 2 3 0 
4 0 3 2 4 1 6 0 
1 4 1 5 6 6 3 0 
1 2 6 5 5 6 3 3 

5 3 1 0 0 1 6 3 
0 2 0 4 1 2 5 2 
1 5 3 5 6 4 6 4 
0 5 0 2 0 4 6 2 
4 5 3 6 0 6 1 1 
2 3 5 3 4 4 5 3 
2 1 1 6 6 2 4 3 

"""
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
(ROOT / "out" / "1_sample.out").write_text("18\n1\n")
assert solve_board(SAMPLE[0]) == 18 and solve_board(SAMPLE[1]) == 1
build()
