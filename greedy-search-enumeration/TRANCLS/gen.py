#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for case_number in range(1, case_count + 1):
        pair_count = tokens[cursor]
        cursor += 1
        adjacency = [set() for _ in range(pair_count)]
        original = set()
        for _ in range(pair_count):
            start = tokens[cursor]
            end = tokens[cursor + 1]
            cursor += 2
            adjacency[start].add(end)
            original.add((start, end))
        closure = set()
        for start in range(pair_count):
            seen = set()
            stack = [start]
            while stack:
                vertex = stack.pop()
                for neighbor in adjacency[vertex]:
                    if neighbor not in seen:
                        seen.add(neighbor)
                        stack.append(neighbor)
            for end in seen:
                closure.add((start, end))
        answers.append(f"Case #{case_number}: {len(closure - original)}")
    return "\n".join(answers) + "\n"


SAMPLE = """3
4
0 1
1 2
2 3
1 3
2
0 1
1 0
1
0 0
"""
SAMPLE_OUT = """Case #1: 2
Case #2: 2
Case #3: 0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2\n0 1\n0 1\n") == "Case #1: 0\n"
assert oracle("1\n3\n0 1\n1 2\n2 2\n") == "Case #1: 1\n"
assert oracle("1\n4\n0 1\n1 0\n2 3\n3 2\n") == "Case #1: 4\n"


def write(name, cases):
    parts = [str(len(cases))]
    for pairs in cases:
        parts.append(str(len(pairs)))
        for start, end in pairs:
            parts.append(f"{start} {end}")
    input_text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [[(0, 0)], [(0, 1), (0, 1), (1, 0)],
                      [(0, 1), (1, 2), (2, 0)]])
    rng = random.Random(20261202)
    write("3_wide", [[(rng.randrange(40), rng.randrange(40)) for _ in range(40)]
                     for _ in range(4)])
    random_cases = []
    for _ in range(40):
        pair_count = rng.randint(1, 20)
        random_cases.append([(rng.randrange(pair_count), rng.randrange(pair_count))
                             for _ in range(pair_count)])
    write("4_random", random_cases)
    write("5_io", [[(rng.randrange(30), rng.randrange(30))
                    for _ in range(30)] for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
