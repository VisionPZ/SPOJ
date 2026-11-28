#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    count = int(text.split()[0])
    powers = []
    power = 3
    while power <= count:
        powers.append(power)
        power *= 3
    lines = []
    for value in range(1, count + 1):
        times = sum(1 for item in powers if value % item == 0)
        if times == 0:
            lines.append(str(value))
        else:
            lines.append("-".join(["fizz"] * times))
    return "\n".join(lines) + "\n"


SAMPLE = """9
"""
SAMPLE_OUT = """1
2
fizz
4
5
fizz
7
8
fizz-fizz
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n") == "1\n"
assert oracle("3\n") == "1\n2\nfizz\n"
assert oracle("27\n").splitlines()[26] == "fizz-fizz-fizz"
assert oracle("27\n").splitlines()[8] == "fizz-fizz"


def write(name, count):
    text = "%d\n" % count
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1)
    write("3_wide", 10000)
    rng = random.Random(20261126)
    write("4_random", rng.randint(1, 10000))
    write("5_io", 10000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 9)
build()
