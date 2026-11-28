#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    pos = 1
    lines = []
    for _ in range(case_count):
        person_count = int(tokens[pos])
        pos += 1
        heights = [int(value) for value in tokens[pos:pos + person_count]]
        pos += person_count
        for index in range(person_count):
            left = -1
            for distance in range(1, person_count):
                neighbor = (index - distance) % person_count
                if heights[neighbor] > heights[index]:
                    left = neighbor + 1
                    break
            right = -1
            for distance in range(1, person_count):
                neighbor = (index + distance) % person_count
                if heights[neighbor] > heights[index]:
                    right = neighbor + 1
                    break
            lines.append(f"{left} {right}")
    return "\n".join(lines) + "\n"


SAMPLE = """3
5
172 170 168 171 169
3
172 169 172
1
172
"""
SAMPLE_OUT = """-1 -1
1 4
2 4
1 1
4 1
-1 -1
1 3
-1 -1
-1 -1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n3\n1 1 1\n") == "-1 -1\n-1 -1\n-1 -1\n"
assert oracle("1\n2\n5 3\n") == "-1 -1\n1 1\n"
assert oracle("1\n4\n1 2 3 4\n") == "4 2\n4 3\n4 4\n-1 -1\n"


def write(name, cases):
    text = str(len(cases)) + "\n"
    for heights in cases:
        text += str(len(heights)) + "\n"
        text += " ".join(str(value) for value in heights) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[1, 1, 1], [5, 3], [2, 1, 4, 3]])
    rng = random.Random(20261126)
    wide = [[rng.randint(1, 10 ** 9) for _ in range(120)] for _ in range(3)]
    write("3_wide", wide)
    random_cases = []
    for _ in range(4):
        size = rng.randint(2, 60)
        random_cases.append([rng.randint(1, 40) for _ in range(size)])
    write("4_random", random_cases)
    big = [[rng.randint(1, 10 ** 9) for _ in range(600)]]
    write("5_io", big)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
