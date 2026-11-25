import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = (
    "6 5 8\n"
    "1 2 3 4 5\n"
    "1 2 3 4 5\n"
    "6 6 6 6 6\n"
    "5 4 3 2 1\n"
    "5 4 3 2 1\n"
    "6 6 6 6 6\n"
    "2 1 1 6 5\n"
    "2 1 1 2 4\n"
    "2 4 2 5 4\n"
    "1 5 4 4\n"
    "1 1 1 665\n"
    "2 1 1 6 5\n"
    "2 1 1 2 4\n"
    "2 4 2 5 4\n"
)
SAMPLE_OUTPUT = "120\n20\n18\n789\n685\n22\n"

BLOCK = 32


def parse(text):
    tokens = text.split()
    cursor = 0
    rows = int(tokens[cursor]); cols = int(tokens[cursor + 1]); q = int(tokens[cursor + 2])
    cursor += 3
    grid = [[0] * (cols + 1) for _ in range(rows + 1)]
    for i in range(1, rows + 1):
        for j in range(1, cols + 1):
            grid[i][j] = int(tokens[cursor]); cursor += 1
    queries = []
    for _ in range(q):
        kind = int(tokens[cursor]); cursor += 1
        if kind == 1:
            queries.append((1, int(tokens[cursor]), int(tokens[cursor + 1]),
                            int(tokens[cursor + 2])))
            cursor += 3
        else:
            queries.append((2, int(tokens[cursor]), int(tokens[cursor + 1]),
                            int(tokens[cursor + 2]), int(tokens[cursor + 3])))
            cursor += 4
    return rows, cols, queries, grid


def oracle(text):
    rows, cols, queries, grid = parse(text)
    row_prefix = [[0] * (cols + 1) for _ in range(rows + 1)]
    for i in range(1, rows + 1):
        running = 0
        for j in range(1, cols + 1):
            running += grid[i][j]
            row_prefix[i][j] = running
    blocks = (rows + BLOCK - 1) // BLOCK
    block_cum = [[0] * (cols + 1) for _ in range(blocks)]
    for b in range(blocks):
        first = b * BLOCK + 1
        last = min(rows, (b + 1) * BLOCK)
        for c in range(1, cols + 1):
            block_cum[b][c] = sum(grid[i][c] for i in range(first, last + 1))
        for c in range(2, cols + 1):
            block_cum[b][c] += block_cum[b][c - 1]

    answers = []
    for query in queries:
        if query[0] == 1:
            _, x, y, delta = query
            grid[x][y] += delta
            for c in range(y, cols + 1):
                row_prefix[x][c] += delta
            b = (x - 1) // BLOCK
            for c in range(y, cols + 1):
                block_cum[b][c] += delta
        else:
            _, r1, c1, r2, c2 = query
            total = 0
            i = r1
            while i <= r2:
                b = (i - 1) // BLOCK
                bstart = b * BLOCK + 1
                bend = min(rows, (b + 1) * BLOCK)
                if i == bstart and bend <= r2:
                    total += block_cum[b][c2] - block_cum[b][c1 - 1]
                    i = bend + 1
                else:
                    total += row_prefix[i][c2] - row_prefix[i][c1 - 1]
                    i += 1
            answers.append(str(total))
    return "\n".join(answers) + "\n"


def brute(text):
    rows, cols, queries, values = parse(text)
    answers = []
    for query in queries:
        if query[0] == 1:
            _, x, y, delta = query
            values[x][y] += delta
        else:
            _, r1, c1, r2, c2 = query
            total = 0
            for i in range(r1, r2 + 1):
                for j in range(c1, c2 + 1):
                    total += values[i][j]
            answers.append(str(total))
    return "\n".join(answers) + "\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1 1 2\n7\n2 1 1 1 1\n2 1 1 1 1\n") == "7\n7\n"
assert oracle("1 3 2\n1 2 3\n1 1 1 5\n2 1 1 1 3\n") == "11\n"
assert oracle("2 1 1\n4\n5\n2 1 1 2 1\n") == "9\n"
assert oracle("1 1 2\n2\n1 1 1 8\n2 1 1 1 1\n") == "10\n"
assert brute(SAMPLE_INPUT) == SAMPLE_OUTPUT


def write(name, rows, cols, grid_rows, queries, check=True):
    pieces = ["{} {} {}".format(rows, cols, len(queries))]
    pieces.extend(" ".join(str(value) for value in row) for row in grid_rows)
    for query in queries:
        pieces.append(" ".join(str(value) for value in query))
    input_text = "\n".join(pieces) + "\n"
    (ROOT / "in" / (name + ".txt")).write_text(input_text)
    result = oracle(input_text)
    (ROOT / "out" / (name + ".out")).write_text(result)
    if check:
        assert brute(input_text) == result


def random_case(rows, cols, q, seed):
    rng = random.Random(seed)
    grid = [[rng.randint(1, 10000) for _ in range(cols)] for _ in range(rows)]
    queries = []
    for _ in range(q):
        if rng.random() < 0.3:
            queries.append((1, rng.randint(1, rows), rng.randint(1, cols),
                            rng.randint(1, 10000)))
        else:
            r1 = rng.randint(1, rows); r2 = rng.randint(r1, rows)
            c1 = rng.randint(1, cols); c2 = rng.randint(c1, cols)
            queries.append((2, r1, c1, r2, c2))
    return grid, queries


def build():
    grid, queries = random_case(6, 5, 60, 1)
    write("2_edges", 6, 5, grid, queries)
    grid = [[1] * 1 for _ in range(40)]
    queries = [(2, 1, 1, 40, 1), (1, 40, 1, 5), (2, 1, 1, 40, 1)]
    write("3_wide", 40, 1, grid, queries)
    grid, queries = random_case(40, 40, 800, 2026)
    write("4_random", 40, 40, grid, queries)
    grid, queries = random_case(120, 120, 3000, 7)
    write("5_io", 120, 120, grid, queries, check=False)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
sample_grid = [
    [1, 2, 3, 4, 5], [1, 2, 3, 4, 5], [6, 6, 6, 6, 6],
    [5, 4, 3, 2, 1], [5, 4, 3, 2, 1], [6, 6, 6, 6, 6],
]
sample_queries = [
    (2, 1, 1, 6, 5), (2, 1, 1, 2, 4), (2, 4, 2, 5, 4),
    (1, 5, 4, 4), (1, 1, 1, 665), (2, 1, 1, 6, 5),
    (2, 1, 1, 2, 4), (2, 4, 2, 5, 4),
]
write("1_sample", 6, 5, sample_grid, sample_queries)
build()
