#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute_answer(steps):
    sequence = "1"
    for _ in range(steps):
        sequence = "".join("01" if digit == "1" else "10" for digit in sequence)
    return sequence.count("00")


def oracle(text):
    tokens = [int(value) for value in text.split()]
    answers = []
    for steps in tokens:
        if steps % 2 == 0:
            exponent = steps // 2 - 1
            answers.append(str((2 * 4 ** exponent + 1) // 3))
        else:
            exponent = steps // 2
            answers.append(str((4 ** exponent - 1) // 3))
    return "\n".join(answers) + "\n"


SAMPLE = """1
2
3
4
5
"""
SAMPLE_OUT = """0
1
1
3
5
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert all(brute_answer(steps) == int(oracle(str(steps) + "\n")) for steps in range(1, 13))
assert oracle("999\n") == str((4 ** 499 - 1) // 3) + "\n"
assert oracle("100\n") == str((2 * 4 ** 49 + 1) // 3) + "\n"


def write(name, steps_list):
    text = "".join(str(steps) + "\n" for steps in steps_list)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 998, 999])
    write("3_wide", list(range(900, 1000)) * 4)
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 999) for _ in range(400)])
    write("5_io", [999] * 4000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 2, 3, 4, 5])
build()
