#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    pos = 1
    lines = []
    for _ in range(case_count):
        girl_count = tokens[pos]
        pos += 1
        reports = tokens[pos:pos + girl_count]
        pos += girl_count
        ordered = sorted(reports)
        answer = -1
        for double_count in range(girl_count + 1):
            expected = sorted([double_count - 1] * double_count +
                              [double_count] * (girl_count - double_count))
            if expected == ordered:
                answer = double_count
                break
        lines.append(str(answer))
    return "\n".join(lines) + "\n"


SAMPLE = "1\n3\n2 2 2\n"
SAMPLE_OUT = "3\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n3\n0 0 0\n") == "0\n"
assert oracle("1\n3\n0 1 1\n") == "1\n"
assert oracle("1\n2\n1 1\n") == "2\n"
assert oracle("1\n4\n1 1 2 3\n") == "-1\n"


def write(name, cases):
    chunks = [str(len(cases))]
    for girl_count, reports in cases:
        chunks.append(str(girl_count))
        chunks.append(" ".join(str(value) for value in reports))
    text = "\n".join(chunks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def valid_case(girl_count, double_count, rng):
    reports = [double_count - 1] * double_count + [double_count] * (girl_count - double_count)
    rng.shuffle(reports)
    return girl_count, reports


def build():
    write("2_edges", [(2, [0, 0]), (2, [1, 1]), (3, [0, 1, 1])])
    write("3_wide", [(10000, [9999] * 10000)])
    rng = random.Random(20261125)
    cases = []
    for _ in range(12):
        girl_count = rng.randint(2, 200)
        double_count = rng.randint(0, girl_count)
        cases.append(valid_case(girl_count, double_count, rng))
    cases.append((5, [4, 4, 4, 4, 1]))
    write("4_random", cases)
    io_cases = []
    for index in range(100):
        girl_count = 100
        double_count = index % (girl_count + 1)
        io_cases.append(valid_case(girl_count, double_count, rng))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(3, [2, 2, 2])])
build()
