#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parent

CYCLE = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
         14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    observed = tokens[1:1 + count]
    signs = set()
    for start in range(30):
        if all(CYCLE[(start + index) % 30] == observed[index] for index in range(count)):
            last = CYCLE[(start + count - 1) % 30]
            coming = CYCLE[(start + count) % 30]
            signs.add(1 if coming > last else -1)
    if signs == {1}:
        return "CRECIENTE\n"
    if signs == {-1}:
        return "MENGUANTE\n"
    return "-1\n"


SAMPLES = [
    ("5\n3 4 5 6 7\n", "CRECIENTE\n"),
    ("7\n12 13 14 15 14 13 12\n", "MENGUANTE\n"),
    ("1\n8\n", "-1\n"),
]
for sample, expected in SAMPLES:
    assert oracle(sample) == expected
assert oracle("1\n0\n") == "CRECIENTE\n"
assert oracle("1\n15\n") == "MENGUANTE\n"


def write(name, observed):
    text = str(len(observed)) + "\n" + " ".join(str(value) for value in observed) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [0, 1, 2, 3])
    write("3_wide", list(CYCLE) * 3 + [0])
    write("4_random", CYCLE[4:37])
    write("5_io", list(CYCLE) * 3 + [0])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [3, 4, 5, 6, 7])
build()
