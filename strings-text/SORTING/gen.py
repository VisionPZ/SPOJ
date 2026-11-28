#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MAX_LINE = 1000


def insertion_sort(text):
    letters = list(text)
    for i in range(1, len(letters)):
        held = letters[i]
        j = i - 1
        while j >= 0 and letters[j] > held:
            letters[j + 1] = letters[j]
            j -= 1
        letters[j + 1] = held
    return "".join(letters)


def oracle(text):
    letters = [ch for ch in text if "A" <= ch <= "Z"]
    return "".join(sorted(letters)) + "\n"


def write(name, lines):
    input_text = "".join(line + "\n" for line in lines)
    (ROOT / "in" / (name + ".txt")).write_text(input_text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(input_text))


SAMPLE = "BRAINFUCK"
assert oracle(SAMPLE + "\n") == "ABCFIKNRU\n"
assert oracle("A\n") == "A\n"
assert oracle("Z\n") == "Z\n"
assert oracle("ZZZZ\n") == "ZZZZ\n"
assert oracle("ZYXWVUTSRQPONMLKJIHGFEDCBA\n") == "ABCDEFGHIJKLMNOPQRSTUVWXYZ\n"
random.seed(11)
for _ in range(200):
    small = "".join(random.choice("ABCDEFGH") for _ in range(random.randint(0, 30)))
    assert insertion_sort(small) == oracle(small + "\n").rstrip("\n")


def build():
    write("2_edges", [
        "",
        "A",
        "Z",
        "AAAA",
        "ZYXWVUTSRQPONMLKJIHGFEDCBA",
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        "A" * MAX_LINE,
    ])
    write("3_wide", [
        "Z" * MAX_LINE,
        "A" * MAX_LINE,
        "".join(random.choice("AZ") for _ in range(MAX_LINE)),
    ])

    random.seed(20261124)
    write("4_random", [
        "".join(random.choice("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
                for _ in range(random.randint(1, MAX_LINE)))
        for _ in range(8)
    ])
    write("5_io", [
        "".join(random.choice("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
                for _ in range(MAX_LINE))
    ])


def worked_example():
    print("input:", SAMPLE)
    for letter in sorted(set(SAMPLE)):
        print(letter, SAMPLE.count(letter))
    print("output:", oracle(SAMPLE + "\n").rstrip("\n"))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [SAMPLE])
build()
worked_example()
