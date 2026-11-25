#!/usr/bin/env python3
from collections import deque
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while cursor < len(tokens):
        count = tokens[cursor]
        cursor += 1
        if count == 0:
            break
        values = tuple(tokens[cursor:cursor + count])
        cursor += count
        target = tuple(sorted(values))
        queue = deque([values])
        seen = {values}
        found = values == target
        while not found and queue:
            current = queue.popleft()
            for pivot in range(count):
                moved = (current[:pivot][::-1] + (current[pivot],) +
                         current[pivot + 1:][::-1])
                if moved == target:
                    found = True
                    break
                if moved not in seen:
                    seen.add(moved)
                    queue.append(moved)
        answers.append('1' if found else '0')
    return ''.join(answers) + '\n'


SAMPLE = """5
7 1 3 9 8
2
2 1
0
"""
SAMPLE_OUT = """10
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n5\n0\n") == "1\n"
assert oracle("2\n2 1\n0\n") == "0\n"
assert oracle("6\n1 2 3 4 5 6\n0\n") == "1\n"
assert oracle("6\n2 1 3 4 5 6\n0\n") == "0\n"
assert oracle("6\n1 1 3 4 5 6\n0\n") == "1\n"


def write(name, cases):
    text = ''.join(
        str(len(values)) + '\n' + ' '.join(str(v) for v in values) + '\n'
        for values in cases) + '0\n'
    (ROOT / 'in' / (name + '.txt')).write_text(text)
    (ROOT / 'out' / (name + '.out')).write_text(oracle(text))


def build():
    write('2_edges', [[1], [1], [2, 1], [2, 2], [3, 2, 1], [3, 1, 2, 3],
                      [4, 4, 3, 2, 1], [5, 5, 5, 5, 5], [6, 2, 1, 3, 4, 5, 6]])
    rng = random.Random(20261126)
    write('3_wide', [rng.sample(range(-1000, 1001), 7) for _ in range(12)])
    write('4_random', [[rng.randint(-1000, 1000) for _ in range(rng.randint(1, 7))]
                       for _ in range(40)])
    write('5_io', [[rng.randint(-1000, 1000) for _ in range(rng.randint(1, 5))]
                   for _ in range(100)])


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
write('1_sample', [[7, 1, 3, 9, 8], [2, 1]])
build()
