#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    lines = []
    for word in text.split():
        distinct = [set() for _ in range(26)]
        for start in range(len(word)):
            letter = ord(word[start]) - 97
            for end in range(start + 1, len(word) + 1):
                distinct[letter].add(word[start:end])
        lines.append(" ".join(str(len(items)) for items in distinct))
    return "\n".join(lines) + "\n"


SAMPLE = """aaa
"""
SAMPLE_OUT = """3 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("abc\n") == "3 2 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0\n"
assert oracle("aabbaa\n") == "10 6 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0\n"
assert oracle("acbabca\n") == "10 7 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0\n"


def write(name, words):
    text = "\n".join(words) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_word(rng, length, alphabet):
    return "".join(rng.choice(alphabet) for _ in range(length))


def build():
    write("2_edges", ["a", "z", "ab", "aa", "abc"])
    rng = random.Random(20261126)
    write("3_wide", [random_word(rng, 200, "abc") for _ in range(12)])
    write("4_random", [random_word(rng, 160, "abcdefghij") for _ in range(25)])
    write("5_io", [random_word(random.Random(700 + index), 6, "abc") for index in range(2000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", ["aaa"])
build()

stress_rng = random.Random(31)
Path("/tmp/ADASTRNG_big.txt").write_text(random_word(stress_rng, 300000, "abcd") + "\n")
