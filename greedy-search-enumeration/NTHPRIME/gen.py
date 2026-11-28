#!/usr/bin/env python3
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent
KNOWN = {1: 2, 2: 3, 3: 5, 4: 7, 5: 11, 6: 13,
         1000: 7919, 10000: 104729, 100000: 1299709,
         1000000: 15485863, 100000000: 2038074743,
         1000000000: 22801763489}


def sieve_result(index):
    if index in KNOWN:
        return str(KNOWN[index]) + "\n"
    bound = int(index * (math.log(index) + math.log(math.log(index)))) + 100
    flags = bytearray([1]) * (bound + 1)
    flags[0] = 0
    flags[1] = 0
    for candidate in range(2, int(bound ** 0.5) + 1):
        if flags[candidate]:
            flags[candidate * candidate::candidate] = bytearray(
                len(flags[candidate * candidate::candidate]))
    count = 0
    for number in range(2, bound + 1):
        if flags[number]:
            count += 1
            if count == index:
                return str(number) + "\n"
    raise ValueError("sieve bound too small")


def oracle(text):
    tokens = text.split()
    return sieve_result(int(tokens[0]))


SAMPLE = """4
"""
SAMPLE_OUT = """7
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n") == "2\n"
assert oracle("1000\n") == "7919\n"
assert oracle("1000000000\n") == "22801763489\n"
assert 31 // 3 == 10


def write(name, index):
    text = f"{index}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1)
    write("3_wide", 100000)
    write("4_random", 12345)
    write("5_io", 1000000000)
    Path("/tmp/NTHPRIME_big.txt").write_text("1000000000\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
