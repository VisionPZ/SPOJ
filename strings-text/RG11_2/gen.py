#!/usr/bin/env python3
import random
import re
import string
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SAMPLE = """a
tv
ptoui
bontres
zoggax
wiinq
eep
houctuh
end
"""
SAMPLE_OUT = """<a> is acceptable.
<tv> is not acceptable.
<ptoui> is not acceptable.
<bontres> is not acceptable.
<zoggax> is not acceptable.
<wiinq> is not acceptable.
<eep> is acceptable.
<houctuh> is acceptable.
"""


def is_acceptable(word):
    if not any(letter in "aeiou" for letter in word):
        return False
    if re.search(r"[aeiou]{3}", word) or re.search(r"[^aeiou]{3}", word):
        return False
    for index in range(1, len(word)):
        if word[index] == word[index - 1] and word[index] not in "eo":
            return False
    return True


def oracle(text):
    lines = []
    for line in text.splitlines():
        word = line.strip()
        if word == "end":
            break
        if not word:
            continue
        verdict = "is acceptable." if is_acceptable(word) else "is not acceptable."
        lines.append("<%s> %s" % (word, verdict))
    return "\n".join(lines) + "\n" if lines else ""


assert oracle(SAMPLE) == SAMPLE_OUT
assert is_acceptable("a")
assert not is_acceptable("tv")
assert is_acceptable("eep")
assert not is_acceptable("ptoui")


def write(name, words):
    input_text = "\n".join(words + ["end"]) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", ["a", "e", "o", "y", "ee", "oo", "aa", "abb",
                      "aei", "bcd", "aae", "eoo", "qv", "iou", "xyz"])
    rng = random.Random(20261126)
    write("3_wide", ["".join(rng.choice(string.ascii_lowercase)
                             for _ in range(20)) for _ in range(300)])
    write("4_random", ["".join(rng.choice(string.ascii_lowercase)
                               for _ in range(rng.randint(1, 20)))
                       for _ in range(400)])
    write("5_io", ["".join(rng.choice("aeiobcdfghjklmnpqrstuvwxyz")
                           for _ in range(rng.randint(1, 20)))
                   for _ in range(20000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE.strip().splitlines()[:-1])
build()
