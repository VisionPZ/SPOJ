#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

from sympy.polys.matrices import DomainMatrix
from sympy.polys.domains import GF

ROOT = Path(__file__).resolve().parent
FIELD = GF(7)
DAYS = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]


def parse(text):
    tokens = text.split()
    cursor = 0
    cases = []
    while cursor < len(tokens):
        type_count = int(tokens[cursor]); cursor += 1
        record_count = int(tokens[cursor]); cursor += 1
        if type_count == 0 and record_count == 0:
            break
        records = []
        for _ in range(record_count):
            widget_count = int(tokens[cursor]); cursor += 1
            start_day = DAYS.index(tokens[cursor]); cursor += 1
            end_day = DAYS.index(tokens[cursor]); cursor += 1
            widgets = [int(value) for value in tokens[cursor:cursor + widget_count]]
            cursor += widget_count
            records.append((widgets, start_day, end_day))
        cases.append((type_count, records))
    return cases


def days_of(residue):
    return residue + 7 if residue <= 2 else residue


def rref_oracle(type_count, records):
    rows = []
    for widgets, start_day, end_day in records:
        row = [0] * type_count
        for widget in widgets:
            row[widget - 1] = (row[widget - 1] + 1) % 7
        row.append((end_day - start_day + 1) % 7)
        rows.append(row)
    if not rows:
        return "Multiple solutions."
    matrix = DomainMatrix([[FIELD(value) for value in row] for row in rows],
                          (len(rows), type_count + 1), FIELD)
    reduced, pivots = matrix.rref()
    table = reduced.to_list()
    for row in table:
        if all(int(value) == 0 for value in row[:type_count]) and int(row[-1]) != 0:
            return "Inconsistent data."
    if len(pivots) < type_count:
        return "Multiple solutions."
    return " ".join(str(days_of(int(table[index][-1]))) for index in range(type_count))


def brute_oracle(type_count, records):
    solutions = set()
    for candidate in itertools.product(range(7), repeat=type_count):
        good = True
        for widgets, start_day, end_day in records:
            total = 0
            for widget in widgets:
                total += candidate[widget - 1]
            if total % 7 != (end_day - start_day + 1) % 7:
                good = False
                break
        if good:
            solutions.add(candidate)
    if not solutions:
        return "Inconsistent data."
    if len(solutions) > 1:
        return "Multiple solutions."
    return " ".join(str(days_of(value)) for value in next(iter(solutions)))


def oracle(text):
    return "\n".join(rref_oracle(type_count, records)
                     for type_count, records in parse(text)) + "\n"


SAMPLE = """2 3
2 MON THU
1 2
3 MON FRI
1 1 2
3 MON SUN
1 2 2
10 2
1 MON TUE 
3
1 MON WED
3
0 0
"""
SAMPLE_OUT = """8 3
Inconsistent data.
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute_oracle(2, parse(SAMPLE)[0][1]) == "8 3"
assert rref_oracle(3, [([1], 0, 2), ([2], 0, 3), ([3], 0, 4)]) == "3 4 5"
assert rref_oracle(2, [([1, 2], 0, 3), ([1], 0, 6)]) == "7 4"
assert rref_oracle(2, [([1], 0, 2)]) == "Multiple solutions."
assert rref_oracle(2, [([1], 0, 1), ([1], 0, 1), ([1], 0, 2)]) == "Inconsistent data."
assert days_of(0) == 7 and days_of(2) == 9 and days_of(3) == 3


def write(name, cases):
    lines = []
    for type_count, records in cases:
        lines.append(f"{type_count} {len(records)}")
        for widgets, start_day, end_day in records:
            lines.append(f"{len(widgets)} {DAYS[start_day]} {DAYS[end_day]}")
            lines.append(" ".join(str(value) for value in widgets))
    lines.append("0 0")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (1, [([1], 0, 2)]),
        (3, [([1], 0, 2), ([2], 0, 3), ([3], 0, 4)]),
        (2, [([1, 2], 0, 3)]),
        (2, [([1], 0, 1), ([1], 0, 2)]),
        (7, [([index + 1], 0, (index % 7 - 1) % 7) for index in range(7)]),
    ])
    wide = [(300, [([index + 1], 0, (index % 7 - 1) % 7) for index in range(300)])]
    write("3_wide", wide)
    rng = random.Random(20261125)
    random_cases = []
    for type_count in (2, 4, 6, 8):
        records = []
        for _ in range(type_count + 2):
            count = rng.randint(1, 4)
            widgets = [rng.randint(1, type_count) for _ in range(count)]
            start_day = rng.randrange(7)
            end_day = rng.randrange(7)
            records.append((widgets, start_day, end_day))
        random_cases.append((type_count, records))
        if type_count <= 4:
            assert rref_oracle(type_count, records) == brute_oracle(type_count, records)
    write("4_random", random_cases)
    io_cases = []
    for _ in range(8):
        io_cases.append((300, [([index + 1], 0, (index % 7 - 1) % 7)
                               for index in range(300)]))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
