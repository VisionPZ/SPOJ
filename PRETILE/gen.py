#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
BASE = 911382323
MOD_ONE = 10 ** 9 + 7
MOD_TWO = 10 ** 9 + 9


def brute(text):
    length = len(text)
    total = 0
    for period in range(1, length + 1):
        matched = period
        while matched < length and text[matched] == text[matched % period]:
            matched += 1
        total += matched
    return total


def oracle(text):
    tokens = text.split()
    test_count = int(tokens[0])
    answers = []
    for case_index in range(test_count):
        word = tokens[case_index + 1]
        length = len(word)
        power_one = [1]
        power_two = [1]
        hash_one = [0]
        hash_two = [0]
        for character in word:
            code = ord(character) - 64
            power_one.append(power_one[-1] * BASE % MOD_ONE)
            power_two.append(power_two[-1] * BASE % MOD_TWO)
            hash_one.append((hash_one[-1] * BASE + code) % MOD_ONE)
            hash_two.append((hash_two[-1] * BASE + code) % MOD_TWO)

        def fragment(hash_values, powers, modulus, start, size):
            return (hash_values[start + size] - hash_values[start] * powers[size]) % modulus

        total = 0
        for period in range(1, length + 1):
            limit = length - period
            low = 0
            high = limit
            while low < high:
                middle = (low + high + 1) // 2
                if (fragment(hash_one, power_one, MOD_ONE, 0, middle) ==
                        fragment(hash_one, power_one, MOD_ONE, period, middle) and
                        fragment(hash_two, power_two, MOD_TWO, 0, middle) ==
                        fragment(hash_two, power_two, MOD_TWO, period, middle)):
                    low = middle
                else:
                    high = middle - 1
            total += period + low
        answers.append(str(total))
    return "\n".join(answers) + "\n"


SAMPLE = """2
ABCAB
ZZZZZZ
"""
SAMPLE_OUT = """17
36
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute("ABCAB") == 17
assert brute("ZZZZZZ") == 36
assert brute("A") == 1
assert oracle("1\nA\n") == "1\n"
for trial in range(60):
    rng = random.Random(trial)
    word = "".join(rng.choice("ABCDE") for _ in range(rng.randint(1, 14)))
    assert oracle("1\n" + word + "\n") == str(brute(word)) + "\n"


def write(name, words):
    text = str(len(words)) + "\n" + "".join(word + "\n" for word in words)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", ["A", "AB", "AA", "ABCABC", "AAAAA"])
    rng = random.Random(20261126)
    large = [
        "A" * 100000,
        "AB" * 50000,
        "ABC" * 33333 + "A",
        "".join(rng.choice("ABCDEFGHIJKLMNOPQRSTUVWXYZ") for _ in range(100000)),
        "ABCD" * 25000,
    ]
    write("3_wide", large)
    write("4_random", ["".join(rng.choice("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
                               for _ in range(rng.randint(1, 2000)))
                       for _ in range(10)])
    write("5_io", ["A" * 100000] * 10)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", ["ABCAB", "ZZZZZZ"])
build()
