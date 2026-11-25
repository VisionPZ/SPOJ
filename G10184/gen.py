#!/usr/bin/env python3
import os
import random
from fractions import Fraction

def formatFraction(value):
    if value.denominator == 1:
        return str(value.numerator)
    cents = int(value * 100 + Fraction(1, 2))
    if cents % 100 == 0:
        return str(cents // 100)
    return "%d.%02d" % (cents // 100, cents % 100)

def oracle(data_bytes):
    tokens = data_bytes.decode("latin-1").split()
    blocks = []
    idx = 0
    while idx + 2 < len(tokens):
        dinerCount = int(tokens[idx])
        ricePrice = int(tokens[idx + 1])
        chickenPrice = int(tokens[idx + 2])
        idx += 3
        if dinerCount == 0 and ricePrice == 0 and chickenPrice == 0:
            break
        riceAmount = Fraction(dinerCount, 8)
        chickenAmount = Fraction(dinerCount, 16)
        totalCost = riceAmount * ricePrice + chickenAmount * chickenPrice
        blocks.append(formatFraction(riceAmount) + " " + formatFraction(chickenAmount) + " " + formatFraction(totalCost))
    return "\n".join(blocks) + ("\n" if blocks else "")

sample_in = "12 1200 6000\n200 1000 4000\n60 1500 5000\n0 0 0\n"
sample_out = "1.50 0.75 6300\n25 12.50 75000\n7.50 3.75 30000\n"
assert oracle(sample_in.encode("latin-1")) == sample_out
assert oracle(b"4 8 16\n0 0 0\n") == "0.50 0.25 8\n"
assert oracle(b"1 100 100\n0 0 0\n") == "0.13 0.06 18.75\n"

os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)

def emit(name, text_in):
    text_out = oracle(text_in.encode("latin-1"))
    with open("in/" + name + ".txt", "wb") as f:
        f.write(text_in.encode("latin-1"))
    with open("out/" + name + ".out", "wb") as f:
        f.write(text_out.encode("latin-1"))

emit("1_sample", sample_in)
emit("2_edges", "4 8 16\n1 100 100\n8 0 0\n0 0 0\n")

rng = random.Random(123)
def random_case():
    diners = 4 * rng.randint(1, 25000)
    ricePrice = rng.randint(1, 10000)
    chickenPrice = rng.randint(1, 10000)
    return "%d %d %d\n" % (diners, ricePrice, chickenPrice)

wide_text = "".join(random_case() for _ in range(10000)) + "0 0 0\n"
emit("3_wide", wide_text)
emit("4_random", "".join(random_case() for _ in range(1000)) + "0 0 0\n")
io_text = "".join(random_case() for _ in range(200000)) + "0 0 0\n"
emit("5_io", io_text)

print("gen ok")
