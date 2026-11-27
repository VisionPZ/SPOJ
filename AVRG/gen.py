#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "3\n7\n5\n2\n1\n6\n"
SAMPLE_OUTPUT = "4.0\n"


def oracle(text):
    values = [int(token) for token in text.split()[:6]]
    assert len(values) == 6
    return f"{sum(values) / 6.0}\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("2\n2\n2\n2\n2\n2\n") == "2.0\n"
assert oracle("1\n1\n1\n1\n1\n7\n") == "2.0\n"
assert oracle("1000000\n1000000\n1000000\n1000000\n1000000\n1000000\n") == "1000000.0\n"


def write(name, costs):
    assert len(costs) == 6
    input_text = "".join(f"{cost}\n" for cost in costs)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [3, 7, 5, 2, 1, 6])
write("2_edges", [0, 0, 0, 0, 0, 6])
write("3_wide", [999999999] * 6)
rng = random.Random(2026)
base = [rng.randint(1, 100000) for _ in range(5)]
last = (sum(base) * 5) % 6
write("4_random", base + [last if last >= 0 else last + 6])
write("5_io", [999999999] * 6)
