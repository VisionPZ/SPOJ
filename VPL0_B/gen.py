#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def render_case(values, unit):
    groups = {}
    for value in values:
        groups.setdefault(value // unit, []).append(value % unit)
    stem_width = len(str(max(groups)))
    lines = []
    for stem in sorted(groups):
        leaves = sorted(groups[stem])
        lines.append(str(stem).rjust(stem_width) + " | " +
                     " ".join(str(leaf) for leaf in leaves))
    return "\n".join(lines) + "\n"


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    case_count = tokens[position]
    position += 1
    pieces = []
    for case_number in range(1, case_count + 1):
        size = tokens[position]
        unit = tokens[position + 1]
        position += 2
        values = tokens[position:position + size]
        position += size
        pieces.append(f"Scenario #{case_number}:\n")
        pieces.append(render_case(values, unit))
        pieces.append("\n")
    return "".join(pieces)


SAMPLE = """2
17 10
44
46
47
49
63
64
66
68
68
72
72
75
76
81
84
88
106
5 23
1
9
127
23
73
"""
SAMPLE_OUT = """Scenario #1:
 4 | 4 6 7 9
 6 | 3 4 6 8 8
 7 | 2 2 5 6
 8 | 1 4 8
10 | 6

Scenario #2:
0 | 1 9
1 | 0
3 | 4
5 | 12

"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1\n1\n") == "Scenario #1:\n1 | 0\n\n"
assert oracle("1\n3 23\n23\n1\n127\n") == "Scenario #1:\n0 | 1\n1 | 0\n5 | 12\n\n"
assert oracle("1\n2 100\n1\n1000\n") == "Scenario #1:\n 0 | 1\n10 | 0\n\n"
assert render_case([106, 44, 49], 10) == " 4 | 4 9\n10 | 6\n"


def write(name, cases):
    pieces = [str(len(cases)) + "\n"]
    for values, unit in cases:
        pieces.append(f"{len(values)} {unit}\n")
        pieces.extend(str(value) + "\n" for value in values)
    text = "".join(pieces)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [([1], 1), ([1, 999, 1000], 100)])
    rng = random.Random(20261126)
    write("3_wide", [([rng.randint(1, 1000) for _ in range(10000)], 1000)])
    write("4_random", [([rng.randint(1, 1000) for _ in range(rng.randint(1, 300))],
                        rng.randint(1, 1000)) for _ in range(20)])
    write("5_io", [(list(range(1, 10001)), 1)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [([44, 46, 47, 49, 63, 64, 66, 68, 68, 72, 72, 75, 76,
                     81, 84, 88, 106], 10),
                   ([1, 9, 127, 23, 73], 23)])
build()
