#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def parse_cases(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    cases = []
    while True:
        knight_count = tokens[cursor]
        pair_count = tokens[cursor + 1]
        cursor += 2
        if knight_count == 0 and pair_count == 0:
            break
        hate = [[False] * knight_count for _ in range(knight_count)]
        for _ in range(pair_count):
            first = tokens[cursor] - 1
            second = tokens[cursor + 1] - 1
            cursor += 2
            hate[first][second] = True
            hate[second][first] = True
        cases.append(hate)
    return cases


def oracle(text):
    answers = []
    for hate in parse_cases(text):
        knight_count = len(hate)
        friends = [[not hate[first][second] and first != second
                    for second in range(knight_count)] for first in range(knight_count)]
        neighbors = [[other for other in range(knight_count) if friends[current][other]]
                     for current in range(knight_count)]
        expelled = 0
        for start in range(knight_count):
            found = [False]

            def walk(current, visited, length):
                if found[0]:
                    return
                for following in neighbors[current]:
                    if following == start:
                        if length >= 3 and length % 2 == 1:
                            found[0] = True
                            return
                    elif not (visited >> following) & 1:
                        walk(following, visited | (1 << following), length + 1)
                        if found[0]:
                            return

            walk(start, 1 << start, 1)
            if not found[0]:
                expelled += 1
        answers.append(str(expelled))
    return "\n".join(answers) + "\n"


SAMPLE = """5 5
1 4
1 5
2 5
3 4
4 5
0 0
"""
SAMPLE_OUT = """2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3 0\n0 0\n") == "0\n"
assert oracle("3 3\n1 2\n1 3\n2 3\n0 0\n") == "3\n"
assert oracle("4 3\n1 4\n2 4\n3 4\n0 0\n") == "1\n"
assert oracle("4 2\n3 4\n4 1\n0 0\n") == "1\n"


def format_case(hate):
    knight_count = len(hate)
    pairs = []
    for first in range(knight_count):
        for second in range(first + 1, knight_count):
            if hate[first][second]:
                pairs.append((first + 1, second + 1))
    text = f"{knight_count} {len(pairs)}\n"
    text += "".join(f"{first} {second}\n" for first, second in pairs)
    return text


def write(name, cases):
    text = "".join(format_case(hate) for hate in cases) + "0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_hate(rng, knight_count, probability):
    hate = [[False] * knight_count for _ in range(knight_count)]
    for first in range(knight_count):
        for second in range(first + 1, knight_count):
            if rng.random() < probability:
                hate[first][second] = True
                hate[second][first] = True
    return hate


def build():
    write("2_edges", [
        [[False]],
        [[True]],
        [[False, False, False], [False, False, False], [False, False, False]],
        [[True, True, True], [True, True, True], [True, True, True]],
        [[False] * 4 for _ in range(4)],
    ])
    rng = random.Random(20261130)
    write("3_wide", [random_hate(rng, 20, 0.55)])
    write("4_random", [random_hate(rng, rng.randint(4, 18), rng.uniform(0.2, 0.8))
                       for _ in range(6)])
    write("5_io", [random_hate(rng, rng.randint(3, 12), rng.uniform(0.2, 0.8))
                   for _ in range(180)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    [[False, False, False, True, True],
     [False, False, False, False, True],
     [False, False, False, True, False],
     [True, False, True, False, True],
     [True, True, False, True, False]],
])
build()
