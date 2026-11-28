#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 10**9 + 7


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    lines = []
    for _ in range(case_count):
        step_count = tokens[cursor]
        part_count = tokens[cursor + 1]
        cursor += 2
        total = 0
        for choice in itertools.product(range(part_count), repeat=step_count):
            used = [0] * part_count
            valid = True
            for picked in choice:
                used[picked] += 1
                if max(used) - min(used) > 2:
                    valid = False
                    break
            if valid:
                total = (total + 1) % MOD
        lines.append(str(total))
    return "\n".join(lines) + "\n"


SAMPLE = """3
1 1
2 2
3 2
"""
SAMPLE_OUT = """1
4
6
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2\n5 1\n4 3\n") == "1\n54\n"
assert oracle("1\n3 3\n") == "24\n"
assert oracle("1\n2 5\n") == "25\n"
assert oracle("1\n6 2\n") == "36\n"


def write(name, cases):
    lines = [str(len(cases))]
    lines.extend(f"{steps} {parts}" for steps, parts in cases)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1), (5, 1), (2, 5), (3, 5), (0, 3)])
    write("3_wide", [(8, 3), (9, 2), (7, 3), (6, 2)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(1, 9), rng.randint(1, 3)) for _ in range(8)])
    write("5_io", [(rng.randint(1, 9), rng.randint(1, 4)) for _ in range(20)])

    big_lines = ["20"]
    rng = random.Random(20261127)
    for _ in range(20):
        big_lines.append(f"{rng.randint(10**17, 10**18)} {rng.randint(1, 50)}")
    Path("/tmp/MACHMAY_big.txt").write_text("\n".join(big_lines) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(1, 1), (2, 2), (3, 2)])
build()
