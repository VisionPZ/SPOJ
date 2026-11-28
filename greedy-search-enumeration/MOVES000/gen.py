#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    length = int(tokens[cursor]); cursor += 1
    queries = int(tokens[cursor]); cursor += 1
    letters = list(tokens[cursor]); cursor += 1
    for _ in range(queries):
        left = int(tokens[cursor]); cursor += 1
        right = int(tokens[cursor]); cursor += 1
        block = letters[left - 1:right]
        del letters[left - 1:right]
        letters[0:0] = block
    return "".join(letters) + "\n"


SAMPLE = """10 3
abcdefghij
2 3
3 5
3 7
"""
SAMPLE_OUT = """ebcfgadhij
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3 1\nabc\n1 3\n") == "abc\n"
assert oracle("4 1\nabcd\n2 4\n") == "bcda\n"
assert oracle("5 1\nabcde\n3 3\n") == "cabde\n"
assert oracle("6 2\nabcdef\n2 3\n5 6\n") == "efbcad\n"


def write(name, letters, queries):
    lines = [f"{len(letters)} {len(queries)}", letters]
    lines += [f"{left} {right}" for left, right in queries]
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "a", [(1, 1), (1, 1), (1, 1)])
    write("3_wide", "abcdefghijklmnopqrstuvwxyz", [(1, 26), (13, 26), (1, 12), (5, 20)])
    rng = random.Random(20261126)
    letters = "".join(chr(97 + rng.randrange(26)) for _ in range(80))
    moves = []
    for _ in range(100):
        left = rng.randint(1, 80)
        right = rng.randint(left, 80)
        moves.append((left, right))
    write("4_random", letters, moves)
    wide = "".join(chr(97 + (index % 26)) for index in range(200000))
    write("5_io", wide, [(1, 1)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", "abcdefghij", [(2, 3), (3, 5), (3, 7)])
build()
