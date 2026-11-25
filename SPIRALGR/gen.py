#!/usr/bin/env python3
import math
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MAX_NUMBER = 141 * 141


def coordinate(number):
    if number == 1:
        return (0, 0)
    ring = (math.isqrt(number - 1) + 1) // 2
    start = (2 * ring - 1) ** 2 + 1
    offset = number - start
    if offset < 2 * ring:
        return (ring, -(ring - 1) + offset)
    if offset < 4 * ring:
        return (ring - 1 - (offset - 2 * ring), ring)
    if offset < 6 * ring:
        return (-ring, ring - 1 - (offset - 4 * ring))
    return (-ring + 1 + (offset - 6 * ring), -ring)


def prime_flags(limit):
    flags = [True] * (limit + 1)
    flags[0] = flags[1] = False
    for value in range(2, math.isqrt(limit) + 1):
        if flags[value]:
            for multiple in range(value * value, limit + 1, value):
                flags[multiple] = False
    return flags


PRIME = prime_flags(MAX_NUMBER)
PASSABLE = {}
for number in range(1, MAX_NUMBER + 1):
    if number == 1 or not PRIME[number]:
        PASSABLE[coordinate(number)] = True


def shortest_path(start, end):
    if start == end:
        return 0
    queue = deque([(start, 0)])
    seen = {start}
    while queue:
        (current_x, current_y), distance = queue.popleft()
        for delta_x, delta_y in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            neighbor = (current_x + delta_x, current_y + delta_y)
            if neighbor in seen or neighbor not in PASSABLE:
                continue
            if neighbor == end:
                return distance + 1
            seen.add(neighbor)
            queue.append((neighbor, distance + 1))
    return None


def oracle(pairs):
    lines = []
    for index, (start, end) in enumerate(pairs):
        distance = shortest_path(coordinate(start), coordinate(end))
        lines.append(f"Case {index + 1}: " +
                     ("impossible" if distance is None else str(distance)))
    return "\n".join(lines) + "\n"


SAMPLE_PAIRS = [(1, 4), (9, 32), (10, 12)]
SAMPLE = "1 4\n9 32\n10 12\n"
SAMPLE_OUT = "Case 1: 1\nCase 2: 7\nCase 3: impossible\n"
assert oracle(SAMPLE_PAIRS) == SAMPLE_OUT
assert oracle([(1, 1)]) == "Case 1: 0\n"
assert oracle([(4, 4)]) == "Case 1: 0\n"
assert oracle([(10, 12)]) == "Case 1: impossible\n"
assert oracle([(25, 26)]) == "Case 1: 1\n"
assert oracle([(9802, 10000)]) == "Case 1: 198\n"


def write(name, pairs):
    text = "".join(f"{start} {end}\n" for start, end in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(pairs))


def random_pair(rng, maximum):
    while True:
        start = rng.randint(1, maximum)
        if start == 1 or not PRIME[start]:
            break
    while True:
        end = rng.randint(1, maximum)
        if end == 1 or not PRIME[end]:
            break
    return start, end


def build():
    rng = random.Random(20261126)
    write("2_edges", [(1, 1), (4, 4), (1, 4), (10, 12), (9, 32),
                      (10000, 10000), (9802, 10000)])
    write("3_wide", [random_pair(rng, 10000) for _ in range(200)])
    write("4_random", [random_pair(rng, 10000) for _ in range(300)])
    write("5_io", [random_pair(rng, 200) for _ in range(20000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_PAIRS)
build()
