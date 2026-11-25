#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def parse_cases(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    cases = []
    while True:
        member_count = tokens[cursor]
        score_limit = tokens[cursor + 1]
        cursor += 2
        if member_count == 0 and score_limit == 0:
            break
        members = []
        for _ in range(member_count):
            members.append((tokens[cursor], tokens[cursor + 1], tokens[cursor + 2]))
            cursor += 3
        cases.append((score_limit, members))
    return cases


def oracle(text):
    answers = []
    for score_limit, members in parse_cases(text):
        count = 0
        for candidate in itertools.product(range(1, score_limit + 1), repeat=3):
            if all(any(candidate[axis] > evil[axis] for axis in range(3)) for evil in members):
                count += 1
        answers.append(str(count))
    return "\n".join(answers) + "\n"


SAMPLE = """3 10
2 8 5
6 3 5
1 3 9
1 3
2 2 2
1 10000
2 2 2
0 0
"""
SAMPLE_OUT = """848
19
999999999992
"""
assert oracle("3 10\n2 8 5\n6 3 5\n1 3 9\n0 0\n") == "848\n"
assert oracle("1 3\n2 2 2\n0 0\n") == "19\n"
assert 10000 ** 3 - 2 ** 3 == 999999999992
assert oracle("1 2\n1 1 1\n0 0\n") == "7\n"
assert oracle("1 4\n4 4 4\n0 0\n") == "0\n"
assert oracle("2 4\n2 2 2\n3 3 3\n0 0\n") == "37\n"


def format_case(score_limit, members):
    text = f"{len(members)} {score_limit}\n"
    text += "".join(f"{first} {second} {third}\n" for first, second, third in members)
    return text


def write(name, cases):
    text = "".join(format_case(score_limit, members) for score_limit, members in cases) + "0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (3, [(2, 2, 2)]),
        (4, [(1, 1, 1)]),
        (4, [(4, 4, 4)]),
        (5, [(2, 2, 2), (2, 2, 2)]),
        (4, [(2, 3, 4), (4, 3, 2)]),
    ])
    rng = random.Random(20261202)
    write("3_wide", [(10, [(rng.randint(1, 10), rng.randint(1, 10), rng.randint(1, 10))
                           for _ in range(12)])])
    write("4_random", [(score,
                        [(rng.randint(1, score), rng.randint(1, score), rng.randint(1, score))
                         for _ in range(rng.randint(1, 4))])
                       for score in [5, 6, 7, 8, 5, 6]])
    io_cases = []
    for _ in range(160):
        score = rng.randint(2, 8)
        io_cases.append((score, [(rng.randint(1, score), rng.randint(1, score), rng.randint(1, score))
                                 for _ in range(rng.randint(1, 3))]))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
