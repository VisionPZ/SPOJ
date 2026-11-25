#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    lines = text.splitlines()
    length = int(lines[0])
    first = list(lines[1][:length])
    second = list(lines[2][:length])
    count = int(lines[3])
    cursor = 4
    for _ in range(count):
        left = int(lines[cursor].split()[0])
        right = int(lines[cursor].split()[1])
        cursor += 1
        for position in range(left, right + 1):
            first[position], second[position] = second[position], first[position]
    return "".join(first) + "\n" + "".join(second) + "\n"


SAMPLE = """6
abcdef
ghijkl
4
2 4
1 3
4 4
4 5
"""
SAMPLE_OUT = """ahcdkl
gbijef
"""

assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\nx\ny\n1\n0 0\n") == "y\nx\n"
assert oracle("3\nabc\nxyz\n2\n0 2\n0 2\n") == "abc\nxyz\n"
assert oracle("4\nabcd\nwxyz\n1\n1 2\n") == "axyd\nwbcz\n"
assert len(SAMPLE_OUT.splitlines()) == 2


def write_case(name, first, second, operations):
    text = (str(len(first)) + "\n" + first + "\n" + second + "\n" +
            str(len(operations)) + "\n" +
            "".join(f"{left} {right}\n" for left, right in operations))
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_case("2_edges", "x", "y", [(0, 0), (0, 0), (0, 0)])
    write_case("3_wide", "a b c d e"[:100].ljust(100, "."),
               "z y x w v"[:100].ljust(100, "."), [(0, 99)] * 7)
    rng = random.Random(20261126)
    alphabet = "abcde fgh!?123"
    length = 200
    first = "".join(rng.choice(alphabet) for _ in range(length))
    second = "".join(rng.choice(alphabet) for _ in range(length))
    operations = []
    for _ in range(1000):
        left = rng.randrange(length)
        right = rng.randrange(left, length)
        operations.append((left, right))
    write_case("4_random", first, second, operations)
    big_length = 20000
    first = "".join(chr(33 + (index % 90)) for index in range(big_length))
    second = "".join(chr(33 + ((index * 7 + 11) % 90)) for index in range(big_length))
    write_case("5_io", first, second, [(0, big_length - 1), (1, big_length - 2), (0, 0)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
