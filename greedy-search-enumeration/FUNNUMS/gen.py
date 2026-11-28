#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
factorial = [1]
for value in range(1, 16):
    factorial.append(factorial[-1] * value)


def next_permutation(letters):
    pivot = len(letters) - 2
    while pivot >= 0 and letters[pivot] >= letters[pivot + 1]:
        pivot -= 1
    if pivot < 0:
        return None
    swap = len(letters) - 1
    while letters[swap] <= letters[pivot]:
        swap -= 1
    letters[pivot], letters[swap] = letters[swap], letters[pivot]
    letters[pivot + 1:] = reversed(letters[pivot + 1:])
    return letters


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    cursor = 1
    answers = []
    for _ in range(case_count):
        letters = list(tokens[cursor])
        cursor += 1
        shift = int(tokens[cursor])
        cursor += 1
        for _ in range(shift):
            letters = next_permutation(letters)
        answers.append("".join(letters))
    return "\n".join(answers) + "\n"


SAMPLE = """3
abdc 2
adcb 3
badc 7
"""
SAMPLE_OUT = """acdb
bcad
cbad
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\nab 1\n") == "ba\n"
assert oracle("1\nacb 2\n") == "bca\n"
assert oracle("1\nabcde 0\n") == "abcde\n"
for shift in range(6):
    ordered = ["".join(perm) for perm in itertools.permutations("abcd")]
    start = ordered.index("badc")
    assert oracle("1\nbadc " + str(shift) + "\n") == ordered[start + shift] + "\n"


def permutation_rank(letters):
    remaining = list(letters)
    rank = 0
    for pos, letter in enumerate(letters):
        smaller = sum(1 for candidate in remaining if candidate < letter)
        rank += smaller * factorial[len(letters) - 1 - pos]
        remaining.remove(letter)
    return rank


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(
        f"{word} {shift}\n" for word, shift in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [("ab", 1), ("ba", 0), ("abc", 0), ("abcde", 119)])
    alphabet = "abcdefghijklmno"
    write("3_wide", [(alphabet, 2000), ("abcdefghijklmon", 1),
                     ("abcdefghijklmn", 87)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(200):
        size = rng.randint(2, 15)
        letters = "".join(rng.sample(alphabet[:size], size))
        room = factorial[size] - 1 - permutation_rank(letters)
        random_cases.append((letters, rng.randint(0, min(1200, room))))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(1000):
        letters = "".join(rng.sample(alphabet, 15))
        io_cases.append((letters, rng.randint(0, 400)))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
