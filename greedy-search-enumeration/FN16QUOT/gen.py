#!/usr/bin/env python3
import functools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while cursor < len(tokens):
        run_count = tokens[cursor]
        cursor += 1
        runs = tokens[cursor:cursor + run_count]
        cursor += run_count
        answers.append(solve_runs(runs))
    return "\n".join(answers) + "\n"


def solve_runs(runs):
    quote_count = sum(runs)
    run_of = []
    for run_index, width in enumerate(runs):
        run_of.extend([run_index] * width)

    def same_run(start, end):
        return end <= start or run_of[start] == run_of[end - 1]

    @functools.lru_cache(None)
    def single(level, start, end):
        if level == 1:
            return end == start + 2
        if end - start < 2 * level:
            return False
        if not same_run(start, start + level):
            return False
        if not same_run(end - level, end):
            return False
        return sequence(level - 1, start + level, end - level)

    @functools.lru_cache(None)
    def sequence(level, start, end):
        if level == 1:
            return end > start and (end - start) % 2 == 0
        if end <= start:
            return False
        for split in range(start + 1, end + 1):
            if single(level, start, split) and (split == end or sequence(level, split, end)):
                return True
        return False

    for level in range(min(quote_count, 30), 1, -1):
        if sequence(level, 0, quote_count):
            return str(level)
    if quote_count == 2:
        return "1"
    return "no quotation"


def format_cases(cases):
    parts = []
    for runs in cases:
        parts.append(str(len(runs)))
        parts.append(" ".join(str(value) for value in runs))
    return "\n".join(parts) + "\n"


SAMPLE = """5
2 1 1 1 3
1
22
1
1
"""
SAMPLE_OUT = """2
4
no quotation
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert solve_runs([2, 1, 1, 1, 3]) == "2"
assert solve_runs([22]) == "4"
assert solve_runs([1]) == "no quotation"
assert solve_runs([2]) == "1"
assert solve_runs([1, 1]) == "1"
assert solve_runs([3, 1, 8]) == "2"


def write(name, cases):
    text = format_cases(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[1, 1], [2], [4], [3, 1], [1, 9], [100]])
    write("3_wide", [[10] * 10, [22], [9] * 11 + [1]])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(40):
        run_count = rng.randint(1, 8)
        random_cases.append([rng.randint(1, 8) for _ in range(run_count)])
    write("4_random", random_cases)
    io_cases = []
    for _ in range(2000):
        run_count = rng.randint(1, 5)
        io_cases.append([rng.randint(1, 5) for _ in range(run_count)])
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
