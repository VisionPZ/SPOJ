#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    count = int(tokens[0])
    cursor = 1
    forms = []
    values = []
    for _ in range(count):
        forms.append(tokens[cursor])
        literal = tokens[cursor + 1]
        cursor += 2
        values.append(int(literal, 2) if forms[-1] == 'b' else int(literal, 10))
    ordered = []
    remaining = list(values)
    while remaining:
        smallest = remaining[0]
        for candidate in remaining[1:]:
            if candidate < smallest:
                smallest = candidate
        ordered.append(smallest)
        remaining.remove(smallest)
    binary_count = forms.count('b')
    decimal_count = forms.count('d')
    if binary_count > decimal_count:
        lines = [format(value, 'b') for value in ordered]
    else:
        lines = [str(value) for value in ordered]
    return "\n".join(lines) + "\n"


SAMPLE = """3
b 111
d 2
d 15
"""
SAMPLE_OUT = """2
7
15
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3\nb 111\nb 10\nd 15\n") == "10\n111\n1111\n"
assert oracle("1\nd 0\n") == "0\n"
assert oracle("1\nb 0\n") == "0\n"
assert oracle("5\nb 101\nd 3\nb 1\nd 12\nb 111\n") == "1\n11\n101\n111\n1100\n"


def write(name, forms, values):
    text = str(len(values)) + "\n" + "".join(
        f"{form} {literal}\n" for form, literal in zip(forms, values))
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", ["b", "d", "b"], ["0", "0", "1"])
    write("3_wide", ["d", "b", "d", "b", "d"],
          ["2147483647", "1111111111111111111111111111111", "2147483646",
           "1000000000000000000000000000000", "0"])
    rng = random.Random(20261126)
    forms = []
    literals = []
    for _ in range(101):
        value = rng.randint(0, 2147483647)
        if rng.random() < 0.5:
            forms.append("b")
            literals.append(format(value, "b"))
        else:
            forms.append("d")
            literals.append(str(value))
    write("4_random", forms, literals)
    forms = ["b"] * 51 + ["d"] * 50
    literals = [format(index * 7, "b") if index < 51 else str(3000 - index * 9)
                for index in range(101)]
    write("5_io", forms, literals)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", ["b", "d", "d"], ["111", "2", "15"])
build()
