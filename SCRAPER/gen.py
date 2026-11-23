#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent
POSSIBLE = "It is possible to move the furniture."
IMPOSSIBLE = "The furniture cannot be moved."


def floor_b_oracle(top_floor, elevators, origin, target):
    if origin == target:
        return True
    lines = []
    line_sets = []
    for step, start in elevators:
        line = list(range(start, top_floor, step))
        lines.append(line)
        line_sets.append(set(line))
    queue = deque([origin])
    seen = {origin}
    while queue:
        floor = queue.popleft()
        if floor == target:
            return True
        for line_index, line in enumerate(lines):
            if floor not in line_sets[line_index]:
                continue
            for neighbor in line:
                if neighbor not in seen:
                    seen.add(neighbor)
                    queue.append(neighbor)
    return False


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(count):
        top = int(tokens[cursor]); cursor += 1
        elevator_count = int(tokens[cursor]); cursor += 1
        origin = int(tokens[cursor]); cursor += 1
        target = int(tokens[cursor]); cursor += 1
        elevators = []
        for _ in range(elevator_count):
            step = int(tokens[cursor]); cursor += 1
            start = int(tokens[cursor]); cursor += 1
            elevators.append((step, start))
        answers.append(POSSIBLE if floor_b_oracle(top, elevators, origin, target)
                       else IMPOSSIBLE)
    return "\n".join(answers) + "\n" if answers else ""


def format_case(top, origin, target, elevators):
    parts = [f"{top} {len(elevators)} {origin} {target}"]
    for step, start in elevators:
        parts.append(f"{step} {start}")
    return "\n".join(parts) + "\n"


def write(name, input_text, expected=None):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    result = oracle(input_text) if expected is None else expected
    (ROOT / "out" / f"{name}.out").write_text(result)


SAMPLE_IN = """2
22 4 0 6
3 2
4 7
13 6
10 0
1000 2 500 777
2 0
2 1
"""
assert oracle(SAMPLE_IN) == POSSIBLE + "\n" + IMPOSSIBLE + "\n"


def build():
    random.seed(314159)
    edges = []
    edges.append((50, 7, 7, []))
    edges.append((50, 3, 9, [(5, 3)]))
    edges.append((50, 4, 11, [(4, 0), (4, 1)]))
    edges.append((50, 2, 3, [(3, 0), (2, 1), (7, 3)]))
    edges.append((50, 10, 11, [(10, 0)]))
    write("2_edges", str(len(edges)) + "\n" +
          "".join(format_case(*case) for case in edges))

    wide = []
    wide.append((50000000, 0, 49999998, [(3, 0), (6, 0), (2, 0)]))
    wide.append((50000000, 1, 49999998, [(2, 0), (2, 1)]))
    wide.append((50000000, 5, 5, []))
    wide.append((49999999, 0, 21, [(6, 0), (9, 3), (15, 6)]))
    wide_expected = "\n".join([
        POSSIBLE, IMPOSSIBLE, POSSIBLE, POSSIBLE,
    ]) + "\n"
    write("3_wide", str(len(wide)) + "\n" +
          "".join(format_case(*case) for case in wide), wide_expected)

    random_cases = []
    for _ in range(24):
        top = random.randint(20, 2500)
        origin = random.randint(0, top - 1)
        target = random.randint(0, top - 1)
        elevators = []
        for _ in range(random.randint(1, 8)):
            step = random.randint(1, 60)
            start = random.randint(0, top - 1)
            elevators.append((step, start))
        random_cases.append((top, origin, target, elevators))
    write("4_random", str(len(random_cases)) + "\n" +
          "".join(format_case(*case) for case in random_cases))

    io_cases = []
    for index in range(2500):
        top = 1000
        origin = index % 1000
        target = (index * 37 + 11) % 1000
        elevators = [(3, index % 3), (5, index % 5), (7, index % 7)]
        io_cases.append((top, origin, target, elevators))
    write("5_io", str(len(io_cases)) + "\n" +
          "".join(format_case(*case) for case in io_cases))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_IN)
build()
