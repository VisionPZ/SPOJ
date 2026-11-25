#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    kept = []
    for line in text.splitlines():
        kept.append(line)
        if line.strip() == "42":
            break
    return "\n".join(kept) + "\n"


def write(name, numbers):
    input_text = "".join(f"{number}\n" for number in numbers)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE = [3, 15, 42]
assert oracle("3\n15\n42\n") == "3\n15\n42\n"
assert oracle("42\n7\n8\n") == "42\n"

write("1_sample", SAMPLE)
write("2_edges", [42])
write("3_wide", list(range(0, 100)) + [42])
random.seed(2026)
write("4_random", [random.randint(0, 99) for _ in range(200)] + [42])
write("5_io", [random.randint(0, 99) for _ in range(20000)] + [42])
