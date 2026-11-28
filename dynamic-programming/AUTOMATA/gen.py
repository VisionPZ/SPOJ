#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(pattern, text):
    rows = len(text)
    columns = len(pattern)
    table = [[False] * (columns + 1) for _ in range(rows + 1)]
    table[0][0] = True
    for column in range(1, columns + 1):
        if pattern[column - 1] == '*':
            table[0][column] = table[0][column - 1]
    for row in range(1, rows + 1):
        for column in range(1, columns + 1):
            marker = pattern[column - 1]
            if marker == '*':
                table[row][column] = table[row][column - 1] or table[row - 1][column]
            elif marker == '?':
                table[row][column] = table[row - 1][column - 1]
            elif marker == text[row - 1]:
                table[row][column] = table[row - 1][column - 1]
    return "Yes" if table[rows][columns] else "No"


def oracle_text(cases):
    return "\n".join(oracle(pattern, text) for pattern, text in cases) + "\n"


SAMPLE_CASES = [("a?b", "acb"), ("a?b", "abbb"), ("a*b", "abbbb"),
                ("a*b", "asbdfuisdhfsbdfsdfb"), ("abb", "bb")]
SAMPLE = "\n".join(value for case in SAMPLE_CASES for value in case) + "\n"
SAMPLE_OUT = """Yes
No
Yes
Yes
No
"""
assert oracle_text([("a?b", "acb")]) == "Yes\n"
assert oracle_text([("a?b", "abbb")]) == "No\n"
assert oracle_text([("*", "anything")]) == "Yes\n"
assert oracle_text([("a*b", "abbbb")]) == "Yes\n"
assert oracle_text(SAMPLE_CASES) == SAMPLE_OUT


def write(name, cases):
    lines = [str(len(cases))]
    for pattern, text in cases:
        lines.append(pattern)
        lines.append(text)
    (ROOT / "in" / f"{name}.txt").write_text("\n".join(lines) + "\n")
    (ROOT / "out" / f"{name}.out").write_text(oracle_text(cases))


def random_case(rng, pattern_length, text_length):
    alphabet = "abcdef"
    parts = []
    for _ in range(pattern_length):
        choice = rng.random()
        if choice < 0.2:
            parts.append('*')
        elif choice < 0.35:
            parts.append('?')
        else:
            parts.append(rng.choice(alphabet))
    pattern = "".join(parts)
    text = "".join(rng.choice(alphabet) for _ in range(text_length))
    return pattern, text


def build():
    write("2_edges", [("*", "abcdef"), ("?", "a"), ("a?", "ab"), ("a*b", "ab"),
                      ("abc", "abc"), ("abc", "abcd"), ("*a*b*", "cabxdab")])
    rng = random.Random(20261126)
    write("3_wide", [random_case(rng, 120, 200) for _ in range(8)])
    write("4_random", [random_case(rng, 25, 40) for _ in range(30)])
    write("5_io", [random_case(rng, 60, 80) for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_CASES)
build()
