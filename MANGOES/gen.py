#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_case(box_count):
    limit = box_count - 2
    all_sum = limit * (limit + 1) // 2
    even_pairs = limit // 2
    even_sum = even_pairs * (even_pairs + 1)
    return (all_sum - even_sum) % box_count


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = [str(oracle_case(tokens[index + 1])) for index in range(case_count)]
    return "\n".join(answers) + "\n"


def brute_case(box_count):
    total = 0
    for index in range(1, box_count - 1):
        if math.gcd(index, index + 2) == 1:
            total += index
    return total % box_count


for size in range(3, 80):
    assert oracle_case(size) == brute_case(size)

SAMPLE = "2\n9\n5\n"
SAMPLE_OUT = "7\n4\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_case(3) == 1
assert oracle_case(4) == 1
assert oracle_case(999) == brute_case(999)


def write(name, sizes):
    text = str(len(sizes)) + "\n" + "".join(str(size) + "\n" for size in sizes)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [3, 4, 5, 6, 7, 8, 9, 10])
    write("3_wide", [100000000, 99999999, 99999998, 99999997])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(3, 100000000) for _ in range(100)])
    write("5_io", [rng.randint(3, 100000000) for _ in range(10000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
