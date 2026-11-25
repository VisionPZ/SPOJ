#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_case(index, difference, modulus):
    found = 0
    second_leg = difference + 1
    while True:
        first_leg = second_leg - difference
        squared = first_leg * first_leg + second_leg * second_leg
        hypotenuse = math.isqrt(squared)
        if hypotenuse * hypotenuse == squared:
            found += 1
            if found == index:
                return f"{first_leg % modulus} {second_leg % modulus} {hypotenuse % modulus}\n"
        second_leg += 1


def oracle(text):
    tokens = list(map(int, text.split()))
    count = tokens[0]
    cursor = 1
    answers = []
    for _ in range(count):
        index = tokens[cursor]
        difference = tokens[cursor + 1]
        modulus = tokens[cursor + 2]
        cursor += 3
        answers.append(oracle_case(index, difference, modulus))
    return "".join(answers)


SAMPLE = """3
1 1 235813
3 21 1000
9 119 11
"""
SAMPLE_OUT = """3 4 5
63 84 105
5 3 1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1 7\n") == "3 4 5\n"
assert oracle("1\n6 21 1000\n") == "420 441 609\n"
assert oracle("1\n2 119 100000\n") == "49 168 175\n"
assert math.isqrt(25) == 5


def write(name, cases):
    lines = [str(len(cases))]
    for index, difference, modulus in cases:
        lines.append(f"{index} {difference} {modulus}")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1, 235813), (8, 7, 1000), (2, 119, 100000), (20, 119, 99991)])
    wide = []
    for difference in (119, 221, 255, 119 * 17, 7 * 17 * 23):
        for index in (1, 7, 13, 20):
            wide.append((index, difference, 1000000000))
    write("3_wide", wide)
    rng = random.Random(20261201)
    differences = [1, 7, 21, 35, 119, 221, 255, 2023, 2737]
    random_cases = []
    for _ in range(60):
        difference = rng.choice(differences)
        limit = 8 if difference == 1 else 20
        random_cases.append((rng.randint(1, limit), difference, rng.randint(2, 1000000000)))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(1000):
        difference = rng.choice(differences)
        limit = 8 if difference == 1 else 12
        io_cases.append((rng.randint(1, limit), difference, rng.randint(2, 1000000000)))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
