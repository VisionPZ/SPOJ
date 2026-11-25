#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1000000007


def oracle(text):
    lines = text.splitlines()
    case_count = int(lines[0])
    answers = []
    for string_value in lines[1:1 + case_count]:
        subsequences = {""}
        for character in string_value:
            subsequences |= {prefix + character for prefix in subsequences}
        answers.append(str(len(subsequences) % MODULUS))
    return "\n".join(answers) + "\n"


SAMPLE = """3
AAA
ABCDEFG
CODECRAFT
"""
SAMPLE_OUT = """4
128
496
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n\n") == "1\n"
assert oracle("1\nA\n") == "2\n"
assert oracle("1\nAA\n") == "3\n"
assert oracle("1\nABAB\n") == "12\n"


def write(name, strings):
    input_text = str(len(strings)) + "\n" + "".join(value + "\n" for value in strings)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", ["A", "AA", "AB", "ABC", "ABA", "ZZZZZZZZZZZZ", "ABCABC"])
    write("3_wide", ["ABCDEFGHIJKLMN", "AAAAAAAAAAAAAA", "ABABABABABABAB", "ZYXWVUTSRQPONM"])
    rng = random.Random(20261126)
    alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    write("4_random", ["".join(rng.choice(alphabet) for _ in range(12)) for _ in range(40)])
    write("5_io", ["".join(rng.choice("ABC") for _ in range(12)) for _ in range(100)])


def trace():
    string_value = "ABA"
    subsequences = {""}
    print("start", len(subsequences))
    for character in string_value:
        subsequences |= {prefix + character for prefix in subsequences}
        print(character, len(subsequences))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", ["AAA", "ABCDEFG", "CODECRAFT"])
build()
trace()
