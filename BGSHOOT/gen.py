#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    animal_count = tokens[cursor]
    cursor += 1
    starts = []
    ends = []
    for _ in range(animal_count):
        starts.append(tokens[cursor])
        ends.append(tokens[cursor + 1])
        cursor += 2
    query_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(query_count):
        left = tokens[cursor]
        right = tokens[cursor + 1]
        cursor += 2
        candidates = [left]
        for start in starts:
            if left <= start <= right:
                candidates.append(start)
        best = 0
        for moment in candidates:
            alive = 0
            for start, end in zip(starts, ends):
                if start <= moment <= end:
                    alive += 1
            if alive > best:
                best = alive
        answers.append(str(best))
    return "\n".join(answers) + "\n"


SAMPLE = """4
1 2
2 3
4 5
6 7
4
1 5
2 3
4 7
5 7
"""
SAMPLE_OUT = """2
2
1
1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n5 5\n1\n5 5\n") == "1\n"
assert oracle("2\n1 3\n2 3\n1\n3 4\n") == "2\n"
assert oracle("3\n1 2\n2 3\n3 4\n1\n1 1\n") == "1\n"


def write(name, intervals, queries):
    lines = [str(len(intervals))]
    for start, end in intervals:
        lines.append(f"{start} {end}")
    lines.append(str(len(queries)))
    for left, right in queries:
        lines.append(f"{left} {right}")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1), (1, 5), (5, 5), (7, 9)],
          [(1, 1), (1, 2), (5, 5), (6, 10), (10, 10)])
    wide = [(1_000_000_000 - offset, 1_000_000_000 + offset)
            for offset in range(0, 100)]
    wide += [(10 * offset, 10 * offset + 3) for offset in range(1, 51)]
    write("3_wide", wide, [(999_999_900, 1_000_000_100),
                           (1, 500), (10, 40), (400, 600)])
    rng = random.Random(20261126)
    random_intervals = []
    for _ in range(400):
        left = rng.randint(1, 5000)
        random_intervals.append((left, left + rng.randint(0, 200)))
    random_queries = []
    for _ in range(300):
        left = rng.randint(1, 5000)
        random_queries.append((left, left + rng.randint(0, 500)))
    write("4_random", random_intervals, random_queries)
    io_intervals = [(offset * 7, offset * 7 + 50) for offset in range(1, 501)]
    io_queries = [(offset * 3, offset * 3 + 17) for offset in range(1, 501)]
    write("5_io", io_intervals, io_queries)
    big = [(offset * 11, offset * 11 + 1000) for offset in range(1, 100001)]
    big_queries = [(offset * 7, offset * 7 + 500) for offset in range(1, 100001)]
    lines = [str(len(big))]
    lines += [f"{start} {end}" for start, end in big]
    lines.append(str(len(big_queries)))
    lines += [f"{left} {right}" for left, right in big_queries]
    Path("/tmp/BGSHOOT_big.txt").write_text("\n".join(lines) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
