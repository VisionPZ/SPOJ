#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    lines = text.splitlines()
    queries = [line.split() for line in lines[1:] if line.strip()]
    limit = 0
    for parts in queries:
        for value in parts[1:]:
            limit = max(limit, int(value))
    columns = [0] * (limit + 1)
    rows = [0] * (limit + 1)
    answers = []
    for parts in queries:
        kind = parts[0]
        if kind == "x":
            lower, upper = int(parts[1]), int(parts[2])
            for coordinate in range(lower, upper + 1):
                columns[coordinate] ^= 1
        elif kind == "y":
            lower, upper = int(parts[1]), int(parts[2])
            for coordinate in range(lower, upper + 1):
                rows[coordinate] ^= 1
        else:
            x_lower, y_lower, x_upper, y_upper = map(int, parts[1:5])
            columns_on = sum(columns[x_lower:x_upper + 1])
            rows_on = sum(rows[y_lower:y_upper + 1])
            columns_off = x_upper - x_lower + 1 - columns_on
            rows_off = y_upper - y_lower + 1 - rows_on
            answers.append(str(columns_on * rows_off + columns_off * rows_on))
    return "\n".join(answers) + "\n"


def brute_grid(queries, size):
    grid = [[0] * (size + 1) for _ in range(size + 1)]
    answers = []
    for parts in queries:
        kind = parts[0]
        if kind == "x":
            lower, upper = int(parts[1]), int(parts[2])
            for column in range(lower, upper + 1):
                for row in range(size + 1):
                    grid[column][row] ^= 1
        elif kind == "y":
            lower, upper = int(parts[1]), int(parts[2])
            for row in range(lower, upper + 1):
                for column in range(size + 1):
                    grid[column][row] ^= 1
        else:
            x_lower, y_lower, x_upper, y_upper = map(int, parts[1:5])
            answers.append(str(sum(grid[column][row]
                                   for column in range(x_lower, x_upper + 1)
                                   for row in range(y_lower, y_upper + 1))))
    return answers


SAMPLE = """3
x 0 1
y 1 2
q 0 0 2 2
"""
SAMPLE_OUT = """4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\nq 0 0 0 0\n") == "0\n"
assert oracle("3\nx 0 0\nx 0 0\nq 0 0 0 0\n") == "0\n"
assert oracle("3\nx 0 0\ny 0 0\nq 0 0 0 0\n") == "0\n"
assert oracle("2\nx 0 0\nq 0 0 0 0\n") == "1\n"
rng = random.Random(20261126)
for _ in range(40):
    queries = []
    for _ in range(20):
        kind = rng.choice(("x", "y", "q"))
        lower = rng.randint(0, 5)
        upper = rng.randint(lower, 5)
        if kind == "q":
            y_lower = rng.randint(0, 5)
            queries.append([kind, str(lower), str(y_lower),
                            str(upper), str(rng.randint(y_lower, 5))])
        else:
            queries.append([kind, str(lower), str(upper)])
    text = str(len(queries)) + "\n" + "".join(" ".join(parts) + "\n" for parts in queries)
    assert oracle(text).splitlines() == brute_grid(queries, 5)


def write(name, queries):
    text = str(len(queries)) + "\n" + "".join(" ".join(parts) + "\n" for parts in queries)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_queries(count, ceiling):
    result = []
    for _ in range(count):
        kind = rng.choice(("x", "y", "q", "q"))
        lower = rng.randint(0, ceiling)
        upper = rng.randint(lower, ceiling)
        if kind == "q":
            y_lower = rng.randint(0, ceiling)
            y_upper = rng.randint(y_lower, ceiling)
            result.append([kind, str(lower), str(y_lower), str(upper), str(y_upper)])
        else:
            result.append([kind, str(lower), str(upper)])
    return result


def build():
    write("2_edges", [["x", "0", "0"], ["y", "0", "0"], ["q", "0", "0", "0", "0"],
                      ["x", "0", "100000"], ["q", "0", "0", "100000", "100000"],
                      ["x", "0", "100000"], ["q", "0", "0", "100000", "100000"]])
    write("3_wide", random_queries(60, 100000))
    write("4_random", random_queries(500, 60))
    write("5_io", random_queries(100000, 200))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [["x", "0", "1"], ["y", "1", "2"], ["q", "0", "0", "2", "2"]])
build()
