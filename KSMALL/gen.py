#!/usr/bin/env python3
import random
from array import array
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SEQUENCE_LENGTH = 5000000
MASK32 = 0xFFFFFFFF


def oracle(text):
    values = [int(token) for token in text.split()]
    first, second, modulus, rank = values[:4]
    state_first = first
    state_second = second
    generated = array('I')
    for _ in range(SEQUENCE_LENGTH):
        state_first = (31014 * (state_first & 65535) + (state_first >> 16)) & MASK32
        state_second = (17508 * (state_second & 65535) + (state_second >> 16)) & MASK32
        generated.append((((state_first << 16) + state_second) & MASK32) % modulus)
    return str(sorted(generated)[rank - 1]) + "\n"


SAMPLE = """2 3 100000007 23
"""
SAMPLE_OUT = """434
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("0 0 2 1\n") == "0\n"
assert oracle("65535 65535 4294967291 2500000\n") == "2149249703\n"
assert oracle("5 7 100 1\n") == "0\n"


def write(name, first, second, modulus, rank):
    text = f"{first} {second} {modulus} {rank}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 0, 0, 2, 1)
    write("3_wide", 65535, 65535, 4294967291, 2500000)
    rng = random.Random(20261126)
    write("4_random", rng.randint(0, 65535), rng.randint(0, 65535),
          rng.randint(2, MASK32), rng.randint(1, SEQUENCE_LENGTH))
    write("5_io", rng.randint(0, 65535), rng.randint(0, 65535), MASK32, SEQUENCE_LENGTH)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
