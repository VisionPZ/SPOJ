#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
ALPHABET = "abcdef"


def palindrome_ways(letters):
    return sum(1 for item in set(itertools.permutations(letters))
               if list(item) == list(item)[::-1])


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        current = list(tokens[cursor])
        cursor += 1
        query_count = int(tokens[cursor])
        cursor += 1
        for _ in range(query_count):
            kind = tokens[cursor]
            left = int(tokens[cursor + 1]) - 1
            right = int(tokens[cursor + 2]) - 1
            cursor += 3
            if kind == "U":
                current[left:right + 1] = sorted(current[left:right + 1])
            else:
                answers.append(str(palindrome_ways(current[left:right + 1])))
        answers.append("".join(current))
    return "\n".join(answers) + "\n"


SAMPLE = """2
nittirichy
3
Q 2 5
U 1 4
Q 1 5
shabba
5
Q 2 3
Q 2 6
U 1 4
Q 2 5
Q 1 6
"""
SAMPLE_OUT = """2
2
inttirichy
0
2
0
0
abhsba
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert palindrome_ways("itti") == 2
assert palindrome_ways("ha") == 0
assert palindrome_ways("aaaa") == 1


def write(name, cases):
    lines = [str(len(cases))]
    for text, queries in cases:
        lines.append(text)
        lines.append(str(len(queries)))
        lines.extend(f"{kind} {left} {right}" for kind, left, right in queries)
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    rng = random.Random(20261126)
    write("2_edges", [
        ("a", [("Q", 1, 1), ("U", 1, 1), ("Q", 1, 1)]),
        ("ab", [("Q", 1, 2), ("U", 1, 2), ("Q", 1, 2)]),
        ("aabb", [("Q", 1, 4), ("U", 2, 4), ("Q", 2, 4)]),
        ("zzzz", [("Q", 1, 4), ("U", 1, 4), ("Q", 2, 3)]),
        ("abcabc", [("Q", 2, 5), ("U", 3, 6), ("Q", 2, 5)]),
    ])

    wide_text = "".join(rng.choice(ALPHABET) for _ in range(50000))
    wide_queries = [("Q", 100, 105), ("U", 1, 50000), ("Q", 200, 205),
                    ("U", 25000, 30000), ("Q", 40000, 40005)]
    write("3_wide", [(wide_text, wide_queries)])

    cases = []
    for _ in range(3):
        text = "".join(rng.choice(ALPHABET) for _ in range(rng.randint(5, 60)))
        queries = []
        for _ in range(25):
            left = rng.randint(1, len(text))
            if rng.random() < 0.5:
                right = min(len(text), left + rng.randint(0, 5))
                queries.append(("Q", left, right))
            else:
                right = rng.randint(left, len(text))
                queries.append(("U", left, right))
        cases.append((text, queries))
    write("4_random", cases)

    cases = []
    for _ in range(2):
        text = "".join(rng.choice(ALPHABET) for _ in range(50000))
        queries = []
        for query_index in range(2000):
            if query_index % 10 == 0:
                left = rng.randint(1, len(text) - 5)
                queries.append(("Q", left, left + rng.randint(0, 5)))
            else:
                left = rng.randint(1, len(text))
                right = rng.randint(left, len(text))
                queries.append(("U", left, right))
        cases.append((text, queries))
    write("5_io", cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
