#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

FENWICK_SIZE = 60005
fenwick_tree = [0] * (FENWICK_SIZE + 2)
fenwick_touched = []


def fenwick_reset():
    for index in fenwick_touched:
        fenwick_tree[index] = 0
    fenwick_touched.clear()


def fenwick_update(index, value):
    while index <= FENWICK_SIZE:
        if value > fenwick_tree[index]:
            if fenwick_tree[index] == 0:
                fenwick_touched.append(index)
            fenwick_tree[index] = value
        index += index & -index


def fenwick_query(index):
    result = 0
    while index > 0:
        if fenwick_tree[index] > result:
            result = fenwick_tree[index]
        index -= index & -index
    return result


def oracle_case(points):
    fenwick_reset()
    order = sorted(points, key=lambda p: (p[1] - p[0], -(p[1] + p[0])))
    best = 0
    index = 0
    total = len(order)
    while index < total:
        up_value = order[index][1] - order[index][0]
        end = index
        while end < total and order[end][1] - order[end][0] == up_value:
            end += 1
        pending = []
        for k in range(index, end):
            x, y = order[k]
            down_value = y + x
            depth = 1 + fenwick_query(down_value)
            pending.append((down_value, depth))
            if depth > best:
                best = depth
        for down_value, depth in pending:
            fenwick_update(down_value + 1, depth)
        index = end
    return best


def brute_case(points):
    count = len(points)
    edges = [[] for _ in range(count)]
    for i in range(count):
        xi, yi = points[i]
        for j in range(count):
            xj, yj = points[j]
            if xi < xj and abs(yj - yi) <= xj - xi:
                edges[i].append(j)
    match = [-1] * count

    def augment(left, seen):
        for right in edges[left]:
            if seen[right]:
                continue
            seen[right] = True
            if match[right] == -1 or augment(match[right], seen):
                match[right] = left
                return True
        return False

    matched = 0
    for left in range(count):
        if augment(left, [False] * count):
            matched += 1
    return count - matched


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(count):
        n = int(tokens[cursor]); cursor += 1
        points = []
        for _ in range(n):
            x = int(tokens[cursor]); cursor += 1
            y = int(tokens[cursor]); cursor += 1
            points.append((x, y))
        answers.append(str(oracle_case(points)))
    return "\n".join(answers) + "\n"


def write(name, cases):
    chunks = [str(len(cases)) + "\n"]
    for case in cases:
        if len(chunks) > 1:
            chunks.append("\n")
        chunks.append(str(len(case)) + "\n")
        for x, y in case:
            chunks.append(f"{x} {y}\n")
    input_text = "".join(chunks)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE = [(1, 6), (10, 8), (1, 5), (2, 20), (4, 4), (6, 2)]
assert oracle_case(SAMPLE) == 3
assert brute_case(SAMPLE) == 3
assert oracle_case([(12345, 6789)]) == 1
assert oracle_case([(5, y) for y in range(10)]) == 10
assert oracle_case([(i, i) for i in range(10)]) == 1
assert oracle_case([(i, 30000 - i) for i in range(10)]) == 1

random.seed(2026)
for _ in range(400):
    n = random.randint(1, 8)
    points = set()
    while len(points) < n:
        points.add((random.randint(0, 8), random.randint(0, 8)))
    points = list(points)
    assert oracle_case(points) == brute_case(points)


def distinct_points(rng, count):
    points = set()
    while len(points) < count:
        points.add((rng.randint(0, 30000), rng.randint(0, 30000)))
    return list(points)


def build():
    write("2_edges", [
        [(12345, 6789)],
        [(5, y) for y in range(10)],
        [(i, i) for i in range(10)],
        [(i, 30000 - i) for i in range(10)],
        [(0, 0), (0, 1)],
        [(0, 0), (1, 2)],
        [(30000, 30000), (29999, 30000), (30000, 29999)],
        SAMPLE,
    ])

    wide_rng = random.Random(1301)
    write("3_wide", [
        [(0, y) for y in range(30000)],
        [(i, i) for i in range(30000)],
        distinct_points(wide_rng, 30000),
        [(i, 30000 - i) for i in range(30000)],
    ])

    random.seed(777)
    random_cases = []
    for _ in range(200):
        n = random.randint(1, 150)
        random_cases.append(distinct_points(random, n))
    write("4_random", random_cases)

    io_rng = random.Random(9090)
    io_cases = []
    for _ in range(150000):
        x = io_rng.randint(0, 30000)
        y = io_rng.randint(0, 30000)
        io_cases.append([(x, y)])
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [SAMPLE])
build()
