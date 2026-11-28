#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MAX_CUBES = 5


def oracle(text):
    target = int(text.split()[0])
    cubes = [value ** 3 for value in range(1, target + 1) if value ** 3 <= target]
    ways = 0

    def search(first_index, remaining, slots):
        nonlocal ways
        if slots == 0:
            if remaining == 0:
                ways += 1
            return
        for index in range(first_index, len(cubes)):
            cube = cubes[index]
            if cube > remaining:
                break
            search(index, remaining - cube, slots - 1)

    for count in range(1, MAX_CUBES + 1):
        search(0, target, count)
    return str(ways) + "\n"


SAMPLE = "64\n"
SAMPLE_OUT = "2\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n") == "1\n"
assert oracle("9\n") == "1\n"
assert oracle("905\n") == "0\n"
assert oracle("15436\n") == "12\n"
assert oracle("125000\n") == "50\n"


def write(name, target):
    text = str(target) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1)
    write("3_wide", 125000)
    rng = random.Random(20261126)
    write("4_random", rng.randint(1, 125000))
    write("5_io", 124999)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 64)
build()
