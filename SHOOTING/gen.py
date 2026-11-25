#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(values, groups):
    ordered = tuple(sorted(values))

    @lru_cache(None)
    def search(remaining, group_count):
        if group_count == 0:
            return 0 if len(remaining) == 0 else None
        if len(remaining) < group_count:
            return None
        if len(remaining) == group_count:
            return sum(remaining)
        first_value = remaining[0]
        rest = remaining[1:]
        best = None
        for mask in range(1 << len(rest)):
            product = first_value
            for index, value in enumerate(rest):
                if mask >> index & 1:
                    product *= value
            leftover = tuple(value for index, value in enumerate(rest)
                             if not (mask >> index & 1))
            sub_score = search(leftover, group_count - 1)
            if sub_score is None:
                continue
            candidate = product + sub_score
            if best is None or candidate > best:
                best = candidate
        return best

    return search(ordered, groups)


def parse(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    cases = []
    for _ in range(case_count):
        bullet_count = int(tokens[cursor])
        target_groups = int(tokens[cursor + 1])
        cursor += 2
        values = [int(token) for token in tokens[cursor:cursor + bullet_count]]
        cursor += bullet_count
        cases.append((values, target_groups))
    return cases


SAMPLE_IN = """3
10 2
0 -1 -2 0 1 2 3 2 10 1
10 3
0 -1 -2 0 1 2 3 2 10 1
5 3
10 0 0 -1 -1
"""
SAMPLE_OUT = """240
241
11
"""
assert [oracle(values, groups) for values, groups in parse(SAMPLE_IN)] == [240, 241, 11]
assert oracle([1, 2, 3], 1) == 6
assert oracle([-2, -3, 4], 2) == 10
assert oracle([0, 0, 0], 2) == 0
assert oracle([-1, -1, -1], 2) == 0


def write(name, cases):
    lines = [str(len(cases))]
    for values, groups in cases:
        lines.append(f"{len(values)} {groups}")
        lines.append(" ".join(str(value) for value in values))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    answers = [str(oracle(values, groups)) for values, groups in cases]
    (ROOT / "out" / f"{name}.out").write_text("\n".join(answers) + "\n")


def build():
    rng = random.Random(20261126)
    write("2_edges", [
        ([1], 1),
        ([-5], 1),
        ([0, 0], 2),
        ([-1, -1], 1),
        ([-1, -1], 2),
        ([2, 3], 1),
        ([2, 3], 2),
    ])
    write("3_wide", [
        ([10, 10, 10, 10, 10, 10, 10, 10, 10, 10], 1),
        ([10, 10, 10, 10, 10, 10, 10, 10, 10, 10], 10),
        ([-3] * 12, 6),
        ([0] * 12, 12),
    ])
    random_cases = []
    for _ in range(12):
        size = rng.randint(2, 11)
        values = [rng.choice([0, 0, 1, -1, 2, -2, 3, -3, 5, -5, 10])
                  for _ in range(size)]
        groups = rng.randint(1, size)
        random_cases.append((values, groups))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(30):
        size = rng.randint(1, 12)
        values = [rng.choice([-4, -2, -1, 0, 1, 2, 3, 5]) for _ in range(size)]
        groups = rng.randint(1, size)
        io_cases.append((values, groups))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
