#!/usr/bin/env python3
import random
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PATTERN = "segsi"


def oracle(text):
    lines = text.split("\n")
    source = lines[0]
    repeats = int(lines[1])
    length = len(source)
    extended = source * (5 // length + 2)
    starts = [match.start() for match in re.finditer("(?=" + PATTERN + ")", extended)
              if match.start() < length]
    interior = sum(1 for start in starts if start <= length - 5)
    wrapping = sum(1 for start in starts if start > length - 5)
    return str(interior * repeats + wrapping * (repeats - 1)) + "\n"


def brute(source, repeats):
    repeated = source * repeats
    return sum(1 for start in range(len(repeated) - 4)
               if repeated[start:start + 5] == PATTERN)


SAMPLE = """siseg
10
"""
SAMPLE_OUT = """9
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("segsi\n10\n") == "10\n"
assert oracle("segsi\n1\n") == "1\n"
assert oracle("x\n1000000000\n") == "0\n"
assert oracle("se\n1000000000\n") == "0\n"
for source in ["siseg", "segsi", "segsis", "s", "segs", "gsiseg", "segsiseg"]:
    for repeats in range(1, 12):
        assert oracle(source + "\n" + str(repeats) + "\n") == str(brute(source, repeats)) + "\n"


def write(name, source, repeats):
    text = source + "\n" + str(repeats) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "x", 1)
    write("3_wide", "segsi" * 5, 1000000000)
    rng = random.Random(20261126)
    source = "".join(rng.choice("segsiabc") for _ in range(100000))
    write("4_random", source, 999999937)
    write("5_io", ("siseg" * 20000), 1000000000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", "siseg", 10)
build()
