#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "2 3\n"
SAMPLE_OUT = "1\n"


def oracle(text):
    tokens = text.split()
    left = int(tokens[0])
    right = int(tokens[1])
    span = right - left + 1
    return str(span // 2 + (1 if span % 2 and left % 2 else 0)) + "\n"


def brute(left, right):
    return sum(1 for value in range(left, right + 1) if value % 2)


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("0 0\n") == "0\n"
assert oracle("1 1\n") == "1\n"
assert oracle("0 9\n") == "5\n"
for left in range(0, 16):
    for right in range(left, 16):
        assert oracle(f"{left} {right}\n") == f"{brute(left, right)}\n"


def write(name, pairs):
    input_text = "".join(f"{left} {right}\n" for left, right in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


write("1_sample", [(2, 3)])
write("2_edges", [(0, 0), (0, 1), (1, 1), (2, 2), (7, 7),
                  (0, 100000000), (99999999, 100000000)])
write("3_wide", [(0, 100000000), (1, 99999999), (50000000, 50000001)] * 40)
random.seed(2026)


def random_pair():
    return tuple(sorted((random.randint(0, 100000000),
                         random.randint(0, 100000000))))


write("4_random", [random_pair() for _ in range(400)])
write("5_io", [random_pair() for _ in range(20000)])

print("trace: [2,3] span 2, even span, even start -> " + SAMPLE_OUT.strip())
