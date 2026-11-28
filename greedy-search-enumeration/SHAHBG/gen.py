#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CAPACITY = 50010


def oracle(text):
    tokens = [int(value) for value in text.split()]
    people_count = tokens[0]
    positions = tokens[1:1 + people_count]
    parent = list(range(CAPACITY))
    occupied = [False] * CAPACITY
    groups = 0
    answers = []
    for position in positions:
        occupied[position] = True
        groups += 1
        for neighbor in (position - 1, position + 1):
            if 1 <= neighbor < CAPACITY and occupied[neighbor]:
                root_current = position
                while parent[root_current] != root_current:
                    parent[root_current] = parent[parent[root_current]]
                    root_current = parent[root_current]
                root_neighbor = neighbor
                while parent[root_neighbor] != root_neighbor:
                    parent[root_neighbor] = parent[parent[root_neighbor]]
                    root_neighbor = parent[root_neighbor]
                if root_current != root_neighbor:
                    parent[root_neighbor] = root_current
                    groups -= 1
        answers.append(str(groups))
    return "\n".join(answers) + "\nJustice\n"


SAMPLE = "6\n2 4 3 6 7 5\n"
SAMPLE_OUT = "1\n2\n1\n2\n2\n1\nJustice\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2\n") == "1\nJustice\n"
assert oracle("3\n1 2 3\n") == "1\n1\n1\nJustice\n"
assert oracle("2\n1 3\n") == "1\n2\nJustice\n"
assert oracle("5\n10 20 30 15 25\n") == "1\n2\n3\n4\n5\nJustice\n"


def write(name, positions):
    input_text = str(len(positions)) + "\n" + " ".join(str(value) for value in positions) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [1, 3, 2, 20000, 19999, 10000])
    write("3_wide", list(range(1, 20001)))
    rng = random.Random(20261126)
    write("4_random", rng.sample(range(1, 20001), 3000))
    write("5_io", rng.sample(range(1, 20001), 20000))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [2, 4, 3, 6, 7, 5])
build()
