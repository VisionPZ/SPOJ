#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    answers = []
    for _ in range(case_count):
        horizontal = tokens[cursor]
        vertical = tokens[cursor + 1]
        cursor += 2
        limit = float(horizontal * horizontal - vertical * vertical)
        low = 0.0
        high = float(horizontal)
        for _ in range(90):
            middle = (low + high) / 2.0
            if middle * middle <= limit:
                low = middle
            else:
                high = middle
        answers.append("%.3f" % (2.0 * low))
    return "\n".join(answers) + "\n"


SAMPLE = "1\n4 2\n"
SAMPLE_OUT = "6.928\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n5 3\n") == "8.000\n"
assert oracle("1\n10 0\n") == "20.000\n"
assert oracle("1\n2 1\n") == "3.464\n"
assert oracle("3\n4 2\n5 3\n10 0\n") == "6.928\n8.000\n20.000\n"


def write(name, pairs):
    text = str(len(pairs)) + "\n" + "".join(
        f"{horizontal} {vertical}\n" for horizontal, vertical in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 0), (2, 1), (5, 3), (999, 998), (999, 1), (100, 50)])
    rng = random.Random(20261126)
    wide = []
    for vertical in range(1, 100, 7):
        wide.append((999, vertical))
    for horizontal in range(1, 999, 31):
        wide.append((horizontal, horizontal // 2))
    write("3_wide", wide)
    random_pairs = []
    for _ in range(100):
        horizontal = rng.randint(2, 999)
        vertical = rng.randint(1, horizontal - 1)
        random_pairs.append((horizontal, vertical))
    write("4_random", random_pairs)
    io_pairs = []
    for _ in range(999):
        horizontal = rng.randint(2, 999)
        vertical = rng.randint(1, horizontal - 1)
        io_pairs.append((horizontal, vertical))
    write("5_io", io_pairs)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
