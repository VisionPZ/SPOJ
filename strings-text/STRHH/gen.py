#!/usr/bin/env python3
import random
import string
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    count = int(tokens[0])
    answers = []
    cursor = 1
    for _ in range(count):
        value = tokens[cursor]
        cursor += 1
        half = len(value) // 2
        answers.append("".join(value[index] for index in range(0, half, 2)))
    return "\n".join(answers) + "\n"


def write(name, cases):
    lines = [str(len(cases))]
    lines.extend(cases)
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle("4\nyour\nprogress\nis\nnoticeable\n") == "y\npo\ni\nntc\n"
assert oracle("2\nab\nxy\n") == "a\nx\n"

write("1_sample", ["your", "progress", "is", "noticeable"])
write("2_edges", ["ab", "abcd", "abcdefghij"])
random.seed(2026)
write("3_wide", ["".join(random.choice(string.ascii_lowercase) for _ in range(200))
                 for _ in range(100)])
write("4_random", ["".join(random.choice(string.ascii_lowercase)
                          for _ in range(2 * random.randint(1, 100)))
                   for _ in range(100)])
write("5_io", ["".join(random.choice(string.ascii_lowercase) for _ in range(200))
               for _ in range(10000)])
