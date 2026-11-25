#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    words = text.split()
    return " ".join(words) + "\n"


SAMPLE = "      Lap trinh         can ban C             \n"
SAMPLE_OUT = "Lap trinh can ban C\n"

assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("  a  b   c \n") == "a b c\n"
assert oracle("\tX\t\tY\t") == "X Y\n"
assert oracle("single") == "single\n"
assert oracle("   \t  \n \t \n") == "\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "   \t  \n \t \n")
    write("3_wide", "alpha" + " " * 5000 + "beta\n")
    rng = random.Random(20261126)
    words = ["Lap", "trinh", "can", "ban", "C", "Information",
             "Technology", "Cong", "nghe", "thong", "tin"]
    separators = [" ", "  ", "     ", "\t", " \t "]
    pieces = [rng.choice(words) for _ in range(120)]
    random_text = " ".join(
        piece + rng.choice(separators) for piece in pieces) + "\n"
    write("4_random", random_text)
    big_pieces = []
    for index in range(25000):
        big_pieces.append("word" + str(index % 100))
        big_pieces.append(rng.choice(separators))
    write("5_io", "  " + "".join(big_pieces) + "   \n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
