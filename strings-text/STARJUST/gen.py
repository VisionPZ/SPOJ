#!/usr/bin/env python3
import random
import string
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    lines = text.split("\n")
    count = int(lines[0])
    cursor = 1
    answers = []
    for _ in range(count):
        width = int(lines[cursor])
        value = lines[cursor + 1]
        cursor += 2
        padding = width - len(value)
        if padding <= 0:
            answers.append(value)
            continue
        slots = ["*"] * width
        start = (padding + 1) // 2
        slots[start:start + len(value)] = list(value)
        answers.append("".join(slots))
    return "\n".join(answers) + "\n"


def alternate(text):
    lines = text.split("\n")
    count = int(lines[0])
    cursor = 1
    answers = []
    for _ in range(count):
        width = int(lines[cursor])
        value = lines[cursor + 1]
        cursor += 2
        gap = width - len(value)
        left = gap // 2 + gap % 2
        right = gap // 2
        answers.append("*" * left + value + "*" * right)
    return "\n".join(answers) + "\n"


SAMPLE = """3
10
hello
10
milk
30
to be, or not to be
"""
SAMPLE_OUT = """***hello**
***milk***
******to be, or not to be*****
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert alternate(SAMPLE) == SAMPLE_OUT
assert oracle("1\n5\nhi\n") == "**hi*\n"
assert oracle("1\n4\nhi\n") == "*hi*\n"
assert oracle("1\n2\nhi\n") == "hi\n"


def write(name, pairs):
    text = str(len(pairs)) + "\n" + "".join(f"{width}\n{value}\n" for width, value in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(0, ""), (1, "x"), (4, "hi"), (5, "hi"), (6, "hi"), (3, "long")])
    write("3_wide", [(999, "star"), (1000, "q" * 40), (1001, "z" * 39)])
    rng = random.Random(20261126)
    pool = string.ascii_letters + string.digits + " ,.!?"
    pairs = []
    for _ in range(120):
        length = rng.randint(1, 30)
        value = "".join(rng.choice(pool) for _ in range(length))
        pairs.append((rng.randint(length, length + 40), value))
    write("4_random", pairs)
    io_pairs = [(200, "value " + str(index).zfill(4)) for index in range(3000)]
    write("5_io", io_pairs)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(10, "hello"), (10, "milk"), (30, "to be, or not to be")])
build()
