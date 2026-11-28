#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def triples_up_to(limit):
    found = []
    for leg_one in range(1, limit + 1):
        for leg_two in range(leg_one, limit + 1):
            square_sum = leg_one * leg_one + leg_two * leg_two
            hypotenuse = math.isqrt(square_sum)
            if hypotenuse * hypotenuse == square_sum and hypotenuse <= limit:
                found.append((leg_one, leg_two, hypotenuse))
    return found


def oracle(queries):
    maximum = max(upper for _, upper in queries)
    triples = triples_up_to(maximum)
    answers = []
    for lower, upper in queries:
        count = sum(1 for leg_one, leg_two, hypotenuse in triples
                    if leg_one >= lower and hypotenuse <= upper)
        answers.append(str(count))
    return "\n".join(answers) + "\n"


SAMPLE_QUERIES = [(1, 5), (4, 10), (10, 100)]
SAMPLE = "3\n1 5\n4 10\n10 100\n"
SAMPLE_OUT = "1\n1\n45\n"
assert oracle(SAMPLE_QUERIES) == SAMPLE_OUT
assert oracle([(1, 10)]) == "2\n"
assert oracle([(1, 100)]) == "52\n"
assert oracle([(5, 20)]) == "5\n"
assert oracle([(20, 200)]) == "105\n"
assert math.isqrt(25) == 5


def write(name, queries):
    lines = [str(len(queries))]
    for lower, upper in queries:
        lines.append(f"{lower} {upper}")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(queries))


def build():
    write("2_edges", [(1, 2), (1, 5), (1, 6), (4, 5), (2, 3), (1, 12)])
    rng = random.Random(20261126)
    wide = []
    for _ in range(20):
        upper = rng.randint(200, 600)
        lower = rng.randint(1, upper // 2)
        wide.append((lower, upper))
    write("3_wide", wide)
    random_queries = []
    for _ in range(25):
        upper = rng.randint(5, 120)
        lower = rng.randint(1, upper)
        random_queries.append((lower, upper))
    write("4_random", random_queries)
    io_queries = []
    for case_index in range(99):
        upper = 2000 + case_index * 10
        lower = 1 + case_index * 5
        io_queries.append((lower, upper))
    write("5_io", io_queries)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_QUERIES)
build()
