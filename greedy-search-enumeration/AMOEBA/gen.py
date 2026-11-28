#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def build_days(digit_count):
    modulus = 10 ** digit_count
    order = 1
    while pow(7, order, modulus) != 1:
        order += 1
    first_day = {}
    for exponent in range(order):
        value = pow(7, exponent, modulus)
        if value not in first_day:
            first_day[value] = exponent + 1
    return first_day


TABLES = {digit_count: build_days(digit_count) for digit_count in range(1, 10)}


def oracle(text):
    lines = []
    for line in text.splitlines():
        if not line.strip():
            continue
        digit_count = len(line.strip())
        target = int(line.strip())
        lines.append(str(TABLES[digit_count].get(target, -1)))
    return "\n".join(lines) + "\n" if lines else ""


SAMPLE = """01
143
743
600
"""
SAMPLE_OUT = """1
20
12
-1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n") == "1\n"
assert oracle("7\n") == "2\n"
assert oracle("9\n") == "3\n"
assert oracle("000000000\n") == "-1\n"
assert pow(7, 11, 1000) == 743
assert TABLES[3][743] == 12


def write(name, lines):
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", ["1", "7", "9", "3", "01", "00", "000000000", "777777777", "600"])
    wide = []
    for exponent in range(0, 40):
        wide.append(f"{pow(7, exponent, 10 ** 9):09d}")
    wide.extend(["000000000", "222222222", "864000000", "999999999"])
    write("3_wide", wide)
    rng = random.Random(20261126)
    random_lines = []
    for _ in range(80):
        digit_count = rng.randint(1, 9)
        random_lines.append("".join(str(rng.randint(0, 9)) for _ in range(digit_count)))
    write("4_random", random_lines)
    io_lines = []
    for index in range(50000):
        if index % 3 == 0:
            io_lines.append(f"{pow(7, index % 5000, 10 ** 9):09d}")
        else:
            io_lines.append(f"{rng.randrange(1, 10 ** 9, 2):09d}")
    write("5_io", io_lines)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", ["01", "143", "743", "600"])
build()
