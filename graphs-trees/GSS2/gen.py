#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    scores = [int(value) for value in tokens[cursor:cursor + count]]
    cursor += count
    query_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(query_count):
        left = int(tokens[cursor])
        right = int(tokens[cursor + 1])
        cursor += 2
        best = 0
        for start in range(left - 1, right):
            seen = set()
            total = 0
            for end in range(start, right):
                value = scores[end]
                if value not in seen:
                    seen.add(value)
                    total += value
                if total > best:
                    best = total
        answers.append(str(best))
    return "\n".join(answers) + "\n"


SAMPLE = """9
4 -2 -2 3 -1 -4 2 2 -6
3
1 2
1 5
4 9
"""
SAMPLE_OUT = """4
5
3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n5\n1\n1 1\n") == "5\n"
assert oracle("3\n-1 -2 -3\n1\n1 3\n") == "0\n"
assert oracle("4\n2 2 2 2\n2\n1 4\n2 3\n") == "2\n2\n"


def write(name, scores, queries):
    lines = [str(len(scores))]
    lines.append(" ".join(str(value) for value in scores))
    lines.append(str(len(queries)))
    for left, right in queries:
        lines.append(f"{left} {right}")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", [0, 0, 0, 0, 0],
          [(1, 5), (2, 4), (3, 3)])
    write("3_wide", [100000, -100000] * 15,
          [(1, 30), (2, 29), (5, 20), (12, 12)])
    all_queries = []
    for count in (25, 40):
        scores = [rng.randint(-100000, 100000) for _ in range(count)]
        for _ in range(20):
            left = rng.randint(1, count)
            right = rng.randint(left, count)
            all_queries.append((left, right))
        write("4_random", scores, all_queries[-20:])
    io_queries = []
    for _ in range(120):
        left = rng.randint(1, 30)
        right = rng.randint(left, 30)
        io_queries.append((left, right))
    write("5_io", [rng.randint(-1000, 1000) for _ in range(30)], io_queries)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
sample_scores = [4, -2, -2, 3, -1, -4, 2, 2, -6]
sample_queries = [(1, 2), (1, 5), (4, 9)]
write("1_sample", sample_scores, sample_queries)
build()
