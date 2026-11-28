#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    test_count = tokens[cursor]
    cursor += 1
    answer_lines = []
    for _ in range(test_count):
        array_size = tokens[cursor]
        cursor += 1
        relations = tokens[cursor:cursor + array_size - 1]
        cursor += array_size - 1
        values = [1] * array_size
        while True:
            changed = False
            for index in range(array_size - 1):
                relation = relations[index]
                if relation == 0:
                    target = max(values[index], values[index + 1])
                    if values[index] != target:
                        values[index] = target
                        changed = True
                    if values[index + 1] != target:
                        values[index + 1] = target
                        changed = True
                elif relation == 1:
                    target = values[index] + 1
                    if values[index + 1] < target:
                        values[index + 1] = target
                        changed = True
                else:
                    target = values[index + 1] + 1
                    if values[index] < target:
                        values[index] = target
                        changed = True
            if not changed:
                break
        answer_lines.append(" ".join(str(value) for value in values))
    return "\n".join(answer_lines) + "\n"


def brute(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    test_count = tokens[cursor]
    cursor += 1
    answer_lines = []
    for _ in range(test_count):
        array_size = tokens[cursor]
        cursor += 1
        relations = tokens[cursor:cursor + array_size - 1]
        cursor += array_size - 1
        limit = array_size + 2

        def search(prefix):
            if len(prefix) == array_size:
                return prefix[:]
            for value in range(1, limit + 1):
                if prefix:
                    previous = prefix[-1]
                    relation = relations[len(prefix) - 1]
                    if relation == 0 and value != previous:
                        continue
                    if relation == 1 and value <= previous:
                        continue
                    if relation == 2 and value >= previous:
                        continue
                candidate = search(prefix + [value])
                if candidate is not None:
                    return candidate
            return None

        found = search([])
        answer_lines.append(" ".join(str(value) for value in found))
    return "\n".join(answer_lines) + "\n"


SAMPLE = """1
5
1 2 0 1
"""
SAMPLE_OUT = """1 2 1 1 2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n") == "1\n"
assert oracle("1\n2\n2\n") == "2 1\n"
assert oracle("1\n3\n1 1\n") == "1 2 3\n"
assert oracle("1\n4\n2 2 2\n") == "4 3 2 1\n"
assert oracle("1\n7\n1 0 1 2 1 1\n") == "1 2 2 3 1 2 3\n"
for seed in range(60):
    rng_check = random.Random(seed)
    size_check = rng_check.randint(1, 6)
    relations_check = [rng_check.randint(0, 2) for _ in range(size_check - 1)]
    case_text = "1\n" + str(size_check) + "\n" + " ".join(map(str, relations_check)) + "\n"
    assert oracle(case_text) == brute(case_text)


def write(name, cases):
    parts = [str(len(cases))]
    for size, relations in cases:
        parts.append(str(size))
        parts.extend(str(value) for value in relations)
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, []), (2, [0]), (2, [1]), (2, [2]), (3, [2, 2]), (3, [1, 1])])
    write("3_wide", [(40, [2] * 39), (40, [1] * 39), (40, [0] * 39)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(20):
        size = rng.randint(1, 40)
        random_cases.append((size, [rng.randint(0, 2) for _ in range(size - 1)]))
    write("4_random", random_cases)
    write("5_io", [(100, [2] * 99), (100, [1] * 99), (100, [0] * 99)])
    large_relations = [1 if index % 2 == 0 else 2 for index in range(99999)]
    (Path("/tmp") / "MOZSATLA_big.txt").write_text(
        "1\n100000\n" + " ".join(str(value) for value in large_relations) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
