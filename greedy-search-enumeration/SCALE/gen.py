#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    weight_count, target = tokens[0], tokens[1]
    if weight_count <= 12:
        states = {0: ()}
        for weight_index in range(1, weight_count + 1):
            mass = 3 ** (weight_index - 1)
            updated = {}
            for difference, digits in states.items():
                for digit in (-1, 0, 1):
                    new_difference = difference + digit * mass
                    if new_difference not in updated:
                        updated[new_difference] = digits + (digit,)
            states = updated
        if target not in states:
            return "-1\n"
        digits = states[target]
    else:
        digits = []
        remaining = target
        while remaining != 0 and len(digits) < weight_count:
            residue = remaining % 3
            if residue == 0:
                digits.append(0)
                remaining //= 3
            elif residue == 1:
                digits.append(1)
                remaining = (remaining - 1) // 3
            else:
                digits.append(-1)
                remaining = (remaining + 1) // 3
        if remaining != 0:
            return "-1\n"
        while len(digits) < weight_count:
            digits.append(0)
    first_scale = [str(index + 1) for index, digit in enumerate(digits) if digit == -1]
    second_scale = [str(index + 1) for index, digit in enumerate(digits) if digit == 1]
    return " ".join(first_scale) + "\n" + " ".join(second_scale) + "\n"


SAMPLE_ONE = """10 2
"""
SAMPLE_ONE_OUT = """1
2
"""
SAMPLE_TWO = """10 5
"""
SAMPLE_TWO_OUT = """1 2
3
"""
assert oracle(SAMPLE_ONE) == SAMPLE_ONE_OUT
assert oracle(SAMPLE_TWO) == SAMPLE_TWO_OUT
assert oracle("20 8\n") == "1\n3\n"
assert oracle("20 11\n") == "1\n2 3\n"
assert oracle("20 4\n") == "\n1 2\n"
assert oracle("1 3\n") == "-1\n"
assert oracle("20 2000000000\n") == "-1\n"


def write(name, weight_count, target):
    input_text = f"{weight_count} {target}\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", 1, 1)
    write("3_wide", 12, 265720)
    rng = random.Random(20261126)
    write("4_random", 20, rng.randint(1, 1742510498))
    write("5_io", 20, rng.randint(1, 1742510498))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 10, 2)
build()
