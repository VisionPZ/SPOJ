#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def phi_by_trial_division(value):
    result = value
    remainder = value
    divisor = 2
    while divisor * divisor <= remainder:
        if remainder % divisor == 0:
            while remainder % divisor == 0:
                remainder //= divisor
            result = result // divisor * (divisor - 1)
        divisor += 1
    if remainder > 1:
        result = result // remainder * (remainder - 1)
    return result


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    queries = tokens[1:1 + case_count]
    largest = max(queries, default=0)
    phi_values = [0] * (largest + 1)
    for number in range(1, largest + 1):
        phi_values[number] = phi_by_trial_division(number)
    prefix = [0] * (largest + 1)
    for number in range(1, largest + 1):
        prefix[number] = prefix[number - 1] + phi_values[number]
    return "".join(str(prefix[query] ** 2) + "\n" for query in queries)


SAMPLE = "2\n3\n10\n"
SAMPLE_OUT = "16\n1024\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert phi_by_trial_division(1) == 1
assert phi_by_trial_division(10) == 4
assert oracle("1\n1\n") == "1\n"
assert oracle("4\n1 2 3 4\n") == "1\n4\n16\n36\n"


def write(name, queries):
    text = str(len(queries)) + "\n" + "".join(str(value) + "\n" for value in queries)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 5, 9999, 10000])
    write("3_wide", [10000] * 20)
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 10000) for _ in range(80)])
    write("5_io", [rng.randint(1, 10000) for _ in range(500)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [3, 10])
build()
