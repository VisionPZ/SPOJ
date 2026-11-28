#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        count = int(tokens[cursor]); cursor += 1
        sticks = [
            (int(tokens[cursor + 2 * index]), int(tokens[cursor + 2 * index + 1]))
            for index in range(count)
        ]
        cursor += 2 * count
        sticks.sort()
        visited = [False] * count
        setups = 0
        for index in range(count):
            if visited[index]:
                continue
            setups += 1
            visited[index] = True
            last_length, last_weight = sticks[index]
            for later in range(index + 1, count):
                if not visited[later] and sticks[later][0] >= last_length \
                        and sticks[later][1] >= last_weight:
                    visited[later] = True
                    last_length, last_weight = sticks[later]
        answers.append(str(setups))
    return "\n".join(answers) + "\n"


SAMPLE = """3
5
4 9 5 2 2 1 3 5 1 4
3
2 2 1 1 2 2
3
1 3 2 2 3 1
"""
SAMPLE_OUT = """2
1
3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n7 7\n") == "1\n"
assert oracle("1\n5\n1 1\n1 1\n1 1\n1 1\n1 1\n") == "1\n"
assert oracle("1\n3\n1 3 2 2 3 1\n") == "3\n"
assert oracle("1\n5\n4 9 5 2 2 1 3 5 1 4\n") == "2\n"


def write(name, cases):
    chunks = [str(len(cases)) + "\n"]
    for sticks in cases:
        chunks.append(str(len(sticks)) + "\n")
        chunks.append(" ".join(str(value) for pair in sticks for value in pair) + "\n")
    text = "".join(chunks)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[(1, 1)], [(5, 5), (5, 5), (5, 5)],
                      [(3, 3), (2, 2), (1, 1)], [(1, 9), (9, 1), (5, 5)],
                      [(4, 9), (5, 2), (2, 1), (3, 5), (1, 4)]])
    rng = random.Random(20261126)
    write("3_wide", [
        [(rng.randint(1, 10000), rng.randint(1, 10000)) for _ in range(300)]
        for _ in range(3)
    ])
    write("4_random", [
        [(rng.randint(1, 10000), rng.randint(1, 10000))
         for _ in range(rng.randint(1, 120))]
        for _ in range(60)
    ])
    write("5_io", [[(rng.randint(1, 10000), rng.randint(1, 10000))]
                   for _ in range(20000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
