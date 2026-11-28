#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 10000


def count_ways(length):
    full = [1, 1]
    notch = [0, 0]
    for size in range(2, length + 1):
        next_notch = full[size - 2] + notch[size - 1]
        next_full = full[size - 1] + full[size - 2] + 2 * notch[size - 1]
        full.append(next_full % MODULUS)
        notch.append(next_notch % MODULUS)
    return full[length] % MODULUS


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    lengths = tokens[1:1 + case_count]
    maximum = max(lengths)
    full = [1, 1]
    notch = [0, 0]
    for size in range(2, maximum + 1):
        full.append((full[size - 1] + full[size - 2] + 2 * notch[size - 1]) % MODULUS)
        notch.append((full[size - 2] + notch[size - 1]) % MODULUS)
    return "\n".join(str(full[length]) for length in lengths) + "\n"


SAMPLE_IN = """2
3
13
"""
SAMPLE_OUT = """5
3465
"""
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle("1\n1\n") == "1\n"
assert oracle("1\n2\n") == "2\n"
assert oracle("1\n3\n") == "5\n"
assert oracle("1\n13\n") == "3465\n"
assert count_ways(4) == 11


def write(name, lengths):
    input_text = str(len(lengths)) + "\n" + "".join(f"{value}\n" for value in lengths)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [1, 2, 3, 4, 5])
    write("3_wide", [1000000, 999999, 999998, 500000])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 1000000) for _ in range(50)])
    write("5_io", [rng.randint(900000, 1000000) for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
