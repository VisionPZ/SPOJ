#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    parts = text.split()
    case_count = int(parts[0])
    position = 1
    results = []
    for _ in range(case_count):
        size = int(parts[position])
        position += 1
        rows = parts[position:position + size]
        position += size
        reach = [set() for _ in range(size)]
        for source, row in enumerate(rows):
            for target, symbol in enumerate(row):
                if symbol == 'Y':
                    reach[source].add(target)
        for middle in range(size):
            for source in range(size):
                if middle in reach[source]:
                    reach[source] |= reach[middle]
        assigned = set()
        groups = 0
        for person in range(size):
            if person in assigned:
                continue
            groups += 1
            for other in range(size):
                if other in reach[person] and person in reach[other]:
                    assigned.add(other)
        results.append(str(groups))
    return "\n".join(results) + "\n"


SAMPLE = """3
3
NYN
NNY
YNN
7
NNYNNNN
NNNYYYN
NNNNNNN
YNNNNNN
NNNYNNN
NNNNNNN
NNNNNYN
7
NNNNYYN
NNNNNNN
NNNNNYN
NYNNNYY
NNNYNNN
NNYNNNY
NNNNYNN
"""
SAMPLE_OUT = """1
7
3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\nN\n") == "1\n"
assert oracle("1\n2\nNY\nYN\n") == "1\n"
assert oracle("1\n2\nNN\nNN\n") == "2\n"
assert oracle("1\n3\nNYN\nNNN\nNNN\n") == "3\n"


def make_graph(rng, size, density):
    rows = []
    for source in range(size):
        row = ['N'] * size
        for target in range(size):
            if source != target and rng.random() < density:
                row[target] = 'Y'
        rows.append("".join(row))
    return rows


def write(name, cases):
    text = str(len(cases)) + "\n"
    for rows in cases:
        text += str(len(rows)) + "\n"
        text += "".join(row + "\n" for row in rows)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        ["N"],
        ["NN", "YN"],
        ["NNN", "NNN", "NNN"],
        ["NNY", "NNY", "NNN"],
        ["NYN", "NNY", "YNN"],
    ])
    rng = random.Random(20261126)
    write("3_wide", [make_graph(rng, 100, 0.30), make_graph(rng, 100, 0.80)])
    write("4_random", [make_graph(rng, rng.randint(1, 100), rng.choice([0.02, 0.1, 0.4]))
                       for _ in range(1000)])
    write("5_io", [make_graph(rng, 100, rng.choice([0.05, 0.5])) for _ in range(1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
