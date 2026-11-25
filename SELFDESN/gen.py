#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def count_vectors(base):
    found = []

    def visit(position, remaining, weighted, digits):
        if position == base:
            if remaining == 0 and weighted == 0:
                counts = [0] * base
                valid = True
                for digit in digits:
                    if digit >= base:
                        valid = False
                        break
                    counts[digit] += 1
                if valid and counts == digits:
                    found.append(tuple(digits))
            return
        if weighted < remaining * position:
            return
        upper = min(remaining, base - 1)
        if position > 0:
            upper = min(upper, weighted // position)
        for digit in range(upper + 1):
            left = remaining - digit
            rest = weighted - position * digit
            if rest < left * (position + 1):
                continue
            digits.append(digit)
            visit(position + 1, left, rest, digits)
            digits.pop()

    visit(0, base, base, [])
    return found


def build_table(max_base=30):
    table = []
    for base in range(2, max_base + 1):
        for digits in count_vectors(base):
            value = 0
            for digit in digits:
                value = value * base + digit
            table.append((value, base, digits))
    table.sort(key=lambda row: row[0])
    return table


TABLE = build_table()


def oracle(text):
    tokens = text.split()
    cursor = 0
    cases = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(cases):
        index = int(tokens[cursor]); cursor += 1
        modulus = int(tokens[cursor]); cursor += 1
        answers.append(str(TABLE[index - 1][0] % modulus))
    return "\n".join(answers) + "\n"


SAMPLE = """2
1 1000
2 1000
"""
SAMPLE_OUT = """100
136
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert [row[0] for row in TABLE[:3]] == [100, 136, 1425]
assert oracle("1\n4 1000000\n") == "389305\n"
assert oracle("1\n7 1000\n") == "0\n"
assert oracle("1\n6 1000000000\n") == "225331713\n"


def write(name, pairs):
    text = str(len(pairs)) + "\n" + "".join(f"{index} {modulus}\n" for index, modulus in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (1, 1), (1, 2), (2, 7), (3, 1000), (4, 1), (6, 1000000000),
    ])
    write("3_wide", [(index, 1000000000) for index in range(1, len(TABLE) + 1)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(1, len(TABLE)), rng.randint(2, 1000000000))
                       for _ in range(200)])
    write("5_io", [(rng.randint(1, len(TABLE)), rng.randint(2, 1000000000))
                   for _ in range(10000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
print("first bases:", [(row[1], "".join(map(str, row[2]))) for row in TABLE[:6]])
