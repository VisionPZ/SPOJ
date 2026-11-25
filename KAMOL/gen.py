#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
STATEMENT_LINE = 'Just print "GoodBye Kam0L Bhai" and grab your point.'
FAREWELL = "GoodBye Kam0L Bhai\n"


def oracle(text):
    start = STATEMENT_LINE.index('"') + 1
    end = STATEMENT_LINE.index('"', start)
    return STATEMENT_LINE[start:end] + "\n"


assert oracle("") == FAREWELL
assert oracle("\n") == FAREWELL
assert oracle("123 456\n") == FAREWELL
assert oracle(FAREWELL) == FAREWELL


def write(name, input_text):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", "\n\n")
    write("3_wide", "123\n456\n")
    rng = random.Random(20261126)
    write("4_random", "".join(f"{rng.randint(0, 9)} " for _ in range(40)) + "\n")
    write("5_io", "".join(f"{rng.randint(0, 9)}\n" for _ in range(5000)))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", "")
build()
