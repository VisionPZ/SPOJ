#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DIGITS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"


def value_and_modulus(base, suffix):
    value = 0
    modulus = 1
    for character in suffix:
        digit = int(character) if character.isdigit() else ord(character) - 55
        value = value * base + digit
        modulus *= base
    return value, modulus


def in_base(number, base):
    if number == 0:
        return "0"
    text = ""
    while number > 0:
        number, remainder = divmod(number, base)
        text = DIGITS[remainder] + text
    return text


def oracle(text):
    tokens = text.split()
    constraint_count = int(tokens[0])
    cursor = 1
    constraints = []
    for _ in range(constraint_count):
        base = int(tokens[cursor])
        suffix = tokens[cursor + 1]
        cursor += 2
        residue, modulus = value_and_modulus(base, suffix)
        constraints.append((base, suffix, residue, modulus))
    largest = max(constraints, key=lambda item: item[3])
    candidate = largest[2]
    step = largest[3]
    for _ in range(20000000):
        if all(in_base(candidate, base).endswith(suffix)
               for base, suffix, _, _ in constraints):
            return str(candidate) + "\n"
        candidate += step
    raise RuntimeError("no candidate found")


SAMPLE_ONE = """3
5 22
11 A2
18 4
"""
SAMPLE_TWO = """5
2 110
32 E
25 M3
28 2
7 2
"""
assert oracle(SAMPLE_ONE) == "112\n"
assert oracle(SAMPLE_TWO) == "53678\n"
assert oracle("1\n2 101\n") == "5\n"
assert oracle("1\n10 0\n") == "0\n"
assert oracle("2\n4 3\n6 1\n") == "7\n"
assert 2 ** 10 == 1024


def suffix_of(number, base, length):
    representation = in_base(number, base)
    if len(representation) < length:
        raise ValueError("representation too short for suffix")
    return representation[-length:]


def write(name, target, bases):
    lines = [str(len(bases))]
    for base, length in bases:
        lines.append("%d %s" % (base, suffix_of(target, base, length)))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 5, [(2, 1), (3, 1), (36, 1)])
    write("3_wide", 10 ** 17 - 12345, [(36, 11), (2, 1), (3, 1)])
    rng = random.Random(20261126)
    write("4_random", rng.randint(1, 100000),
          [(base, 2 if base > 3 else 3) for base in range(2, 12)])
    write("5_io", 13 * (10 ** 16) - 97, [(36, 11), (2, 1), (3, 1)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_ONE)
(ROOT / "out" / "1_sample.out").write_text("112\n")
build()
