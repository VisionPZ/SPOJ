#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    count = int(tokens[0])
    results = []
    for case in range(count):
        current = tokens[1 + case]
        while "100" in current:
            current = current.replace("100", "")
        results.append(f"Case {case + 1}: {'yes' if current == '' else 'no'}")
    return "\n".join(results) + "\n"


def brute_check(binary_text):
    current = binary_text
    changed = True
    while changed:
        changed = False
        for position in range(len(current) - 2):
            if current[position:position + 3] == "100":
                current = current[:position] + current[position + 3:]
                changed = True
                break
    return current == ""


SAMPLE = """2
101000
1010001
"""
SAMPLE_OUT = """Case 1: yes
Case 2: no
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n100\n") == "Case 1: yes\n"
assert oracle("1\n0011\n") == "Case 1: no\n"
assert oracle("1\n110000\n") == "Case 1: yes\n"
assert oracle("2\n100100\n10010\n") == "Case 1: yes\nCase 2: no\n"
for trial in ("101000", "1010001", "1100100", "000111", "1" * 6 + "0" * 12):
    assert brute_check(trial) == (oracle("1\n" + trial + "\n") == "Case 1: yes\n")


def write(name, strings):
    text = str(len(strings)) + "\n" + "\n".join(strings) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", ["1", "0", "10", "100", "1000", "101000", "1010001", "0011", "110000"])
    write("3_wide", ["100" * 4000, "100" * 4000 + "1", "1" * 2000 + "0" * 4000,
                     "0" + "100" * 3999, "100" * 2000 + "0" + "100" * 1999])
    rng = random.Random(20261126)
    random_strings = ["".join(rng.choice("01") for _ in range(rng.randint(1, 240))) for _ in range(60)]
    write("4_random", random_strings)
    io_strings = []
    for index in range(100):
        block_count = 1000 + index * 20
        io_strings.append("100" * block_count + ("1" if index % 7 == 0 else ""))
    write("5_io", io_strings)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
