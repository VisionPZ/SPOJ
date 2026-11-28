#!/usr/bin/env python3
import random
import string
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    lines = text.split("\n")
    answers = []
    for line_index, line in enumerate(lines):
        if line_index == len(lines) - 1 and line == "":
            continue
        cleaned = "".join(ch.lower() for ch in line if ch.isalnum())
        if cleaned == cleaned[::-1]:
            answers.append(line + " is a palindrome")
        else:
            answers.append(line + " is not a palindrome")
    return "\n".join(answers) + ("\n" if text.endswith("\n") else "")


def brute(text):
    lines = text.splitlines()
    answers = []
    for line in lines:
        kept = [ch.lower() for ch in line if ch in string.ascii_letters + string.digits]
        mirror = list(reversed(kept))
        suffix = " is a palindrome" if kept == mirror else " is not a palindrome"
        answers.append(line + suffix)
    return "\n".join(answers) + "\n"


SAMPLE = """dad
Hannah
A man, a plan, a canal, Panama!
"""
SAMPLE_OUT = """dad is a palindrome
Hannah is a palindrome
A man, a plan, a canal, Panama! is a palindrome
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute(SAMPLE) == SAMPLE_OUT
assert oracle("racecar\n") == "racecar is a palindrome\n"
assert oracle("hello\n") == "hello is not a palindrome\n"
assert oracle("Was it a car or a cat I saw?\n") == "Was it a car or a cat I saw? is a palindrome\n"
assert oracle("Madam, I'm Adam.\n") == "Madam, I'm Adam. is a palindrome\n"


def write(name, lines):
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", ["", "a", "44", "a!", "??", "ab", "A b a", "0 0"])
    long_palindrome = "abcdefgfedcba"
    long_mirror = "xyz" + "q" * 34
    write("3_wide", [long_palindrome, long_mirror, "A" * 40, "z" * 39 + "a"])
    rng = random.Random(20261126)
    alphabet = string.ascii_letters + string.digits + " ,.!?'"
    random_lines = []
    for _ in range(80):
        length = rng.randint(1, 40)
        random_lines.append("".join(rng.choice(alphabet) for _ in range(length)))
    write("4_random", random_lines)
    io_lines = []
    for index in range(6000):
        if index % 2 == 0:
            io_lines.append("" .join(rng.choice(string.ascii_letters) for _ in range(40)))
        else:
            io_lines.append("Never odd or even " + str(index).zfill(8))
    write("5_io", io_lines)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE.splitlines())
build()
