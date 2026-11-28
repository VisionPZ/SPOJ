#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    lines = text.split('\n')
    node_count, flavor_count, query_count = map(int, lines[0].split())
    parents = [0] + [int(value) for value in lines[1].split()]
    flavors = [int(value) for value in lines[2].split()]
    depths = [0] * node_count
    for node in range(1, node_count):
        depths[node] = depths[parents[node]] + 1

    def nodes_on_path(first, second):
        path = []
        left, right = first, second
        while depths[left] > depths[right]:
            path.append(left)
            left = parents[left]
        while depths[right] > depths[left]:
            path.append(right)
            right = parents[right]
        while left != right:
            path.append(left)
            path.append(right)
            left = parents[left]
            right = parents[right]
        path.append(left)
        return path

    answers = []
    for line in lines[3:3 + query_count]:
        values = list(map(int, line.split()))
        if not values:
            continue
        selected = set()
        for pair in ((values[0], values[1]), (values[2], values[3]), (values[4], values[5])):
            selected.update(nodes_on_path(pair[0], pair[1]))
        answers.append(str(len({flavors[node] for node in selected})))
    return '\n'.join(answers) + '\n' if answers else ''


SAMPLE = """5 2 5
0 0 0 2
1 1 1 1 2
3 2 3 1 1 4
1 0 2 4 2 3
2 1 4 3 1 0
1 3 3 0 3 1
4 2 0 3 4 1
"""
SAMPLE_OUT = """2
2
2
1
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
SAMPLE_TWO = """7 3 7
0 0 0 1 2 3
1 3 2 2 2 1 1
3 2 3 6 3 5
0 2 6 0 4 2
3 6 3 0 2 0
2 0 4 0 2 0
1 5 5 3 2 6
1 2 0 5 0 6
0 4 5 3 2 0
"""
assert oracle(SAMPLE_TWO) == "2\n3\n2\n3\n3\n3\n3\n"
assert oracle("2 1 2\n0\n1 1\n0 1 1 0 1 1\n0 0 0 0 0 0\n") == "1\n1\n"


def make_tree(rng, node_count, shape):
    if shape == 'path':
        return [node - 1 for node in range(1, node_count)]
    if shape == 'star':
        return [0] * (node_count - 1)
    return [rng.randrange(node) for node in range(1, node_count)]


def write(name, node_count, flavor_count, parents, flavors, queries):
    lines = [f"{node_count} {flavor_count} {len(queries)}",
             " ".join(map(str, parents)),
             " ".join(map(str, flavors))]
    lines += [" ".join(map(str, query)) for query in queries]
    text = '\n'.join(lines) + '\n'
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    parents = make_tree(rng, 30, 'path')
    edge_queries = [(0, 29, 29, 0, 14, 14), (7, 7, 7, 7, 7, 7)]
    write("2_edges", 30, 3, parents,
          [flavor % 3 + 1 for flavor in range(30)], edge_queries)

    wide_parents = make_tree(rng, 2000, 'random')
    wide_flavors = [rng.randint(1, 1000) for _ in range(2000)]
    wide_queries = [tuple(rng.randrange(2000) for _ in range(6)) for _ in range(2000)]
    write("3_wide", 2000, 1000, wide_parents, wide_flavors, wide_queries)

    mid_parents = make_tree(rng, 300, 'random')
    mid_flavors = [rng.randint(1, 50) for _ in range(300)]
    mid_queries = [tuple(rng.randrange(300) for _ in range(6)) for _ in range(2000)]
    write("4_random", 300, 50, mid_parents, mid_flavors, mid_queries)

    io_parents = make_tree(rng, 2000, 'random')
    io_flavors = [rng.randint(1, 1000) for _ in range(2000)]
    io_queries = [tuple(rng.randrange(2000) for _ in range(6)) for _ in range(10000)]
    write("5_io", 2000, 1000, io_parents, io_flavors, io_queries)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
