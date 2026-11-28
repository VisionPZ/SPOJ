#!/usr/bin/env python3
import random
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def terms_for(numerator, denominator):
    value = Fraction(numerator, denominator)
    terms = []
    while value.denominator != 1:
        quotient = value.numerator // value.denominator
        terms.append(quotient)
        value = Fraction(value.denominator,
                         value.numerator - quotient * value.denominator)
    terms.append(value.numerator - 1)
    return terms


def draw(numerator, denominator):
    terms = terms_for(numerator, denominator)
    width = 3 * len(terms) + 1 + sum(len(str(term)) for term in terms)
    lines = ["." * width for _ in range(2 * len(terms) + 1)]
    column = 0
    for index, term in enumerate(terms):
        line_index = 2 * index + 1
        digits = str(term)
        for digit in digits:
            lines[line_index] = (lines[line_index][:column] + digit +
                                 lines[line_index][column + 1:])
            column += 1
        lines[line_index] = (lines[line_index][:column] + ".+." +
                             lines[line_index][column + 3:])
        column += 3
        lines[line_index] = (lines[line_index][:column] +
                             "-" * (width - column))
        marker = (column + width - 1) // 2
        lines[line_index - 1] = (lines[line_index - 1][:marker] + "1" +
                                 lines[line_index - 1][marker + 1:])
    lines[-1] = lines[-1][:-1] + "1"
    return "\n".join(lines)


def restore(lines):
    coefficients = []
    for index in range(1, len(lines), 2):
        start = 0
        while lines[index][start] == ".":
            start += 1
        stop = start
        while lines[index][stop].isdigit():
            stop += 1
        coefficients.append(int(lines[index][start:stop]))
    value = Fraction(coefficients[-1] + 1, 1)
    for coefficient in reversed(coefficients[:-1]):
        value = Fraction(coefficient, 1) + Fraction(1, 1) / value
    return value.numerator, value.denominator


def oracle(text):
    lines = text.splitlines()
    index = 0
    answers = []
    case_number = 0
    while index < len(lines):
        kind = lines[index]
        index += 1
        if kind == "C":
            break
        case_number += 1
        header = f"Case {case_number}:"
        if kind == "A":
            numerator, denominator = (int(value) for value in lines[index].split())
            index += 1
            answers.append(header)
            answers.append(draw(numerator, denominator))
        else:
            art = []
            while index < len(lines) and lines[index] not in ("A", "B", "C"):
                art.append(lines[index])
                index += 1
            numerator, denominator = restore(art)
            answers.append(header)
            answers.append(f"{numerator} {denominator}")
    return "\n".join(answers) + "\n"


SAMPLE = """A
75 34
B
..........1......
2.+.-------------
............1....
....4.+.---------
..............1..
........1.+.-----
................1
............5.+.-
................1
C
"""
SAMPLE_OUT = """Case 1:
..........1......
2.+.-------------
............1....
....4.+.---------
..............1..
........1.+.-----
................1
............5.+.-
................1
Case 2:
75 34
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("A\n30 10\nC\n") == "Case 1:\n....1\n2.+.-\n....1\n"
assert oracle("A\n1 2\nC\n") == f"Case 1:\n{draw(1, 2)}\n"

art_for_75 = draw(75, 34)
assert oracle("B\n" + art_for_75 + "\nC\n") == "Case 1:\n75 34\n"
assert restore(art_for_75.splitlines()) == (75, 34)


def write(name, chunks):
    text = "".join(chunks) + "C\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def a_case(numerator, denominator):
    return f"A\n{numerator} {denominator}\n"


def b_case(numerator, denominator):
    return "B\n" + draw(numerator, denominator) + "\n"


def build():
    chunks = [a_case(1, 1), a_case(30, 10), b_case(7, 3), a_case(3, 7)]
    write("2_edges", chunks)
    chunks = [a_case(2147483647, 1000000007), b_case(2147483647, 1000000007),
              a_case(1000000007, 999999937)]
    write("3_wide", chunks)
    rng = random.Random(20261126)
    chunks = []
    for _ in range(12):
        numerator = rng.randint(1, 10**9)
        denominator = rng.randint(1, 10**9)
        if rng.random() < 0.5:
            chunks.append(a_case(numerator, denominator))
        else:
            chunks.append(b_case(numerator, denominator))
    write("4_random", chunks)
    chunks = [a_case(rng.randint(1, 10**9), rng.randint(1, 10**9))
              for _ in range(400)]
    write("5_io", chunks)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
