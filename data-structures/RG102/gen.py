#!/usr/bin/env python3
import random
import os

def oracle(data_bytes):
    lines = data_bytes.decode("latin-1").splitlines()
    answers = []
    for line in lines:
        line = line.strip()
        if not line:
            continue
        hourText, minuteText = line.split(":")
        minutesSoFar = int(hourText) * 60 + int(minuteText)
        if minutesSoFar == 0:
            break
        answers.append(str(1440 - minutesSoFar))
    return "\n".join(answers) + ("\n" if answers else "")

assert oracle(b"23:45\n21:30\n00:01\n00:00\n") == "15\n150\n1439\n"
assert oracle(b"23:59\n00:00\n") == "1\n"
assert oracle(b"00:00\n") == ""
assert oracle(b"12:00\n00:00\n") == "720\n"

os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)

def emit(name, text_in):
    text_out = oracle(text_in.encode("latin-1"))
    with open("in/" + name + ".txt", "wb") as f:
        f.write(text_in.encode("latin-1"))
    with open("out/" + name + ".out", "wb") as f:
        f.write(text_out.encode("latin-1"))

def fmt(hh, mm):
    return "%02d:%02d" % (hh, mm)

emit("1_sample", "23:45\n21:30\n00:01\n00:00\n")

emit("2_edges", "23:59\n00:01\n01:00\n12:00\n00:00\n")

wide = "".join(fmt(t // 60, t % 60) + "\n" for t in range(1, 1440)) + "00:00\n"
emit("3_wide", wide)

rng = random.Random(7)
rand_cases = "".join(fmt(t // 60, t % 60) + "\n" for t in (rng.randrange(1, 1440) for _ in range(1000)))
emit("4_random", rand_cases + "00:00\n")

io_cases = "".join(fmt(t // 60, t % 60) + "\n" for t in (rng.randrange(1, 1440) for _ in range(200000)))
emit("5_io", io_cases + "00:00\n")

print("gen ok")
