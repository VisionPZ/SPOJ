#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 31011


def oracle(node_count, edges):
    best = None
    count = 0
    for choice in itertools.combinations(range(len(edges)), node_count - 1):
        parent = list(range(node_count + 1))

        def find(node):
            while parent[node] != node:
                node = parent[node]
            return node

        total = 0
        connected = True
        for edge_index in choice:
            first, second, weight = edges[edge_index]
            first_root = find(first)
            second_root = find(second)
            if first_root == second_root:
                connected = False
                break
            parent[first_root] = second_root
            total += weight
        if not connected:
            continue
        root = find(1)
        if any(find(node) != root for node in range(2, node_count + 1)):
            continue
        if best is None or total < best:
            best = total
            count = 1
        elif total == best:
            count += 1
    return str(count % MODULUS) + "\n"


def encode(node_count, edges):
    lines = [f"{node_count} {len(edges)}"]
    lines.extend(f"{first} {second} {weight}" for first, second, weight in edges)
    return "\n".join(lines) + "\n"


SAMPLE = (4, [(1, 2, 1), (1, 3, 1), (1, 4, 1), (2, 3, 2), (2, 4, 1), (3, 4, 1)])
assert oracle(4, [(1, 2, 1), (1, 3, 1), (1, 4, 1), (2, 3, 2), (2, 4, 1), (3, 4, 1)]) == "8\n"
assert oracle(2, [(1, 2, 7)]) == "1\n"
assert oracle(3, [(1, 2, 4), (2, 3, 4), (1, 3, 9)]) == "1\n"
assert oracle(3, [(1, 2, 4), (2, 3, 4), (1, 3, 4)]) == "3\n"
assert MODULUS == 3 * 10337
assert 3 * 3446 % 10337 == 1


def write(name, node_count, edges):
    text = encode(node_count, edges)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(node_count, edges))


def connected_graph(rng, node_count, extra):
    edges = []
    for node in range(2, node_count + 1):
        edges.append((rng.randint(1, node - 1), node, rng.randint(1, 6)))
    used = {(min(first, second), max(first, second)) for first, second, _ in edges}
    for _ in range(extra):
        first = rng.randint(1, node_count)
        second = rng.randint(1, node_count)
        if first == second or (min(first, second), max(first, second)) in used:
            continue
        used.add((min(first, second), max(first, second)))
        edges.append((first, second, rng.randint(1, 6)))
    rng.shuffle(edges)
    return edges


def build():
    write("2_edges", 3, [(1, 2, 4), (2, 3, 4), (1, 3, 4)])
    rng = random.Random(20261126)
    write("3_wide", 6, connected_graph(rng, 6, 6))
    write("4_random", 7, connected_graph(rng, 7, 8))
    write("5_io", 7, connected_graph(rng, 7, 9))
    big = encode(100, connected_graph(rng, 100, 900))
    Path("/tmp/MSTS_big.txt").write_text(big)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE[0], SAMPLE[1])
build()
