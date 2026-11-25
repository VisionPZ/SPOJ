#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    sum_count = tokens[0]
    target = sorted(tokens[1:1 + sum_count])
    number_count = 1
    while number_count * (number_count - 1) // 2 < sum_count:
        number_count += 1
    largest_number = target[-1] - 1 if target else 1
    for candidate in itertools.combinations_with_replacement(range(1, largest_number + 1), number_count):
        produced = sorted(candidate[first] + candidate[second]
                          for first in range(number_count)
                          for second in range(first + 1, number_count))
        if produced == target:
            return " ".join(str(value) for value in candidate) + "\n"
    return "-1\n"


def pairwise_sums(numbers):
    return sorted(numbers[first] + numbers[second]
                  for first in range(len(numbers))
                  for second in range(first + 1, len(numbers)))


SAMPLE = """6
2 2 2 3 3 3
"""
SAMPLE_OUT = """1 1 1 2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2\n") == "1 1\n"
assert oracle("3\n2 2 2\n") == "1 1 1\n"
assert oracle("1\n4\n") == "1 3\n"
assert pairwise_sums([1, 1, 1, 2]) == [2, 2, 2, 3, 3, 3]


def write(name, numbers):
    sums = pairwise_sums(numbers)
    text = str(len(sums)) + "\n" + " ".join(str(value) for value in sums) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 3])
    write("3_wide", [1, 1, 1, 2, 2, 2, 3, 3])
    rng = random.Random(20261126)
    numbers = [rng.randint(1, 6) for _ in range(rng.randint(2, 7))]
    write("4_random", sorted(numbers))
    write("5_io", [1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 4])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
