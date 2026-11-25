#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    token = text.split()[0]
    return "YA\n" if token == token[::-1] else "TIDAK\n"


SAMPLE = "1221\n"
SAMPLE_OUT = "YA\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1123\n") == "TIDAK\n"
assert oracle("7\n") == "YA\n"
assert oracle("10\n") == "TIDAK\n"


def write(name, value):
    text = str(value) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1)
    write("3_wide", 99999)
    write("4_random", 54321)
    write("5_io", 12321)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 1221)
build()
