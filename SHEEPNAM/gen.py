#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10 ** 19


def oracle(text):
    tokens = [int(value) for value in text.split()]
    nodes = tokens[0]
    start = tokens[1]
    finish = tokens[2]
    cursor = 3
    matrix = [[INF] * (nodes + 1) for _ in range(nodes + 1)]
    for index in range(1, nodes + 1):
        matrix[index][index] = 0
    for _ in range(nodes - 1):
        first = tokens[cursor]
        second = tokens[cursor + 1]
        length = tokens[cursor + 2]
        cursor += 3
        matrix[first][second] = length
        matrix[second][first] = length
    for middle in range(1, nodes + 1):
        for first in range(1, nodes + 1):
            for second in range(1, nodes + 1):
                candidate = matrix[first][middle] + matrix[middle][second]
                if candidate < matrix[first][second]:
                    matrix[first][second] = candidate
    return str(matrix[start][finish]) + "\n"


SAMPLE = """6 2 6
1 2 2
2 3 1
2 4 5
4 6 2
4 5 4
"""
SAMPLE_OUT = """7
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1 1\n") == "0\n"
assert oracle("2 1 2\n1 2 1000000000\n") == "1000000000\n"
assert oracle("4 1 4\n1 2 3\n2 3 4\n3 4 5\n") == "12\n"


def write(name, nodes, start, finish, edges):
    lines = [f"{nodes} {start} {finish}"]
    lines.extend(f"{first} {second} {length}" for first, second, length in edges)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, 1, 1, [])
    write("3_wide", 25, 1, 25,
          [(index, index + 1, 1000000000) for index in range(1, 25)])
    rng = random.Random(20261126)
    edges = [(rng.randint(1, index - 1), index, rng.randint(1, 1000000000))
             for index in range(2, 16)]
    write("4_random", 15, 3, 14, edges)
    edges = [(index, index + 1, 1000000000) for index in range(1, 30)]
    write("5_io", 30, 1, 30, edges)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 6, 2, 6, [(1, 2, 2), (2, 3, 1), (2, 4, 5), (4, 6, 2), (4, 5, 4)])
build()
