#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(intervals):
    if any(interval is None for interval in intervals):
        return "-1\n"
    ordered = sorted(intervals, key=lambda pair: pair[1])
    chosen = []
    last_edge = -1
    for left, right in ordered:
        if last_edge < left:
            last_edge = right
            chosen.append(right)
    chosen.sort()
    if not chosen:
        return "0\n\n"
    return str(len(chosen)) + "\n" + " ".join(str(value) for value in chosen) + "\n"


def encode(intervals, set_count):
    chunks = [f"{len(intervals)} {set_count}"]
    for edge in range(set_count):
        members = [index for index, interval in enumerate(intervals)
                   if interval is not None and interval[0] <= edge <= interval[1]]
        chunks.append(str(len(members)))
        if members:
            chunks.append(" ".join(str(member) for member in members))
    return "\n".join(chunks) + "\n"


SAMPLE = """3 4
0
2
2 1
2
1 0
0
"""
SAMPLE_OUT = """2
1 2
"""
SAMPLE_INTERVALS = [(2, 2), (1, 2), (1, 1)]
assert oracle(SAMPLE_INTERVALS) == SAMPLE_OUT
assert oracle([(0, 0)]) == "1\n0\n"
assert oracle([(0, 3), (1, 1)]) == "1\n1\n"
assert oracle([(0, 0), (2, 2), (0, 2)]) == "2\n0 2\n"
assert oracle([(0, 0), None]) == "-1\n"


def write(name, intervals, set_count):
    text = encode(intervals, set_count)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(intervals))


def build():
    write("2_edges", [(0, 0), (2, 2), (0, 2), (4, 4)], 6)
    write("3_wide", [(index, index) for index in range(300)], 300)
    rng = random.Random(20261126)
    intervals = [(edge, edge) for edge in range(60)]
    for _ in range(40):
        left = rng.randrange(60)
        right = min(left + rng.randint(0, 8), 59)
        intervals.append((left, right))
    rng.shuffle(intervals)
    intervals.sort(key=lambda pair: pair[0])
    write("4_random", intervals, 60)
    intervals = [(index, min(index + 1, 299)) for index in range(300)]
    write("5_io", intervals, 300)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
