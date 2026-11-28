#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DIRS = [(-1, 0), (1, 0), (0, -1), (0, 1)]

SAMPLE = (
    "1\n"
    "10 12\n"
    "SSSSSSSSSSSS\n"
    "SwwwwwwwSSSS\n"
    "SwSSSSwwSSSS\n"
    "SwSSSSwwSKSS\n"
    "SwSSSSwwSwSS\n"
    "SwwwwwPwwwww\n"
    "SSSSSSSwSwSw\n"
    "SSSSSSMwSwww\n"
    "SSSSSSSSSSSS\n"
    "SSSSSSSSSSSS\n"
)


def parse(text):
    tokens = text.split()
    pos = 0
    count = int(tokens[pos]); pos += 1
    cases = []
    for _ in range(count):
        rows = int(tokens[pos]); cols = int(tokens[pos + 1]); pos += 2
        grid = tokens[pos:pos + rows]; pos += rows
        cases.append((rows, cols, grid))
    return cases


def positions(rows, cols, grid):
    parcel = keeper = target = -1
    for r in range(rows):
        for c in range(cols):
            mark = grid[r][c]
            cell = r * cols + c
            if mark == 'P':
                parcel = cell
            elif mark == 'M':
                keeper = cell
            elif mark == 'K':
                target = cell
    return parcel, keeper, target


def neighbors(cell, rows, cols):
    r, c = divmod(cell, cols)
    for dr, dc in DIRS:
        nr, nc = r + dr, c + dc
        if 0 <= nr < rows and 0 <= nc < cols:
            yield nr * cols + nc


def oracle_case(rows, cols, grid):
    parcel, keeper, target = positions(rows, cols, grid)
    if parcel == target:
        return 0
    start = (parcel, keeper)
    dist = {start: 0}
    queue = deque([start])
    while queue:
        parcel_here, keeper_here = queue.popleft()
        pushes = dist[(parcel_here, keeper_here)]
        for walk_cell in neighbors(keeper_here, rows, cols):
            if walk_cell != parcel_here and grid[walk_cell // cols][walk_cell % cols] != 'S':
                state = (parcel_here, walk_cell)
                if state not in dist:
                    dist[state] = pushes
                    queue.appendleft(state)
        parcel_row, parcel_col = divmod(parcel_here, cols)
        for dr, dc in DIRS:
            stand_row, stand_col = parcel_row - dr, parcel_col - dc
            land_row, land_col = parcel_row + dr, parcel_col + dc
            if not (0 <= stand_row < rows and 0 <= stand_col < cols):
                continue
            if not (0 <= land_row < rows and 0 <= land_col < cols):
                continue
            stand_cell = stand_row * cols + stand_col
            land_cell = land_row * cols + land_col
            if stand_cell != keeper_here:
                continue
            if grid[land_row][land_col] == 'S':
                continue
            if land_cell == target:
                return pushes + 1
            state = (land_cell, parcel_here)
            if state not in dist:
                dist[state] = pushes + 1
                queue.append(state)
    return None


def brute_case(rows, cols, grid, limit):
    parcel, keeper, target = positions(rows, cols, grid)
    best = [None]

    def keeper_reach(parcel_here, keeper_here):
        seen = {keeper_here}
        queue = deque([keeper_here])
        while queue:
            cell = queue.popleft()
            for walk_cell in neighbors(cell, rows, cols):
                if (walk_cell != parcel_here and walk_cell not in seen and
                        grid[walk_cell // cols][walk_cell % cols] != 'S'):
                    seen.add(walk_cell)
                    queue.append(walk_cell)
        return seen

    def search(parcel_here, keeper_here, depth):
        if parcel_here == target:
            if best[0] is None or depth < best[0]:
                best[0] = depth
            return
        if depth >= limit:
            return
        reachable = keeper_reach(parcel_here, keeper_here)
        parcel_row, parcel_col = divmod(parcel_here, cols)
        for dr, dc in DIRS:
            stand_row, stand_col = parcel_row - dr, parcel_col - dc
            land_row, land_col = parcel_row + dr, parcel_col + dc
            if not (0 <= stand_row < rows and 0 <= stand_col < cols):
                continue
            if not (0 <= land_row < rows and 0 <= land_col < cols):
                continue
            stand_cell = stand_row * cols + stand_col
            land_cell = land_row * cols + land_col
            if (stand_cell in reachable and grid[land_row][land_col] != 'S'):
                search(land_cell, parcel_here, depth + 1)

    search(parcel, keeper, 0)
    return best[0]


def oracle(text):
    answers = []
    for rows, cols, grid in parse(text):
        result = oracle_case(rows, cols, grid)
        answers.append("NO" if result is None else str(result))
    return "\n".join(answers) + "\n"


def case_text(cases):
    blocks = []
    for rows, cols, grid in cases:
        blocks.append(f"{rows} {cols}\n" + "\n".join(grid))
    return str(len(cases)) + "\n" + "\n\n".join(blocks) + "\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


assert oracle(SAMPLE) == "7\n"
assert oracle(case_text([(1, 3, ["MPK"])])) == "1\n"
assert oracle(case_text([(1, 5, ["MPwwK"])])) == "3\n"
assert oracle(case_text([(1, 3, ["PMK"])])) == "NO\n"
assert oracle(case_text([(3, 3, ["KMw", "SPS", "SSS"])])) == "NO\n"

random.seed(208)
for _ in range(30):
    grid = []
    for r in range(3):
        grid.append("".join(random.choice("wSw") for c in range(3)))
    cells = [(r, c) for r in range(3) for c in range(3)]
    random.shuffle(cells)
    for mark in "MPK":
        row, col = cells.pop()
        grid[row] = grid[row][:col] + mark + grid[row][col + 1:]
    from_full = oracle_case(3, 3, grid)
    from_brute = brute_case(3, 3, grid, 4)
    if from_brute is not None:
        assert from_full is not None and from_full <= from_brute
    if from_full is not None and from_full <= 4:
        assert from_brute is not None and from_brute == from_full


def large_open():
    grid = [["S" for _ in range(100)] for _ in range(100)]
    for r in range(1, 99):
        for c in range(1, 99):
            grid[r][c] = "w"
    grid[50][48] = "M"
    grid[50][49] = "P"
    grid[50][50] = "K"
    return [list("".join(row)) for row in grid]


def large_corridor():
    grid = [["S" for _ in range(100)] for _ in range(100)]
    for c in range(1, 61):
        grid[50][c] = "w"
    grid[50][1] = "M"
    grid[50][2] = "P"
    grid[50][60] = "K"
    return [list("".join(row)) for row in grid]


def large_room():
    grid = [["S" for _ in range(100)] for _ in range(100)]
    for r in range(40, 45):
        for c in range(40, 45):
            grid[r][c] = "w"
    grid[42][40] = "M"
    grid[42][41] = "P"
    grid[42][44] = "K"
    return [list("".join(row)) for row in grid]


def build():
    edges = [
        (1, 3, ["MPK"]),
        (1, 5, ["MPwwK"]),
        (1, 3, ["PMK"]),
        (3, 3, ["SMS", "SPS", "SKS"]),
        (3, 3, ["KMw", "SPS", "SSS"]),
        (3, 3, ["MSS", "PwS", "wKS"]),
        (5, 5, ["wwwww", "wSSSw", "wMPKw", "wSSSw", "wwwww"]),
    ]
    write("2_edges", case_text(edges))

    wide = []
    for maker in (large_open, large_corridor, large_room):
        grid = maker()
        wide.append((100, 100, ["".join(row) for row in grid]))
    write("3_wide", case_text(wide))

    random.seed(916)
    rnd = []
    for _ in range(60):
        rows = random.randint(5, 9)
        cols = random.randint(5, 9)
        grid = [["S" if random.randrange(4) == 0 else "w"
                 for _ in range(cols)] for _ in range(rows)]
        cells = [(r, c) for r in range(rows) for c in range(cols)]
        random.shuffle(cells)
        for mark in "MPK":
            row, col = cells.pop()
            grid[row][col] = mark
        rnd.append((rows, cols, ["".join(row) for row in grid]))
    write("4_random", case_text(rnd))

    io = []
    for i in range(20000):
        io.append((1, 3, ["MPK" if i % 2 == 0 else "PMK"]))
    write("5_io", case_text(io))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(oracle(SAMPLE))
build()
