#!/usr/bin/env python3
import random
from collections import deque
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1000000007


def solve_case(home, objects):
    count = len(objects)
    places = [0] + [item[1] for item in objects]
    start = (1, ())
    queue = deque([start])
    states = {start}
    while queue:
        index, stack = queue.popleft()
        if index > count:
            continue
        kind = objects[index - 1][0]
        next_states = [(index + 1, stack)]
        if kind == 'F':
            next_states.append((index + 1, stack + (index,)))
        elif stack:
            top = stack[-1]
            lower = stack[:-1]
            next_states.append((top + 1, lower + (top,)))
            next_states.append((top + 1, lower))
        else:
            next_states.append((1, ()))
        for state in next_states:
            if state not in states:
                states.add(state)
                queue.append(state)
    states = sorted(states)
    lookup = {state: row for row, state in enumerate(states)}
    size = len(states)
    matrix = [[Fraction(0) for _ in range(size + 1)] for _ in range(size)]
    for state in states:
        row = lookup[state]
        index, stack = state
        matrix[row][row] = Fraction(1)
        if index > count:
            matrix[row][size] = home - places[count]
            continue
        distance = places[index] - places[index - 1]
        kind, _, numerator, denominator = objects[index - 1]
        chance = Fraction(numerator, denominator)
        matrix[row][size] += distance
        if kind == 'F':
            matrix[row][lookup[(index + 1, stack + (index,))]] -= chance
            matrix[row][lookup[(index + 1, stack)]] -= 1 - chance
        else:
            matrix[row][lookup[(index + 1, stack)]] -= chance
            if stack:
                top = stack[-1]
                lower = stack[:-1]
                retry = Fraction(objects[top - 1][2], objects[top - 1][3])
                matrix[row][lookup[(top + 1, lower + (top,))]] -= (1 - chance) * retry
                matrix[row][lookup[(top + 1, lower)]] -= (1 - chance) * (1 - retry)
            else:
                matrix[row][lookup[(1, ())]] -= 1 - chance
    for column in range(size):
        pivot = next((row for row in range(column, size) if matrix[row][column] != 0), None)
        matrix[column], matrix[pivot] = matrix[pivot], matrix[column]
        scale = matrix[column][column]
        matrix[column] = [value / scale for value in matrix[column]]
        for row in range(size):
            if row == column or matrix[row][column] == 0:
                continue
            factor = matrix[row][column]
            matrix[row] = [matrix[row][col] - factor * matrix[column][col]
                           for col in range(size + 1)]
    return matrix[lookup[start]][size]


def oracle(text):
    tokens = text.split()
    pos = 0
    results = []
    while True:
        home = int(tokens[pos])
        count = int(tokens[pos + 1])
        pos += 2
        if home == 0 and count == 0:
            break
        objects = []
        for _ in range(count):
            kind = tokens[pos]
            place = int(tokens[pos + 1])
            numerator = int(tokens[pos + 2])
            denominator = int(tokens[pos + 3])
            pos += 4
            objects.append((kind, place, numerator, denominator))
        expected = solve_case(home, objects)
        assert expected.denominator == 1
        results.append(str(expected.numerator % MODULUS))
    return "\n".join(results) + "\n"


SAMPLE = ("32 0\n32 1\nX 16 1 2\n32 2\nF 8 1 1\nX 16 1 2\n"
          "32 2\nF 8 1 2\nX 16 1 2\n0 0\n")
SAMPLE_OUT = "32\n48\n40\n44\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("10 0\n0 0\n") == "10\n"
assert oracle("16 1\nX 8 1 1\n0 0\n") == "16\n"
assert oracle("16 1\nX 8 1 2\n0 0\n") == "24\n"
assert Fraction(3, 1).denominator == 1


def write(name, cases):
    chunks = []
    for home, objects in cases:
        chunks.append(f"{home} {len(objects)}")
        for kind, place, numerator, denominator in objects:
            chunks.append(f"{kind} {place} {numerator} {denominator}")
    chunks.append("0 0")
    text = "\n".join(chunks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def make_case(rng, large):
    count = rng.randint(0, 5)
    if large:
        places = sorted(rng.sample(range(1, 10**18), count)) if count else []
        home = max(places) + rng.randint(1, 10**17) if places else 10**18
    else:
        places = sorted(rng.sample(range(1, 60), count)) if count else []
        home = max(places) + rng.randint(1, 20) if places else rng.randint(1, 60)
    objects = []
    for place in places:
        kind = rng.choice('FX')
        if rng.random() < 0.4:
            numerator, denominator = 1, 1
        else:
            denominator = rng.choice([2, 3, 4])
            numerator = rng.randint(1, denominator)
        objects.append((kind, place, numerator, denominator))
    return home, objects


def accepted_cases(rng, amount, large=False):
    cases = []
    attempts = 0
    while len(cases) < amount and attempts < amount * 30:
        attempts += 1
        case = make_case(rng, large)
        expected = solve_case(*case)
        if expected.denominator == 1:
            cases.append(case)
    assert len(cases) == amount
    return cases


def build():
    rng = random.Random(20261125)
    edges = [(5, []), (16, [('F', 8, 1, 1)]), (16, [('X', 8, 1, 2)]),
             (20, [('X', 6, 1, 2), ('X', 12, 1, 2)]),
             (24, [('F', 6, 1, 1), ('X', 12, 1, 2)])]
    write("2_edges", edges)
    write("3_wide", accepted_cases(rng, 12, True))
    write("4_random", accepted_cases(rng, 20))
    write("5_io", accepted_cases(rng, 100))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(32, []), (32, [('X', 16, 1, 2)]),
                   (32, [('F', 8, 1, 1), ('X', 16, 1, 2)]),
                   (32, [('F', 8, 1, 2), ('X', 16, 1, 2)])])
build()
