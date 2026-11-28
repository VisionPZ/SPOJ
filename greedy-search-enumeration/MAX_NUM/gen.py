#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def best_after_one_deletion(digits):
    best = None
    for remove_index in range(len(digits)):
        candidate = digits[:remove_index] + digits[remove_index + 1:]
        if best is None or candidate > best:
            best = candidate
    return best


def oracle_case(digits, delete_count):
    current = digits
    for _ in range(delete_count):
        current = best_after_one_deletion(current)
    return current


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    cursor = 1
    answers = []
    for _ in range(case_count):
        digits = tokens[cursor]
        delete_count = int(tokens[cursor + 1])
        cursor += 2
        answers.append(oracle_case(digits, delete_count))
    return "\n".join(answers) + "\n"


def brute_case(digits, delete_count):
    from itertools import combinations
    length = len(digits)
    best = ""
    for kept in combinations(range(length), length - delete_count):
        candidate = "".join(digits[index] for index in kept)
        if candidate > best:
            best = candidate
    return best


SAMPLE = "2\n1223 2\n8756 2\n"
SAMPLE_OUT = "23\n87\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n01 0\n") == "01\n"
assert oracle("1\n111 3\n") == "\n"
assert oracle("1\n313 1\n") == "33\n"
assert oracle("1\n987654321 4\n") == "98765\n"
for sample_digits in ["1223", "8756", "313", "01010", "987654321"]:
    for delete_count in range(len(sample_digits) + 1):
        assert oracle_case(sample_digits, delete_count) == brute_case(sample_digits, delete_count)


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(
        f"{digits} {delete_count}\n" for digits, delete_count in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [("0", 0), ("000", 1), ("123", 3), ("01", 0), ("9", 1), ("11111", 4)])
    write("3_wide", [("9" * 300, 150), ("1" * 300, 299), ("0" * 200, 100)])
    rng = random.Random(20261126)
    wide_cases = []
    for _ in range(40):
        length = rng.randint(1, 80)
        digits = "".join(rng.choice("0123456789") for _ in range(length))
        wide_cases.append((digits, rng.randint(0, length)))
    write("4_random", wide_cases)
    io_cases = []
    for _ in range(120):
        digits = "".join(rng.choice("0123456789") for _ in range(200))
        io_cases.append((digits, 1))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [("1223", 2), ("8756", 2)])
build()
