#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    count = int(text.split()[0])
    return "W" + "o" * count + "w\n"


def write(name, input_text):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle("1\n") == "Wow\n"
assert oracle("7\n") == "Wooooooow\n"
assert oracle("49\n") == "W" + "o" * 49 + "w\n"

write("1_sample", "1\n")
write("2_edges", "7\n")
write("3_wide", "49\n")
random.seed(2026)
write("4_random", f"{random.randint(1, 49)}\n")
write("5_io", "\n" * 50000 + "  49  \n")
