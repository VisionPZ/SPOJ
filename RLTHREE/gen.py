#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1000000007


def oracle(text):
    strings = [token for token in text.split() if set(token) <= {"0", "1"}]
    points = [tuple(int(bit) for bit in string) for string in strings]
    safe = 0
    for vertex in range(1 << len(strings[0])):
        coordinates = tuple((vertex >> index) & 1 for index in range(len(strings[0])))
        distances = [sum(abs(coordinates[index] - point[index]) for index in range(len(strings[0])))
                     for point in points]
        if distances[0] == distances[1] == distances[2]:
            safe += 1
    return str(safe % MODULUS) + "\n"


SAMPLE = """111
001
100
"""
SAMPLE_OUT = """2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("00\n00\n00\n") == "4\n"
assert oracle("00\n01\n10\n") == "0\n"
assert oracle("00\n00\n11\n") == "2\n"
assert oracle("0\n0\n1\n") == "0\n"
assert math.comb(100000, 50000) % MODULUS == 149033233
assert pow(2, 100000, MODULUS) == 607723520


def write(name, strings, expected):
    input_text = "\n".join(strings) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(expected)


def build():
    write("2_edges", ["00", "00", "11"], oracle("00\n00\n11\n"))
    write("3_wide", ["0" * 100000, "0" * 100000, "1" * 100000],
          str(math.comb(100000, 50000) % MODULUS) + "\n")
    rng = random.Random(20261126)
    length = 13
    strings = ["".join(rng.choice("01") for _ in range(length)) for _ in range(3)]
    write("4_random", strings, oracle("\n".join(strings) + "\n"))
    write("5_io", ["1" * 100000, "1" * 100000, "1" * 100000],
          str(pow(2, 100000, MODULUS)) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", ["111", "001", "100"], SAMPLE_OUT)
build()
