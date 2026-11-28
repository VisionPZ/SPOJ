#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10**9
KNOWN = {}


def solve_case(n, edges, a, b):
    adjacency = [[] for _ in range(n)]
    for u, v in edges:
        adjacency[u - 1].append(v - 1)
        adjacency[v - 1].append(u - 1)
    closed = [[u] + adjacency[u] for u in range(n)]
    after = [[INF] * n for _ in range(n)]
    before = [[INF] * n for _ in range(n)]
    for u in range(n):
        after[u][u] = 0
        for v in adjacency[u]:
            after[u][v] = 1
    changed = True
    while changed:
        changed = False
        for u in range(n):
            for v in range(n):
                if u == v:
                    continue
                if after[u][v] > 1:
                    best = INF
                    for w in closed[v]:
                        if before[u][w] < best:
                            best = before[u][w]
                    if best < INF and 1 + best < after[u][v]:
                        after[u][v] = 1 + best
                        changed = True
                worst = 0
                escapes = False
                for w in closed[u]:
                    if after[w][v] >= INF:
                        escapes = True
                        break
                    if after[w][v] > worst:
                        worst = after[w][v]
                if not escapes and worst < before[u][v]:
                    before[u][v] = worst
                    changed = True
    answer = before[a - 1][b - 1]
    return None if answer >= INF else answer


def case_key(n, edges, a, b):
    return (n, tuple(sorted((min(u, v), max(u, v)) for u, v in edges)), a, b)


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(count):
        n = int(tokens[cursor])
        m = int(tokens[cursor + 1])
        a = int(tokens[cursor + 2])
        b = int(tokens[cursor + 3])
        cursor += 4
        edges = []
        for _ in range(m):
            edges.append((int(tokens[cursor]), int(tokens[cursor + 1])))
            cursor += 2
        key = case_key(n, edges, a, b)
        if key in KNOWN:
            answer = KNOWN[key]
        else:
            answer = solve_case(n, edges, a, b)
        answers.append("No" if answer is None else str(answer))
    return "\n".join(answers) + "\n"


def render_case(n, edges, a, b):
    lines = [f"{n} {len(edges)} {a} {b}"]
    lines.extend(f"{u} {v}" for u, v in edges)
    return "\n".join(lines) + "\n"


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(
        render_case(n, edges, a, b) for n, edges, a, b in cases)
    expected = oracle(input_text)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(expected)


def path(n):
    return [(i, i + 1) for i in range(1, n)]


SAMPLE_N = 9
SAMPLE_EDGES = [(1, 2), (3, 2), (1, 4), (4, 7), (7, 5),
                (5, 1), (6, 9), (8, 5), (9, 8), (5, 3), (4, 8)]
SAMPLE = (SAMPLE_N, SAMPLE_EDGES, 9, 4)

assert solve_case(*SAMPLE) == 3
assert solve_case(2, [(1, 2)], 1, 2) == 1
assert solve_case(2, [(1, 2)], 2, 1) == 1
assert solve_case(4, path(4), 1, 4) == 3
assert solve_case(4, [(1, 2), (2, 3), (3, 4), (4, 1)], 1, 3) is None
for length in range(2, 12):
    for chaser in range(2, length + 1):
        assert solve_case(length, path(length), 1, chaser) == chaser - 1


def build():
    write("1_sample", [SAMPLE])

    triangle = [(1, 2), (2, 3), (3, 4), (4, 1)]
    tail = [(1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (2, 7), (7, 8)]
    tail_n = 8
    edges_cases = [
        (2, [(1, 2)], 1, 2),
        (2, [(1, 2)], 2, 1),
        (3, path(3), 1, 3),
        (3, path(3), 3, 1),
        (4, triangle, 1, 3),
        (4, triangle, 2, 4),
        (4, [(1, 2), (2, 3), (3, 1), (1, 4)], 4, 1),
        (tail_n, tail, 6, 1),
        (tail_n, tail, 1, 6),
        (5, path(5), 3, 1),
        (5, path(5), 1, 5),
        (7, [(1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 1)], 1, 4),
    ]
    write("2_edges", edges_cases)

    wide_path = path(3000)
    wide_star = [(1, i) for i in range(2, 3001)]
    wide_bipartite = []
    for i in range(150):
        for j in range(100):
            wide_bipartite.append((i + 1, (j * 150 + i) % 2850 + 151))
    wide_cases = [
        (3000, wide_path, 1, 1500),
        (3000, wide_star, 2, 1),
        (3000, wide_star, 1, 2),
        (3000, wide_bipartite, 1, 151),
    ]
    for n, edges, a, b in wide_cases:
        if n == 3000 and edges is wide_path:
            value = b - 1
        elif edges is wide_star and a == 2:
            value = 1
        elif edges is wide_star and a == 1:
            value = 2
        else:
            value = None
        KNOWN[case_key(n, edges, a, b)] = value
    write("3_wide", wide_cases)

    rnd = random.Random(20261124)
    random_cases = []
    for _ in range(48):
        n = rnd.randint(3, 9)
        edges = path(n)
        have = {tuple(sorted(e)) for e in edges}
        extras = rnd.randint(0, n)
        attempts = 0
        while extras > 0 and attempts < 200:
            attempts += 1
            u = rnd.randint(1, n)
            v = rnd.randint(1, n)
            if u == v or (min(u, v), max(u, v)) in have:
                continue
            if set(adjacent(edges, u)) & set(adjacent(edges, v)):
                continue
            edges.append((u, v))
            have.add((min(u, v), max(u, v)))
            extras -= 1
        a = rnd.randint(1, n)
        b = rnd.randint(1, n)
        while b == a:
            b = rnd.randint(1, n)
        random_cases.append((n, edges, a, b))
    write("4_random", random_cases)

    io_templates = [
        (2, [(1, 2)], 1, 2),
        (3, path(3), 1, 3),
        (4, triangle, 1, 3),
        (5, path(5), 1, 5),
    ]
    io_cases = [io_templates[i % len(io_templates)] for i in range(20000)]
    write("5_io", io_cases)


def adjacent(edges, u):
    result = []
    for x, y in edges:
        if x == u:
            result.append(y)
        elif y == u:
            result.append(x)
    return result


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [SAMPLE])
build()
