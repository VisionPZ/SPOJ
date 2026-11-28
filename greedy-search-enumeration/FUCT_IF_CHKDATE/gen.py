#!/usr/bin/env python3
import datetime
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """7
9 8 2018
3 39 2000
2 29 2018
20 -4 1998 
2 29 2000
7 31 1986 
11 31 2002
"""
SAMPLE_OUT = """VALID
INVALID
INVALID
INVALID
VALID
VALID
INVALID
"""


def manual_valid(month_value, day_value, year_value):
    if month_value < 1 or month_value > 12:
        return False
    lengths = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    limit = lengths[month_value]
    if month_value == 2 and (year_value % 400 == 0 or (year_value % 4 == 0 and year_value % 100 != 0)):
        limit += 1
    return 1 <= day_value <= limit


def oracle(input_text):
    tokens = input_text.split()
    count = int(tokens[0])
    answers = []
    cursor = 1
    for _ in range(count):
        month_value = int(tokens[cursor])
        day_value = int(tokens[cursor + 1])
        year_value = int(tokens[cursor + 2])
        cursor += 3
        if 1 <= year_value <= 9999:
            ok = True
            try:
                datetime.date(year_value, month_value, day_value)
            except ValueError:
                ok = False
        else:
            ok = manual_valid(month_value, day_value, year_value)
        answers.append("VALID" if ok else "INVALID")
    return "\n".join(answers) + "\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1\n2 29 2000\n") == "VALID\n"
assert oracle("1\n2 29 1900\n") == "INVALID\n"
assert oracle("1\n2 29 2100\n") == "INVALID\n"
assert oracle("1\n2 29 2400\n") == "VALID\n"
assert oracle("1\n13 1 2020\n") == "INVALID\n"
assert oracle("1\n12 31 2020\n") == "VALID\n"


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(
        "%d %d %d\n" % case for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    edge_cases = [
        (1, 1, 1), (12, 31, 9999), (2, 29, 2000), (2, 29, 1900),
        (2, 30, 2020), (0, 1, 2020), (13, 1, 2020), (1, 0, 2020),
        (1, 32, 2020), (4, 31, 2020), (2, -1, 2020), (-1, 1, 2020),
        (1, 1, 0), (2, 29, 0), (2, 29, -4), (1, 1, -100),
        (2, 29, 1600), (2, 29, 1700), (6, 31, 2021), (11, 31, 2002),
    ]
    write("2_edges", edge_cases)
    rng = random.Random(20180710)
    wide_cases = []
    for _ in range(1000):
        month_value = rng.randint(-2, 14)
        day_value = rng.randint(-5, 32)
        year_value = rng.randint(1, 9999)
        wide_cases.append((month_value, day_value, year_value))
    write("3_wide", wide_cases)
    random_cases = []
    for _ in range(1000):
        month_value = rng.randint(1, 12)
        day_value = rng.randint(1, 31)
        year_value = rng.randint(1, 9999)
        random_cases.append((month_value, day_value, year_value))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(1000):
        month_value = rng.randint(1, 12)
        day_value = rng.randint(1, 31)
        year_value = rng.randint(1, 9999)
        io_cases.append((month_value, day_value, year_value))
    write("5_io", io_cases)


def trace_example():
    lengths = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    for year_value in (2018, 2000):
        limit = lengths[2]
        if year_value % 400 == 0 or (year_value % 4 == 0 and year_value % 100 != 0):
            limit += 1
        print("february %d limit %d -> day 29 %s" % (
            year_value, limit, "VALID" if 29 <= limit else "INVALID"))


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
        raise SystemExit
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [(9, 8, 2018), (3, 39, 2000), (2, 29, 2018),
                       (20, -4, 1998), (2, 29, 2000), (7, 31, 1986),
                       (11, 31, 2002)])
    (ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
    (ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
    build()
