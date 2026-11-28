#!/usr/bin/env python3
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = "3 5 9\n1 1 1 0 0\n3 1 0 9 7\n6 2 0 0 3\n3 5 0 2 0\n6 5 8 0 9\n"
SAMPLE_OUT = "12\n"


def oracle(text):
    numbers = [int(piece) for piece in text.split()]
    cursor = 0
    courses = numbers[cursor]; cursor += 1
    restaurants = numbers[cursor]; cursor += 1
    budget = numbers[cursor]; cursor += 1
    rows = []
    columns = []
    prices = []
    for _ in range(restaurants):
        rows.append(numbers[cursor]); cursor += 1
        columns.append(numbers[cursor]); cursor += 1
        prices.append(numbers[cursor:cursor + courses])
        cursor += courses
    unreachable = 10**9
    layer = [[unreachable] * restaurants for _ in range(budget + 1)]
    for place in range(restaurants):
        opening = prices[place][0]
        if opening > 0 and opening <= budget:
            layer[opening][place] = 0
    for course in range(1, courses):
        following = [[unreachable] * restaurants for _ in range(budget + 1)]
        for place in range(restaurants):
            cost = prices[place][course]
            if cost <= 0:
                continue
            for spent in range(budget + 1 - cost):
                for previous in range(restaurants):
                    travel = layer[spent][previous]
                    if travel >= unreachable:
                        continue
                    distance = (abs(rows[previous] - rows[place])
                                + abs(columns[previous] - columns[place]))
                    candidate = travel + distance
                    cell = spent + cost
                    if candidate < following[cell][place]:
                        following[cell][place] = candidate
        layer = following
    answer = min(min(row) for row in layer)
    return "-1\n" if answer >= unreachable else str(answer) + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1 0\n1 1 5\n") == "-1\n"
assert oracle("1 1 10\n1 1 3\n") == "0\n"
assert oracle("2 2 10\n1 1 1 0\n3 1 0 1\n") == "2\n"
assert oracle("2 2 10\n1 1 1 1\n3 1 1 1\n") == "0\n"


def write(name, courses, budget, places):
    parts = [f"{courses} {len(places)} {budget}\n"]
    for row, column, costs in places:
        parts.append(f"{row} {column} " + " ".join(str(cost) for cost in costs) + "\n")
    input_text = "".join(parts)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", 3, 10, [
        (1, 1, [1, 0, 0]), (1, 1, [0, 1, 0]), (1, 1, [0, 0, 1]),
    ])

    rng = random.Random(20261125)
    wide_places = []
    for index in range(50):
        costs = [0] * 20
        for course in range(20):
            if rng.random() < 0.6:
                costs[course] = rng.randint(1, 40)
        wide_places.append((rng.randint(1, 1000), rng.randint(1, 1000), costs))
    write("3_wide", 20, 100, wide_places)

    random_places = []
    for index in range(60):
        costs = [0] * 20
        for course in range(20):
            if rng.random() < 0.55:
                costs[course] = rng.randint(1, 40)
        random_places.append((rng.randint(1, 1000), rng.randint(1, 1000), costs))
    write("4_random", 20, 100, random_places)

    io_places = []
    for index in range(20000):
        io_places.append((rng.randint(1, 1000), rng.randint(1, 1000),
                          [rng.randint(1, 40)]))
    write("5_io", 1, 100, io_places)


def worked_example():
    print("budget 9: restaurants 1 -> 4 -> 3")
    print("price sum: 1 + 0 + 5 = 6")
    print("walk: (1,1) to (6,2) = 6, (6,2) to (3,5) = 6")
    print("total travel: 12")


if "--trace" in sys.argv:
    worked_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", 3, 9, [
        (1, 1, [1, 0, 0]),
        (3, 1, [0, 9, 7]),
        (6, 2, [0, 0, 3]),
        (3, 5, [0, 2, 0]),
        (6, 5, [8, 0, 9]),
    ])
    build()
