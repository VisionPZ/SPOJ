#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def is_prime(value):
    if value < 2:
        return False
    divisor = 2
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        divisor += 1
    return True


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    numbers = tokens[1:1 + case_count]
    limit = max(numbers) if numbers else 0
    flags = [False] * (limit + 1)
    if limit >= 2:
        flags[2] = True
    for odd in range(3, limit + 1, 2):
        flags[odd] = True
    candidate = 3
    while candidate * candidate <= limit:
        if flags[candidate]:
            for multiple in range(candidate * candidate, limit + 1, 2 * candidate):
                flags[multiple] = False
        candidate += 2
    prefix = [0] * (limit + 1)
    for value in range(1, limit + 1):
        prefix[value] = prefix[value - 1] + (1 if flags[value] else 0)
    return "\n".join(str(prefix[number]) for number in numbers) + "\n"


SAMPLE = "2\n9\n11\n"
SAMPLE_OUT = "4\n5\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n") == "0\n"
assert oracle("1\n2\n") == "1\n"
assert oracle("1\n1000000\n") == "78498\n"


def write(name, numbers):
    text = str(len(numbers)) + "\n" + "".join(str(value) + "\n" for value in numbers)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 1000000, 999999])
    write("3_wide", [1000000] * 10000)
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 1000000) for _ in range(10000)])
    write("5_io", [1000000] * 10000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [9, 11])
build()
