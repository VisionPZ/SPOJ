#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def walk_from_permutation(perm):
    count = len(perm)
    walk = [0] * count
    pieces = [(value, index) for index, value in enumerate(perm)]

    def split(part):
        if len(part) <= 1:
            return part
        middle = len(part) // 2
        left = split(part[:middle])
        right = split(part[middle:])
        merged = []
        li = ri = 0
        while li < len(left) and ri < len(right):
            if left[li][0] <= right[ri][0]:
                merged.append(left[li])
                li += 1
            else:
                walk[right[ri][1]] += len(left) - li
                merged.append(right[ri])
                ri += 1
        merged.extend(left[li:])
        merged.extend(right[ri:])
        return merged

    split(pieces)
    return walk


def brute_walk(perm):
    return [sum(1 for j in range(i) if perm[j] > perm[i])
            for i in range(len(perm))]


def matches(perm, walk):
    return walk_from_permutation(perm) == walk


def worked_example():
    walk = [0, 1, 2, 0, 1]
    remaining = list(range(1, len(walk) + 1))
    rows = []
    for i in range(len(walk) - 1, -1, -1):
        rank_index = i + 1 - walk[i]
        rank = remaining.pop(rank_index - 1)
        rows.append((i + 1, walk[i], rank_index, rank, list(remaining)))
    return rows


TRACE = worked_example()
assert [row[3] for row in TRACE][::-1] == [3, 2, 1, 5, 4]


def format_input(cases):
    lines = [str(len(cases))]
    for walk in cases:
        lines.append(str(len(walk)))
        lines.append(" ".join(str(value) for value in walk))
    return "\n".join(lines) + "\n"


def format_output(cases, perms):
    return "\n".join(" ".join(str(value) for value in perm)
                     for perm in perms) + "\n"


def write(name, perms):
    cases = [walk_from_permutation(perm) for perm in perms]
    (ROOT / "in" / (name + ".txt")).write_text(format_input(cases))
    (ROOT / "out" / (name + ".out")).write_text(format_output(cases, perms))


def ascending(count):
    return list(range(1, count + 1))


def descending(count):
    return list(range(count, 0, -1))


SAMPLE_PERMS = [[2, 1, 3], [3, 2, 1, 5, 4]]

assert walk_from_permutation(SAMPLE_PERMS[0]) == [0, 1, 0]
assert walk_from_permutation(SAMPLE_PERMS[1]) == [0, 1, 2, 0, 1]
assert walk_from_permutation(ascending(200000)) == [0] * 200000
assert walk_from_permutation(descending(200000)) == list(range(200000))

random.seed(17)
for _ in range(40):
    small = list(range(1, random.randint(2, 7) + 1))
    random.shuffle(small)
    assert walk_from_permutation(small) == brute_walk(small)
    walk = walk_from_permutation(small)
    all_perms = [list(order) for order in itertools.permutations(small)]
    winners = [order for order in all_perms if matches(order, walk)]
    assert winners == [small]


def build():
    edges = [
        [1],
        ascending(2),
        descending(2),
        [2, 1, 3],
        descending(9),
        ascending(7),
        [4, 3, 2, 1, 5],
        [5, 1, 4, 2, 3],
    ]
    write("2_edges", edges)

    write("3_wide", [ascending(200000), descending(200000)])

    rng = random.Random(20261124)
    sizes = [1, 2, 3, 17, 64, 500, 5000, 50000]
    random_perms = []
    for size in sizes:
        perm = list(range(1, size + 1))
        rng.shuffle(perm)
        random_perms.append(perm)
    write("4_random", random_perms)

    io_perms = []
    for _ in range(10):
        perm = list(range(1, 200001))
        rng.shuffle(perm)
        io_perms.append(perm)
    write("5_io", io_perms)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(
    "2\n3\n0 1 0\n5\n0 1 2 0 1\n")
(ROOT / "out" / "1_sample.out").write_text("2 1 3\n3 2 1 5 4\n")
build()
