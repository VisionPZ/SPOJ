#!/usr/bin/env python3
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    answers = []
    for limit in tokens[1:1 + count]:
        marked = [False] * (limit + 1)
        current = limit
        while current >= 2:
            for divisor in range(2, current):
                if current % divisor == 0:
                    marked[divisor] = True
            following = -1
            for candidate in range(current - 1, 1, -1):
                if not marked[candidate]:
                    following = candidate
                    break
            if following < 0:
                break
            current = following
        answers.append(str(sum(1 for value in range(2, limit + 1) if not marked[value])))
    return "".join(answer + "\n" for answer in answers)


SAMPLE = """3
2
3
5
"""
SAMPLE_OUT = """1
2
3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n4\n") == "2\n"
assert oracle("1\n6\n") == "3\n"
assert oracle("4\n2\n3\n4\n5\n") == "1\n2\n2\n3\n"


def write(name, limits):
    text = str(len(limits)) + "\n" + "".join(str(limit) + "\n" for limit in limits)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [2, 3, 4, 5, 6, 7, 8])
    rng = random.Random(20261126)
    write("3_wide", [rng.randint(2, 200) for _ in range(500)])
    write("4_random", [rng.randint(2, 200) for _ in range(1000)])
    write("5_io", [rng.randint(2, 200) for _ in range(20000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [2, 3, 5])
build()
