#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    count = int(tokens[0])
    token_index = 1
    char_buffer = ""
    answers = []
    for _ in range(count):
        side = int(tokens[token_index])
        token_index += 1
        needed = side * side
        dark = 0
        taken = 0
        while taken < needed:
            if not char_buffer:
                char_buffer = tokens[token_index]
                token_index += 1
            pixel = char_buffer[0]
            char_buffer = char_buffer[1:]
            if pixel == "*":
                dark += 1
            taken += 1
        value = format(dark / needed, ".16g")
        if "." not in value and "e" not in value:
            value += ".0"
        answers.append(value)
    return "\n".join(answers) + "\n"


SAMPLE = "2\n2\n...*\n8\n..................*..*...........*....*...****..................\n"
SAMPLE_OUT = "0.25\n0.125\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n*\n") == "1.0\n"
assert oracle("1\n1\n.\n") == "0.0\n"
assert oracle("1\n2\n*.*.\n") == "0.5\n"


def write(name, images):
    text = str(len(images)) + "\n"
    for side, pixels in images:
        text += str(side) + "\n" + "".join(pixels) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, ["*"]), (1, ["."]), (2, ["*..."])])
    write("3_wide", [(30, ["*" if index % 3 == 0 else "." for index in range(900)])])
    rng = random.Random(20261126)
    images = []
    for _ in range(10):
        side = rng.randint(1, 30)
        images.append((side, ["*" if rng.random() < 0.4 else "." for _ in range(side * side)]))
    write("4_random", images)
    write("5_io", images)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(2, ["...*"]), (8, ["..................*..*...........*....*...****.................."])])
build()
