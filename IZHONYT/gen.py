#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = """6 3
2 5 1 4 6 3
"""
SAMPLE_OUT = """1 1 2 2 1 3
2 1 3 2 1 1
"""


def lds_oracle(wagons):
    count = len(wagons)
    tree = [0] * (count + 2)

    def update(index, value):
        while index <= count:
            if value > tree[index]:
                tree[index] = value
            index += index & -index

    def query(index):
        best = 0
        while index > 0:
            if tree[index] > best:
                best = tree[index]
            index -= index & -index
        return best

    tracks = []
    for wagon in wagons:
        reverse_index = count - wagon + 1
        length = query(reverse_index - 1) + 1
        tracks.append(length)
        update(reverse_index, length)
    return tracks


def oracle(text):
    tokens = [int(value) for value in text.split()]
    wagon_count = tokens[0]
    wagons = tokens[2:2 + wagon_count]
    tracks = lds_oracle(wagons)
    label_tracks = [0] * (wagon_count + 1)
    for wagon, track in zip(wagons, tracks):
        label_tracks[wagon] = track
    first_line = " ".join(str(track) for track in tracks)
    second_line = " ".join(str(label_tracks[label]) for label in range(1, wagon_count + 1))
    return first_line + "\n" + second_line + "\n"


def brute_lexicographic(wagons, track_limit):
    assignment = []
    lasts = []

    def search(position):
        if position == len(wagons):
            return True
        wagon = wagons[position]
        for track in range(track_limit):
            if track < len(lasts) and lasts[track] >= wagon:
                continue
            old_length = len(lasts)
            if track == len(lasts):
                lasts.append(wagon)
            else:
                previous = lasts[track]
                lasts[track] = wagon
            assignment.append(track + 1)
            if search(position + 1):
                return True
            assignment.pop()
            if len(lasts) > old_length:
                lasts.pop()
            else:
                lasts[track] = previous
        return False

    assert search(0)
    return assignment


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n1\n") == "1\n1\n"
assert oracle("4 4\n4 3 2 1\n") == "1 2 3 4\n4 3 2 1\n"
assert oracle("5 5\n1 2 3 4 5\n") == "1 1 1 1 1\n1 1 1 1 1\n"

rng = random.Random(20261126)
for _ in range(200):
    count = rng.randint(1, 8)
    wagons = list(range(1, count + 1))
    rng.shuffle(wagons)
    text = f"{count} {count}\n" + " ".join(str(wagon) for wagon in wagons) + "\n"
    assert oracle(text).splitlines()[0] == " ".join(
        str(track) for track in brute_lexicographic(wagons, count))


def write(name, wagon_count, rng):
    wagons = list(range(1, wagon_count + 1))
    rng.shuffle(wagons)
    text = f"{wagon_count} {wagon_count}\n" + " ".join(str(wagon) for wagon in wagons) + "\n"
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(text))


def build():
    generator = random.Random(20261126)
    (ROOT / "in" / "2_edges.txt").write_text("1 1\n1\n")
    (ROOT / "out" / "2_edges.out").write_text(oracle("1 1\n1\n"))
    (ROOT / "in" / "3_wide.txt").write_text("10 10\n" + " ".join(str(v) for v in range(10, 0, -1)) + "\n")
    (ROOT / "out" / "3_wide.out").write_text(oracle((ROOT / "in" / "3_wide.txt").read_text()))
    write("4_random", 200, generator)
    write("5_io", 200000, generator)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
