#!/usr/bin/env python3
import os
import random
from collections import Counter

def oracle(data_bytes):
    text = data_bytes.decode("latin-1")
    newlinePos = text.find("\n")
    if newlinePos < 0:
        header, body = text, ""
    else:
        header, body = text[:newlinePos], text[newlinePos + 1:]
    lineCount = int("".join(ch for ch in header if ch.isdigit()))
    textLines = body.split("\n")[:lineCount]
    joined = "".join(textLines).lower()
    letterCounts = Counter(ch for ch in joined if "a" <= ch <= "z")
    ranked = sorted(letterCounts.items(), key=lambda pair: (pair[1], pair[0]), reverse=True)
    answerLines = ["%s %d" % (letter.upper(), count) for letter, count in ranked]
    return "\n".join(answerLines) + ("\n" if answerLines else "")

sample_in = (
    "3\n"
    "Esta es una prueba,\n"
    "Cuentame 1 2 3 4 5,\n"
    "\u00a1 \u00a1oohh!! \u00bfEsta es pregunta facil?\n"
)
sample_out = (
    "E 8\nA 7\nU 4\nT 4\nS 4\nN 3\nR 2\nP 2\nO 2\nH 2\nC 2\n"
    "M 1\nL 1\nI 1\nG 1\nF 1\nB 1\n"
)
assert oracle(sample_in.encode("latin-1")) == sample_out
assert oracle(b"1\nabcabc\n") == "C 2\nB 2\nA 2\n"
assert oracle(b"1\n12345\n") == ""

os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)

def emit(name, text_in):
    text_out = oracle(text_in.encode("latin-1"))
    with open("in/" + name + ".txt", "wb") as f:
        f.write(text_in.encode("latin-1"))
    with open("out/" + name + ".out", "wb") as f:
        f.write(text_out.encode("latin-1"))

emit("1_sample", sample_in)
emit("2_edges", "2\n\n12345\n")

rng = random.Random(99)
def random_text_line():
    return "".join(rng.choice("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ ,.0123456789") for _ in range(200)) + "\n"

wide_text = "5000\n" + "".join(random_text_line() for _ in range(5000))
emit("3_wide", wide_text)
emit("4_random", "1000\n" + "".join(random_text_line() for _ in range(1000)))
emit("5_io", wide_text)

print("gen ok")
