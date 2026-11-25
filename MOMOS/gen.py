#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    momo_count, pig_count = tokens[0], tokens[1]
    hungers = tokens[2:2 + pig_count]
    eaten = 0
    for index in range(momo_count):
        for hunger in hungers:
            if index % hunger == 0:
                eaten += 1
                break
    return str(momo_count - eaten) + "\n"


SAMPLE = """20 3
3
6
5
"""
SAMPLE_OUT = "11\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n1\n") == "0\n"
assert oracle("10 2\n2\n5\n") == "4\n"
assert oracle("100 3\n7\n11\n13\n") == "71\n"


def write(name, momo_count, hungers):
    text = f"{momo_count} {len(hungers)}\n"
    text += "\n".join(str(hunger) for hunger in hungers) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, [1])
    write("3_wide", 1000000, [1])
    rng = random.Random(20261126)
    write("4_random", 3000, [rng.randint(1, 3000) for _ in range(12)])
    write("5_io", 2500, [rng.randint(1, 2500) for _ in range(25)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 20, [3, 6, 5])
build()
