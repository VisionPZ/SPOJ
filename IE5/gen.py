#!/usr/bin/env python3
import random
from itertools import permutations
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 9901


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    pos = 1
    lines = []
    for case_number in range(1, case_count + 1):
        node_count = tokens[pos]
        edge_count = tokens[pos + 1]
        pos += 2
        forbidden = set()
        for _ in range(edge_count):
            left = tokens[pos]
            right = tokens[pos + 1]
            pos += 2
            forbidden.add(frozenset((left, right)))
        cycles = 0
        for order in permutations(range(2, node_count + 1)):
            cycle = (1,) + order
            if all(frozenset((cycle[index], cycle[(index + 1) % node_count])) not in forbidden
                   for index in range(node_count)):
                cycles += 1
        lines.append(f"Case #{case_number}: {(cycles // 2) % MODULUS}")
    return "\n".join(lines) + "\n"


SAMPLE = "2\n4 1\n1 2\n8 4\n1 2\n2 3\n4 5\n5 6\n"
SAMPLE_OUT = "Case #1: 1\nCase #2: 660\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n3 0\n") == "Case #1: 1\n"
assert oracle("1\n3 1\n1 2\n") == "Case #1: 0\n"
assert oracle("1\n4 2\n1 2\n3 4\n") == "Case #1: 1\n"
assert 2 * 4951 % 9901 == 1


def write(name, cases):
    chunks = [str(len(cases))]
    for node_count, edges in cases:
        chunks.append(f"{node_count} {len(edges)}")
        for left, right in edges:
            chunks.append(f"{left} {right}")
    text = "\n".join(chunks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(3, []), (3, [(1, 2)]), (4, [(1, 2)]),
                      (4, [(1, 2), (3, 4)]), (5, [(1, 2), (2, 3), (3, 4)])])
    rng = random.Random(20261125)
    wide = []
    for _ in range(10):
        node_count = 8
        pairs = [(left, right) for left in range(1, node_count + 1)
                 for right in range(left + 1, node_count + 1)]
        rng.shuffle(pairs)
        wide.append((node_count, pairs[:15]))
    write("3_wide", wide)
    random_cases = []
    for _ in range(12):
        node_count = rng.randint(3, 7)
        pairs = [(left, right) for left in range(1, node_count + 1)
                 for right in range(left + 1, node_count + 1)]
        rng.shuffle(pairs)
        random_cases.append((node_count, pairs[:rng.randint(0, len(pairs))]))
    write("4_random", random_cases)
    io_cases = []
    for index in range(30):
        io_cases.append((6, [(1, 2), (2, 3), (3, 4)] if index % 2 else []))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(4, [(1, 2)]), (8, [(1, 2), (2, 3), (4, 5), (5, 6)])])
build()
