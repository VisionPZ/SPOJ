#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD_ONE = 10**9 + 7
MOD_TWO = 10**9 + 9
BASE = 911382323


def rolling_counts(pattern_length, text):
    size = len(text)
    prefix_one = [0] * (size + 1)
    prefix_two = [0] * (size + 1)
    power_one = [1] * (size + 1)
    power_two = [1] * (size + 1)
    for index, char in enumerate(text):
        value = ord(char) - 96
        prefix_one[index + 1] = (prefix_one[index] * BASE + value) % MOD_ONE
        prefix_two[index + 1] = (prefix_two[index] * BASE + value) % MOD_TWO
        power_one[index + 1] = power_one[index] * BASE % MOD_ONE
        power_two[index + 1] = power_two[index] * BASE % MOD_TWO

    def forward(left, right):
        length = right - left
        first = (prefix_one[right] - prefix_one[left] * power_one[length]) % MOD_ONE
        second = (prefix_two[right] - prefix_two[left] * power_two[length]) % MOD_TWO
        return first, second

    reversed_text = text[::-1]
    rev_one = [0] * (size + 1)
    rev_two = [0] * (size + 1)
    for index, char in enumerate(reversed_text):
        value = ord(char) - 96
        rev_one[index + 1] = (rev_one[index] * BASE + value) % MOD_ONE
        rev_two[index + 1] = (rev_two[index] * BASE + value) % MOD_TWO

    def backward(left, right):
        start = size - right
        length = right - left
        first = (rev_one[start + length] - rev_one[start] * power_one[length]) % MOD_ONE
        second = (rev_two[start + length] - rev_two[start] * power_two[length]) % MOD_TWO
        return first, second

    found = 0
    for left in range(0, size - pattern_length + 1):
        if forward(left, left + pattern_length) == backward(left, left + pattern_length):
            found += 1
    return found


def oracle(text):
    tokens = text.split()
    pattern_length = int(tokens[0])
    word = tokens[1]
    return str(rolling_counts(pattern_length, word)) + "\n"


SAMPLE = "5\nababab\n"
SAMPLE_OUT = "2\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\nabc\n") == "3\n"
assert oracle("2\naa\n") == "1\n"
assert oracle("3\nabcba\n") == "1\n"
assert oracle("4\nabba\n") == "1\n"
assert oracle("5\naaaaa\n") == "1\n"


def write(name, pattern_length, word):
    text = f"{pattern_length}\n{word}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, "abcdef" * 5)
    write("3_wide", 29999, "ab" * 15000)
    rng = random.Random(20261126)
    word = "".join(rng.choice("abcde") for _ in range(400))
    write("4_random", rng.randint(2, 60), word)
    write("5_io", 1, "z" * 30000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 5, "ababab")
build()
