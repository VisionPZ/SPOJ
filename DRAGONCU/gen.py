#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
BIG_ANSWER = "(9648,-31504)"


def complement_reverse(text):
    return "".join("1" if digit == "0" else "0" for digit in reversed(text))


def oracle(values):
    answers = []
    for steps in values:
        if steps == 1000000000:
            answers.append(BIG_ANSWER)
            continue
        turns = "1"
        while len(turns) < steps:
            turns = turns + "1" + complement_reverse(turns)
        pos_x = pos_y = 0
        dir_x, dir_y = 1, 0
        for index in range(steps):
            pos_x += dir_x
            pos_y += dir_y
            if turns[index] == "1":
                dir_x, dir_y = -dir_y, dir_x
            else:
                dir_x, dir_y = dir_y, -dir_x
        answers.append(f"({pos_x},{pos_y})")
    return "\n".join(answers) + "\n"


SAMPLE = [1, 2, 3, 2048, 1000000000, -1]
SAMPLE_OUT = """(1,0)
(1,1)
(0,1)
(-32,32)
(9648,-31504)
"""
assert oracle(SAMPLE[:-1]) == SAMPLE_OUT
assert oracle([0]) == "(0,0)\n"
assert oracle([1, 2, 3]) == "(1,0)\n(1,1)\n(0,1)\n"
assert oracle([2048]) == "(-32,32)\n"
assert len(complement_reverse("110")) == 3


def write(name, values):
    (ROOT / "in" / f"{name}.txt").write_text("\n".join(str(v) for v in values) + "\n")
    (ROOT / "out" / f"{name}.out").write_text(oracle([v for v in values if v != -1]))


def build():
    write("2_edges", [0, 1, 2, 3, 4, 7, 8, 15, 16, 31, 32, 63, 64,
                      127, 128, 255, 256, 1023, 1024, 2047, 2048, -1])
    rng = random.Random(20261126)
    write("3_wide", [rng.randint(0, 4000) for _ in range(200)] + [-1])
    write("4_random", [rng.randint(0, 6000) for _ in range(400)] + [-1])
    write("5_io", [1000000000 if index % 3 == 0 else rng.randint(0, 200)
                   for index in range(4999)] + [-1])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
