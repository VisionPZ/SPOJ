#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    for track_count in tokens[1:1 + case_count]:
        total = 0
        for mask in range(1 << track_count):
            if mask & (mask >> 1):
                continue
            total += 1
        answers.append(str(total))
    return "\n".join(answers) + "\n"


SAMPLE = "2\n1\n2\n"
SAMPLE_OUT = "2\n3\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0\n") == "1\n"
assert oracle("1\n3\n") == "5\n"
assert oracle("1\n4\n") == "8\n"
assert oracle("3\n5\n6\n7\n") == "13\n21\n34\n"


def write(name, counts):
    text = str(len(counts)) + "\n" + "".join(str(value) + "\n" for value in counts)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [0, 1, 2, 3])
    write("3_wide", [12, 15, 16, 17, 18])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(0, 18) for _ in range(40)])
    write("5_io", [12] * 500)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 2])
build()
