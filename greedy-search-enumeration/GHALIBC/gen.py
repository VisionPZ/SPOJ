#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def catalan_exact(index):
    return math.comb(2 * index, index) // (index + 1)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    answers = []
    for _ in range(case_count):
        residue = tokens[cursor]
        prime = tokens[cursor + 1]
        exponent = tokens[cursor + 2]
        cursor += 3
        modulus = prime * prime
        limit = prime ** exponent - 1
        total = 0
        for index in range(residue, limit + 1, prime - 1):
            total += catalan_exact(index)
        answers.append(str(total % modulus))
    return "\n".join(answers) + "\n"


SAMPLE = "2\n5 7 2\n5 7 1\n"
SAMPLE_OUT = "42\n42\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n4 5 2\n") == "20\n"
assert oracle("1\n6 7 2\n") == "21\n"
assert oracle("1\n3 5 1\n") == "5\n"
assert catalan_exact(5) == 42


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(
        f"{residue} {prime} {exponent}\n" for residue, prime, exponent in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(3, 5, 1), (4, 5, 2), (3, 5, 3),
                      (4, 7, 1), (5, 7, 2), (6, 7, 3)])
    write("3_wide", [(residue, prime, 2) for prime in (5, 7, 11, 13, 17, 19, 23, 29, 31, 37)
                     for residue in ((prime + 1) // 2, prime - 1)][:10])
    rng = random.Random(20261126)
    primes = [5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47]
    random_cases = []
    for _ in range(10):
        prime = rng.choice(primes)
        residue = rng.randint((prime + 1) // 2, prime - 1)
        exponent = rng.randint(1, 3)
        random_cases.append((residue, prime, exponent))
    write("4_random", random_cases)
    io_cases = [(residue, prime, exponent)
                for prime in (5, 7, 11, 13, 17)
                for residue, exponent in [((prime + 1) // 2, 1), (prime - 1, 2)]][:10]
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(5, 7, 2), (5, 7, 1)])
build()
