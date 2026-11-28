#!/usr/bin/env python3
import random
import string
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    lines = text.splitlines()
    first_line = lines[0] if lines else ""
    return first_line[:10] + "\n"


SAMPLE = "123456789011\n"
SAMPLE_OUT = "1234567890\n"

assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("abc\n") == "abc\n"
assert oracle("abcdefghij\n") == "abcdefghij\n"
assert oracle("abcdefghijk\n") == "abcdefghij\n"
assert oracle("\n") == "\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "\n")
    write("3_wide", "A" * 100 + "\n")
    rng = random.Random(20261126)
    alphabet = string.ascii_letters + string.digits
    for name, length in (("4_random", 60), ("5_io", 200000)):
        text = "".join(rng.choice(alphabet) for _ in range(length)) + "\n"
        write(name, text)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
