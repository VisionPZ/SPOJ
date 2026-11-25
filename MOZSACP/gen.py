#!/usr/bin/env python3
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = ""
SAMPLE_OUT = "C Programming\n"

MESSAGE_WORDS = ["C", "Programming"]


def oracle(input_text):
    return " ".join(MESSAGE_WORDS) + "\n"


def write(name, input_text):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert len(MESSAGE_WORDS) == 2
assert oracle("The input is empty.\n") == SAMPLE_OUT
assert oracle("0\n") == SAMPLE_OUT


def trace_example():
    print("words", MESSAGE_WORDS)
    print("output", oracle("").strip())


def build():
    write("2_edges", "0\n")
    write("3_wide", "1" * 1000 + "\n")
    rng = random.Random(61327)
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
