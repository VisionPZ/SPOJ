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
        limit = int(tokens[pos]); pos += 1
        rows = []
        for _ in range(count):
            rows.append(tokens[pos]); pos += 1
        history = [[0] * count for _ in range(3)]
        history[2][0] = 1
        total = 0
        for step in range(limit + 1):
            total = (total + history[2][1]) % MOD
            following = [0] * count
            for source in range(count):
                for target in range(count):
                    mark = rows[source][target]
                    if mark != '-':
                        age = 3 - int(mark)
                        following[target] = (following[target] + history[age][source]) % MOD
            history = [history[1], history[2], following]
        lines.append("Case #%d: %d" % (case_index + 1, total))
    return "\n".join(lines) + "\n"


SAMPLE = """3
2 9
-3
3-
5 4
--123
--123
11---
22---
33---
3 100
-21
2-3
13-
"""
SAMPLE_OUT = """Case #1: 2
Case #2: 4
Case #3: 924247768
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 1\n-1\n1-\n") == "Case #1: 1\n"
assert oracle("1\n2 3\n-3\n3-\n") == "Case #1: 1\n"
assert oracle("1\n2 9\n-3\n3-\n") == "Case #1: 2\n"
assert oracle("1\n3 1\n-1-\n1--\n---\n") == "Case #1: 1\n"
assert oracle("1\n3 1\n---\n---\n---\n") == "Case #1: 0\n"


def write(name, cases):
    text = str(len(cases)) + "\n"
    for count, limit, rows in cases:
        text += "%d %d\n" % (count, limit)
        for row in rows:
            text += row + "\n"
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(text))


def random_case(rng, count, limit):
    rows = [['-'] * count for _ in range(count)]
    for source in range(count):
        for target in range(source + 1, count):
            mark = rng.choice(['-', '-', '1', '2', '3'])
            rows[source][target] = mark
            rows[target][source] = mark
    return count, limit, ["".join(row) for row in rows]


def build():
    write("2_edges", [
        (2, 1, ["-1", "1-"]),
        (2, 5, ["--", "--"]),
        (3, 6, ["-12", "1-3", "23-"]),
    ])
    rng = random.Random(20261126)
    write("3_wide", [random_case(rng, 5, 120) for _ in range(10)])
    write("4_random", [random_case(rng, rng.randint(2, 5), rng.randint(1, 60)) for _ in range(10)])
    write("5_io", [random_case(rng, 5, 100) for _ in range(10)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
