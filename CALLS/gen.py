#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent
BIG = 10**14
INF = 10**15


def oracle_incremental(n, line_count, values):
    if line_count > n * (n - 1) // 2:
        return False
    if any(value <= 0 for value in values):
        return False
    current = np.full((n, n), BIG, dtype=np.int64)
    np.fill_diagonal(current, 0)
    ordered = []
    cursor = 0
    for i in range(n):
        for j in range(i + 1, n):
            ordered.append((values[cursor], i, j))
            cursor += 1
    ordered.sort()
    essential = 0
    for advertised, i, j in ordered:
        if current[i, j] < advertised:
            return False
        if current[i, j] > advertised:
            np.minimum(current, current[:, i][:, None] + advertised + current[j, :][None, :], out=current)
            np.minimum(current, current[:, j][:, None] + advertised + current[i, :][None, :], out=current)
            essential += 1
            if essential > line_count:
                return False
    return essential <= line_count


def oracle_bruteforce(n, line_count, values):
    all_pairs = [(i, j) for i in range(n) for j in range(i + 1, n)]
    if line_count > len(all_pairs):
        return False
    target = [[0] * n for _ in range(n)]
    cursor = 0
    for i, j in all_pairs:
        value = values[cursor]
        cursor += 1
        if value <= 0:
            return False
        target[i][j] = target[j][i] = value
    for chosen in itertools.combinations(all_pairs, line_count):
        distances = [[INF] * n for _ in range(n)]
        for vertex in range(n):
            distances[vertex][vertex] = 0
        for u, v in chosen:
            weight = target[u][v]
            if weight < distances[u][v]:
                distances[u][v] = distances[v][u] = weight
        for middle in range(n):
            row_middle = distances[middle]
            for u in range(n):
                row_u = distances[u]
                first = row_u[middle]
                for v in range(n):
                    candidate = first + row_middle[v]
                    if candidate < row_u[v]:
                        row_u[v] = candidate
        if all(distances[i][j] == target[i][j] for i, j in all_pairs):
            return True
    return False


def shortest_path_values(n, edges):
    matrix = np.full((n, n), BIG, dtype=np.int64)
    np.fill_diagonal(matrix, 0)
    for u, v, weight in edges:
        if weight < matrix[u, v]:
            matrix[u, v] = matrix[v, u] = weight
    for middle in range(n):
        np.minimum(matrix, matrix[:, middle][:, None] + matrix[middle, :][None, :], out=matrix)
    return [int(matrix[i, j]) for i in range(n) for j in range(i + 1, n)]


def random_tree(n, rng, maximum_weight=9):
    edges = []
    for vertex in range(1, n):
        parent = rng.randrange(vertex)
        edges.append((parent, vertex, rng.randint(1, maximum_weight)))
    return edges


def random_bipartite(n, edge_count, rng):
    edges = [(vertex, vertex + 1, 1) for vertex in range(n - 1)]
    left = list(range(0, n, 2))
    right = list(range(1, n, 2))
    choices = [(u, v) for u in left for v in right if abs(u - v) != 1]
    rng.shuffle(choices)
    for u, v in choices:
        if len(edges) >= edge_count:
            break
        edges.append((u, v, 1))
    return edges


def format_case(n, line_count, values):
    parts = [f"{n} {line_count}\n"]
    cursor = 0
    for i in range(n):
        width = n - i - 1
        if width:
            parts.append(" ".join(str(value) for value in values[cursor:cursor + width]) + "\n")
            cursor += width
    return "".join(parts)


def write_pair(name, cases):
    input_parts = [str(len(cases)) + "\n"]
    output_parts = []
    for n, line_count, values in cases:
        input_parts.append(format_case(n, line_count, values))
        output_parts.append("YES\n" if oracle_incremental(n, line_count, values) else "NO\n")
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    (ROOT / "in" / f"{name}.txt").write_text("".join(input_parts))
    (ROOT / "out" / f"{name}.out").write_text("".join(output_parts))


assert oracle_incremental(3, 3, [1, 2, 2]) is True
assert oracle_incremental(3, 2, [1, 2, 2]) is False
assert oracle_bruteforce(3, 3, [1, 2, 2]) is True
assert oracle_bruteforce(3, 2, [1, 2, 2]) is False
assert oracle_incremental(3, 3, [1, 5, 1]) is False

check_rng = random.Random(11)
for _ in range(80):
    check_n = check_rng.randint(1, 5)
    pair_total = check_n * (check_n - 1) // 2
    check_values = [check_rng.randint(1, 7) for _ in range(pair_total)]
    check_k = check_rng.randint(0, pair_total + 2)
    assert oracle_incremental(check_n, check_k, check_values) == oracle_bruteforce(check_n, check_k, check_values)

tree_values = shortest_path_values(10, random_tree(10, random.Random(3), 4))
assert oracle_incremental(10, 9, tree_values) is True
assert oracle_incremental(10, 8, tree_values) is False

small_bipartite = random_bipartite(20, 40, random.Random(5))
bipartite_values = shortest_path_values(20, small_bipartite)
assert oracle_incremental(20, 40, bipartite_values) is True
assert oracle_incremental(20, 39, bipartite_values) is False

SAMPLE = [(3, 3, [1, 2, 2]), (3, 2, [1, 2, 2])]
write_pair("1_sample", SAMPLE)

edge_cases = [
    (1, 0, []),
    (1, 1, []),
    (2, 1, [5]),
    (2, 0, [5]),
    (2, 2, [5]),
    (3, 3, [1, 1, 1]),
    (3, 2, [1, 1, 1]),
    (3, 3, [1, 5, 1]),
    (3, 3, [0, 2, 2]),
    (4, 3, shortest_path_values(4, random_tree(4, random.Random(7), 5))),
    (4, 0, shortest_path_values(4, random_tree(4, random.Random(8), 5))),
    (5, 10, [1] * 10),
    (5, 9, [1] * 10),
]
write_pair("2_edges", edge_cases)

wide_tree = shortest_path_values(300, random_tree(300, random.Random(21)))
wide_bipartite = shortest_path_values(300, random_bipartite(300, 1200, random.Random(22)))
wide_cases = [
    (300, 299, wide_tree),
    (300, 298, wide_tree),
    (300, 1200, wide_bipartite),
    (300, 1199, wide_bipartite),
    (300, 44851, wide_tree),
    (300, 2, [1, 5, 1] + wide_tree[3:]),
]
write_pair("3_wide", wide_cases)

random_cases = []
rng = random.Random(20261125)
for _ in range(50):
    n = rng.randint(1, 45)
    pair_total = n * (n - 1) // 2
    choice = rng.randint(0, 3)
    if choice == 0:
        values = [rng.randint(1, 12) for _ in range(pair_total)]
        k = rng.randint(0, pair_total + 2)
    elif choice == 1:
        values = shortest_path_values(n, random_tree(n, rng))
        k = n - 1 + rng.randint(-1, 2)
    elif choice == 2:
        if n == 1:
            values = []
        else:
            edge_target = max(n - 1, min(pair_total, rng.randint(1, 3 * n)))
            values = shortest_path_values(n, random_bipartite(n, edge_target, rng))
        k = rng.randint(0, pair_total + 1)
    else:
        values = [1] * pair_total
        k = rng.randint(0, pair_total + 1)
    random_cases.append((n, k, values))
write_pair("4_random", random_cases)

io_cases = []
rng = random.Random(9090)
for _ in range(20):
    values = shortest_path_values(300, random_bipartite(300, 1200, rng))
    io_cases.append((300, 1200, values))
write_pair("5_io", io_cases)

print("generated", len(random_cases), "random cases and", len(io_cases), "io cases")
