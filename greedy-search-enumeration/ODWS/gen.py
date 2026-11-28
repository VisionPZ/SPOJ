#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1000000007
LETTERS = "abcdefghijklmnopqrstuvwxyz"


def count_between(lower_word, upper_word):
    length = len(lower_word)

    @lru_cache(maxsize=None)
    def walk(position, equal_lower, equal_upper):
        if position == length:
            return 1 if not equal_lower and not equal_upper else 0
        total = 0
        lower_digit = LETTERS.index(lower_word[position])
        upper_digit = LETTERS.index(upper_word[position])
        for letter_index in range(26):
            if equal_lower and letter_index < lower_digit:
                continue
            if equal_upper and letter_index > upper_digit:
                continue
            next_lower = equal_lower and letter_index == lower_digit
            next_upper = equal_upper and letter_index == upper_digit
            total += walk(position + 1, next_lower, next_upper)
        return total

    return walk(0, True, True) % MODULUS


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for case_index in range(1, case_count + 1):
        lower_word = tokens[cursor]; cursor += 1
        upper_word = tokens[cursor]; cursor += 1
        answers.append("Case %d: %d" % (case_index, count_between(lower_word, upper_word)))
    return "\n".join(answers) + "\n"


SAMPLE = """3
ad
ag
abcdefg
abcdefh
xy
yz
"""
SAMPLE_OUT = """Case 1: 2
Case 2: 0
Case 3: 26
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\na\nz\n") == "Case 1: 24\n"
assert oracle("1\nabc\nabd\n") == "Case 1: 0\n"
assert oracle("1\n" + "a" * 5 + "\n" + "z" * 5 + "\n") == "Case 1: %d\n" % (
    (26 ** 5 - 2) % MODULUS)
assert 26 ** 2 == 676


def write(name, pairs):
    input_text = str(len(pairs)) + "\n" + "".join(
        "%s\n%s\n" % pair for pair in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [("a", "b"), ("a", "z"), ("a" * 100, "a" * 99 + "b")])
    rng = random.Random(20261126)
    wide_pairs = []
    for _ in range(10):
        lower = "".join(rng.choice(LETTERS) for _ in range(100))
        upper_list = list(lower)
        position = rng.randrange(100)
        upper_list[position] = "z"
        upper = "".join(upper_list)
        if upper <= lower:
            upper = lower[:-1] + "z"
        wide_pairs.append((lower, upper))
    write("3_wide", wide_pairs)
    random_pairs = []
    for _ in range(50):
        length = rng.randint(1, 12)
        lower = "".join(rng.choice(LETTERS[:6]) for _ in range(length))
        upper = "".join(rng.choice(LETTERS) for _ in range(length))
        if upper <= lower:
            upper = lower[:-1] + "z" if length > 1 else "z"
        random_pairs.append((lower, upper))
    write("4_random", random_pairs)
    io_pairs = [("a" + "b" * 99, "a" + "z" * 99) for _ in range(100)]
    write("5_io", io_pairs)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [("ad", "ag"), ("abcdefg", "abcdefh"), ("xy", "yz")])
build()
