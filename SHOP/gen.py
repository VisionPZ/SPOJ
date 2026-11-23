import heapq
import os
import random

os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)

SAMPLE_INPUT = """4 3
X1S3
42X4
X1D2

5 5
S5213
2X2X5
51248
4X4X2
1445D

0 0
"""
SAMPLE_OUTPUT = "4\n23\n"


def find_markers(grid):
    start = None
    destination = None
    for row_index, row in enumerate(grid):
        for col_index, cell in enumerate(row):
            if cell == "S":
                start = (row_index, col_index)
            if cell == "D":
                destination = (row_index, col_index)
    assert start is not None and destination is not None
    return start, destination


def neighbours(row_index, col_index, height, width):
    return ((row_index - 1, col_index), (row_index + 1, col_index),
            (row_index, col_index - 1), (row_index, col_index + 1))


def step_cost(cell):
    if cell in "SD":
        return 0
    return int(cell)


def oracle(grid):
    """Binary-heap Dijkstra, independent of the bucket queue in the solution."""
    height = len(grid)
    width = len(grid[0])
    start, destination = find_markers(grid)
    distance = [[None] * width for _ in range(height)]
    distance[start[0]][start[1]] = 0
    queue = [(0, start[0], start[1])]
    while queue:
        current, row_index, col_index = heapq.heappop(queue)
        if distance[row_index][col_index] != current:
            continue
        if (row_index, col_index) == destination:
            return current
        for next_row, next_col in neighbours(row_index, col_index, height, width):
            if not (0 <= next_row < height and 0 <= next_col < width):
                continue
            cell = grid[next_row][next_col]
            if cell == "X":
                continue
            candidate = current + step_cost(cell)
            if (distance[next_row][next_col] is None or
                    candidate < distance[next_row][next_col]):
                distance[next_row][next_col] = candidate
                heapq.heappush(queue, (candidate, next_row, next_col))
    raise AssertionError("oracle found no path")


def oracle_by_relaxation(grid):
    """Repeat full relaxations; a second method that uses no priority queue."""
    height = len(grid)
    width = len(grid[0])
    start, destination = find_markers(grid)
    large = 10 ** 9
    distance = [[large] * width for _ in range(height)]
    distance[start[0]][start[1]] = 0
    for _ in range(height * width):
        changed = False
        for row_index in range(height):
            for col_index in range(width):
                if grid[row_index][col_index] == "X":
                    continue
                if distance[row_index][col_index] >= large:
                    continue
                for next_row, next_col in neighbours(row_index, col_index, height, width):
                    if not (0 <= next_row < height and 0 <= next_col < width):
                        continue
                    if grid[next_row][next_col] == "X":
                        continue
                    candidate = distance[row_index][col_index] + step_cost(grid[next_row][next_col])
                    if candidate < distance[next_row][next_col]:
                        distance[next_row][next_col] = candidate
                        changed = True
        if not changed:
            break
    result = distance[destination[0]][destination[1]]
    assert result < large
    return result


def path_exists(grid):
    height = len(grid)
    width = len(grid[0])
    start, destination = find_markers(grid)
    seen = {start}
    queue = [start]
    while queue:
        row_index, col_index = queue.pop()
        if (row_index, col_index) == destination:
            return True
        for next_row, next_col in neighbours(row_index, col_index, height, width):
            if not (0 <= next_row < height and 0 <= next_col < width):
                continue
            if grid[next_row][next_col] == "X":
                continue
            if (next_row, next_col) not in seen:
                seen.add((next_row, next_col))
                queue.append((next_row, next_col))
    return False


def make_grid(rng, width, height, block_probability=0.0, top_digit=9):
    while True:
        rows = []
        for _ in range(height):
            row = []
            for _ in range(width):
                if rng.random() < block_probability:
                    row.append("X")
                else:
                    row.append(str(rng.randint(1, top_digit)))
            rows.append(row)
        positions = [(r, c) for r in range(height) for c in range(width)]
        start_row, start_col = rng.choice(positions)
        others = [p for p in positions if p != (start_row, start_col)]
        dest_row, dest_col = rng.choice(others)
        rows[start_row][start_col] = "S"
        rows[dest_row][dest_col] = "D"
        grid = ["".join(row) for row in rows]
        if path_exists(grid):
            return grid


def format_case(grid_rows):
    height = len(grid_rows)
    width = len(grid_rows[0])
    return "%d %d\n" % (width, height) + "\n".join(grid_rows) + "\n\n"


def write_case_set(name, cases):
    body = "".join(format_case(case) for case in cases) + "0 0\n"
    answers = "".join("%d\n" % oracle(case) for case in cases)
    with open("in/%s.txt" % name, "w") as handle:
        handle.write(body)
    with open("out/%s.out" % name, "w") as handle:
        handle.write(answers)


assert oracle(["X1S3", "42X4", "X1D2"]) == 4
assert oracle(["S5213", "2X2X5", "51248", "4X4X2", "1445D"]) == 23
assert oracle(["S" + "9" * 23 + "D"]) == 207
assert oracle(["S" + "9" * 24] + ["9" * 25] * 23 + ["9" * 24 + "D"]) == 423
assert oracle_by_relaxation(["1S3", "4X4", "1D2"]) == oracle(["1S3", "4X4", "1D2"])
for seed in range(40):
    probe_rng = random.Random(seed)
    probe_grid = make_grid(probe_rng, probe_rng.randint(2, 8),
                           probe_rng.randint(2, 8), 0.12, 9)
    assert oracle(probe_grid) == oracle_by_relaxation(probe_grid)

with open("in/1_sample.txt", "w") as handle:
    handle.write(SAMPLE_INPUT)
with open("out/1_sample.out", "w") as handle:
    handle.write(SAMPLE_OUTPUT)

edges = [
    ["SD"],
    ["S9D"],
    ["S", "9", "D"],
    ["S" + "9" * 23 + "D"],
    ["9" * 24 + "S"] + ["9" * 25] * 23 + ["D" + "9" * 24],
    ["1S1", "1X1", "1D1"],
    ["9" * 12 + "S" + "9" * 12, "9" * 12 + "D" + "9" * 12],
    ["S1111", "1XXX1", "1XXX1", "1111D"],
    ["1" * 25] * 25,
    ["9" * 25] * 25,
]
edges[8][0] = "S" + "1" * 24
edges[8][24] = "1" * 24 + "D"
edges[9][0] = "S" + "9" * 24
edges[9][24] = "9" * 24 + "D"
write_case_set("2_edges", edges)

wide = [
    ["S" + "9" * 24] + ["9" * 25] * 23 + ["9" * 24 + "D"],
    ["S" + "1" * 24] + ["1" * 25] * 23 + ["1" * 24 + "D"],
    make_grid(random.Random(101), 25, 25, 0.18, 9),
    make_grid(random.Random(102), 25, 25, 0.35, 9),
]
write_case_set("3_wide", wide)

random_cases = []
for index in range(40):
    generator = random.Random(200 + index)
    random_cases.append(make_grid(generator, generator.randint(2, 25),
                                  generator.randint(2, 25), 0.15, 9))
write_case_set("4_random", random_cases)

io_case = ["S" + "9" * 23 + "D"]
io_expected = oracle(io_case)
io_body = format_case(io_case) * 100000 + "0 0\n"
with open("in/5_io.txt", "w") as handle:
    handle.write(io_body)
with open("out/5_io.out", "w") as handle:
    handle.write(("%d\n" % io_expected) * 100000)

stress_body = format_case(["S9D"]) * 300000 + "0 0\n"
with open("/tmp/SHOP_big.txt", "w") as handle:
    handle.write(stress_body)
