#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    modulus = tokens[1]
    best = [-1] * modulus
    best[0] = 0
    for value in tokens[2:2 + count]:
        remainder = value % modulus
        updated = best[:]
        for residue in range(modulus):
            if best[residue] >= 0:
                target = (residue + remainder) % modulus
                candidate = best[residue] + value
                if candidate > updated[target]:
                    updated[target] = candidate
        best = updated
    return " ".join(str(value if value > 0 else -1) for value in best) + "\n"


SAMPLE = """6 5
2 8 10 44 15 32
"""
SAMPLE_OUT = "65 111 77 103 109\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 5\n2\n") == "-1 -1 2 -1 -1\n"
assert oracle("2 2\n1 1\n") == "2 1\n"
assert oracle("1 1\n7\n") == "7\n"
assert oracle("3 4\n5 5 5\n") == "-1 5 10 15\n"


def write(name, modulus, values):
    text = f"{len(values)} {modulus}\n" + " ".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 5, [2])
    rng = random.Random(20261126)
    write("3_wide", 200, [rng.randint(1, 1000000000) for _ in range(100000)])
    write("4_random", 7, [rng.randint(1, 1000000000) for _ in range(30)])
    write("5_io", 200, [1000000000] * 50000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 5, [2, 8, 10, 44, 15, 32])
build()
