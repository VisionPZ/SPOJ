#!/usr/bin/env python3
import bisect
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PATTERN = "PANDA"


def oracle(text):
    letters = "".join(value for value in text.split())
    length = len(letters)
    prefix = {letter: [0] for letter in PATTERN}
    for char in letters:
        for letter in prefix:
            prefix[letter].append(prefix[letter][-1] + (1 if char == letter else 0))

    def can(level):
        if level == 0:
            return True
        start = 0
        for letter in PATTERN:
            counts = prefix[letter]
            target = counts[start] + level
            spot = bisect.bisect_left(counts, target, start, length + 1)
            if spot > length:
                return False
            start = spot
        return True

    low = 0
    high = length // 5 + 1
    while high - low > 1:
        middle = (low + high) // 2
        if can(middle):
            low = middle
        else:
            high = middle
    return str(low) + "\n"


SAMPLE = "PADPAPAAANDNDNPANDADDDAAADA\n"
SAMPLE_OUT = "3\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("ADNAP\n") == "0\n"
assert oracle("PANDA\n") == "1\n"
assert oracle("PPPAAANNNDDDAAA\n") == "3\n"
assert oracle("PPAANNDDAA\n") == "2\n"
assert oracle("APANDA\n") == "1\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "PPAAA\n")
    write("3_wide", "PANDA" * 20000 + "\n")
    rng = random.Random(20261126)
    write("4_random", "".join(rng.choice(PATTERN) for _ in range(5000)) + "\n")
    write("5_io", "".join(rng.choice(PATTERN) for _ in range(100000)) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
