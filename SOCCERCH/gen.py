#!/usr/bin/env python3
import heapq
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_case(grid, corner):
    rows, cols = len(grid), len(grid[0])
    cell_index = {(r, c): r * cols + c for r in range(rows) for c in range(cols)}
    cell_count = rows * cols
    target_bits = 0
    forbidden_bits = 0
    for (row, col), index in cell_index.items():
        if grid[row][col] == 'I':
            target_bits |= 1 << index
        if grid[row][col] == 'X':
            forbidden_bits |= 1 << index

    def vertex_id(row, col):
        return row * (cols + 1) + col

    start_vertex = vertex_id(*corner)
    if target_bits == 0:
        return 0
    vertex_total = (rows + 1) * (cols + 1)
    best = None
    for inside in range(1 << cell_count):
        if inside & target_bits != target_bits:
            continue
        if inside & forbidden_bits:
            continue
        boundary = set()

        def add_edge(first, second):
            boundary.add(tuple(sorted((first, second))))

        for row in range(rows):
            for col in range(cols):
                if not (inside >> cell_index[(row, col)]) & 1:
                    continue
                top_left = vertex_id(row, col)
                top_right = vertex_id(row, col + 1)
                bottom_left = vertex_id(row + 1, col)
                bottom_right = vertex_id(row + 1, col + 1)
                if row == 0 or not (inside >> cell_index[(row - 1, col)]) & 1:
                    add_edge(top_left, top_right)
                if row == rows - 1 or not (inside >> cell_index[(row + 1, col)]) & 1:
                    add_edge(bottom_left, bottom_right)
                if col == 0 or not (inside >> cell_index[(row, col - 1)]) & 1:
                    add_edge(top_left, bottom_left)
                if col == cols - 1 or not (inside >> cell_index[(row, col + 1)]) & 1:
                    add_edge(top_right, bottom_right)
        if not boundary:
            continue
        parent = list(range(vertex_total))

        def find(node):
            while parent[node] != node:
                parent[node] = parent[parent[node]]
                node = parent[node]
            return node

        for first, second in boundary:
            first_root, second_root = find(first), find(second)
            if first_root != second_root:
                parent[first_root] = second_root
        component_of = {}
        for first, second in boundary:
            for vertex in (first, second):
                root = find(vertex)
                if root not in component_of:
                    component_of[root] = len(component_of)
        comp_at_vertex = [-1] * vertex_total
        for vertex in range(vertex_total):
            root = find(vertex)
            if root in component_of:
                comp_at_vertex[vertex] = component_of[root]
        component_count = len(component_of)
        start_component = comp_at_vertex[start_vertex]
        if start_component == -1:
            start_component = component_count
            component_count += 1
        full_mask = (1 << component_count) - 1
        start_mask = 1 << start_component
        distances = {}
        heap = [(0, start_mask, start_vertex)]
        while heap:
            cost, mask, vertex = heapq.heappop(heap)
            if (mask, vertex) in distances:
                continue
            distances[(mask, vertex)] = cost
            if mask == full_mask:
                break
            for neighbor in neighbors(vertex, rows, cols):
                next_mask = mask
                comp = comp_at_vertex[neighbor]
                step_cost = 1
                if comp >= 0 and (mask >> comp) & 1:
                    step_cost = 0
                elif comp >= 0:
                    next_mask |= 1 << comp
                key = (next_mask, neighbor)
                if key not in distances:
                    heapq.heappush(heap, (cost + step_cost, next_mask, neighbor))
        connection = min(
            (cost for (mask, vertex), cost in distances.items() if mask == full_mask),
            default=None,
        )
        if connection is None:
            continue
        total = len(boundary) + 2 * connection
        if best is None or total < best:
            best = total
    return best


def neighbors(vertex, rows, cols):
    row, col = divmod(vertex, cols + 1)
    for delta_row, delta_col in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        new_row, new_col = row + delta_row, col + delta_col
        if 0 <= new_row <= rows and 0 <= new_col <= cols:
            yield new_row * (cols + 1) + new_col


def parse(text):
    values = text.split()
    position = 0
    cases = []
    while position + 1 < len(values):
        rows, cols = int(values[position]), int(values[position + 1])
        position += 2
        if rows == 0 and cols == 0:
            break
        grid = values[position:position + rows]
        position += rows
        cases.append(grid)
    return cases


def oracle(text):
    lines = []
    for grid in parse(text):
        fernando = oracle_case(grid, (0, 0))
        martin = oracle_case(grid, (len(grid), len(grid[0])))
        if fernando == martin:
            lines.append(f"Tie {fernando}")
        elif fernando < martin:
            lines.append(f"Fernando {fernando}")
        else:
            lines.append(f"Martin {martin}")
    return '\n'.join(lines) + '\n'


SAMPLE = """1 1 I
2 2
XX
XI
2 2
XI
IX
3 3
III
IXI
III
2 2
IO
OO
0 0
"""
SAMPLE_OUT = """Tie 4
Martin 4
Tie 10
Tie 18
Fernando 4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_case(['I'], (0, 0)) == 4
assert oracle_case(['XX', 'XI'], (2, 2)) == 4
assert oracle_case(['IO', 'OO'], (0, 0)) == 4


def render(cases):
    blocks = []
    for grid in cases:
        blocks.append(f"{len(grid)} {len(grid[0])}")
        blocks.extend(grid)
    blocks.append("0 0")
    return '\n'.join(blocks) + '\n'


def write(name, cases):
    text = render(cases)
    (ROOT / 'in' / f'{name}.txt').write_text(text)
    (ROOT / 'out' / f'{name}.out').write_text(oracle(text))


def build():
    write('2_edges', [
        ['I'],
        ['O'],
        ['X'],
        ['II'],
        ['XX', 'XX'],
        ['IX', 'OI'],
    ])
    write('3_wide', [
        ['III', 'IXI', 'III'],
        ['III', 'III', 'III'],
        ['XIX', 'III', 'XIX'],
    ])
    rng = random.Random(20261126)
    cases = []
    for _ in range(10):
        rows = rng.randint(1, 3)
        cols = rng.randint(1, 3)
        grid = [''.join(rng.choice('IOX') for _ in range(cols)) for _ in range(rows)]
        cases.append(grid)
    write('4_random', cases)
    io_cases = []
    for index in range(40):
        rows = rng.randint(1, 3)
        cols = rng.randint(1, 3)
        grid = [''.join(rng.choice('IO') for _ in range(cols)) for _ in range(rows)]
        grid[0] = 'I' + grid[0][1:]
        io_cases.append(grid)
    write('5_io', io_cases)


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
(ROOT / 'in' / '1_sample.txt').write_text(SAMPLE)
(ROOT / 'out' / '1_sample.out').write_text(SAMPLE_OUT)
build()
