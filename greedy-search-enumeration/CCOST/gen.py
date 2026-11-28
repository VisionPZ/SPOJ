#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        tree_count = tokens[cursor]
        cursor += 1
        trees = []
        for _ in range(tree_count):
            trees.append((tokens[cursor], tokens[cursor + 1], tokens[cursor + 2]))
            cursor += 3
        query_count = tokens[cursor]
        cursor += 1
        for _ in range(query_count):
            lower_x, lower_y, upper_x, upper_y = tokens[cursor:cursor + 4]
            cursor += 4
            total = sum(value for tree_x, tree_y, value in trees
                        if lower_x <= tree_x <= upper_x and lower_y <= tree_y <= upper_y)
            answers.append(str(total))
    return "\n".join(answers) + "\n"


SAMPLE = """1
3
1 1 2
2 2 3
3 3 4
2
1 1 1 2
0 0 5 5
"""
SAMPLE_OUT = """2
9
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n5 5 7\n1\n0 0 5 5\n") == "7\n"
assert oracle("1\n1\n5 5 7\n1\n0 0 4 3\n") == "0\n"
assert oracle("1\n2\n1 1 3\n1 1 4\n1\n1 1 1 1\n") == "7\n"
assert oracle("2\n1\n2 3 5\n1\n0 0 9 9\n1\n7 8 6\n1\n0 0 9 9\n") == "5\n6\n"


def encode(cases):
    blocks = [str(len(cases))]
    for trees, queries in cases:
        blocks.append(str(len(trees)))
        for tree_x, tree_y, value in trees:
            blocks.append(f"{tree_x} {tree_y} {value}")
        blocks.append(str(len(queries)))
        for query in queries:
            blocks.append(" ".join(str(value) for value in query))
    return "\n".join(blocks) + "\n"


def write(name, cases):
    input_text = encode(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    edge_trees = [(0, 0, 1), (0, 10000000, 2), (10000000, 0, 3),
                  (10000000, 10000000, 4), (5, 5, 10000), (5, 5, 1)]
    edge_queries = [(0, 0, 0, 0), (10000000, 10000000, 10000000, 10000000),
                    (5, 5, 5, 5), (0, 0, 10000000, 10000000),
                    (1, 1, 4, 4), (0, 10000000, 10000000, 10000000)]
    write("2_edges", [(edge_trees, edge_queries)])
    rng = random.Random(20261126)
    wide_trees = [(rng.randint(0, 10000000), rng.randint(0, 10000000),
                   rng.randint(0, 10000)) for _ in range(200)]
    wide_queries = []
    for _ in range(80):
        first_x, second_x = sorted(rng.sample(range(0, 10000001), 2))
        first_y, second_y = sorted(rng.sample(range(0, 10000001), 2))
        wide_queries.append((first_x, first_y, second_x, second_y))
    write("3_wide", [(wide_trees, wide_queries)])
    random_trees = [(rng.randint(0, 500), rng.randint(0, 500), rng.randint(0, 10000))
                    for _ in range(300)]
    random_queries = []
    for _ in range(100):
        first_x, second_x = sorted(rng.sample(range(0, 501), 2))
        first_y, second_y = sorted(rng.sample(range(0, 501), 2))
        random_queries.append((first_x, first_y, second_x, second_y))
    write("4_random", [(random_trees, random_queries)])
    io_trees = [(rng.randint(0, 700), rng.randint(0, 700), rng.randint(1, 10000))
                for _ in range(400)]
    io_queries = []
    for _ in range(3000):
        first_x, second_x = sorted(rng.sample(range(0, 701), 2))
        first_y, second_y = sorted(rng.sample(range(0, 701), 2))
        io_queries.append((first_x, first_y, second_x, second_y))
    write("5_io", [(io_trees, io_queries)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [([(1, 1, 2), (2, 2, 3), (3, 3, 4)],
                    [(1, 1, 1, 2), (0, 0, 5, 5)])])
build()
