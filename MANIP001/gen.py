#!/usr/bin/env python3
import random
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent

RECORD = re.compile(
    r"TYPE 1:\s*(\d+)\s*,\s*TYPE 2:\s*(\d*)\s*,\s*TYPE 3:\s*(\d*)\s*,\s*TYPE details:\s*(.*?)\s*$")


def oracle(text):
    lines = text.splitlines()
    case_count = int(lines[0])
    answers = []
    for raw in lines[1:1 + case_count]:
        match = RECORD.search(raw)
        first, second, third, detail = match.groups()
        second_out = second if second else "NULL"
        third_out = third if third else "NULL"
        answers.append(f"({int(first)},{second_out},{third_out},'{detail}')")
    return "\n".join(answers) + "\n"


def record(first, second, third, detail):
    return (f"TYPE 1: {first}, TYPE 2: {second}, TYPE 3: {third}, "
            f"TYPE details: {detail}")


def make_text(records):
    return str(len(records)) + "\n" + "\n".join(records) + "\n"


SAMPLE = make_text([
    record(2, 0, "", "n/a"),
    record(2, 1, 0, "nothing"),
    record(0, "", "", "nice"),
])
SAMPLE_OUT = """(2,0,NULL,'n/a')
(2,1,0,'nothing')
(0,NULL,NULL,'nice')
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle(make_text([record(0, "", "", "x")])) == "(0,NULL,NULL,'x')\n"
assert oracle(make_text([record(100, 100, 100, "y")])) == "(100,100,100,'y')\n"
assert oracle(make_text([record(1, "", "", "z")])) == "(1,NULL,NULL,'z')\n"


def write(name, records):
    text = make_text(records)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        record(0, "", "", "empty"),
        record(1, "", "", "one"),
        record(50, 0, "", "zero"),
        record(100, 100, 100, "full"),
    ])
    write("3_wide", [
        record(100, 100, 100, "w" * 20),
        record(99, 98, 97, "x" * 20),
    ])
    rng = random.Random(20261126)
    random_records = []
    for _ in range(12):
        first = rng.randint(0, 100)
        second = "" if first == 0 else rng.randint(0, 100)
        third = "" if second in (0, "") else rng.randint(0, 100)
        detail = "".join(rng.choice("abcdefghijklmnopqrstuvwxyz/-") for _ in range(rng.randint(1, 20)))
        random_records.append(record(first, second, third, detail))
    write("4_random", random_records)
    write("5_io", [record(rng.randint(0, 100), rng.randint(0, 100),
                          rng.randint(0, 100), "d" * 20) for _ in range(20)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    record(2, 0, "", "n/a"),
    record(2, 1, 0, "nothing"),
    record(0, "", "", "nice"),
])
build()
