#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "3\n0 1\n1 0\n3 3\n"
SAMPLE_OUT = "KILLUA\nGON\nDRAW\n"

GESTURE = {0: "ROCK", 1: "PAPER", 2: "SCISSORS"}
WINS = {("ROCK", "SCISSORS"), ("SCISSORS", "PAPER"), ("PAPER", "ROCK")}


def oracle(input_text):
    tokens = input_text.split()
    case_count = int(tokens[0])
    lines = []
    for i in range(case_count):
        gon_gesture = GESTURE[int(tokens[1 + 2 * i]) % 3]
        killua_gesture = GESTURE[int(tokens[2 + 2 * i]) % 3]
        if gon_gesture == killua_gesture:
            lines.append("DRAW")
        elif (gon_gesture, killua_gesture) in WINS:
            lines.append("GON")
        else:
            lines.append("KILLUA")
    return "\n".join(lines) + "\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("3\n0 0\n1 2\n2 0\n") == "DRAW\nKILLUA\nKILLUA\n"
assert oracle("1\n100000 99999\n") == "GON\n"


def write(name, pairs):
    input_text = "%d\n%s\n" % (len(pairs), "\n".join("%d %d" % p for p in pairs))
    (ROOT / "in" / ("%s.txt" % name)).write_text(input_text)
    (ROOT / "out" / ("%s.out" % name)).write_text(oracle(input_text))


def build():
    write("2_edges", [(0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (1, 2),
                      (2, 0), (2, 1), (2, 2), (100000, 100000), (1, 100000)])
    write("3_wide", [(100000, 1), (1, 100000), (99999, 100000), (2, 100000),
                     (100000, 2), (50000, 50001), (50001, 50000)])
    rng = random.Random(20190128)
    write("4_random", [(rng.randint(0, 100000), rng.randint(0, 100000)) for _ in range(2000)])
    write("5_io", [(rng.randint(1, 100000), rng.randint(1, 100000)) for _ in range(100000)])


if __name__ == "__main__":
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [(0, 1), (1, 0), (3, 3)])
    build()
