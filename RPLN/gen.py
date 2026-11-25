#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007


def oracle(text):
    tokens = text.split()
    pos = 0
    case_total = int(tokens[pos]); pos += 1
    lines = []
    for case_index in range(case_total):
        count = int(tokens[pos]); pos += 1
        queries = int(tokens[pos]); pos += 1
        size = 1
        while size < count:
            size *= 2
        tree = [10 ** 30] * (2 * size)
        for index in range(count):
            tree[size + index] = int(tokens[pos]); pos += 1
        for node in range(size - 1, 0, -1):
            tree[node] = min(tree[2 * node], tree[2 * node + 1])
        lines.append("Scenario #%d:" % (case_index + 1))
        for _ in range(queries):
            left = int(tokens[pos]); pos += 1
            right = int(tokens[pos]); pos += 1
            left += size - 1
            right += size - 1
            best = 10 ** 30
            while left <= right:
                if left % 2 == 1:
                    best = min(best, tree[left]); left += 1
                if right % 2 == 0:
                    best = min(best, tree[right]); right -= 1
                left //= 2
                right //= 2
            lines.append(str(best))
    return "\n".join(lines) + "\n"


SAMPLE = """2
5 3
1 2 3 4 5
1 5
1 3
2 4
5 3
1 -2 -4 3 -5
1 5
1 3
2 4
"""
SAMPLE_OUT = """Scenario #1:
1
1
2
Scenario #2:
-5
-4
-4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1\n-7\n1 1\n") == "Scenario #1:\n-7\n"
assert oracle("1\n4 2\n10 -20 30 -40\n1 4\n2 3\n") == "Scenario #1:\n-40\n-20\n"
assert oracle("1\n3 3\n0 0 0\n1 1\n2 2\n3 3\n") == "Scenario #1:\n0\n0\n0\n"
assert 10 ** 9 < MOD


def write(name, case_blocks):
    text = str(len(case_blocks)) + "\n"
    for scores, queries in case_blocks:
        text += "%d %d\n" % (len(scores), len(queries))
        text += " ".join(str(value) for value in scores) + "\n"
        for left, right in queries:
            text += "%d %d\n" % (left, right)
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(text))


def build():
    write("2_edges", [
        ([5], [(1, 1), (1, 1), (1, 1)]),
        ([1000000000, -1000000000], [(1, 2), (2, 2), (1, 1)]),
    ])
    rng = random.Random(20261126)
    scores = [rng.randint(-1000000000, 1000000000) for _ in range(1000)]
    queries = []
    for _ in range(1000):
        left = rng.randint(1, 1000)
        right = rng.randint(left, 1000)
        queries.append((left, right))
    write("3_wide", [(scores, queries)])
    scores = [rng.randint(-50, 50) for _ in range(60)]
    queries = []
    for _ in range(200):
        left = rng.randint(1, 60)
        right = rng.randint(left, 60)
        queries.append((left, right))
    write("4_random", [(scores, queries)])
    write("5_io", [([42], [(1, 1) for _ in range(100000)])])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
