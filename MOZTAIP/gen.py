#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parent

REQUIRED_LINE = "Competitive\\tprogramming\\n"


def oracle(text):
    return REQUIRED_LINE


SAMPLE = ""
SAMPLE_OUT = "Competitive\\tprogramming\\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("no input\n") == SAMPLE_OUT
assert len(SAMPLE_OUT) == 26
assert "\\t" in SAMPLE_OUT and "\\n" in SAMPLE_OUT
assert "\t" not in SAMPLE_OUT and "\n" not in SAMPLE_OUT


def build():
    for name in ("2_edges", "3_wide", "4_random", "5_io"):
        (ROOT / "in" / f"{name}.txt").write_text("")
        (ROOT / "out" / f"{name}.out").write_text(oracle(""))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
