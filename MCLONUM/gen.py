#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    answers = []
    for index in range(0, len(tokens), 2):
        if index + 1 >= len(tokens):
            break
        first = tokens[index]
        second = tokens[index + 1]
        candidates = sorted(set("".join(parts) for parts in itertools.permutations(second)))
        valid = [number for number in candidates if number[0] != "0"]
        higher = [number for number in valid if number >= first]
        lower = [number for number in valid if number < first]
        answers.append(higher[0] if higher else "0")
        answers.append(lower[-1] if lower else "0")
    return "\n".join(answers) + "\n"


SAMPLE = """3075
6604
3000203
4562454
"""
SAMPLE_OUT = """4066
0
4244556
2655444
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1232\n3022\n") == "2023\n0\n"
assert oracle("1\n1\n") == "1\n0\n"
assert oracle("2\n1\n") == "0\n1\n"
assert oracle("21\n12\n") == "21\n12\n"
assert oracle("10\n10\n") == "10\n0\n"
assert oracle("999\n999\n") == "999\n0\n"


def write(name, pairs):
    text = "".join(first + "\n" + second + "\n" for first, second in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [("1", "1"), ("2", "1"), ("21", "12"), ("10", "10"),
                      ("3022", "1232"), ("1232", "3022")])
    wide_pairs = [("3075", "6604"), ("3000203", "4562454"),
                  ("987654", "123456"), ("111111", "123456")]
    write("3_wide", wide_pairs)
    rng = random.Random(20261126)
    random_pairs = []
    for _ in range(120):
        digits_a = [rng.randint(1, 9)] + [rng.randint(0, 9) for _ in range(6)]
        digits_b = [rng.randint(1, 9)] + [rng.randint(0, 9) for _ in range(6)]
        random_pairs.append(("".join(map(str, digits_a)), "".join(map(str, digits_b))))
    write("4_random", random_pairs)
    io_pairs = []
    for _ in range(15000):
        digits_a = [rng.randint(1, 9)] + [rng.randint(0, 9) for _ in range(3)]
        digits_b = [rng.randint(1, 9)] + [rng.randint(0, 9) for _ in range(3)]
        io_pairs.append(("".join(map(str, digits_a)), "".join(map(str, digits_b))))
    write("5_io", io_pairs)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [("3075", "6604"), ("3000203", "4562454")])
build()
