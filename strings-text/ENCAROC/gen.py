#!/usr/bin/env python3
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = "hello world\no\n"
SAMPLE_OUT = "2\n"


def oracle(text):
    lines = text.split("\n")
    sentence = lines[0]
    target = ""
    for line in lines[1:]:
        stripped = line.strip()
        if stripped:
            target = stripped[0]
            break
    return str(sentence.count(target)) + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("aaaa\na\n") == "4\n"
assert oracle("abc\nz\n") == "0\n"
assert oracle("a b a\na\n") == "2\n"
assert oracle("AaAa\nA\n") == "2\n"


def write(name, sentence, target):
    input_text = sentence + "\n" + target + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", "", "a")
    write("3_wide", "ab" * 50000, "a")
    rng = random.Random(20261125)
    alphabet = "abcdefghijklmnopqrstuvwxyz "
    write("4_random", "".join(rng.choice(alphabet) for _ in range(20000)),
          rng.choice(alphabet))
    write("5_io", ("the quick brown fox\n" * 50000).replace("\n", " "), "x")


def worked_example():
    sentence = "hello world"
    target = "o"
    hits = [index for index, ch in enumerate(sentence) if ch == target]
    print(f"string: {sentence}")
    print(f"character: {target}")
    print(f"positions (zero based): {hits}")
    print(f"count: {len(hits)}")


if "--trace" in sys.argv:
    worked_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", "hello world", "o")
    build()
