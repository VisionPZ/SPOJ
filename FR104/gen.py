#!/usr/bin/env python3
"""Test-data generator and statement-derived oracle for FR104.

The key shifts each ASCII code before hex output.
The oracle sorts names with Python's key function and formats hex with format().
The solution quicksorts with a hand comparator and uses a hex digit table.
"""
import random
import string
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "2\nJuan\nJUAN1\nLazaro?\nPedrito\n*\n"
SAMPLE_OUTPUT = (
    "4C776370\n"
    "4C57435033\n"
    "4E637C63747141\n"
    "526766746B7671\n"
)


def encrypted_name(name, key):
    return "".join(format(ord(character) + key, "02X") for character in name)


def oracle(text):
    lines = [line.strip() for line in text.splitlines()]
    lines = [line for line in lines if line]
    if not lines:
        return ""
    key = int(lines[0])
    names = []
    for line in lines[1:]:
        if line == "*":
            break
        names.append(line)
    names.sort(key=lambda value: (value.lower(), value))
    return "".join(encrypted_name(name, key) + "\n" for name in names)


def write(name, key, names):
    input_text = str(key) + "\n" + "".join(value + "\n" for value in names) + "*\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert SAMPLE_OUTPUT == (
    "4C776370\n4C57435033\n4E637C63747141\n526766746B7671\n")
assert encrypted_name("Juan", 2) == "4C776370"
assert oracle("3\nz\nA\n*\n") == "44\n7D\n"
assert oracle("0\n*\n") == ""


def trace_example():
    for name in ["Juan", "JUAN1", "Lazaro?", "Pedrito"]:
        print("%s -> %s" % (name, encrypted_name(name, 2)))


def main():
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", 2, ["Juan", "JUAN1", "Lazaro?", "Pedrito"])
    write("2_edges", 3, ["alpha", "ALPHA", "Alpha", "beta", "BETA", "Z", "z", "0", "?"])
    write("3_wide", 1, ["A" * 200, "z" * 200, "0" * 200, "?" * 200])
    random.seed(2026)
    alphabet = string.ascii_letters + string.digits + "?-."
    write("4_random", 2, ["".join(random.choice(alphabet)
                                 for _ in range(random.randint(1, 30)))
                          for _ in range(200)])
    write("5_io", 3, ["".join(random.choice(alphabet)
                              for _ in range(random.randint(10, 40)))
                       for _ in range(5000)])


if "--trace" in sys.argv:
    trace_example()
else:
    main()
