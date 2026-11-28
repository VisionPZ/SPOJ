#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while cursor < len(tokens):
        count = tokens[cursor]
        cursor += 1
        if count == 0:
            break
        particles = []
        for _ in range(count):
            particles.append((tokens[cursor], tokens[cursor + 1], tokens[cursor + 2]))
            cursor += 3
        farthest = 0
        for first in range(count):
            for second in range(first + 1, count):
                layer_gap = abs(particles[first][0] - particles[second][0])
                x_gap = abs(particles[first][1] - particles[second][1])
                y_gap = abs(particles[first][2] - particles[second][2])
                distance = layer_gap + x_gap + y_gap
                if distance > farthest:
                    farthest = distance
        answers.append(str(farthest))
    return "".join(answer + "\n" for answer in answers)


SAMPLE = """5
1 1 2
3 4 1
2 5 7
4 1 1
3 3 3
0
"""
SAMPLE_OUT = """12
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2\n1 1 1\n2 2 2\n0\n") == "3\n"
assert oracle("2\n1000000000 1 1\n1 1000000000 1000000000\n0\n") == "2999999997\n"
assert oracle("3\n1 1 1\n1 1 1\n1 1 1\n0\n") == "0\n"
assert oracle("2\n1 1 1\n2 2 2\n2\n5 5 5\n10 10 10\n0\n") == "3\n15\n"


def write(name, cases):
    lines = []
    for particles in cases:
        lines.append(str(len(particles)))
        for layer, coord_x, coord_y in particles:
            lines.append(f"{layer} {coord_x} {coord_y}")
    lines.append("0")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        [(1, 1, 1), (1, 1, 1)],
        [(1, 1, 1), (1000000000, 1000000000, 1000000000)],
        [(7, 3, 9), (7, 3, 9), (7, 3, 9), (7, 3, 9)],
    ])
    wide = []
    for index in range(100):
        if index % 2 == 0:
            wide.append((1, 1, 1000000000))
        else:
            wide.append((1000000000, 1000000000, 1))
    write("3_wide", [wide])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(6):
        count = rng.randint(2, 60)
        random_cases.append([
            (rng.randint(1, 1000000000), rng.randint(1, 1000000000),
             rng.randint(1, 1000000000))
            for _ in range(count)
        ])
    write("4_random", random_cases)
    io_cases = []
    for case_index in range(2000):
        io_cases.append([
            (case_index % 1000000000 + 1, 1000000000 - case_index % 999999999,
             case_index * 7 + 1),
            (case_index + 2, case_index + 3, case_index + 4),
        ])
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [[(1, 1, 2), (3, 4, 1), (2, 5, 7), (4, 1, 1), (3, 3, 3)]])
build()
