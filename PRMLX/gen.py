#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def rank_of(word):
    variants = sorted(set("".join(chars) for chars in itertools.permutations(word)))
    return variants.index(word) + 1


def oracle(text):
    answers = []
    for line in text.splitlines():
        if line == "#":
            break
        answers.append(f"{rank_of(line):10d}")
    return "".join(answer + "\n" for answer in answers)


SAMPLE = """bacaa
abc
cba

bacaa
abc
cba
#
"""
SAMPLE_OUT = """        15
         1
         6
         1
        15
         1
         6
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert rank_of("acab") == 5
assert rank_of("cba") == 6
assert rank_of("") == 1
assert rank_of("aaaaa") == 1


def write_case(name, words):
    text = "".join(word + "\n" for word in words) + "#\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_case("2_edges", ["a", "", "zzz", "ab", "ba", "cba", ""])
    write_case("3_wide", ["abcdefgh", "hgfedcba", "aaaaaaa", "abababa", "zyxwvuts", "abcabcab"])
    rng = random.Random(20261126)
    words = []
    for _ in range(40):
        length = rng.randint(1, 8)
        words.append("".join(rng.choice("abcdefgh") for _ in range(length)))
    write_case("4_random", words)
    rng = random.Random(773311)
    words = ["".join(rng.choice("abcdefg") for _ in range(7)) for _ in range(400)]
    write_case("5_io", words)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
