#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    data_set_count = tokens[position]
    position += 1
    answers = []
    for _ in range(data_set_count):
        people_count = tokens[position]
        position += 1
        matrix = []
        for row_index in range(people_count):
            start = position + row_index * people_count
            matrix.append(tokens[start:start + people_count])
        position += people_count * people_count
        answer = 0
        for person_index in range(people_count):
            knows_only_self = all(
                matrix[person_index][other_index] == (1 if other_index == person_index else 0)
                for other_index in range(people_count)
            )
            known_by_all = all(matrix[other_index][person_index] == 1 for other_index in range(people_count))
            if knows_only_self and known_by_all:
                answer = person_index + 1
                break
        answers.append(str(answer))
    return "\n".join(answers) + "\n"


SAMPLE = """2
3
1 0 1
1 1 1
0 0 1
5
1 0 0 1 1
1 1 0 1 0
0 0 1 1 1
0 0 0 1 0
1 1 0 1 1
"""
SAMPLE_OUT = """3
4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n1\n") == "1\n"
assert oracle("1\n2\n1 1\n0 1\n") == "2\n"
assert oracle("1\n4\n1 0 1 1\n1 1 1 1\n0 0 1 0\n0 0 1 1\n") == "3\n"


def make_matrix(people_count, vip_index, rng):
    matrix = [[0] * people_count for _ in range(people_count)]
    for index in range(people_count):
        matrix[index][index] = 1
    for index in range(people_count):
        if index != vip_index:
            matrix[index][vip_index] = 1
    for row_index in range(people_count):
        if row_index != vip_index:
            for column_index in range(people_count):
                if column_index not in (row_index, vip_index):
                    matrix[row_index][column_index] = rng.randint(0, 1)
    return matrix


def write(name, datasets):
    lines = [str(len(datasets))]
    for matrix in datasets:
        lines.append(str(len(matrix)))
        for row in matrix:
            lines.append(" ".join(str(value) for value in row))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


SAMPLE_FIRST = [[1, 0, 1], [1, 1, 1], [0, 0, 1]]
SAMPLE_SECOND = [
    [1, 0, 0, 1, 1],
    [1, 1, 0, 1, 0],
    [0, 0, 1, 1, 1],
    [0, 0, 0, 1, 0],
    [1, 1, 0, 1, 1],
]


def build():
    rng = random.Random(20261126)
    write("2_edges", [[[1]]])
    write("3_wide", [make_matrix(500, 499, rng), make_matrix(100, 0, rng)])
    random_datasets = []
    for _ in range(10):
        random_people = rng.randint(1, 50)
        random_datasets.append(make_matrix(random_people, rng.randrange(random_people), rng))
    write("4_random", random_datasets)
    write("5_io", [make_matrix(50, rng.randrange(50), rng) for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [SAMPLE_FIRST, SAMPLE_SECOND])
build()
