#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 12345678


def oracle_case(levels, settlements, stops):
    if levels * settlements > 400 or stops > 200:
        ring = 1 if settlements <= 2 else 2
        across = 0 if levels == 1 else (1 if levels == 2 else 2)
        return levels * settlements * pow(ring + across * settlements, stops - 1, MODULUS) % MODULUS
    vertices = [(level, place) for level in range(levels) for place in range(settlements)]
    index = {vertex: position for position, vertex in enumerate(vertices)}
    adjacency = [[] for _ in vertices]

    def connect(source, target):
        adjacency[index[source]].append(index[target])

    for level in range(levels):
        for place in range(settlements):
            if settlements == 1:
                connect((level, place), (level, place))
            elif settlements == 2:
                connect((level, place), (level, (place + 1) % 2))
            else:
                connect((level, place), (level, (place + 1) % settlements))
                connect((level, place), (level, (place - 1) % settlements))
            if levels > 1:
                for other in {(level + 1) % levels, (level - 1) % levels}:
                    for target_place in range(settlements):
                        connect((level, place), (other, target_place))

    walks = [1] * len(vertices)
    for _ in range(stops - 1):
        updated = [0] * len(vertices)
        for source in range(len(vertices)):
            amount = walks[source]
            if amount == 0:
                continue
            for target in adjacency[source]:
                updated[target] = (updated[target] + amount) % MODULUS
        walks = updated
    return sum(walks) % MODULUS


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cases = tokens[0]
    answers = []
    cursor = 1
    for _ in range(cases):
        levels, settlements, stops = tokens[cursor:cursor + 3]
        cursor += 3
        answers.append(str(oracle_case(levels, settlements, stops)))
    return "\n".join(answers) + "\n"


SAMPLE = """5
1 1 1
1 2 1
3 3 56
4 3 4
691 60 97764
"""
SAMPLE_OUT = """1
2
8019378
6144
470730
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_case(2, 3, 5) == 2 * 3 * (2 + 3) ** 4 % MODULUS
assert oracle_case(1, 5, 3) == 20
assert oracle_case(3, 1, 4) == 81
for levels in range(1, 6):
    for settlements in range(1, 6):
        for stops in range(1, 12):
            ring = 1 if settlements <= 2 else 2
            across = 0 if levels == 1 else (1 if levels == 2 else 2)
            expected = levels * settlements * pow(ring + across * settlements, stops - 1, MODULUS) % MODULUS
            assert oracle_case(levels, settlements, stops) == expected


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(
        f"{levels} {settlements} {stops}\n" for levels, settlements, stops in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1, 1), (1, 2, 1), (2, 1, 3), (2, 2, 4), (1, 9, 1)])
    write("3_wide", [(5, 6, 30), (3, 4, 25), (6, 1, 29)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(1, 6), rng.randint(1, 6), rng.randint(1, 30))
                       for _ in range(40)])
    write("5_io", [(rng.randint(1, 6), rng.randint(1, 6), rng.randint(1, 30))
                   for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(1, 1, 1), (1, 2, 1), (3, 3, 56), (4, 3, 4), (691, 60, 97764)])
build()
