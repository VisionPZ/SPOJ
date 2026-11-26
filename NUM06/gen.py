#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def stein_gcd(first, second):
    if first == 0:
        return second
    if second == 0:
        return first
    shift = 0
    while ((first | second) & 1) == 0:
        first >>= 1
        second >>= 1
        shift += 1
    while (first & 1) == 0:
        first >>= 1
    while second:
        while (second & 1) == 0:
            second >>= 1
        if first > second:
            first, second = second, first
        second -= first
    return first << shift


def oracle(text):
    tokens = [int(value) for value in text.split()]
    answers = []
    for cursor in range(0, len(tokens) - 1, 2):
        first, second = tokens[cursor], tokens[cursor + 1]
        if first == 0 and second == 0:
            break
        answers.append(str(stein_gcd(first, second)))
    return "\n".join(answers) + "\n" if answers else ""


SAMPLE = "5 6\n3 9\n10 2\n0 0\n"
SAMPLE_OUT = "1\n3\n2\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n0 0\n") == "1\n"
assert oracle("1000000000000000000 999999999999999999\n0 0\n") == "1\n"
assert oracle("0 7\n0 0\n") == "7\n"


def write(name, pairs):
    text = "".join(f"{first} {second}\n" for first, second in pairs) + "0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1), (1, 1000000000000000000), (0, 7), (999999999999999999, 999999999999999999)])
    write("3_wide", [(1000000000000000000, 999999999999999999)] * 20)
    rng = random.Random(20261126)
    pairs = [(rng.randint(1, 10 ** 18), rng.randint(1, 10 ** 18)) for _ in range(20)]
    write("4_random", pairs)
    write("5_io", pairs)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(5, 6), (3, 9), (10, 2)])
build()

if __name__ == "__main__":
    lines = ["1000000000000000000 999999999999999999"] * 500000
    lines.append("0 0")
    Path("/tmp/NUM06_big.txt").write_text("\n".join(lines) + "\n")
