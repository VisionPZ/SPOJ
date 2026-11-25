#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    fields = [line for line in text.splitlines() if line.strip()]
    employee_id = fields[0]
    employee_name = fields[1]
    employee_gender = fields[2]
    employee_salary = int(fields[3])
    return f"{employee_id} : {employee_name} : {employee_gender} : {employee_salary}\n"


SAMPLE = """NV02
Tran Thanh Hung
M
1500
"""
SAMPLE_OUT = """NV02 : Tran Thanh Hung : M : 1500
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("A\nB C\nF\n0\n") == "A : B C : F : 0\n"
assert oracle("X\nY Z W\nM\n1000000000\n") == "X : Y Z W : M : 1000000000\n"
assert oracle("Q\nName Here\nF\n42\n") == "Q : Name Here : F : 42\n"


def write(name, employee_id, employee_name, employee_gender, employee_salary):
    text = f"{employee_id}\n{employee_name}\n{employee_gender}\n{employee_salary}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "A1", "Single", "F", 0)
    write("3_wide", "ID1000000000", "A" * 500 + " " + "B" * 500, "M", 2000000000)
    rng = random.Random(20261126)
    name_parts = ["".join(rng.choice("abcdefghijklmnopqrstuvwxyz") for _ in range(rng.randint(1, 12)))
                  for _ in range(rng.randint(1, 6))]
    write("4_random", "R" + str(rng.randint(0, 999)),
          " ".join(name_parts), rng.choice(["M", "F"]), rng.randint(0, 100000))
    write("5_io", "LONGID", "N" * 2000, "M", 999999999)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", "NV02", "Tran Thanh Hung", "M", 1500)
build()
