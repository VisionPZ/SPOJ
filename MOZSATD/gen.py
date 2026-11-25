#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    amount_count = tokens[0]
    amounts = tokens[1:1 + amount_count]
    best_share = 0
    for mask in range(1 << amount_count):
        kept_total = 0
        for index in range(amount_count):
            if mask & (1 << index):
                kept_total += amounts[index]
        if kept_total % 2 == 0:
            share = kept_total // 2
            if share > best_share:
                best_share = share
    return str(best_share) + "\n"


SAMPLE = """3
8 2 5
"""
SAMPLE_OUT = """5
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n5\n") == "0\n"
assert oracle("2\n4 6\n") == "5\n"
assert oracle("3\n3 5 7\n") == "6\n"
assert oracle("4\n1000000000 1000000000 1000000000 1000000000\n") == "2000000000\n"


def write(name, amounts):
    text = str(len(amounts)) + "\n" + " ".join(str(value) for value in amounts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 3, 7])
    write("3_wide", [1000000000] * 16)
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 1000000000) for _ in range(16)])
    write("5_io", [1000000000 if index % 2 == 0 else 999999999 for index in range(16)])
    large = [rng.randint(1, 1000000000) for _ in range(100000)]
    (Path("/tmp") / "MOZSATD_big.txt").write_text(
        str(len(large)) + "\n" + " ".join(str(value) for value in large) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [8, 2, 5])
build()
