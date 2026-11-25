#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    length = int(tokens[0])
    lower = int(tokens[1])
    upper = int(tokens[2])
    values = [int(value) for value in tokens[3:3 + length]]

    def at_most(limit):
        if limit < 1:
            return 0
        frequency = {}
        distinct = 0
        left = 0
        total = 0
        for right, value in enumerate(values):
            frequency[value] = frequency.get(value, 0) + 1
            if frequency[value] == 1:
                distinct += 1
            while distinct > limit:
                old = values[left]
                frequency[old] -= 1
                if frequency[old] == 0:
                    del frequency[old]
                    distinct -= 1
                left += 1
            total += right - left + 1
        return total

    return str(at_most(upper) - at_most(lower - 1)) + "\n"


def brute(text):
    tokens = text.split()
    length = int(tokens[0])
    lower = int(tokens[1])
    upper = int(tokens[2])
    values = [int(value) for value in tokens[3:3 + length]]
    answer = 0
    for left in range(length):
        for right in range(left, length):
            if lower <= len(set(values[left:right + 1])) <= upper:
                answer += 1
    return str(answer) + "\n"


SAMPLE = """4 1 2
231
19
7
19
"""
SAMPLE_OUT = """8
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute(SAMPLE) == SAMPLE_OUT
assert oracle("1 1 1\n4294967295\n") == "1\n"
assert oracle("3 2 2\n1 1 1\n") == "0\n"
assert oracle("3 1 3\n1 2 3\n") == "6\n"
assert oracle("4 2 2\n1 1 1 1\n") == "0\n"


def write(name, length, lower, upper, values):
    text = f"{length} {lower} {upper}\n" + "\n".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, 1, 1, [4294967295])
    write("3_wide", 220, 1, 220, list(range(1, 221)))
    rng = random.Random(20261126)
    lower = rng.randint(1, 8)
    upper = rng.randint(lower, 30)
    values = []
    for _ in range(220):
        if rng.random() < 0.5:
            values.append(rng.randint(1, 40))
        else:
            values.append(rng.randint(1, 2 ** 32 - 1))
    write("4_random", 220, lower, upper, values)
    write("5_io", 220, 1, 220, [rng.randint(1, 2 ** 32 - 1) for _ in range(220)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 4, 1, 2, [231, 19, 7, 19])
build()
