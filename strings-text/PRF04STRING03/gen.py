#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = "Lap trinh can ban C             \n"
SAMPLE_OUT = "Lap trinh can ban C\n"


def oracle(text):
    return text.split("\n")[0].rstrip(" \t\r") + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("Information Technology          \n") == "Information Technology\n"
assert oracle("X\t\t\n") == "X\n"
assert oracle("     \n") == "\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "X   \n")
    write("3_wide", "Cong nghe thong tin   \t\n")
    rng = random.Random(20261135)
    tail = " " * rng.randint(1, 12)
    words = ["Lap", "trinh", "can", "ban", "C."]
    write("4_random", " ".join(rng.choice(words) for _ in range(20)) + tail + "\n")
    io_line = "Lap trinh can ban C. " * 10000 + " " * 40
    write("5_io", io_line + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
