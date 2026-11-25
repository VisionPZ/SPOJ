#!/usr/bin/env python3
import itertools
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def endpoint(segments, segment_index, which_end):
    return segments[segment_index][which_end]


def distance(first, second):
    return math.hypot(first[0] - second[0], first[1] - second[1])


def oracle(text):
    tokens = text.split()
    cursor = 0
    answers = []
    case_number = 0
    while True:
        count = int(tokens[cursor]); cursor += 1
        if count == 0:
            break
        case_number += 1
        segments = []
        for _ in range(count):
            first = (float(tokens[cursor]), float(tokens[cursor + 1]))
            second = (float(tokens[cursor + 2]), float(tokens[cursor + 3]))
            cursor += 4
            segments.append((first, second))
        original = sum(distance(*segment) for segment in segments)
        best = float('inf')
        for order in itertools.permutations(range(count)):
            costs = [0.0, 0.0]
            for position in range(count - 1):
                current = order[position]
                following = order[position + 1]
                updated = [float('inf'), float('inf')]
                for free_end in range(2):
                    for joining_end in range(2):
                        candidate = costs[free_end] + distance(
                            endpoint(segments, current, free_end),
                            endpoint(segments, following, joining_end))
                        other_end = 1 - joining_end
                        if candidate < updated[other_end]:
                            updated[other_end] = candidate
                costs = updated
            best = min(best, original + min(costs))
        answers.append('Case {}: {:.5f}'.format(case_number, best))
    return ''.join(answer + '\n' for answer in answers)


SAMPLE_IN = '''4
0 1 0 9
10 1 10 9
1 0 9 0
1 10 9 10
2
1.2 3.4 5.6 7.8
5.6 3.4 1.2 7.8
0
'''
SAMPLE_OUT = '''Case 1: 36.24264
Case 2: 16.84508
'''
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle('2\n0 0 1 0\n0 1 1 1\n0\n') == 'Case 1: 3.00000\n'
assert oracle('2\n0 0 2 0\n0 2 2 2\n0\n') == 'Case 1: 6.00000\n'
assert distance((0.0, 0.0), (3.0, 4.0)) == 5.0
assert math.sqrt(2) * 3 + 32 < 36.24265


def write(name, cases):
    lines = []
    for segments in cases:
        lines.append(str(len(segments)))
        lines.extend('{} {} {} {}'.format(first[0], first[1], second[0], second[1])
                     for first, second in segments)
    lines.append('0')
    text = '\n'.join(lines) + '\n'
    (ROOT / 'in' / '{}.txt'.format(name)).write_text(text)
    (ROOT / 'out' / '{}.out'.format(name)).write_text(oracle(text))


def build():
    write('2_edges', [
        [[(0.0, 0.0), (1.0, 0.0)]],
        [[(0.0, 0.0), (1.0, 0.0)], [(0.0, 1.0), (1.0, 1.0)]],
        [[(0.0, 0.0), (2.0, 0.0)], [(0.0, 2.0), (2.0, 2.0)],
         [(0.0, 4.0), (2.0, 4.0)]],
    ])
    write('3_wide', [
        [[(float(column), float(row)), (float(column + 20), float(row))]
         for row in range(4) for column in range(2)],
    ])
    rng = random.Random(20261126)
    cases = []
    for _ in range(30):
        segments = []
        for _ in range(rng.randint(2, 7)):
            first = (rng.randint(-100, 100) / 2, rng.randint(-100, 100) / 2)
            second = (rng.randint(-100, 100) / 2, rng.randint(-100, 100) / 2)
            segments.append((first, second))
        cases.append(segments)
    write('4_random', cases)
    cases = []
    for _ in range(200):
        segments = []
        for _ in range(6):
            first = (rng.randint(-100, 100), rng.randint(-100, 100))
            second = (rng.randint(-100, 100), rng.randint(-100, 100))
            segments.append((first, second))
        cases.append(segments)
    write('5_io', cases)


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
(ROOT / 'in' / '1_sample.txt').write_text(SAMPLE_IN)
(ROOT / 'out' / '1_sample.out').write_text(SAMPLE_OUT)
build()
