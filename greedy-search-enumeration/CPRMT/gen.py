#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def sorted_lcs(first, second):
    left = sorted(first)
    right = sorted(second)
    rows = [[0] * (len(right) + 1) for _ in range(len(left) + 1)]
    for row in range(1, len(left) + 1):
        for column in range(1, len(right) + 1):
            if left[row - 1] == right[column - 1]:
                rows[row][column] = rows[row - 1][column - 1] + 1
            else:
                rows[row][column] = max(rows[row - 1][column], rows[row][column - 1])
    row = len(left)
    column = len(right)
    chosen = []
    while row > 0 and column > 0:
        if left[row - 1] == right[column - 1]:
            chosen.append(left[row - 1])
            row -= 1
            column -= 1
        elif rows[row - 1][column] >= rows[row][column - 1]:
            row -= 1
        else:
            column -= 1
    return "".join(reversed(chosen))


def oracle(text):
    lines = [line.strip() for line in text.splitlines()]
    words = [line for line in lines if line]
    answers = []
    for pair_index in range(0, len(words) - 1, 2):
        answers.append(sorted_lcs(words[pair_index], words[pair_index + 1]))
    return "\n".join(answers) + "\n"


SAMPLE = "pretty\nwomen\nwalking\ndown\nthe\nstreet\n"
SAMPLE_OUT = "e\nnw\net\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("abc\nabc\n") == "abc\n"
assert oracle("aabbcc\nccbb\n") == "bbcc\n"
assert oracle("xyz\nabc\n") == "\n"
assert oracle("zyx\nabc\n") == "\n"


def write(name, pairs):
    text = "".join(first + "\n" + second + "\n" for first, second in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [("a", "a"), ("abc", "xyz"), ("zzz", "z"), ("abab", "bbaa")])
    write("3_wide", [("abcdefghijklmnopqrstuvwxyz" * 3, "zyxwvutsrqponmlkjihgfedcba" * 2)])
    rng = random.Random(20261126)
    letters = "abcdefghijklmnopqrstuvwxyz"
    pairs = []
    for _ in range(40):
        first = "".join(rng.choice(letters[:rng.randint(1, 12)]) for _ in range(rng.randint(1, 60)))
        second = "".join(rng.choice(letters[:rng.randint(1, 12)]) for _ in range(rng.randint(1, 60)))
        pairs.append((first, second))
    write("4_random", pairs)
    io_pairs = []
    for index in range(400):
        first = "".join(letters[(index + position) % 26] for position in range(120))
        second = "".join(letters[(index + position + 13) % 26] for position in range(120))
        io_pairs.append((first, second))
    write("5_io", io_pairs)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [("pretty", "women"), ("walking", "down"), ("the", "street")])
build()
