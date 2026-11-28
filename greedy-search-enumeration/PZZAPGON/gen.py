#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DIRECTIONS = "NSEW"


def oracle(text):
    tokens = text.split()
    count = int(tokens[0])
    position = 1
    row = 0
    column = 0
    for _ in range(count):
        token = tokens[position]
        position += 1
        digits = ""
        letter = ""
        for char in token:
            if char.isdigit():
                digits += char
            else:
                letter = char
                break
        steps = int(digits)
        for _ in range(steps):
            if letter == "N":
                row += 1
            elif letter == "S":
                row -= 1
            elif letter == "E":
                column += 1
            elif letter == "W":
                column -= 1
    squared = row * row + column * column
    result = math.isqrt(squared)
    if result * result < squared:
        result += 1
    return str(result) + "\n"


SAMPLE = """3
4W 4N
3E 5S
2W 4N
"""
SAMPLE_OUT = "5\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1N\n") == "1\n"
assert oracle("2\n1N\n1S\n") == "0\n"
assert oracle("2\n3E\n4N\n") == "5\n"
assert oracle("1\n0N\n") == "0\n"


def write(name, lines):
    text = str(len(lines)) + "\n" + "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", ["1N", "1S", "1E", "1W", "0N"])
    rng = random.Random(20261126)
    write("3_wide", [f"{rng.randint(100000, 999999)}{rng.choice(DIRECTIONS)}" for _ in range(99)])
    write("4_random", [f"{rng.randint(0, 100)}{rng.choice(DIRECTIONS)}" for _ in range(50)])
    write("5_io", [f"{rng.randint(0, 1000)}{rng.choice(DIRECTIONS)}" for _ in range(99)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", ["4W 4N", "3E 5S", "2W 4N"])
