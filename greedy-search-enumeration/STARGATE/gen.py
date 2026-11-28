#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    adjacency = {}
    answers = []
    for raw_line in text.splitlines():
        parts = raw_line.split()
        if not parts:
            continue
        command = parts[0].upper()
        numbers = list(map(int, parts[1:]))
        if command == "D":
            adjacency = {}
            continue
        source, destination = numbers[0], numbers[1]
        if len(numbers) == 2:
            pairs = [(source, destination)]
        elif len(numbers) == 3:
            pairs = [(source, destination + offset) for offset in range(numbers[2])]
        elif len(numbers) == 4:
            pairs = [(source, destination + offset * numbers[3]) for offset in range(numbers[2])]
        else:
            pairs = [(source + offset * numbers[4], destination + offset * numbers[3])
                     for offset in range(numbers[2])]
        if command == "C":
            for first, second in pairs:
                adjacency.setdefault(first, set()).add(second)
                adjacency.setdefault(second, set()).add(first)
            continue
        component = {}
        for start in list(adjacency):
            if start in component:
                continue
            component[start] = start
            stack = [start]
            while stack:
                node = stack.pop()
                for neighbor in adjacency.get(node, ()):
                    if neighbor not in component:
                        component[neighbor] = start
                        stack.append(neighbor)
        connected = sum(1 for first, second in pairs
                        if component.get(first, first) == component.get(second, second))
        answers.append(f"{connected} {len(pairs) - connected}")
    return "\n".join(answers) + "\n" if answers else ""


SAMPLE_ONE = """d 5
C 1 3
D 20
q 1 3
c 1 10 10
Q 1 2 18 1 1
"""
SAMPLE_ONE_OUT = """0 1
9 9
"""
SAMPLE_TWO = """d 5
d 1
q 1 1
d 10
q 1 6 5 1 1
c 1 2 9
q 1 6 5 1 1
"""
SAMPLE_TWO_OUT = """1 0
0 5
5 0
"""
assert oracle(SAMPLE_ONE) == SAMPLE_ONE_OUT
assert oracle(SAMPLE_TWO) == SAMPLE_TWO_OUT
assert oracle("D 2\nQ 1 2\nC 1 2\nQ 1 2\n") == "0 1\n1 0\n"
assert oracle("D 4\nQ 1 1 3 1 1\n") == "3 0\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", SAMPLE_TWO)
    write("3_wide", "D 200\nC 1 100 10 3\nQ 1 100 10 3\nC 5 5 4 0 2\n"
          "Q 5 5 4 0 2\nQ 1 100 5 7\n")
    rng = random.Random(20261126)
    commands = ["D 120"]
    for _ in range(200):
        command = rng.choice("CQ")
        count = rng.randint(1, 6)
        step = rng.randint(1, 4)
        if rng.random() < 0.5:
            commands.append(f"{command} {rng.randint(1, 120)} {rng.randint(1, 120)}")
        else:
            source = rng.randint(1, 120 - (count - 1) * step)
            destination = rng.randint(1, 120 - (count - 1) * step)
            commands.append(f"{command} {source} {destination} {count} {step}")
    write("4_random", "\n".join(commands) + "\n")
    io_lines = ["D 10", "C 1 2 9"]
    io_lines.extend(["Q 1 2 9 1 1"] * 100000)
    write("5_io", "\n".join(io_lines) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_ONE)
build()
