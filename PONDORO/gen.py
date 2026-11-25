#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    world_length = int(tokens[0])
    mouth_count = int(tokens[1])
    world = tokens[2]
    lengths = [int(value) for value in tokens[3:3 + mouth_count]]
    best_water = -1
    answer = 0
    for length in lengths:
        water = 0
        for start in range(world_length - length + 1):
            water = max(water, world[start:start + length].count('R'))
        if water > best_water or (water == best_water and length < answer):
            best_water = water
            answer = length
    return str(answer) + "\n"


SAMPLE = "12 3\nR..RR.RR..RR\n4 5 6\n"
SAMPLE_OUT = "5\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("12 2\nR..RR.RR..RR\n7 8\n") == "8\n"
assert oracle("11 2\nR.RR.RR..RR\n7 8\n") == "7\n"
assert oracle("5 2\n.....\n2 4\n") == "2\n"
assert oracle("5 3\nRRRRR\n1 3 5\n") == "5\n"
assert oracle("4 2\nR..R\n2 4\n") == "4\n"


def write(name, world, lengths):
    text = f"{len(world)} {len(lengths)}\n{world}\n" + " ".join(str(value) for value in lengths) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", ".", [1])
    write("3_wide", ("R." * 150), list(range(1, 41)))
    rng = random.Random(20261126)
    world = "".join(rng.choice("R.") for _ in range(240))
    write("4_random", world, rng.sample(range(1, 60), 35))
    write("5_io", "R" * 200, list(range(1, 41)))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
