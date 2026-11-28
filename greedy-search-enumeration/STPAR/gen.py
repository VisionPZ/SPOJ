#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def has_pattern_312(order):
    for first in range(len(order)):
        for second in range(first + 1, len(order)):
            if order[second] <= order[first]:
                continue
            for third in range(second + 1, len(order)):
                if order[third] < order[first]:
                    return True
    return False


def oracle(text):
    tokens = text.split()
    cursor = 0
    answers = []
    while cursor < len(tokens):
        count = int(tokens[cursor]); cursor += 1
        if count == 0:
            break
        order = [int(tokens[cursor + index]) for index in range(count)]
        cursor += count
        answers.append("no" if has_pattern_312(order) else "yes")
    return "\n".join(answers) + "\n"


def write(name, cases):
    input_text = "".join(f"{len(order)}\n" + " ".join(map(str, order)) + "\n"
                         for order in cases) + "0\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE = [5, 1, 2, 4, 3]
assert oracle("5\n" + " ".join(map(str, SAMPLE)) + "\n0\n") == "yes\n"
assert oracle("3\n2 3 1\n0\n") == "no\n"


def build():
    write("2_edges", [[1], [2, 1], [1, 2], [3, 2, 1], [3, 1, 2],
                      [2, 3, 1], [1, 3, 2], [4, 1, 2, 3]])

    wide = [list(range(1000, 0, -1)), list(range(1, 1001)),
            [1] + list(range(1000, 1, -1)),
            list(range(500, 0, -1)) + list(range(1000, 500, -1))]
    write("3_wide", wide)

    random.seed(123)
    random_cases = []
    for _ in range(100):
        size = random.randint(1, 40)
        order = list(range(1, size + 1))
        random.shuffle(order)
        random_cases.append(order)
    write("4_random", random_cases)

    io_cases = []
    for _ in range(1000):
        size = random.randint(1, 30)
        order = list(range(1, size + 1))
        random.shuffle(order)
        io_cases.append(order)
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [SAMPLE])
build()
