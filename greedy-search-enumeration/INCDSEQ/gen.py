#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 5000000


def brute(values, length):
    return len({tuple(values[index] for index in choice)
                for choice in itertools.combinations(range(len(values)), length)
                if all(values[choice[pos]] < values[choice[pos + 1]]
                       for pos in range(length - 1))}) % MODULUS


def oracle(text):
    tokens = [int(value) for value in text.split()]
    element_count = tokens[0]
    subsequence_length = tokens[1]
    values = tokens[2:2 + element_count]
    distinct_values = sorted(set(values))
    rank_of = {value: index for index, value in enumerate(distinct_values)}
    distinct_count = len(distinct_values)
    endings = [[0] * (subsequence_length + 1) for _ in range(distinct_count)]
    for value in values:
        rank = rank_of[value]
        for length in range(subsequence_length, 1, -1):
            total = 0
            for smaller in range(rank):
                total += endings[smaller][length - 1]
            endings[rank][length] = total % MODULUS
        endings[rank][1] = 1
    answer = sum(row[subsequence_length] for row in endings) % MODULUS
    return str(answer) + "\n"


SAMPLE = """4 3
1
2
2
10
"""
SAMPLE_OUT = "1\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n7\n") == "1\n"
assert oracle("3 2\n2 1 0\n") == "0\n"
assert oracle("4 2\n1 2 3 4\n") == "6\n"
assert oracle("4 2\n1 1 1 2\n") == "1\n"
for trial in range(60):
    rng = random.Random(trial)
    values = [rng.randint(0, 6) for _ in range(rng.randint(1, 10))]
    length = rng.randint(1, min(4, len(values)))
    text = str(len(values)) + " " + str(length) + "\n" + "\n".join(
        str(value) for value in values) + "\n"
    assert oracle(text) == str(brute(values, length)) + "\n"


def write(name, values, length):
    text = f"{len(values)} {length}\n" + "".join(
        f"{value}\n" for value in values)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [0], 1)
    write("3_wide", list(range(100)), 50)
    rng = random.Random(20261126)
    write("4_random", [rng.randint(0, 999999999) for _ in range(200)], 25)
    write("5_io", [rng.randint(0, 999999999) for _ in range(300)], 50)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 2, 2, 10], 3)
build()
