#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SAMPLE_INPUT = """1 11
12 20
1 20
3 100
6354 234363
123456789 234567891
0 0
"""
SAMPLE_OUTPUT = """1
0
1
9
82340
54801678
"""


def is_cool(number):
    digits = [int(char) for char in str(number)]
    total = sum(digits)
    if total % 2:
        return False
    target = total // 2
    reachable = {0}
    for digit in digits:
        reachable |= {value + digit for value in reachable if value + digit <= target}
    return target in reachable


def oracle_range(start, end):
    return sum(1 for number in range(start, end + 1) if is_cool(number))


def oracle(text):
    answers = []
    for line in text.splitlines():
        start, end = (int(value) for value in line.split())
        if start == 0 and end == 0:
            break
        answers.append(str(oracle_range(start, end)))
    return "\n".join(answers) + "\n"


assert oracle("1 11\n12 20\n1 20\n3 100\n0 0\n") == "1\n0\n1\n9\n"
assert oracle_range(1, 1) == 0
assert oracle_range(11, 11) == 1
assert oracle_range(1, 100) == 9
assert is_cool(23450) and is_cool(91125) and not is_cool(567) and not is_cool(34523)


def build_case(start, end):
    return f"{start} {end}\n"


def write(name, ranges):
    text = "".join(build_case(start, end) for start, end in ranges) + "0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1), (11, 11), (1, 9), (10, 10), (100, 100), (999, 999)])
    write("3_wide", [(90000, 120000), (150000, 180000)])
    rng = random.Random(20261126)
    random_ranges = []
    for _ in range(6):
        start = rng.randint(1, 400000)
        end = start + rng.randint(0, 30000)
        random_ranges.append((start, end))
    write("4_random", random_ranges)
    io_ranges = [(index * 3000 + 1, index * 3000 + 1200) for index in range(60)]
    write("5_io", io_ranges)
    with open("/tmp/COOLNUMS_big.txt", "w") as handle:
        handle.write("".join(build_case(start, end) for start, end in
                             [(1, 4000000000), (123456789, 234567891),
                              (3000000000, 4000000000)] * 20) + "0 0\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUTPUT)
build()
