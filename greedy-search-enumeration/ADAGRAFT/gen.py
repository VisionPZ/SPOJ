#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 10 ** 9 + 7
MASTER_RNG = random.Random(20261126)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    tree_size = tokens[0]
    parents = tokens[1:tree_size]
    fruits = tokens[tree_size:2 * tree_size]
    children = [[] for _ in range(tree_size)]
    for child in range(1, tree_size):
        children[parents[child - 1]].append(child)

    def distinct_in_subtree(node):
        kinds = {fruits[node]}
        for child in children[node]:
            kinds.update(distinct_in_subtree(child))
        return kinds

    result = 1
    for node in range(tree_size):
        result = result * len(distinct_in_subtree(node)) % MOD
    return str(result) + "\n"


SAMPLE_A = """5
0 0 1 1
1 1 1 2 2
"""
SAMPLE_B = """4
0 1 2
6 7 2 3
"""
SAMPLE_C = """11
0 1 1 1 3 5 2 7 5 4
494052753 959648710 959648710 959648710 494052753 959648710 959648710 959648710 959648710 494052753 959648710
"""
assert oracle(SAMPLE_A) == "4\n"
assert oracle(SAMPLE_B) == "24\n"
assert oracle(SAMPLE_C) == "32\n"
assert oracle("1\n\n7\n") == "1\n"
assert oracle("3\n0 0\n5 5 5\n") == "1\n"


def write(name, parents, fruits):
    text = f"{len(fruits)}\n" + " ".join(str(value) for value in parents) + "\n" + " ".join(
        str(value) for value in fruits) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", list(range(9)), [3] * 10)
    write("3_wide", [0] * 29, list(range(30)))
    parent_list = [rng.randint(0, index - 1) for index in range(1, 60)]
    write("4_random", parent_list, [rng.randint(0, 8) for _ in range(60)])
    parent_list = list(range(199))
    write("5_io", parent_list, [index % 7 for index in range(200)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_A)
(ROOT / "out" / "1_sample.out").write_text("4\n")
big_lines = ["400000"]
big_lines.append(" ".join(str(index - 1) for index in range(1, 400000)))
big_lines.append(" ".join(str(MASTER_RNG.randint(0, 10 ** 9)) for _ in range(400000)))
Path("/tmp/ADAGRAFT_big.txt").write_text("\n".join(big_lines) + "\n")
build()
