#!/usr/bin/env python3
import random
import sys
from pathlib import Path

sys.setrecursionlimit(200000)

ROOT = Path(__file__).resolve().parent


def pattern_number(cell):
    number = 0
    while (number + 1) * (number + 1) + number + 1 <= cell:
        number += 1
    return number


def print_direction(start_offset, segment_length, remaining, direction, parts):
    if segment_length <= remaining:
        next_remaining = remaining - segment_length + start_offset
        steps = segment_length - start_offset
    else:
        next_remaining = 0
        steps = remaining
    parts.append(str(steps) + direction)
    if next_remaining <= 0:
        return
    if direction == "U":
        print_direction(0, segment_length, next_remaining, "T", parts)
    elif direction == "T":
        print_direction(0, segment_length + 1, next_remaining, "S", parts)
    elif direction == "S":
        print_direction(0, segment_length, next_remaining, "B", parts)
    else:
        print_direction(0, segment_length + 1, next_remaining, "U", parts)


def oracle_case(start_cell, target_cell):
    number = pattern_number(start_cell)
    pattern_start = number * number + number
    offset = start_cell - pattern_start
    segment_length = number + 1
    distance = target_cell - start_cell
    parts = []
    if number % 2 == 0:
        if offset >= segment_length:
            print_direction(offset - segment_length, segment_length, distance, "T", parts)
        else:
            print_direction(offset, segment_length, distance, "U", parts)
    else:
        if offset >= segment_length:
            print_direction(offset - segment_length, segment_length, distance, "B", parts)
        else:
            print_direction(offset, segment_length, distance, "S", parts)
    return " -> ".join(parts)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    result = []
    position = 1
    for _ in range(case_count):
        result.append(oracle_case(tokens[position], tokens[position + 1]))
        position += 2
    return "\n".join(result) + "\n"


SAMPLE = """2
8 14
3 5
"""
SAMPLE_OUT = """1U -> 3T -> 2S
1S -> 1B
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0 1\n") == "1U\n"
assert oracle("1\n2 4\n") == "2S\n"
assert oracle("1\n6 9\n") == "3U\n"
assert oracle("1\n4 6\n") == "2B\n"
assert oracle("1\n8 9\n") == "1U\n"
assert oracle("1\n8 10\n") == "2U\n"


def write_cases(name, pairs):
    text = str(len(pairs)) + "\n"
    for start_cell, target_cell in pairs:
        text += f"{start_cell} {target_cell}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_cases("2_edges", [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 9), (9999990, 10000000)])
    write_cases("3_wide", [(start, start + span) for start in range(0, 200) for span in (1, 2, 3, 7)])
    rng = random.Random(20261126)
    write_cases("4_random", [
        (rng.randint(0, 50000), rng.randint(50001, 100000)) for _ in range(200)
    ])
    write_cases("5_io", [
        (rng.randint(0, 40), rng.randint(41, 120)) for _ in range(300)
    ])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
