#!/usr/bin/env python3
import random
from math import comb
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = (
    "5\n"
    "5 3 100\n"
    "5 3 2\n"
    "5 3 7\n"
    "1 1 20\n"
    "100 50 1000000009\n"
)
SAMPLE_OUT = "10\n0\n3\n1\n933591892\n"


def oracle(text):
    tokens = text.split()
    count = int(tokens[0])
    cursor = 1
    answers = []
    for _ in range(count):
        total = int(tokens[cursor])
        chosen = int(tokens[cursor + 1])
        modulus = int(tokens[cursor + 2])
        cursor += 3
        answers.append(str(comb(total, chosen) % modulus)
                       if chosen <= total else "0")
    return "\n".join(answers) + "\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert comb(5, 3) % 100 == 10
assert comb(100, 50) % 1000000009 == 933591892
assert oracle("1\n10 11 7\n") == "0\n"
assert oracle("1\n7 0 5\n") == "1\n"


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(
        f"{total} {chosen} {modulus}\n" for total, chosen, modulus in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


write("1_sample", [(5, 3, 100), (5, 3, 2), (5, 3, 7),
                   (1, 1, 20), (100, 50, 1000000009)])
write("2_edges", [(1, 0, 1), (1, 1, 1), (5, 5, 7), (5, 6, 7),
                  (20, 10, 10**12), (100, 50, 2), (100, 50, 3)])
write("3_wide", [(100000, 50000, 1000000000000),
                 (100000, 99999, 9999999967),
                 (99999, 49999, 1000000009),
                 (100000, 0, 1000000000000)])
random.seed(2026)
write("4_random", [(random.randint(1, 1000), random.randint(0, 1000),
                    random.randint(1, 10**12)) for _ in range(60)])
write("5_io", [(random.choice([100000, 50000, 12345, 999]),
                random.randint(0, 60000),
                random.choice([1, 2, 100, 1000000009, 10**12]))
               for _ in range(100)])

print("trace: C(5,3)=10; 10 mod 100 -> " + SAMPLE_OUT.split("\n")[0])
