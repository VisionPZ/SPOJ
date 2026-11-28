#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def key_of(letter):
    if letter <= 'o':
        return (ord(letter) - ord('a')) // 3 + 2
    if letter <= 's':
        return 7
    if letter <= 'v':
        return 8
    return 9


def cycle_of(letter):
    return 4 if letter in 'pqrs wxyz'.replace(' ', '') else 3


def presses_of(letter):
    if letter in 'pqrstuvwxyz':
        base = 'pqrs' if letter <= 's' else ('tuv' if letter <= 'v' else 'wxyz')
    else:
        base = 'abcdefghijklmno'[(ord(letter) - ord('a')) // 3 * 3:(ord(letter) - ord('a')) // 3 * 3 + 3]
    return base.index(letter) + 1


@lru_cache(maxsize=None)
def run_strings(press_count, cycle_length):
    if press_count == 0:
        return frozenset([()])
    result = set()
    for first_presses in range(1, press_count + 1):
        character = (first_presses - 1) % cycle_length
        for tail in run_strings(press_count - first_presses, cycle_length):
            result.add((character,) + tail)
    return frozenset(result)


def word_count(word):
    total = 1
    run_presses = 0
    run_cycle = 0
    run_key = -1
    for letter in word:
        key = key_of(letter)
        if run_presses > 0 and key != run_key:
            total *= len(run_strings(run_presses, run_cycle))
            run_presses = 0
        run_key = key
        run_cycle = cycle_of(letter)
        run_presses += presses_of(letter)
    if run_presses > 0:
        total *= len(run_strings(run_presses, run_cycle))
    return total


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    return "\n".join(str(word_count(word)) for word in tokens[1:1 + case_count]) + "\n"


SAMPLE = """2
mod
iopc
"""
SAMPLE_OUT = """8
64
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert len(run_strings(4, 3)) == 8
assert word_count("a") == 1
assert word_count("aaaa") == 8
assert word_count("pppp") == 8
assert word_count("adgj") == 1


def write(name, words):
    text = str(len(words)) + "\n" + "\n".join(words) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def alternating(length, offset):
    choices = "adgjmptw"
    return "".join(choices[(index + offset) % len(choices)] for index in range(length))


def build():
    write("2_edges", ["a", "aaa", "pppp", "zz", "modmod"])
    write("3_wide", [alternating(100000, 0), alternating(100000, 3)])
    rng = random.Random(20261126)
    random_words = []
    for _ in range(10):
        length = rng.randint(1, 12)
        random_words.append("".join(rng.choice("abcdefghijklmnopqrstuvwxyz") for _ in range(length)))
    write("4_random", random_words)
    io_words = [alternating(50000, index % 8) for index in range(10)]
    write("5_io", io_words)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
