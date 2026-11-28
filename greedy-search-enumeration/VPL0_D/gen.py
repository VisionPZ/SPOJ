#!/usr/bin/env python3
import random
import sys
from functools import lru_cache
from pathlib import Path

sys.setrecursionlimit(10000)

ROOT = Path(__file__).resolve().parent


def brute_force(left, right):
    best = (0, 0)
    for left_mask in range(1 << len(left)):
        left_pick = [left[index] for index in range(len(left)) if left_mask >> index & 1]
        for right_mask in range(1 << len(right)):
            right_pick = [right[index] for index in range(len(right)) if right_mask >> index & 1]
            if left_pick == right_pick:
                candidate = (sum(left_pick), len(left_pick))
                if candidate > best:
                    best = candidate
    return best


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_total = tokens[0]
    lines = []
    cursor = 1
    for case_number in range(1, case_total + 1):
        priority_count = tokens[cursor]
        grape_count = tokens[cursor + 1]
        cursor += 2
        priorities = tokens[cursor:cursor + priority_count]
        cursor += priority_count
        grapes = tokens[cursor:cursor + grape_count]
        cursor += grape_count

        @lru_cache(maxsize=None)
        def solve(priority_index, grape_index):
            if priority_index == priority_count or grape_index == grape_count:
                return (0, 0)
            best = solve(priority_index + 1, grape_index)
            other = solve(priority_index, grape_index + 1)
            if other > best:
                best = other
            if priorities[priority_index] == grapes[grape_index]:
                paired_sum, paired_length = solve(priority_index + 1, grape_index + 1)
                candidate = (paired_sum + priorities[priority_index], paired_length + 1)
                if candidate > best:
                    best = candidate
            return best

        power, amount = solve(0, 0)
        lines.append(f"Scenario #{case_number}: {power} {amount}")
    return "\n".join(lines) + "\n"


SAMPLE = """3
3 3
1 2 3
3 2 1
3 3
2 4 5
3 2 5
5 7
3 3 3 4 5
4 5 3 8 3 12 3
"""
SAMPLE_OUT = """Scenario #1: 3 1
Scenario #2: 7 2
Scenario #3: 9 3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute_force([1, 2, 3], [3, 2, 1]) == (3, 1)
assert brute_force([2, 4, 5], [3, 2, 5]) == (7, 2)
assert brute_force([3, 3, 3, 4, 5], [4, 5, 3, 8, 3, 12, 3]) == (9, 3)
assert brute_force([1, 2, 3], [4, 5, 6]) == (0, 0)


def write(name, cases):
    text = str(len(cases)) + "\n"
    for priorities, grapes in cases:
        text += f"{len(priorities)} {len(grapes)}\n"
        text += " ".join(str(value) for value in priorities) + "\n"
        text += " ".join(str(value) for value in grapes) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [([1], [2]), ([1, 2], [2, 1]), ([5, 5, 5], [5]), ([1, 2, 3], [4, 5, 6])])
    write("3_wide", [(list(range(1, 101)), list(range(100, 0, -1)))])
    rng = random.Random(20261126)
    cases = []
    for _ in range(20):
        size = rng.randint(3, 60)
        priorities = [rng.randint(1, 10000) for _ in range(size)]
        grapes = [rng.randint(1, 10000) for _ in range(size)]
        cases.append((priorities, grapes))
    write("4_random", cases)
    cases = [(list(range(1, 301)), list(range(300, 0, -1))) for _ in range(20)]
    write("5_io", cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [([1, 2, 3], [3, 2, 1]), ([2, 4, 5], [3, 2, 5]),
                   ([3, 3, 3, 4, 5], [4, 5, 3, 8, 3, 12, 3])])
build()

rng = random.Random(19471208)
big_cases = []
for _ in range(20):
    size = 1000
    big_cases.append(([rng.randint(1, 10000) for _ in range(size)],
                      [rng.randint(1, 10000) for _ in range(size)]))
big_text = str(len(big_cases)) + "\n"
for priorities, grapes in big_cases:
    big_text += f"{len(priorities)} {len(grapes)}\n"
    big_text += " ".join(str(value) for value in priorities) + "\n"
    big_text += " ".join(str(value) for value in grapes) + "\n"
Path("/tmp/VPL0_D_big.txt").write_text(big_text)
