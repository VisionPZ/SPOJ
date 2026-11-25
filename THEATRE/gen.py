#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    heights = tokens[1:1 + count]
    result = 1
    for index in range(count):
        blocker = 1
        for following in range(index + 1, count):
            if heights[following] > heights[index]:
                blocker = heights[following]
                break
        result = result * blocker % MOD
    return str(result) + "\n"


SAMPLE = """5
5 2 1 4 3
"""
SAMPLE_OUT = """16
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("5\n9 8 3 5 7\n") == "35\n"
assert oracle("2\n1 2\n") == "2\n"
assert oracle("3\n3 2 1\n") == "1\n"
assert oracle("10\n30 10 50 70 11 60 20 80 31 12\n") == "999962375\n"


def write(name, heights):
    text = str(len(heights)) + "\n" + " ".join(str(value) for value in heights) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 5])
    write("3_wide", [1000000000 - index * 7 for index in range(300)])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 1000000000) for _ in range(400)])
    write("5_io", [rng.randint(1, 1000000000) for _ in range(3000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [5, 2, 1, 4, 3])
build()
