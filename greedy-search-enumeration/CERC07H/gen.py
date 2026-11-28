#!/usr/bin/env python3
import random
from itertools import combinations
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def layout(land_size):
    row_count = 2 * land_size - 1
    row_lengths = [land_size + min(row, row_count - 1 - row) for row in range(row_count)]
    row_offsets = [land_size - 1 - row if row < land_size else row - land_size + 1
                   for row in range(row_count)]
    row_starts = []
    cell_columns = []
    total = 0
    for row in range(row_count):
        row_starts.append(total)
        cell_columns.extend(row_offsets[row] + 2 * position
                            for position in range(row_lengths[row]))
        total += row_lengths[row]
    positions = {}
    for row in range(row_count):
        for position in range(row_lengths[row]):
            positions[(row, cell_columns[row_starts[row] + position])] = row_starts[row] + position
    neighbors = [[] for _ in range(total)]
    for row in range(row_count):
        for position in range(row_lengths[row]):
            index = row_starts[row] + position
            column = cell_columns[index]
            for next_row, next_column in ((row, column - 2), (row, column + 2),
                                          (row - 1, column - 1), (row - 1, column + 1),
                                          (row + 1, column - 1), (row + 1, column + 1)):
                if (next_row, next_column) in positions:
                    neighbors[index].append(positions[(next_row, next_column)])
    return row_lengths, row_starts, neighbors


def parse(text):
    lines = [line for line in text.splitlines() if line.strip()]
    cursor = 0
    scenarios = []
    while cursor < len(lines):
        land_size = int(lines[cursor].split()[0]); cursor += 1
        if land_size == 0:
            break
        row_lengths, row_starts, neighbors = layout(land_size)
        board = []
        for row in range(len(row_lengths)):
            board.append([char for char in lines[cursor] if char != " "][:row_lengths[row]])
            cursor += 1
        flat_board = [char for row in board for char in row]
        scenarios.append((flat_board, neighbors))
    return scenarios


def oracle_scenario(board, neighbors):
    dots = [index for index, char in enumerate(board) if char == "."]
    area_cells = {char: [index for index, value in enumerate(board) if value == char]
                  for char in "ABCD"}
    if any(len(cells) == 0 for cells in area_cells.values()):
        return None
    for bought_count in range(len(dots) + 1):
        for bought in combinations(dots, bought_count):
            bought_set = set(bought)
            parent = list(range(len(board)))

            def find(cell):
                while parent[cell] != cell:
                    parent[cell] = parent[parent[cell]]
                    cell = parent[cell]
                return cell

            def owned(cell):
                return board[cell] != "." or cell in bought_set

            for cell in range(len(board)):
                if not owned(cell):
                    continue
                for neighbor in neighbors[cell]:
                    if owned(neighbor):
                        first = find(cell)
                        second = find(neighbor)
                        if first != second:
                            parent[first] = second
            roots = {find(cells[0]) for cells in area_cells.values()}
            if len(roots) == 1:
                return bought_count
    return None


def oracle(text):
    answers = []
    for board, neighbors in parse(text):
        parcels = oracle_scenario(board, neighbors)
        if parcels is None:
            answers.append("Damaged billboard.")
        else:
            answers.append(f"You have to buy {parcels} parcels.")
    return "\n".join(answers) + "\n"


def render(board, land_size):
    row_lengths, row_starts, _ = layout(land_size)
    lines = [str(land_size)]
    for row in range(len(row_lengths)):
        start = row_starts[row]
        lines.append(" ".join(board[start:start + row_lengths[row]]))
    return "\n".join(lines) + "\n\n"


def make_board(land_size, dot_count, rng, forced_neighbors=False):
    row_lengths, row_starts, neighbors = layout(land_size)
    total = len(neighbors)
    if forced_neighbors:
        dot = max(range(total), key=lambda cell: len(neighbors[cell]))
        dot_set = {dot}
        seeds = neighbors[dot][:4]
    else:
        dot_count = min(dot_count, total - 4)
        for _ in range(200):
            dot_set = set(rng.sample(range(total), dot_count))
            remaining = [cell for cell in range(total) if cell not in dot_set]
            reached = {remaining[0]}
            stack = [remaining[0]]
            while stack:
                cell = stack.pop()
                for neighbor in neighbors[cell]:
                    if neighbor not in dot_set and neighbor not in reached:
                        reached.add(neighbor)
                        stack.append(neighbor)
            if len(reached) == len(remaining) and len(remaining) >= 4:
                break
        else:
            raise ValueError("no connected layout")
        seeds = rng.sample(sorted(remaining), 4)
    board = ["." for _ in range(total)]
    for area_index, seed in enumerate(seeds):
        board[seed] = "ABCD"[area_index]
    unassigned = [cell for cell in range(total)
                  if cell not in dot_set and board[cell] == "."]
    rng.shuffle(unassigned)
    for _ in range(total):
        progressed = False
        remaining = []
        for cell in unassigned:
            matching = [board[neighbor] for neighbor in neighbors[cell]
                        if board[neighbor] in "ABCD"]
            if matching:
                board[cell] = rng.choice(matching)
                progressed = True
            else:
                remaining.append(cell)
        unassigned = remaining
        if not unassigned:
            break
        if not progressed:
            raise ValueError("growth stuck")
    return board


SAMPLE = """4
   B . . C
  . . . . C
 . A . . C .
. A A . . . .
 . A . . . .
  . . . D D
   . . . .

0
"""
SAMPLE_OUT = """You have to buy 4 parcels.
"""

assert oracle(SAMPLE) == SAMPLE_OUT
check_rng = random.Random(4242)
no_dot_board = make_board(2, 0, check_rng)
one_dot_board = make_board(2, 1, check_rng)
no_dot_wide = make_board(3, 0, check_rng)
assert oracle(render(no_dot_board, 2) + "0\n") == "You have to buy 0 parcels.\n"
assert oracle(render(one_dot_board, 2) + "0\n") in (
    "You have to buy 0 parcels.\n", "You have to buy 1 parcels.\n")
assert oracle(render(no_dot_wide, 3) + "0\n") == "You have to buy 0 parcels.\n"


def write(name, scenarios):
    text = "".join(render(board, land_size) for land_size, board in scenarios) + "0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    edges = []
    for land_size, dot_count in ((2, 0), (2, 1), (2, 2), (3, 0), (3, 3)):
        rng = random.Random(land_size * 100 + dot_count)
        edges.append((land_size, make_board(land_size, dot_count, rng)))
    write("2_edges", edges)
    wide = []
    for land_size in (12, 20, 20):
        rng = random.Random(land_size + 7000)
        wide.append((land_size, make_board(land_size, 0, rng, forced_neighbors=True)))
    write("3_wide", wide)
    rng = random.Random(20261127)
    random_scenarios = []
    for land_size in (2, 3, 4, 5):
        for _ in range(4):
            random_scenarios.append((land_size,
                                     make_board(land_size, rng.randint(0, 9), rng)))
    write("4_random", random_scenarios)
    io_scenarios = []
    for index in range(5000):
        seed = 90000 + index
        io_scenarios.append((2, make_board(2, index % 3, random.Random(seed))))
    write("5_io", io_scenarios)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
