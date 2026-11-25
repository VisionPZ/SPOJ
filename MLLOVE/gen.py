#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    modulo_base, visit_stride = tokens[0], tokens[1]
    seen = set()
    position = 1 % modulo_base
    for _ in range(modulo_base):
        seen.add(position)
        position = (position + visit_stride) % modulo_base
    return str(sum(seen)) + "\n"


SAMPLE = "6 3\n"
SAMPLE_OUT = "5\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("6 1\n") == "15\n"
assert oracle("6 2\n") == "9\n"
assert oracle("1 1\n") == "0\n"


def write(name, modulo_base, visit_stride):
    text = f"{modulo_base} {visit_stride}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, 1)
    write("3_wide", 200000, 1)
    rng = random.Random(20261126)
    write("4_random", rng.randint(2, 200000), rng.randint(1, 200000))
    write("5_io", 200000, rng.randint(1, 200000))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 6, 3)
build()
