#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def parse_cases(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    cases = []
    for _ in range(case_count):
        extents = tuple(tokens[cursor:cursor + 4])
        cursor += 4
        queries = []
        for _ in range(extents[3]):
            kind = tokens[cursor]
            cursor += 1
            if kind <= 2:
                queries.append((kind, tokens[cursor], tokens[cursor + 1]))
                cursor += 2
            else:
                queries.append((kind, tuple(tokens[cursor:cursor + 6])))
                cursor += 6
        cases.append((extents, queries))
    return cases


def oracle(text):
    outputs = []
    for extents, queries in parse_cases(text):
        x_size, y_size, z_size, _ = extents
        axis_parity = [[0] * x_size, [0] * y_size, [0] * z_size]
        for query in queries:
            if query[0] <= 2:
                axis = axis_parity[query[0]]
                for coordinate in range(query[1], query[2] + 1):
                    axis[coordinate] ^= 1
                continue
            x_low, y_low, z_low, x_high, y_high, z_high = query[1]
            x_ones = sum(axis_parity[0][x_low:x_high + 1])
            y_ones = sum(axis_parity[1][y_low:y_high + 1])
            z_ones = sum(axis_parity[2][z_low:z_high + 1])
            span_x = x_high - x_low + 1
            span_y = y_high - y_low + 1
            span_z = z_high - z_low + 1
            total = span_x * span_y * span_z
            signed = (span_x - 2 * x_ones) * (span_y - 2 * y_ones) * (span_z - 2 * z_ones)
            outputs.append(str((total - signed) // 2))
    return "\n".join(outputs) + "\n"


def brute(text):
    outputs = []
    for extents, queries in parse_cases(text):
        x_size, y_size, z_size, _ = extents
        grid = [[[0] * z_size for _ in range(y_size)] for _ in range(x_size)]
        for query in queries:
            if query[0] == 0:
                for x in range(query[1], query[2] + 1):
                    for y in range(y_size):
                        for z in range(z_size):
                            grid[x][y][z] ^= 1
            elif query[0] == 1:
                for y in range(query[1], query[2] + 1):
                    for x in range(x_size):
                        for z in range(z_size):
                            grid[x][y][z] ^= 1
            elif query[0] == 2:
                for z in range(query[1], query[2] + 1):
                    for x in range(x_size):
                        for y in range(y_size):
                            grid[x][y][z] ^= 1
            else:
                x_low, y_low, z_low, x_high, y_high, z_high = query[1]
                count = 0
                for x in range(x_low, x_high + 1):
                    for y in range(y_low, y_high + 1):
                        for z in range(z_low, z_high + 1):
                            count += grid[x][y][z]
                outputs.append(str(count))
    return "\n".join(outputs) + "\n"


SAMPLE = """1
3 4 5 5
0 1 2
1 2 3
3 0 0 0 1 2 3
2 3 4
3 1 1 1 2 2 2
"""
SAMPLE_OUT = """12
4
"""
SMALL = """1
2 3 4 8
0 0 1
1 1 2
2 2 3
3 0 0 0 1 2 3
0 1 1
3 1 0 1 1 2 3
2 0 0
3 0 0 0 0 0 0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle(SMALL) == brute(SMALL)
assert oracle("1\n1 1 1 3\n0 0 0\n3 0 0 0 0 0 0\n1 0 0\n") == "1\n"


def write(name, cases):
    lines = [str(len(cases))]
    for extents, queries in cases:
        lines.append(" ".join(str(value) for value in extents))
        for query in queries:
            if query[0] <= 2:
                lines.append(f"{query[0]} {query[1]} {query[2]}")
            else:
                coordinates = query[1]
                lines.append(str(query[0]) + " " +
                             " ".join(str(value) for value in coordinates))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def make_queries(rng, extents, count):
    x_size, y_size, z_size = extents
    queries = []
    for _ in range(count):
        kind = rng.randint(0, 3)
        if kind <= 2:
            size = (x_size, y_size, z_size)[kind]
            first = rng.randrange(size)
            last = min(size - 1, first + rng.randint(0, size - 1))
            queries.append((kind, first, last))
        else:
            x_low = rng.randrange(x_size)
            y_low = rng.randrange(y_size)
            z_low = rng.randrange(z_size)
            x_high = min(x_size - 1, x_low + rng.randint(0, 3))
            y_high = min(y_size - 1, y_low + rng.randint(0, 3))
            z_high = min(z_size - 1, z_low + rng.randint(0, 3))
            queries.append((3, (x_low, y_low, z_low, x_high, y_high, z_high)))
    return queries


def build():
    rng = random.Random(20261126)
    write("2_edges", [((1, 1, 1, 4), make_queries(rng, (1, 1, 1), 4)),
                      ((1, 2, 3, 6), make_queries(rng, (1, 2, 3), 6))])
    write("3_wide", [((100000, 100000, 100000, 30),
                      make_queries(rng, (100000, 100000, 100000), 30))])
    random_cases = []
    for _ in range(5):
        extents = (rng.randint(1, 20), rng.randint(1, 20), rng.randint(1, 20), 100)
        random_cases.append((extents, make_queries(rng, extents[:3], 100)))
    write("4_random", random_cases)
    report_queries = []
    for index in range(5000):
        if index % 50 == 0:
            first = rng.randrange(1000)
            last = min(999, first + rng.randint(0, 999))
            report_queries.append((0, first, last))
        else:
            report_queries.append((3, (0, 0, 0, 999, 999, 999)))
    write("5_io", [((1000, 1000, 1000, 5000), report_queries)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
