#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 10 ** 9 + 7
LIMIT = 130


def is_over(first, second):
    if first == 25 and second < 24:
        return True
    if second == 25 and first < 24:
        return True
    return first >= 24 and second >= 24 and abs(first - second) == 2


def build_counts():
    ways = [[0] * (LIMIT + 1) for _ in range(LIMIT + 1)]
    ways[0][0] = 1
    for total in range(0, LIMIT + 1):
        for first in range(total + 1):
            second = total - first
            value = ways[first][second]
            if value == 0:
                continue
            if is_over(first, second):
                continue
            if first + 1 <= LIMIT:
                ways[first + 1][second] += value
            if second + 1 <= LIMIT:
                ways[first][second + 1] += value
    return ways


WAYS = build_counts()


def formula(first, second):
    if first == 25 and second < 24:
        return math.comb(24 + second, second) % MOD
    if second == 25 and first < 24:
        return math.comb(24 + first, first) % MOD
    if first >= 24 and second >= 24 and abs(first - second) == 2:
        loser = min(first, second)
        return math.comb(48, 24) * pow(2, loser - 24, MOD) % MOD
    return 0


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    for index in range(case_count):
        first = tokens[1 + 2 * index]
        second = tokens[2 + 2 * index]
        answers.append(str(WAYS[first][second] % MOD if is_over(first, second) else 0))
    return "\n".join(answers) + "\n"


SAMPLE = """2
3 25
24 17
"""
SAMPLE_OUT = """2925
0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n25 23\n") == "801728689\n"
assert oracle("1\n27 25\n") == "206914735\n"
assert oracle("1\n24 24\n") == "0\n"
for first_score in range(0, 51):
    for second_score in range(0, 51):
        brute = WAYS[first_score][second_score] % MOD if is_over(first_score, second_score) else 0
        assert brute == formula(first_score, second_score)


def write(name, pairs):
    text = str(len(pairs)) + "\n" + "".join(f"{first} {second}\n" for first, second in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(25, 23), (23, 25), (24, 24), (25, 24), (26, 24), (27, 25),
                      (28, 26), (0, 25), (25, 0), (30, 28)])
    write("3_wide", [(25, 23), (26, 24), (27, 25), (28, 26), (29, 27), (30, 28),
                     (60, 58), (59, 57), (24, 23), (23, 24)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(0, 60), rng.randint(0, 60)) for _ in range(15)])
    write("5_io", [(rng.randint(0, 60), rng.randint(0, 60)) for _ in range(15)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(3, 25), (24, 17)])
build()
