#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def fixed(value):
    rounded = int(value * 1000000.0 + 0.5)
    whole, fraction = divmod(rounded, 1000000)
    return f"{whole}.{fraction:06d} percent\n"


def oracle(cases):
    lines = []
    for node_count, edges in cases:
        width = node_count + 1
        best = [[0.0] * width for _ in range(width)]
        for node in range(1, width):
            best[node][node] = 1.0
        for first, second, percent in edges:
            chance = percent / 100.0
            if chance > best[first][second]:
                best[first][second] = chance
                best[second][first] = chance
        for middle in range(1, width):
            middle_row = best[middle]
            for start in range(1, width):
                prefix = best[start][middle]
                if prefix == 0.0:
                    continue
                start_row = best[start]
                for finish in range(1, width):
                    candidate = prefix * middle_row[finish]
                    if candidate > start_row[finish]:
                        start_row[finish] = candidate
        lines.append(fixed(best[1][node_count] * 100.0))
    return "".join(lines)


def brute(case):
    node_count, edges = case
    adjacency = [[] for _ in range(node_count + 1)]
    for first, second, percent in edges:
        adjacency[first].append((second, percent / 100.0))
        adjacency[second].append((first, percent / 100.0))
    best = 0.0

    def walk(node, arrived, seen):
        nonlocal best
        if node == node_count:
            if arrived > best:
                best = arrived
            return
        for nxt, chance in adjacency[node]:
            if nxt not in seen:
                walk(nxt, arrived * chance, seen | {nxt})

    walk(1, 1.0, {1})
    return fixed(best * 100.0)


def write(name, cases):
    input_lines = []
    for node_count, edges in cases:
        input_lines.append(f"{node_count} {len(edges)}\n")
        for first, second, percent in edges:
            input_lines.append(f"{first} {second} {percent}\n")
    input_lines.append("0\n")
    (ROOT / "in" / f"{name}.txt").write_text("".join(input_lines))
    (ROOT / "out" / f"{name}.out").write_text(oracle(cases))


SAMPLE_CASE = (5, [(5, 2, 100), (3, 5, 80), (2, 3, 70), (2, 1, 50),
                   (3, 4, 90), (4, 1, 85), (3, 1, 70)])
SAMPLE_INPUT = ("5 7\n5 2 100\n3 5 80\n2 3 70\n2 1 50\n"
                "3 4 90\n4 1 85\n3 1 70\n0\n")
SAMPLE_OUTPUT = "61.200000 percent\n"

assert oracle([SAMPLE_CASE]) == SAMPLE_OUTPUT
assert oracle([(2, [(2, 1, 100)])]) == "100.000000 percent\n"
assert oracle([(3, [(1, 2, 50), (2, 3, 50)])]) == "25.000000 percent\n"
assert fixed(0.612 * 100.0) == SAMPLE_OUTPUT


def connected_case(node_count, target_edges, chance_rng):
    edges = []
    used = set()
    for node in range(2, node_count + 1):
        parent = chance_rng.randint(1, node - 1)
        pair = (min(parent, node), max(parent, node))
        used.add(pair)
        edges.append((pair[0], pair[1], chance_rng.randint(1, 100)))
    limit = node_count * (node_count - 1) // 2
    target = min(target_edges, limit)
    while len(edges) < target:
        first = chance_rng.randint(1, node_count)
        second = chance_rng.randint(1, node_count)
        if first == second:
            continue
        pair = (min(first, second), max(first, second))
        if pair in used:
            continue
        used.add(pair)
        edges.append((pair[0], pair[1], chance_rng.randint(1, 100)))
    return (node_count, edges)


check_rng = random.Random(77)
for _ in range(25):
    small_case = connected_case(check_rng.randint(2, 6), 12, check_rng)
    assert oracle([small_case]) == brute(small_case)


def complete_case(node_count, chance_rng, fixed_percent=None):
    edges = []
    for first in range(1, node_count + 1):
        for second in range(first + 1, node_count + 1):
            percent = fixed_percent if fixed_percent else chance_rng.randint(1, 100)
            edges.append((first, second, percent))
    return (node_count, edges)


def build():
    edge_cases = [
        (2, [(1, 2, 100)]),
        (2, [(2, 1, 1)]),
        (3, [(1, 2, 50), (2, 3, 50)]),
        (3, [(1, 2, 50), (2, 3, 50), (1, 3, 80)]),
        (100, [(1, 100, 7)]),
        (100, [(node, node + 1, 99) for node in range(1, 100)]),
        (100, [(1, node, node) for node in range(2, 101)]),
        complete_case(100, random.Random(1), 100),
        (5, [(1, 2, 10), (2, 5, 10), (1, 3, 90), (3, 5, 90),
             (1, 4, 25), (4, 5, 25)]),
        (99, [(1, 99, 100)]),
    ]
    write("2_edges", edge_cases)

    wide_rng = random.Random(31415)
    wide_cases = [
        complete_case(100, wide_rng),
        complete_case(100, wide_rng, 100),
        complete_case(99, wide_rng),
        connected_case(100, 1800, wide_rng),
    ]
    write("3_wide", wide_cases)

    random_rng = random.Random(20261125)
    random_cases = []
    for _ in range(16):
        node_count = random_rng.randint(2, 100)
        limit = node_count * (node_count - 1) // 2
        target = random_rng.randint(node_count - 1, min(limit, 1400))
        random_cases.append(connected_case(node_count, target, random_rng))
    write("4_random", random_cases)

    io_rng = random.Random(9182736)
    io_cases = [(2, [(1, 2, io_rng.randint(1, 100))]) for _ in range(150000)]
    write("5_io", io_cases)
    print("generated 150000 io cases")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [SAMPLE_CASE])
assert (ROOT / "in" / "1_sample.txt").read_text() == SAMPLE_INPUT
assert (ROOT / "out" / "1_sample.out").read_text() == SAMPLE_OUTPUT
build()
