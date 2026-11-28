#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    lines = text.split("\n")
    count = int(lines[0])
    results = []
    cursor = 1
    for _ in range(count):
        employee_id = lines[cursor]
        name = lines[cursor + 1]
        gender = lines[cursor + 2]
        salary = int(lines[cursor + 3])
        results.append(f"{employee_id} : {name} : {gender} : {salary}")
        cursor += 4
    return "\n".join(results) + "\n" if results else ""


SAMPLE = (
    "3\n"
    "NV01\nTran Thanh Hung\nF\n1500\n"
    "NV02\nNguyen Ngoc Bich\nM\n2000\n"
    "NV03\nTran Trung Hau\nF\n1700\n"
)
SAMPLE_OUT = (
    "NV01 : Tran Thanh Hung : F : 1500\n"
    "NV02 : Nguyen Ngoc Bich : M : 2000\n"
    "NV03 : Tran Trung Hau : F : 1700\n"
)

assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\nA\nB\nM\n0\n") == "A : B : M : 0\n"
assert oracle("2\nX\nY\nF\n10\nZ\nW\nM\n20\n") == \
    "X : Y : F : 10\nZ : W : M : 20\n"


def write(name, employees):
    lines = [str(len(employees))]
    for employee_id, employee_name, gender, salary in employees:
        lines.extend([employee_id, employee_name, gender, str(salary)])
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [("A", "B", "M", 0)])
    write("3_wide", [("NV" + "9" * 200, "Tran " * 60, "F", 2147483647)])
    rng = random.Random(20261126)
    first = ["Tran", "Nguyen", "Le", "Pham", "Bui"]
    last = ["Thanh Hung", "Ngoc Bich", "Trung Hau", "Van Anh", "Minh Tri"]
    for name, count in (("4_random", 17), ("5_io", 4000)):
        employees = []
        for index in range(count):
            employee_id = "NV" + f"{index:05d}"
            employee_name = rng.choice(first) + " " + rng.choice(last)
            gender = rng.choice(["M", "F"])
            salary = rng.randint(0, 10 ** 6)
            employees.append((employee_id, employee_name, gender, salary))
        write(name, employees)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
