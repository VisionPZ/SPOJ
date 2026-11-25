#!/usr/bin/env python3
import itertools
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10 ** 9


def oracle(cows, barn_target):
    spots = sorted((col, row) for row, col in cows)
    columns = [col for col, _ in spots]
    cow_rows = [row for _, row in spots]
    cow_total = len(spots)
    full_mask = (1 << cow_total) - 1
    row_counts = {1: 0, 2: 0}

    @lru_cache(maxsize=None)
    def search(covered, used):
        if used > barn_target:
            return INF
        if covered == full_mask:
            return 0 if used == barn_target else INF
        first = 0
        while covered & (1 << first):
            first += 1
        left = columns[first]
        need_row = cow_rows[first]
        right_edge = {1: -1, 2: -1}
        for index in range(cow_total):
            if covered & (1 << index):
                row = cow_rows[index]
                if columns[index] > right_edge[row]:
                    right_edge[row] = columns[index]
        best = INF
        for right in set(columns[first:]):
            for barn_mask in (1, 2, 3):
                if not (barn_mask & need_row):
                    continue
                blocked = False
                for row in (1, 2):
                    if (barn_mask & row) and right_edge[row] >= left:
                        blocked = True
                if blocked:
                    continue
                next_covered = covered
                for index in range(first, cow_total):
                    if (barn_mask & cow_rows[index]) and columns[index] <= right:
                        next_covered |= 1 << index
                area = (right - left + 1) * row_counts[barn_mask]
                tail = search(next_covered, used + 1)
                if tail + area < best:
                    best = tail + area
        return best

    row_counts[1] = 1
    row_counts[2] = 1
    row_counts[3] = 2
    return search(0, 0)


def brute_force(cows, barn_target):
    spots = list((row, col) for row, col in cows)
    needed = frozenset(spots)
    columns = sorted({col for _, col in spots})
    rectangles = []
    for row_mask in (1, 2, 3):
        for start in columns:
            for end in columns:
                if end < start:
                    continue
                cells = frozenset(
                    (row, col)
                    for row in (1, 2)
                    if row_mask & row
                    for col in range(start, end + 1)
                )
                rectangles.append((cells, bin(row_mask).count("1") * (end - start + 1)))
    best = INF
    for choice in itertools.combinations(range(len(rectangles)), barn_target):
        occupied = set()
        total = 0
        valid = True
        for index in choice:
            cells, area = rectangles[index]
            if cells & occupied:
                valid = False
                break
            occupied |= cells
            total += area
        if valid and needed <= occupied and total < best:
            best = total
    return best


assert oracle([(1, 2), (1, 6), (1, 7), (1, 8), (1, 9), (2, 2), (2, 3), (2, 4)], 2) == 10
assert oracle([(1, 5), (2, 5)], 1) == 2
assert oracle([(1, 5), (2, 5)], 2) == 2

check_rng = random.Random(4242)
for trial in range(40):
    cow_total = check_rng.randint(1, 6)
    spots = []
    for _ in range(cow_total):
        spots.append((check_rng.randint(1, 2), check_rng.randint(1, 6)))
    spots = list(dict.fromkeys(spots))
    for barn_target in range(1, min(3, len(spots)) + 1):
        assert oracle(spots, barn_target) == brute_force(spots, barn_target)


def as_text(cases):
    lines = [str(len(cases))]
    for cow_total, barn_target, width, spots in cases:
        lines.append(f"{cow_total} {barn_target} {width}")
        for row, col in spots:
            lines.append(f"{row} {col}")
    return "\n".join(lines) + "\n"


def expected(cases):
    return "".join(str(oracle(spots, barn_target)) + "\n"
                   for _, barn_target, _, spots in cases)


def write(name, cases):
    (ROOT / "in" / f"{name}.txt").write_text(as_text(cases))
    (ROOT / "out" / f"{name}.out").write_text(expected(cases))


SAMPLE = [
    (8, 2, 9, [(1, 2), (1, 6), (1, 7), (1, 8), (1, 9), (2, 2), (2, 3), (2, 4)])
]
assert expected(SAMPLE) == "10\n"


def edges():
    return [
        (1, 1, 1, [(1, 1)]),
        (2, 1, 1, [(1, 1), (2, 1)]),
        (2, 2, 5, [(1, 5), (2, 5)]),
        (2, 1, 10, [(1, 1), (2, 10)]),
        (4, 1, 9, [(1, 1), (1, 3), (1, 6), (1, 9)]),
        (4, 2, 9, [(1, 1), (1, 3), (1, 6), (1, 9)]),
        (4, 4, 9, [(1, 1), (1, 3), (1, 6), (1, 9)]),
        (5, 2, 15000000, [(1, 1), (1, 15000000), (2, 1), (2, 2), (2, 15000000)]),
        (6, 3, 15000000, [(1, 1), (1, 14999999), (1, 15000000),
                           (2, 1), (2, 2), (2, 15000000)]),
    ]


def wide():
    rng = random.Random(20261125)
    cases = []
    for _ in range(6):
        low = rng.choice([1, 2, 3, 15000000 - 40, 15000000 - 12])
        high = rng.choice([12, 40, 15000000])
        if high < low:
            low, high = high, low
        spots = []
        while len(spots) < 12:
            spots.append((rng.randint(1, 2), rng.randint(low, high)))
            spots = list(dict.fromkeys(spots))
        cases.append((12, rng.randint(1, 12), 15000000, spots))
    return cases


def randomized():
    rng = random.Random(20261126)
    cases = []
    for _ in range(20):
        width = rng.randint(1, 15000000)
        cow_total = rng.randint(1, 12)
        spots = []
        while len(spots) < cow_total:
            spots.append((rng.randint(1, 2), rng.randint(1, width)))
            spots = list(dict.fromkeys(spots))
        cow_total = len(spots)
        cases.append((cow_total, rng.randint(1, cow_total), width, spots))
    return cases


def io_cases(count):
    rng = random.Random(20261127)
    cases = []
    for _ in range(count):
        spots = []
        while len(spots) < 4:
            spots.append((rng.randint(1, 2), rng.randint(1, 30)))
            spots = list(dict.fromkeys(spots))
        cases.append((4, rng.randint(1, 4), rng.randint(4, 30), spots))
    return cases


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
write("2_edges", edges())
write("3_wide", wide())
write("4_random", randomized())
write("5_io", io_cases(20000))

big_rng = random.Random(20261128)
big_spots = set()
while len(big_spots) < 1000:
    big_spots.add((big_rng.randint(1, 2), big_rng.randint(1, 15000000)))
big_spots = sorted(big_spots)
Path("/tmp/LAZYCOWS_big.txt").write_text(
    as_text([(1000, 500, 15000000, big_spots)]))
Path("/tmp/LAZYCOWS_io_big.txt").write_text(as_text(io_cases(50000)))

print("generated five pairs and two stress files")
