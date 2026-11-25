#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = "      Lap trinh can ban C\n"
SAMPLE_OUT = "Lap trinh can ban C\n"


def oracle(text):
    return text.split("\n")[0].lstrip(" \t\r") + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("      Information Technology\n") == "Information Technology\n"
assert oracle("\t\tX\n") == "X\n"
assert oracle("     \n") == "\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "   X\n")
    write("3_wide", "\t   Cong nghe thong tin\n")
    rng = random.Random(20261134)
    lead = " " * rng.randint(1, 12)
    words = ["Lap", "trinh", "can", "ban", "C."]
    write("4_random", lead + " ".join(rng.choice(words) for _ in range(20)) + "\n")
    io_line = " " * 40 + "Lap trinh can ban C. " * 10000
    write("5_io", io_line + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
