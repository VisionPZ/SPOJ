#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    values = [int(value) for value in text.split()]
    if not values:
        return []
    position = 0
    case_count = values[position]
    position += 1
    answers = []
    for _ in range(case_count):
        width, height, pass_count = values[position:position + 3]
        position += 3
        reverse = {}
        sites = set()
        forward_ok = True
        for _ in range(pass_count):
            start_x, start_y, end_x, end_y = values[position:position + 4]
            position += 4
            if end_x < start_x:
                forward_ok = False
            start = (start_x, start_y)
            end = (end_x, end_y)
            sites.add(start)
            sites.add(end)
            reverse.setdefault(end, set()).add(start)
        goal = (width, height // 2)
        reached = {goal}
        stack = [goal]
        while stack:
            here = stack.pop()
            for before in reverse.get(here, ()):
                if before not in reached:
                    reached.add(before)
                    stack.append(before)
        answers.append("Yes" if forward_ok and sites <= reached else "No")
    return answers


SAMPLE = """2

2 2 1
0 1 2 1

2 2 4
0 1 2 1
0 0 1 1
0 2 1 1
1 1 2 1

"""
SAMPLE_OUT = """Yes
Yes
"""
assert oracle(SAMPLE) == ["Yes", "Yes"]
assert oracle("1\n2 2 1\n0 1 1 1\n") == ["No"]
assert oracle("1\n2 2 1\n1 1 0 1\n") == ["No"]
assert oracle("1\n2 2 2\n0 1 2 1\n0 0 2 1\n") == ["Yes"]
assert oracle("1\n4 2 2\n0 1 4 1\n0 0 4 1\n") == ["Yes"]


def render(cases):
    blocks = [str(len(cases))]
    for width, height, passes in cases:
        blocks.append(f"{width} {height} {len(passes)}")
        for pass_values in passes:
            blocks.append(" ".join(str(value) for value in pass_values))
    return "\n".join(blocks) + "\n"


def write(name, cases):
    text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text("".join(line + "\n" for line in oracle(text)))


def build():
    write("2_edges", [
        (2, 2, [(0, 1, 2, 1)]),
        (2, 2, [(0, 1, 1, 1)]),
        (2, 2, [(1, 1, 0, 1)]),
        (4, 4, [(0, 2, 4, 2)]),
        (4, 4, [(0, 0, 4, 2), (0, 4, 4, 2)]),
    ])
    chain = [(index, 1, index + 1, 1) for index in range(0, 99)]
    write("3_wide", [(100, 100, chain), (100, 100, [(0, 0, 100, 50)])])
    rng = random.Random(20261126)
    cases = []
    for _ in range(8):
        width = rng.choice([2, 4, 10, 50])
        height = rng.choice([2, 4, 10, 50])
        passes = []
        for _ in range(30):
            start_x = rng.randint(0, width)
            end_x = min(width, start_x + rng.randint(0, 3))
            passes.append((start_x, rng.randint(0, height), end_x, rng.randint(0, height)))
        cases.append((width, height, passes))
    write("4_random", cases)
    io_cases = []
    for index in range(60):
        width = rng.choice([2, 4, 6])
        height = rng.choice([2, 4, 6])
        io_cases.append((width, height, [(index % width, index % height, width, height // 2)]))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
