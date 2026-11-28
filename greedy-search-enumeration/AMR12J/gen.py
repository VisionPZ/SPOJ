#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = """4
0 0 10 10
2 3 7 8
3 4 5 6
12 10 13 15
"""
SAMPLE_OUT = """-1
0
1
-1
"""


def oracle(text):
    tokens = [int(value) for value in text.split()]
    room_count = tokens[0]
    rooms = []
    for index in range(room_count):
        base = 1 + 4 * index
        rooms.append(tuple(tokens[base:base + 4]))
    answers = []
    for index in range(room_count):
        west, south, east, north = rooms[index]
        best_room = -1
        best_area = None
        for other in range(room_count):
            if other == index:
                continue
            other_west, other_south, other_east, other_north = rooms[other]
            if (other_west < west and other_south < south and
                    other_east > east and other_north > north):
                area = (other_east - other_west) * (other_north - other_south)
                if best_area is None or area < best_area:
                    best_area = area
                    best_room = other
        answers.append(str(best_room))
    return "\n".join(answers) + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0 0 1 1\n") == "-1\n"
assert oracle("2\n0 0 10 10\n1 1 9 9\n") == "-1\n0\n"
assert oracle("3\n0 0 10 10\n20 0 30 10\n1 1 9 9\n") == "-1\n-1\n0\n"


def make_case(cluster_lengths, rng):
    rooms = []
    for cluster_index, length in enumerate(cluster_lengths):
        slot_start = cluster_index * 10 ** 8 + 1
        xs = sorted(rng.sample(range(slot_start, slot_start + 10 ** 8 - 1), 2 * length))
        ys = sorted(rng.sample(range(1, 10 ** 9), 2 * length))
        for depth in range(length):
            rooms.append((xs[depth], ys[depth], xs[2 * length - 1 - depth], ys[2 * length - 1 - depth]))
    rng.shuffle(rooms)
    text = str(len(rooms)) + "\n"
    for room in rooms:
        text += " ".join(str(value) for value in room) + "\n"
    return text


def write(name, text):
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", make_case([1, 2, 1], rng))
    write("3_wide", make_case([6, 5], rng))
    write("4_random", make_case([4, 3, 5, 2, 4], rng))
    write("5_io", make_case([30] * 20, rng))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
