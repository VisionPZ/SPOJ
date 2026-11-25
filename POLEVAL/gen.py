#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = iter(int(value) for value in text.split())
    lines = []
    case_number = 1
    while True:
        degree = next(tokens)
        if degree == -1:
            break
        coefficients = [next(tokens) for _ in range(degree + 1)]
        point_count = next(tokens)
        points = [next(tokens) for _ in range(point_count)]
        lines.append(f"Case {case_number}:")
        for point in points:
            total = 0
            power = 1
            for exponent in range(degree + 1):
                total += coefficients[degree - exponent] * power
                power *= point
            lines.append(str(total))
        case_number += 1
    return "\n".join(lines) + "\n"


SAMPLE = """2
1 -2 -1
5
0 1 -1 2 -2
3
2 1 -2 -1
4
0 -1 2 -2
-1
"""
SAMPLE_OUT = """Case 1:
-1
-2
2
-1
7
Case 2:
-1
0
15
-9
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("0\n-100\n2\n0 1\n-1\n") == "Case 1:\n-100\n-100\n"
assert oracle("1\n2 3\n1\n-1\n-1\n") == "Case 1:\n1\n"
assert oracle("2\n1 -2 -1\n2\n0 1\n-1\n") == "Case 1:\n-1\n-2\n"
assert 2 ** 10 == 1024


def build_case(degree, coefficients, points):
    lines = [str(degree), " ".join(str(value) for value in coefficients),
             str(len(points)), " ".join(str(value) for value in points), "-1"]
    return "\n".join(lines) + "\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", build_case(0, [-100], [-100, -1, 0, 1, 100]))
    write("3_wide", "".join(
        build_case(999, [(-1) ** index * (index % 101 - 50) for index in range(1000)],
                   [-1, 0, 1] * 10) for _ in range(3)))
    rng = random.Random(20261126)
    cases = []
    for _ in range(40):
        degree = rng.randint(0, 15)
        coefficients = [rng.randint(-100, 100) for _ in range(degree + 1)]
        points = [rng.randint(-5, 5) for _ in range(rng.randint(1, 20))]
        cases.append(build_case(degree, coefficients, points))
    write("4_random", "".join(cases))
    io_cases = []
    for case_index in range(150):
        degree = 2 + case_index % 9
        coefficients = [rng.randint(-100, 100) for _ in range(degree + 1)]
        points = [rng.randint(-3, 3) for _ in range(100)]
        io_cases.append(build_case(degree, coefficients, points))
    write("5_io", "".join(io_cases))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
