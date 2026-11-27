#!/usr/bin/env python3
import random
from bisect import bisect_left
from pathlib import Path

ROOT = Path(__file__).resolve().parent
STMT_PATH = ROOT.parent / "stmts" / "SMPSEQ6.txt"
STATEMENT = STMT_PATH.read_text() if STMT_PATH.exists() else None

SAMPLES = [
    ("5 2\n-1 2 -1 1 -1\n3 -2 -1 1 2\n", "1 3 4 5\n"),
    ("6 4\n-1 2 2 2 2 -2\n3 -2 3 3 3 -1\n", "6\n"),
    ("6 0\n-1 2 10 12 6 -2\n2 -2 10 21 6 -1\n", "3 5\n"),
]


def oracle(text):
    values = [int(token) for token in text.split()]
    length = values[0]
    radius = values[1]
    left = values[2:2 + length]
    right = values[2 + length:2 + 2 * length]
    places = {}
    for index, value in enumerate(right):
        places.setdefault(value, []).append(index)
    chosen = []
    for index, value in enumerate(left):
        low = max(0, index - radius)
        high = min(length - 1, index + radius)
        candidates = places.get(value, [])
        probe = bisect_left(candidates, low)
        if probe < len(candidates) and candidates[probe] <= high:
            chosen.append(str(index + 1))
    return " ".join(chosen) + "\n"


for sample_input, sample_output in SAMPLES:
    if STATEMENT is not None:
        assert sample_input in STATEMENT
        assert sample_output in STATEMENT
    assert oracle(sample_input) == sample_output

assert oracle("2 0\n1 2\n1 2\n") == "1 2\n"
assert oracle("2 1\n1 1\n2 2\n") == "\n"
assert oracle("3 1\n7 8 9\n7 0 9\n") == "1 3\n"
assert oracle("4 3\n5 5 5 5\n0 0 0 0\n") == "\n"


def write(name, length, radius, left, right):
    input_text = (f"{length} {radius}\n" + " ".join(map(str, left)) + "\n"
                  + " ".join(map(str, right)) + "\n")
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace(length, radius, left, right):
    lines = []
    chosen = []
    for index, value in enumerate(left):
        low = max(0, index - radius)
        high = min(length - 1, index + radius)
        hit = None
        for candidate in range(low, high + 1):
            if right[candidate] == value:
                hit = candidate
                break
        if hit is None:
            lines.append(f"index {index + 1}: value {value}, window {low + 1}..{high + 1}, no match")
        else:
            chosen.append(str(index + 1))
            lines.append(f"index {index + 1}: value {value}, window {low + 1}..{high + 1}, match at {hit + 1}, emit {index + 1}")
    lines.append('answer "' + " ".join(chosen) + '"')
    return "\n".join(lines)


write("1_sample", 5, 2, [-1, 2, -1, 1, -1], [3, -2, -1, 1, 2])
write("2_edges", 100, 0, list(range(-50, 50)), list(range(-50, 50)))
write("3_wide", 100, 99, [-100 + 2 * i for i in range(100)],
      [100 - 2 * i for i in range(100)])
random.seed(2026)
write("4_random", 100, random.randrange(100),
      [random.randint(-100, 100) for _ in range(100)],
      [random.randint(-100, 100) for _ in range(100)])
write("5_io", 100, 50, [7] * 100, [7] * 100)

if __name__ == "__main__":
    print(trace(5, 2, [-1, 2, -1, 1, -1], [3, -2, -1, 1, 2]))
