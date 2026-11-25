#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parent
NAMES = ["1_sample", "2_edges", "3_wide", "4_random", "5_io"]


def oracle(text):
    assert text == ""
    return ""


assert oracle("") == ""

for name in NAMES:
    input_text = ""
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))
