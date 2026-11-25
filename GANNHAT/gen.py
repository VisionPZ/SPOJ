#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(points):
    answers = []
    for first_index, (first_x, first_y) in enumerate(points):
        best = None
        for second_index, (second_x, second_y) in enumerate(points):
            if first_index == second_index:
                continue
            distance = abs(first_x - second_x) + abs(first_y - second_y)
            if best is None or distance < best:
                best = distance
        answers.append(str(0 if best is None else best))
    return "\n".join(answers) + "\n"


def encode(points):
    lines = [str(len(points))]
    lines.extend(f"{x} {y}" for x, y in points)
    return "\n".join(lines) + "\n"


SAMPLE = [(0, 0), (0, 1), (1, 0), (1, 1)]
assert oracle(SAMPLE) == "1\n1\n1\n1\n"
assert encode(SAMPLE) == "4\n0 0\n0 1\n1 0\n1 1\n"
assert oracle([(5, 5), (5, 5)]) == "0\n0\n"
assert oracle([(0, 0), (10000000, 10000000)]) == "20000000\n20000000\n"
assert oracle([(0, 0), (3, 4), (10, 0), (3, 3)]) == "6\n1\n10\n1\n"


def write(name, points):
    text = encode(points)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(points))


def build():
    rng = random.Random(20261126)
    write("2_edges", [(0, 0)])
    grid = [(x * 37, y * 53) for x in range(6) for y in range(6)]
    write("3_wide", grid[:36])
    write("4_random", [(rng.randint(0, 10**7), rng.randint(0, 10**7)) for _ in range(80)])
    write("5_io", [(rng.randint(0, 10**7), rng.randint(0, 10**7)) for _ in range(20000)])
    huge = [(rng.randint(0, 10**7), rng.randint(0, 10**7)) for _ in range(200000)]
    Path("/tmp/GANNHAT_big.txt").write_text(encode(huge))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
