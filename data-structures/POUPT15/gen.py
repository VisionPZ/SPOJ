#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


class TreeNode:
    def __init__(self, key):
        self.key = key
        self.left = None
        self.right = None


def oracle_case(keys):
    root = None
    for key in keys:
        if root is None:
            root = TreeNode(key)
            continue
        current = root
        while True:
            if key < current.key:
                if current.left is None:
                    current.left = TreeNode(key)
                    break
                current = current.left
            else:
                if current.right is None:
                    current.right = TreeNode(key)
                    break
                current = current.right

    def height(node):
        if node is None:
            return 0
        return 1 + max(height(node.left), height(node.right))

    def balanced(node):
        if node is None:
            return True
        if abs(height(node.left) - height(node.right)) > 1:
            return False
        return balanced(node.left) and balanced(node.right)

    return "sim" if balanced(root) else "nao"


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    position = 1
    answers = []
    for _ in range(case_count):
        keys = []
        while tokens[position] != -1:
            keys.append(tokens[position])
            position += 1
        position += 1
        answers.append(oracle_case(keys))
    return "\n".join(answers) + "\n"


SAMPLE = """3
40 30 25 50 35 60 45 -1
25 36 20 22 30 40 38 28 10 5 12 48 -1
25 36 20 22 30 40 38 28 10 5 12 1 8 15 48 50 45   -1
"""
SAMPLE_OUT = """sim
sim
nao
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n10 15 20 -1\n") == "nao\n"
assert oracle("2\n10 5 20 -1\n5 20 -1\n") == "sim\nsim\n"
assert oracle("1\n1 -1\n") == "sim\n"
assert oracle("1\n40 20 10 30 60 50 70 -1\n") == "sim\n"


def write(name, cases):
    text = str(len(cases)) + "\n" + "\n".join(
        " ".join(str(key) for key in keys) + " -1" for keys in cases
    ) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[1], [0], [1, 2], [2, 1], [64000, 0, 1]])
    rng = random.Random(20261126)
    for name, count in (("3_wide", 60), ("4_random", 40), ("5_io", 100)):
        cases = []
        for _ in range(count):
            size = rng.randint(1, 90)
            keys = rng.sample(range(0, 64001), size)
            cases.append(keys)
        write(name, cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
