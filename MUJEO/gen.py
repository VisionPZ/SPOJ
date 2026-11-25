#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    cursor = 1
    for _ in range(case_count):
        left = tokens[cursor]
        right = tokens[cursor + 1]
        cursor += 2
        if left > right:
            left, right = right, left
        total = 0
        for bound in (right, left - 1):
            odd_positions = (bound + 1) // 2 if bound > 0 else 0
            even_positions = bound // 2 if bound > 0 else 0
            base_total = bound * (bound + 1) // 2 if bound > 0 else 0
            prefix = base_total + odd_positions - even_positions
            total = prefix if bound == right else total - prefix
        answers.append(str(total))
    return "\n".join(answers) + "\n"


SAMPLE = "2\n1 4\n1 1000000000\n"
SAMPLE_OUT = "10\n500000000500000000\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1\n") == "2\n"
assert oracle("1\n2 2\n") == "1\n"
assert oracle("1\n3 5\n") == "13\n"
assert oracle("1\n1000000000 1000000000\n") == "999999999\n"


def write(name, pairs):
    text = str(len(pairs)) + "\n" + "".join(f"{left} {right}\n" for left, right in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1), (2, 2), (1, 2), (5, 5), (1000000000, 1000000000)])
    write("3_wide", [(1, 1000000000)] * 10)
    rng = random.Random(20261126)
    pairs = []
    for _ in range(10):
        left = rng.randint(1, 1000000000)
        right = rng.randint(1, 1000000000)
        pairs.append((left, right))
    write("4_random", pairs)
    write("5_io", pairs)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(1, 4), (1, 1000000000)])
build()
