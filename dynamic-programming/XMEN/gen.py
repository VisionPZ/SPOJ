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
        element_total = tokens[cursor]
        cursor += 1
        first = tokens[cursor:cursor + element_total]
        cursor += element_total
        second = tokens[cursor:cursor + element_total]
        cursor += element_total
        table = [[0] * (element_total + 1) for _ in range(element_total + 1)]
        for left in range(1, element_total + 1):
            for right in range(1, element_total + 1):
                if first[left - 1] == second[right - 1]:
                    table[left][right] = table[left - 1][right - 1] + 1
                else:
                    table[left][right] = max(table[left - 1][right],
                                             table[left][right - 1])
        answers.append(str(table[element_total][element_total]))
    return "\n".join(answers) + "\n"


SAMPLE = """2
2
1 2
2 1
3
1 2 3
1 3 2
"""
SAMPLE_OUT = """1
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n1\n1\n") == "1\n"
assert oracle("1\n4\n1 2 3 4\n1 2 3 4\n") == "4\n"
assert oracle("1\n4\n1 2 3 4\n4 3 2 1\n") == "1\n"


def render(cases):
    parts = [str(len(cases))]
    for first, second in cases:
        parts.append(str(len(first)))
        parts.append(" ".join(str(value) for value in first))
        parts.append(" ".join(str(value) for value in second))
    return "\n".join(parts) + "\n"


def write(name, cases):
    text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    identity = list(range(1, 6))
    two_reversed = [2, 1]
    four_reversed = [4, 3, 2, 1]
    write("2_edges", [([1], [1]), (identity[:2], two_reversed),
                      (identity[:4], identity[:4]), (identity[:4], four_reversed)])
    rng = random.Random(20261131)
    wide_first = list(range(1, 61))
    wide_second = wide_first[:]
    rng.shuffle(wide_second)
    write("3_wide", [(wide_first, wide_second)])
    random_cases = []
    for _ in range(20):
        length = rng.randint(1, 50)
        first = list(range(1, length + 1))
        second = first[:]
        rng.shuffle(second)
        random_cases.append((first, second))
    write("4_random", random_cases)
    many = []
    for _ in range(10):
        first = list(range(1, 61))
        second = first[:]
        rng.shuffle(second)
        many.append((first, second))
    write("5_io", many)
    big = random.Random(9283750)
    huge = []
    for _ in range(10):
        first = list(range(1, 100001))
        second = first[:]
        big.shuffle(second)
        huge.append((first, second))
    Path("/tmp/XMEN_big.txt").write_text(render(huge))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [([1, 2], [2, 1]), ([1, 2, 3], [1, 3, 2])])
build()
