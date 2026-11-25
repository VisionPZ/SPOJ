#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def parse(text):
    values = [int(value) for value in text.split()]
    position = 0
    case_count = values[position]
    position += 1
    cases = []
    for _ in range(case_count):
        vertices, edges, cut_count = values[position:position + 3]
        position += 3
        pairs = []
        for _ in range(edges):
            pairs.append((values[position], values[position + 1]))
            position += 2
        cases.append((vertices, edges, cut_count, pairs))
    return cases


def brute_force(text):
    answers = []
    for vertices, edges, cut_count, pairs in parse(text):
        target = set(pairs[:cut_count])
        works = False
        for mask in range(1 << vertices):
            side = [0] + [(mask >> (index - 1)) & 1 for index in range(1, vertices + 1)]
            cut = {pair for pair in pairs if side[pair[0]] != side[pair[1]]}
            if cut == target:
                works = True
                break
        answers.append("YES" if works else "NO")
    return answers


def oracle(text):
    answers = []
    for vertices, edges, cut_count, pairs in parse(text):
        parent = list(range(vertices + 1))
        parity = [0] * (vertices + 1)

        def find(node):
            if parent[node] == node:
                return node, 0
            root, root_parity = find(parent[node])
            parent[node] = root
            parity[node] ^= root_parity
            return parent[node], parity[node]

        works = True
        for index, (left, right) in enumerate(pairs):
            wanted = 1 if index < cut_count else 0
            root_left, side_left = find(left)
            root_right, side_right = find(right)
            if root_left == root_right:
                if side_left ^ side_right != wanted:
                    works = False
            else:
                parent[root_left] = root_right
                parity[root_left] = side_left ^ side_right ^ wanted
        answers.append("YES" if works else "NO")
    return answers


SAMPLE = """2
3 3 1
1 2
2 3
1 3
12 17 6
3 4
5 6
10 11
1 5
6 10
4 8
1 2
2 3
6 7
7 8
9 10
11 12
5 9
2 6
3 7
7 11
8 12
"""
SAMPLE_OUT = """NO
YES
"""
assert brute_force(SAMPLE) == ["NO", "YES"]
assert oracle(SAMPLE) == ["NO", "YES"]
assert oracle("1\n2 1 1\n1 2\n") == ["YES"]
assert oracle("1\n3 2 1\n1 2\n2 3\n") == ["YES"]
assert oracle("1\n3 3 1\n1 2\n2 3\n1 3\n") == ["NO"]
assert oracle("1\n2 2 1\n1 1\n1 2\n") == ["NO"]


def render(cases):
    blocks = [str(len(cases))]
    for vertices, pairs, cut_count in cases:
        blocks.append(f"{vertices} {len(pairs)} {cut_count}")
        for left, right in pairs:
            blocks.append(f"{left} {right}")
    return "\n".join(blocks) + "\n"


def write(name, cases):
    text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text("".join(line + "\n" for line in oracle(text)))


def build():
    write("2_edges", [
        (2, [(1, 2)], 1),
        (2, [(1, 1)], 0),
        (2, [(1, 1)], 1),
        (4, [(1, 2), (2, 3), (3, 4)], 2),
        (5, [(1, 2), (1, 2), (3, 4)], 1),
    ])
    wide = [(index, index + 1) for index in range(1, 500)]
    write("3_wide", [(500, wide, 250)])

    rng = random.Random(20261126)
    cases = []
    for _ in range(10):
        vertices = rng.randint(3, 8)
        pairs = [(rng.randint(1, vertices), rng.randint(1, vertices)) for _ in range(14)]
        cut_count = rng.randint(1, len(pairs))
        cases.append((vertices, pairs, cut_count))
    write("4_random", cases)
    io_cases = [(6, [(1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 1)], index % 3)
                for index in range(60)]
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
