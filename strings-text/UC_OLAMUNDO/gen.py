#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    name = text.splitlines()[0].strip() if text.splitlines() else ""
    return f"Olá {name}, este é seu primeiro programa!\n"


SAMPLE = "Everton\n"
SAMPLE_OUT = "Olá Everton, este é seu primeiro programa!\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("Ana\n") == "Olá Ana, este é seu primeiro programa!\n"
assert oracle("João Silva\n") == "Olá João Silva, este é seu primeiro programa!\n"


def write(name, person):
    text = person + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "A")
    write("3_wide", "Marina de Jesus Souza")
    write("4_random", "Luiz Felipe")
    write("5_io", "Alexandre")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", "Everton")
build()
