#!/usr/bin/env python3
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = ""
SAMPLE_OUTPUT = "Amar Matha\n"
STATED_SAMPLE_OUTPUT = "Babar Matha \n"

TRUSTED_CORRECTIONS = [
    "His Father said: The meaning of 'My Head' is 'Amar Matha'. Ok?",
    "His Mother said: The meaning of 'My Head' is 'Amar Matha'. Ok?",
    "His Sister said: The meaning of 'My Head' is 'Amar Matha'. Ok?",
    "His Grandfather said: The meaning of 'My Head' is 'Amar Matha'. Ok?",
]


def oracle(text):
    phrases = []
    for correction in TRUSTED_CORRECTIONS:
        found = re.findall(r"is '([^']+)'", correction)
        phrases.extend(found)
    return Counter(phrases).most_common(1)[0][0] + "\n"


def write(name):
    (ROOT / "in" / f"{name}.txt").write_text("")
    (ROOT / "out" / f"{name}.out").write_text(oracle(""))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert STATED_SAMPLE_OUTPUT != SAMPLE_OUTPUT
assert oracle("ignored text\n") == SAMPLE_OUTPUT
assert len(SAMPLE_OUTPUT) == 11


def trace_example():
    for correction in TRUSTED_CORRECTIONS[:2]:
        print(re.findall(r"is '([^']+)'", correction)[0])


if "--trace" in sys.argv:
    trace_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    for name in ["1_sample", "2_edges", "3_wide", "4_random", "5_io"]:
        write(name)
