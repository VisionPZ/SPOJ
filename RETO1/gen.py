#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    word_count = int(tokens[0])
    delay = int(tokens[1])
    screen = [int(tokens[2])]
    for index in range(1, word_count):
        current = int(tokens[2 + index])
        if current - screen[-1] > delay:
            screen = [current]
        else:
            screen.append(current)
    return str(len(screen)) + "\n"


SAMPLE_INPUT_ONE = "6 5\n1 3 8 14 19 20\n"
SAMPLE_OUTPUT_ONE = "3\n"
SAMPLE_INPUT_TWO = "6 1\n1 3 5 7 9 10\n"
SAMPLE_OUTPUT_TWO = "2\n"
assert oracle(SAMPLE_INPUT_ONE) == SAMPLE_OUTPUT_ONE
assert oracle(SAMPLE_INPUT_TWO) == SAMPLE_OUTPUT_TWO
assert oracle("1 1000000000\n1\n") == "1\n"
assert oracle("3 1\n1 2 3\n") == "3\n"
assert oracle("3 1\n1 2 4\n") == "1\n"
assert oracle("4 5\n1 3 8 9\n") == "4\n"


def write(name, word_count, delay, times):
    input_text = "%d %d\n" % (word_count, delay)
    input_text += " ".join(str(value) for value in times) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


random.seed(2026)
write("1_sample", 6, 5, [1, 3, 8, 14, 19, 20])
write("2_edges", 6, 1, [1, 3, 5, 7, 9, 10])
write("3_wide", 100000, 1000000000, list(range(1, 100001)))
write("4_random", 100000, 7, sorted(random.sample(range(1, 1000000001), 100000)))
write("5_io", 100000, 30, sorted(random.sample(range(1, 1000000001), 100000)))
