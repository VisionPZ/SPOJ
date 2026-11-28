#!/usr/bin/env python3
import random
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_total = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_total):
        coder_total = int(tokens[cursor])
        problem_total = int(tokens[cursor + 1])
        cursor += 2
        matrix = []
        for _ in range(coder_total):
            matrix.append([int(tokens[cursor + index]) for index in range(problem_total)])
            cursor += problem_total
        chances = [Fraction(int(tokens[cursor + index]), 100)
                   for index in range(problem_total)]
        cursor += problem_total

        def outcomes(row):
            submitted = [(index, row[index]) for index in range(problem_total)
                         if row[index] >= 0]
            result = []
            for mask in range(1 << len(submitted)):
                chance = Fraction(1)
                score = 0
                penalty = 0
                for bit, (problem_index, problem_penalty) in enumerate(submitted):
                    if mask >> bit & 1:
                        chance *= chances[problem_index]
                        score += 1
                        penalty += problem_penalty
                    else:
                        chance *= 1 - chances[problem_index]
                result.append((score, penalty, chance))
            return result

        dexter_outcomes = outcomes(matrix[0])
        expected = Fraction(1)
        for coder_index in range(1, coder_total):
            rival_outcomes = outcomes(matrix[coder_index])
            for dex_score, dex_penalty, dex_chance in dexter_outcomes:
                for rival_score, rival_penalty, rival_chance in rival_outcomes:
                    if rival_score > dex_score or (rival_score == dex_score
                                                   and rival_penalty < dex_penalty):
                        expected += dex_chance * rival_chance
        answers.append(f"{float(expected):.4f}")
    return "\n".join(answers) + "\n"


SAMPLE = """3
2 1
100
150
50
2 2
-1 -1
10 -1
0 100
3 2
100 200
-1 199
99 -1
50 50
"""
SAMPLE_OUT = """1.2500
1.0000
1.6250
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 1\n10\n10\n100\n") == "1.0000\n"
assert oracle("1\n2 1\n10\n10\n0\n") == "1.0000\n"
assert oracle("1\n2 2\n100 200\n-1 50\n50 50\n") == "1.3750\n"


def render(cases):
    parts = [str(len(cases))]
    for matrix, chances in cases:
        parts.append(f"{len(matrix)} {len(chances)}")
        for row in matrix:
            parts.append(" ".join(str(value) for value in row))
        parts.append(" ".join(str(value) for value in chances))
    return "\n".join(parts) + "\n"


def write(name, cases):
    text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def make_case(rng, coder_total, problem_total):
    matrix = []
    for _ in range(coder_total):
        row = []
        for _ in range(problem_total):
            row.append(-1 if rng.random() < 0.3 else rng.randint(1, 100))
        matrix.append(row)
    chances = [rng.choice([0, 50, 100]) for _ in range(problem_total)]
    return matrix, chances


def build():
    write("2_edges", [([[10], [20]], [0]), ([[10], [20]], [100]),
                      ([[-1, -1], [5, 9]], [0, 100]),
                      ([[1, 2], [3, 4]], [50, 50])])
    rng = random.Random(20261130)
    write("3_wide", [make_case(rng, 8, 4) for _ in range(3)])
    write("4_random", [make_case(rng, rng.randint(2, 12), rng.randint(1, 4))
                       for _ in range(10)])
    write("5_io", [make_case(rng, 20, 4) for _ in range(16)])
    big = random.Random(9283749)
    huge = []
    for _ in range(16):
        matrix = []
        for _ in range(256):
            matrix.append([-1 if big.random() < 0.2 else big.randint(1, 1000000)
                           for _ in range(12)])
        chances = [big.choice([0, 25, 50, 75, 100]) for _ in range(12)]
        huge.append((matrix, chances))
    Path("/tmp/DEXTER_big.txt").write_text(render(huge))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [([[100], [150]], [50]),
                   ([[-1, -1], [10, -1]], [0, 100]),
                   ([[100, 200], [-1, 199], [99, -1]], [50, 50])])
build()
