#!/usr/bin/env python3
import math
import os
import sys

try:
    sys.set_int_max_str_digits(10000000)
except AttributeError:
    pass

def oracle(data_bytes):
    text = data_bytes.decode("latin-1").strip()
    if not text:
        return "1\n"
    value = int(text.split()[0])
    return str(math.factorial(value)) + "\n"

assert oracle(b"4\n") == "24\n"
assert oracle(b"0\n") == "1\n"
assert oracle(b"1\n") == "1\n"
assert oracle(b"10\n") == "3628800\n"
assert oracle(b"20\n") == "2432902008176640000\n"

os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)

def emit(name, text_in):
    text_out = oracle(text_in.encode("latin-1"))
    with open("in/" + name + ".txt", "wb") as f:
        f.write(text_in.encode("latin-1"))
    with open("out/" + name + ".out", "wb") as f:
        f.write(text_out.encode("latin-1"))

emit("1_sample", "4\n")
emit("2_edges", "0\n")
emit("3_wide", "100\n")
emit("4_random", "57\n")
emit("5_io", "10000\n")

print("gen ok")
