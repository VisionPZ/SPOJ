#!/usr/bin/env python3
import random
import string
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SAMPLE = "GKILQMT\n"
SAMPLE_OUT = """GIKLMQT
LIGKQMT
GKIMTQL
"""


class Node:
    __slots__ = ("key", "left", "right", "height")

    def __init__(self, key):
        self.key = key
        self.left = None
        self.right = None
        self.height = 1


def node_height(node):
    return 0 if node is None else node.height


def refresh(node):
    node.height = 1 + max(node_height(node.left), node_height(node.right))
    return node


def rotate_left(node):
    pivot = node.right
    node.right = pivot.left
    pivot.left = node
    refresh(node)
    refresh(pivot)
    return pivot


def rotate_right(node):
    pivot = node.left
    node.left = pivot.right
    pivot.right = node
    refresh(node)
    refresh(pivot)
    return pivot


def rebalance(node, key):
    refresh(node)
    lean = node_height(node.left) - node_height(node.right)
    if lean > 1:
        if key > node.left.key:
            node.left = rotate_left(node.left)
        return rotate_right(node)
    if lean < -1:
        if key < node.right.key:
            node.right = rotate_right(node.right)
        return rotate_left(node)
    return node


def insert_iterative(root, key):
    path = []
    node = root
    while node is not None:
        if key < node.key:
            path.append((node, "L"))
            node = node.left
        else:
            path.append((node, "R"))
            node = node.right
    replacement = Node(key)
    for ancestor, side in reversed(path):
        if side == "L":
            ancestor.left = replacement
        else:
            ancestor.right = replacement
        replacement = rebalance(ancestor, key)
    return replacement


def inorder(root):
    result = []
    stack = []
    node = root
    while node is not None or stack:
        while node is not None:
            stack.append(node)
            node = node.left
        node = stack.pop()
        result.append(node.key)
        node = node.right
    return "".join(result)


def preorder(root):
    result = []
    if root is None:
        return ""
    stack = [root]
    while stack:
        node = stack.pop()
        result.append(node.key)
        if node.right is not None:
            stack.append(node.right)
        if node.left is not None:
            stack.append(node.left)
    return "".join(result)


def postorder(root):
    result = []
    stack = []
    if root is None:
        return ""
    stack.append((root, False))
    while stack:
        node, visited = stack.pop()
        if visited:
            result.append(node.key)
        else:
            stack.append((node, True))
            if node.right is not None:
                stack.append((node.right, False))
            if node.left is not None:
                stack.append((node.left, False))
    return "".join(result)


def oracle(text):
    root = None
    for token in text.split():
        for letter in token:
            root = insert_iterative(root, letter)
    return "\n".join([inorder(root), preorder(root), postorder(root)]) + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("A\n") == "A\nA\nA\n"
assert oracle("BA\n") == "AB\nBA\nAB\n"
assert oracle("ABC\n") == "ABC\nBAC\nACB\n"


def write(name, word):
    input_text = word + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", "A")
    write("3_wide", "".join(random.Random(1).sample(string.ascii_uppercase, 26)))
    rng = random.Random(20261126)
    write("4_random", "".join(rng.choice(string.ascii_letters)
                              for _ in range(500)))
    write("5_io", "".join(rng.choice(string.ascii_letters)
                          for _ in range(5000)))


if "--trace" in sys.argv:
    print(oracle(SAMPLE), end="")
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", "GKILQMT")
    build()
