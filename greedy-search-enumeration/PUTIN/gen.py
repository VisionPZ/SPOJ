#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_total = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_total):
        dimension = tokens[cursor]
        budget = tokens[cursor + 1]
        point_count = tokens[cursor + 2]
        cursor += 3
        points = []
        for _ in range(point_count):
            points.append(tuple(tokens[cursor:cursor + dimension]))
            cursor += dimension
        found = [0]

        def walk(axis, remaining, vector):
            if axis == dimension:
                for point in points:
                    if all(vector[coordinate] >= point[coordinate]
                           for coordinate in range(dimension)):
                        return
                found[0] += 1
                return
            for value in range(1, remaining + 1):
                vector.append(value)
                walk(axis + 1, remaining - value, vector)
                vector.pop()

        walk(0, budget, [])
        answers.append(str(found[0]))
    return '\n'.join(answers) + '\n'


SAMPLE = """1
2 4 2
1 3
2 1
"""
SAMPLE_OUT = """2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 4 0\n") == "6\n"
assert oracle("1\n3 3 1\n1 1 1\n") == "0\n"
assert oracle("1\n2 2 1\n2 2\n") == "1\n"
assert oracle("1\n2 5 2\n1 1\n2 2\n") == "0\n"
assert oracle("1\n2 4 2\n1 3\n2 1\n") == "2\n"


def write(name, cases):
    lines = [str(len(cases))]
    for dimension, budget, points in cases:
        lines.append(f"{dimension} {budget} {len(points)}")
        for point in points:
            lines.append(' '.join(str(value) for value in point))
    text = '\n'.join(lines) + '\n'
    (ROOT / 'in' / (name + '.txt')).write_text(text)
    (ROOT / 'out' / (name + '.out')).write_text(oracle(text))


def build():
    write('2_edges', [
        (2, 2, []), (2, 2, [(1, 1)]), (2, 3, [(2, 1)]),
        (3, 4, [(1, 1, 1), (2, 2, 2)]), (4, 5, [(1, 1, 1, 1)]),
        (2, 9, [(1, 9), (9, 1), (2, 2)]),
    ])
    rng = random.Random(20261126)
    wide = [(6, 16, [tuple(rng.randint(1, 10) for _ in range(6))
                     for _ in range(20)]) for _ in range(4)]
    write('3_wide', wide)
    random_cases = []
    for _ in range(24):
        dimension = rng.randint(2, 6)
        budget = rng.randint(dimension, 16)
        point_count = rng.randint(0, 20)
        points = [tuple(rng.randint(1, 12) for _ in range(dimension))
                  for _ in range(point_count)]
        random_cases.append((dimension, budget, points))
    write('4_random', random_cases)
    io_cases = [(4, 14, [tuple(rng.randint(1, 10) for _ in range(4))
                         for _ in range(20)]) for _ in range(60)]
    write('5_io', io_cases)
    stress = ['1', '30 10000 20']
    for _ in range(20):
        stress.append(' '.join(str(rng.randint(1, 500)) for _ in range(30)))
    Path('/tmp/PUTIN_big.txt').write_text('\n'.join(stress) + '\n')


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
write('1_sample', [(2, 4, [(1, 3), (2, 1)])])
build()
