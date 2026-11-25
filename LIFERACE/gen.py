#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def build_golomb(limit):
    sequence = [0, 1, 2, 2]
    value = 3
    while len(sequence) - 1 < limit:
        sequence.extend([value] * sequence[value])
        value += 1
    return sequence


def oracle(text):
    tokens = [int(value) for value in text.split()]
    update_count = tokens[0]
    query_count = tokens[1]
    position = 2
    updates = []
    queries = []
    largest = 1
    for _ in range(update_count):
        left, right, amount = tokens[position:position + 3]
        position += 3
        if left > right:
            left, right = right, left
        updates.append((left, right, amount))
        largest = max(largest, right)
    for _ in range(query_count):
        left, right = tokens[position:position + 2]
        position += 2
        if left > right:
            left, right = right, left
        queries.append((left, right))
        largest = max(largest, right)
    golomb = build_golomb(largest ** 3)
    increments = [0] * (largest + 2)
    for left, right, amount in updates:
        for person in range(left, right + 1):
            increments[person] += amount
    prefix = [0] * (largest + 1)
    for person in range(1, largest + 1):
        prefix[person] = prefix[person - 1] + golomb[person ** 3] + increments[person]
    return "".join(str(prefix[right] - prefix[left - 1]) + "\n"
                   for left, right in queries)


SAMPLE = "1 1\n1 1 1\n1 2\n"
SAMPLE_OUT = "6\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert build_golomb(1000)[1000] == 86
assert build_golomb(100)[8] == 4
assert oracle("0 1\n1 2\n") == "5\n"
assert oracle("0 2\n3 3\n1 1\n") == "9\n1\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    edges = "2 4\n2 1 3\n1 4 2\n1 1\n3 4\n4 1\n5 5\n"
    write("2_edges", edges)
    wide = ["0 100\n"] + [f"{rng.randint(1, 30)} {rng.randint(1, 30)}\n"
                        for _ in range(100)]
    write("3_wide", "".join(wide))
    mixed = ["50 100\n"]
    mixed += [f"{rng.randint(1, 30)} {rng.randint(1, 30)} {rng.randint(1, 10)}\n"
              for _ in range(50)]
    mixed += [f"{rng.randint(1, 30)} {rng.randint(1, 30)}\n" for _ in range(100)]
    write("4_random", "".join(mixed))
    heavy = [f"{1000} {100000}\n"]
    heavy += [f"{rng.randint(1, 10)} {rng.randint(1, 10)} {rng.randint(1, 10)}\n"
              for _ in range(1000)]
    heavy += [f"{rng.randint(1, 10)} {rng.randint(1, 10)}\n" for _ in range(100000)]
    write("5_io", "".join(heavy))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
