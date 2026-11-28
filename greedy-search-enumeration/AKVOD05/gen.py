#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    position = 1
    answers = []
    for _ in range(case_count):
        target = tokens[position]
        window = tokens[position + 1]
        position += 2
        sequence = tokens[position:position + window]
        position += window
        if target <= window:
            answers.append(sequence[target - 1])
            continue
        seen = {}
        while len(sequence) < target:
            state = tuple(sequence[-window:])
            if state in seen:
                start = seen[state]
                period = len(sequence) - start
                index = start + (target - 1 - start) % period
                answers.append(sequence[index])
                break
            seen[state] = len(sequence)
            present = set(state)
            candidate = 0
            while candidate in present:
                candidate += 1
            sequence.append(candidate)
        else:
            answers.append(sequence[-1])
    return "".join(str(answer) + "\n" for answer in answers)


SAMPLE = """2
7 4
0 4 3 2
8 5
4 7 2 3 0
"""
SAMPLE_OUT = """4
5
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n7 4\n0 4 3 2\n") == "4\n"
assert oracle("1\n8 5\n4 7 2 3 0\n") == "5\n"
assert oracle("1\n5 1\n0\n") == "0\n"
assert oracle("1\n6 1\n0\n") == "1\n"
assert oracle("1\n100000000 3\n0 1 2\n") == "3\n"


def write(name, cases):
    lines = [str(len(cases))]
    for target, window, values in cases:
        lines.append(f"{target} {window}")
        lines.append(" ".join(str(value) for value in values))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (1, 1, [7]),
        (2, 3, [100000000, 100000000, 5]),
        (3, 2, [0, 0]),
        (4, 4, [9, 9, 9, 9]),
        (100000000, 1, [1]),
    ])
    rng = random.Random(20261126)
    wide = [rng.randint(0, 100000000) for _ in range(60)]
    write("3_wide", [(100000000, 60, wide)])
    random_cases = []
    for _ in range(5):
        window = rng.randint(1, 30)
        values = [rng.randint(0, 100000000) for _ in range(window)]
        random_cases.append((rng.randint(window + 1, 100000000), window, values))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(10):
        window = rng.randint(1, 8)
        values = [rng.randint(0, 40) for _ in range(window)]
        io_cases.append((rng.randint(window + 1, 100000000), window, values))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(7, 4, [0, 4, 3, 2]), (8, 5, [4, 7, 2, 3, 0])])
build()
