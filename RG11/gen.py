#!/usr/bin/env python3
import random
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SAMPLE = "9 4 80 80 30 4 4 80 4 4\n"
SAMPLE_OUT = "5 3 1\n"


def oracle(text):
    tokens = text.split()
    answers = []
    cursor = 0
    while cursor < len(tokens):
        count = int(tokens[cursor]); cursor += 1
        numbers = [int(token) for token in tokens[cursor:cursor + count]]
        cursor += len(numbers)
        counts = Counter(numbers)
        frequencies = sorted(counts.values(), reverse=True)
        answers.append(" ".join(str(frequency) for frequency in frequencies))
    return "\n".join(answers) + "\n" if answers else ""


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("4 5 5 5 5\n") == "4\n"
assert oracle("3 1 2 3\n") == "1 1 1\n"
assert oracle("6 7 7 8 8 9 9\n") == "2 2 2\n"
assert oracle("1 -5\n") == "1\n"


def write(name, cases):
    lines = []
    for numbers in cases:
        lines.append(" ".join([str(len(numbers))] + [str(number) for number in numbers]))
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    rng = random.Random(20261126)
    write("2_edges", [[7], [7, 7, 7], [1, 2, 3], [-5, -5, 2],
                      [0, 0, 0, 0, 0]])
    write("3_wide", [[rng.randint(0, 9) for _ in range(2000)],
                     [rng.randint(-10**9, 10**9) for _ in range(2000)]])
    write("4_random", [[rng.randint(-50, 50) for _ in range(rng.randint(1, 200))]
                       for _ in range(50)])
    write("5_io", [[rng.randint(-10**6, 10**6) for _ in range(rng.randint(1, 1000))]
                   for _ in range(300)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [[4, 80, 80, 30, 4, 4, 80, 4, 4]])
build()
