#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SCRATCH = Path("/tmp/opencode")


def oracle_grid(grid):
    rows = len(grid)
    cols = len(grid[0])
    best = 0
    for top in range(rows):
        full = [True] * cols
        for bottom in range(top, rows):
            line = grid[bottom]
            for c in range(cols):
                full[c] = full[c] and line[c] == 'F'
            run = 0
            for c in range(cols):
                if full[c]:
                    run += 1
                    area = run * (bottom - top + 1)
                    if area > best:
                        best = area
                else:
                    run = 0
    return best * 3


def brute_grid(grid):
    rows = len(grid)
    cols = len(grid[0])
    prefix = [[0] * (cols + 1) for _ in range(rows + 1)]
    for r in range(rows):
        for c in range(cols):
            prefix[r + 1][c + 1] = (prefix[r][c + 1] + prefix[r + 1][c]
                                   - prefix[r][c] + (1 if grid[r][c] == 'F' else 0))
    best = 0
    for top in range(rows):
        for bottom in range(top, rows):
            height = bottom - top + 1
            for left in range(cols):
                for right in range(left, cols):
                    cells = (prefix[bottom + 1][right + 1] - prefix[top][right + 1]
                             - prefix[bottom + 1][left] + prefix[top][left])
                    if cells == height * (right - left + 1):
                        best = max(best, cells)
    return best * 3


def render(grid):
    lines = [f"{len(grid)} {len(grid[0])}"]
    for row in grid:
        lines.append(" ".join(row))
    lines.append("")
    return "\n".join(lines) + "\n"


def write(name, grids, answers=None):
    text = str(len(grids)) + "\n" + "".join(render(grid) for grid in grids)
    if answers is None:
        answers = [oracle_grid(grid) for grid in grids]
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text("".join(f"{value}\n" for value in answers))


def grid_from(rows):
    return [[letter for letter in line] for line in rows]


sample = grid_from([
    "RFFFFF",
    "FFFFFF",
    "RRRFFF",
    "FFFFFF",
    "FFFFFF",
])
all_reserved = grid_from(["RRRRR", "RRRRR", "RRRRR", "RRRRR", "RRRRR"])

assert oracle_grid(sample) == 45
assert oracle_grid(all_reserved) == 0
assert oracle_grid(grid_from(["F"])) == 3
assert oracle_grid(grid_from(["F", "F", "F"])) == 9
assert oracle_grid(grid_from(["FFFFFF"])) == 18

random.seed(277)
for _ in range(200):
    rows = random.randint(1, 6)
    cols = random.randint(1, 6)
    small = [[random.choice("FR") for _ in range(cols)] for _ in range(rows)]
    assert oracle_grid(small) == brute_grid(small)


def build():
    edges = [
        grid_from(["F"]),
        grid_from(["R"]),
        grid_from(["FFFFFF"]),
        grid_from(["F", "F", "F", "F", "F"]),
        grid_from(["RRR", "RRR", "RRR"]),
        grid_from(["FF", "FF"]),
        grid_from(["FFF", "FFF", "RRR"]),
        grid_from(["RFR", "FFF", "RFR"]),
        grid_from(["FR", "RF"]),
        grid_from(["FFFF", "FFFF", "RRRR", "RRRR"]),
    ]
    write("2_edges", edges)

    big = 1000
    wide = [
        [["F"] * big for _ in range(big)],
        [["R"] * big for _ in range(big)],
        [["F" if (r + c) % 2 == 0 else "R" for c in range(big)] for r in range(big)],
        [["F" if c % 2 == 0 else "R" for c in range(big)] for r in range(big)],
    ]
    write("3_wide", wide, [3 * big * big, 0, 3, 3 * big])

    random.seed(2026)
    rnd = []
    for _ in range(60):
        rows = random.randint(1, 30)
        cols = random.randint(1, 30)
        density = random.choice([0.2, 0.5, 0.8, 0.95])
        rnd.append([["F" if random.random() < density else "R" for _ in range(cols)]
                    for _ in range(rows)])
    write("4_random", rnd)

    write("5_io", [[["F"]] for _ in range(200000)])

    scratch_text = "1\n" + render([["F"] * big for _ in range(big)])
    SCRATCH.mkdir(parents=True, exist_ok=True)
    (SCRATCH / "CTGAME_big.txt").write_text(scratch_text)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [sample, all_reserved], [45, 0])
build()
