#!/usr/bin/env python3
from itertools import permutations, product
from collections import deque
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parent


def bfs_answer(side, start, goal):
    cell_total = side * side
    if sorted(start) != sorted(goal):
        return -1
    row_lines = [[r * side + c for c in range(side)] for r in range(side)]
    col_lines = [[r * side + c for r in range(side)] for c in range(side)]
    perms = list(permutations(range(side)))
    rounds = []
    for lines in (row_lines, col_lines):
        for choices in product(perms, repeat=side):
            move = list(range(cell_total))
            for line, order in zip(lines, choices):
                for old, dst in zip(line, order):
                    move[old] = line[dst]
            rounds.append(tuple(move))
    def apply(state, move):
        new = [0] * cell_total
        for old in range(cell_total):
            new[move[old]] = state[old]
        return tuple(new)
    seen = {tuple(start): 0}
    queue = deque([tuple(start)])
    target = tuple(goal)
    while queue:
        state = queue.popleft()
        if state == target:
            return seen[state]
        for move in rounds:
            nxt = apply(state, move)
            if nxt not in seen:
                seen[nxt] = seen[state] + 1
                queue.append(nxt)
    return -1


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(count):
        side = int(tokens[cursor]); cursor += 1
        cell_total = side * side
        initial = [int(tokens[cursor + i]) for i in range(cell_total)]; cursor += cell_total
        target = [int(tokens[cursor + i]) for i in range(cell_total)]; cursor += cell_total
        if sorted(initial) != sorted(target):
            answers.append("no")
            continue
        if initial == target:
            answers.append("0")
            continue
        row_match = all(sorted(initial[r * side:(r + 1) * side]) == sorted(target[r * side:(r + 1) * side]) for r in range(side))
        col_match = all(sorted(initial[r * side + c] for r in range(side)) == sorted(target[r * side + c] for r in range(side)) for c in range(side))
        if row_match or col_match:
            answers.append("1")
            continue
        start_pos = {}
        goal_pos = {}
        for cell, color in enumerate(initial):
            start_pos.setdefault(color, []).append(cell)
        for cell, color in enumerate(target):
            goal_pos.setdefault(color, []).append(cell)
        doubles = [color for color in start_pos if len(start_pos[color]) == 2]
        options = []
        for color in sorted(start_pos):
            starts = start_pos[color]
            goals = goal_pos[color]
            if len(starts) == 1:
                options.append([[(starts[0], goals[0])]])
            else:
                options.append([
                    [(starts[0], goals[0]), (starts[1], goals[1])],
                    [(starts[0], goals[1]), (starts[1], goals[0])],
                ])
        found_two = False
        for choice in product(*options):
            mapping = {}
            for pair in choice:
                for start_cell, goal_cell in pair:
                    mapping[start_cell] = goal_cell
            row_ok = all(len({mapping[r * side + c] % side for c in range(side)}) == side for r in range(side))
            col_ok = all(len({mapping[r * side + c] // side for r in range(side)}) == side for c in range(side))
            if row_ok or col_ok:
                found_two = True
                break
        answers.append("2" if found_two else "3")
    return "\n".join(answers) + "\n"


def write(name, cases):
    parts = [str(len(cases))]
    for side, initial, target in cases:
        parts.append(str(side))
        parts.extend(str(value) for value in initial)
        parts.extend(str(value) for value in target)
    input_text = "\n".join(parts) + "\n"
    (ROOT / "in" / (name + ".txt")).write_text(input_text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(input_text))


def shifted(side, shift_rows, shift_cols):
    return [((i // side + shift_rows) % side) * side + (i % side + shift_cols) % side for i in range(side * side)]


def identity(side):
    return list(range(1, side * side + 1))


SAMPLE_CASES = [
    (3, [1, 3, 4, 2, 1, 3, 2, 5, 5], [3, 1, 3, 2, 1, 2, 4, 5, 5]),
    (3, list(range(1, 10)), [1, 5, 6, 4, 2, 9, 7, 8, 3]),
    (2, [1, 2, 1, 2], [1, 3, 1, 2]),
]
SAMPLE_INPUT = "3\n3\n1 3 4\n2 1 3\n2 5 5\n3 1 3\n2 1 2\n4 5 5\n3\n1 2 3\n4 5 6\n7 8 9\n1 5 6\n4 2 9\n7 8 3\n2\n1 2\n1 2\n1 3\n1 2\n"
assert oracle(SAMPLE_INPUT) == "2\n1\nno\n"
assert len(SAMPLE_CASES) == 3
for side, initial, target in SAMPLE_CASES:
    single = str(1) + "\n" + str(side) + "\n" + "\n".join(map(str, initial)) + "\n" + "\n".join(map(str, target)) + "\n"
    if side <= 2:
        expected = bfs_answer(side, initial, target)
        assert oracle(single).strip() == ("no" if expected < 0 else str(expected))


def build():
    edges = [
        (1, [1], [1]),
        (2, [1, 2, 3, 4], [1, 2, 3, 4]),
        (2, [1, 2, 3, 4], [1, 4, 3, 2]),
        (2, [1, 2, 3, 4], [3, 4, 1, 2]),
        (2, [1, 1, 2, 2], [1, 2, 1, 2]),
        (2, [1, 2, 1, 2], [1, 1, 2, 2]),
        (2, [1, 2, 1, 2], [1, 2, 1, 3]),
        (3, [1, 1, 2, 2, 3, 3, 4, 4, 5], [1, 2, 1, 2, 3, 3, 4, 4, 5]),
        (3, list(range(1, 10)), [2, 3, 4, 5, 6, 7, 8, 9, 1]),
    ]
    for side, initial, target in edges:
        single = str(1) + "\n" + str(side) + "\n" + "\n".join(map(str, initial)) + "\n" + "\n".join(map(str, target)) + "\n"
        if side <= 2:
            expected = bfs_answer(side, initial, target)
            assert oracle(single).strip() == ("no" if expected < 0 else str(expected))
    write("2_edges", edges)

    wide = []
    for side, rows, cols in ((100, 7, 0), (100, 0, 11), (120, 5, 9)):
        base = identity(side)
        permutation = shifted(side, rows, cols)
        initial = [base[permutation[i]] for i in range(side * side)]
        wide.append((side, initial, base))
    write("3_wide", wide)

    random.seed(2026)
    random_cases = []
    for _ in range(12):
        side = random.randint(6, 12)
        cell_total = side * side
        colors = list(range(1, cell_total + 1))
        double_count = random.randint(0, 6)
        for extra in range(double_count):
            colors[random.randrange(cell_total)] = extra + 1
        initial = colors[:]
        target = colors[:]
        random.shuffle(initial)
        random.shuffle(target)
        random_cases.append((side, initial, target))
    write("4_random", random_cases)

    io_cases = []
    for i in range(200):
        side = 1 + (i % 5)
        cell_total = side * side
        initial = list(range(1, cell_total + 1))
        if i % 7 == 0:
            target = initial[:]
        elif i % 3 == 0:
            target = [initial[(j + 1) % cell_total] for j in range(cell_total)]
        else:
            target = initial[:]
            random.shuffle(target)
        io_cases.append((side, initial, target))
    write("5_io", io_cases)


def worked_example():
    side = 3
    initial = SAMPLE_CASES[0][1]
    target = SAMPLE_CASES[0][2]
    goal_columns = {}
    for cell, color in enumerate(target):
        goal_columns.setdefault(color, []).append(cell % side)
    print("color : P rows -> Q columns")
    for color in sorted(goal_columns):
        rows = [cell // side for cell, value in enumerate(initial) if value == color]
        print("%d : %s -> %s" % (color, rows, goal_columns[color]))
    print("answer:", oracle(SAMPLE_INPUT).splitlines()[0])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_CASES)
build()
