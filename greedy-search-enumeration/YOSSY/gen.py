#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    soldier_count = tokens[cursor]
    cursor += 1
    powers = []
    foods = []
    for _ in range(soldier_count):
        powers.append(tokens[cursor])
        foods.append(tokens[cursor + 1])
        cursor += 2
    food_supply = tokens[cursor]
    cursor += 1
    list_length = tokens[cursor]
    army_powers = []
    for mask in range(1 << soldier_count):
        total_power = 0
        total_food = 0
        for index in range(soldier_count):
            if mask & (1 << index):
                total_power += powers[index]
                total_food += foods[index]
        if total_food <= food_supply:
            army_powers.append(total_power)
    army_powers.sort(reverse=True)
    answers = army_powers[:list_length]
    while len(answers) < list_length:
        answers.append(0)
    return "\n".join(str(value) for value in answers) + "\n"


SAMPLE = """4
45 3
30 5
45 9
10 5
15
4
"""
SAMPLE_OUT = """90
85
75
75
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2\n10 5\n20 5\n10\n3\n") == "30\n20\n10\n"
assert oracle("3\n5 1\n6 1\n7 1\n2\n4\n") == "13\n12\n11\n7\n"
assert oracle("2\n0 0\n0 5\n5\n4\n") == "0\n0\n0\n0\n"
assert oracle("3\n9 2\n8 3\n7 4\n5\n3\n") == "17\n9\n8\n"


def write(name, soldiers, food_supply, list_length):
    input_text = (str(len(soldiers)) + "\n"
                  + "".join(f"{power} {food}\n" for power, food in soldiers)
                  + f"{food_supply}\n{list_length}\n")
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [(0, 0), (5, 10)], 10, 5)
    write("3_wide", [(100, 1), (90, 2), (80, 3), (70, 4), (60, 5)], 10, 6)
    rng = random.Random(20261126)
    soldiers = [(rng.randint(0, 30), rng.randint(0, 12)) for _ in range(14)]
    write("4_random", soldiers, 60, 12)
    soldiers = [(rng.randint(0, 50), rng.randint(0, 15)) for _ in range(15)]
    write("5_io", soldiers, 75, 40)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(45, 3), (30, 5), (45, 9), (10, 5)], 15, 4)
build()
