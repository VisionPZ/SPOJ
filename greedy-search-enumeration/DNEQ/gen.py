#!/usr/bin/env python3
import random
from decimal import Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        men_count = int(tokens[cursor]); cursor += 1
        increase = Decimal(tokens[cursor]); cursor += 1
        old_weight = int(tokens[cursor]); cursor += 1
        total = Decimal(old_weight)
        for _ in range(men_count):
            total += increase
        answers.append(str(int(total)))
    return "\n".join(answers) + "\n"


SAMPLE = "2\n8 1.5 65\n6 3 80\n"
SAMPLE_OUT = "77\n98\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 1.5 5\n") == "8\n"
assert oracle("1\n10 1 3\n") == "13\n"
assert oracle("3\n1 1 1\n1 2 2\n1 3 3\n") == "2\n4\n6\n"
assert Decimal("1.5") * 8 == Decimal("12.0")


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(
        f"{count} {gain} {weight}\n" for count, gain, weight in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1, 1), (102, 99, 99), (2, 1.5, 5)])
    write("3_wide", [(102, 99, 99)] * 10)
    rng = random.Random(20261126)
    gains = [1, 2, 3, 1.5, 2.5]
    write("4_random", [(rng.randint(1, 102), rng.choice(gains), rng.randint(1, 99))
                       for _ in range(10)])
    write("5_io", [(102, 99, 99)] * 10)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(8, 1.5, 65), (6, 3, 80)])
build()
