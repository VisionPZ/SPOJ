#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(data):
    frequencies = [0] * 256
    for byte in data:
        frequencies[byte] += 1
    present = [byte for byte in range(256) if frequencies[byte]]

    def rank(byte):
        return sum(1 for other in present
                   if (frequencies[other], other) < (frequencies[byte], byte))

    ranks = {byte: rank(byte) for byte in present}
    total = len(present)
    pairs = [(byte, total - 1 - ranks[byte]) for byte in present]
    substitution = {byte: next(other for other, target in pairs if target == rank(byte))
                    for byte in present}
    return bytes(substitution[byte] for byte in data)


SAMPLE_ONE_IN = b"1\nAliens are dumb\n"
SAMPLE_ONE_OUT = b" mn\nibAud\nAralse"
SAMPLE_TWO_IN = b"1\nMississippi"
SAMPLE_TWO_OUT = b"spMMpMMpiip"
SAMPLE_THREE_IN = b"2\nMissi\nssippi"
SAMPLE_THREE_OUT = b"iM\n\nMs\n\nMppM"

assert oracle(SAMPLE_ONE_IN[2:]) == SAMPLE_ONE_OUT
assert oracle(SAMPLE_TWO_IN[2:]) == SAMPLE_TWO_OUT
assert oracle(SAMPLE_THREE_IN[2:]) == SAMPLE_THREE_OUT
assert oracle(b"aa") == b"aa"
assert oracle(b"ab") == b"ba"


def write(name, data):
    (ROOT / "in" / f"{name}.txt").write_bytes(data)
    (ROOT / "out" / f"{name}.out").write_bytes(oracle(data[data.index(b"\n") + 1:]))


def build():
    rng = random.Random(20261126)
    alphabet = b"abcXYZ 0123\n"
    text = bytes(rng.choice(alphabet) for _ in range(400))
    write("4_random", str(text.count(b"\n") + (0 if text.endswith(b"\n") else 1))
          .encode() + b"\n" + text)
    lines = [bytes(rng.randrange(32, 127) for _ in range(42)) + b"\n"
             for _ in range(590)]
    large = b"".join(lines)[:25000]
    write("5_io", b"590\n" + large)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_bytes(SAMPLE_ONE_IN)
(ROOT / "out" / "1_sample.out").write_bytes(SAMPLE_ONE_OUT)
write("2_edges", SAMPLE_TWO_IN)
write("3_wide", SAMPLE_THREE_IN)
build()
