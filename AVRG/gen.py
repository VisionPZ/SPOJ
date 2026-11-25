#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "3\n7\n5\n2\n1\n6\n"
SAMPLE_OUTPUT = "4\n"


def oracle(text):
    values = [int(token) for token in text.split()][:6]
    assert len(values) == 6
    mean = sum(values) / 6.0
    assert mean == int(mean)
    return str(int(mean)) + "\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("2\n2\n2\n2\n2\n2\n") == "2\n"
assert oracle("1\n1\n1\n1\n1\n7\n") == "2\n"
assert oracle("10\n10\n10\n10\n10\n10\n") == "10\n"
assert oracle("1000000\n1000000\n1000000\n1000000\n1000000\n1000000\n") == "1000000\n"


def write(name, costs):
    assert len(costs) == 6
    input_text = "".join(f"{cost}\n" for cost in costs)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


write("1_sample", [3, 7, 5, 2, 1, 6])
write("2_edges", [1, 1, 1, 1, 1, 7])
write("3_wide", [999999999, 999999999, 999999999,
                 999999999, 999999999, 999999999])
random.seed(2026)
base = [random.randint(1, 100000) for _ in range(5)]
last = (sum(base) * 5) % 6
write("4_random", base + [last if last >= 0 else last + 6])
write("5_io", [999999999] * 6)
