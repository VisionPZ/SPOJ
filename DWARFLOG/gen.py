#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    dwarf_count = int(tokens[0])
    request_count = int(tokens[1])
    positions = list(range(1, dwarf_count + 1))
    answers = []
    cursor = 2
    for _ in range(request_count):
        kind = int(tokens[cursor])
        first = int(tokens[cursor + 1])
        second = int(tokens[cursor + 2])
        cursor += 3
        if kind == 1:
            positions[first - 1], positions[second - 1] = positions[second - 1], positions[first - 1]
        else:
            span = positions[first - 1:second]
            answers.append("YES" if max(span) - min(span) == second - first else "NO")
    return "\n".join(answers) + "\n"


SAMPLE = """4 5
2 2 3
2 2 4
1 1 3
2 3 4
1 4 3
"""
SAMPLE_OUT = """YES
YES
NO
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2 3\n2 1 2\n1 1 2\n2 1 2\n") == "YES\nYES\n"
assert oracle("5 3\n1 1 5\n2 2 5\n2 1 3\n") == "YES\nNO\n"
assert oracle("3 2\n1 1 3\n2 1 3\n") == "YES\n"


def write(name, dwarf_count, requests):
    text = f"{dwarf_count} {len(requests)}\n"
    text += "\n".join(" ".join(str(value) for value in request) for request in requests) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 2, [[2, 1, 2], [1, 1, 2], [2, 1, 2]])
    rng = random.Random(20261126)
    wide_requests = []
    for _ in range(400):
        if rng.random() < 0.5:
            wide_requests.append([1, rng.randint(1, 500), rng.randint(1, 500)])
        else:
            first = rng.randint(1, 480)
            wide_requests.append([2, first, min(500, first + rng.randint(0, 20))])
    write("3_wide", 500, wide_requests)
    small_requests = []
    for _ in range(200):
        if rng.random() < 0.6:
            small_requests.append([1, rng.randint(1, 12), rng.randint(1, 12)])
        else:
            first = rng.randint(1, 10)
            small_requests.append([2, first, min(12, first + rng.randint(0, 3))])
    write("4_random", 12, small_requests)
    io_requests = []
    for index in range(3000):
        if index % 3 == 0:
            io_requests.append([1, rng.randint(1, 3000), rng.randint(1, 3000)])
        else:
            first = rng.randint(1, 2900)
            io_requests.append([2, first, min(3000, first + rng.randint(0, 100))])
    write("5_io", 3000, io_requests)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
