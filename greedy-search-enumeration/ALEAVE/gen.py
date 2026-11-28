#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    used_days = set()
    cursor = 1
    for _ in range(count):
        start_day = tokens[cursor]
        end_day = tokens[cursor + 1]
        cursor += 2
        for day in range(start_day, end_day):
            if 1 <= day <= 366:
                used_days.add(day)
    return str(len(used_days)) + "\n"


SAMPLE = """3
140 145
120 123
121 122
"""
SAMPLE_OUT = """8
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 10\n") == "9\n"
assert oracle("2\n1 5\n3 7\n") == "6\n"
assert oracle("1\n10 10\n") == "0\n"
assert oracle("3\n365 366\n1 4\n2 5\n") == "5\n"


def write(name, requests):
    text = str(len(requests)) + "\n"
    text += "".join(f"{start_day} {end_day}\n" for start_day, end_day in requests)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(10, 20), (15, 25), (30, 30), (1, 366)])
    write("3_wide", [(index, index + 1) for index in range(1, 367)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(1, 366), rng.randint(1, 367)) for _ in range(500)])
    write("5_io", [(rng.randint(1, 366), rng.randint(1, 367)) for _ in range(10000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(140, 145), (120, 123), (121, 122)])
build()
