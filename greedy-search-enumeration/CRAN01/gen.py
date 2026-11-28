#!/usr/bin/env python3
import random
from pathlib import Path
from collections import deque

ROOT = Path(__file__).resolve().parent


def simulate_spread(rows, columns, start_row, start_column, rng):
    occupied = {(start_row - 1, start_column - 1)}
    time = 0

    while len(occupied) < rows * columns and time <= rows + columns + 5:
        time += 1
        free = []
        for row, column in occupied:
            for delta_row, delta_column in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                neighbor = (row + delta_row, column + delta_column)
                if (0 <= neighbor[0] < rows and 0 <= neighbor[1] < columns
                        and neighbor not in occupied and neighbor not in free):
                    free.append(neighbor)
        slots = []
        for cell in occupied:
            slots.extend([cell, cell])
        adjacency = {index: [] for index in range(len(free))}
        for index, cell in enumerate(free):
            for delta_row, delta_column in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                parent = (cell[0] + delta_row, cell[1] + delta_column)
                if parent in occupied:
                    for slot_index in range(len(slots)):
                        if slots[slot_index] == parent:
                            adjacency[index].append(slot_index)
        matched = {}

        def augment(free_index, seen):
            for slot_index in adjacency[free_index]:
                if slot_index in seen:
                    continue
                seen.add(slot_index)
                if slot_index not in matched or augment(matched[slot_index], seen):
                    matched[slot_index] = free_index
                    return True
            return False

        order = list(range(len(free)))
        rng.shuffle(order)
        for free_index in order:
            augment(free_index, set())
        added = {free[index] for index in matched.values()}
        occupied.update(added)
        if not added:
            break
    return time


def oracle_case(rows, columns, start_row, start_column):
    seed = rows * 1000000 + columns * 10000 + start_row * 100 + start_column
    rng = random.Random(seed)
    best = None
    for _ in range(40):
        time = simulate_spread(rows, columns, start_row, start_column, rng)
        if best is None or time < best:
            best = time
    return best


def brute_case(rows, columns, start_row, start_column):
    total = rows * columns

    def index(cell):
        return cell[0] * columns + cell[1]

    start = (start_row - 1, start_column - 1)
    neighbors = {}
    for row in range(rows):
        for column in range(columns):
            cell_neighbors = []
            for delta_row, delta_column in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                neighbor = (row + delta_row, column + delta_column)
                if 0 <= neighbor[0] < rows and 0 <= neighbor[1] < columns:
                    cell_neighbors.append(neighbor)
            neighbors[(row, column)] = cell_neighbors
    full = (1 << total) - 1
    initial = 1 << index(start)
    queue = deque([initial])
    distance = {initial: 0}
    while queue:
        mask = queue.popleft()
        if mask == full:
            return distance[mask]
        free = [cell for row in range(rows) for column in range(columns)
                if not (mask >> index((row, column))) & 1
                for cell in [(row, column)]]
        capacity = {cell: 2 for cell in neighbors if (mask >> index(cell)) & 1}
        results = set()

        def explore(position, new_mask, caps):
            if position == len(free):
                if new_mask != mask:
                    results.add(new_mask)
                return
            cell = free[position]
            explore(position + 1, new_mask, caps)
            for parent in neighbors[cell]:
                if parent in caps and caps[parent] > 0:
                    updated = dict(caps)
                    updated[parent] -= 1
                    explore(position + 1, new_mask | (1 << index(cell)), updated)

        explore(0, mask, capacity)
        for new_mask in results:
            if new_mask not in distance:
                distance[new_mask] = distance[mask] + 1
                queue.append(new_mask)
    return None


def oracle(text):
    tokens = [int(value) for value in text.split()]
    test_count = tokens[0]
    answers = []
    cursor = 1
    for _ in range(test_count):
        rows = tokens[cursor]
        columns = tokens[cursor + 1]
        start_row = tokens[cursor + 2]
        start_column = tokens[cursor + 3]
        cursor += 4
        answers.append(str(oracle_case(rows, columns, start_row, start_column)))
    return "\n".join(answers) + "\n"


SAMPLE = "2\n1 1 1 1\n11 10 6 4\n"
SAMPLE_OUT = "0\n11\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1 1 1\n") == "0\n"
assert oracle("1\n3 3 2 2\n") == "2\n"
assert oracle("1\n3 3 1 1\n") == "4\n"
assert oracle("1\n1 11 1 10\n") == "9\n"
for rows in range(1, 4):
    for columns in range(1, 5):
        for start_row in range(1, rows + 1):
            for start_column in range(1, columns + 1):
                assert oracle_case(rows, columns, start_row, start_column) == brute_case(
                    rows, columns, start_row, start_column)


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(
        f"{rows} {columns} {start_row} {start_column}\n"
        for rows, columns, start_row, start_column in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [(1, 1, 1, 1), (1, 5, 1, 3), (5, 1, 5, 1), (3, 3, 2, 2), (3, 3, 1, 1)])
    write("3_wide", [(1, 100, 1, 1), (100, 1, 100, 1), (4, 4, 2, 3), (5, 5, 3, 3)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(30):
        rows = rng.randint(1, 5)
        columns = rng.randint(1, 5)
        random_cases.append((rows, columns, rng.randint(1, rows), rng.randint(1, columns)))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(50):
        rows = rng.randint(1, 5)
        columns = rng.randint(1, 5)
        io_cases.append((rows, columns, rng.randint(1, rows), rng.randint(1, columns)))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(1, 1, 1, 1), (11, 10, 6, 4)])
build()
