#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    datasets = []
    current = []
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if line:
            current.append(line)
        elif current:
            datasets.append(current)
            current = []
    if current:
        datasets.append(current)
    blocks = []
    for dataset in datasets:
        ordering = dataset[0]
        digit_values = {character: index for index, character in enumerate(ordering)}
        highest_base = len(ordering)
        answers = []
        for number_line in dataset[1:]:
            digits = [digit_values[character] for character in number_line]
            lowest_base = max(2, max(digits) + 1)
            total = 0
            for base in range(lowest_base, highest_base + 1):
                power = len(digits) - 1
                for digit in digits:
                    total += digit * base ** power
                    power -= 1
            answers.append(str(total))
        blocks.append("\n".join(answers))
    return "\n\n".join(blocks) + "\n"


SAMPLE = """0123456789
  90763  
1

.1>C
CC.
>.1
1....
"""
SAMPLE_OUT = """90763
9

60
52
353
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("0123456789\n0\n") == "0\n"
assert oracle("01\n10\n1111\n") == "2\n15\n"
assert oracle("012\n22\n") == "8\n"
assert oracle("0123456789\n6201\n") == str(sum(int("6201", base) for base in range(7, 11))) + "\n"


def write(name, datasets):
    text = "\n\n".join("\n".join(dataset) for dataset in datasets) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [["01", "0", "1", "10", "1111"], [".1>C", ".", "C", ">"]])
    wide_ordering = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    rng = random.Random(20261126)
    wide_numbers = ["".join(rng.choice(wide_ordering) for _ in range(20)) for _ in range(8)]
    write("3_wide", [["0123456789"] + ["99999999999999999999", "10000000000000000000"],
                     [wide_ordering] + wide_numbers])
    random_datasets = []
    for _ in range(4):
        ordering = "".join(rng.sample("0123456789#$%&*+-<=>?@", 10))
        numbers = ["".join(rng.choice(ordering) for _ in range(rng.randint(1, 20)))
                   for _ in range(10)]
        random_datasets.append([ordering] + numbers)
    write("4_random", random_datasets)
    long_ordering = "".join(chr(code) for code in range(33, 127))
    io_numbers = ["".join(rng.choice(long_ordering) for _ in range(100)) for _ in range(100)]
    write("5_io", [[long_ordering] + io_numbers])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [["0123456789", "  90763  ", "1"], [".1>C", "CC.", ">.1", "1...."]])
build()
