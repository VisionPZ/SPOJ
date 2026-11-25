#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def apply_flip(stack, count):
    top = [(-size if size > 0 else -size) for size in reversed(stack[:count])]
    return top + stack[count:]


def solve(stack):
    stack = list(stack)
    size = len(stack)
    flips = []
    for target in range(size, 0, -1):
        position = next(index for index, value in enumerate(stack[:size])
                        if abs(value) == target)
        if position == size - 1 and stack[position] > 0:
            size -= 1
            continue
        if position != 0:
            stack = apply_flip(stack, position + 1)
            flips.append(position + 1)
        if stack[0] > 0:
            stack = apply_flip(stack, 1)
            flips.append(1)
        stack = apply_flip(stack, size)
        flips.append(size)
        size -= 1
    if stack[0] < 0:
        stack = apply_flip(stack, 1)
        flips.append(1)
    return flips


def validate(initial, flips):
    stack = list(initial)
    for count in flips:
        stack = apply_flip(stack, count)
    return stack == list(range(1, len(initial) + 1)) and len(flips) <= 3 * len(initial) - 2


def parse_size(token):
    if token[0] in '-\u2013':
        return -int(token[1:])
    if token[0] == '+':
        return int(token[1:])
    return int(token)


def oracle(text):
    lines = text.splitlines()
    count = int(lines[0])
    answers = []
    for case in range(1, count + 1):
        values = [parse_size(token) for token in lines[case].split()]
        flips = solve(values[1:])
        assert validate(values[1:], flips)
        parts = [str(case), str(len(flips))] + [str(value) for value in flips]
        answers.append(" ".join(parts))
    return "\n".join(answers) + "\n"


SAMPLE = """3
3 +1 \u20133 \u20132
4 \u20133 +1 \u20132 \u20134
5 +1 +2 +3 +4 -5
"""
SAMPLE_OUT = """1 6 2 1 3 1 2 1
2 6 4 1 4 3 1 2
3 3 5 1 5
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 +1\n") == "1 0\n"
assert oracle("1\n1 -1\n") == "1 1 1\n"
assert oracle("1\n2 +2 +1\n") == "1 3 1 2 1\n"
assert solve([-1, -2]) == [2, 1, 2, 1]
assert solve([-1, -2, -3]) == [3, 1, 3, 2, 1, 2, 1]
assert validate([-3, 1, -2, -4], [4, 1, 4, 3, 1, 2])


def write(name, datasets):
    lines = [str(len(datasets))]
    for sizes in datasets:
        tokens = []
        for size in sizes:
            tokens.append(('+' if size > 0 else '-') + str(abs(size)))
        lines.append(f"{len(sizes)} " + " ".join(tokens))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[1], [-1], [1, 2], [-1, -2], [3, 1, 2], [-3, 1, -2, -4]])
    rng = random.Random(20261126)
    wide = []
    for _ in range(200):
        sizes = list(range(1, 31))
        rng.shuffle(sizes)
        wide.append([size if rng.random() < 0.5 else -size for size in sizes])
    write("3_wide", wide)
    random_cases = []
    for _ in range(200):
        count = rng.randint(1, 20)
        sizes = list(range(1, count + 1))
        rng.shuffle(sizes)
        random_cases.append([size if rng.random() < 0.5 else -size for size in sizes])
    write("4_random", random_cases)
    write("5_io", [[-size for size in range(1, 31)] for _ in range(1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
