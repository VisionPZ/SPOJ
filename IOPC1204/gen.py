#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def totient(value):
    result = value
    remainder = value
    divisor = 2
    while divisor * divisor <= remainder:
        if remainder % divisor == 0:
            while remainder % divisor == 0:
                remainder //= divisor
            result -= result // divisor
        divisor += 1
    if remainder > 1:
        result -= result // remainder
    return result


def brute_answer(threshold):
    candidate = 1
    while True:
        candidate += 1
        if totient(candidate) > threshold:
            return candidate


def is_prime_trial(value):
    if value < 2:
        return False
    if value % 2 == 0:
        return value == 2
    divisor = 3
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        divisor += 2
    return True


def oracle(text):
    tokens = [int(value) for value in text.split()]
    answers = []
    for threshold in tokens[1:]:
        candidate = threshold + 2
        if candidate > 2 and candidate % 2 == 0:
            candidate += 1
        while not is_prime_trial(candidate):
            candidate += 2
        answers.append(str(candidate))
    return "".join(answer + "\n" for answer in answers)


SAMPLE = """2
1
2
"""
SAMPLE_OUT = """3
5
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("4\n0\n1\n2\n3\n") == "2\n3\n5\n5\n"
assert totient(12) == 4
assert brute_answer(0) == 2
assert brute_answer(10) == 13
assert all(brute_answer(value) == int(oracle(f"1\n{value}\n").strip())
           for value in range(0, 300))


def write(name, values):
    text = str(len(values)) + "\n" + "".join(str(value) + "\n" for value in values)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [0, 1, 2, 3, 4, 10, 100, 1000])
    write("3_wide", [10 ** 6 - 1, 10 ** 9, 10 ** 12 - 1, 10 ** 12])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(0, 10 ** 9) for _ in range(30)])
    write("5_io", [rng.randint(0, 10 ** 6) for _ in range(1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
