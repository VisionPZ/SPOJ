#!/usr/bin/env python3
import functools
import random
import string
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    answers = []
    while cursor < len(tokens):
        first_length = int(tokens[cursor]); cursor += 1
        second_length = int(tokens[cursor]); cursor += 1
        prices = [int(value) for value in tokens[cursor:cursor + 26]]; cursor += 26
        first_string = tokens[cursor]; cursor += 1
        second_string = tokens[cursor]; cursor += 1

        @functools.lru_cache(maxsize=None)
        def best(first_pos, second_pos):
            if first_pos == first_length or second_pos == second_length:
                return 0
            skip_first = best(first_pos + 1, second_pos)
            skip_second = best(first_pos, second_pos + 1)
            best_value = max(skip_first, skip_second)
            if first_string[first_pos] == second_string[second_pos]:
                letter_id = ord(first_string[first_pos]) - ord('a')
                best_value = max(best_value, prices[letter_id] + best(first_pos + 1, second_pos + 1))
            return best_value

        answers.append(str(best(0, 0)))
        best.cache_clear()
    return "\n".join(answers) + "\n"


SAMPLE_ONE = """4 4
1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
abcd
dbca
"""
SAMPLE_TWO = """3 3
1 7 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
baa
aab
"""
assert oracle(SAMPLE_ONE) == "2\n"
assert oracle(SAMPLE_TWO) == "7\n"
assert oracle("4 5\n1 4 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 6\nzbbz\nbbzbb\n") == "14\n"
assert oracle("3 3\n1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1\nabc\ndef\n") == "0\n"
assert oracle("1 1\n5 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1\na\na\n") == "5\n"


def write(name, cases):
    lines = []
    for first_string, second_string, prices in cases:
        lines.append(f"{len(first_string)} {len(second_string)}")
        lines.append(" ".join(map(str, prices)))
        lines.append(first_string)
        lines.append(second_string)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def uniform_prices():
    return [1] * 26


def build():
    write("2_edges", [
        ("a", "a", [7] + [1] * 25),
        ("a", "b", uniform_prices()),
        ("abc", "abc", uniform_prices()),
        ("aaa", "aa", uniform_prices()),
    ])
    rng = random.Random(20261126)
    wide_prices = [rng.randint(1, 100000) for _ in range(26)]
    first = "".join(rng.choice(string.ascii_lowercase) for _ in range(300))
    second = "".join(rng.choice(string.ascii_lowercase) for _ in range(300))
    write("3_wide", [(first, second, wide_prices)])
    mixed = []
    for _ in range(6):
        left = "".join(rng.choice("abcde") for _ in range(160))
        right = "".join(rng.choice("abcde") for _ in range(160))
        mixed.append((left, right, [rng.randint(1, 1000) for _ in range(26)]))
    write("4_random", mixed)
    io_cases = []
    for index in range(20000):
        left = "".join(rng.choice("xyz") for _ in range(20))
        right = "".join(rng.choice("xyz") for _ in range(20))
        io_cases.append((left, right, uniform_prices()))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [("abcd", "dbca", uniform_prices())])
build()
