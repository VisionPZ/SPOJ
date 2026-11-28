#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_case(range_limit, cities, towers):
    ordered = sorted(towers, key=lambda item: item[0])
    locations = [item[0] for item in ordered]
    costs = [item[1] for item in ordered]
    tower_count = len(ordered)
    best = 0
    for mask in range(1 << tower_count):
        profit = -sum(costs[index] for index in range(tower_count) if mask >> index & 1)
        for city_x in cities:
            nearest = -1
            for index in range(tower_count):
                if locations[index] < city_x:
                    nearest = index
                else:
                    break
            chain_index = nearest
            while chain_index >= 0:
                distance = city_x - locations[chain_index]
                if distance > range_limit or not (mask >> chain_index & 1):
                    break
                profit += range_limit - distance
                chain_index -= 4
        if profit > best:
            best = profit
    return best


def oracle(text):
    tokens = text.split()
    cursor = 0
    answers = []
    while True:
        first = int(tokens[cursor]); cursor += 1
        second = int(tokens[cursor]); cursor += 1
        third = int(tokens[cursor]); cursor += 1
        if first == -1 and second == -1 and third == -1:
            break
        cities = [int(tokens[cursor + index]) for index in range(second)]
        cursor += second
        towers = []
        for _ in range(third):
            towers.append((int(tokens[cursor]), int(tokens[cursor + 1])))
            cursor += 2
        answers.append(str(oracle_case(first, cities, towers)))
    return "\n".join(answers) + "\n" if answers else ""


SAMPLE = """4 9 6
23
43
18
15
29
50
41
31
40
32 2
26 0
46 7
48 0
50 3
38 1
-1 -1 -1
"""
SAMPLE_OUT = """5
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2 1 1\n5\n3 0\n-1 -1 -1\n") == "0\n"
assert oracle("3 1 1\n5\n3 0\n-1 -1 -1\n") == "1\n"
assert oracle("1 1 2\n5\n3 0\n1 5\n-1 -1 -1\n") == "0\n"
assert oracle("100 1 9\n10\n" + "".join(f"{value} 0\n" for value in range(1, 10)) +
              "-1 -1 -1\n") == "285\n"
assert oracle_case(4, [29], [(26, 0), (32, 2)]) == 1


def write(name, cases):
    lines = []
    for range_limit, cities, towers in cases:
        lines.append(f"{range_limit} {len(cities)} {len(towers)}")
        lines.extend(str(value) for value in cities)
        lines.extend(f"{location} {cost}" for location, cost in towers)
    lines.append("-1 -1 -1")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (0, [], []),
        (2, [5], [(3, 0)]),
        (2, [5], [(3, 7)]),
        (100, [10], [(value, 0) for value in range(1, 10)]),
        (1000000000, [500000000], [(100000000, 1000000000), (200000000, 0)]),
    ])
    rng = random.Random(20261126)
    wide = []
    for _ in range(10):
        count = 12
        locations = rng.sample(range(1, 100000000), count)
        cities = rng.sample(range(200000000, 400000000), 100)
        towers = [(location, rng.randint(0, 1000000000)) for location in locations]
        wide.append((1000000000, cities, towers))
    write("3_wide", wide)
    random_cases = []
    for _ in range(20):
        tower_count = rng.randint(0, 10)
        city_count = rng.randint(0, 50)
        locations = rng.sample(range(1, 200), tower_count)
        cities = rng.sample(range(300, 600), city_count)
        towers = [(location, rng.randint(0, 100)) for location in locations]
        random_cases.append((rng.randint(0, 200), cities, towers))
    write("4_random", random_cases)
    io_cases = []
    for index in range(20000):
        io_cases.append((1000000000, [1000000000 + index], [(1, 0)]))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
