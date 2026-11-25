#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    length = int(text.split()[0])
    total = 0
    for word in itertools.product("012", repeat=length):
        valid = True
        for index in range(length - 1):
            if abs(int(word[index]) - int(word[index + 1])) > 1:
                valid = False
                break
        if valid:
            total += 1
    return str(total) + "\n"


SAMPLE = "2\n"
SAMPLE_OUT = "7\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n") == "3\n"
assert oracle("3\n") == "17\n"
assert oracle("4\n") == "41\n"
assert oracle("0\n") == "1\n"


def write(name, length):
    text = str(length) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1)
    write("3_wide", 12)
    rng = random.Random(20261126)
    write("4_random", rng.randint(1, 12))
    write("5_io", 15)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 2)
build()
