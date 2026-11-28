#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def cartesian_parents(nodes):
    parents = {}
    stack = []
    for key, weight in nodes:
        displaced = None
        while stack and stack[-1][1] < weight:
            displaced = stack.pop()
        if stack:
            parents[key] = stack[-1][0]
        if displaced is not None:
            parents[displaced[0]] = key
        stack.append((key, weight))
    return parents


def depth_to_root(key, parents):
    depth = 0
    while key in parents:
        key = parents[key]
        depth += 1
    return depth


def distance(first_key, second_key, parents):
    first_depth = depth_to_root(first_key, parents)
    second_depth = depth_to_root(second_key, parents)
    first_key_alias = first_key
    second_key_alias = second_key
    while first_depth > second_depth:
        first_key_alias = parents[first_key_alias]
        first_depth -= 1
    while second_depth > first_depth:
        second_key_alias = parents[second_key_alias]
        second_depth -= 1
    while first_key_alias != second_key_alias:
        first_key_alias = parents[first_key_alias]
        second_key_alias = parents[second_key_alias]
    return depth_to_root(first_key, parents) + depth_to_root(second_key, parents) - 2 * first_depth


def oracle(text):
    tokens = [int(value) for value in text.split()]
    operation_total = tokens[0]
    live = {}
    lines = []
    cursor = 1
    for _ in range(operation_total):
        code = tokens[cursor]
        cursor += 1
        if code == 0:
            key = tokens[cursor]
            weight = tokens[cursor + 1]
            cursor += 2
            live[key] = weight
        elif code == 1:
            key = tokens[cursor]
            cursor += 1
            del live[key]
        else:
            first_key = tokens[cursor]
            second_key = tokens[cursor + 1]
            cursor += 2
            parents = cartesian_parents(sorted(live.items()))
            lines.append(str(distance(first_key, second_key, parents)))
    return "\n".join(lines) + "\n"


SAMPLE = """12
0 4 17535
0 10 38964
0 2 21626
0 1 61321
2 1 10
2 10 4
1 10
1 1
0 8 42634
2 8 4
2 8 2
2 4 2
"""
SAMPLE_OUT = """1
2
2
1
1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3\n0 5 10\n0 2 20\n2 5 2\n") == "1\n"
assert oracle("5\n0 1 1\n0 2 2\n0 3 3\n2 1 3\n2 1 2\n") == "2\n1\n"
assert oracle("2\n0 7 9\n2 7 7\n") == "0\n"


def write(name, operations):
    text = str(len(operations)) + "\n"
    text += "".join(" ".join(str(value) for value in operation) + "\n" for operation in operations)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(0, 1, 1), (2, 1, 1), (0, 2, 5), (2, 1, 2), (1, 1),
                      (2, 2, 2), (0, 3, 9), (2, 2, 3), (1, 2), (2, 3, 3)])
    write("3_wide", [(0, key, 100000 - key) for key in range(1, 101)] +
                    [(2, 1, 100), (2, 50, 51), (1, 50), (2, 1, 100)])
    rng = random.Random(20261126)
    keys = rng.sample(range(1, 1000000), 400)
    weights = rng.sample(range(1, 2000000000), 400)
    operations = [(0, keys[index], weights[index]) for index in range(400)]
    for _ in range(200):
        operations.append((2, rng.choice(keys[:200]), rng.choice(keys[:200])))
    write("4_random", operations)
    queries = []
    for index in range(1, 101):
        queries.append((0, index, 1000000 - index))
    for index in range(1, 100):
        queries.append((2, index, index + 1))
    write("5_io", queries)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(0, 4, 17535), (0, 10, 38964), (0, 2, 21626), (0, 1, 61321),
                   (2, 1, 10), (2, 10, 4), (1, 10), (1, 1), (0, 8, 42634),
                   (2, 8, 4), (2, 8, 2), (2, 4, 2)])
build()

rng = random.Random(19471208)
big_keys = rng.sample(range(1, 2000000000), 200000)
big_weights = rng.sample(range(1, 2000000000), 200000)
big_operations = [(0, big_keys[index], big_weights[index]) for index in range(100000)]
for _ in range(100000):
    big_operations.append((2, rng.choice(big_keys[:100000]), rng.choice(big_keys[:100000])))
Path("/tmp/COT5_big.txt").write_text(
    str(len(big_operations)) + "\n" +
    "".join(" ".join(str(value) for value in operation) + "\n" for operation in big_operations))
