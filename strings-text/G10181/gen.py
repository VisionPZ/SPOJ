#!/usr/bin/env python3
import os
import random
import re

def oracle(data_bytes):
    tokens = re.findall(rb"[A-Za-z]+", data_bytes)
    lowered = set()
    for token in tokens:
        lowered.add(token.decode("ascii").lower())
    ordered = sorted(lowered)
    return "\n".join(ordered) + ("\n" if ordered else "")

sample_in = (
    "los pollitos dicen\n"
    "pio, PIO,pIo,\n"
    "cuando tienen hambre.\n"
    "cuando tiEnen frio,\n"
    "La gallina busca,\n"
    "el maiz y el trigo,\n"
    "les da la comida,\n"
    "y les presta abrigo\n"
)
sample_out = (
    "abrigo\nbusca\ncomida\ncuando\nda\ndicen\nel\nfrio\ngallina\nhambre\n"
    "la\nles\nlos\nmaiz\npio\npollitos\npresta\ntienen\ntrigo\ny\n"
)
assert oracle(sample_in.encode("latin-1")) == sample_out
assert oracle(b"A a Bb\n") == "a\nbb\n"
assert oracle(b"!!!\n") == ""

os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)

def emit(name, text_in):
    text_out = oracle(text_in.encode("latin-1"))
    with open("in/" + name + ".txt", "wb") as f:
        f.write(text_in.encode("latin-1"))
    with open("out/" + name + ".out", "wb") as f:
        f.write(text_out.encode("latin-1"))

emit("1_sample", sample_in)
emit("2_edges", "A\na\nZz\n!!!\n\n")

rng = random.Random(42)
vocabulary = []
seenVocabulary = set()
while len(vocabulary) < 5000:
    length = rng.randint(3, 10)
    word = "".join(rng.choice("abcdefghijklmnopqrstuvwxyz") for _ in range(length))
    if word not in seenVocabulary:
        seenVocabulary.add(word)
        vocabulary.append(word)
def random_line():
    words = []
    width = 0
    while width < 190:
        word = rng.choice(vocabulary)
        if rng.random() < 0.2:
            word = word.upper()
        elif rng.random() < 0.2:
            word = word[0].upper() + word[1:]
        words.append(word)
        width += len(word) + 1
    return " ".join(words) + ",\n"

wide_text = "".join(random_line() for _ in range(5000))
emit("3_wide", wide_text)
emit("4_random", "".join(random_line() for _ in range(1000)))
emit("5_io", wide_text)

print("gen ok")
