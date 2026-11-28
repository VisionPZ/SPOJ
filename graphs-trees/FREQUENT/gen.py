#!/usr/bin/env python3
import random
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while cursor < len(tokens):
        count = tokens[cursor]; cursor += 1
        if count == 0:
            break
        queries = tokens[cursor]; cursor += 1
        values = tokens[cursor:cursor + count]; cursor += count
        for _ in range(queries):
            left = tokens[cursor]; cursor += 1
            right = tokens[cursor]; cursor += 1
            frequencies = Counter(values[left - 1:right])
            answers.append(str(max(frequencies.values())))
    return '\n'.join(answers) + '\n'


def solve_by_runs(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while cursor < len(tokens):
        count = tokens[cursor]; cursor += 1
        if count == 0:
            break
        queries = tokens[cursor]; cursor += 1
        values = tokens[cursor:cursor + count]; cursor += count
        boundary = [0]
        for index in range(1, count):
            if values[index] != values[index - 1]:
                boundary.append(index)
        boundary.append(count)
        for _ in range(queries):
            left = tokens[cursor] - 1; cursor += 1
            right = tokens[cursor]; cursor += 1
            answer = 0
            for run in range(len(boundary) - 1):
                overlap = min(right, boundary[run + 1]) - max(left, boundary[run])
                if overlap > answer:
                    answer = overlap
            answers.append(str(answer))
    return '\n'.join(answers) + '\n'


def write(name, cases):
    text = ''.join(f'{len(values)} {len(queries)}\n'
                   + ' '.join(str(value) for value in values) + '\n'
                   + ''.join(f'{left} {right}\n' for left, right in queries)
                   for values, queries in cases) + '0\n'
    (ROOT / 'in' / f'{name}.txt').write_text(text)
    (ROOT / 'out' / f'{name}.out').write_text(oracle(text))


SAMPLE = ([-1, -1, 1, 1, 1, 1, 3, 10, 10, 10], [(2, 3), (1, 10), (5, 10)])
SAMPLE_IN = ('10 3\n-1 -1 1 1 1 1 3 10 10 10\n'
             '2 3\n1 10\n5 10\n0\n')
SAMPLE_OUT = '1\n4\n3\n'
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert solve_by_runs(SAMPLE_IN) == SAMPLE_OUT
assert oracle('1 2\n-100000\n1 1\n1 1\n0\n') == '1\n1\n'
assert oracle('4 1\n1 2 3 4\n1 4\n0\n') == '1\n'
assert oracle('3 3\n-5 -5 -5\n1 2\n2 3\n1 3\n0\n') == '2\n2\n3\n'
assert solve_by_runs('3 3\n-5 -5 -5\n1 2\n2 3\n1 3\n0\n') == '2\n2\n3\n'
assert oracle(SAMPLE_IN) == solve_by_runs(SAMPLE_IN)


def build():
    write('2_edges', [
        ([7], [(1, 1), (1, 1)]),
        ([1, 1, 1, 1, 1], [(1, 5), (2, 4), (3, 3)]),
        (list(range(-10, 11)), [(1, 21), (5, 15), (21, 21)]),
        ([-5, -5, -4, -4, -4, 9], [(1, 6), (2, 5), (4, 4)]),
    ])
    rng = random.Random(20261126)
    values = [rng.randint(-100000, 100000) for _ in range(1000)]
    values.sort()
    queries = []
    for _ in range(300):
        left = rng.randint(1, 1000)
        right = rng.randint(left, 1000)
        queries.append((left, right))
    write('3_wide', [(values, queries)])
    wide = []
    for _ in range(6):
        size = rng.randint(1, 120)
        arr = sorted(rng.randint(-20, 20) for _ in range(size))
        qs = []
        for _ in range(60):
            left = rng.randint(1, size)
            right = rng.randint(left, size)
            qs.append((left, right))
        wide.append((arr, qs))
    write('4_random', wide)
    many_values = sorted(rng.randint(-100, 100) for _ in range(200))
    many_queries = []
    for _ in range(70000):
        left = rng.randint(1, 200)
        right = rng.randint(left, 200)
        many_queries.append((left, right))
    write('5_io', [(many_values, many_queries)])


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
(ROOT / 'in' / '1_sample.txt').write_text(SAMPLE_IN)
(ROOT / 'out' / '1_sample.out').write_text(SAMPLE_OUT)
build()
