#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007


def oracle(text):
    digits = [int(char) for char in text.strip()]
    total = 0
    for left in range(len(digits)):
        value = 0
        for right in range(left, len(digits)):
            value = (value * 10 + digits[right]) % MOD
            total = (total + value) % MOD
    return str(total) + "\n"


SAMPLE = "123\n"
SAMPLE_OUT = "164\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("001\n") == "3\n"
assert oracle("105004400\n") == "127807548\n"
assert oracle("4774\n") == "6245\n"
assert oracle("4369383968\n") == "353343059\n"
assert oracle("447723168365033648256648424988\n") == "42233771\n"
assert pow(10, 3, MOD) == 1000


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "0000\n")
    write("3_wide", "".join(str(index % 10) for index in range(600)) + "\n")
    rng = random.Random(20261126)
    write("4_random", "".join(str(rng.randrange(10)) for _ in range(600)) + "\n")
    write("5_io", "".join(str(rng.randrange(1, 10)) for _ in range(600)) + "\n")
    big = "".join(rng.choices("0123456789", k=2000000))
    Path("/tmp/ADASUM_big.txt").write_text(big + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
