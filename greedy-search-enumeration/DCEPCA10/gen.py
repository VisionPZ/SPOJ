#!/usr/bin/env python3
import random
from collections import Counter
from itertools import combinations, product
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def median(values):
    ordered = sorted(values)
    length = len(ordered)
    if length % 2:
        return ordered[length // 2]
    return (ordered[length // 2 - 1] + ordered[length // 2]) / 2


def median_deviation_median(values):
    center = median(values)
    return median([abs(value - center) for value in values])


def brute_answer(values):
    if median_deviation_median(values) == 0:
        return 0
    for changes in range(1, len(values) + 1):
        for positions in combinations(range(len(values)), changes):
            for replacements in product(range(5), repeat=changes):
                candidate = list(values)
                for position, replacement in zip(positions, replacements):
                    candidate[position] = replacement
                if median_deviation_median(candidate) == 0:
                    return changes
    return -1


def oracle(text):
    tokens = [int(token) for token in text.split()]
    case_count = tokens[0]
    position = 1
    answers = []
    for _ in range(case_count):
        count = tokens[position]
        position += 1
        values = tokens[position:position + count]
        position += count
        required = count // 2 + 1
        frequency = Counter(values)
        answers.append(str(max(0, required - max(frequency.values()))))
    return "\n".join(answers) + "\n"


SAMPLE = """2
5
4 5 3 1 2
10
5 5 5 254 5 5 768 5 5 5
"""
SAMPLE_OUT = """2
0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n7\n") == "0\n"
assert oracle("1\n2\n7 8\n") == "1\n"
assert oracle("1\n5\n3 3 3 3 9\n") == "0\n"
assert oracle("1\n6\n1 2 3 4 5 6\n") == "3\n"
check_rng = random.Random(101)
for _ in range(80):
    size = check_rng.randint(1, 6)
    values = [check_rng.randint(0, 4) for _ in range(size)]
    text = f"1\n{size}\n" + " ".join(str(value) for value in values) + "\n"
    assert brute_answer(values) == int(oracle(text)), (values, brute_answer(values), oracle(text))


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def make_case(values):
    return f"{len(values)}\n" + " ".join(str(value) for value in values) + "\n"


def build():
    edges = "4\n" + "".join([
        make_case([7]),
        make_case([1, 2]),
        make_case([5, 5, 5, 5, 5, 5]),
        make_case([0, 0, 0, 1000000000]),
    ])
    write("2_edges", edges)
    rng = random.Random(20261126)
    wide = "2\n" + f"100000\n" + " ".join(["1000000000"] * 100000) + "\n" + "99999\n" + " ".join(
        str(rng.randint(0, 1000000000)) for _ in range(99999)) + "\n"
    write("3_wide", wide)
    random_cases = "6\n" + "".join(
        make_case([rng.randint(0, 1000000000) for _ in range(rng.randint(1, 200))])
        for _ in range(6))
    write("4_random", random_cases)
    io_cases = "10\n" + "".join(
        make_case([(index * 7) % 11 for index in range(1000)]) for _ in range(10))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
