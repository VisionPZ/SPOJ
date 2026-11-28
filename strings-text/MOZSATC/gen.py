#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    source = tokens[0]
    allowed = int(tokens[1])
    comma_positions = [-1]
    for index, char in enumerate(source):
        if char == ',':
            comma_positions.append(index)
    comma_positions.append(len(source))
    total_commas = len(comma_positions) - 2
    if allowed >= total_commas:
        return str(len(source)) + "\n"
    best = 0
    for gap_index in range(0, len(comma_positions) - allowed - 1):
        length = comma_positions[gap_index + allowed + 1] - comma_positions[gap_index] - 1
        if length > best:
            best = length
    return str(best) + "\n"


SAMPLE = """a,b,a0,3hg,0,,,sdfghijfh06
3
"""
SAMPLE_OUT = """15
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("abc\n0\n") == "3\n"
assert oracle(",,,\n0\n") == "0\n"
assert oracle(",,,\n3\n") == "3\n"
assert oracle("a,b,c\n1\n") == "3\n"


def write(name, source, allowed):
    text = f"{source}\n{allowed}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", ",,abc,,", 0)
    write("3_wide", "x,y,z," * 16000, 16000)
    rng = random.Random(20261126)
    alphabet = "abcxyz0129,,,,"
    for name in ("4_random", "5_io"):
        chars = [rng.choice(alphabet) for _ in range(100000)]
        allowed = rng.randint(0, len(chars))
        write(name, "".join(chars), allowed)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", "a,b,a0,3hg,0,,,sdfghijfh06", 3)
build()
