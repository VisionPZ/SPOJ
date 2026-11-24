#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def solve_direct(plants, goal):
    xs = sorted({x for x, y, f in plants})
    ys = sorted({y for x, y, f in plants})
    xslot = {v: j for j, v in enumerate(xs)}
    yslot = {v: j for j, v in enumerate(ys)}
    grid = [[0] * len(ys) for _ in xs]
    for x, y, f in plants:
        grid[xslot[x]][yslot[y]] += f
    best = 10**9
    for x1 in range(len(xs)):
        for x2 in range(x1, len(xs)):
            for y1 in range(len(ys)):
                for y2 in range(y1, len(ys)):
                    total = 0
                    for j in range(x1, x2 + 1):
                        for k in range(y1, y2 + 1):
                            total += grid[j][k]
                    if total >= goal:
                        area = (xs[x2] - xs[x1]) * (ys[y2] - ys[y1])
                        if area < best:
                            best = area
    return best


def solve_prefix(plants, goal):
    xs = sorted({x for x, y, f in plants})
    ys = sorted({y for x, y, f in plants})
    xslot = {v: j for j, v in enumerate(xs)}
    yslot = {v: j for j, v in enumerate(ys)}
    dx, dy = len(xs), len(ys)
    grid = [[0] * dy for _ in range(dx)]
    for x, y, f in plants:
        grid[xslot[x]][yslot[y]] += f
    prefix = [[0] * (dy + 1) for _ in range(dx + 1)]
    for j in range(dx):
        running = 0
        for k in range(dy):
            running += grid[j][k]
            prefix[j + 1][k + 1] = prefix[j][k + 1] + running
    best = 10**9
    for x1 in range(dx):
        for x2 in range(x1, dx):
            for y1 in range(dy):
                for y2 in range(y1, dy):
                    total = (prefix[x2 + 1][y2 + 1] - prefix[x1][y2 + 1]
                             - prefix[x2 + 1][y1] + prefix[x1][y1])
                    if total >= goal:
                        area = (xs[x2] - xs[x1]) * (ys[y2] - ys[y1])
                        if area < best:
                            best = area
    return best


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        plant_count = int(tokens[cursor]); cursor += 1
        goal = int(tokens[cursor]); cursor += 1
        plants = []
        for _ in range(plant_count):
            x = int(tokens[cursor]); cursor += 1
            y = int(tokens[cursor]); cursor += 1
            f = int(tokens[cursor]); cursor += 1
            plants.append((x, y, f))
        answers.append(str(solve_prefix(plants, goal)))
    return "\n".join(answers) + "\n"


def write_cases(name, cases):
    lines = [str(len(cases))]
    for plants, goal in cases:
        lines.append(f"{len(plants)} {goal}")
        lines.extend(f"{x} {y} {f}" for x, y, f in plants)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


SAMPLE = "1\n6 11\n1 1 2\n1 2 2\n3 1 2\n3 2 3\n4 2 5\n3 3 2\n"

assert oracle(SAMPLE) == "2\n"
assert solve_prefix([(5, 5, 7)], 7) == 0
assert solve_prefix([(2, 10, 1), (1, 1, 5), (500, 500, 9)], 15) == 499 * 499
assert oracle("1\n2 10\n1 1 5\n4 7 5\n") == "18\n"

check_rng = random.Random(11)
for trial in range(60):
    plants = [(check_rng.randint(1, 6), check_rng.randint(1, 6),
               check_rng.randint(1, 5))
              for _ in range(check_rng.randint(1, 4))]
    goal = check_rng.randint(1, sum(f for x, y, f in plants))
    assert solve_prefix(plants, goal) == solve_direct(plants, goal)


def build():
    edges = [
        ([(5, 5, 7)], 7),
        ([(5, 1, 3), (5, 4, 4), (5, 9, 5)], 12),
        ([(1, 5, 3), (4, 5, 4), (9, 5, 5)], 12),
        ([(2, 2, 4), (2, 2, 6)], 10),
        ([(1, 1, 2), (9, 9, 3)], 5),
        ([(10, 10, 1), (1, 1, 1), (500, 500, 8), (1000, 1000, 1)], 11),
    ]
    write_cases("2_edges", edges)

    rng = random.Random(7001)
    wide_x = sorted(rng.sample(range(1, 1001), 24))
    wide_y = sorted(rng.sample(range(1, 1001), 24))
    wide_plants = [(rng.choice(wide_x), rng.choice(wide_y), rng.randint(1, 50))
                   for _ in range(1000)]
    wide_goal = sum(f for x, y, f in wide_plants)
    write_cases("3_wide", [(wide_plants, 1), (wide_plants, wide_goal)])

    rng = random.Random(2026)
    random_cases = []
    for case_index in range(100):
        xs = sorted(rng.sample(range(1, 1001), 12))
        ys = sorted(rng.sample(range(1, 1001), 12))
        plants = [(rng.choice(xs), rng.choice(ys), rng.randint(1, 20))
                  for _ in range(rng.randint(1, 1000))]
        goal = rng.randint(1, sum(f for x, y, f in plants))
        random_cases.append((plants, goal))
    write_cases("4_random", random_cases)

    rng = random.Random(31337)
    io_cases = []
    for case_index in range(100):
        xs = sorted(rng.sample(range(1, 1001), 12))
        ys = sorted(rng.sample(range(1, 1001), 12))
        plants = [(rng.choice(xs), rng.choice(ys), rng.randint(1, 20))
                  for _ in range(1000)]
        goal = sum(f for x, y, f in plants) - rng.randint(0, 30)
        io_cases.append((plants, goal))
    write_cases("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text("2\n")
build()
