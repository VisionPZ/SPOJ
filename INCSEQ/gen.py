#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 5000000


def brute(values, length):
    return sum(1 for choice in itertools.combinations(values, length)
               if all(choice[index] < choice[index + 1]
                      for index in range(length - 1))) % MODULUS


def oracle(text):
    tokens = [int(value) for value in text.split()]
    element_count = tokens[0]
    subsequence_length = tokens[1]
    values = tokens[2:2 + element_count]
    endings = [[0] * (subsequence_length + 1) for _ in range(element_count)]
    for index, value in enumerate(values):
        current = [0] * (subsequence_length + 1)
        current[1] = 1
        for length in range(2, subsequence_length + 1):
            total = 0
            for previous in range(index):
                if values[previous] < value:
                    total += endings[previous][length - 1]
            current[length] = total % MODULUS
        endings[index] = current
    answer = sum(row[subsequence_length] for row in endings) % MODULUS
    return str(answer) + "\n"


SAMPLE = """4 3
1
2
2
10
"""
SAMPLE_OUT = "2\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n7\n") == "1\n"
assert oracle("3 2\n2 1 0\n") == "0\n"
assert oracle("4 2\n1 2 3 4\n") == "6\n"
for trial in range(40):
    rng = random.Random(trial)
    values = [rng.randint(0, 6) for _ in range(rng.randint(1, 9))]
    length = rng.randint(1, min(4, len(values)))
    text = str(len(values)) + " " + str(length) + "\n" + "\n".join(
        str(value) for value in values) + "\n"
    assert oracle(text) == str(brute(values, length) % MODULUS) + "\n"


def write(name, values, length):
    text = f"{len(values)} {length}\n" + "".join(
        f"{value}\n" for value in values)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [0], 1)
    write("3_wide", list(range(100)), 50)
    rng = random.Random(20261126)
    write("4_random", [rng.randint(0, 99999) for _ in range(200)], 25)
    write("5_io", [rng.randint(0, 99999) for _ in range(300)], 50)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 2, 2, 10], 3)
build()
