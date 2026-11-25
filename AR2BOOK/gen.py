#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    lines = text.split("\n")
    title, author, subject, book_id = lines[0], lines[1], lines[2], lines[3]
    return f"{title} : {author} : {subject} : {int(book_id)}\n"


SAMPLE = "nghin le mot dem\nkhong tac gia\nco tich\n1\n"
SAMPLE_OUT = "nghin le mot dem : khong tac gia : co tich : 1\n"

assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("A\nB\nC\n7\n") == "A : B : C : 7\n"
assert oracle("\n\n\n42\n") == " :  :  : 42\n"
assert oracle("two words\nthree word title\nsub ject\n2147483647\n") == \
    "two words : three word title : sub ject : 2147483647\n"


def write(name, title, author, subject, book_id):
    text = f"{title}\n{author}\n{subject}\n{book_id}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "", "", "", 42)
    write("3_wide", "A" * 300, "B " * 150, "C" * 300, 2147483647)
    rng = random.Random(20261126)
    words = ["nghin", "le", "mot", "dem", "khong", "tac", "gia",
             "co", "tich", "thang", "quy", "nho"]
    for name, length in (("4_random", 40), ("5_io", 40000)):
        fields = [" ".join(rng.choice(words) for _ in range(length // 4))
                  for _ in range(3)]
        write(name, fields[0], fields[1], fields[2],
              rng.randint(0, 10 ** 9))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", "nghin le mot dem", "khong tac gia", "co tich", 1)
build()
