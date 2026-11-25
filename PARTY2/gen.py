#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def parse(text):
    tokens = text.split()
    cursor = 0
    cases = []
    while cursor < len(tokens):
        killer_count = int(tokens[cursor]); cursor += 1
        sighting_count = int(tokens[cursor]); cursor += 1
        edges = []
        for _ in range(sighting_count):
            source = int(tokens[cursor]); cursor += 1
            target = int(tokens[cursor]); cursor += 1
            edges.append((source - 1, target - 1))
        cases.append((killer_count, edges))
    return cases


def oracle_case(killer_count, edges):
    outgoing = [[] for _ in range(killer_count)]
    incoming = [[] for _ in range(killer_count)]
    for source, target in edges:
        outgoing[source].append(target)
        incoming[target].append(source)
    valid = []
    for group_count in range(3, killer_count + 1):
        levels = [-1] * killer_count
        consistent = True
        for start in range(killer_count):
            if levels[start] != -1:
                continue
            levels[start] = 0
            stack = [start]
            while stack and consistent:
                current = stack.pop()
                for target in outgoing[current]:
                    expected = (levels[current] + 1) % group_count
                    if levels[target] == -1:
                        levels[target] = expected
                        stack.append(target)
                    elif levels[target] != expected:
                        consistent = False
                        break
                if not consistent:
                    break
                for source in incoming[current]:
                    expected = (levels[current] - 1) % group_count
                    if levels[source] == -1:
                        levels[source] = expected
                        stack.append(source)
                    elif levels[source] != expected:
                        consistent = False
                        break
        if consistent:
            valid.append(group_count)
    if not valid:
        return "-1 -1"
    return f"{max(valid)} {min(valid)}"


def oracle(text):
    return "\n".join(oracle_case(killer_count, edges)
                     for killer_count, edges in parse(text)) + "\n"


SAMPLE = """6 5
1 2
2 3
3 4
4 1
3 5
3 3
1 2
2 1
2 3
"""
SAMPLE_OUT = """4 4
-1 -1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_case(5, [(0, 1), (1, 2)]) == "5 3"
assert oracle_case(1, [(0, 0)]) == "-1 -1"
assert oracle_case(2, [(0, 1), (1, 0)]) == "-1 -1"
assert oracle_case(3, [(0, 1), (1, 2), (2, 0)]) == "3 3"
assert oracle_case(6, [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]) == "6 3"


def encode_case(killer_count, edges):
    lines = [f"{killer_count} {len(edges)}"]
    for source, target in edges:
        lines.append(f"{source + 1} {target + 1}")
    return "\n".join(lines) + "\n"


def write(name, cases):
    text = "".join(encode_case(killer_count, edges) for killer_count, edges in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    edges_cases = [
        (5, [(0, 1), (1, 2)]),
        (1, [(0, 0)]),
        (2, [(0, 1), (1, 0)]),
        (3, [(0, 1), (1, 2), (2, 0)]),
        (4, [(0, 1), (1, 2), (2, 3), (3, 0)]),
        (6, [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]),
        (3, [(0, 1), (0, 2)]),
        (6, [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]),
        (4, [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2)]),
        (5, [(0, 1)]),
    ]
    write("2_edges", edges_cases)
    six_cycle = [(index, (index + 1) % 6) for index in range(6)]
    ten_cycle = [(index + 6, 6 + (index + 1) % 10) for index in range(10)]
    twelve_cycle = [(index + 16, 16 + (index + 1) % 12) for index in range(12)]
    wide_cases = [
        (60, six_cycle + ten_cycle + [(0, 3)] * 500),
        (60, twelve_cycle + six_cycle + [(3, 7)] * 500),
        (60, [(index, index + 1) for index in range(59)]),
    ]
    while len(wide_cases) < 10:
        wide_cases.append((30, [(index, (index + 3) % 30) for index in range(30)]))
    write("3_wide", wide_cases)
    rng = random.Random(20261125)
    random_cases = []
    for _ in range(10):
        killer_count = rng.randint(3, 30)
        sighting_count = rng.randint(1, 70)
        edges = [(rng.randrange(killer_count), rng.randrange(killer_count))
                 for _ in range(sighting_count)]
        random_cases.append((killer_count, edges))
    write("4_random", random_cases)
    io_cases = []
    for case_index in range(10):
        cycle_length = 3 + case_index
        io_cases.append((40, [(index, (index + 1) % cycle_length)
                              for index in range(cycle_length)]))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", parse(SAMPLE))
build()
