#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    for number in tokens[1:1 + case_count]:
        total = 0
        for value in range(1, number + 1):
            total += bin(value).count("1")
        answers.append(str(total))
    return "\n".join(answers) + "\n"


SAMPLE = "5\n7\n4\n10\n9\n6\n"
SAMPLE_OUT = "12\n5\n17\n15\n9\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n") == "1\n"
assert oracle("2\n10000\n10000\n") == "64613\n64613\n"
assert oracle("3\n1\n2\n3\n") == "1\n2\n4\n"


def write(name, numbers):
    text = str(len(numbers)) + "\n" + "".join(str(value) + "\n" for value in numbers)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 10000, 10000])
    write("3_wide", [10000] * 20)
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 10000) for _ in range(20)])
    write("5_io", [10000] * 20)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [7, 4, 10, 9, 6])
build()
