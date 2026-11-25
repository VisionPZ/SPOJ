#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    results = []
    case_number = 1
    while True:
        house_count = tokens[position]
        position += 1
        if house_count == 0:
            break
        houses = []
        for _ in range(house_count):
            house_x = tokens[position]
            house_y = tokens[position + 1]
            position += 2
            houses.append((house_x, house_y))
        center_ax = tokens[position]
        center_ay = tokens[position + 1]
        center_bx = tokens[position + 2]
        center_by = tokens[position + 3]
        query_count = tokens[position + 4]
        position += 5
        results.append(f"Case {case_number}:")
        for _ in range(query_count):
            radius_first = tokens[position]
            radius_second = tokens[position + 1]
            position += 2
            count = 0
            for house_x, house_y in houses:
                first_sq = (house_x - center_ax) ** 2 + (house_y - center_ay) ** 2
                second_sq = (house_x - center_bx) ** 2 + (house_y - center_by) ** 2
                if first_sq <= radius_first ** 2 and second_sq <= radius_second ** 2:
                    count += 1
            results.append(str(count))
        case_number += 1
    return "\n".join(results) + "\n"


SAMPLE = """11
95 75
27 6
93 5
124 13
34 49
65 61
81 49
77 33
110 50
91 22
110 25
57 42 97 36 1
31 25
0
"""
SAMPLE_OUT = """Case 1:
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n5 5\n0 0 10 10 1\n1 1\n0\n") == "Case 1:\n0\n"
assert oracle("1\n5 5\n0 0 10 10 1\n100 100\n0\n") == "Case 1:\n1\n"
assert oracle("1\n0 0\n0 0 5 0 1\n5 5\n1\n0 0\n0 0 0 0 1\n1 1\n0\n") == "Case 1:\n1\nCase 2:\n1\n"


def write(name, cases):
    text = ""
    for houses, centers, queries in cases:
        text += str(len(houses)) + "\n"
        for house_x, house_y in houses:
            text += f"{house_x} {house_y}\n"
        center_ax, center_ay, center_bx, center_by = centers
        text += f"{center_ax} {center_ay} {center_bx} {center_by} {len(queries)}\n"
        for radius_first, radius_second in queries:
            text += f"{radius_first} {radius_second}\n"
    text += "0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [([(0, 0)], (0, 0, 0, 0), [(1, 1), (13000, 13000)]),
                      ([(100, 100)], (0, 0, 200, 200), [(141, 141), (142, 142)])])
    rng = random.Random(20261126)
    wide_houses = [(rng.randint(0, 20000), rng.randint(0, 20000)) for _ in range(200)]
    wide_queries = [(rng.randint(1, 13000), rng.randint(1, 13000)) for _ in range(30)]
    write("3_wide", [(wide_houses, (4132, 7712, 15551, 3222), wide_queries)])
    random_cases = []
    for _ in range(2):
        houses = [(rng.randint(0, 20000), rng.randint(0, 20000)) for _ in range(180)]
        centers = (rng.randint(0, 20000), rng.randint(0, 20000),
                   rng.randint(0, 20000), rng.randint(0, 20000))
        queries = [(rng.randint(1, 13000), rng.randint(1, 13000)) for _ in range(45)]
        random_cases.append((houses, centers, queries))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(3):
        houses = [(rng.randint(0, 20000), rng.randint(0, 20000)) for _ in range(250)]
        centers = (rng.randint(0, 20000), rng.randint(0, 20000),
                   rng.randint(0, 20000), rng.randint(0, 20000))
        queries = [(rng.randint(1, 13000), rng.randint(1, 13000)) for _ in range(300)]
        io_cases.append((houses, centers, queries))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
