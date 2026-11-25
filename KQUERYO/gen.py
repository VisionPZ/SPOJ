#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    element_count = tokens[cursor]
    cursor += 1
    values = tokens[cursor:cursor + element_count]
    cursor += element_count
    query_count = tokens[cursor]
    cursor += 1
    answers = []
    last_answer = 0
    for _ in range(query_count):
        raw_left = tokens[cursor]
        raw_right = tokens[cursor + 1]
        raw_threshold = tokens[cursor + 2]
        cursor += 3
        query_left = raw_left ^ last_answer
        query_right = raw_right ^ last_answer
        threshold = raw_threshold ^ last_answer
        if query_left < 1:
            query_left = 1
        if query_right > element_count:
            query_right = element_count
        if query_left > query_right:
            answer = 0
        else:
            answer = sum(1 for value in values[query_left - 1:query_right]
                         if value > threshold)
        answers.append(str(answer))
        last_answer = answer
    return "\n".join(answers) + ("\n" if answers else "")


SAMPLE = """6
8 9 3 5 1 9
5
2 3 5
3 3 7
0 0 11
0 0 2
3 7 4
"""
SAMPLE_OUT = """1
1
0
0
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3\n1 2 3\n1\n3 3 0\n") == "1\n"
assert oracle("3\n1 2 3\n1\n3 3 3\n") == "0\n"
assert oracle("3\n1 2 3\n2\n1 3 1\n0 0 0\n") == "2\n0\n"
assert oracle("2\n5 5\n1\n1 2 4\n") == "2\n"


def encode(values, decoded_queries):
    lines = [str(len(values)), " ".join(str(value) for value in values),
             str(len(decoded_queries))]
    last_answer = 0
    for query_left, query_right, threshold in decoded_queries:
        for raw in (query_left ^ last_answer, query_right ^ last_answer,
                    threshold ^ last_answer):
            lines.append(str(raw))
        segment = values[query_left - 1:query_right]
        last_answer = sum(1 for value in segment if value > threshold)
    return "\n".join(lines) + "\n"


def write(name, values, decoded_queries, verbatim=None):
    input_text = verbatim if verbatim is not None else encode(values, decoded_queries)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [1, 1, 1], [(1, 3, 0), (2, 2, 1), (1, 3, 9)])
    write("3_wide", list(range(1, 101)),
          [(1, 100, 50), (25, 75, 25), (1, 1, 100), (100, 100, 0)])
    rng = random.Random(20261126)
    values = [rng.randint(1, 1000) for _ in range(60)]
    decoded_queries = []
    for _ in range(200):
        query_left = rng.randint(1, 60)
        query_right = rng.randint(query_left, 60)
        threshold = rng.randint(0, 1000)
        decoded_queries.append((query_left, query_right, threshold))
    write("4_random", values, decoded_queries)
    values = [rng.randint(1, 10**9) for _ in range(200)]
    decoded_queries = []
    for _ in range(2000):
        query_left = rng.randint(1, 200)
        query_right = rng.randint(query_left, 200)
        threshold = rng.randint(1, 10**9)
        decoded_queries.append((query_left, query_right, threshold))
    write("5_io", values, decoded_queries)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [8, 9, 3, 5, 1, 9], [], verbatim=SAMPLE)
build()
