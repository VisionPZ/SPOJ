#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    answers = []
    for word in tokens[1:1 + case_count]:
        pieces = set()
        for start in range(len(word)):
            for end in range(start + 1, len(word) + 1):
                pieces.add(word[start:end])
        magical = all(piece[::-1] in pieces for piece in pieces)
        answers.append("YES" if magical else "NO")
    return "\n".join(answers) + "\n"


SAMPLE = """2
aba
ab
"""
SAMPLE_OUT = """YES
NO
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\na\n") == "YES\n"
assert oracle("1\naa\n") == "YES\n"
assert oracle("1\nabca\n") == "NO\n"
assert oracle("2\nabcba\nabcda\n") == "YES\nNO\n"


def write(name, words):
    text = str(len(words)) + "\n" + "\n".join(words) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", ["a", "ab", "zz", "abcba", "abca", "zyx"])
    rng = random.Random(20261126)
    alphabet = "abcdefghijklmnopqrstuvwxyz"
    wide = ["".join(rng.choice(alphabet) for _ in range(10)) for _ in range(100)]
    write("3_wide", wide)
    random_words = ["".join(rng.choice(alphabet) for _ in range(rng.randint(1, 10)))
                    for _ in range(60)]
    write("4_random", random_words)
    io_words = ["ab" * 5 if index % 2 == 0 else "abcba" + "zy"
                for index in range(100)]
    write("5_io", io_words)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
