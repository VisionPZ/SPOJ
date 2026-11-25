#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

BASE_SHAPES = {
    1: [(0, 0, 0)],
    2: [(0, 0, 0), (0, 1, 1)],
    3: [(0, 0, 0), (0, 1, 1), (0, 2, 2)],
    4: [(0, 0, 0), (0, 1, 1), (1, 1, 2)],
}
FORM_LENGTH = {1: 1, 2: 2, 3: 3, 4: 3}
INF = 10 ** 9


def shape_rotations(form):
    matrix = [[None] * 3 for _ in range(3)]
    for row, col, label in BASE_SHAPES[form]:
        matrix[row][col] = label
    found = []
    seen = set()
    for _ in range(4):
        raw = [(row, col, matrix[row][col])
               for row in range(3) for col in range(3)
               if matrix[row][col] is not None]
        min_row = min(row for row, _, _ in raw)
        min_col = min(col for _, col, _ in raw)
        cells = tuple(sorted((row - min_row, col - min_col, label)
                             for row, col, label in raw))
        if cells not in seen:
            seen.add(cells)
            found.append(cells)
        matrix = [list(row) for row in zip(*matrix[::-1])]
    return found


ROTATIONS = {form: shape_rotations(form) for form in BASE_SHAPES}


def placement_table(grid, tiles):
    rows = len(grid)
    cols = len(grid[0])
    wanted = set()
    for row in range(rows):
        for col in range(cols):
            if grid[row][col] != 2:
                wanted.add((row, col))
    table = {}
    for anchor in wanted:
        options = []
        for cost, form, paint in tiles:
            for shape in ROTATIONS[form]:
                for anchor_row, anchor_col, _ in shape:
                    covered = []
                    good = True
                    for row, col, label in shape:
                        abs_row = anchor[0] + row - anchor_row
                        abs_col = anchor[1] + col - anchor_col
                        if abs_row < 0 or abs_row >= rows or abs_col < 0 or abs_col >= cols:
                            good = False
                            break
                        if (abs_row, abs_col) not in wanted:
                            good = False
                            break
                        if grid[abs_row][abs_col] != paint[label]:
                            good = False
                            break
                        covered.append((abs_row, abs_col))
                    if good:
                        options.append((frozenset(covered), cost))
        table[anchor] = options
    return frozenset(wanted), table


def oracle(grid, tiles):
    remaining0, table = placement_table(grid, tiles)
    memo = {}

    def search(remaining):
        if not remaining:
            return 0
        if remaining in memo:
            return memo[remaining]
        pivot = None
        pivot_options = None
        for cell in remaining:
            usable = [(cells, cost) for cells, cost in table[cell] if cells <= remaining]
            if pivot_options is None or len(usable) < len(pivot_options):
                pivot = cell
                pivot_options = usable
            if not pivot_options:
                break
        if not pivot_options:
            memo[remaining] = -1
            return -1
        answer = INF
        for cells, cost in pivot_options:
            rest = search(remaining - cells)
            if rest >= 0 and cost + rest < answer:
                answer = cost + rest
        memo[remaining] = answer if answer < INF else -1
        return memo[remaining]

    return search(remaining0)


def brute(grid, tiles):
    remaining0, table = placement_table(grid, tiles)

    def search(remaining):
        if not remaining:
            return 0
        cell = min(remaining)
        answer = INF
        for cells, cost in table[cell]:
            if not cells <= remaining:
                continue
            rest = search(remaining - cells)
            if rest >= 0 and cost + rest < answer:
                answer = cost + rest
        return answer if answer < INF else -1

    return search(remaining0)


SAMPLE_INPUT = (
    "1\n"
    "4 3 3\n"
    "2 2 2\n"
    "2 0 0\n"
    "2 1 2\n"
    "2 2 2\n"
    "2 10 0 0\n"
    "1 5 1\n"
    "4 6 0 0 1\n"
)
SAMPLE_OUTPUT = "15\n"

SAMPLE_GRID = [[2, 2, 2], [2, 0, 0], [2, 1, 2], [2, 2, 2]]
SAMPLE_TILES = [(10, 2, (0, 0)), (5, 1, (1,)), (6, 4, (0, 0, 1))]


def make_case(rows, cols, grid, tiles):
    parts = [f"{rows} {cols} {len(tiles)}"]
    parts += [" ".join(str(value) for value in row) for row in grid]
    for cost, form, paint in tiles:
        parts.append(f"{form} {cost} " + " ".join(str(value) for value in paint))
    return "\n".join(parts) + "\n"


def solve_case(rows, cols, grid, tiles):
    if rows == 1 and cols == 1:
        wanted = grid[0][0]
        if wanted == 2:
            return 0
        best = INF
        for cost, form, paint in tiles:
            if form == 1 and paint[0] == wanted and cost < best:
                best = cost
        return best if best < INF else -1
    return oracle(grid, tiles)


def emit(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(
        make_case(rows, cols, grid, tiles) for rows, cols, grid, tiles in cases)
    output_text = "".join(
        str(solve_case(rows, cols, grid, tiles)) + "\n"
        for rows, cols, grid, tiles in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(output_text)
    return input_text, output_text


assert oracle(SAMPLE_GRID, SAMPLE_TILES) == 15
assert oracle([[0]], [(7, 1, (0,))]) == 7
assert oracle([[1]], [(7, 1, (0,))]) == -1
assert oracle([[2, 2], [2, 2]], [(9, 1, (1,))]) == 0

check_rng = random.Random(77)
for _ in range(25):
    small_rows = check_rng.randint(1, 3)
    small_cols = check_rng.randint(1, 3)
    small_grid = [[check_rng.randint(0, 2) for _ in range(small_cols)]
                  for _ in range(small_rows)]
    small_tiles = []
    for _ in range(check_rng.randint(1, 4)):
        form = check_rng.randint(1, 4)
        small_tiles.append((check_rng.randint(1, 20), form,
                            tuple(check_rng.randint(0, 1)
                                  for _ in range(FORM_LENGTH[form]))))
    assert oracle(small_grid, small_tiles) == brute(small_grid, small_tiles)


def main():
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)

    sample_in, sample_out = emit("1_sample", [(4, 3, SAMPLE_GRID, SAMPLE_TILES)])
    assert sample_in == SAMPLE_INPUT
    assert sample_out == SAMPLE_OUTPUT

    edges = [
        (1, 1, [[2]], [(9, 1, (1,))]),
        (1, 1, [[0]], [(5, 1, (0,))]),
        (1, 1, [[1]], [(5, 1, (0,))]),
        (1, 3, [[0, 0, 0]], [(7, 3, (0, 0, 0))]),
        (1, 3, [[1, 1, 1]], [(7, 3, (1, 1, 1))]),
        (1, 3, [[0, 1, 0]], [(7, 3, (0, 0, 0))]),
        (2, 2, [[0, 0], [0, 0]], [(3, 2, (0, 0))]),
        (2, 2, [[0, 0], [0, 2]], [(9, 4, (0, 0, 0))]),
        (2, 2, [[0, 0], [0, 2]], [(9, 4, (1, 1, 1))]),
        (1, 8, [[0] * 8], [(2, 2, (0, 0)), (1, 1, (0,))]),
        (3, 3, [[2] * 3 for _ in range(3)], [(10000, 4, (1, 1, 1))]),
    ]
    emit("2_edges", edges)

    wide = [
        (8, 8, [[0] * 8 for _ in range(8)], [(1, 1, (0,))]),
        (8, 8, [[0] * 8 for _ in range(8)], [(10000, 1, (0,))]),
        (8, 1, [[0], [0], [0], [0], [0], [0], [0], [0]], [(4, 2, (0, 0))]),
        (8, 8, [[0 if (row + col) % 2 == 0 else 1 for col in range(8)]
                for row in range(8)], [(2, 1, (0,)), (3, 1, (1,))]),
        (8, 8, [[2] * 8 for _ in range(8)], [(10000, 4, (0, 0, 0))]),
        (8, 8, [[2] * 8 for _ in range(7)] + [[0] * 8],
         [(3, 2, (0, 0)), (2, 1, (0,))]),
        (4, 8, [[0] * 8 for _ in range(4)], [(5, 4, (0, 0, 0))]),
    ]
    emit("3_wide", wide)

    rng = random.Random(20261125)
    random_cases = []
    for _ in range(30):
        rows = rng.randint(1, 5)
        cols = rng.randint(1, 5)
        grid = [[rng.choice([0, 0, 1, 2]) for _ in range(cols)]
                for _ in range(rows)]
        tiles = []
        for _ in range(rng.randint(1, 6)):
            form = rng.randint(1, 4)
            tiles.append((rng.randint(1, 10000), form,
                          tuple(rng.randint(0, 1) for _ in range(FORM_LENGTH[form]))))
        random_cases.append((rows, cols, grid, tiles))
    emit("4_random", random_cases)

    io_cases = []
    for idx in range(120000):
        cost = 1 + idx % 10000
        io_cases.append((1, 1, [[idx % 2]], [(cost, 1, (idx % 2,))]))
    emit("5_io", io_cases)


if __name__ == "__main__":
    main()
