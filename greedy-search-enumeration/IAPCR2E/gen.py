#!/usr/bin/env python3
import random
from functools import lru_cache
from itertools import product
from pathlib import Path

ROOT = Path(__file__).resolve().parent

COLORS = 4
GROUP_SIZE = 4


def feasible(counts, groups):
    total = sum(counts)
    if GROUP_SIZE * groups > total:
        return False
    return max(counts) <= total - groups


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    answers = []
    for case_index in range(case_count):
        counts = tuple(tokens[cursor:cursor + COLORS])
        cursor += COLORS
        if sum(counts) <= 48:
            best = brute_groups(counts)
        else:
            low, high = 0, sum(counts) // GROUP_SIZE
            while low < high:
                middle = (low + high + 1) // 2
                if feasible(counts, middle):
                    low = middle
                else:
                    high = middle - 1
            best = low
        answers.append(f"Case {case_index + 1}: {best}\n")
    return "".join(answers)


COMPOSITIONS = [
    tuple(composition) for composition in product(range(COLORS + 1), repeat=COLORS)
    if sum(composition) == GROUP_SIZE and max(composition) < GROUP_SIZE
]


@lru_cache(maxsize=None)
def brute_groups(counts):
    best = 0
    for composition in COMPOSITIONS:
        if all(used <= have for used, have in zip(composition, counts)):
            rest = tuple(have - used for have, used in zip(counts, composition))
            best = max(best, 1 + brute_groups(rest))
    return best


def input_text(cases):
    parts = [str(len(cases))]
    parts.extend(" ".join(str(value) for value in counts) for counts in cases)
    return "\n".join(parts) + "\n"


SAMPLE = [(2, 2, 1, 3), (1, 1, 4, 1)]
SAMPLE_OUT = "Case 1: 2\nCase 2: 1\n"
assert oracle(input_text(SAMPLE)) == SAMPLE_OUT
assert brute_groups((2, 2, 1, 3)) == 2
assert brute_groups((1, 1, 4, 1)) == 1
assert oracle("1\n0 0 0 0\n") == "Case 1: 0\n"
assert oracle("1\n1000000000 0 0 0\n") == "Case 1: 0\n"
assert oracle("1\n1000000000 1000000000 1000000000 1000000000\n") == "Case 1: 1000000000\n"

check_rng = random.Random(17)
for trial in range(200):
    counts = tuple(check_rng.randint(0, 12) for _ in range(COLORS))
    assert oracle(input_text([counts])) == f"Case 1: {brute_groups(counts)}\n", counts


def build():
    edges = [(0, 0, 0, 0), (1, 0, 0, 0), (4, 0, 0, 0), (1, 1, 1, 1),
             (9, 1, 1, 1), (0, 0, 0, 7)]
    write("2_edges", edges)
    wide = [(10**9, 10**9, 10**9, 10**9), (10**9, 0, 0, 0),
            (10**9, 10**9, 0, 0), (999999999, 1, 1, 1)]
    write("3_wide", wide)
    rng = random.Random(20261126)
    random_cases = [tuple(rng.randint(0, 10**9) for _ in range(COLORS))
                    for _ in range(500)]
    write("4_random", random_cases)
    io_cases = [tuple(rng.randint(0, 10**9) for _ in range(COLORS))
                for _ in range(20000)]
    write("5_io", io_cases)


def write(name, cases):
    text = input_text(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
