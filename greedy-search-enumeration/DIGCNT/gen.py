#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


@lru_cache(maxsize=None)
def digit_totals(limit):
    digits = [ord(char) - 48 for char in str(limit)]
    length = len(digits)

    @lru_cache(maxsize=None)
    def walk(position, tight):
        if position == length:
            return (0,) * 9
        cap = digits[position] if tight else 9
        totals = [0] * 9
        for choice in range(cap + 1):
            stays_tight = tight and choice == cap
            if stays_tight:
                suffix_text = "".join(str(value) for value in digits[position + 1:])
                completions = int(suffix_text) + 1 if suffix_text else 1
            else:
                completions = 10 ** (length - position - 1)
            if choice:
                totals[choice - 1] += completions
            lower = walk(position + 1, stays_tight)
            for digit in range(1, 10):
                totals[digit - 1] += lower[digit - 1]
        return tuple(totals)

    return walk(0, True)


def oracle(text):
    tokens = text.split()
    cursor = 0
    lines = []
    while cursor + 1 < len(tokens):
        start = int(tokens[cursor])
        end = int(tokens[cursor + 1])
        cursor += 2
        if start == 0:
            break
        if start > end:
            start, end = end, start
        upper = digit_totals(end)
        lower = digit_totals(start - 1)
        counts = [upper[digit - 1] - lower[digit - 1] for digit in range(1, 10)]
        lines.append(" ".join(str(value) for value in counts))
    return "\n".join(lines) + ("\n" if lines else "")


def brute(text):
    tokens = text.split()
    cursor = 0
    lines = []
    while cursor + 1 < len(tokens):
        start = int(tokens[cursor])
        end = int(tokens[cursor + 1])
        cursor += 2
        if start == 0:
            break
        if start > end:
            start, end = end, start
        counts = [0] * 9
        for number in range(start, end + 1):
            for char in str(number):
                digit = ord(char) - 48
                if digit:
                    counts[digit - 1] += 1
        lines.append(" ".join(str(value) for value in counts))
    return "\n".join(lines) + ("\n" if lines else "")


SAMPLE = "1 10\n0 0\n"
SAMPLE_OUT = "2 1 1 1 1 1 1 1 1\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute(SAMPLE) == SAMPLE_OUT
assert oracle("1 9\n0 0\n") == "1 1 1 1 1 1 1 1 1\n"
assert oracle("10 10\n0 0\n") == "1 0 0 0 0 0 0 0 0\n"
assert digit_totals(99) == (20,) * 9
assert oracle("1024 1032\n0 0\n") == brute("1024 1032\n0 0\n")


def write(name, pairs):
    text = "".join(f"{start} {end}\n" for start, end in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1), (9, 1), (10, 10), (99, 100), (0, 7)])
    write("3_wide", [(1, 10**16), (10**16, 10**16), (10**16 - 1, 10**16)])
    rng = random.Random(20261126)
    pairs = []
    for _ in range(80):
        start = rng.randint(1, 10**16)
        end = min(10**16, start + rng.randint(0, 10**9))
        pairs.append((start, end))
    write("4_random", pairs)
    big_pairs = [(10**16 - rng.randint(0, 10**8), 10**16) for _ in range(500)]
    write("5_io", big_pairs)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(1, 10), (0, 0)])
build()
