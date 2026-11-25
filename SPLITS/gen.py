#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    array_size = int(tokens[cursor]); cursor += 1
    operation_count = int(tokens[cursor]); cursor += 1
    initial = tokens[cursor]; cursor += 1
    values = [initial] * array_size
    answers = []
    for _ in range(operation_count):
        command = tokens[cursor]; cursor += 1
        position = int(tokens[cursor]); cursor += 1
        index = position - 1
        if command == "SPLIT":
            left_string = tokens[cursor]; cursor += 1
            right_string = tokens[cursor]; cursor += 1
            original = values[index]
            scan = index
            while scan > 0 and values[scan - 1] == original:
                scan -= 1
            while scan < index:
                values[scan] = left_string
                scan += 1
            scan = index
            while scan + 1 < array_size and values[scan + 1] == original:
                scan += 1
                values[scan] = right_string
        else:
            answers.append(values[index])
    return "\n".join(answers) + "\n" if answers else ""


SAMPLE = """6 6
picsel
SPLIT 3 petarv duxserbia
SPLIT 5 sasav nikolaj
QUERY 1
QUERY 3
QUERY 5
QUERY 6
"""
SAMPLE_OUT = """petarv
picsel
duxserbia
nikolaj
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 2\nstart\nSPLIT 1 left right\nQUERY 1\n") == "start\n"
assert oracle("2 3\nstart\nSPLIT 1 left right\nQUERY 1\nQUERY 2\n") == "start\nright\n"
assert oracle("3 4\nstart\nSPLIT 2 left right\nQUERY 1\nQUERY 2\nQUERY 3\n") == (
    "left\nstart\nright\n")


def unique_string(serial, length):
    letters = []
    for _ in range(length):
        letters.append("abcdefghijklmnopqrstuvwxyz"[serial % 26])
        serial //= 26
    return "".join(letters)


def write(name, array_size, operations, initial="picsel"):
    lines = ["%d %d" % (array_size, len(operations)), initial]
    for operation in operations:
        if operation[0] == "SPLIT":
            lines.append("SPLIT %d %s %s" % (operation[1], operation[2], operation[3]))
        else:
            lines.append("QUERY %d" % operation[1])
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def make_operations(rng, array_size, operation_count, string_length, serial_start):
    operations = []
    serial = serial_start
    for step in range(operation_count):
        if rng.random() < 0.4 and step < operation_count - 1:
            operations.append(("SPLIT", rng.randint(1, array_size),
                               unique_string(serial, string_length),
                               unique_string(serial + 1000000, string_length)))
            serial += 1
        else:
            operations.append(("QUERY", rng.randint(1, array_size)))
    return operations


def build():
    write("2_edges", 1, [
        ("SPLIT", 1, "lefta", "righta"),
        ("QUERY", 1),
        ("SPLIT", 1, "leftb", "rightb"),
        ("QUERY", 1),
    ])
    rng = random.Random(20261126)
    write("3_wide", 1000, make_operations(rng, 1000, 1000, 50, 0))
    write("4_random", 200, make_operations(rng, 200, 200, 12, 10000))
    write("5_io", 3000, make_operations(rng, 3000, 3000, 50, 20000))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 6, [
    ("SPLIT", 3, "petarv", "duxserbia"),
    ("SPLIT", 5, "sasav", "nikolaj"),
    ("QUERY", 1),
    ("QUERY", 3),
    ("QUERY", 5),
    ("QUERY", 6),
])
build()
