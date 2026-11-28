#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SHOP_MINUTES = 60


def distances_from(grid, start):
    rows = len(grid)
    columns = len(grid[0])
    start_row, start_column = start
    distances = [[-1] * columns for _ in range(rows)]
    distances[start_row][start_column] = 0
    queue = deque([(start_row, start_column)])
    while queue:
        row, column = queue.popleft()
        for next_row, next_column in ((row - 1, column), (row + 1, column),
                                      (row, column - 1), (row, column + 1)):
            if 0 <= next_row < rows and 0 <= next_column < columns:
                if grid[next_row][next_column] != '#' and distances[next_row][next_column] < 0:
                    distances[next_row][next_column] = distances[row][column] + 1
                    queue.append((next_row, next_column))
    return distances


def oracle_mall(grid):
    car = None
    stores = []
    for row, line in enumerate(grid):
        for column, cell in enumerate(line):
            if cell == 'C':
                car = (row, column)
            elif cell == 'S':
                stores.append((row, column))
    points = [car] + stores
    tables = [distances_from(grid, point) for point in points]
    between = [[tables[source][destination[0]][destination[1]] for destination in points]
               for source in range(len(points))]
    store_count = len(stores)
    full_mask = (1 << store_count) - 1
    infinity = 10 ** 12
    costs = [[infinity] * store_count for _ in range(full_mask + 1)]
    for index in range(store_count):
        costs[1 << index][index] = SHOP_MINUTES
    for mask in range(full_mask + 1):
        for last in range(store_count):
            current = costs[mask][last]
            if current >= infinity:
                continue
            for following in range(store_count):
                if mask & (1 << following):
                    continue
                next_mask = mask | (1 << following)
                candidate = current + between[last + 1][0] + between[0][following + 1] + SHOP_MINUTES
                if candidate < costs[next_mask][following]:
                    costs[next_mask][following] = candidate
    return min(costs[full_mask][last] + between[last + 1][0] for last in range(store_count))


def oracle(text):
    lines = text.splitlines()
    position = 0
    mall_count = int(lines[position])
    position += 1
    answers = []
    for _ in range(mall_count):
        rows, columns = map(int, lines[position].split())
        position += 1
        grid = lines[position:position + rows]
        position += rows
        answers.append(str(oracle_mall(grid)))
    return "\n".join(answers) + "\n"


SAMPLE = """2
4 4
..S#
.##C
....
S.#S
1 5
SSCSS
"""
SAMPLE_OUT = """202
250
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 2\nSC\n") == "61\n"
assert oracle("1\n2 2\nSC\n.S\n") == "123\n"
assert oracle("1\n1 2\nCS\n") == "61\n"


def write_malls(name, grids):
    lines = [str(len(grids))]
    for grid in grids:
        lines.append(f"{len(grid)} {len(grid[0])}")
        lines.extend(grid)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_grid(rng, rows, columns, store_count, wall_chance):
    while True:
        cells = [['.' for _ in range(columns)] for _ in range(rows)]
        positions = rng.sample(range(rows * columns), store_count + 1)
        car_position = positions[0]
        cells[car_position // columns][car_position % columns] = 'C'
        for cell_index in positions[1:]:
            cells[cell_index // columns][cell_index % columns] = 'S'
        for row in range(rows):
            for column in range(columns):
                if cells[row][column] == '.' and rng.random() < wall_chance:
                    cells[row][column] = '#'
        grid = ["".join(line) for line in cells]
        car = (car_position // columns, car_position % columns)
        reachable = distances_from(grid, car)
        if all(reachable[index // columns][index % columns] >= 0 for index in positions[1:]):
            return grid


def build():
    rng = random.Random(20261126)
    write_malls("2_edges", [
        ["SC"],
        ["CS"],
        ["S.S", ".#C"],
        ["S..C.S"],
    ])
    write_malls("3_wide", [random_grid(rng, 10, 10, 8, 0.1) for _ in range(20)])
    random_grids = []
    for _ in range(30):
        rows = rng.randint(1, 8)
        columns = rng.randint(2, 8)
        store_count = min(rows * columns - 1, rng.randint(1, 6))
        random_grids.append(random_grid(rng, rows, columns, store_count, rng.random() * 0.3))
    write_malls("4_random", random_grids)
    io_grids = []
    for _ in range(100):
        io_grids.append(random_grid(rng, 5, 5, rng.randint(1, 6), 0.15))
    write_malls("5_io", io_grids)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_malls("1_sample", [["..S#", ".##C", "....", "S.#S"], ["SSCSS"]])
build()
