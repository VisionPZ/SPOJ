#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    land_length = int(tokens[0])
    land = tokens[1]
    best = 0
    for size in range(land_length + 1):
        suffix = land[land_length - size:] if size else ""
        if suffix.count('u') <= suffix.count('o'):
            best = size
    return str(best) + "\n"


SAMPLE = "6\nuuouou\n"
SAMPLE_OUT = "4\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("6\nuuuouo\n") == "4\n"
assert oracle("6\nuuuooo\n") == "6\n"
assert oracle("1\nu\n") == "0\n"
assert oracle("1\no\n") == "1\n"
assert oracle("4\nuuoo\n") == "4\n"


def write(name, land):
    text = f"{len(land)}\n{land}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "u")
    write("3_wide", "o" * 2000)
    rng = random.Random(20261126)
    write("4_random", "".join(rng.choice("uo") for _ in range(1500)))
    write("5_io", "u" * 1500 + "o" * 1500)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
