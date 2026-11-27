#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
COLOR_INDEX = {"W": 0, "R": 1, "G": 2}
COLOR_NAME = "WRG"


def third_color(first, second):
    if first == second:
        return first
    for candidate in range(3):
        if candidate != first and candidate != second:
            return candidate


def simulate(colors, steps):
    current = list(colors)
    size = len(current)
    if size <= 1:
        return current
    seen = {}
    step = 0
    while step < steps:
        state = tuple(current)
        if state in seen:
            cycle = step - seen[state]
            remaining = (steps - step) % cycle
            return simulate(current, remaining)
        seen[state] = step
        for index in range(size):
            following = (index + 1) % size
            changed = third_color(current[index], current[following])
            current[index] = changed
            current[following] = changed
        step += 1
    return current


def oracle(text):
    tokens = text.split()
    size = int(tokens[0])
    steps = int(tokens[1])
    colors = [COLOR_INDEX[letter] for letter in tokens[2].strip()]
    result = simulate(colors, steps)
    return "".join(COLOR_NAME[color] for color in result) + "\n"


SAMPLE = """3 1
GRR
"""
SAMPLE_OUT = """RGR
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("5 4\nWRWRW\n") == "GGGWG\n"
assert oracle("1 1000000000\nW\n") == "W\n"
assert oracle("2 1\nWR\n") == "GG\n"
assert oracle("3 2\nGRR\n") == "RGR\n"


def write(name, colors, steps):
    text = f"{len(colors)} {steps}\n{colors}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "WRG", 1)
    rng = random.Random(20261126)
    wide = "".join(rng.choice("WRG") for _ in range(1500))
    write("3_wide", wide, 40)
    random_colors = "".join(rng.choice("WRG") for _ in range(200))
    write("4_random", random_colors, 137)
    io_colors = "".join(rng.choice("WRG") for _ in range(6000))
    write("5_io", io_colors, 3)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
