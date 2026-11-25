#!/usr/bin/env python3
import random
import string
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = ""
SAMPLE_OUT = "Alphabet\nA, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z\n"


def oracle(text):
    joined = ", ".join(character for character in string.ascii_uppercase)
    return "Alphabet\n" + joined + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("ignored\n").splitlines()[0] == "Alphabet"
assert len(oracle(SAMPLE).splitlines()[1].split(", ")) == 26
assert oracle(SAMPLE).splitlines()[1].split(", ")[-1] == "Z"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "")
    write("3_wide", "7 8 9\n")
    rng = random.Random(20261126)
    write("4_random", "".join(chr(rng.randint(32, 126)) for _ in range(50)) + "\n")
    write("5_io", "x" * 200000 + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
