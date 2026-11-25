#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    ball_count = tokens[0]
    balls = [(tokens[index], tokens[index + 1]) for index in range(1, 2 * ball_count, 2)]
    needed = (ball_count + 1) // 2
    best = ball_count + 1
    for label in {value for ball in balls for value in ball}:
        moves = 0
        shown = 0
        for top_label, bottom_label in balls:
            if top_label == label:
                shown += 1
            elif bottom_label == label:
                moves += 1
                shown += 1
        if shown >= needed and moves < best:
            best = moves
    if best <= ball_count:
        return str(best) + "\n"
    return "Impossible\n"


SAMPLE = "3\n3 100\n100 3\n5 4\n"
SAMPLE_OUT = "1\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("5\n5 9\n5 9\n3 2\n1 4\n5 7\n") == "0\n"
assert oracle("3\n1 2\n3 4\n5 6\n") == "Impossible\n"
assert oracle("1\n7 9\n") == "0\n"
assert oracle("2\n1 2\n2 1\n") == "1\n"


def write(name, balls):
    text = str(len(balls)) + "\n" + "\n".join(f"{top} {bottom}" for top, bottom in balls) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1), (2, 3), (3, 2), (4, 5), (4, 5)])
    write("3_wide", [(100000 - index, 99999 - index) for index in range(40)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(0, 100000), rng.randint(0, 100000)) for _ in range(120)])
    write("5_io", [(rng.randint(0, 20), rng.randint(0, 20)) for _ in range(200)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(3, 100), (100, 3), (5, 4)])
build()
