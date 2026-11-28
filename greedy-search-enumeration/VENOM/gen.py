#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    position = 1
    results = []
    for _ in range(case_count):
        health = tokens[position]
        poison = tokens[position + 1]
        heal = tokens[position + 2]
        position += 3
        time = 0
        attack = 0
        while True:
            attack += 1
            time += 1
            health -= attack * poison
            if health <= 0:
                break
            time += 1
            health += heal
        results.append(str(time))
    return "\n".join(results) + "\n"


SAMPLE = """3
3 7 2
81 4 1
87 8 4
"""
SAMPLE_OUT = """1
13
9
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n10 2 1\n") == "5\n"
assert oracle("1\n1 1 0\n") == "1\n"
assert oracle("1\n1000000 1 0\n") == "2827\n"
assert oracle("1\n81 4 1\n") == "13\n"


def write(name, cases):
    text = str(len(cases)) + "\n"
    text += "".join(f"{health} {poison} {heal}\n" for health, poison, heal in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1, 0), (1, 1000000, 999999), (1000000, 1, 0),
                      (1000000, 1000000, 0), (2, 3, 2), (10, 2, 1)])
    write("3_wide", [(1000000, 1, 0), (1000000, 2, 1),
                     (1000000, 1000000, 999999), (999999, 1, 0)])
    rng = random.Random(20261126)
    cases = []
    for _ in range(1000):
        poison = rng.randint(1, 1000000)
        cases.append((rng.randint(1, 1000000), poison, rng.randint(0, poison - 1)))
    write("4_random", cases)
    cases = []
    for _ in range(200000):
        poison = rng.randint(1, 1000000)
        cases.append((rng.randint(1, 1000000), poison, rng.randint(0, poison - 1)))
    write("5_io", cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
