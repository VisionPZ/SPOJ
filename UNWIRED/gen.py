#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    cursor = 1
    for _ in range(case_count):
        wire = tokens[cursor]
        pieces = tokens[cursor + 1]
        loss = tokens[cursor + 2]
        cursor += 3
        low, high = 0, wire // pieces
        while low < high:
            middle = (low + high + 1) // 2
            needed = pieces * middle + (pieces - 1) * loss
            if needed <= wire:
                low = middle
            else:
                high = middle - 1
        answers.append(str(low))
    return "\n".join(answers) + "\n"


SAMPLE = "3\n1 1 1\n100 2 20\n44 3 5\n"
SAMPLE_OUT = "1\n40\n11\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n10 1 5\n") == "10\n"
assert oracle("1\n10 3 5\n") == "0\n"
assert oracle("1\n1000000000 1000000000 1\n") == "0\n"


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(f"{wire} {pieces} {loss}\n" for wire, pieces, loss in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1, 1), (10, 1, 5), (10, 3, 5), (999999999, 999999999, 1)])
    write("3_wide", [(1000000000, 2, 1)] * 10)
    rng = random.Random(20261126)
    cases = [(rng.randint(1, 1000000000), rng.randint(1, 1000000000), rng.randint(1, 1000000000))
             for _ in range(10)]
    write("4_random", cases)
    write("5_io", cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(1, 1, 1), (100, 2, 20), (44, 3, 5)])
build()
