#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def kruskal_total(node_count, edges):
    parent = list(range(node_count))

    def find(node):
        while parent[node] != node:
            parent[node] = parent[parent[node]]
            node = parent[node]
        return node

    total = 0
    for left, right, weight in sorted(edges, key=lambda edge: edge[2]):
        left_root = find(left)
        right_root = find(right)
        if left_root != right_root:
            parent[left_root] = right_root
            total += weight
    return total


def oracle(text):
    tokens = [int(value) for value in text.split()]
    node_count, query_count = tokens[0], tokens[1]
    cursor = 2
    edges = []
    last_answer = 0
    answers = []
    for _ in range(query_count):
        left = tokens[cursor] ^ last_answer
        right = tokens[cursor + 1] ^ last_answer
        weight = tokens[cursor + 2] ^ last_answer
        cursor += 3
        edges.append((left, right, weight))
        last_answer = kruskal_total(node_count, edges)
        answers.append(str(last_answer))
    return "\n".join(answers) + "\n"


SAMPLE_ONE = """5 5
4 3 6
6 7 4
8 9 10
8 12 9
8 10 11
"""
SAMPLE_ONE_OUT = """6
8
8
9
5
"""
SAMPLE_TWO = """6 9
3 2 7
4 5 13
2 6 3
11 10 14
17 18 18
16 23 26
19 18 17
18 19 21
14 13 12
"""
SAMPLE_TWO_OUT = """7
7
11
16
18
18
16
14
11
"""
SAMPLE_THREE = """3 4
0 1 8
8 10 13
15 13 4
13 12 8
"""
SAMPLE_THREE_OUT = """8
13
13
10
"""
SAMPLE_FOUR = """6 7
4 3 3
3 6 4
14 9 13
8 15 14
11 13 9
17 16 20
13 14 6
"""
SAMPLE_FOUR_OUT = """3
10
10
14
21
15
24
"""
SAMPLE_FIVE = """7 11
3 0 997179154
997179152 997179154 204554238
1926119418 1926119416 1370896084
2521188650 2521188654 3204670819
3213587831 3213587825 2592574673
3142795976 3142795983 3067341340
3369331620 3369331617 3266995941
3544021221 3544021220 3341161807
2952422819 2952422823 3068368185
2952422818 2952422823 3137316850
2952422817 2952422819 2934379046
"""
SAMPLE_FIVE_OUT = """997179154
1926119422
2521188648
3213587827
3142795978
3369331616
3544021221
2952422819
2952422819
2952422819
2349523846
"""
assert oracle(SAMPLE_ONE) == SAMPLE_ONE_OUT
assert oracle(SAMPLE_TWO) == SAMPLE_TWO_OUT
assert oracle(SAMPLE_THREE) == SAMPLE_THREE_OUT
assert oracle(SAMPLE_FOUR) == SAMPLE_FOUR_OUT
assert oracle(SAMPLE_FIVE) == SAMPLE_FIVE_OUT
assert kruskal_total(3, [(0, 1, 5), (1, 2, 2)]) == 7


def encode_cases(node_count, triples):
    last_answer = 0
    lines = [f"{node_count} {len(triples)}"]
    seen = []
    for left, right, weight in triples:
        lines.append(f"{left ^ last_answer} {right ^ last_answer} {weight ^ last_answer}")
        seen.append((left, right, weight))
        last_answer = kruskal_total(node_count, seen)
    return "\n".join(lines) + "\n"


def write_encoded(name, node_count, triples):
    text = encode_cases(node_count, triples)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    edges = [(rng.randrange(8), rng.randrange(8), rng.randint(0, 20))
             for _ in range(40)]
    edges = [(left, right, weight) for left, right, weight in edges if left != right]
    write_encoded("2_edges", 8, edges[:25])
    wide_edges = []
    last_answer = 0
    for _ in range(60):
        left = rng.randrange(40)
        right = rng.randrange(40)
        if left == right:
            continue
        weight = rng.randint(0, 10 ** 9)
        wide_edges.append((left, right, weight))
    write_encoded("3_wide", 40, wide_edges)
    write_encoded("4_random", 25,
                  [(left, right, rng.randint(0, 10 ** 9))
                   for left, right in ((rng.randrange(25), rng.randrange(25))
                                       for _ in range(80)) if left != right])
    write_encoded("5_io", 12,
                  [(left, right, rng.randint(0, 1000000007))
                   for left, right in ((rng.randrange(12), rng.randrange(12))
                                       for _ in range(400)) if left != right])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_ONE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_ONE_OUT)
build()
