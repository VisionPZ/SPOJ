#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def floyd_warshall(matrix, size):
    dist = [row[:] for row in matrix]
    for k in range(size):
        row_k = dist[k]
        for i in range(size):
            row_i = dist[i]
            via = row_i[k]
            for j in range(size):
                candidate = via + row_k[j]
                if candidate < row_i[j]:
                    row_i[j] = candidate
    return dist


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answer = []
    for case_index in range(case_count):
        size = int(tokens[cursor]); cursor += 1
        matrix = []
        for _ in range(size):
            row = [int(tokens[cursor + offset]) for offset in range(size)]
            cursor += size
            matrix.append(row)
        dist = floyd_warshall(matrix, size)
        blocked = [[False] * size for _ in range(size)]
        for k in range(size):
            for i in range(size):
                if i == k:
                    continue
                row_k = dist[k]
                for j in range(i + 1, size):
                    if j == k:
                        continue
                    if dist[i][k] + row_k[j] == dist[i][j]:
                        blocked[i][j] = True
        for i in range(size):
            for j in range(i + 1, size):
                if not blocked[i][j]:
                    answer.append(f"{i + 1} {j + 1}\n")
        if case_index != case_count - 1:
            answer.append("\n")
    return "".join(answer)


def brute(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answer = []
    for case_index in range(case_count):
        size = int(tokens[cursor]); cursor += 1
        matrix = []
        for _ in range(size):
            row = [int(tokens[cursor + offset]) for offset in range(size)]
            cursor += size
            matrix.append(row)
        for i in range(size):
            for j in range(i + 1, size):
                if all(k in (i, j) or matrix[i][k] + matrix[k][j] != matrix[i][j]
                       for k in range(size)):
                    answer.append(f"{i + 1} {j + 1}\n")
        if case_index != case_count - 1:
            answer.append("\n")
    return "".join(answer)


def line_metric(coordinates):
    return [[abs(left - right) for right in coordinates] for left in coordinates]


def unit_metric(size):
    return [[0 if i == j else 1 for j in range(size)] for i in range(size)]


def write(name, matrices):
    input_lines = [str(len(matrices))]
    for matrix in matrices:
        input_lines.append(str(len(matrix)))
        for row in matrix:
            input_lines.append(" ".join(str(value) for value in row))
    input_text = "\n".join(input_lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE = [[0, 1, 2], [1, 0, 3], [2, 3, 0]]
assert oracle("1\n3\n0 1 2\n1 0 3\n2 3 0\n") == "1 2\n1 3\n"
assert oracle("1\n1\n0\n") == ""
assert oracle("1\n2\n0 5\n5 0\n") == "1 2\n"
assert oracle("1\n3\n0 1 1\n1 0 1\n1 1 0\n") == "1 2\n1 3\n2 3\n"
assert oracle("1\n3\n0 4 9\n4 0 5\n9 5 0\n") == "1 2\n2 3\n"
assert oracle("2\n2\n0 7\n7 0\n1\n0\n") == "1 2\n\n"

random.seed(1780)
for trial in range(40):
    size = random.randint(1, 8)
    coords = sorted(random.sample(range(0, 30), size))
    text = str(1) + "\n" + str(size) + "\n"
    for row in line_metric(coords):
        text += " ".join(str(value) for value in row) + "\n"
    assert oracle(text) == brute(text)


def build():
    write("2_edges", [
        [[0]],
        [[0, 5], [5, 0]],
        [[0, 0], [0, 0]],
        SAMPLE,
        unit_metric(3),
        line_metric([0, 4, 9]),
        line_metric([0, 1, 3]),
    ])
    write("3_wide", [unit_metric(200), line_metric(list(range(200)))])
    random.seed(2004)
    wide_matrices = []
    for _ in range(10):
        size = random.randint(2, 70)
        coordinates = sorted(random.sample(range(0, 101), size))
        wide_matrices.append(line_metric(coordinates))
    write("4_random", wide_matrices)
    write("5_io", [unit_metric(200) for _ in range(6)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [SAMPLE])
build()
