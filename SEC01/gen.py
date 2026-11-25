#!/usr/bin/env python3
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = ""
SAMPLE_OUT = "Sylhet International University\n"

NAME_WORDS = ["Sylhet", "International", "University"]


def oracle(input_text):
    return " ".join(NAME_WORDS) + "\n"


def write(name, input_text):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert len(NAME_WORDS) == 3
assert oracle("no input\n") == SAMPLE_OUT
assert oracle("123 456\n") == SAMPLE_OUT


def trace_example():
    print("words", NAME_WORDS)
    print("output", oracle("").strip())


def build():
    write("2_edges", "0\n")
    write("3_wide", "9" * 1000 + "\n")
    rng = random.Random(73201)
    random_bytes = "".join(chr(rng.randint(32, 126)) for _ in range(5000))
    write("4_random", random_bytes + "\n")
    write("5_io", "ignored input\n" * 8000)


if __name__ == "__main__":
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", SAMPLE_INPUT)
        build()
