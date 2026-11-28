#!/usr/bin/env python3
import random
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent


def brute_min_waste(slab_width, slab_height, plates):
    plate_set = frozenset(plates)
    memo = {}

    def solve(width, height):
        key = (width, height)
        if key in memo:
            return memo[key]
        if key in plate_set:
            memo[key] = 0
            return 0
        best = width * height
        for cut in range(1, width):
            value = solve(cut, height) + solve(width - cut, height)
            if value < best:
                best = value
            if best == 0:
                break
        if best > 0:
            for cut in range(1, height):
                value = solve(width, cut) + solve(width, height - cut)
                if value < best:
                    best = value
                if best == 0:
                    break
        memo[key] = best
        return best

    return solve(slab_width, slab_height)


def oracle_solve(slab_width, slab_height, plates):
    plate_heights = {}
    for plate_width, plate_height in plates:
        plate_heights.setdefault(plate_width, set()).add(plate_height)
    waste = np.zeros((slab_width + 1, slab_height + 1), dtype=np.int64)
    heights = np.arange(1, slab_height + 1, dtype=np.int64)
    for width in range(1, slab_width + 1):
        row = np.zeros(slab_height + 1, dtype=np.int64)
        row[1:] = width * heights
        for cut in range(1, width):
            np.minimum(row[1:], waste[cut, 1:] + waste[width - cut, 1:], out=row[1:])
        for plate_height in plate_heights.get(width, ()):
            row[plate_height] = 0
        for cut in range(1, slab_height):
            tail = slab_height - cut
            np.minimum(row[cut + 1:], row[cut] + row[1:tail + 1], out=row[cut + 1:])
        waste[width] = row
    return int(waste[slab_width, slab_height])


assert oracle_solve(21, 11, [(10, 4), (6, 2), (7, 5), (15, 10)]) == 10
assert oracle_solve(10, 10, [(3, 3)]) == 19
assert oracle_solve(6, 5, [(5, 5)]) == 5
assert oracle_solve(600, 600, [(301, 301)]) == 269399
for _ in range(120):
    check_width = random.randint(1, 11)
    check_height = random.randint(1, 11)
    check_plates = [(random.randint(1, check_width), random.randint(1, check_height))
                    for _ in range(random.randint(1, 7))]
    assert oracle_solve(check_width, check_height, check_plates) == brute_min_waste(
        check_width, check_height, check_plates)


def write_case(name, cases):
    lines = [str(len(cases))]
    answers = []
    for width, height, plates in cases:
        lines.append(f"{width} {height}")
        lines.append(str(len(plates)))
        for plate_width, plate_height in plates:
            lines.append(f"{plate_width} {plate_height}")
        answers.append(str(oracle_solve(width, height, plates)))
    (ROOT / "in" / f"{name}.txt").write_text("\n".join(lines) + "\n")
    (ROOT / "out" / f"{name}.out").write_text("\n".join(answers) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)

write_case("1_sample", [(21, 11, [(10, 4), (6, 2), (7, 5), (15, 10)])])

write_case("2_edges", [
    (1, 1, [(1, 1)]),
    (1, 1, [(1, 1)] * 200),
    (2, 2, [(1, 1)]),
    (6, 5, [(5, 5)]),
    (10, 10, [(3, 3)]),
    (8, 5, [(6, 4)]),
    (600, 600, [(600, 600)]),
    (600, 1, [(600, 1)]),
    (1, 600, [(1, 600)]),
    (7, 5, [(7, 5), (7, 4), (6, 5)]),
])

write_case("3_wide", [
    (600, 600, [(600, 600)]),
    (600, 600, [(599, 599)]),
    (600, 600, [(300, 300)]),
    (600, 600, [(301, 301)] * 200),
    (600, 1, [(1, 1)] * 200),
    (1, 600, [(1, 1)] * 200),
])

rng = random.Random(20261125)
random_cases = []
for _ in range(20):
    case_width = rng.randint(2, 30)
    case_height = rng.randint(2, 30)
    count = rng.randint(1, 30)
    plate_list = [(rng.randint(1, case_width), rng.randint(1, case_height))
                  for _ in range(count)]
    random_cases.append((case_width, case_height, plate_list))
write_case("4_random", random_cases)

write_case("5_io", [(600, 600, [(301, 301)] * 200) for _ in range(20)])
