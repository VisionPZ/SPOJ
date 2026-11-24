#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
LAST_ATM = 99
MAX_LOAN = (4 ** 50 - 1) // 3


def negabinary(value):
    digits = []
    while value != 0:
        quotient, remainder = divmod(value, 4)
        digits.append(remainder % 2)
        digits.append(remainder // 2)
        value = quotient + (1 if remainder >= 2 else 0)
    while digits and digits[-1] == 0:
        digits.pop()
    return digits


def atm_line(amount, sign):
    digits = negabinary(sign * amount)
    used = [index for index, digit in enumerate(digits) if digit]
    if not used or used[-1] > LAST_ATM:
        return "No"
    return " ".join(str(index) for index in reversed(used))


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    lines = []
    for _ in range(count):
        amount = int(tokens[cursor])
        cursor += 1
        lines.append(atm_line(amount, 1))
        lines.append(atm_line(amount, -1))
    assert cursor == len(tokens)
    return "\n".join(lines) + "\n"


def write(name, amounts):
    input_text = str(len(amounts)) + "\n" + "".join(
        f"{amount}\n" for amount in amounts)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE_INPUT = "2\n7\n633825300114114700748351602698\n"
SAMPLE_OUTPUT = "4 3 1 0\n3 0\nNo\n99 3 1\n"

assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert atm_line(7, 1) == "4 3 1 0" and atm_line(7, -1) == "3 0"
assert atm_line(MAX_LOAN, 1).split() == [str(index) for index in range(98, -1, -2)]
assert atm_line(MAX_LOAN + 1, 1) == "No"
assert atm_line(10 ** 30 - 1, -1) == "No"
assert 2 ** 99 + 10 == 633825300114114700748351602698

subset_values = {}
for mask in range(1 << 10):
    total = sum(((-2) ** index) for index in range(10) if mask >> index & 1)
    assert total not in subset_values
    subset_values[total] = mask
for value in range(-200, 201):
    mask = subset_values[value]
    expected = [(mask >> index) & 1 for index in range(10)]
    while expected and expected[-1] == 0:
        expected.pop()
    assert negabinary(value) == expected


def worked_example():
    value = 7
    rows = []
    while value != 0:
        quotient, remainder = divmod(value, 4)
        rows.append((value, quotient, remainder, remainder % 2,
                     remainder // 2, quotient + (1 if remainder >= 2 else 0)))
        value = quotient + (1 if remainder >= 2 else 0)
    return rows


def build():
    edges = [1, 2, 3, 7, 2 ** 98, 2 ** 99 + 10, MAX_LOAN - 1,
             MAX_LOAN, MAX_LOAN + 1, 2 * MAX_LOAN, 10 ** 30 - 1]
    write("2_edges", edges)

    wide = []
    for index in range(100):
        wide.append(MAX_LOAN - index)
        wide.append(MAX_LOAN + index)
        wide.append(2 ** 99 + index)
        wide.append(10 ** 30 - 1 - index)
    write("3_wide", wide)

    random.seed(2026)
    random_cases = []
    for index in range(3000):
        if index % 4 == 0:
            amount = random.randint(1, 1000)
        elif index % 4 == 1:
            amount = random.randint(1, MAX_LOAN)
        elif index % 4 == 2:
            amount = random.randint(MAX_LOAN, 2 * MAX_LOAN)
        else:
            amount = random.randint(1, 10 ** 30 - 1)
        random_cases.append(amount)
    write("4_random", random_cases)

    write("5_io", [MAX_LOAN] * 10000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUTPUT)
build()
for row in worked_example():
    print(row)
