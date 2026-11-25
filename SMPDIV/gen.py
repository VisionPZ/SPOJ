#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(cases):
    lines = []
    for limit_value, divisor, excluded_divisor in cases:
        wanted = [str(value) for value in range(2, limit_value)
                  if value % divisor == 0 and value % excluded_divisor != 0]
        lines.append(" ".join(wanted))
    return "\n".join(lines) + "\n"


def write(name, cases):
    lines = [str(len(cases))]
    lines.extend(" ".join(str(value) for value in case) for case in cases)
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(cases))


SAMPLE = [(7, 2, 4), (35, 5, 12)]
assert oracle(SAMPLE) == "2 6\n5 10 15 20 25 30\n"
assert oracle([(2, 1, 3)]) == "\n"
assert oracle([(3, 2, 3)]) == "2\n"
assert oracle([(4, 1, 2)]) == "3\n"
assert oracle([(10, 3, 4)]) == "3 6 9\n"

write("1_sample", SAMPLE)
write("2_edges", [(2, 1, 3), (3, 2, 3), (4, 1, 2), (5, 2, 4),
                  (10, 3, 4), (10, 3, 100000), (99999, 99998, 3)])
write("3_wide", [(99999, 1, 2), (99999, 1, 3), (99999, 2, 3),
                 (99999, 1, 99999)])
random.seed(2026)
rnd = []
while len(rnd) < 99:
    limit_value = random.randint(2, 99999)
    divisor = random.randint(1, limit_value - 1)
    excluded = random.randint(1, 100000)
    if divisor % excluded != 0:
        rnd.append((limit_value, divisor, excluded))
write("4_random", rnd)
write("5_io", [(99999, 1, 99999) for _ in range(12)])
