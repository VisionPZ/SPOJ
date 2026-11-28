#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_values(values):
    magnitudes = sorted(set(abs(value) for value in values))
    rank_of = {magnitude: index + 1 for index, magnitude in enumerate(magnitudes)}
    size = len(magnitudes)
    positive_tree = [0] * (size + 1)
    negative_tree = [0] * (size + 1)

    def update(tree, index, length):
        while index <= size:
            if length > tree[index]:
                tree[index] = length
            index += index & -index

    def query(tree, index):
        result = 0
        while index > 0:
            if tree[index] > result:
                result = tree[index]
            index -= index & -index
        return result

    answer = 0
    for value in values:
        rank = rank_of[abs(value)]
        if value > 0:
            length = query(negative_tree, rank - 1) + 1
            update(positive_tree, rank, length)
        else:
            length = query(positive_tree, rank - 1) + 1
            update(negative_tree, rank, length)
        if length > answer:
            answer = length
    return answer


def oracle(text):
    tokens = [int(value) for value in text.split()]
    values = tokens[1:1 + tokens[0]]
    return str(oracle_values(values)) + "\n"


SAMPLE = """8
1 2 -2 -3 5 -7 -8 10
"""
SAMPLE_OUT = """5
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n5\n") == "1\n"
assert oracle("4\n1 -2 3 -4\n") == "4\n"
assert oracle("4\n-1 2 -3 4\n") == "4\n"
assert oracle("10\n1 2 -9 -10 4 5 -3 -4 5 6\n") == "3\n"
assert oracle("7\n3 -4 5 -6 7 -1 9\n") == "5\n"


def write(name, values):
    text = f"{len(values)}\n" + " ".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [5, -5, 5, -5, 1000000000, -1000000000])
    write("3_wide", [((-1) ** index) * (index + 1) * 1000000 for index in range(5000)])
    rng = random.Random(20261126)
    write("4_random", [rng.choice([-1, 1]) * rng.randint(1, 1000000000) for _ in range(5000)])
    write("5_io", [((-1) ** index) * (index + 1) for index in range(5000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 2, -2, -3, 5, -7, -8, 10])
build()
