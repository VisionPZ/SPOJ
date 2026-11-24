#!/usr/bin/env python3
from collections import deque
from math import lcm
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """2
10
.*********
........**
*.******.*
*.******.*
*.******.*
*........*
*.******.*
*.******.*
*........*
********..
0000000000
0000000000
0000000000
0000000000
0000000000
0123456780
0000000000
0000000000
0123456780
0000000000
3
...
**.
**.
021
002
000
"""

FORUM_INPUT = """1
4
.***
..*.
...*
.*..
3818
1081
5548
7739
"""


def build_cycle(durations):
    cycle = 1
    for duration in durations:
        if duration > 0:
            cycle = lcm(cycle, 2 * duration)
    return cycle


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        size = int(tokens[cursor])
        cursor += 1
        grid_rows = []
        for _ in range(size):
            grid_rows.append(tokens[cursor])
            cursor += 1
        schedule_rows = []
        for _ in range(size):
            schedule_rows.append(tokens[cursor])
            cursor += 1
        durations = [int(ch) for row in schedule_rows for ch in row]
        cell_count = size * size
        cycle = build_cycle(durations)
        open_table = []
        for cell_index in range(cell_count):
            row, column = divmod(cell_index, size)
            duration = durations[cell_index]
            is_open = grid_rows[row][column] == '.'
            table = bytearray(cycle)
            for instant in range(cycle):
                table[instant] = 1 if is_open else 0
                if duration > 0 and (instant + 1) % duration == 0:
                    is_open = not is_open
            open_table.append(table)
        if open_table[0][0] == 0:
            answers.append("NO")
            continue
        seen = bytearray(cell_count * cycle)
        queue = deque()
        seen[0] = 1
        queue.append(0)
        residue = 0
        elapsed = 0
        target = cell_count - 1
        answer = -1
        while queue and answer < 0:
            following_queue = deque()
            following_residue = (residue + 1) % cycle
            while queue:
                state = queue.popleft()
                cell = state % cell_count
                row, column = divmod(cell, size)
                for next_row, next_column in (
                    (row - 1, column), (row + 1, column),
                    (row, column - 1), (row, column + 1), (row, column),
                ):
                    if 0 <= next_row < size and 0 <= next_column < size:
                        next_cell = next_row * size + next_column
                        if open_table[next_cell][following_residue]:
                            if next_cell == target:
                                answer = elapsed + 1
                                break
                            next_state = next_cell + cell_count * following_residue
                            if seen[next_state] == 0:
                                seen[next_state] = 1
                                following_queue.append(next_state)
                if answer >= 0:
                    break
            queue = following_queue
            residue = following_residue
            elapsed += 1
        answers.append("NO" if answer < 0 else str(answer))
    return "\n".join(answers) + "\n"


def brute(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        size = int(tokens[cursor])
        cursor += 1
        grid_rows = []
        for _ in range(size):
            grid_rows.append(tokens[cursor])
            cursor += 1
        schedule_rows = []
        for _ in range(size):
            schedule_rows.append(tokens[cursor])
            cursor += 1
        durations = [int(ch) for row in schedule_rows for ch in row]
        limit = 3 * build_cycle(durations)
        answers.append(simulate(size, grid_rows, durations, limit))
    return "\n".join(answers) + "\n"


def simulate(size, grid_rows, durations, limit):
    start_open = grid_rows[0][0] == '.'
    if not start_open:
        return "NO"
    target = size * size - 1
    open_now = set()
    for cell_index, duration in enumerate(durations):
        row, column = divmod(cell_index, size)
        phase = 0 if grid_rows[row][column] == '.' else 1
        if duration > 0:
            phase ^= (0 // duration) % 2
        if phase == 0:
            open_now.add(cell_index)
    frontier = {0}
    for elapsed in range(1, limit + 1):
        following = set()
        for cell in frontier:
            row, column = divmod(cell, size)
            for next_row, next_column in (
                (row - 1, column), (row + 1, column),
                (row, column - 1), (row, column + 1), (row, column),
            ):
                if 0 <= next_row < size and 0 <= next_column < size:
                    following.add(next_row * size + next_column)
        open_next = set()
        for cell_index, duration in enumerate(durations):
            row, column = divmod(cell_index, size)
            phase = 0 if grid_rows[row][column] == '.' else 1
            if duration > 0:
                phase ^= (elapsed // duration) % 2
            if phase == 0:
                open_next.add(cell_index)
        reachable = following & open_next
        if target in reachable:
            return str(elapsed)
        frontier = reachable
        if not frontier:
            return "NO"
    return "NO"


def render(cases):
    lines = [str(len(cases))]
    for size, grid_rows, schedule_rows in cases:
        lines.append(str(size))
        lines.extend(grid_rows)
        lines.extend(schedule_rows)
    return "\n".join(lines) + "\n"


def make_case(size, open_pattern, digit_pattern):
    grid_rows = []
    schedule_rows = []
    for row in range(size):
        grid_rows.append("".join(open_pattern(row, column) for column in range(size)))
        schedule_rows.append("".join(str(digit_pattern(row, column)) for column in range(size)))
    return (size, grid_rows, schedule_rows)


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


assert oracle(SAMPLE_INPUT) == "34\nNO\n"
assert oracle(FORUM_INPUT) == "19\n"
assert build_cycle(list(range(1, 10))) == 5040
assert lcm(*range(1, 10)) == 2520
assert oracle("1\n2\n..\n..\n00\n00\n") == "2\n"
assert oracle("1\n2\n*.\n..\n00\n00\n") == "NO\n"
assert oracle("1\n2\n..\n.*\n00\n00\n") == "NO\n"

assert oracle("1\n3\n...\n**.\n**.\n021\n002\n000\n") == "NO\n"

check_seed = random.Random(4242)
for _ in range(30):
    small_size = check_seed.randint(2, 4)
    small_case = make_case(
        small_size,
        lambda row, column, rng=check_seed: rng.choice('. . * * *'.split()),
        lambda row, column, rng=check_seed: rng.randint(0, 4),
    )
    small_text = render([small_case])
    assert oracle(small_text) == brute(small_text), small_text


def build():
    write("1_sample", SAMPLE_INPUT)

    edges = [
        make_case(2, lambda r, c: '.', lambda r, c: 0),
        make_case(2, lambda r, c: '*' if (r, c) == (0, 0) else '.', lambda r, c: 0),
        make_case(2, lambda r, c: '*' if (r, c) == (1, 1) else '.', lambda r, c: 0),
        make_case(3, lambda r, c: '.', lambda r, c: 0),
        make_case(3, lambda r, c: '.' if (r, c) in ((0, 0), (0, 1), (0, 2), (1, 2), (2, 2)) else '*',
                  lambda r, c: {0: 0, 1: 2, 2: 1}.get(c, 0) if r == 0 else (2 if c == 2 else 0)),
        make_case(3, lambda r, c: '.', lambda r, c: 8),
        (4, [".***", "..*.", "...*", ".*.."], ["3818", "1081", "5548", "7739"]),
        make_case(2, lambda r, c: '.', lambda r, c: 1),
    ]
    write("2_edges", render(edges))

    def serpentine(size, row, column):
        if row % 2 == 0:
            return '.'
        connector_side = ((row - 1) // 2) % 2
        connector_column = size - 1 if connector_side == 0 else 0
        return '.' if column == connector_column else '*'

    wide = [
        make_case(25, lambda r, c: '.', lambda r, c: 0),
        make_case(25, lambda r, c: '.', lambda r, c: 1),
        make_case(25, lambda r, c: serpentine(25, r, c), lambda r, c: 8 if (r, c) == (12, 0) else 0),
        make_case(15, lambda r, c: '*' if (r, c) == (14, 14) else '.', lambda r, c: 8),
    ]
    write("3_wide", render(wide))

    rng = random.Random(2026)
    random_cases = []
    for _ in range(8):
        size = rng.randint(4, 11)
        random_cases.append(make_case(
            size,
            lambda r, c, generator=rng: '.' if generator.random() < 0.62 else '*',
            lambda r, c, generator=rng: generator.choice([0, 0, 1, 2, 3, 5, 7, 8, 9]),
        ))
    write("4_random", render(random_cases))

    io_cases = []
    for index in range(10):
        size = 25
        if index == 0:
            io_cases.append(make_case(size, lambda r, c: '.', lambda r, c: 0))
        elif index == 1:
            io_cases.append(make_case(size, lambda r, c: '.', lambda r, c: 8))
        elif index == 2:
            io_cases.append(make_case(size, lambda r, c: serpentine(size, r, c),
                                      lambda r, c: 8 if serpentine(size, r, c) == '.' and (r + c) % 7 == 0 else 0))
        elif index == 3:
            io_cases.append(make_case(size,
                                      lambda r, c: '*' if (r, c) == (size - 1, size - 1) else '.',
                                      lambda r, c: 8))
        elif index == 4:
            cycle_digits = {(12, 12): 8, (12, 13): 9, (13, 12): 5, (13, 13): 7}
            io_cases.append(make_case(
                size,
                lambda r, c: '*' if (r, c) in ((size - 2, size - 1), (size - 1, size - 2)) else '.',
                lambda r, c: cycle_digits.get((r, c), 0),
            ))
        else:
            io_cases.append(make_case(
                size,
                lambda r, c, generator=rng: '.' if generator.random() < 0.70 else '*',
                lambda r, c, generator=rng: generator.choice([0, 0, 2, 3, 4, 6, 8]),
            ))
    write("5_io", render(io_cases))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
build()
