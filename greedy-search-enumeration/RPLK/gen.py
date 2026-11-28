#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_case(piece_count, overlap, separator, max_steps, pieces):
    step_values = []
    for height, width in pieces:
        step_values.extend([height + separator] * (width // (overlap + 1)))
    step_values.sort(reverse=True)
    used = min(max_steps, len(step_values))
    return sum(step_values[:used])


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    cursor = 1
    lines = []
    for case_index in range(1, case_count + 1):
        piece_count = int(tokens[cursor])
        overlap = int(tokens[cursor + 1])
        separator = int(tokens[cursor + 2])
        max_steps = int(tokens[cursor + 3])
        cursor += 4
        pieces = []
        for _ in range(piece_count):
            pieces.append((int(tokens[cursor]), int(tokens[cursor + 1])))
            cursor += 2
        answer = oracle_case(piece_count, overlap, separator, max_steps, pieces)
        lines.append(f"Scenario #{case_index}: {answer}")
    return "\n".join(lines) + "\n"


SAMPLE = """3
5 1 1 3
6 2
5 10
4 20
3 15
1 1
3 1 0 5
3 15
2 20
1 60
2 1 1 25
15 10
12 10
"""
SAMPLE_OUT = """Scenario #1: 19
Scenario #2: 15
Scenario #3: 145
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1 0 1\n3 4\n") == "Scenario #1: 3\n"
assert oracle("1\n1 0 2 10\n4 5\n") == "Scenario #1: 30\n"
assert oracle("1\n1 2 1 100\n5 7\n") == "Scenario #1: 12\n"
assert oracle("1\n2 5 0 4\n3 1\n7 2\n") == "Scenario #1: 0\n"


def write(name, cases):
    chunks = [str(len(cases))]
    for piece_count, overlap, separator, max_steps, pieces in cases:
        chunks.append(f"{piece_count} {overlap} {separator} {max_steps}")
        chunks.extend(f"{height} {width}" for height, width in pieces)
    text = "\n".join(chunks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (1, 5, 0, 4, [(3, 1)]),
        (1, 0, 0, 1, [(1, 1000)]),
        (2, 3, 100000, 1, [(1000, 1000), (1, 1000)]),
        (3, 1, 0, 100, [(2, 2), (5, 4), (7, 6)]),
    ])
    wide_pieces = [(1000 - index % 1000, 1000 - index % 997) for index in range(100)]
    write("3_wide", [(100, 1, 100000, 10000, wide_pieces)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(30):
        piece_count = rng.randint(1, 8)
        pieces = [(rng.randint(1, 1000), rng.randint(1, 1000))
                  for _ in range(piece_count)]
        random_cases.append((piece_count, rng.randint(0, 5), rng.randint(0, 20),
                             rng.randint(1, 12), pieces))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(200):
        piece_count = rng.randint(1, 4)
        pieces = [(rng.randint(1, 100), rng.randint(1, 100))
                  for _ in range(piece_count)]
        io_cases.append((piece_count, rng.randint(0, 3), rng.randint(0, 10),
                         rng.randint(1, 10), pieces))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    (5, 1, 1, 3, [(6, 2), (5, 10), (4, 20), (3, 15), (1, 1)]),
    (3, 1, 0, 5, [(3, 15), (2, 20), (1, 60)]),
    (2, 1, 1, 25, [(15, 10), (12, 10)]),
])
build()
