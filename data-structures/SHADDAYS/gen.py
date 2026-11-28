#!/usr/bin/env python3
import datetime
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """3
10-12-2020
12
29-02-2016
1010
03-12-2019
120
"""
SAMPLE_OUT = """22-12-2020
05-12-2018
01-04-2020
"""


def oracle(input_text):
    tokens = input_text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(count):
        day_text, month_text, year_text = tokens[cursor].split("-")
        cursor += 1
        start = datetime.date(int(year_text), int(month_text), int(day_text))
        extra_days = int(tokens[cursor])
        cursor += 1
        result = start + datetime.timedelta(days=extra_days)
        answers.append("%02d-%02d-%04d" % (result.day, result.month, result.year))
    return "\n".join(answers) + "\n"


def format_case(case):
    day_value, month_value, year_value, extra_days = case
    return "%02d-%02d-%04d\n%d\n" % (day_value, month_value, year_value, extra_days)


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(format_case(case) for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    case = (29, 2, 2016, 1010)
    start_day, start_month, start_year, extra_days = case
    start = datetime.date(start_year, start_month, start_day)
    result = start + datetime.timedelta(days=extra_days)
    print("start 29-02-2016")
    print("add 1010 days")
    print("result %02d-%02d-%04d" % (result.day, result.month, result.year))


SAMPLE = [(10, 12, 2020, 12), (29, 2, 2016, 1010), (3, 12, 2019, 120)]

assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1\n28-02-2020\n1\n") == "29-02-2020\n"
assert oracle("1\n28-02-1900\n1\n") == "01-03-1900\n"
assert oracle("1\n31-12-2019\n1\n") == "01-01-2020\n"


def build():
    write("2_edges", [
        (28, 2, 2020, 1), (29, 2, 2016, 1), (28, 2, 1900, 1),
        (31, 12, 1999, 1), (1, 1, 2000, 1), (30, 4, 2019, 1),
        (31, 1, 2020, 28), (15, 6, 2021, 365), (1, 3, 2020, 1),
    ])
    write("3_wide", [
        (1, 1, 1, 9999), (31, 12, 9970, 9999), (29, 2, 2000, 9999),
        (1, 1, 9990, 1), (28, 2, 2100, 1), (31, 12, 2020, 9999),
    ])
    rng = random.Random(5041)
    random_cases = []
    for _ in range(100):
        year_value = rng.randint(1900, 9970)
        month_value = rng.randint(1, 12)
        day_value = rng.randint(1, 28)
        random_cases.append((day_value, month_value, year_value, rng.randint(1, 9999)))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(100):
        year_value = rng.randint(1, 9970)
        month_value = rng.randint(1, 12)
        day_value = rng.randint(1, 28)
        io_cases.append((day_value, month_value, year_value, rng.randint(1, 9999)))
    write("5_io", io_cases)


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", SAMPLE)
        build()
