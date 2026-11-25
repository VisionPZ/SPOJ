#!/usr/bin/env python3
import random
import string
from pathlib import Path

ROOT = Path(__file__).resolve().parent
ALPHABET = string.ascii_uppercase


def encrypt(key, plain):
    column_count = len(key)
    grid = []
    pos = 0
    digraph = True
    while pos < len(plain):
        row = []
        for _ in range(column_count):
            size = 2 if digraph else 1
            row.append(plain[pos:pos + size])
            pos += size
            digraph = not digraph
        grid.append(row)
    result = []
    for digit in sorted(key):
        column_index = key.index(digit)
        for row in grid:
            result.append(row[column_index])
    return "".join(result)


def oracle(text):
    lines = [line for line in text.splitlines() if line.strip()]
    answers = []
    for line in lines:
        key, plain = line.split()
        answers.append(encrypt(key, plain))
    return "\n".join(answers) + "\n"


SAMPLE = "41325 INCOMPLETECOLUMNARWITHALTERNATINGSINGLELETTERSANDDIGRAPHS\n"
SAMPLE_OUT = "CECRTEGLENPHPLUTNANTEIOMOWIRSITDDSINTNALINESAALEMHATGLRGR\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert encrypt("12", "ABCDEFGHIJKLMN") == "ABDEGHJKMNCFIL"
assert encrypt("1", "ABC") == "ABC"
assert encrypt("21", "ABCDE") == "CABDE"


def random_key(rng, size):
    digits = list(range(1, size + 1))
    rng.shuffle(digits)
    return "".join(str(digit) for digit in digits)


def write(name, pairs):
    text = "".join(key + " " + plain + "\n" for key, plain in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", [
        ("1", "A"), ("1", "ABC"), ("12", "ABCDEF"), ("21", "ABCDEFGH"),
        ("123", "ABCDEFGHIJKLM"), ("321", "ABCDEFGHIJKLMNOP"),
        ("987654321", "ABCDEFGHIJKLMNOPQRSTUVWXYZ"),
    ])
    write("3_wide", [(random_key(rng, 9), "".join(rng.choice(ALPHABET) for _ in range(250)))])
    pairs = []
    for _ in range(60):
        size = rng.randint(1, 9)
        length = rng.randint(1, 250)
        pairs.append((random_key(rng, size), "".join(rng.choice(ALPHABET) for _ in range(length))))
    write("4_random", pairs)
    pairs = []
    for _ in range(1000):
        pairs.append((random_key(rng, 9), "".join(rng.choice(ALPHABET) for _ in range(250))))
    write("5_io", pairs)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
