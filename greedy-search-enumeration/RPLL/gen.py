#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
VECTORS = {"north": (0, 1), "south": (0, -1), "east": (1, 0), "west": (-1, 0)}


def ship_tuple(fields):
    start_x = int(fields[0])
    start_y = int(fields[1])
    direction = fields[2]
    speed = int(fields[3])
    vector_x, vector_y = VECTORS[direction]
    return (start_x, start_y, vector_x * speed, vector_y * speed)


def twice_area(ships, time_value):
    points = [(x + vx * time_value, y + vy * time_value)
              for x, y, vx, vy in ships]
    first, second, third = points
    return abs((second[0] - first[0]) * (third[1] - first[1]) -
               (second[1] - first[1]) * (third[0] - first[0]))


def oracle_case(max_area, ships):
    time_value = 0
    while twice_area(ships, time_value) <= 2 * max_area:
        time_value += 1
        if time_value > 10 ** 7:
            raise AssertionError("area never exceeded the search limit")
    answer = time_value - 1
    values = [twice_area(ships, moment) for moment in range(answer + 3)]
    assert all(left < right for left, right in zip(values, values[1:]))
    return answer


def oracle(text):
    lines = [line for line in text.splitlines() if line.strip()]
    case_count = int(lines[0])
    answers = []
    cursor = 1
    for case_index in range(case_count):
        max_area = int(lines[cursor])
        cursor += 1
        ships = []
        for _ in range(3):
            ships.append(ship_tuple(lines[cursor].split()))
            cursor += 1
        answers.append(f"Scenario #{case_index + 1}: {oracle_case(max_area, ships)}")
    return "\n".join(answers) + "\n"


SAMPLE = """2
150
1 4 north 2
2 0 south 2
3 1 east 2
12
0 -2 north 1
0 0 north 2
0 0 east 3
"""
SAMPLE_OUT = """Scenario #1: 5
Scenario #2: 2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_case(1, [(0, 0, 0, 1), (0, 0, 0, -1), (0, 0, 1, 0)]) == 1
assert oracle_case(200, [(0, 0, 0, 10), (0, 0, 0, -10), (0, 0, 10, 0)]) == 1
assert oracle_case(12, [(0, -2, 0, 1), (0, 0, 0, 2), (0, 0, 3, 0)]) == 2


def write(name, cases):
    chunks = [str(len(cases))]
    for max_area, ships in cases:
        chunks.append(str(max_area))
        for start_x, start_y, direction, speed in ships:
            chunks.append(f"{start_x} {start_y} {direction} {speed}")
    text = "\n".join(chunks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def make_case(max_area, ships):
    return (max_area, ships)


def build():
    base = [(0, 0, "north", 1), (0, 0, "south", 1), (0, 0, "east", 1)]
    wide = [(0, 0, "north", 10), (0, 0, "south", 10), (0, 0, "east", 10)]
    write("2_edges", [make_case(1, base), make_case(2, wide),
                      make_case(1000, [(0, 0, "north", 3), (0, 0, "south", 4),
                                       (0, 0, "east", 5)])])
    write("3_wide", [make_case(10 ** 9, wide),
                     make_case(999999999, wide),
                     make_case(10 ** 9, [(0, 0, "north", 10), (0, 0, "west", 10),
                                         (0, 0, "east", 10)])])
    rng = random.Random(20261126)
    random_cases = []
    while len(random_cases) < 30:
        max_area = rng.randint(1000, 10 ** 9)
        ships = []
        for direction in ("north", "south", "east"):
            ships.append((rng.randint(-5, 5), rng.randint(-5, 5),
                          direction, rng.randint(1, 10)))
        parsed = [ship_tuple(f"{x} {y} {direction} {speed}".split())
                  for x, y, direction, speed in ships]
        candidate = make_case(max_area, ships)
        try:
            oracle_case(max_area, parsed)
        except AssertionError:
            continue
        random_cases.append(candidate)
    write("4_random", random_cases)
    io_cases = []
    for index in range(200):
        speed = 1 + index % 10
        io_cases.append(make_case(1000 + index * 37,
                                  [(0, 0, "north", speed), (0, 0, "south", speed),
                                   (0, 0, "east", speed)]))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    (150, [(1, 4, "north", 2), (2, 0, "south", 2), (3, 1, "east", 2)]),
    (12, [(0, -2, "north", 1), (0, 0, "north", 2), (0, 0, "east", 3)]),
])
build()
