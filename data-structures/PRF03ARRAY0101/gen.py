#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = "5\n2\n-1\n8\n3\n0\n"
SAMPLE_OUT = (
    "How many element of numeric array:"
    "The value of a[1] is:The value of a[2] is:The value of a[3] is:"
    "The value of a[4] is:The value of a[5] is:\n"
    "\n"
    "5 element of numeric array:\n"
    "The value of a[1] is:2\n"
    "The value of a[2] is:-1\n"
    "The value of a[3] is:8\n"
    "The value of a[4] is:3\n"
    "The value of a[5] is:0\n"
)


def oracle(text):
    tokens = iter(text.split())
    count = int(next(tokens))
    values = [int(next(tokens)) for _ in range(count)]
    prompts = "How many element of numeric array:"
    for index in range(1, count + 1):
        prompts += f"The value of a[{index}] is:"
    listing = f"{count} element of numeric array:\n"
    for index, value in enumerate(values, 1):
        listing += f"The value of a[{index}] is:{value}\n"
    return prompts + "\n\n" + listing


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3\n2\n1\n3\n") == (
    "How many element of numeric array:The value of a[1] is:"
    "The value of a[2] is:The value of a[3] is:\n\n"
    "3 element of numeric array:\nThe value of a[1] is:2\n"
    "The value of a[2] is:1\nThe value of a[3] is:3\n"
)
assert oracle("1\n-7\n") == (
    "How many element of numeric array:The value of a[1] is:\n\n"
    "1 element of numeric array:\nThe value of a[1] is:-7\n"
)
assert oracle("2\n0\n0\n").count("The value of a[") == 4


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "1\n-5\n")
    write("3_wide", "4\n1000000000\n-1000000000\n2147483647\n-2147483648\n")
    rng = random.Random(20261130)
    values = [rng.randint(-1000000, 1000000) for _ in range(8)]
    write("4_random", "8\n" + "\n".join(str(value) for value in values) + "\n")
    io_values = [rng.randint(-1000000, 1000000) for _ in range(6000)]
    write("5_io", "6000\n" + "\n".join(str(value) for value in io_values) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
