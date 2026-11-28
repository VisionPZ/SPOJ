#!/usr/bin/env python3
import random
import string
from pathlib import Path

ROOT = Path(__file__).resolve().parent
IGNORED = {"a", "in", "is", "on", "of", "and", "the", "for"}


def oracle(text):
    lines = text.split("\n")
    count = int(lines[0])
    words = [word.strip(" ") for word in lines[1:1 + count]]
    kept = [word[0] for word in words if word and word.lower() not in IGNORED]
    return "".join(ch.upper() for ch in kept) + "\n"


def alternate(text):
    lines = text.split("\n")
    count = int(lines[0])
    answer = []
    for word in lines[1:1 + count]:
        cleaned = word.strip(" ")
        if not cleaned or cleaned.lower() in IGNORED:
            continue
        answer.append(str.translate(cleaned[:1], str.maketrans(string.ascii_lowercase,
                                                               string.ascii_uppercase)))
    return "".join(answer) + "\n"


SAMPLE = """5
the
ministry
of
silly
walks
"""
SAMPLE_OUT = """MSW
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert alternate(SAMPLE) == SAMPLE_OUT
assert oracle("4\nthe \nMinistry\nOF\nsilly\n") == "MS\n"
assert oracle("3\n A \n IN\nIs \n") == "\n"
assert oracle("2\nrobin\nhood\n") == "RH\n"
assert oracle("3\n  and  \n platform\n  association\n") == "PA\n"


def write(name, words):
    text = str(len(words)) + "\n" + "\n".join(words) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", ["the ", "Ministry", "OF", "silly", "walks "])
    write("3_wide", [("The" if index % 3 == 0 else "longword" + str(index))
                     for index in range(99)])
    rng = random.Random(20261126)
    pool = ["a", "in", "is", "on", "of", "and", "the", "for",
            "Alpha", "beta", "GAMMA", "delta", "epsilon", "zeta"]
    write("4_random", [rng.choice(pool) for _ in range(70)])
    write("5_io", [("connectivity" + str(index)) for index in range(99)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE.splitlines()[1:])
build()
