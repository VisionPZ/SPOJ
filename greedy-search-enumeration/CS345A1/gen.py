#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def parse(text):
    tokens = text.split()
    index = 0
    count = int(tokens[index])
    index += 1
    blue = []
    for _ in range(count):
        first = float(tokens[index])
        second = float(tokens[index + 1])
        level = float(tokens[index + 2])
        index += 3
        blue.append((min(first, second), max(first, second), level))
    red = []
    for _ in range(count):
        first = float(tokens[index])
        second = float(tokens[index + 1])
        position = float(tokens[index + 2])
        index += 3
        red.append((min(first, second), max(first, second), position))
    return blue, red


class Fenwick:
    def __init__(self, size):
        self.tree = [0] * (size + 1)

    def add(self, index, delta):
        while index < len(self.tree):
            self.tree[index] += delta
            index += index & -index

    def total(self, index):
        result = 0
        while index > 0:
            result += self.tree[index]
            index -= index & -index
        return result


def oracle(text):
    blue, red = parse(text)
    coordinates = sorted({segment[2] for segment in red})
    coordinate_index = {value: index + 1 for index, value in enumerate(coordinates)}
    events = []
    for low_y, high_y, position in red:
        index = coordinate_index[position]
        events.append((low_y, 0, index))
        events.append((high_y, 2, index))
    for low_x, high_x, level in blue:
        left_index = 0
        right_index = len(coordinates)
        while left_index < right_index:
            middle = (left_index + right_index) // 2
            if coordinates[middle] < low_x:
                left_index = middle + 1
            else:
                right_index = middle
        first = left_index + 1
        left_index = 0
        right_index = len(coordinates)
        while left_index < right_index:
            middle = (left_index + right_index) // 2
            if high_x < coordinates[middle]:
                right_index = middle
            else:
                left_index = middle + 1
        last = right_index
        if first <= last:
            events.append((level, 1, first, last))
    events.sort(key=lambda event: (event[0], event[1]))
    tree = Fenwick(len(coordinates))
    count = 0
    for event in events:
        if event[1] == 0:
            tree.add(event[2], 1)
        elif event[1] == 2:
            tree.add(event[2], -1)
        else:
            count += tree.total(event[3]) - tree.total(event[2] - 1)
    return str(count) + "\n"


def brute(text):
    blue, red = parse(text)
    count = 0
    for low_x, high_x, level in blue:
        for low_y, high_y, position in red:
            if low_x <= position <= high_x and low_y <= level <= high_y:
                count += 1
    return str(count) + "\n"


SAMPLE = """3
0.36295 0.557494 0.184032
0.0479258 0.214097 0.508344
0.234284 0.969098 0.739363
0.499323 0.739797 0.138495
0.829265 0.22551 0.290582
0.791082 0.069214 0.450979
"""
SAMPLE_OUT = "4\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0.1 0.3 0.2\n0.2 0.4 0.3\n") == "1\n"
assert oracle("1\n0.1 0.3 0.2\n0.5 0.7 0.2\n") == "0\n"
assert oracle("2\n0.1 0.9 0.5\n0.2 0.8 0.5\n0.2 0.8 0.5\n0.1 0.9 0.5\n") == "4\n"


def write(name, blue, red):
    lines = [str(len(blue))]
    lines.extend(f"{first:.6f} {second:.6f} {level:.6f}" for first, second, level in blue)
    lines.extend(f"{first:.6f} {second:.6f} {position:.6f}" for first, second, position in red)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges",
          [(0.1, 0.3, 0.2), (0.4, 0.6, 0.8)],
          [(0.2, 0.4, 0.3), (0.7, 0.9, 0.5)])
    rng = random.Random(20261126)
    blue_small = []
    red_small = []
    for _ in range(30):
        first = rng.random()
        second = rng.random()
        blue_small.append((first, second, rng.random()))
        first = rng.random()
        second = rng.random()
        red_small.append((first, second, rng.random()))
    write("4_random", blue_small, red_small)
    write("3_wide",
          [(0.0, 1.0, 0.5)] * 100000,
          [(0.0, 1.0, 0.5)] * 100000)
    blue_io = [(0.25, 0.75, 0.25 + 0.5 * (index % 100) / 100) for index in range(50000)]
    red_io = [(0.25, 0.75, 0.25 + 0.5 * (index % 100) / 100) for index in range(50000)]
    write("5_io", blue_io, red_io)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
