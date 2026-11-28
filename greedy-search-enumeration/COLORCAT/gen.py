#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
COLORS = {"W", "R", "G"}


def oracle(text):
    tokens = text.split()
    cat_count = int(tokens[0])
    step_count = int(tokens[1])
    colors = list(tokens[2])
    for _ in range(step_count):
        for index in range(cat_count):
            neighbor = (index + 1) % cat_count
            first = colors[index]
            second = colors[neighbor]
            if first != second:
                third = (COLORS - {first, second}).pop()
                colors[index] = third
                colors[neighbor] = third
    return "".join(colors) + "\n"


def arithmetic_check(text):
    tokens = text.split()
    cat_count = int(tokens[0])
    step_count = int(tokens[1])
    values = [{"W": 0, "R": 1, "G": 2}[symbol] for symbol in tokens[2]]
    for _ in range(step_count):
        for index in range(cat_count):
            neighbor = (index + 1) % cat_count
            both = (3 - values[index] - values[neighbor]) % 3
            values[index] = both
            values[neighbor] = both
    return "".join("WRG"[value] for value in values) + "\n"


SAMPLE_ONE = """3 1
GRR
"""
SAMPLE_ONE_OUT = """RGR
"""
SAMPLE_TWO = """5 4
WRWRW
"""
SAMPLE_TWO_OUT = """GGGWG
"""
assert oracle(SAMPLE_ONE) == SAMPLE_ONE_OUT
assert oracle(SAMPLE_TWO) == SAMPLE_TWO_OUT
assert arithmetic_check(SAMPLE_ONE) == SAMPLE_ONE_OUT
assert arithmetic_check(SAMPLE_TWO) == SAMPLE_TWO_OUT
assert oracle("1 30000\nG\n") == "G\n"
assert oracle("3 1\nWRG\n") == "GGG\n"
assert oracle("4 2\nRGRG\n") == "GRRG\n"


def write(name, cat_count, step_count, colors):
    text = f"{cat_count} {step_count}\n{colors}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, 30000, "G")
    rng = random.Random(20261126)
    write("3_wide", 20000, 5, "".join(rng.choice("WRG") for _ in range(20000)))
    write("4_random", 1000, 2000, "".join(rng.choice("WRG") for _ in range(1000)))
    write("5_io", 20000, 300, "".join(rng.choice("WRG") for _ in range(20000)))


def trace_example():
    print("colors: G R R")
    print("pair 1-2: G and R become W")
    print("pair 2-3: W and R become G")
    print("pair 3-1: G and W become R")
    print("result: R G R")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 3, 1, "GRR")
build()
trace_example()
