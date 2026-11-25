#!/usr/bin/env python3
import random
from array import array
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MAX_QUERY = 2000000


def build_prefix(limit):
    sieve_limit = max(1000, limit)
    composite = bytearray(sieve_limit + 1)
    for value in range(2, int(sieve_limit ** 0.5) + 1):
        if not composite[value]:
            for multiple in range(value * value, sieve_limit + 1, value):
                composite[multiple] = 1
    bits = bytearray()
    for value in range(2, sieve_limit + 1):
        if not composite[value]:
            representation = bin(value)[2:].encode()
            bits.extend(representation)
            if len(bits) >= limit + 100:
                break
    prefix = array('I', [0]) * (len(bits) + 1)
    for index, bit in enumerate(bits):
        prefix[index + 1] = prefix[index] + (1 if bit == 49 else 0)
    return prefix


PREFIX = build_prefix(MAX_QUERY)


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    answers = []
    for index in range(1, case_count + 1):
        target = int(tokens[index])
        answers.append(str(PREFIX[target]))
    return "\n".join(answers) + "\n"


SAMPLE = """3
3
10
50
"""
SAMPLE_OUT = """2
8
36
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0\n") == "0\n"
assert oracle("1\n1\n") == "1\n"
assert oracle("1\n2\n") == "1\n"
assert oracle("1\n20\n") == "15\n"


def write(name, values):
    text = str(len(values)) + "\n" + "\n".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [0, 1, 2, 3, 4])
    write("3_wide", [MAX_QUERY, MAX_QUERY - 1, MAX_QUERY // 2, 1500000])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(0, MAX_QUERY) for _ in range(100)])
    write("5_io", [rng.randint(0, MAX_QUERY) for _ in range(50000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
