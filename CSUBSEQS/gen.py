#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def is_subsequence(pattern, text):
    iterator = iter(text)
    return all(character in iterator for character in pattern)


def oracle(text):
    strings = [line.strip() for line in text.splitlines() if line.strip()]
    shortest = min(strings, key=len)
    size = len(shortest)
    found = set()
    for mask in range(1, 1 << size):
        candidate = "".join(shortest[index] for index in range(size)
                            if (mask >> index) & 1)
        if candidate not in found and all(
                is_subsequence(candidate, word) for word in strings):
            found.add(candidate)
    return str(len(found)) + "\n"


SAMPLE = """aabb
abab
baba
acba
"""
SAMPLE_OUT = "4\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("a\na\na\na\n") == "1\n"
assert oracle("ab\nba\nab\nba\n") == "2\n"
assert oracle("aaa\naaa\naaa\naaa\n") == "3\n"
assert oracle("abc\ndef\nabc\ndef\n") == "0\n"
assert is_subsequence("ab", "acb")


def write(name, strings):
    text = "".join(word + "\n" for word in strings)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", ["a", "a", "a", "a"])
    write("3_wide", ["".join(rng.choice("abcde") for _ in range(15))
                     for _ in range(4)])
    write("4_random", ["".join(rng.choice("abcdefghij")
                               for _ in range(rng.randint(4, 12)))
                       for _ in range(4)])
    write("5_io", ["abcdefghijklmno"] * 4)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", ["aabb", "abab", "baba", "acba"])
build()
