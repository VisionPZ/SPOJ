#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    town_count = tokens[position]
    position += 1
    outbreak_count = tokens[position]
    position += 1
    coordinates = []
    for _ in range(town_count):
        coordinates.append((tokens[position], tokens[position + 1]))
        position += 2
    outbreak_numbers = tokens[position:position + outbreak_count]
    priorities = [0] * (town_count + 1)
    for town_number in range(1, town_count + 1):
        town_x, town_y = coordinates[town_number - 1]
        count = 0
        for outbreak_number in outbreak_numbers:
            outbreak_x, outbreak_y = coordinates[outbreak_number - 1]
            if abs(town_x - outbreak_x) <= 10 and abs(town_y - outbreak_y) <= 10:
                count += 1
        priorities[town_number] = count
    order = sorted(range(1, town_count + 1), key=lambda number: (-priorities[number], number))
    return " ".join(str(number) for number in order) + "\n"


SAMPLE = """3 1
0 11
0 10
0 0
3
"""
SAMPLE_OUT = """2 3 1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("4 2\n0 11\n9 0\n0 1\n11 11\n1 2\n") == "3 1 2 4\n"
assert oracle("1 1\n0 0\n1\n") == "1\n"
assert oracle("2 2\n0 0\n0 0\n1 2\n") == "1 2\n"
assert oracle("3 1\n0 0\n10 10\n11 0\n1\n") == "1 2 3\n"


def write(name, coordinates, outbreak_numbers):
    lines = [f"{len(coordinates)} {len(outbreak_numbers)}"]
    for x_coord, y_coord in coordinates:
        lines.append(f"{x_coord} {y_coord}")
    lines.append(" ".join(str(number) for number in outbreak_numbers))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(0, 0)], [1])
    rng = random.Random(20261126)
    clustered = [(rng.randint(0, 50), rng.randint(0, 50)) for _ in range(1000)]
    write("3_wide", clustered, list(range(1, 101)))
    random_towns = [(rng.randint(0, 1000000000), rng.randint(0, 1000000000)) for _ in range(1000)]
    write("4_random", random_towns, rng.sample(range(1, 1001), 200))
    large_towns = [(rng.randint(0, 1000000000), rng.randint(0, 1000000000)) for _ in range(100000)]
    write("5_io", large_towns, [rng.randint(1, 100000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(0, 11), (0, 10), (0, 0)], [3])
build()
