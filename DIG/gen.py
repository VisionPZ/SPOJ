#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 10 ** 9 + 7


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    for vertex_count in tokens[1:1 + case_count]:
        answers.append(str(math.comb(vertex_count, 4) % MODULUS))
    return "\n".join(answers) + "\n"


SAMPLE = "2\n4\n5\n"
SAMPLE_OUT = "1\n5\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n3\n") == "0\n"
assert oracle("1\n6\n") == "15\n"
assert oracle("1\n100000000\n") == str(math.comb(100000000, 4) % MODULUS) + "\n"
assert math.comb(8, 4) == 70


def write(name, counts):
    text = str(len(counts)) + "\n" + "".join(str(value) + "\n" for value in counts)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 5, 6])
    write("3_wide", [10 ** 8, 99999999, 12345678, 50000000])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 10 ** 8) for _ in range(200)])
    write("5_io", [rng.randint(4, 10 ** 8) for _ in range(20000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [4, 5])
build()
