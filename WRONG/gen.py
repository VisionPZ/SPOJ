#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DIRECTIONS = ((0, 1), (1, 0), (0, -1), (-1, 0))
ALTERNATIVES = {"F": "LR", "L": "FR", "R": "FL"}


def final_position(text):
    pos_x = 0
    pos_y = 0
    facing = 0
    for command in text:
        if command == "F":
            dx, dy = DIRECTIONS[facing]
            pos_x += dx
            pos_y += dy
        elif command == "L":
            facing = (facing + 3) % 4
        else:
            facing = (facing + 1) % 4
    return pos_x, pos_y


def oracle(text):
    intended = text.strip()
    answers = set()
    for index, command in enumerate(intended):
        for replacement in ALTERNATIVES[command]:
            typed = intended[:index] + replacement + intended[index + 1:]
            answers.add(final_position(typed))
    return str(len(answers)) + "\n"


SAMPLE = "FF\n"
SAMPLE_OUT = "3\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("F\n") == "1\n"
assert oracle("L\n") == "2\n"
assert oracle("FLR\n") == "4\n"
assert final_position("FF") == (0, 2)


def write(name, commands):
    text = commands + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "FLR")
    write("3_wide", "FLFRFLFRFLFRFLFRFLFRFLFRFLFRFLFRFLFRFLFR")
    rng = random.Random(20261126)
    write("4_random", "".join(rng.choice("FLR") for _ in range(40)))
    write("5_io", "".join(rng.choice("FLR") for _ in range(200)))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", "FF")
build()
