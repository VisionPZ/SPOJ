#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def format_line(values):
    if not values:
        return " \n"
    return "".join(str(value) + " " for value in values) + "\n"


def oracle(text):
    tokens = [int(value) for value in text.split()]
    first_size = tokens[0]
    second_size = tokens[1]
    first_set = tokens[2:2 + first_size]
    second_set = tokens[2 + first_size:2 + first_size + second_size]
    intersection = sorted(set(first_set) & set(second_set))
    union = sorted(set(first_set) | set(second_set))
    return format_line(intersection) + format_line(union)


SAMPLE = "5 6\n3 4 5 7 22\n5 7 9 18 22 25\n"
SAMPLE_OUT = "5 7 22 \n3 4 5 7 9 18 22 25 \n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("0 0\n\n\n") == " \n \n"
assert oracle("3 3\n1 2 3\n1 2 3\n") == "1 2 3 \n1 2 3 \n"
assert oracle("2 2\n1 3\n2 4\n") == " \n1 2 3 4 \n"
assert format_line([]) == " \n"


def write(name, first_values, second_values):
    text = f"{len(first_values)} {len(second_values)}\n"
    text += " ".join(str(value) for value in first_values) + "\n"
    text += " ".join(str(value) for value in second_values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [], [])
    write("3_wide", [value * 30 for value in range(30)],
          [value * 30 + 15 for value in range(30)])
    rng = random.Random(20261126)
    first_values = sorted(rng.sample(range(1001), rng.randint(0, 30)))
    second_values = sorted(rng.sample(range(1001), rng.randint(0, 30)))
    write("4_random", first_values, second_values)
    shared = [value * 33 for value in range(30)]
    write("5_io", shared, shared)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [3, 4, 5, 7, 22], [5, 7, 9, 18, 22, 25])
build()
