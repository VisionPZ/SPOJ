#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = "Lap trinh can ban C.\n"
SAMPLE_OUT = "Lap trinh can ban C.\n"


def oracle(text):
    return text.split("\n")[0] + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("Cong nghe thong tin.\n") == "Cong nghe thong tin.\n"
assert oracle("Infomation Technology.\n") == "Infomation Technology.\n"
assert oracle("A  B\n") == "A  B\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "X\n")
    write("3_wide", "Cong nghe thong tin.\n")
    rng = random.Random(20261133)
    words = ["Lap", "trinh", "can", "ban", "C.", "Technology"]
    line = " ".join(rng.choice(words) for _ in range(40))
    write("4_random", line + "\n")
    io_line = "Lap trinh can ban C. " * 10000
    write("5_io", io_line + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
