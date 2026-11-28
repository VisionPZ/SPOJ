#!/usr/bin/env python3
import math
import random
from itertools import permutations
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    cursor = 1
    answers = []
    for case_number in range(1, case_count + 1):
        word = tokens[cursor]
        cursor += 1
        symbols = sorted(set(word))
        symbol_count = len(symbols)
        smallest_base = max(2, symbol_count)
        best_value = None
        for base in range(smallest_base, smallest_base + 4):
            for digits in permutations(range(base), symbol_count):
                assignment = dict(zip(symbols, digits))
                if assignment[word[0]] == 0:
                    continue
                value = 0
                for letter in word:
                    value = value * base + assignment[letter]
                if best_value is None or value < best_value:
                    best_value = value
        answers.append(f"Case #{case_number}: {best_value}")
    return "\n".join(answers) + "\n"


SAMPLE = """3
11001001
cats
zig
"""
SAMPLE_OUT = """Case #1: 201
Case #2: 75
Case #3: 11
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1111\n") == "Case #1: 15\n"
assert oracle("1\nab\n") == "Case #1: 2\n"
assert oracle("1\nabc\n") == "Case #1: 11\n"
assert oracle("2\nzz\nba\n") == "Case #1: 3\nCase #2: 2\n"


def bounded_length(symbol_count):
    number_base = max(2, symbol_count)
    return max(1, int(math.log10(10**18) / math.log10(number_base)) - 1)


def write(name, words):
    text = str(len(words)) + "\n" + "\n".join(words) + "\n"
    expected = oracle(text)
    for line in expected.splitlines():
        assert int(line.split(": ")[1]) <= 10**18
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(expected)


def build():
    write("2_edges", ["a", "aaaa", "00", "1", "abab", "zzzzz"])
    write("3_wide", ["0123456789abcdefghijklmnopqrstuvwxyz"[:size] * 3
                     for size in range(2, 7)])
    rng = random.Random(20261126)
    alphabet = "0123abcd"
    words = []
    for _ in range(60):
        size = rng.randint(2, 5)
        length = rng.randint(1, bounded_length(size))
        source = alphabet[:size]
        words.append("".join(rng.choice(source) for _ in range(length)))
    write("4_random", words)
    words = []
    for _ in range(100):
        size = rng.randint(2, 4)
        source = alphabet[:size]
        length = bounded_length(size)
        words.append("".join(rng.choice(source) for _ in range(length)))
    write("5_io", words)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", ["11001001", "cats", "zig"])
build()
