#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1000000007


def forms_progress(values):
    if len(values) < 2:
        return False
    if all(value == values[0] for value in values):
        return True
    ordered = sorted(values)
    if ordered[1] % ordered[0] != 0:
        return False
    ratio = ordered[1] // ordered[0]
    if ratio < 2:
        return False
    expected = ordered[0]
    for value in ordered:
        if value != expected:
            return False
        expected *= ratio
    return True


def oracle(text):
    tokens = [int(value) for value in text.split()]
    numbers = tokens[1:1 + tokens[0]]
    total = 0
    for mask in range(1, 1 << len(numbers)):
        subset = [numbers[index] for index in range(len(numbers))
                  if mask & (1 << index)]
        if forms_progress(subset):
            total += 1
    return str(total % MODULUS) + "\n"


SAMPLE = "7\n2 4 4 2 8 16 8\n"
SAMPLE_OUT = "41\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n5\n") == "0\n"
assert oracle("2\n3 3\n") == "1\n"
assert oracle("3\n1 2 4\n") == "4\n"
assert oracle("4\n5 5 5 5\n") == "11\n"
assert oracle("3\n2 6 18\n") == "4\n"


def write(name, numbers):
    text = str(len(numbers)) + "\n"
    text += " ".join(str(value) for value in numbers) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [5, 3, 3, 8, 12])
    write("3_wide", [1, 2, 4, 8, 16, 32, 64, 1000000, 500000,
                     250000, 125000, 62500])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 1000000) for _ in range(12)])
    write("5_io", [7, 7, 7, 7, 49, 343, 2401, 16807, 117649,
                   2, 4, 8, 16, 32])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [2, 4, 4, 2, 8, 16, 8])
build()
