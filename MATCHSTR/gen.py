#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "123123\n12\n"
SAMPLE_OUT = "2\n"


def oracle(input_text):
    lines = input_text.split()
    if len(lines) < 2:
        return "0\n"
    text, pattern = lines[0], lines[1]
    count = 0
    searchPos = 0
    while True:
        searchPos = text.find(pattern, searchPos)
        if searchPos < 0:
            break
        count += 1
        searchPos += 1
    return "%d\n" % count


def write(name, text, pattern):
    input_text = "%s\n%s\n" % (text, pattern)
    (ROOT / "in" / ("%s.txt" % name)).write_text(input_text)
    (ROOT / "out" / ("%s.out" % name)).write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("aaaa\naa\n") == "3\n"
assert oracle("abcde\nz\n") == "0\n"
assert oracle("121212\n1212\n") == "2\n"
assert oracle("7\n7\n") == "1\n"


def build():
    write("2_edges", "0", "0")
    write("3_wide", "1" * 100000, "1" * 10)
    rng = random.Random(20181122)
    long_text = "".join(str(rng.randint(0, 9)) for _ in range(1000000))
    long_pattern = "".join(str(rng.randint(0, 9)) for _ in range(1000000))
    write("4_random", long_text, long_pattern)
    medium_text = "".join(str(rng.randint(0, 9)) for _ in range(20000))
    medium_pattern = "".join(str(rng.randint(0, 9)) for _ in range(50))
    write("5_io", medium_text, medium_pattern)
    extra_text = "".join(str(rng.randint(0, 9)) for _ in range(1000000))
    single_digit = str(rng.randint(0, 9))
    (ROOT / "in" / "6_single.txt").write_text("%s\n%s\n" % (extra_text, single_digit))
    (ROOT / "out" / "6_single.out").write_text(oracle("%s\n%s\n" % (extra_text, single_digit)))


if __name__ == "__main__":
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", "123123", "12")
    build()
