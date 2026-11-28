#!/usr/bin/env python3
"""Test-data generator and statement-derived oracle for TRIPPL.

The rendered statement collapses the sample's whitespace onto one line.
The logical sample holds three test cases with three, four and five teams.
The oracle uses separate parity formulas verified by exhaustive search.
The solution instead derives the answer from the minimising win distribution.
"""
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "3\n3\n4\n5\n"
SAMPLE_OUTPUT = "1\n2\n5\n"


def choose_two(value):
    return value * (value - 1) // 2


def choose_three(value):
    return value * (value - 1) * (value - 2) // 6


def parity_answer(team_count):
    if team_count < 3:
        return 0
    total = choose_three(team_count)
    if team_count % 2 == 1:
        degree = (team_count - 1) // 2
        return total - team_count * choose_two(degree)
    degree = team_count // 2
    return total - (team_count // 2) * (
        choose_two(degree) + choose_two(degree - 1))


def brute_answer(team_count):
    pairs = [(first, second) for first in range(team_count)
             for second in range(first + 1, team_count)]
    best = 0
    for mask in range(1 << len(pairs)):
        wins = [[False] * team_count for _ in range(team_count)]
        for edge_index, (first, second) in enumerate(pairs):
            if (mask >> edge_index) & 1:
                wins[first][second] = True
            else:
                wins[second][first] = True
        cyclic = 0
        for first in range(team_count):
            for second in range(first + 1, team_count):
                for third in range(second + 1, team_count):
                    forward = (wins[first][second] and wins[second][third]
                               and wins[third][first])
                    backward = (wins[second][first] and wins[third][second]
                                and wins[first][third])
                    if forward or backward:
                        cyclic += 1
        if cyclic > best:
            best = cyclic
    return best


def oracle(text):
    values = [int(token) for token in text.split()]
    case_count = values[0]
    return "".join(str(parity_answer(values[index + 1])) + "\n"
                   for index in range(case_count))


def write(name, counts):
    input_text = (str(len(counts)) + "\n" +
                  "".join(str(value) + "\n" for value in counts))
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert SAMPLE_OUTPUT == "1\n2\n5\n"
assert "".join(SAMPLE_INPUT.split()) == "3345"
for small_count in range(1, 6):
    assert brute_answer(small_count) == parity_answer(small_count)
assert parity_answer(3) == 1 and parity_answer(4) == 2
assert parity_answer(5) == 5 and parity_answer(6) == 8


def build():
    write("2_edges", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
    write("3_wide", [1000000, 999999, 1000000, 1, 2, 999998, 3])
    random.seed(2026)
    write("4_random", [random.randint(1, 1000000) for _ in range(3000)])
    write("5_io", [1000000 if index % 2 == 0 else 999999
                   for index in range(100000)])


def trace_example():
    for team_count in [3, 4, 5, 6]:
        if team_count < 3:
            continue
        degree_sum = team_count * (team_count - 1) // 2
        base = degree_sum // team_count
        extra = degree_sum % team_count
        transitive = extra * choose_two(base + 1)
        transitive += (team_count - extra) * choose_two(base)
        print("%d teams degrees %dx%d %dx%d transitive %d balanced %d" % (
            team_count, base + 1, extra, base, team_count - extra,
            transitive, choose_three(team_count) - transitive))


if "--trace" in sys.argv:
    trace_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [3, 4, 5])
    build()
