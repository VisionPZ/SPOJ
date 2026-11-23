#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
IN_DIR = ROOT / "in"
OUT_DIR = ROOT / "out"
DUPLICATE = ord("d")
NEWLINE = ord("\n")

SAMPLE_INPUT = b"sample-test\n-dd-d-dd\nend signalled by two newlines\n\n"
SAMPLE_OUTPUT = (
    b"sample-test\n"
    + b"-" * 44
    + b"\nenen signalleenen signalle by two newlines\n"
)


def oracle(data):
    produced = []
    for segment in data.split(b"\n"):
        if len(segment) == 0:
            break
        built = bytearray()
        for key in segment:
            if key == DUPLICATE:
                built.extend(bytes(built))
            else:
                built.append(key)
        produced.append(bytes(built))
    if not produced:
        return b""
    return b"\n".join(produced) + b"\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle(b"abdd\n\n") == b"abababab\n"
assert oracle(b"a\n\nb\n\n") == b"a\n"
assert oracle(b"a b!?\n\n") == b"a b!?\n"


def write_pair(name, data):
    (IN_DIR / (name + ".txt")).write_bytes(data)
    (OUT_DIR / (name + ".out")).write_bytes(oracle(data))


def build_edges():
    chunks = [b"x\n", b"xdd\n", b"a b!?-dd\n", b"12345678ddd\n", b"~\n"]
    return b"".join(chunks) + b"\n"


def build_wide():
    lines = []
    lines.append(b"a" * 75 + b"d\n")
    lines.append(b"b" * 9 + b"dddd\n")
    lines.append(b"c" * 37 + b"dd\n")
    lines.append(b"z\n")
    lines.append(b"e" * 75 + b"d\n")
    for size in range(1, 60):
        lines.append(bytes([65 + (size % 26)]) * size + b"\n")
    lines.append(b"f" * 9 + b"dddd\n")
    lines.append(b"g" * 75 + b"d\n")
    return b"".join(lines) + b"\n"


def build_random():
    rng = random.Random(20261123)
    alphabet = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,-!?"
    lines = []
    for _ in range(1000):
        length = rng.randint(1, 75)
        text = bytes(rng.choice(alphabet) for _ in range(length))
        doublings = rng.randint(0, 4)
        while length * (2 ** doublings) > 150:
            doublings -= 1
        lines.append(text + b"d" * doublings + b"\n")
    return b"".join(lines) + b"\n"


def build_io():
    line = b"a" * 75 + b"d\n"
    return line * 20000 + b"\n"


IN_DIR.mkdir(exist_ok=True)
OUT_DIR.mkdir(exist_ok=True)
pairs = {
    "1_sample": SAMPLE_INPUT,
    "2_edges": build_edges(),
    "3_wide": build_wide(),
    "4_random": build_random(),
    "5_io": build_io(),
}
for pair_name, pair_data in pairs.items():
    write_pair(pair_name, pair_data)
