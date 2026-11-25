#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def insert_node(tree, value):
    if tree is None:
        return (value, None, None)
    root, left, right = tree
    if value < root:
        return (root, insert_node(left, value), right)
    return (root, left, insert_node(right, value))


def shape_of(tree):
    if tree is None:
        return None
    return (shape_of(tree[1]), shape_of(tree[2]))


def oracle(text):
    tokens = [int(value) for value in text.split()]
    pos = 0
    answers = []
    while pos < len(tokens):
        proto_count = tokens[pos]
        layer_count = tokens[pos + 1]
        pos += 2
        shapes = []
        for _ in range(proto_count):
            tree = None
            for _ in range(layer_count):
                tree = insert_node(tree, tokens[pos])
                pos += 1
            outline = shape_of(tree)
            if outline not in shapes:
                shapes.append(outline)
        answers.append(str(len(shapes)))
    return "\n".join(answers) + "\n"


SAMPLE = """5 3
2 7 1
3 1 4
1 5 9
2 6 5
9 7 3
3 4
3 1 2 40000
3 4 2 1
33 42 17 23
"""
SAMPLE_OUT = """4
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n7\n") == "1\n"
assert oracle("3 2\n1 2\n2 1\n1 2\n") == "2\n"
assert oracle("2 3\n1 2 3\n3 2 1\n") == "2\n"
assert oracle("4 4\n1 2 3 4\n4 3 2 1\n1 4 2 3\n2 3 4 1\n") == "4\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def make_case(rng, proto_count, layer_count):
    lines = [f"{proto_count} {layer_count}"]
    for _ in range(proto_count):
        values = rng.sample(range(1, 1000001), layer_count)
        lines.append(" ".join(str(value) for value in values))
    return "\n".join(lines) + "\n"


def build():
    write("2_edges", "1 1\n7\n")
    rng = random.Random(20261126)
    write("3_wide", make_case(rng, 50, 20))
    rng = random.Random(20261127)
    cases = []
    for proto_count, layer_count in [(5, 4), (10, 7), (3, 12)]:
        cases.append(make_case(rng, proto_count, layer_count).rstrip("\n"))
    write("4_random", "\n".join(cases) + "\n")
    rng = random.Random(20261128)
    many = []
    for _ in range(25):
        many.append(make_case(rng, rng.randint(1, 50), rng.randint(1, 20)).rstrip("\n"))
    write("5_io", "\n".join(many) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
