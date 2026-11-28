#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def normalize(rectangle):
    x1, y1, x2, y2 = rectangle
    return (min(x1, x2), min(y1, y2), max(x1, x2), max(y1, y2))


def doors_between(first, second):
    left_a, bottom_a, right_a, top_a = first
    left_b, bottom_b, right_b, top_b = second
    if right_a == left_b or right_b == left_a:
        overlap_start = max(bottom_a, bottom_b)
        overlap_end = min(top_a, top_b)
        if overlap_end - overlap_start > 2:
            return ("vertical", right_a if right_a == left_b else right_b, overlap_start + 1, overlap_end - 1)
    if top_a == bottom_b or top_b == bottom_a:
        overlap_start = max(left_a, left_b)
        overlap_end = min(right_a, right_b)
        if overlap_end - overlap_start > 2:
            return ("horizontal", top_a if top_a == bottom_b else top_b, overlap_start + 1, overlap_end - 1)
    return None


def oracle_case(rectangles):
    rooms = [normalize(rectangle) for rectangle in rectangles]
    leftmost = min(room[0] for room in rooms)
    rightmost = max(room[2] for room in rooms)
    lowest = min(room[1] for room in rooms)
    highest = max(room[3] for room in rooms)
    cell_owner = {}
    for room_index, (left, bottom, right, top) in enumerate(rooms):
        for x_coord in range(left, right):
            for y_coord in range(bottom, top):
                cell_owner[(x_coord, y_coord)] = room_index
    doors = {}
    for first_index in range(len(rooms)):
        for second_index in range(first_index + 1, len(rooms)):
            door = doors_between(rooms[first_index], rooms[second_index])
            if door is not None:
                doors[(first_index, second_index)] = door
    largest_square = min(rightmost - leftmost, highest - lowest)
    total = 0
    for size in range(1, largest_square + 1):
        for start_x in range(leftmost, rightmost - size + 1):
            for start_y in range(lowest, highest - size + 1):
                owners = set()
                covered = True
                for x_coord in range(start_x, start_x + size):
                    for y_coord in range(start_y, start_y + size):
                        owner = cell_owner.get((x_coord, y_coord))
                        if owner is None:
                            covered = False
                            break
                        owners.add(owner)
                    if not covered:
                        break
                if not covered or len(owners) == 0:
                    continue
                if len(owners) == 1:
                    total += 1
                    continue
                if len(owners) != 2:
                    continue
                first_index, second_index = sorted(owners)
                door = doors.get((first_index, second_index))
                if door is None:
                    continue
                orientation, wall, gap_start, gap_end = door
                if orientation == "vertical":
                    crosses = start_x < wall < start_x + size
                    along_start = start_y
                else:
                    crosses = start_y < wall < start_y + size
                    along_start = start_x
                if crosses and along_start >= gap_start and along_start + size <= gap_end:
                    total += 1
    return total


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    answers = []
    while position < len(tokens):
        room_count = tokens[position]
        position += 1
        if room_count == 0:
            break
        rooms = []
        for _ in range(room_count):
            rooms.append(tuple(tokens[position + offset] for offset in range(4)))
            position += 4
        answers.append(f"Case {len(answers) + 1}: {oracle_case(rooms)}")
    return "".join(answer + "\n" for answer in answers)


SAMPLE = """2
0 0 9 3
10 6 4 3
3
11 20 15 24
11 17 15 20
15 16 20 24
0
"""
SAMPLE_OUT = """Case 1: 86
Case 2: 152
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_case([(0, 0, 2, 2)]) == 5
assert oracle_case([(0, 0, 3, 2)]) == 8
assert oracle_case([(0, 0, 2, 3), (2, 0, 4, 3)]) == 16
assert oracle_case([(0, 0, 2, 4), (2, 0, 4, 4)]) == 23


def write_case(name, cases):
    lines = []
    for rooms in cases:
        lines.append(f"{len(rooms)}\n")
        lines.extend(f"{a} {b} {c} {d}\n" for a, b, c, d in rooms)
    lines.append("0\n")
    text = "".join(lines)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def partition(rng, left, bottom, right, top, depth):
    width = right - left
    height = top - bottom
    if depth == 0 or (width <= 2 and height <= 2) or rng.random() < 0.25:
        return [(left, bottom, right, top)]
    if width >= height and width > 2:
        cut = rng.randint(left + 1, right - 1)
        return partition(rng, left, bottom, cut, top, depth - 1) + partition(rng, cut, bottom, right, top, depth - 1)
    if height > 2:
        cut = rng.randint(bottom + 1, top - 1)
        return partition(rng, left, bottom, right, cut, depth - 1) + partition(rng, left, cut, right, top, depth - 1)
    return [(left, bottom, right, top)]


def build():
    write_case("2_edges", [
        [(0, 0, 1, 1)],
        [(0, 0, 3, 2)],
        [(0, 0, 2, 3), (2, 0, 4, 3)],
        [(0, 0, 2, 4), (2, 0, 4, 4)],
        [(0, 0, 6, 4), (6, 1, 10, 5)],
    ])
    rng = random.Random(20261126)
    write_case("3_wide", [partition(rng, 0, 0, 20, 16, 4), partition(rng, 0, 0, 18, 18, 3)])
    cases = []
    for _ in range(10):
        cases.append(partition(rng, 0, 0, rng.randint(6, 14), rng.randint(6, 14), 3))
    write_case("4_random", cases)
    rng = random.Random(570133)
    cases = []
    for _ in range(250):
        cases.append(partition(rng, 0, 0, rng.randint(3, 8), rng.randint(3, 8), 2))
    write_case("5_io", cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
