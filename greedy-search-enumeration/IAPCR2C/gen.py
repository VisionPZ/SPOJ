#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for case_index in range(case_count):
        student_count = tokens[cursor]
        working_count = tokens[cursor + 1]
        cursor += 2
        intervals = []
        for _ in range(working_count):
            position = tokens[cursor]
            cursor += 1
            intervals.append((max(1, position - 1), min(student_count, position + 1)))
        intervals.sort()
        covered = 0
        current_first, current_last = intervals[0]
        for first_seat, last_seat in intervals[1:]:
            if first_seat > current_last + 1:
                covered += current_last - current_first + 1
                current_first, current_last = first_seat, last_seat
            elif last_seat > current_last:
                current_last = last_seat
        covered += current_last - current_first + 1
        answers.append(f"Case {case_index + 1}: {covered}\n")
    return "".join(answers)


def brute(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for case_index in range(case_count):
        student_count = tokens[cursor]
        working_count = tokens[cursor + 1]
        cursor += 2
        seats = set()
        for _ in range(working_count):
            position = tokens[cursor]
            cursor += 1
            for seat in (position - 1, position, position + 1):
                if 1 <= seat <= student_count:
                    seats.add(seat)
        answers.append(f"Case {case_index + 1}: {len(seats)}\n")
    return "".join(answers)


def input_text(cases):
    parts = [str(len(cases))]
    for student_count, positions in cases:
        parts.append(f"{student_count} {len(positions)}")
        parts.append(" ".join(str(position) for position in positions))
    return "\n".join(parts) + "\n"


SAMPLE = [(6, [2, 5]), (5, [2, 5])]
SAMPLE_OUT = "Case 1: 6\nCase 2: 5\n"
assert oracle(input_text(SAMPLE)) == SAMPLE_OUT
assert oracle("1\n1 1\n1\n") == "Case 1: 1\n"
assert oracle("1\n5 5\n1 2 3 4 5\n") == "Case 1: 5\n"
assert oracle("1\n4 2\n4 1\n") == "Case 1: 4\n"
assert brute(input_text(SAMPLE)) == SAMPLE_OUT

check_rng = random.Random(404)
for trial in range(200):
    student_count = check_rng.randint(1, 12)
    positions = check_rng.sample(range(1, student_count + 1),
                                 check_rng.randint(1, student_count))
    text = input_text([(student_count, positions)])
    assert oracle(text) == brute(text), (trial, text)


def build():
    edges = [(1, [1]), (2, [2]), (3, [1, 3]), (10, [10]), (9, [1, 9])]
    write("2_edges", edges)
    wide = [(100000, [100000] + [1] * 9),
            (100000, list(range(1, 100001, 2))),
            (100000, [50000, 50001])]
    write("3_wide", wide)
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(20):
        student_count = rng.randint(1, 2000)
        count = rng.randint(1, student_count)
        positions = rng.sample(range(1, student_count + 1), count)
        random_cases.append((student_count, positions))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(40):
        student_count = 100000
        positions = rng.sample(range(1, student_count + 1), 100000)
        io_cases.append((student_count, positions))
    write("5_io", io_cases)


def write(name, cases):
    text = input_text(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
