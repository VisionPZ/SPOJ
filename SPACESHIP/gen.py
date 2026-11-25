#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    required = tokens[cursor]
    start = tuple(tokens[cursor + 1:cursor + 4])
    cursor += 4
    shop_count = tokens[cursor]
    cursor += 1
    positions = []
    supplies = []
    for _ in range(shop_count):
        positions.append(tuple(tokens[cursor:cursor + 3]))
        supplies.append(tuple(tokens[cursor + 3:cursor + 6]))
        cursor += 6
    nodes = [start] + positions
    node_count = shop_count + 1
    distance = [[0 if first == second else squared(nodes[first], nodes[second])
                 for second in range(node_count)] for first in range(node_count)]
    changed = True
    while changed:
        changed = False
        for first in range(node_count):
            for via in range(node_count):
                for second in range(node_count):
                    through = distance[first][via] + distance[via][second]
                    if through < distance[first][second]:
                        distance[first][second] = through
                        changed = True
    best = None
    for mask in range(1, 1 << shop_count):
        chosen = [index for index in range(shop_count) if mask & (1 << index)]
        totals = [sum(supplies[index][part] for index in chosen)
                  for part in range(3)]
        if any(total < required for total in totals):
            continue
        for order in itertools.permutations(chosen):
            previous = 0
            cost = 0
            for shop in order:
                cost += distance[previous][shop + 1]
                previous = shop + 1
            if best is None or cost < best:
                best = cost
    return str(best) + "\n"


def squared(first, second):
    return sum((first[axis] - second[axis]) ** 2 for axis in range(3))


SAMPLE_ONE = """1
0 0 0
2
10 0 0
2 5 7
0 10 0
0 3 9
"""
SAMPLE_ONE_OUT = """100
"""
SAMPLE_TWO = """5
0 0 0
5
60 34 56
0 5 7
90 41 92
1 7 8
24 61 81
6 8 8
41 86 70
5 6 7
46 97 85
9 2 4
"""
assert oracle(SAMPLE_ONE) == SAMPLE_ONE_OUT
assert oracle(SAMPLE_TWO) == "10542\n"
assert oracle("1\n0 0 0\n1\n1 2 3\n20 20 20\n") == "14\n"
assert oracle("2\n0 0 0\n1\n0 0 0\n2 3 4\n") == "0\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", SAMPLE_TWO)
    wide_lines = ["20", "500 500 500", "7"]
    rng = random.Random(20261126)
    for shop_index in range(7):
        wide_lines.append(f"{rng.randint(0, 500)} {rng.randint(0, 500)} {rng.randint(0, 500)}")
        wide_lines.append(f"{rng.randint(15, 20)} {rng.randint(15, 20)} {rng.randint(15, 20)}")
    write("3_wide", "\n".join(wide_lines) + "\n")
    random_lines = ["5", "250 250 250", "6"]
    for shop_index in range(6):
        random_lines.append(f"{rng.randint(0, 500)} {rng.randint(0, 500)} {rng.randint(0, 500)}")
        random_lines.append(f"{rng.randint(5, 20)} {rng.randint(5, 20)} {rng.randint(5, 20)}")
    write("4_random", "\n".join(random_lines) + "\n")
    io_lines = ["20", "0 0 0", "7"]
    for shop_index in range(7):
        io_lines.append(f"{rng.randint(0, 500)} {rng.randint(0, 500)} {rng.randint(0, 500)}")
        io_lines.append(f"{20 if shop_index in (2, 5) else 0} 20 20")
    write("5_io", "\n".join(io_lines) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_ONE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_ONE_OUT)
build()
