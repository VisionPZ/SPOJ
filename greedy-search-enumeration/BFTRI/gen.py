#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    test_count = int(tokens[0])
    lines = []
    token_index = 1
    for _ in range(test_count):
        triangle_char = tokens[token_index]
        triangle_size = int(tokens[token_index + 1])
        token_index += 2
        for row_size in range(1, triangle_size + 1):
            lines.append(triangle_char * row_size)
    return "\n".join(lines) + "\n"


SAMPLE = """3
& 1
@ 3
? 5
"""
SAMPLE_OUT = """&
@
@@
@@@
?
??
???
????
?????
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 A 1\n") == "A\n"
assert oracle("2 # 2 * 3\n") == "#\n##\n*\n**\n***\n"
assert oracle("1 _ 5\n") == "_\n__\n___\n____\n_____\n"


def write(name, cases):
    lines = [str(len(cases))]
    for triangle_char, triangle_size in cases:
        lines.append(f"{triangle_char} {triangle_size}")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [("A", 1), ("z", 2)])
    write("3_wide", [("#", 99)])
    rng = random.Random(20261126)
    alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ@#$%&*+-=<>?"
    cases = [(rng.choice(alphabet), rng.randint(1, 20)) for _ in range(12)]
    write("4_random", cases)
    write("5_io", [(rng.choice(alphabet), 99) for _ in range(99)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [("&", 1), ("@", 3), ("?", 5)])
build()
