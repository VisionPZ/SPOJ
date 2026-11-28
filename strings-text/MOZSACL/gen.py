#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def smallest_divisor(value):
    divisor = 2
    while divisor * divisor <= value:
        if value % divisor == 0:
            return divisor
        divisor += 1
    return value


def oracle(text):
    lines = text.split("\n")
    length = len(lines[0].strip())
    query_count = int(lines[1])
    cells = ["#"] * (length + 1)
    answers = []
    position = 2
    for _ in range(query_count):
        parts = lines[position].split()
        position += 1
        if parts[0] == "Update":
            divisor = smallest_divisor(int(parts[1]))
            letter = parts[2]
            power = divisor
            while power <= length:
                cells[power] = letter
                power *= divisor
        else:
            left = int(parts[1])
            right = int(parts[2])
            letter = parts[3]
            answers.append(str(sum(1 for index in range(left, right + 1)
                                   if cells[index] == letter)))
    return "\n".join(answers) + "\n" if answers else ""


SAMPLE = """##########
4
Query 1 5 a
Update 2 a
Query 1 5 a
Query 8 8 a
"""
SAMPLE_OUT = """0
2
1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("#\n2\nQuery 1 1 a\nUpdate 2 a\n") == "0\n"
assert smallest_divisor(4) == 2
assert smallest_divisor(9) == 3
assert smallest_divisor(97) == 97
assert smallest_divisor(10000000) == 2
assert oracle("######\n4\nUpdate 4 z\nQuery 1 6 z\nUpdate 9 b\nQuery 3 3 z\n") == "2\n0\n"


def write(name, length, queries):
    lines = ["#" * length, str(len(queries))] + queries
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, ["Query 1 1 a", "Update 2 a", "Query 1 1 a", "Update 4 b",
                         "Query 1 1 b"])
    rng = random.Random(20261126)
    wide = []
    for _ in range(60):
        if rng.random() < 0.5:
            wide.append("Update {} {}".format(rng.choice([2, 3, 4, 97, 10000000]),
                                              rng.choice("abcdefghijklmnopqrstuvwxyz")))
        else:
            left = rng.randint(1, 900)
            right = rng.randint(left, 1000)
            wide.append("Query {} {} {}".format(left, right,
                                                rng.choice("abcdefghijklmnopqrstuvwxyz")))
    write("3_wide", 1000, wide)
    random_queries = []
    for _ in range(500):
        if rng.random() < 0.4:
            random_queries.append("Update {} {}".format(rng.randint(2, 100000),
                                                        rng.choice("abcdefghijklmnopqrstuvwxyz")))
        else:
            left = rng.randint(1, 400)
            right = rng.randint(left, 500)
            random_queries.append("Query {} {} {}".format(left, right,
                                                          rng.choice("abcdefghijklmnopqrstuvwxyz")))
    write("4_random", 500, random_queries)
    io_queries = []
    for index in range(2000):
        if index % 10 == 0:
            io_queries.append("Update {} {}".format(rng.randint(2, 10000000),
                                                     rng.choice("abcdefghijklmnopqrstuvwxyz")))
        else:
            io_queries.append("Query 1 1000 {}".format(rng.choice("abcdefghijklmnopqrstuvwxyz")))
    write("5_io", 1000, io_queries)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
