#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "1\n"
SAMPLE_OUTPUT = "I hate it\n"


def feeling(layer_index, layer_count):
    hates = layer_index % 2 == 1
    if layer_index == layer_count:
        return "I hate it" if hates else "I love it"
    prefix = "I hate that " if hates else "I love that "
    return prefix + feeling(layer_index + 1, layer_count)


def oracle(text):
    layer_count = int(text.split()[0])
    return feeling(1, layer_count) + "\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("2\n") == "I hate that I love it\n"
assert oracle("3\n") == "I hate that I love that I hate it\n"
assert oracle("4\n") == "I hate that I love that I hate that I love it\n"
assert oracle("5\n") == "I hate that I love that I hate that I love that I hate it\n"


def write(name, layer_count):
    input_text = str(layer_count) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace():
    for layer_count in range(1, 5):
        print(f"layers {layer_count}: {oracle(str(layer_count) + chr(10)).strip()}")
    print("layer words alternate, and the last word pair changes from that to it")


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", 1)
        write("2_edges", 2)
        write("3_wide", 100)
        random.seed(2026)
        write("4_random", random.randint(1, 100))
        write("5_io", 99)
