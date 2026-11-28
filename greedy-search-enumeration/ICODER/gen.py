#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 65536


def affine(text):
    tokens = text.split()
    cursor = 0
    answers = []
    while cursor < len(tokens):
        instruction_count = int(tokens[cursor])
        cursor += 1
        if instruction_count == 0:
            break
        multiplier = 1
        offset = 0
        for _ in range(instruction_count):
            operation = tokens[cursor]
            operand = int(tokens[cursor + 1])
            cursor += 2
            if operation == "MUL":
                multiplier = multiplier * operand % MODULUS
                offset = offset * operand % MODULUS
            else:
                offset = (offset + operand) % MODULUS
        answers.append(str(MODULUS // math.gcd(multiplier, MODULUS)))
    return "".join(answer + "\n" for answer in answers)


def brute(text):
    tokens = text.split()
    cursor = 0
    answers = []
    while cursor < len(tokens):
        instruction_count = int(tokens[cursor])
        cursor += 1
        if instruction_count == 0:
            break
        reachable = set(range(MODULUS))
        for _ in range(instruction_count):
            operation = tokens[cursor]
            operand = int(tokens[cursor + 1])
            cursor += 2
            if operation == "MUL":
                reachable = {value * operand % MODULUS for value in reachable}
            else:
                reachable = {(value + operand) % MODULUS for value in reachable}
        answers.append(str(len(reachable)))
    return "".join(answer + "\n" for answer in answers)


def oracle(text):
    return affine(text)


SAMPLE = """1
ADD 3
1
MUL 0
5
MUL 3
ADD 4
MUL 5
ADD 3
MUL 2
8
ADD 32
MUL 5312
ADD 7
MUL 7
ADD 32
MUL 5312
ADD 7
MUL 7
0
"""
SAMPLE_OUT = """65536
1
32768
16
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\nADD 0\n0\n") == "65536\n"
assert oracle("1\nMUL 1\n0\n") == "65536\n"
assert oracle("2\nMUL 32768\nADD 5\n0\n") == "2\n"
assert oracle("2\nMUL 2\nMUL 2\n0\n") == "16384\n"
assert math.gcd(0, 65536) == 65536

rng = random.Random(20261126)
for _ in range(12):
    small = []
    for _ in range(rng.randint(1, 6)):
        if rng.random() < 0.5:
            small.append("ADD " + str(rng.randint(0, 65535)))
        else:
            small.append("MUL " + str(rng.randint(0, 65535)))
    text = str(len(small)) + "\n" + "\n".join(small) + "\n0\n"
    assert oracle(text) == brute(text)


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def case(instructions):
    return str(len(instructions)) + "\n" + "\n".join(instructions) + "\n"


def build():
    edges = "".join([
        case(["ADD 0"]),
        case(["MUL 1"]),
        case(["MUL 0"]),
        case(["MUL 2"]),
        case(["MUL 2", "MUL 2", "MUL 2"]),
        case(["MUL 3", "ADD 5", "MUL 0", "ADD 9"]),
        "0\n",
    ])
    write("2_edges", edges)
    wide = "".join([
        case(["MUL 65535"]),
        case(["MUL 5312", "MUL 5312"]),
        case(["MUL 32768", "ADD 65535", "MUL 65535"]),
        case(["ADD 65535", "MUL 65534"]),
        "0\n",
    ])
    write("3_wide", wide)
    random_cases = []
    for _ in range(80):
        count = rng.randint(1, 500)
        instructions = []
        for _ in range(count):
            if rng.random() < 0.45:
                instructions.append("ADD " + str(rng.randint(0, 65535)))
            else:
                instructions.append("MUL " + str(rng.randint(0, 65535)))
        random_cases.append(case(instructions))
    random_cases.append("0\n")
    write("4_random", "".join(random_cases))
    io_cases = []
    for _ in range(40000):
        io_cases.append(case(["MUL " + str(rng.randint(1, 65535))]))
    io_cases.append("0\n")
    write("5_io", "".join(io_cases))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
