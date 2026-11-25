#!/usr/bin/env python3
import heapq
import random
from math import isqrt
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    answers = []
    for _ in range(case_count):
        length = tokens[cursor]
        moves = tokens[cursor + 1]
        cursor += 2
        heap = [-value for value in range(1, length + 1)]
        heapq.heapify(heap)
        for _ in range(moves):
            largest = -heapq.heappop(heap)
            heapq.heappush(heap, -isqrt(largest))
        answers.append(str(-sum(heap)) + "\n")
    return "".join(answers)


def gain_method(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    answers = []
    for _ in range(case_count):
        length = tokens[cursor]
        moves = tokens[cursor + 1]
        cursor += 2
        gains = []
        for value in range(1, length + 1):
            current = value
            while current > 1:
                child = isqrt(current)
                gains.append(current - child)
                current = child
        gains.sort(reverse=True)
        answers.append(str(length * (length + 1) // 2 - sum(gains[:moves])) + "\n")
    return "".join(answers)


def input_text(cases):
    parts = [str(len(cases))]
    for length, moves in cases:
        parts.append(str(length))
        parts.append(str(moves))
    return "\n".join(parts) + "\n"


SAMPLE = [(5, 2), (2327, 4895)]
SAMPLE_OUT = "10\n10647\n"
assert oracle(input_text(SAMPLE)) == SAMPLE_OUT
assert gain_method(input_text(SAMPLE)) == SAMPLE_OUT
assert oracle("1\n1 10000\n") == "1\n"
assert oracle("1\n10000 1\n") == "49995100\n"
assert oracle("1\n2 3\n") == "2\n"
assert oracle(input_text([(7, 4)])) == gain_method(input_text([(7, 4)]))

check_rng = random.Random(29)
for trial in range(100):
    cases = [(check_rng.randint(1, 40), check_rng.randint(1, 40))
             for _ in range(3)]
    text = input_text(cases)
    assert oracle(text) == gain_method(text), (trial, text)


def build():
    edges = [(1, 1), (2, 1), (2, 10000), (3, 2), (10000, 10000)]
    write("2_edges", edges[:4])
    wide = [(10000, 100), (9999, 200), (10000, 50), (5000, 1000)]
    write("3_wide", wide)
    rng = random.Random(20261126)
    random_cases = [(rng.randint(1, 1500), rng.randint(1, 1500))
                    for _ in range(200)]
    write("4_random", random_cases)
    io_cases = [(rng.randint(1, 30), rng.randint(1, 30))
                for _ in range(50000)]
    write("5_io", io_cases)


def write(name, cases):
    text = input_text(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
