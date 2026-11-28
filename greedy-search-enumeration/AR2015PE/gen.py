#!/usr/bin/env python3
import itertools
import random
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for case_index in range(1, case_count + 1):
        soldier_count = int(tokens[cursor]); cursor += 1
        death_limit = int(tokens[cursor]); cursor += 1
        heights = [int(value) for value in tokens[cursor:cursor + soldier_count]]
        cursor += soldier_count
        survivors = 0
        for arrangement in set(itertools.permutations(heights)):
            lowest = 10 ** 9
            deaths = 0
            for height in arrangement:
                if height > lowest:
                    deaths += 1
                else:
                    lowest = height
            if deaths == death_limit:
                survivors += 1
        answers.append(f"Case {case_index}: {survivors}")
    return "\n".join(answers) + "\n"


SAMPLE = "3\n3 1\n1 2 3\n3 1\n1 2 2\n3 2\n1 2 3\n"
SAMPLE_OUT = "Case 1: 3\nCase 2: 1\nCase 3: 2\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 0\n5\n") == "Case 1: 1\n"
assert oracle("1\n2 0\n2 1\n") == "Case 1: 1\n"
assert oracle("1\n3 2\n1 2 3\n") == "Case 1: 2\n"
assert sum(1 for keys in itertools.permutations([1, 2, 3])) == 6


def case_text(heights, death_limit):
    return f"{len(heights)} {death_limit}\n" + " ".join(str(value) for value in heights) + "\n"


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(case_text(*case) for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [([1], 0), ([1], 1), ([2, 1], 0), ([1, 2], 1),
                      ([2, 2, 2], 0), ([2, 2, 2], 2), ([3, 1, 2], 3)])
    write("3_wide", [([1, 2, 3, 4, 5, 6, 7, 8], limit) for limit in range(8)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(60):
        heights = [rng.randint(1, 5) for _ in range(rng.randint(1, 8))]
        random_cases.append((heights, rng.randint(0, len(heights))))
    write("4_random", random_cases)
    io_cases = []
    for case_index in range(15000):
        heights = [rng.randint(1, 4) for _ in range(4)]
        io_cases.append((heights, case_index % 5))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [([1, 2, 3], 1), ([1, 2, 2], 1), ([1, 2, 3], 2)])
build()
