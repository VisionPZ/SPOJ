#!/usr/bin/env python3
import random
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_case(prisoner_count, magician_count):
    outsider_count = prisoner_count - magician_count
    off = [[Fraction(0)] * (outsider_count + 1) for _ in range(magician_count + 1)]
    on = [[Fraction(0)] * (outsider_count + 1) for _ in range(magician_count + 1)]
    on[0][0] = Fraction(1, magician_count)
    for magicians in range(1, magician_count + 1):
        off[magicians][0] = sum(Fraction(1, step)
                                for step in range(1, magicians + 1))
        on[magicians][0] = off[magicians][0]
    for outsiders in range(1, outsider_count + 1):
        off[0][outsiders] = Fraction(1, outsiders) + on[0][outsiders - 1]
        on[0][outsiders] = Fraction(1, magician_count) + off[0][outsiders]
    for magicians in range(1, magician_count + 1):
        for outsiders in range(1, outsider_count + 1):
            off[magicians][outsiders] = (
                1 + magicians * off[magicians - 1][outsiders] +
                outsiders * on[magicians][outsiders - 1]) / (magicians + outsiders)
            on[magicians][outsiders] = (
                1 + magicians * off[magicians - 1][outsiders] +
                (magician_count - magicians) * off[magicians][outsiders]) / magician_count
    return float(Fraction(prisoner_count) * off[magician_count][outsider_count])


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    cursor = 1
    answers = []
    for _ in range(case_count):
        prisoner_count = int(tokens[cursor])
        magician_count = int(tokens[cursor + 1])
        cursor += 2
        answers.append(f"{oracle_case(prisoner_count, magician_count):.6E}")
    return "".join(answer + "\n" for answer in answers)


SAMPLE = """2
100 10
1 1
"""
SAMPLE_OUT = """1.408258E+03
1.000000E+00
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3\n2 1\n3 1\n3 3\n") == "4.000000E+00\n1.050000E+01\n5.500000E+00\n"
assert oracle_case(100, 10) < oracle_case(100, 9)
assert oracle_case(5, 1) > oracle_case(5, 2)
assert oracle_case(2, 2) == 3.0


def write(name, pairs):
    text = str(len(pairs)) + "\n" + "".join(
        f"{prisoners} {magicians}\n" for prisoners, magicians in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(2, 1), (3, 1), (5, 2), (10, 3), (10, 10)])
    write("3_wide", [(100, 10), (200, 100), (100, 99), (60, 30)])
    rng = random.Random(20261126)
    random_pairs = []
    for _ in range(30):
        prisoners = rng.randint(2, 60)
        random_pairs.append((prisoners, rng.randint(1, min(30, prisoners))))
    write("4_random", random_pairs)
    io_pairs = []
    for _ in range(200):
        prisoners = rng.randint(2, 20)
        io_pairs.append((prisoners, rng.randint(1, min(10, prisoners))))
    write("5_io", io_pairs)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
