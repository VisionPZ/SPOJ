#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1000000007


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    cursor = 1
    answers = []
    for _ in range(case_count):
        people = int(tokens[cursor])
        edges = int(tokens[cursor + 1])
        cursor += 2
        parent = list(range(people))

        def find(person):
            while parent[person] != person:
                person = parent[person]
            return person

        for _ in range(edges):
            first = int(tokens[cursor]) - 1
            second = int(tokens[cursor + 1]) - 1
            cursor += 2
            first_root = find(first)
            second_root = find(second)
            if first_root != second_root:
                parent[first_root] = second_root
        component = [find(person) for person in range(people)]
        good = 0
        for arrangement in itertools.permutations(range(people)):
            for index in range(people - 1):
                if component[arrangement[index]] == component[arrangement[index + 1]]:
                    good += 1
                    break
        answers.append(f"Case #{len(answers) + 1}: {good % MODULUS}")
    return "\n".join(answers) + "\n"


SAMPLE = """3
2 1
2 1
3 2
2 1
1 3
4 0
"""
SAMPLE_OUT = """Case #1: 2
Case #2: 6
Case #3: 0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 0\n") == "Case #1: 0\n"
assert oracle("1\n3 2\n1 2\n2 3\n") == "Case #1: 6\n"
assert oracle("1\n4 1\n1 2\n") == "Case #1: 12\n"


def write(name, cases):
    parts = [str(len(cases))]
    for people, edges in cases:
        parts.append(f"{people} {len(edges)}")
        for first, second in edges:
            parts.append(f"{first} {second}")
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(2, []), (2, [(1, 2)]), (3, []), (3, [(1, 2)]), (3, [(1, 2), (2, 3)])])
    write("3_wide", [(8, [(1, 3), (3, 5), (2, 4), (4, 8)]),
                     (8, [(1, 2), (3, 4), (5, 6), (7, 8)]),
                     (8, [(index, index + 1) for index in range(1, 8)])])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(12):
        people = rng.randint(2, 8)
        edges = []
        for _ in range(rng.randint(0, 10)):
            first = rng.randint(1, people)
            second = rng.randint(1, people)
            if first != second:
                edges.append((first, second))
        random_cases.append((people, edges))
    write("4_random", random_cases)
    io_cases = [(7, [(1, 2), (3, 4), (5, 6)]) for _ in range(120)]
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
