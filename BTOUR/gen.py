#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10 ** 18


def parse(text):
    tokens = text.split()
    pos = 0
    count = int(tokens[pos]); pos += 1
    cases = []
    for _ in range(count):
        n = int(tokens[pos]); pos += 1
        m = int(tokens[pos]); pos += 1
        edges = []
        for _ in range(m):
            u = int(tokens[pos]); pos += 1
            v = int(tokens[pos]); pos += 1
            w = int(tokens[pos]); pos += 1
            edges.append((u - 1, v - 1, w))
        cases.append((n, edges))
    return cases


def better(candidate, best, count):
    length, ways = candidate
    if best is None or length < best:
        return length, ways
    if length == best:
        return best, count + ways
    return best, count


def oracle_fw(n, edges):
    best = None
    count = 0
    for u, v, w in edges:
        if u == v:
            best, count = better((w, 1), best, count)
    for s in range(n):
        verts = [v for v in range(s + 1, n)]
        if len(verts) < 1:
            continue
        idx = {v: i for i, v in enumerate(verts)}
        size = len(verts)
        dist = [[INF] * size for _ in range(size)]
        ways = [[0] * size for _ in range(size)]
        for i in range(size):
            dist[i][i] = 0
            ways[i][i] = 1
        for u, v, w in edges:
            if u == v or u <= s or v <= s:
                continue
            iu, iv = idx[u], idx[v]
            for a, b in ((iu, iv), (iv, iu)):
                if w < dist[a][b]:
                    dist[a][b] = w
                    ways[a][b] = 1
                elif w == dist[a][b]:
                    ways[a][b] += 1
        for k in range(size):
            for i in range(size):
                if i == k or dist[i][k] >= INF:
                    continue
                dik = dist[i][k]
                wik = ways[i][k]
                for j in range(size):
                    if j == k or i == j or dist[k][j] >= INF:
                        continue
                    nd = dik + dist[k][j]
                    if nd < dist[i][j]:
                        dist[i][j] = nd
                        ways[i][j] = wik * ways[k][j]
                    elif nd == dist[i][j]:
                        ways[i][j] += wik * ways[k][j]
        neighbors = []
        for u, v, w in edges:
            if u == v:
                continue
            if u == s and v > s:
                neighbors.append((v, w))
            elif v == s and u > s:
                neighbors.append((u, w))
        for i in range(len(neighbors)):
            for j in range(i + 1, len(neighbors)):
                a, wa = neighbors[i]
                b, wb = neighbors[j]
                ia, ib = idx[a], idx[b]
                if dist[ia][ib] >= INF:
                    continue
                best, count = better((wa + dist[ia][ib] + wb, ways[ia][ib]), best, count)
    if best is None:
        return 0, 0
    return best, count


def oracle_brute(n, edges):
    adj = {}
    for u, v, w in edges:
        if u == v:
            continue
        adj.setdefault(u, []).append((v, w))
        adj.setdefault(v, []).append((u, w))
    cycles = {}

    def walk(start, u, visited, path, length):
        for v, w in adj.get(u, []):
            if v == start:
                if len(path) >= 3:
                    forward = tuple(path)
                    backward = (path[0],) + tuple(reversed(path[1:]))
                    cycles[min(forward, backward)] = length + w
            elif v > start and v not in visited:
                visited.add(v)
                path.append(v)
                walk(start, v, visited, path, length + w)
                path.pop()
                visited.remove(v)

    for start in range(n):
        walk(start, start, {start}, [start], 0)
    for u, v, w in edges:
        if u == v:
            cycles[('self', u)] = w
    if not cycles:
        return 0, 0
    minimum = min(cycles.values())
    return minimum, sum(1 for value in cycles.values() if value == minimum)


def oracle(text):
    answers = []
    for n, edges in parse(text):
        length, count = oracle_fw(n, edges)
        answers.append(f"{length} {count}")
    return "\n".join(answers) + "\n"


def render(cases):
    lines = [str(len(cases))]
    for n, edges in cases:
        lines.append(f"{n} {len(edges)}")
        for u, v, w in edges:
            lines.append(f"{u + 1} {v + 1} {w}")
    return "\n".join(lines) + "\n"


def write(name, cases):
    input_text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE_TEXT = """2
3 2
1 2 1
1 3 2
4 6
1 2 5
1 4 5
2 3 4
2 4 5
3 4 5
3 1 5
"""
SAMPLE = parse(SAMPLE_TEXT)

assert oracle(SAMPLE_TEXT) == "0 0\n14 2\n"
assert oracle_brute(3, [(0, 1, 1), (0, 2, 1), (1, 2, 1)]) == (3, 1)
assert oracle_fw(3, [(0, 1, 1), (0, 2, 1), (1, 2, 1)]) == (3, 1)
assert oracle_fw(2, [(0, 1, 3), (0, 1, 4)]) == (7, 1)
assert oracle_fw(2, [(0, 0, 9)]) == (9, 1)

probe = random.Random(7717)
for _ in range(40):
    n = probe.randint(3, 8)
    degree = [0] * n
    edges = []
    for u in range(n):
        for v in range(u + 1, n):
            if degree[u] >= 4 or degree[v] >= 4:
                continue
            if probe.random() < 0.45:
                edges.append((u, v, probe.randint(1, 12)))
                degree[u] += 1
                degree[v] += 1
    assert oracle_fw(n, edges) == oracle_brute(n, edges), (n, edges)


def random_graph(rng, n, weight_high, allow_parallel=False):
    degree = [0] * n
    edges = []
    pairs = [(u, v) for u in range(n) for v in range(u + 1, n)]
    rng.shuffle(pairs)
    for u, v in pairs:
        if degree[u] >= 4 or degree[v] >= 4:
            continue
        if rng.random() < 0.55:
            weight = rng.randint(1, weight_high)
            edges.append((u, v, weight))
            degree[u] += 1
            degree[v] += 1
    if allow_parallel and n >= 2 and degree[0] < 3 and degree[1] < 3:
        edges.append((0, 1, rng.randint(1, weight_high)))
    return n, edges


def build():
    edges_cases = [
        (1, []),
        (2, [(0, 1, 5)]),
        (3, [(0, 1, 2), (1, 2, 3)]),
        (3, [(0, 1, 1), (0, 2, 1), (1, 2, 1)]),
        (3, [(0, 1, 4), (0, 2, 5), (1, 2, 6)]),
        (4, [(0, 1, 1), (1, 2, 1), (2, 3, 1), (0, 3, 1)]),
        (4, [(0, 1, 1), (1, 2, 1), (2, 3, 1), (0, 3, 1), (0, 2, 1)]),
        (4, [(0, 1, 2), (0, 1, 3)]),
        (4, [(0, 0, 7), (0, 1, 2), (1, 2, 3)]),
        (5, [(0, 1, 1), (0, 2, 1), (1, 2, 1), (2, 3, 1), (3, 4, 1), (2, 4, 1)]),
        (6, [(0, 1, 3), (1, 2, 3), (2, 0, 3), (3, 4, 3), (4, 5, 3), (3, 5, 3)]),
    ]
    write("2_edges", edges_cases)

    wide_rng = random.Random(31337)
    wide = [random_graph(wide_rng, 50, 20) for _ in range(3)]
    ring = [(i, i + 1, 1) for i in range(49)] + [(0, 49, 1)]
    wide.append((50, ring))
    write("3_wide", wide)

    rand_rng = random.Random(90210)
    random_cases = []
    for _ in range(60):
        n = rand_rng.randint(3, 16)
        high = rand_rng.choice([6, 15, 1000, 1000000])
        random_cases.append(random_graph(rand_rng, n, high, allow_parallel=True))
    write("4_random", random_cases)

    io_rng = random.Random(55555)
    io_cases = [random_graph(io_rng, rand_rng.randint(3, 6), 50) for _ in range(200)]
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
