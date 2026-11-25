#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1000000007


def oracle(text):
    lines = text.split()
    case_total = int(lines[0])
    answers = []
    for case_index in range(case_total):
        secret = lines[case_index + 1]
        length = len(secret)
        non_palindrome = 0
        for mask in range(1 << length):
            kept = "".join(secret[position] for position in range(length)
                           if mask >> position & 1)
            if kept != kept[::-1]:
                non_palindrome += 1
        answers.append(str(non_palindrome % MODULUS))
    return "\n".join(answers) + "\n"


SAMPLE = """2
AA
b99b
"""
SAMPLE_OUT = """0
6
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\na\n") == "0\n"
assert oracle("1\nabc\n") == "4\n"
assert oracle("1\nabba\n") == "6\n"


def make_palindrome(rng, half_length, use_center):
    half = "".join(rng.sample("abcXYZ019qw7", half_length))
    center = rng.choice("pU5") if use_center else ""
    return half + center + half[::-1]


def render(strings):
    return str(len(strings)) + "\n" + "\n".join(strings) + "\n"


def write(name, strings):
    text = render(strings)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", ["a", "AA", "aba", "abba", "abcba", "abccba"])
    rng = random.Random(20261129)
    write("3_wide", [make_palindrome(rng, 5, True)
                     for _ in range(8)])
    write("4_random", [make_palindrome(rng, rng.randint(1, 5), rng.choice([True, False]))
                       for _ in range(20)])
    write("5_io", [make_palindrome(rng, rng.randint(1, 4), rng.choice([True, False]))
                   for _ in range(1000)])
    big = random.Random(9283748)
    alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    huge = ["".join(big.sample(alphabet, 50)) for _ in range(10)]
    huge = [half + half[::-1] for half in huge]
    Path("/tmp/NAIVELOK_big.txt").write_text(render(huge * 100))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", ["AA", "b99b"])
build()
