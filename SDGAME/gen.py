#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    turns = int(tokens[cursor]); cursor += 1
    dice_count = int(tokens[cursor]); cursor += 1
    track_cells = int(tokens[cursor]); cursor += 1
    dice = [1] * dice_count
    positions = [0, 0]
    answers = []
    for turn in range(turns):
        rolled = int(tokens[cursor]); cursor += 1
        shown = int(tokens[cursor]); cursor += 1
        left = int(tokens[cursor]); cursor += 1
        right = int(tokens[cursor]); cursor += 1
        dice[rolled] = shown
        distance = 1
        for index in range(left, right + 1):
            distance *= dice[index]
        player = turn % 2
        positions[player] = (positions[player] + distance) % track_cells
        answers.append(str(positions[player]))
        if positions[0] == positions[1]:
            shared_cell = positions[0]
            dice = [value * shared_cell for value in dice]
    return "\n".join(answers) + "\n"


SAMPLE = """6 4 20
1 5 1 1
3 10 2 3
2 3 0 3
1 2 0 3
1 5 1 2
0 7 0 1
"""
SAMPLE_OUT = """5
10
15
10
10
0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2 2 7\n0 3 0 0\n1 2 1 1\n") == "3\n2\n"
assert oracle("1 1 5\n0 0 0 0\n") == "0\n"
assert oracle("3 3 11\n2 2 0 2\n0 3 1 2\n1 4 0 1\n") == "2\n2\n4\n"


def write(name, lines, first_line, oracle_text=None):
    input_text = first_line + "\n" + "".join(line + "\n" for line in lines)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(oracle_text or input_text))


def build():
    write("2_edges", [
        "0 3 0 0", "1 4 1 1", "2 0 0 2", "0 1 0 0", "1 1 1 1",
        "3 6 0 2", "2 7 2 2", "0 2 0 1",
    ], "8 4 13")
    rng = random.Random(20261126)
    wide_lines = []
    for _ in range(2000):
        rolled = rng.randrange(1000)
        shown = rng.randint(0, 10 ** 9)
        left = rng.randrange(1000)
        right = min(999, left + rng.randrange(50))
        wide_lines.append(f"{rolled} {shown} {left} {right}")
    write("3_wide", wide_lines, "2000 1000 1000000007")
    random_lines = []
    for _ in range(500):
        rolled = rng.randrange(200)
        shown = rng.randint(0, 10 ** 9)
        left = rng.randrange(200)
        right = min(199, left + rng.randrange(30))
        random_lines.append(f"{rolled} {shown} {left} {right}")
    write("4_random", random_lines, "500 200 999983")
    io_lines = []
    for _ in range(5000):
        rolled = rng.randrange(100)
        shown = rng.randint(0, 10 ** 9)
        left = rng.randrange(100)
        right = min(99, left + rng.randrange(10))
        io_lines.append(f"{rolled} {shown} {left} {right}")
    write("5_io", io_lines, "5000 100 1000000007")
    big_lines = []
    for _ in range(100000):
        rolled = rng.randrange(10000)
        shown = rng.randint(0, 10 ** 9)
        left = rng.randrange(10000)
        right = min(9999, left + rng.randrange(100))
        big_lines.append(f"{rolled} {shown} {left} {right}")
    Path("/tmp/SDGAME_big.txt").write_text(
        "100000 10000 1000000007\n" + "".join(line + "\n" for line in big_lines))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
