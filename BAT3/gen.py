#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        peak_count = tokens[cursor]
        robin_index = tokens[cursor + 1]
        cursor += 2
        heights = tokens[cursor:cursor + peak_count]
        cursor += peak_count

        @lru_cache(maxsize=None)
        def walk(position, bat_available):
            longest = 1
            for landing in range(position + 1, peak_count):
                if heights[landing] < heights[position]:
                    longest = max(longest, 1 + walk(landing, bat_available))
                elif position == robin_index and bat_available:
                    longest = max(longest, 1 + walk(landing, False))
            return longest

        answers.append(str(max(walk(start, True) for start in range(peak_count))))
    return "\n".join(answers) + "\n"


SAMPLE = """1
6 4
6 3 5 2 4 5
"""
SAMPLE_OUT = """4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n3 0\n5 3 4\n") == "2\n"
assert oracle("1\n1 0\n9\n") == "1\n"
assert oracle("1\n5 4\n1 2 3 4 5\n") == "1\n"
assert oracle("1\n4 1\n9 7 5 3\n") == "4\n"


def write(name, cases):
    parts = [str(len(cases))]
    for heights, robin_index in cases:
        parts.append(f"{len(heights)} {robin_index}")
        parts.append(" ".join(str(value) for value in heights))
    input_text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [([9], 0), ([5, 3], 1), ([1, 2, 3], 0), ([3, 3, 3], 1)])
    write("3_wide", [([1000 - index for index in range(60)], 59)])
    rng = random.Random(20261128)
    random_cases = []
    for _ in range(20):
        peak_count = rng.randint(2, 26)
        random_cases.append(([rng.randint(1, 40) for _ in range(peak_count)],
                             rng.randrange(peak_count)))
    write("4_random", random_cases)
    write("5_io", [([rng.randint(1, 100) for _ in range(20)], rng.randrange(20))
                   for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
