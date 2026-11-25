import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = (
    "2\n"
    "4 3\n"
    "1 2\n"
    "1 3\n"
    "1 4\n"
    "4 5\n"
    "1 2\n"
    "2 3\n"
    "3 4\n"
    "1 4\n"
    "2 4\n"
)
SAMPLE_OUTPUT = "Case #1: -1\nCase #2: 3 1 2 4 1\n"

INF = 10 ** 9


def parse(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    cases = []
    for _ in range(count):
        size = int(tokens[cursor]); width = int(tokens[cursor + 1]); cursor += 2
        adjacency = [[] for _ in range(size + 1)]
        edges = []
        for _ in range(width):
            a = int(tokens[cursor]); b = int(tokens[cursor + 1]); cursor += 2
            if a > b:
                a, b = b, a
            edges.append((a, b))
            adjacency[a].append(b)
            adjacency[b].append(a)
        cases.append((size, edges, adjacency))
    return cases


def shortest_through(start, size, adjacency):
    neighbors = [v for v in adjacency[start] if v > start]
    best = INF
    for first in neighbors:
        dist = [-1] * (size + 1)
        dist[first] = 0
        queue = [first]
        cursor = 0
        while cursor < len(queue):
            here = queue[cursor]; cursor += 1
            for nxt in adjacency[here]:
                if nxt > start and dist[nxt] < 0:
                    dist[nxt] = dist[here] + 1
                    queue.append(nxt)
        for last in neighbors:
            if last != first and dist[last] >= 0:
                best = min(best, dist[last] + 2)
    return best


def can_finish(candidate, remaining, start, used, adjacency):
    goals = set(v for v in adjacency[start]
                if v >= start and not used[v] and
                (remaining == 1 or v != candidate))

    def walk(here, depth, seen):
        if depth == remaining - 1:
            return here in goals
        for nxt in adjacency[here]:
            if nxt < start or nxt == start or used[nxt] or nxt in seen:
                continue
            seen.add(nxt)
            if walk(nxt, depth + 1, seen):
                return True
            seen.remove(nxt)
        return False

    return walk(candidate, 0, {candidate})


def oracle(text):
    lines = []
    for case_index, (size, edges, adjacency) in enumerate(parse(text), 1):
        lengths = [shortest_through(node, size, adjacency)
                   for node in range(1, size + 1)]
        girth = min(lengths) if lengths else INF
        if girth == INF:
            lines.append("Case #{}: -1".format(case_index))
            continue
        start = lengths.index(girth) + 1
        used = [False] * (size + 1)
        used[start] = True
        tour = [start]
        for step in range(girth - 1):
            remaining = girth - step - 1
            current = tour[-1]
            chosen = -1
            for candidate in sorted(adjacency[current]):
                if candidate <= start or used[candidate]:
                    continue
                if can_finish(candidate, remaining, start, used, adjacency):
                    chosen = candidate
                    break
            assert chosen != -1
            tour.append(chosen)
            used[chosen] = True
        whole = " ".join(str(v) for v in tour + [start])
        lines.append("Case #{}: {} {}".format(case_index, girth, whole))
    return "\n".join(lines) + "\n"


def brute_case(size, edges):
    adjacency = [[] for _ in range(size + 1)]
    for a, b in edges:
        adjacency[a].append(b)
        adjacency[b].append(a)
    best = None

    for start in range(1, size + 1):
        def walk(path):
            nonlocal best
            here = path[-1]
            for nxt in adjacency[here]:
                if nxt < start:
                    continue
                if nxt == start:
                    if len(path) >= 3:
                        candidate = tuple(path)
                        if (best is None or len(candidate) < len(best) or
                                (len(candidate) == len(best) and candidate < best)):
                            best = candidate
                elif nxt not in path:
                    walk(path + [nxt])
        walk([start])
    return best


def brute(text):
    lines = []
    for case_index, (size, edges, adjacency) in enumerate(parse(text), 1):
        best = brute_case(size, edges)
        if best is None:
            lines.append("Case #{}: -1".format(case_index))
        else:
            whole = " ".join(str(v) for v in list(best) + [best[0]])
            lines.append("Case #{}: {} {}".format(case_index, len(best), whole))
    return "\n".join(lines) + "\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1\n2 1\n1 2\n") == "Case #1: -1\n"
assert oracle("1\n3 3\n1 2\n2 3\n1 3\n") == "Case #1: 3 1 2 3 1\n"
assert oracle("1\n4 4\n1 2\n2 3\n3 4\n1 4\n") == "Case #1: 4 1 2 3 4 1\n"
assert oracle("1\n5 5\n1 2\n2 3\n3 4\n4 5\n1 5\n") == "Case #1: 5 1 2 3 4 5 1\n"

for seed in range(40):
    rng = random.Random(seed)
    size = rng.randint(2, 7)
    edges = []
    for a in range(1, size + 1):
        for b in range(a + 1, size + 1):
            if rng.random() < 0.45:
                edges.append((a, b))
    pieces = ["1", "{} {}".format(size, len(edges))]
    pieces.extend("{} {}".format(a, b) for a, b in edges)
    tiny = "\n".join(pieces) + "\n"
    assert oracle(tiny) == brute(tiny), tiny


def write(name, cases):
    pieces = [str(len(cases))]
    for size, edges in cases:
        pieces.append("{} {}".format(size, len(edges)))
        pieces.extend("{} {}".format(a, b) for a, b in edges)
    input_text = "\n".join(pieces) + "\n"
    (ROOT / "in" / (name + ".txt")).write_text(input_text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(input_text))


def build():
    write("2_edges", [
        (2, [(1, 2)]),
        (3, [(1, 2), (2, 3)]),
        (3, [(1, 2), (2, 3), (1, 3)]),
        (6, [(1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (1, 6)]),
        (6, [(1, 2), (1, 3), (1, 4), (2, 3), (3, 4), (2, 4)]),
    ])
    ring = [(i, i + 1) for i in range(1, 200)] + [(1, 200)]
    chords = [(1, 3), (2, 4), (1, 5), (7, 9), (100, 102)]
    write("3_wide", [(200, ring), (200, ring + chords)])
    rng = random.Random(2026)
    random_cases = []
    for _ in range(40):
        size = rng.randint(2, 60)
        density = rng.choice([0.03, 0.08, 0.2])
        edges = [(a, b) for a in range(1, size + 1)
                 for b in range(a + 1, size + 1) if rng.random() < density]
        random_cases.append((size, edges))
    write("4_random", random_cases)
    big_rng = random.Random(77)
    big = [(a, b) for a in range(1, 201)
           for b in range(a + 1, 201) if big_rng.random() < 0.06]
    write("5_io", [(200, big), (200, ring + chords), (180, ring[:179])])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    (4, [(1, 2), (1, 3), (1, 4)]),
    (4, [(1, 2), (2, 3), (3, 4), (1, 4), (2, 4)]),
])
build()
