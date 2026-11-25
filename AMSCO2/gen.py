#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def cells_for(length, columns):
    cells = []
    position = 0
    row = 0
    while position < length:
        for column in range(columns):
            size = 2 if (row + column) % 2 == 0 else 1
            size = min(size, length - position)
            if size <= 0:
                break
            cells.append((row, column, size))
            position += size
        row += 1
    return cells


def encrypt(plain, key):
    columns = len(key)
    cells = cells_for(len(plain), columns)
    grouped = [[] for _ in range(columns)]
    position = 0
    for _, column, size in cells:
        grouped[column].append(plain[position:position + size])
        position += size
    pieces = []
    for label in range(1, columns + 1):
        pieces.append("".join(grouped[key.index(str(label))]))
    return "".join(pieces)


def oracle(key, cipher):
    columns = len(key)
    cells = cells_for(len(cipher), columns)
    lengths = [0] * columns
    for _, column, size in cells:
        lengths[column] += size
    grouped = [""] * columns
    position = 0
    for label in range(1, columns + 1):
        column = key.index(str(label))
        grouped[column] = cipher[position:position + lengths[column]]
        position += lengths[column]
    cursors = [0] * columns
    pieces = []
    for _, column, size in cells:
        pieces.append(grouped[column][cursors[column]:cursors[column] + size])
        cursors[column] += size
    return "".join(pieces)


def oracle_text(pairs):
    return "\n".join(oracle(key, cipher) for key, cipher in pairs) + "\n"


SAMPLE_PAIRS = [
    ("7456321", "HETEAMTTOWIMONNSEJNDTOSEBRERRHOOISSMIURNORISHIROR"),
    ("41325", "CECRTEGLENPHPLUTNANTEIOMOWIRSITDDSINTNALINESAALEMHATGLRGR"),
]
SAMPLE_OUT = """RIDERSONTHESTORMINTOTHISHOUSEWEAREBORNJIMMORRISON
INCOMPLETECOLUMNARWITHALTERNATINGSINGLELETTERSANDDIGRAPHS
"""
assert oracle_text(SAMPLE_PAIRS) == SAMPLE_OUT
assert oracle("7456321", encrypt("RIDERSONTHESTORMINTOTHISHOUSEWEAREBORNJIMMORRISON", "7456321")) == SAMPLE_OUT.splitlines()[0]
assert oracle("41325", encrypt("INCOMPLETECOLUMNARWITHALTERNATINGSINGLELETTERSANDDIGRAPHS", "41325")) == SAMPLE_OUT.splitlines()[1]
assert oracle("21", encrypt("RIDERS", "21")) == "RIDERS"
assert len(cells_for(11, 7)) == 7


def write(name, pairs):
    lines = [f"{key} {cipher}" for key, cipher in pairs]
    (ROOT / "in" / f"{name}.txt").write_text("\n".join(lines) + "\n")
    (ROOT / "out" / f"{name}.out").write_text(oracle_text(pairs))


def make_pair(rng, columns, text_length):
    digits = list(range(1, columns + 1))
    rng.shuffle(digits)
    key = "".join(str(value) for value in digits)
    letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    plain = "".join(rng.choice(letters) for _ in range(text_length))
    return key, encrypt(plain, key)


def build():
    rng = random.Random(20261126)
    write("2_edges", [("21", encrypt("RIDERS", "21")),
                      ("1", encrypt("ABCDEFGHIJKLMNOPQRSTUVWXYZ", "1")),
                      ("987654321", encrypt("ABCDEFGHIJKLMNOPQRSTUVWXYZ", "987654321")),
                      ("12", encrypt("ABC", "12"))])
    write("3_wide", [make_pair(rng, 9, 250) for _ in range(12)])
    write("4_random", [make_pair(rng, rng.randint(2, 9), rng.randint(6, 200)) for _ in range(30)])
    write("5_io", [make_pair(rng, 9, 250) for _ in range(500)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_PAIRS)
build()
