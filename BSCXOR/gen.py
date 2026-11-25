#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
STATEMENT = (ROOT.parent / "stmts" / "BSCXOR.txt").read_text()

SAMPLES = [("1 1\n", "0\n")]


def oracle(text):
    first_value, second_value = (int(token) for token in text.split())
    return str(first_value ^ second_value) + "\n"


for sample_input, sample_output in SAMPLES:
    assert sample_input in STATEMENT
    assert sample_output in STATEMENT
    assert oracle(sample_input) == sample_output

assert oracle("0 0\n") == "0\n"
assert oracle("0 1\n") == "1\n"
assert oracle("1 0\n") == "1\n"
assert oracle("1 1\n") == "0\n"


def write(name, first_value, second_value):
    input_text = f"{first_value} {second_value}\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace(first_value, second_value):
    return (f"p {first_value}, q {second_value}, different "
            f"{int(first_value != second_value)}\nanswer {oracle(f'{first_value} {second_value}')}".rstrip("\n"))


random.seed(2026)
write("1_sample", 1, 1)
write("2_edges", 0, 0)
write("3_wide", 0, 1)
write("4_random", random.randint(0, 1), random.randint(0, 1))
write("5_io", 1, 0)

if __name__ == "__main__":
    print(trace(1, 1))
