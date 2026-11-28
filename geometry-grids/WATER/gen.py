#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MAX_HEIGHT = 10000
SAMPLE_TEXT = ("1\n"
               "3 6\n"
               "3 3 4 4 4 2\n"
               "3 1 3 2 1 4\n"
               "7 3 1 6 4 1\n")
SAMPLE_GRID = [[3, 3, 4, 4, 4, 2],
               [3, 1, 3, 2, 1, 4],
               [7, 3, 1, 6, 4, 1]]


def neighbours(k, rows, cols):
    row, col = divmod(k, cols)
    if row > 0:
        yield k - cols
    if row + 1 < rows:
        yield k + cols
    if col > 0:
        yield k - 1
    if col + 1 < cols:
        yield k + 1


def oracle_case(heights, rows, cols):
    cell_count = rows * cols
    parent = list(range(cell_count))
    group_size = [1] * cell_count
    sealed = [False] * cell_count
    pending = [[k] for k in range(cell_count)]
    added = [False] * cell_count
    level = [-1] * cell_count

    def find(k):
        while parent[k] != k:
            parent[k] = parent[parent[k]]
            k = parent[k]
        return k

    def merge(left, right):
        if left == right:
            return left
        if group_size[left] < group_size[right]:
            left, right = right, left
        parent[right] = left
        group_size[left] += group_size[right]
        if sealed[right]:
            sealed[left] = True
        pending[left].extend(pending[right])
        return left

    order = sorted(range(cell_count), key=lambda k: heights[k])
    pos = 0
    while pos < cell_count:
        wall = heights[order[pos]]
        batch = []
        while pos < cell_count and heights[order[pos]] == wall:
            batch.append(order[pos])
            pos += 1
        for k in batch:
            added[k] = True
            for nb in neighbours(k, rows, cols):
                if added[nb]:
                    merge(find(k), find(nb))
            row, col = divmod(k, cols)
            if row == 0 or row == rows - 1 or col == 0 or col == cols - 1:
                sealed[find(k)] = True
        for k in batch:
            root = find(k)
            if sealed[root]:
                for member in pending[root]:
                    level[member] = wall
                pending[root] = []
    total = 0
    for k in range(cell_count):
        water_line = level[k] if level[k] >= 0 else MAX_HEIGHT
        total += water_line - heights[k]
    return total


def levels_case(heights, rows, cols):
    cell_count = rows * cols
    walls = [None] * cell_count
    for target in sorted(set(heights)):
        seen = [False] * cell_count
        stack = []
        for k in range(cell_count):
            row, col = divmod(k, cols)
            if ((row == 0 or row == rows - 1 or col == 0 or col == cols - 1)
                    and heights[k] <= target):
                seen[k] = True
                stack.append(k)
        while stack:
            k = stack.pop()
            for nb in neighbours(k, rows, cols):
                if not seen[nb] and heights[nb] <= target:
                    seen[nb] = True
                    stack.append(nb)
        for k in range(cell_count):
            if seen[k] and walls[k] is None:
                walls[k] = target
    return walls


def brute_case(heights, rows, cols):
    walls = levels_case(heights, rows, cols)
    return sum(walls[k] - heights[k] for k in range(len(walls)))


def oracle(text):
    tokens = text.split()
    cursor = 0
    cases = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(cases):
        rows = int(tokens[cursor]); cols = int(tokens[cursor + 1]); cursor += 2
        heights = [int(tokens[cursor + k]) for k in range(rows * cols)]
        cursor += rows * cols
        answers.append(str(oracle_case(heights, rows, cols)))
    return "\n".join(answers) + "\n"


def encode(cases):
    chunks = []
    for rows, cols, grid in cases:
        chunks.append(str(rows) + " " + str(cols) + "\n" +
                      "\n".join(" ".join(map(str, row)) for row in grid))
    return str(len(cases)) + "\n" + "\n\n".join(chunks) + "\n"


def write(name, text):
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(text))


def flat(rows, cols, value):
    return [[value] * cols for _ in range(rows)]


def bowl(rows, cols, wall, floor):
    grid = flat(rows, cols, floor)
    for k in range(cols):
        grid[0][k] = wall
        grid[rows - 1][k] = wall
    for k in range(rows):
        grid[k][0] = wall
        grid[k][cols - 1] = wall
    return grid


SAMPLE_FLAT = [value for row in SAMPLE_GRID for value in row]
assert oracle(SAMPLE_TEXT) == "5\n"
assert oracle_case(SAMPLE_FLAT, 3, 6) == 5
assert oracle_case([5, 5, 5, 5, 1, 5, 5, 5, 5], 3, 3) == 4
assert oracle_case([7], 1, 1) == 0
assert oracle_case([1, 2, 3, 4], 2, 2) == 0
big_bowl = [item for row in bowl(100, 100, MAX_HEIGHT, 1) for item in row]
assert oracle_case(big_bowl, 100, 100) == 9604 * 9999
random.seed(1937)
for _ in range(200):
    rows = random.randint(1, 5)
    cols = random.randint(1, 5)
    values = [random.randint(1, 12) for _ in range(rows * cols)]
    assert oracle_case(values, rows, cols) == brute_case(values, rows, cols)


def build():
    edges = [
        (1, 1, [[1]]),
        (1, 100, [[random.randint(1, MAX_HEIGHT) for _ in range(100)]]),
        (100, 1, [[random.randint(1, MAX_HEIGHT)] for _ in range(100)]),
        (2, 2, [[1, 2], [3, 4]]),
        (3, 3, [[5, 5, 5], [5, 1, 5], [5, 5, 5]]),
        (3, 6, SAMPLE_GRID),
        (100, 100, flat(100, 100, 7)),
        (100, 100, flat(100, 100, MAX_HEIGHT)),
        (100, 100, bowl(100, 100, MAX_HEIGHT, 1)),
        (100, 100, bowl(100, 100, 1, MAX_HEIGHT)),
    ]
    write("2_edges", encode(edges))

    random.seed(20261124)
    wide = [
        (100, 100, flat(100, 100, 1)),
        (100, 100, flat(100, 100, MAX_HEIGHT)),
        (100, 100, bowl(100, 100, MAX_HEIGHT, 1)),
        (100, 100, bowl(100, 100, 1, MAX_HEIGHT)),
        (100, 100, [[random.randint(1, MAX_HEIGHT) for _ in range(100)]
                    for _ in range(100)]),
        (100, 100, [[1 if (r + c) % 2 == 0 else MAX_HEIGHT
                     for c in range(100)] for r in range(100)]),
        (100, 100, [[random.randint(1, 5) for _ in range(100)]
                    for _ in range(100)]),
        (100, 100, [[1 + ((r + c) % 100) * 99 for c in range(100)]
                    for r in range(100)]),
        (100, 100, [[1 + (r * 99 + c) % 10000 for c in range(100)]
                    for r in range(100)]),
        (100, 100, [[MAX_HEIGHT for _ in range(100)] for _ in range(100)]),
    ]
    deep_pit = flat(100, 100, 9000)
    deep_pit[50][50] = 1
    wide.append((100, 100, deep_pit))
    terraced = [[min(MAX_HEIGHT, 1 + max(abs(r - 50), abs(c - 50)) * 100)
                 for c in range(100)] for r in range(100)]
    wide.append((100, 100, terraced))
    random_wall = bowl(100, 100, 1, 1)
    for c in range(100):
        random_wall[0][c] = random.randint(2, MAX_HEIGHT)
        random_wall[99][c] = random.randint(2, MAX_HEIGHT)
    for r in range(100):
        random_wall[r][0] = random.randint(2, MAX_HEIGHT)
        random_wall[r][99] = random.randint(2, MAX_HEIGHT)
    wide.append((100, 100, random_wall))
    write("3_wide", encode(wide))

    random.seed(777)
    general = []
    for _ in range(24):
        rows = random.randint(1, 100)
        cols = random.randint(1, 100)
        spread = random.choice([3, 10, 100, MAX_HEIGHT])
        grid = [[random.randint(1, spread) for _ in range(cols)]
                for _ in range(rows)]
        general.append((rows, cols, grid))
    write("4_random", encode(general))

    random.seed(31337)
    many = []
    for _ in range(60000):
        center = random.randint(1, MAX_HEIGHT)
        many.append((3, 3, [[MAX_HEIGHT, MAX_HEIGHT, MAX_HEIGHT],
                            [MAX_HEIGHT, center, MAX_HEIGHT],
                            [MAX_HEIGHT, MAX_HEIGHT, MAX_HEIGHT]]))
    write("5_io", encode(many))


def worked_example():
    walls = levels_case(SAMPLE_FLAT, 3, 6)
    print("water line:")
    for r in range(3):
        print(" ".join(str(walls[r * 6 + c]) for c in range(6)))
    print("depth:")
    for r in range(3):
        print(" ".join(str(walls[r * 6 + c] - SAMPLE_FLAT[r * 6 + c])
                       for c in range(6)))
    print("total", sum(walls[k] - SAMPLE_FLAT[k] for k in range(18)))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_TEXT)
build()
worked_example()
