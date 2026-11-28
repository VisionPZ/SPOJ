#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    pondo_step, pundu_step, track_length = (int(value) for value in text.split())
    pondo_position = 0
    pundu_position = 0
    while True:
        pondo_position += pondo_step
        if pondo_position >= track_length:
            return "WIN\n"
        while pundu_position < pondo_position:
            pundu_position += pundu_step
        if pundu_position >= track_length:
            return "LOSS\n"


SAMPLE = "1 2 2\n"
SAMPLE_OUT = "LOSS\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("5 7 15\n") == "WIN\n"
assert oracle("10 1 10\n") == "WIN\n"
assert oracle("1 10 15\n") == "LOSS\n"
assert oracle("3 5 10\n") == "LOSS\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "1000000000 1 1000000000\n")
    write("3_wide", "999999999 1000000000 1000000000\n")
    rng = random.Random(20261126)
    write("4_random", f"{rng.randint(1, 200000)} {rng.randint(1, 200000)} {rng.randint(1, 200000)}\n")
    write("5_io", "1 1 100000\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
