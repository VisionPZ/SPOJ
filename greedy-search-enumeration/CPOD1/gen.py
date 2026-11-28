#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "2\n5\n-2 -1 0 1 2\n2\n1 10\n"
SAMPLE_OUT = "1\n9\n"


def brute_closest(values):
    best = None
    size = len(values)
    for i in range(size):
        for j in range(i + 1, size):
            gap = abs(values[i] - values[j])
            if best is None or gap < best:
                best = gap
            if best == 0:
                return 0
    return best


def sorted_closest(values):
    ordered = sorted(values)
    best = ordered[1] - ordered[0]
    for i in range(1, len(ordered) - 1):
        gap = ordered[i + 1] - ordered[i]
        if gap < best:
            best = gap
            if best == 0:
                return 0
    return best


def closest_gap(values):
    if len(values) <= 2500:
        return brute_closest(values)
    return sorted_closest(values)


def oracle(input_text):
    tokens = input_text.split()
    case_count = int(tokens[0])
    scan_pos = 1
    lines = []
    for _ in range(case_count):
        element_count = int(tokens[scan_pos])
        scan_pos += 1
        values = [int(t) for t in tokens[scan_pos:scan_pos + element_count]]
        scan_pos += element_count
        lines.append(str(closest_gap(values)))
    return "\n".join(lines) + "\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1\n2\n5 5\n") == "0\n"
assert oracle("1\n3\n-10000000000 10000000000 0\n") == "10000000000\n"
assert oracle("1\n4\n7 3 12 3\n") == "0\n"


def write(name, cases):
    parts = [str(len(cases))]
    for values in cases:
        parts.append(str(len(values)))
        parts.append(" ".join(str(v) for v in values))
    input_text = "\n".join(parts) + "\n"
    (ROOT / "in" / ("%s.txt" % name)).write_text(input_text)
    (ROOT / "out" / ("%s.out" % name)).write_text(oracle(input_text))


def build():
    write("2_edges", [
        [1, 10], [5, 5], [-20000000000, 20000000000], [0, -1],
        [1, 2, 3], [10, 10, 10], [-5, 5, 0], [2, 4, 8, 16],
    ])
    rng = random.Random(20190120)
    wide_cases = []
    for _ in range(2):
        wide_cases.append([rng.randint(-20000000000, 20000000000) for _ in range(100000)])
    write("3_wide", wide_cases)
    random_cases = []
    for _ in range(10):
        random_cases.append([rng.randint(-20000000000, 20000000000) for _ in range(2000)])
    write("4_random", random_cases)
    io_cases = []
    for _ in range(10):
        io_cases.append([rng.randint(-20000000000, 20000000000) for _ in range(100000)])
    write("5_io", io_cases)


if __name__ == "__main__":
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [[-2, -1, 0, 1, 2], [1, 10]])
    build()
