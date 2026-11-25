#!/usr/bin/env python3
import os

def oracle(data_bytes):
    text = data_bytes.decode("latin-1").strip()
    if not text:
        return "0\n"
    numberList = eval(text)
    total = 0
    for value in numberList:
        if value == 0:
            break
        total += value
    return str(total) + "\n"

assert oracle(b"[3,6,7,2,0,4,0,45,32,0]") == "18\n"
assert oracle(b"[]") == "0\n"
assert oracle(b"[1,2,3]") == "6\n"
assert oracle(b"[0,5]") == "0\n"
assert oracle(b"[-3,4,0]") == "1\n"

os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)

def emit(name, text_in):
    text_out = oracle(text_in.encode("latin-1"))
    with open("in/" + name + ".txt", "wb") as f:
        f.write(text_in.encode("latin-1"))
    with open("out/" + name + ".out", "wb") as f:
        f.write(text_out.encode("latin-1"))

emit("1_sample", "[3,6,7,2,0,4,0,45,32,0]\n")
emit("2_edges", "[]\n")
emit("3_wide", "[" + ",".join(str(i % 97 + 1) for i in range(100000)) + "]\n")
emit("4_random", "[" + ",".join(str(v) for v in ([3] * 50 + [0] + [7] * 50)) + "]\n")
big = "[" + ",".join(str(i % 100 + 1) for i in range(1000000)) + ",0," + ",".join(str(i) for i in range(1000)) + "]\n"
emit("5_io", big)

print("gen ok")
