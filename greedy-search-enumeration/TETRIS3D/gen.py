#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SAMPLE = """7 5 4
4 3 2 0 0
3 3 1 3 0
7 1 2 0 3
2 3 3 2 2
"""
SAMPLE_OUT = "6\n"


def oracle(text):
    tokens = iter(int(value) for value in text.split())
    length = next(tokens)
    depth = next(tokens)
    count = next(tokens)
    heights = [[0] * depth for _ in range(length)]
    for _ in range(count):
        block_length = next(tokens)
        block_depth = next(tokens)
        weight = next(tokens)
        start_x = next(tokens)
        start_y = next(tokens)
        support = 0
        for row in range(start_x, start_x + block_length):
            for column in range(start_y, start_y + block_depth):
                if heights[row][column] > support:
                    support = heights[row][column]
        landing = support + weight
        for row in range(start_x, start_x + block_length):
            for column in range(start_y, start_y + block_depth):
                heights[row][column] = landing
    return str(max(max(row) for row in heights)) + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1 1\n1 1 7 0 0\n") == "7\n"
assert oracle("2 1 2\n1 1 3 0 0\n1 1 4 1 0\n") == "4\n"
assert oracle("3 1 3\n1 1 5 0 0\n1 1 5 0 0\n1 1 5 1 0\n") == "10\n"
assert 1 << 10 == 1024


def build_input(length, depth, blocks):
    lines = [f"{length} {depth} {len(blocks)}"]
    lines.extend(f"{d} {s} {w} {x} {y}" for d, s, w, x, y in blocks)
    return "\n".join(lines) + "\n"


def write(name, length, depth, blocks):
    text = build_input(length, depth, blocks)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 3, 3, [(1, 1, 7, 0, 0), (3, 1, 2, 0, 0),
                            (1, 3, 4, 2, 0), (1, 1, 1, 0, 0)])
    write("3_wide", 1000, 1000, [(1, 1, 100000, 999, 999),
                                 (1, 1, 99999, 0, 0),
                                 (1, 1, 1, 500, 500)] * 5)
    rng = random.Random(20261126)
    blocks = []
    for _ in range(120):
        d = rng.randint(1, 20)
        s = rng.randint(1, 20)
        x = rng.randint(0, 60 - d)
        y = rng.randint(0, 60 - s)
        blocks.append((d, s, rng.randint(1, 100000), x, y))
    write("4_random", 60, 60, blocks)
    stress = [(1, 1, rng.randint(1, 100000), rng.randint(0, 999), rng.randint(0, 999))
              for _ in range(20000)]
    write("5_io", 1000, 1000, stress)
    with open("/tmp/TETRIS3D_big.txt", "w") as handle:
        handle.write(build_input(1000, 1000,
                                 [(1, 1000, rng.randint(1, 100000), rng.randint(0, 999), 0)
                                  for _ in range(20000)]))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 7, 5, [(4, 3, 2, 0, 0), (3, 3, 1, 3, 0),
                         (7, 1, 2, 0, 3), (2, 3, 3, 2, 2)])
build()
