#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def feasible(matrix, hole_count, needed, digging, deadline):
    slot_count = 2 * hole_count
    used = [False] * slot_count

    def search(hobbit_index, assigned):
        if assigned >= needed:
            return True
        if hobbit_index >= len(matrix) or len(matrix) - hobbit_index + assigned < needed:
            return False
        for slot_index in range(slot_count):
            if used[slot_index]:
                continue
            hole_index = slot_index // 2
            arrival = matrix[hobbit_index][hole_index]
            limit = deadline if slot_index % 2 == 0 else deadline - digging
            if arrival > limit:
                continue
            used[slot_index] = True
            if search(hobbit_index + 1, assigned + 1):
                return True
            used[slot_index] = False
        return search(hobbit_index + 1, assigned)

    return search(0, 0)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_total = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_total):
        hobbit_count = tokens[cursor]
        hole_count = tokens[cursor + 1]
        needed = tokens[cursor + 2]
        digging = tokens[cursor + 3]
        cursor += 4
        matrix = []
        for _ in range(hobbit_count):
            matrix.append(tokens[cursor:cursor + hole_count])
            cursor += hole_count
        candidates = {0}
        for row in matrix:
            for arrival in row:
                candidates.add(arrival)
                candidates.add(arrival + digging)
        answer = max(candidates)
        for deadline in sorted(candidates):
            if feasible(matrix, hole_count, needed, digging, deadline):
                answer = deadline
                break
        answers.append(str(answer))
    return "\n".join(answers) + "\n"


SAMPLE = """2
3 3 2 10
9 11 13
2 10 14
12 15 12
4 3 3 8
1 10 100
1 10 100
100 100 6
12 10 10
"""
SAMPLE_OUT = """10
9
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1 1 5\n7\n") == "7\n"
assert oracle("1\n2 1 2 5\n3\n4\n") == "8\n"
assert oracle("1\n3 3 1 100\n50 60 70\n80 90 100\n110 120 130\n") == "50\n"
assert oracle("1\n4 2 4 7\n1 20\n2 21\n3 22\n4 23\n") == "27\n"


def write(name, cases):
    text = str(len(cases)) + "\n"
    for matrix, needed, digging in cases:
        hobbit_count = len(matrix)
        hole_count = len(matrix[0])
        text += f"{hobbit_count} {hole_count} {needed} {digging}\n"
        text += "".join(" ".join(str(value) for value in row) + "\n" for row in matrix)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [([[5]], 1, 100)])
    write("3_wide", [([[10000000 - index - 1 for index in range(5)] for _ in range(5)], 5, 9999999)])
    rng = random.Random(20261126)
    cases = []
    for _ in range(5):
        hobbit_count = rng.randrange(2, 6)
        hole_count = rng.randrange(2, 5)
        matrix = [[rng.randrange(1, 60) for _ in range(hole_count)]
                  for _ in range(hobbit_count)]
        needed = rng.randrange(1, min(hobbit_count, 2 * hole_count) + 1)
        cases.append((matrix, needed, rng.randrange(1, 20)))
    write("4_random", cases)
    cases = []
    for _ in range(6):
        matrix = [[rng.randrange(1, 10000000) for _ in range(5)] for _ in range(5)]
        cases.append((matrix, 5, rng.randrange(1, 10000000)))
    write("5_io", cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [([[9, 11, 13], [2, 10, 14], [12, 15, 12]], 2, 10),
                   ([[1, 10, 100], [1, 10, 100], [100, 100, 6], [12, 10, 10]], 3, 8)])
build()
