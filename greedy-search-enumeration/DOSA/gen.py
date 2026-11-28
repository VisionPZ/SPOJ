#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    prices = tokens[1:1 + count]
    adjusted = [prices[index] - index - 1 for index in range(count)]
    usable = [value for value in adjusted if value >= 0]
    if not usable:
        return str(count) + "\n"
    ranks = {value: index + 1 for index, value in enumerate(sorted(set(usable)))}
    tree = [0] * (len(ranks) + 2)

    def query(rank):
        best = 0
        while rank:
            if tree[rank] > best:
                best = tree[rank]
            rank -= rank & -rank
        return best

    def update(rank, value):
        while rank < len(tree):
            if value > tree[rank]:
                tree[rank] = value
            rank += rank & -rank

    longest = 0
    for value in usable:
        rank = ranks[value]
        current = query(rank) + 1
        if current > longest:
            longest = current
        update(rank, current)
    return str(count - longest) + "\n"


def brute(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    prices = tokens[1:1 + count]
    adjusted = [prices[index] - index - 1 for index in range(count)]
    usable = [value for value in adjusted if value >= 0]
    lengths = [1] * len(usable)
    for index in range(len(usable)):
        for earlier in range(index):
            if usable[earlier] <= usable[index] and lengths[earlier] + 1 > lengths[index]:
                lengths[index] = lengths[earlier] + 1
    return str(count - (max(lengths) if lengths else 0)) + "\n"


SAMPLE = "6\n1 7 10 2 20 22\n"
SAMPLE_OUT = "1\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("5\n1 2 2 3 4\n") == "3\n"
assert brute(SAMPLE) == SAMPLE_OUT
assert oracle("1\n7\n") == "0\n"
assert oracle("3\n5 5 5\n") == "2\n"
assert oracle("4\n1 3 5 7\n") == "0\n"
assert oracle("4\n7 5 3 1\n") == "3\n"


def write(name, count, prices):
    text = str(count) + "\n" + " ".join(str(value) for value in prices) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, [7])
    write("2_edges_b", 5, [1, 2, 2, 3, 4])
    write("3_wide", 20000, [1000000000 - index for index in range(20000)])
    rng = random.Random(20261126)
    write("4_random", 10000, [rng.randint(1, 1000000000) for _ in range(10000)])
    write("5_io", 1000000, [rng.randint(1, 1000000000) for _ in range(1000000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 6, [1, 7, 10, 2, 20, 22])
build()
