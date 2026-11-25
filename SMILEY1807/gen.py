#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DIGITS = "1807"


def oracle(sequence):
    sequence = "".join(digit for digit in sequence if digit in DIGITS)
    length = len(sequence)
    boundaries = [0]
    for index in range(length - 1):
        if sequence[index] != sequence[index + 1]:
            boundaries.append(index + 1)
    boundaries.append(length)
    stats = [(0, 0, 0, 0)]
    counts = [0, 0, 0, 0]
    boundary_index = 1
    for index, digit in enumerate(sequence):
        counts[DIGITS.index(digit)] += 1
        if boundary_index < len(boundaries) and index + 1 == boundaries[boundary_index]:
            stats.append(tuple(counts))
            boundary_index += 1
    best = 0
    for first, second, third, fourth in itertools.combinations_with_replacement(range(len(stats)), 4):
        ones = stats[first][0]
        eights = stats[second][1] - stats[first][1]
        zeros = stats[third][2] - stats[second][2]
        sevens = stats[fourth][3] - stats[third][3]
        if ones > 0 and eights > 0 and zeros > 0 and sevens > 0:
            total = ones + eights + zeros + sevens
            if total > best:
                best = total
    return str(best) + "\n"


def brute(sequence):
    sequence = "".join(digit for digit in sequence if digit in DIGITS)
    length = len(sequence)
    prefix = [[0] for _ in range(4)]
    for index, digit in enumerate(sequence):
        for group in range(4):
            prefix[group].append(prefix[group][-1] + (digit == DIGITS[group]))
    best = 0
    for first in range(length + 1):
        for second in range(first, length + 1):
            for third in range(second, length + 1):
                for fourth in range(third, length + 1):
                    ones = prefix[0][first]
                    eights = prefix[1][second] - prefix[1][first]
                    zeros = prefix[2][third] - prefix[2][second]
                    sevens = prefix[3][fourth] - prefix[3][third]
                    if ones > 0 and eights > 0 and zeros > 0 and sevens > 0:
                        total = ones + eights + zeros + sevens
                        if total > best:
                            best = total
    return str(best) + "\n"


SAMPLE = "1800777700088888000777\n"
SAMPLE_OUT = "13\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute(SAMPLE) == SAMPLE_OUT
assert oracle("1807\n") == "4\n"
assert oracle("180\n") == "0\n"
assert oracle("111888000777\n") == "12\n"
assert oracle("180770\n") == "5\n"
assert oracle("1078\n") == "0\n"
assert brute("18077\n") == oracle("18077\n")


def write(name, sequence):
    (ROOT / "in" / f"{name}.txt").write_text(sequence + "\n")
    (ROOT / "out" / f"{name}.out").write_text(oracle(sequence + "\n"))


def build():
    write("2_edges", "1807")
    write("3_wide", "1" * 250000 + "8" * 250000 + "0" * 250000 + "7" * 250000)
    rng = random.Random(20261126)
    write("4_random", "".join(rng.choice(DIGITS) for _ in range(50)))
    write("5_io", "1" * 200000 + "8" * 300000 + "0" * 100000 + "7" * 400000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", "1800777700088888000777")
build()
