#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    lines = text.split("\n")
    if lines and lines[-1] == "":
        lines.pop()
    count = int(lines[0])
    answers = []
    for case_index in range(count):
        word = lines[case_index + 1].rstrip("\r")
        length = len(word)
        reachable = [False] * (length + 1)
        reachable[0] = True
        for start in range(length):
            if not reachable[start]:
                continue
            for end in range(start + 2, length + 1, 2):
                left = start
                right = end - 1
                is_palindrome = True
                while left < right:
                    if word[left] != word[right]:
                        is_palindrome = False
                        break
                    left += 1
                    right -= 1
                if is_palindrome:
                    reachable[end] = True
        answers.append("YES " if reachable[length] else "NO")
    return "\n".join(answers) + "\n"


SAMPLE = """3
madam
aA
aabb
"""
SAMPLE_OUT = """NO
NO
YES 
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\naabb\n") == "YES \n"
assert oracle("1\nabab\n") == "NO\n"
assert oracle("1\nabba\n") == "YES \n"
assert oracle("1\n\n") == "YES \n"
assert oracle("1\naaabbb\n") == "NO\n"


def write(name, words):
    text = f"{len(words)}\n" + "\n".join(words) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", ["", "a", "aa", "ab", "abba", "abab", "aabb", "abcabc", "zzzzzz"])
    write("3_wide", ["a" * 200, "ab" * 100, "abba" * 50, "abcd" * 50, "aabb" * 50])
    rng = random.Random(20261126)
    words = []
    for case_index in range(40):
        length = rng.randint(0, 200)
        words.append("".join(rng.choice("abc") for _ in range(length)))
    write("4_random", words)
    io_words = ["aabb" * 50 for _ in range(99)]
    write("5_io", io_words)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
